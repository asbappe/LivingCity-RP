--[[
    Living City: the chronicle (what happened in the city, and what led to it)

    The owner, 12 November: "how do we move to leave our scripted events ...
    but start building an emergent narrative engine/system". This is the first
    step: nothing that already happens changes. The chronicle only watches,
    like the minds' log, but it keeps each thing with what led to it:

      Unit 30 beat Pavel Orlov. Olga Volkov saw it, and later went to paint
      over a poster. Then, Olga Volkov was taken to the cells.

    An entry is one thing that happened: who (s), what (pred, a past-tense
    phrase), to whom (o), whose doing it was (a), which named people were
    near enough to see (saw), how much it matters (w: 1 small, 2 and up can
    lead to other things) and, when one is found, the entry that led to it
    (c): the latest thing of weight in the last three hours that happened to,
    was done by, or was seen by the one who acted.

    Players meet it in the world only:
      - a citizen's Chat (E on a citizen) passes on a story, once the city's
        older rumours (LC.TakeRumor) have run out; one who saw it says so
      - the Civil Protection incident feed (a placed monitor): only what was
        formally reported (arrests, reports received, units attacked or lost)
      - the Resistance notice board (placed): what their own people saw
    Staff only, for testing: "While you were away" on joining, and the
    stories list (F1 > What now? > The city's stories, or !news), secrets
    included.

    Kept secret from players (staff see them in the stories file): who
    informs, who leaks to the Resistance, who shelters, and the quiet things
    people do at home.

    Files (data/livingcity/chronicle/):
      <map>.json          the entries (the newest 400) and when each player
                          was last here; kept over map changes
      <map>_stories.txt   the last week's stories in plain words, secrets
                          included, rewritten at every save: for the owner

    lc_chronicle 1/0 turns it on or off.
]]

LC = LC or {}

local cvOn = CreateConVar("lc_chronicle", "1", FCVAR_ARCHIVE, "The chronicle: what happens in the city is kept with what led to it, and told as rumours, on joining and in F1 (data/livingcity/chronicle/)")

local DIR = "livingcity/chronicle"
local MAX = 400               -- entries kept
local WINDOW = 3 * 3600       -- how far back a cause is looked for (seconds)
local SAME = 120              -- the same thing again within this long is one entry (a fight is many blows)
local RUMOUR_AGE = 6 * 3600   -- citizens talk about the last six hours
local NEWS_AGE = 24 * 3600    -- F1's list: the last day
local AWAY_MIN = 600          -- away less than this: no card on joining
local AWAY_MAX = 3 * 86400    -- and never further back than three days
local SAVE_EVERY = 300

LC.Chron = LC.Chron or { list = {}, byN = {}, n = 0, seen = {}, loaded = false, dirty = false, lastSave = 0 }
local C = LC.Chron

local function On() return cvOn:GetBool() end
LC.ChronicleOn = On

local function Has(list, id)
    for _, v in ipairs(list or {}) do if v == id then return true end end
    return false
end

local function NameOf(id)
    local n = LC.MindsName and LC.MindsName(id) or "someone"
    return (string.gsub(n, " %(player%)$", ""))
end

local function KeyOf(ent) return LC.MindsWhoKey and LC.MindsWhoKey(ent) or nil end
local function IsPlayerKey(id) return type(id) == "string" and string.sub(id, 1, 3) == "pl:" end

------------------------------------------------------------------------
-- Keeping it over a map change
------------------------------------------------------------------------
local function Path() return string.format("%s/%s.json", DIR, game.GetMap()) end
local function Key(s) if s == nil then return nil end return tonumber(s) or s end

function LC.ChronicleLoad()
    C.loaded = true
    local raw = file.Read(Path(), "DATA")
    local data = raw and util.JSONToTable(raw)
    if not data or not data.list then return 0 end
    C.list, C.byN, C.seen = {}, {}, {}
    C.n = tonumber(data.n) or 0
    for _, d in ipairs(data.list) do
        local saw = {}
        for i, v in ipairs(d.saw or {}) do saw[i] = Key(v) end
        local e = { n = tonumber(d.n) or 0, t = tonumber(d.t) or 0, k = tostring(d.k or ""), s = Key(d.s), sn = tostring(d.sn or "someone"), o = Key(d.o),
            pred = tostring(d.pred or ""), a = Key(d.a), saw = saw, w = tonumber(d.w) or 1, sec = d.sec and true or nil, c = tonumber(d.c) }
        C.list[#C.list + 1] = e
        C.byN[e.n] = e
        if e.n > C.n then C.n = e.n end
    end
    for _, sd in ipairs(data.seen or {}) do C.seen[tostring(sd[1])] = tonumber(sd[2]) end
    return #C.list
end

local function Ensure() if not C.loaded then pcall(LC.ChronicleLoad) C.loaded = true end end

------------------------------------------------------------------------
-- Writing a thing down
------------------------------------------------------------------------
local function FindCause(actor, now)
    if actor == nil then return nil end
    for i = #C.list, math.max(1, #C.list - 150), -1 do
        local e = C.list[i]
        if now - e.t > WINDOW then break end
        if (e.w or 0) >= 2 and (e.s == actor or e.o == actor or Has(e.saw, actor)) then return e.n end
    end
    return nil
end

-- e: { k = kind, s = who, pred = "beat Pavel Orlov", o = to whom, a = whose doing (s when left out),
--      pos = where (named people within sight are written down as having seen it), w = weight, sec = kept from players }
function LC.ChronicleAdd(e, now)
    if not On() or not e or e.s == nil or not e.pred or e.pred == "" then return nil end
    Ensure()
    now = now or os.time()
    for i = #C.list, math.max(1, #C.list - 12), -1 do
        local p = C.list[i]
        if now - p.t > SAME then break end
        if p.s == e.s and (p.pred == e.pred or (p.k == e.k and p.o == e.o)) then return p end
    end
    local saw = {}
    if e.pos and LC.MindsNearby then
        for _, w in ipairs(LC.MindsNearby(e.pos)) do
            if w.id ~= e.s and w.id ~= e.o and #saw < 12 then saw[#saw + 1] = w.id end
        end
    end
    for _, id in ipairs(e.saw or {}) do if not Has(saw, id) then saw[#saw + 1] = id end end
    local actor = e.a
    if actor == nil then actor = e.s end
    C.n = C.n + 1
    local entry = { n = C.n, t = now, k = e.k or "", s = e.s, sn = e.sn or NameOf(e.s), o = e.o, pred = e.pred, a = actor, saw = saw,
        w = e.w or 1, sec = e.sec and true or nil }
    entry.c = FindCause(actor, now)
    C.list[#C.list + 1] = entry
    C.byN[entry.n] = entry
    while #C.list > MAX do
        C.byN[C.list[1].n] = nil
        table.remove(C.list, 1)
    end
    C.dirty = true
    return entry
end

------------------------------------------------------------------------
-- Stories: a thing, and the things that led to it
------------------------------------------------------------------------
-- The chain that ends at e, oldest first, three at most. public: the secret ones are left out.
local function ChainOf(e, public)
    local out, been = {}, {}
    while e and #out < 3 and not been[e.n] do
        been[e.n] = true
        if not (public and e.sec) then table.insert(out, 1, e) end
        e = e.c and C.byN[e.c] or nil
    end
    return out
end

local function Tell(chain)
    local parts = {}
    for i, e in ipairs(chain) do
        local prev = chain[i - 1]
        if not prev then parts[#parts + 1] = e.sn .. " " .. e.pred .. "."
        elseif e.a == e.s and Has(prev.saw, e.s) then parts[#parts + 1] = e.sn .. " saw it, and later " .. e.pred .. "."
        else parts[#parts + 1] = (i == 2 and "Later, " or "Then, ") .. e.sn .. " " .. e.pred .. "." end
    end
    return table.concat(parts, " ")
end

-- Every story whose last thing happened after `since`: { chain, text, score, t }, the weightiest first.
function LC.ChronicleStories(since, now, public)
    Ensure()
    now = now or os.time()
    local led = {} -- (entries that led to a later one aren't stories of their own)
    for _, e in ipairs(C.list) do if e.c then led[e.c] = true end end
    local out, got = {}, {}
    for i = #C.list, 1, -1 do
        local e = C.list[i]
        if e.t < since then break end
        if not led[e.n] then
            local chain = ChainOf(e, public)
            local last = chain[#chain]
            if last and not got[last.n] then
                got[last.n] = true
                local score = (#chain - 1) * 2
                for _, c in ipairs(chain) do score = score + (c.w or 1) end
                out[#out + 1] = { chain = chain, text = Tell(chain), score = score, t = last.t }
            end
        end
    end
    table.sort(out, function(a, b) if a.score ~= b.score then return a.score > b.score end return a.t > b.t end)
    return out
end

------------------------------------------------------------------------
-- A citizen passes one on (Chat in the talk window: sv_livingcity_talk.lua)
------------------------------------------------------------------------
local HEARD = { "They say ", "Did you hear? ", "People are talking. ", "Keep this to yourself. " }

function LC.ChronicleRumor(ply, npc, now)
    if not On() or not IsValid(ply) then return nil end
    now = now or os.time()
    ply.lcChronHeard = ply.lcChronHeard or {}
    local id = IsValid(npc) and npc.lcProfile and npc.lcProfile.id or nil
    local me = KeyOf(ply)
    local best, bestSaw
    for _, st in ipairs(LC.ChronicleStories(now - RUMOUR_AGE, now, true)) do
        local last = st.chain[#st.chain]
        if st.score >= 3 and not ply.lcChronHeard[last.n] then
            local inIt, saw = false, false
            for _, e in ipairs(st.chain) do
                if (id ~= nil and (e.s == id or e.o == id)) or (me ~= nil and (e.s == me or e.o == me)) then inIt = true end
                if id ~= nil and Has(e.saw, id) then saw = true end
            end
            if not inIt then
                if saw then best, bestSaw = st, true break end
                if not best then best = st end
            end
        end
    end
    if not best then return nil end
    ply.lcChronHeard[best.chain[#best.chain].n] = true
    return (bestSaw and "I saw it myself. " or HEARD[math.random(#HEARD)]) .. best.text
end

------------------------------------------------------------------------
-- On joining: what happened while you were away
------------------------------------------------------------------------
local function SeenKey(ply) return tostring(ply:SteamID()) end

function LC.ChronicleAway(ply, now)
    if not On() or not IsValid(ply) then return nil end
    Ensure()
    now = now or os.time()
    local last = C.seen[SeenKey(ply)]
    if not last or now - last < AWAY_MIN then return nil end
    local parts, len = {}, 0
    for _, st in ipairs(LC.ChronicleStories(math.max(last, now - AWAY_MAX), now, true)) do
        if (#st.chain >= 2 or st.score >= 4) and len + #st.text <= 380 and #parts < 3 then
            parts[#parts + 1] = st.text
            len = len + #st.text + 1
        end
    end
    return #parts > 0 and table.concat(parts, " ") or nil
end

hook.Add("PlayerInitialSpawn", "LivingCityChronicle", function(ply)
    if not On() then return end
    timer.Simple(25, function()
        if not IsValid(ply) then return end
        -- (staff only, as the list is: nobody else knows what they weren't there for)
        local ok, text = pcall(LC.ChronicleAway, ply)
        if ok and text and LC.Notice and IsStaff(ply) then LC.Notice(ply, "info", "While you were away", text, 18) end
        C.seen[SeenKey(ply)] = os.time()
        C.dirty = true
    end)
end)

hook.Add("PlayerDisconnected", "LivingCityChronicle", function(ply)
    if not On() or not IsValid(ply) then return end
    Ensure()
    C.seen[SeenKey(ply)] = os.time()
    C.dirty = true
end)

------------------------------------------------------------------------
-- F1 > What now? > What's been happening (or !news)
------------------------------------------------------------------------
-- Staff only (the owner, 12 November: "only admins should have it for testing purposes; we don't need
-- to add in psychic lore breaking roleplay breaking concepts"): secrets included.
local function IsStaff(ply) return IsValid(ply) and (ply:IsAdmin() or (LC.CanEdit ~= nil and LC.CanEdit(ply))) or false end
LC.ChronicleStaff = IsStaff

function LC.ChronicleNews(now)
    now = now or os.time()
    local out = {}
    for _, st in ipairs(LC.ChronicleStories(now - NEWS_AGE, now, false)) do
        if #out < 20 then out[#out + 1] = { text = st.text, mins = math.max(0, math.floor((now - st.t) / 60)) } end
    end
    table.sort(out, function(a, b) return a.mins < b.mins end)
    return out
end

function LC.SendNews(ply)
    if not IsValid(ply) or not LC.SendCompressed then return false end
    if not IsStaff(ply) then
        ply:ChatPrint("[Miscount] The city's stories are for staff. Ask around (E on a citizen, then Chat), or read a board.")
        return false
    end
    LC.SendCompressed("lc_chronicle", { on = On(), stories = On() and LC.ChronicleNews() or {} }, ply)
    return true
end

if util.AddNetworkString then util.AddNetworkString("lc_chronicle") end
LC.SlashCommands = LC.SlashCommands or {}
LC.SlashCommands.news = function(ply) LC.SendNews(ply) end

------------------------------------------------------------------------
-- The two feeds (lc_newsfeed: the Civil Protection incident feed, the Resistance notice board)
------------------------------------------------------------------------
local FEED_MAX = 8
local WORD_TRAVELS = 300 -- seconds before the Resistance's board has it

local function PlayerOfKey(id)
    if not IsPlayerKey(id) then return nil end
    for _, ply in ipairs(player.GetAll()) do if KeyOf(ply) == id then return ply end end
    return nil
end
local function IsUnitId(id)
    if id == nil then return false end
    local m = LC.Minds and LC.Minds.byId[id]
    if m then return m.role == "cop" end
    local ply = PlayerOfKey(id)
    return ply ~= nil and LC.PlayerIsCP ~= nil and LC.PlayerIsCP(ply) or false
end
local function IsRebelId(id)
    if id == nil then return false end
    local m = LC.Minds and LC.Minds.byId[id]
    if m then return m.rebel == true or (m.p ~= nil and m.p.rebel == true) end
    local ply = PlayerOfKey(id)
    return ply ~= nil and ply:GetNW2String("lcf_faction", "") == "resistance"
end
local function Short(s, n) s = tostring(s or "") if #s > n then return string.sub(s, 1, n - 2) .. ".." end return s end

-- What Civil Protection's feed says of an entry: only what was formally reported (an arrest, a report
-- received, a unit attacked or lost, a subject killed by a unit). Nil: not on the feed.
local function CPLine(e)
    local s, o = string.upper(Short(e.sn, 24)), e.o ~= nil and string.upper(Short(NameOf(e.o), 24)) or nil
    if e.k == "arrest" then return "DETAINED: " .. s .. ".", false end
    if (e.k == "snitch" or e.k == "did:inform") and o then return "REPORT RECEIVED. SUBJECT: " .. o .. ".", false end
    if e.k == "hurt" and o and IsUnitId(e.o) and not IsUnitId(e.s) then return "ASSAULT ON " .. o .. ".", true, "SUSPECT: " .. s end
    if e.k == "killed" and o and IsUnitId(e.o) then return "UNIT LOST: " .. o .. ".", true, "SUSPECT: " .. s end
    if e.k == "killed" and o and IsUnitId(e.s) then return "AMPUTATED: " .. o .. ".", false, "BY: " .. s end
    return nil
end

-- What the Resistance's board has: things the street could see, that one of their own (a sympathizer,
-- a Resistance player) saw or was part of. It can be wrong: an accusation goes up as it was shouted.
local REBEL_KINDS = { hurt = true, killed = true, died = true, arrest = true, burned = true,
    ["did:accuse"] = true, ["did:brutal"] = true, ["did:tantrum"] = true, ["did:sabotage"] = true, ["did:defy"] = true }
local function RebelLine(e)
    if e.sec or not REBEL_KINDS[e.k] then return nil end
    local known = IsRebelId(e.s) or IsRebelId(e.o)
    if not known then for _, id in ipairs(e.saw or {}) do if IsRebelId(id) then known = true break end end end
    if not known then return nil end
    return Short(e.sn .. " " .. e.pred .. ".", 62)
end

function LC.ChronicleFeeds(now)
    Ensure()
    now = now or os.time()
    local cp, rebel = {}, {}
    for i = #C.list, 1, -1 do
        local e = C.list[i]
        if now - e.t > RUMOUR_AGE then break end
        local mins = math.max(0, math.floor((now - e.t) / 60))
        if #cp < FEED_MAX then
            local text, hot, more = CPLine(e)
            if text then cp[#cp + 1] = { text = text, hot = hot or nil, more = more, mins = mins } end
        end
        if #rebel < FEED_MAX and now - e.t >= WORD_TRAVELS then
            local text = RebelLine(e)
            if text then rebel[#rebel + 1] = { text = text, mins = mins } end
        end
    end
    return { cp = cp, rebel = rebel }
end

local function FeedSig(f)
    local parts = {}
    for _, it in ipairs(f.cp) do parts[#parts + 1] = it.text end
    parts[#parts + 1] = "|"
    for _, it in ipairs(f.rebel) do parts[#parts + 1] = it.text end
    return table.concat(parts, ";")
end

function LC.ChronicleSendFeeds(to, force)
    if not On() or not LC.SendCompressed then return false end
    local f = LC.ChronicleFeeds()
    local sig = FeedSig(f)
    if not force and sig == C.feedSig and os.time() - (C.feedAt or 0) < 600 then return false end
    if not to then C.feedSig, C.feedAt = sig, os.time() end
    LC.SendCompressed("lc_feeds", f, to or player.GetAll())
    return true
end

if util.AddNetworkString then util.AddNetworkString("lc_feeds") end
timer.Create("LivingCityChronicleFeeds", 20, 0, function()
    if not On() or #player.GetAll() == 0 then return end
    local ok, err = pcall(LC.ChronicleSendFeeds)
    if not ok and LC.Error then LC.Error("chronicle (feeds)", err) end
end)
hook.Add("PlayerInitialSpawn", "LivingCityChronicleFeeds", function(ply)
    timer.Simple(12, function() if IsValid(ply) and On() then pcall(LC.ChronicleSendFeeds, ply, true) end end)
end)

------------------------------------------------------------------------
-- What's watched (the game's own moments; nothing here changes them)
------------------------------------------------------------------------
local function IsUnit(ent)
    if not IsValid(ent) then return false end
    if ent.lcProfile then return ent.lcProfile.role == "cop" end
    return ent:IsPlayer() and LC.PlayerIsCP and LC.PlayerIsCP(ent) or false
end

function LC.ChronicleHurt(ent, attacker)
    if not IsValid(ent) or not IsValid(attacker) or ent == attacker then return nil end
    if not (ent.lcProfile or ent:IsPlayer()) then return nil end
    local who, to = KeyOf(attacker), KeyOf(ent)
    if who == nil or to == nil then return nil end
    return LC.ChronicleAdd({ k = "hurt", s = who, o = to, pred = ((IsUnit(attacker) and not IsUnit(ent)) and "beat " or "attacked ") .. NameOf(to), pos = ent:GetPos(), w = 3 })
end

hook.Add("EntityTakeDamage", "LivingCityChronicle", function(ent, dmg)
    if not On() or not IsValid(ent) or not (ent.lcProfile or ent:IsPlayer()) then return end
    if (dmg:GetDamage() or 0) <= 0 then return end
    local ok, err = pcall(LC.ChronicleHurt, ent, dmg:GetAttacker())
    if not ok and LC.Error then LC.Error("chronicle (hurt)", err) end
end)

function LC.ChronicleKilled(victim, attacker)
    if not IsValid(victim) then return nil end
    local to = KeyOf(victim)
    if to == nil then return nil end
    local who = IsValid(attacker) and attacker ~= victim and KeyOf(attacker) or nil
    if who ~= nil then return LC.ChronicleAdd({ k = "killed", s = who, o = to, pred = "killed " .. NameOf(to), pos = victim:GetPos(), w = 4 }) end
    if victim:IsPlayer() then return nil end -- (a player's lonely death is theirs)
    return LC.ChronicleAdd({ k = "died", s = to, pred = "died", pos = victim:GetPos(), w = 3 })
end

hook.Add("OnNPCKilled", "LivingCityChronicle", function(npc, attacker)
    if not On() or not (IsValid(npc) and npc.lcProfile) then return end
    local ok, err = pcall(LC.ChronicleKilled, npc, attacker)
    if not ok and LC.Error then LC.Error("chronicle (killed)", err) end
end)

hook.Add("PlayerDeath", "LivingCityChronicle", function(victim, _, attacker)
    if not On() then return end
    pcall(LC.ChronicleKilled, victim, attacker)
end)

hook.Add("LivingCityIncarcerated", "LivingCityChronicle", function(ent, secs, reason, arrester)
    if not On() or not IsValid(ent) then return end
    local to = KeyOf(ent)
    if to == nil then return end
    local who = KeyOf(arrester)
    LC.ChronicleAdd({ k = "arrest", s = to, o = who, pred = "was taken to the cells" .. (who ~= nil and (" by " .. NameOf(who)) or ""), pos = ent:GetPos(), w = 3 })
end)

hook.Add("LivingCityPickpocket", "LivingCityChronicle", function(ply, npc, got)
    if got or not On() or not (IsValid(npc) and npc.lcProfile) then return end
    local who, to = KeyOf(ply), KeyOf(npc)
    if who == nil or to == nil then return end
    LC.ChronicleAdd({ k = "robbed", s = who, o = to, pred = "was caught with a hand in " .. NameOf(to) .. "'s pocket", pos = npc:GetPos(), w = 2 })
end)

hook.Add("LivingCityBurned", "LivingCityChronicle", function(burner, target)
    if not On() or not (IsValid(target) and target.lcProfile) then return end
    local who, to = KeyOf(burner), KeyOf(target)
    if who == nil or to == nil then return end
    LC.ChronicleAdd({ k = "burned", s = who, o = to, pred = "beat " .. NameOf(to) .. " as an informer", pos = target:GetPos(), w = 3 })
end)

hook.Add("LivingCityPosterDefaced", "LivingCityChronicle", function(ply, e)
    if not On() or not IsValid(e) then return end
    local who = KeyOf(ply)
    if not IsPlayerKey(who) then return end -- (a named citizen's own poster is the break that sent them: below)
    LC.ChronicleAdd({ k = "poster", s = who, pred = "painted over a Combine poster", pos = e:GetPos(), w = 2 })
end)

hook.Add("LivingCitySnitched", "LivingCityChronicle", function(npc, ply)
    if not On() or not (IsValid(npc) and npc.lcProfile) then return end
    local who, to = KeyOf(npc), KeyOf(ply)
    if who == nil then return end
    LC.ChronicleAdd({ k = "snitch", s = who, o = to, pred = "reported " .. NameOf(to) .. " to Civil Protection", pos = npc:GetPos(), w = 2, sec = true })
end)

-- A mind breaking (sv_livingcity_mindsact.lua runs LivingCityMindBroke with what was done, in words).
local HARD = { tantrum = true, defy = true, accuse = true, sabotage = true, brutal = true, despair = true }
local SECRET = { inform = true, leak = true, shelter = true }
-- what the street could see; anything else was done quietly, at home or not at all
local SEEN = { "went to ", "shouted ", "sat down ", "called ", "beat ", "drank in the street", "drank on duty", "shared food ", "steadied " }

function LC.ChronicleBroke(m, kind, did, now)
    if not m or m.id == nil or type(did) ~= "string" or did == "" then return nil end
    local pred = did
    pred = string.gsub(pred, ", and sides with the Resistance now$", "") -- (who sides with whom isn't street talk)
    pred = string.gsub(pred, ":.*$", "")
    local public = false
    for _, s in ipairs(SEEN) do if string.sub(pred, 1, #s) == s then public = true break end end
    local secret = SECRET[kind] or not public
    -- to whom: a named person the words name, or (informing) the player they like least
    local o
    for id, q in pairs(LC.Minds and LC.Minds.byId or {}) do
        if id ~= m.id and q.name and q.name ~= "" and string.find(pred, q.name, 1, true) then o = id break end
    end
    if o == nil and kind == "inform" and m.psy then
        local wv
        for id, v in pairs(m.psy.ties or {}) do
            if IsPlayerKey(id) and v <= -2 and (not wv or v < wv) then o, wv = id, v end
        end
    end
    local npc = m.p and m.p.npc
    return LC.ChronicleAdd({ k = "did:" .. tostring(kind), s = m.id, sn = m.name, o = o, pred = pred, pos = IsValid(npc) and npc:GetPos() or nil,
        w = (HARD[kind] and public) and 3 or ((SECRET[kind] and 2) or 1), sec = secret }, now)
end

hook.Add("LivingCityMindBroke", "LivingCityChronicle", function(m, kind, did)
    if not On() then return end
    local ok, err = pcall(LC.ChronicleBroke, m, kind, did)
    if not ok and LC.Error then LC.Error("chronicle (break)", err) end
end)

------------------------------------------------------------------------
-- Saving
------------------------------------------------------------------------
function LC.ChronicleSave(now)
    Ensure()
    now = now or os.time()
    local out = { n = C.n, saved = now, list = {}, seen = {} }
    for _, e in ipairs(C.list) do
        local saw = {}
        for i, v in ipairs(e.saw or {}) do saw[i] = tostring(v) end
        out.list[#out.list + 1] = { n = e.n, t = e.t, k = e.k, s = tostring(e.s), sn = e.sn, o = e.o ~= nil and tostring(e.o) or nil, pred = e.pred,
            a = e.a ~= nil and tostring(e.a) or nil, saw = saw, w = e.w, sec = e.sec, c = e.c }
    end
    for _, ply in ipairs(player.GetAll()) do C.seen[SeenKey(ply)] = now end -- (so a crash doesn't lose who was here)
    for k, v in pairs(C.seen) do
        if now - v < 30 * 86400 then out.seen[#out.seen + 1] = { k, v } end
    end
    file.CreateDir("livingcity")
    file.CreateDir(DIR)
    file.Write(Path(), util.TableToJSON(out))
    -- and the last week in plain words, secrets included, for the owner
    local lines = { "The chronicle: stories of the last week, the weightiest first (secrets included: not what players are told).", "" }
    for _, st in ipairs(LC.ChronicleStories(now - 7 * 86400, now, false)) do
        lines[#lines + 1] = string.format("%s  [%d]  %s", os.date("%Y-%m-%d %H:%M", st.t), st.score, st.text)
    end
    file.Write(string.format("%s/%s_stories.txt", DIR, game.GetMap()), table.concat(lines, "\n") .. "\n")
    C.dirty, C.lastSave = false, now
end

-- For the debug report.
function LC.ChronicleReport()
    if not On() then return { "off (lc_chronicle 0)" } end
    Ensure()
    local now = os.time()
    local stories = LC.ChronicleStories(now - NEWS_AGE, now, false)
    local linked = 0
    for _, st in ipairs(stories) do if #st.chain >= 2 then linked = linked + 1 end end
    local out = { string.format("entries kept %d | stories in the last day %d, %d of them with a cause", #C.list, #stories, linked) }
    for i = 1, math.min(3, #stories) do out[#out + 1] = "  " .. stories[i].text end
    return out
end

timer.Create("LivingCityChronicle", 60, 0, function()
    if not On() or not C.dirty or os.time() - (C.lastSave or 0) < SAVE_EVERY then return end
    local ok, err = pcall(LC.ChronicleSave)
    if not ok and LC.Error then LC.Error("chronicle (save)", err) end
end)

hook.Add("ShutDown", "LivingCityChronicle", function()
    if On() and C.loaded then pcall(LC.ChronicleSave) end
end)
