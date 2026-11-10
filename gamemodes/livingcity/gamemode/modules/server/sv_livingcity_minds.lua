--[[
    Living City: watching the city's minds (writes it down, changes nothing)

    The named people (the roster, data/livingcity/<map>_people.json) are given
    minds by sv_livingcity_psyche.lua: traits, needs, thoughts, stress, who
    they feel what about, and rumours passed on in chats. For now this only
    WATCHES: it tells their minds what happens to them, steps one mind every
    half second, and writes down what they felt and what they would have done
    when something gave ("WOULD: tantrum at Unit 30"). No NPC does anything
    differently, nothing is sent to players, nothing in the roster file
    changes. The owner leaves it running and brings the logs back to be read
    (python3 _dev/psyche/analyze.py FOLDER).

    What it is told (all things the game already does):
      hurt        a named person hurt by a unit, a player or anything else;
                  named people within sight of it hear who did it
      killed      a named person dies: friends grieve, those near saw it
      arrested    a named person taken to the cells: friends feel it
      fed         a citizen served at the ration dispenser
      kindness    a player sharing food with them (talking to them)
      asleep      a citizen in bed at home (sv_livingcity_rest.lua)
      stopped     a citizen stopped and searched by a unit (seen as "detained")
      curfew      a curfew, lockdown or sweep starting (everyone)
      socio       sociostability turning red or black, and calming again
      posters     a poster of the Administrator defaced, by those who saw it
      robbed      a pickpocket caught at it
      burned      an informant beaten by the Resistance, and who saw it
      snitched    a secret informant reporting a player
      announced   the Administrator on the PA (at most every 10 minutes)
      vices       a drink or a smoke: given by a player, in the street
                  (sv_livingcity_npcvices.lua) or at home
    Off the streets they're at home: they eat and sleep as the day allows,
    and those fond of a drink and a smoke have one when they can (it costs
    them a little food).

    Files (data/livingcity/minds/):
      <map>_<date>_<time>.txt  one log per map start: inputs, would-be
                               breaks, a snapshot every 10 minutes with the
                               cost; at most 3 MB each, the newest 40 kept
      <map>_state.json         the minds themselves, kept over map changes

    lc_minds 1/0 turns it all on or off (editor panel, NPC budget section).
    lc_minds_show 1 adds a line to the talk window saying how they seem and
    why (off by default: nothing players see changes).
]]

LC = LC or {}
local Psy = LC.Psy

local FLAGS = FCVAR_ARCHIVE
local cvOn = CreateConVar("lc_minds", "1", FLAGS, "The city's minds: watch how the named people feel and write it down (data/livingcity/minds/); nobody behaves differently")
local cvShow = CreateConVar("lc_minds_show", "0", FLAGS, "Talking to a named person says how they seem and why (from the city's minds)")

local DIR = "livingcity/minds"
local STEP = 0.5           -- seconds between minds
local SNAP_EVERY = 600     -- seconds between snapshots in the log
local SAVE_EVERY = 300     -- seconds between saves of the minds
local MAX_BYTES = 3 * 1024 * 1024
local KEEP_LOGS = 40
local SEE = 700            -- how far a named person sees something happen

LC.Minds = LC.Minds or { byId = {}, names = {}, order = {}, idx = 0, buf = {}, counts = {}, breaks = {},
    stats = { steps = 0, total = 0, max = 0, since = 0 }, bytes = 0 }
local M = LC.Minds

local function On() return Psy ~= nil and cvOn:GetBool() end
LC.MindsOn = On

------------------------------------------------------------------------
-- Who's who
------------------------------------------------------------------------
local function MindOf(p)
    if not p or not p.id then return nil end
    local m = M.byId[p.id]
    if not m then
        m = { id = p.id }
        M.byId[p.id] = m
    end
    m.p, m.role, m.name, m.rebel = p, p.role, p.name, p.rebel
    return m
end
LC.MindOf = MindOf

-- An entity, as a mind sees it: a named person's id, a player's key, or nothing.
local function WhoKey(ent)
    if not IsValid(ent) then return nil end
    if ent.lcProfile and ent.lcProfile.id then return ent.lcProfile.id end
    if ent:IsPlayer() then
        local k = "pl:" .. ((LC.MemoryKey and LC.MemoryKey(ent)) or ent:SteamID())
        local char = ent:GetNW2String("lc_char", "")
        M.names[k] = (char ~= "" and char or ent:Nick()) .. " (player)"
        return k
    end
    return nil
end

local function Name(id)
    if id == nil then return "something" end
    if M.names[id] then return M.names[id] end
    local m = M.byId[id]
    return m and m.name or "someone"
end
LC.MindsName = Name

------------------------------------------------------------------------
-- The log
------------------------------------------------------------------------
local function Clock()
    local h = LC.Hour and LC.Hour() or 0
    return string.format("%s city %02d:%02d", os.date("%Y-%m-%d %H:%M:%S"), math.floor(h), math.floor((h % 1) * 60))
end

local function Log(kind, fmt, ...)
    M.buf[#M.buf + 1] = Clock() .. "  " .. kind .. "  " .. string.format(fmt, ...)
    if #M.buf > 2000 then table.remove(M.buf, 1) end
end
LC.MindsLog = Log

local function Count(k) M.counts[k] = (M.counts[k] or 0) + 1 end

local function LogPath()
    if not M.path then
        M.path = string.format("%s/%s_%s.txt", DIR, game.GetMap(), os.date("%Y-%m-%d_%H%M%S"))
        M.bytes = 0
        file.CreateDir("livingcity")
        file.CreateDir(DIR)
        -- the newest few only
        local logs = file.Find(DIR .. "/*.txt", "DATA") or {}
        table.sort(logs)
        for i = 1, #logs - KEEP_LOGS do file.Delete(DIR .. "/" .. logs[i]) end
    end
    return M.path
end

function LC.MindsFlush()
    if #M.buf == 0 then return end
    local text = table.concat(M.buf, "\n") .. "\n"
    M.buf = {}
    if M.bytes > MAX_BYTES then return end
    local path = LogPath()
    M.bytes = M.bytes + #text
    if M.bytes > MAX_BYTES then text = text .. "(this log is full: the next map start begins a new one)\n" end
    file.Append(path, text)
end

------------------------------------------------------------------------
-- Keeping the minds over a map change
------------------------------------------------------------------------
local function StatePath() return string.format("%s/%s_state.json", DIR, game.GetMap()) end

function LC.MindsSave()
    local now = CurTime()
    local out = { saved = os.time(), minds = {} }
    for id, m in pairs(M.byId) do
        local s = m.psy
        if s and m.p and m.p.alive then
            local ties, th, news = {}, {}, {}
            for k, v in pairs(s.ties) do ties[#ties + 1] = { tostring(k), v } end
            for _, t in ipairs(s.th) do th[#th + 1] = { t.k, t.v, math.max(0, t.untilT - now), t.who and tostring(t.who) or nil } end
            for _, n in ipairs(s.news) do news[#news + 1] = { n.k, tostring(n.about), tostring(n.to), n.w, n.hop } end
            out.minds[#out.minds + 1] = { id = id, food = s.food, rest = s.rest, company = s.company, stress = s.stress, crave = s.crave or 0,
                ties = ties, th = th, news = news }
        end
    end
    local names = {}
    for k, v in pairs(M.names) do names[#names + 1] = { k, v } end
    out.names = names
    file.CreateDir("livingcity")
    file.CreateDir(DIR)
    file.Write(StatePath(), util.TableToJSON(out))
end

local function Key(s) return tonumber(s) or s end

function LC.MindsLoad()
    M.loaded = true
    local raw = file.Read(StatePath(), "DATA")
    local data = raw and util.JSONToTable(raw)
    if not data or not data.minds then return 0 end
    local now, n = CurTime(), 0
    for _, nm in ipairs(data.names or {}) do M.names[nm[1]] = nm[2] end
    for _, d in ipairs(data.minds) do
        local id = tonumber(d.id)
        if id then
            local m = M.byId[id] or { id = id }
            M.byId[id] = m
            local s = { food = tonumber(d.food) or 0.8, rest = tonumber(d.rest) or 0.8, company = tonumber(d.company) or 0.7,
                stress = tonumber(d.stress) or 0, crave = tonumber(d.crave) or 0, th = {}, ties = {}, news = {}, last = 0, broke = -1e9 }
            for _, t in ipairs(d.ties or {}) do s.ties[Key(t[1])] = tonumber(t[2]) end
            for _, t in ipairs(d.th or {}) do
                if Psy.THOUGHTS[t[1]] then s.th[#s.th + 1] = { k = t[1], v = tonumber(t[2]) or 0, untilT = now + (tonumber(t[3]) or 0), who = t[4] and Key(t[4]) or nil } end
            end
            for _, x in ipairs(d.news or {}) do
                s.news[#s.news + 1] = { k = x[1], about = Key(x[2]), to = Key(x[3]), w = tonumber(x[4]) or 0, hop = tonumber(x[5]) or 0, at = now }
            end
            m.psy = s
            n = n + 1
        end
    end
    return n
end

------------------------------------------------------------------------
-- What happens to them (the game's own moments, watched)
------------------------------------------------------------------------
local function NearbyMinds(pos, except)
    local out = {}
    for npc, st in pairs(LC.NPCs or {}) do
        local p = IsValid(npc) and npc.lcProfile
        if p and npc ~= except and p.alive ~= false and npc:GetPos():DistToSqr(pos) < SEE * SEE then out[#out + 1] = MindOf(p) end
    end
    return out
end

local function Witness(pos, except, item, thought, victim)
    local now = CurTime()
    for _, w in ipairs(NearbyMinds(pos, except)) do
        if w.role == "citizen" and w.id ~= item.about then
            if thought then Psy.Think(w, (victim and Psy.Tie(w, victim) >= 3) and "friend_beaten" or thought, now, item.about) end
            if item.about and Psy.Hear(w, item, now) then Psy.Bond(w, item.about, -2) end
        end
    end
end

-- A named person hurt (EntityTakeDamage, below; the tests call it directly).
function LC.MindsHurt(ent, attacker, amount)
    if not On() then return end
    local p = IsValid(ent) and ent.lcProfile
    if not p or (amount or 0) <= 0 then return end
    local now = CurTime()
    if (ent.lcMindHurtAt or 0) > now - 5 and ent.lcMindHurtBy == attacker then return end
    ent.lcMindHurtAt, ent.lcMindHurtBy = now, attacker
    local m = MindOf(p)
    local who = WhoKey(attacker)
    Count("hurt")
    if p.role == "cop" then
        Psy.Think(m, "attacked", now, who)
        if who then Psy.Bond(m, who, -4) end
        Log("HURT", "%s attacked by %s", m.name, Name(who))
        return
    end
    if who then
        Psy.Think(m, "beaten", now, who)
        Psy.Bond(m, who, -6)
        Witness(ent:GetPos(), ent, { k = "beating", about = who, to = m.id, w = 1, hop = 0 }, "saw_beating", m.id)
    else
        Psy.Think(m, "hurt", now)
    end
    Log("HURT", "%s hurt by %s", m.name, who and Name(who) or (IsValid(attacker) and attacker:GetClass() or "something"))
end

hook.Add("EntityTakeDamage", "LivingCityMinds", function(ent, dmg)
    if not ent.lcProfile or not On() then return end
    local ok, err = pcall(LC.MindsHurt, ent, dmg:GetAttacker(), dmg:GetDamage())
    if not ok and LC.Error then LC.Error("minds (hurt)", err) end
end)

function LC.MindsKilled(npc, attacker)
    if not On() then return end
    local p = IsValid(npc) and npc.lcProfile
    if not p then return end
    local now = CurTime()
    local m = MindOf(p)
    local who = WhoKey(attacker)
    Count("killed")
    Log("KILLED", "%s killed by %s", m.name, who and Name(who) or (IsValid(attacker) and attacker:GetClass() or "something"))
    for _, q in pairs(M.byId) do
        if q ~= m and q.psy and q.p and q.p.alive ~= false and Psy.Tie(q, m.id) >= 3 then
            Psy.Think(q, "friend_died", now, m.id)
            if who then Psy.Bond(q, who, -5) end
        end
    end
    Witness(npc:GetPos(), npc, { k = "killing", about = who, to = m.id, w = 1, hop = 0 }, "saw_death")
    m.dead = true
end

hook.Add("OnNPCKilled", "LivingCityMinds", function(npc, attacker)
    if not On() or not (IsValid(npc) and npc.lcProfile) then return end
    local ok, err = pcall(LC.MindsKilled, npc, attacker)
    if not ok and LC.Error then LC.Error("minds (killed)", err) end
end)

hook.Add("LivingCityIncarcerated", "LivingCityMinds", function(ent, secs, reason, arrester)
    if not On() or not (IsValid(ent) and ent.lcProfile) then return end
    local m = MindOf(ent.lcProfile)
    local now = CurTime()
    local who = WhoKey(arrester)
    Psy.Think(m, "arrested", now, who)
    if who then Psy.Bond(m, who, -4) end
    for _, q in pairs(M.byId) do
        if q ~= m and q.psy and Psy.Tie(q, m.id) >= 3 then Psy.Think(q, "friend_taken", now, m.id) end
    end
    Count("arrested")
    Log("ARREST", "%s taken to the cells by %s (%s)", m.name, Name(who), tostring(reason))
end)

hook.Add("LivingCityServed", "LivingCityMinds", function(npc)
    if not On() or not (IsValid(npc) and npc.lcProfile) then return end
    local m = MindOf(npc.lcProfile)
    local s = Psy.State(m)
    s.food = math.min(1, s.food + 0.55)
    Psy.Think(m, "fed", CurTime())
    Count("fed")
end)

hook.Add("LivingCitySharedFood", "LivingCityMinds", function(ply, npc, id)
    if not On() or not (IsValid(npc) and npc.lcProfile) then return end
    local m = MindOf(npc.lcProfile)
    local s = Psy.State(m)
    local who = WhoKey(ply)
    local it = LCS and LCS.Items and LCS.Items[id]
    if it and it.vice then
        LC.MindsIndulged(m, "given")
        if Psy.Traits(m).vice > 0 then Psy.Bond(m, who, 2) end
    else
        s.food = math.min(1, s.food + 0.4)
    end
    Psy.Think(m, "kindness", CurTime(), who)
    if who then Psy.Bond(m, who, 3) end
    Count("kindness")
    Log("KIND", "%s given %s by %s", m.name, it and string.lower(it.name or id) or "food", Name(who))
end)

-- A drink or a smoke (a player's gift, in the street, or at home): the craving goes.
function LC.MindsIndulged(m, where)
    if not On() or not m then return end
    local s = Psy.State(m)
    s.crave = 0
    Psy.Think(m, "indulged", CurTime())
    Count("indulged_" .. (where or "street"))
end

local function Citizens()
    local out = {}
    for _, m in pairs(M.byId) do
        if m.role == "citizen" and m.p and m.p.alive and not m.dead then out[#out + 1] = m end
    end
    return out
end

-- Curfew, lockdown, sweep: everyone feels it.
local EVENT_THOUGHT = { curfew = "curfew", lockdown = "lockdown", sweep = "sweep" }
hook.Add("LivingCityEventStarted", "LivingCityMinds", function(name)
    local k = EVENT_THOUGHT[name]
    if not On() or not k then return end
    local now = CurTime()
    for _, m in ipairs(Citizens()) do Psy.Think(m, k, now) end
    Count(k)
    Log("CITY", "%s begins", name)
end)

-- Sociostability (sv_livingcity_cp.lua, LC.Socio), looked at each step: red and black frighten, calm relieves.
function LC.MindsSocio()
    local now, socio = CurTime(), LC.Socio or "green"
    if socio == M.lastSocio then return end
    local was = M.lastSocio
    M.lastSocio = socio
    if not was then return end
    local k = (socio == "red" and "city_red") or (socio == "black" and "city_black")
        or ((was == "red" or was == "black") and "relief") or nil
    if k then for _, m in ipairs(Citizens()) do Psy.Think(m, k, now) end end
    Log("CITY", "sociostability %s (was %s)", socio, was)
end

-- A poster defaced (sv_livingcity_learning.lua): the disloyal cheer inside, the loyal are upset.
hook.Add("LivingCityPosterDefaced", "LivingCityMinds", function(ply, e)
    if not On() or not IsValid(e) then return end
    local now = CurTime()
    for _, w in ipairs(NearbyMinds(e:GetPos())) do
        if w.role == "citizen" then Psy.Think(w, Psy.Traits(w).loyal < 0 and "defiance_good" or "defiance_bad", now, WhoKey(ply)) end
    end
    Count("posters")
end)

-- A pickpocket caught at it (sv_livingcity_talk.lua).
hook.Add("LivingCityPickpocket", "LivingCityMinds", function(ply, npc, got)
    if got or not On() or not (IsValid(npc) and npc.lcProfile) then return end
    local m = MindOf(npc.lcProfile)
    local who = WhoKey(ply)
    Psy.Think(m, "robbed", CurTime(), who)
    if who then Psy.Bond(m, who, -4) end
    Count("robbed")
    Log("ROBBED", "%s caught %s at their pocket", m.name, Name(who))
end)

-- An informant burned by the Resistance (sv_livingcity_snitches.lua): beaten as a rat, and those who saw it know who.
hook.Add("LivingCityBurned", "LivingCityMinds", function(burner, target, right)
    if not On() or not (IsValid(target) and target.lcProfile) then return end
    local m = MindOf(target.lcProfile)
    local who = WhoKey(burner)
    local now = CurTime()
    Psy.Think(m, "burned", now, who)
    if who then Psy.Bond(m, who, -8) end
    Witness(target:GetPos(), target, { k = "burning", about = who, to = m.id, w = 1, hop = 0 }, "saw_beating", m.id)
    Count("burned")
    Log("BURNED", "%s beaten as a rat by %s (%s)", m.name, Name(who), right and "really an informant" or "not one")
end)

-- A secret informant reporting a player (sv_livingcity_snitches.lua).
hook.Add("LivingCitySnitched", "LivingCityMinds", function(npc, ply, what)
    if not On() or not (IsValid(npc) and npc.lcProfile) then return end
    local m = MindOf(npc.lcProfile)
    local who = WhoKey(ply)
    Psy.Think(m, "snitched", CurTime(), who)
    Count("snitched")
    Log("SNITCH", "%s reported %s (%s)", m.name, Name(who), tostring(what))
end)

-- The Administrator on the PA (the server's own recordings: sv_livingcity_announcer.lua), every 10 minutes at most.
hook.Add("LivingCityCustomAnnouncement", "LivingCityMinds", function(voice)
    if not On() or voice ~= "administrator" then return end
    local now = CurTime()
    if now - (M.lastPA or -1e9) < 600 then return end
    M.lastPA = now
    for _, m in ipairs(Citizens()) do Psy.Think(m, "propaganda", now) end
    Count("propaganda")
end)

------------------------------------------------------------------------
-- What a break would have been (written down only)
------------------------------------------------------------------------
local ctx = {}
function ctx.Person(id) return M.byId[id] end

function ctx.Partner(m)
    local p = m.p
    local npc = p and p.npc
    if IsValid(npc) then
        local best, bd
        local pos = npc:GetPos()
        for other, st in pairs(LC.NPCs or {}) do
            local q = IsValid(other) and other ~= npc and other.lcProfile
            if q and q.role == m.role then
                local d = other:GetPos():DistToSqr(pos)
                if d < 250 * 250 and (not bd or d < bd) then best, bd = q, d end
            end
        end
        return best and MindOf(best) or nil
    end
    -- off the streets: now and then a friend who's off the streets too
    if math.random() > 0.3 then return nil end
    local friends = {}
    for id, v in pairs(m.psy and m.psy.ties or {}) do
        local q = M.byId[id]
        if v > 0 and q and q.p and q.p.alive ~= false and not IsValid(q.p.npc) then friends[#friends + 1] = q end
    end
    return #friends > 0 and friends[math.random(#friends)] or nil
end

function ctx.Break(m, kind)
    Count("would_" .. kind)
    M.breaks[kind] = (M.breaks[kind] or 0) + 1
    local target = ""
    local s = m.psy
    if kind == "tantrum" or kind == "defy" or kind == "brutal" then
        local worst, wv
        for id, v in pairs(s.ties) do if not wv or v < wv then worst, wv = id, v end end
        if worst and wv < 0 then target = " (angriest at " .. Name(worst) .. string.format(" %+d)", wv) end
    elseif kind == "accuse" then
        local worst, wv
        for id, v in pairs(s.ties) do local q = M.byId[id] if q and q.role == "citizen" and (not wv or v < wv) then worst, wv = id, v end end
        if worst then target = " (would call " .. Name(worst) .. string.format(" an informer, %+d)", wv) end
    elseif kind == "shelter" then
        local best, bv
        for id, v in pairs(s.ties) do local q = M.byId[id] if q and q.rebel and v > 0 and (not bv or v > bv) then best, bv = id, v end end
        if best then target = " (would hide " .. Name(best) .. ")" end
    elseif kind == "seek" or kind == "share" then
        local best, bv
        for id, v in pairs(s.ties) do if not bv or v > bv then best, bv = id, v end end
        if best and bv > 0 then target = " (closest to " .. Name(best) .. string.format(" %+d)", bv) end
    end
    local words = Psy.TraitWords(m, 3)
    Log("WOULD", "%s%s: %s%s%s  [%s]%s", m.name, m.role == "cop" and "" or (m.rebel and " (sympathizer)" or ""), kind, target,
        IsValid(m.p and m.p.npc) and " (on the streets)" or " (off the streets)", Psy.Describe(m, CurTime(), Name),
        #words > 0 and (" {" .. table.concat(words, ", ") .. "}") or "")
end

function ctx.Heard(m, n)
    Count("news_passed")
    if n.k == "informer" or n.k == "killing" then Log("RUMOUR", "%s heard: %s did %s to %s (told %d times)", m.name, Name(n.about), n.k, Name(n.to), n.hop) end
end

------------------------------------------------------------------------
-- The step: one mind every half second, round robin
------------------------------------------------------------------------
local function Rebuild()
    local order = {}
    for _, p in ipairs(LC.People and LC.People.list or {}) do
        if p.alive and (p.role == "citizen" or p.role == "cop") then
            MindOf(p)
            order[#order + 1] = p.id
        end
    end
    M.order, M.idx = order, 0
end

-- What their day is doing to their needs.
local function Live(m, now)
    local s = Psy.State(m)
    local npc = m.p.npc
    local st = IsValid(npc) and LC.NPCs and LC.NPCs[npc]
    local night = LC.DayPhase and LC.DayPhase() == "night"
    if st then
        if st.state == "abed" then
            s.rest = math.min(1, s.rest + 0.1)
            Psy.Think(m, "slept", now)
            Count("slept")
        end
        -- stopped and searched by a unit (sv_livingcity.lua: TryStartInspection)
        if st.state == "detained" then
            if not m.wasStopped then
                m.wasStopped = true
                local by
                for cop, cst in pairs(LC.NPCs) do if cst.subject == npc then by = WhoKey(cop) break end end
                Psy.Think(m, "stopped", now, by)
                if by then Psy.Bond(m, by, -1) end
                Count("stopped")
            end
        else
            m.wasStopped = nil
        end
        return st
    end
    -- at home, those fond of a drink and a smoke have one when they can (it costs a little food)
    if Psy.Traits(m).vice > 0 and (s.crave or 0) > 0.5 and math.random() < 0.15 then
        s.food = math.max(0, s.food - 0.06)
        LC.MindsIndulged(m, "home")
    end
    -- off the streets: at home, getting by on what they have, and sleeping at night
    if s.food < 0.45 then s.food = s.food + 0.02 end
    if night then
        s.rest = math.min(1, s.rest + 0.05)
        if s.rest > 0.7 and math.random() < 0.1 then Psy.Think(m, "slept", now) end
    end
end

function LC.MindsStep(now)
    if not On() then return end
    now = now or CurTime()
    if not M.loaded then
        local n = LC.MindsLoad()
        Log("START", "watching the city's minds on %s (%d minds put back from the last map)", game.GetMap(), n)
    end
    LC.MindsSocio()
    if M.idx >= #M.order then Rebuild() end
    if #M.order == 0 then return end
    M.idx = M.idx + 1
    local m = M.byId[M.order[M.idx]]
    if not m or not m.p or not m.p.alive or m.dead then return end
    m.rebel, m.name = m.p.rebel, m.p.name
    Psy.cfg.day = GetGlobal2Float("lc_day_len", 3600)
    local st = Live(m, now)
    if st and (st.state == "jailed" or st.state == "detained") then return end
    local t0 = SysTime()
    Psy.Step(m, now, ctx)
    local dt = SysTime() - t0
    local S = M.stats
    S.steps, S.total = S.steps + 1, S.total + dt
    if dt > S.max then S.max = dt end
end

-- How the city stands, in a line or two (the log's snapshots, the debug report).
function LC.MindsSnapshot(n)
    local now = CurTime()
    local all, sums, count, onStreet = {}, { food = 0, rest = 0, company = 0, stress = 0 }, 0, 0
    for _, m in pairs(M.byId) do
        if m.psy and m.p and m.p.alive and not m.dead then
            all[#all + 1] = m
            count = count + 1
            for k in pairs(sums) do sums[k] = sums[k] + m.psy[k] end
            if IsValid(m.p.npc) then onStreet = onStreet + 1 end
        end
    end
    local S = M.stats
    local lines = {}
    local function avg(k) return count > 0 and sums[k] / count or 0 end
    local roster = {}
    for _, m in ipairs(all) do if m.role == "citizen" then roster[#roster + 1] = m end end
    lines[1] = string.format("unrest=%.2f minds=%d on_streets=%d food=%.2f rest=%.2f company=%.2f stress=%.1f steps=%d avg_us=%.1f max_us=%.1f",
        Psy.Unrest(roster), count, onStreet, avg("food"), avg("rest"), avg("company"), avg("stress"),
        S.steps, S.steps > 0 and S.total / S.steps * 1e6 or 0, S.max * 1e6)
    local c = {}
    for k, v in pairs(M.counts) do c[#c + 1] = k .. "=" .. v end
    table.sort(c)
    lines[2] = "counts " .. (#c > 0 and table.concat(c, " ") or "(none yet)")
    table.sort(all, function(a, b) return a.psy.stress > b.psy.stress end)
    for i = 1, math.min(n or 3, #all) do
        local m = all[i]
        local t = Psy.Traits(m)
        lines[#lines + 1] = string.format("  %s%s brave %+.1f temper %+.1f loyal %+.1f social %+.1f hope %+.1f | %s",
            m.name or "?", m.role == "cop" and " (unit)" or (m.rebel and " (sympathizer)" or ""),
            t.brave, t.temper, t.loyal, t.social, t.hope, Psy.Describe(m, now, Name))
    end
    return lines
end

-- For the debug report (sv_livingcity_debug.lua).
function LC.MindsReport()
    if not On() then return { "off (lc_minds 0)" } end
    local lines = LC.MindsSnapshot(6)
    lines[#lines + 1] = "log: data/" .. (M.path or "(not written yet)") .. " | lc_minds_show " .. cvShow:GetString()
    return lines
end

-- For the talk window (sv_livingcity_talk.lua): how they seem and why, or "" (lc_minds_show 0).
function LC.MindsSeem(npc)
    if not On() or not cvShow:GetBool() then return "" end
    local p = IsValid(npc) and npc.lcProfile
    local m = p and M.byId[p.id]
    local s = m and m.psy
    if not s then return "" end
    local word
    if s.stress >= 20 then word = "close to breaking"
    elseif s.stress >= Psy.cfg.frayed then word = "on edge"
    elseif (s.mood or 0) > 3 then word = "in good spirits"
    elseif (s.mood or 0) < -3 then word = "low"
    else word = "all right" end
    local th = {}
    for _, t in ipairs(s.th) do th[#th + 1] = t end
    table.sort(th, function(a, b) return math.abs(a.v) > math.abs(b.v) end)
    local why = {}
    for i = 1, math.min(2, #th) do why[#why + 1] = Psy.THOUGHTS[th[i].k].text end
    return "They seem " .. word .. (#why > 0 and (": " .. table.concat(why, ", ")) or "") .. "."
end

timer.Create("LivingCityMinds", STEP, 0, function()
    if not On() or LC.TimeStopped then return end
    local ok, err = pcall(LC.MindsStep, CurTime())
    if not ok and LC.Error then LC.Error("minds (step)", err) end
    local now = CurTime()
    if now - (M.lastSnap or 0) >= SNAP_EVERY then
        M.lastSnap = now
        local okS, lines = pcall(LC.MindsSnapshot, 3)
        if okS then for _, l in ipairs(lines) do Log("SNAP", "%s", l) end end
    end
    if now - (M.lastFlush or 0) >= 60 then M.lastFlush = now LC.MindsFlush() end
    if now - (M.lastSave or 0) >= SAVE_EVERY then M.lastSave = now pcall(LC.MindsSave) end
end)

hook.Add("ShutDown", "LivingCityMinds", function()
    if not On() then return end
    pcall(function()
        for _, l in ipairs(LC.MindsSnapshot(6)) do Log("SNAP", "%s", l) end
        Log("STOP", "map ending")
        LC.MindsFlush()
        LC.MindsSave()
    end)
end)
