--[[
    Living City: the city's minds (the arithmetic)

    A Dwarf Fortress style layer that runs on the named people's records
    (data/livingcity/<map>_people.json), never on the NPC entities, so it costs
    no traces, no pathing and no networking. It is pure arithmetic on small
    tables:

      traits    eleven numbers from -1 to 1, worked out from the person's id
                (nothing new to save): brave, temper, loyal, social, hope,
                greed, compassion, suspicion, resilience, pride, vice
      needs     food, rest, company, from 0 (desperate) to 1 (fine), and for
                anyone with a weakness for drink and smokes, a craving
      thoughts  at most 8 timed feelings ("beaten by Unit 45", "fed"), the
                same kind refreshes instead of stacking (as in DF)
      mood      the thoughts plus the needs
      stress    builds while mood is low, eases while it is good (faster or
                slower by resilience); past a line the person breaks, in a
                way that fits their traits
      ties      at most 8 people they feel something about, -10 to 10
      news      at most 4 things they heard, passed on in chats, weaker
                with each telling (rumours: who beat whom, who informed);
                the suspicious believe only their friends

    The game feeds it what happens (O(1) each, from hooks it already has) and
    it is stepped a person or two at a time, round robin. What comes out is a
    break or an inspiration, which the game turns into something seen.

    Nothing here touches the game: no entities, no hooks, no settings. It is
    used by sv_livingcity_minds.lua (which only watches and writes down, for
    now) and by the offline test city in _dev/psyche/.
]]

LC = LC or {}
local Psy = {}
LC.Psy = Psy

Psy.cfg = {
    thoughtCap = 8,
    tieCap = 8,
    newsCap = 4,
    frayed = 10,      -- stress where behaviour starts to bend
    breakAt = 28,     -- stress where something gives
    breakCool = 3600, -- seconds before the same person breaks again
    stressCap = 40,   -- it never builds past this (no endless spiral)
    day = 2400,       -- seconds in a city day (needs decay against this)
}

------------------------------------------------------------------------
-- Traits: from the id, so nothing is saved and they never change
------------------------------------------------------------------------
-- (a scrambled number per id and trait: each trait independent of the others;
-- the first version's dice made them move together, 10 November)
local function Frac(x) return x - math.floor(x) end
local function Roll(id, salt)
    local a = Frac(math.sin(id * 12.9898 + salt * 78.233) * 43758.5453)
    local b = Frac(math.sin(a * 93.9898 + salt * 47.233 + id * 0.731) * 24634.6345)
    return b * 2 - 1
end

-- (new traits go on the end: each one's roll depends on its place, so the
-- people the city already has keep the traits they had)
local TRAITS = { "brave", "temper", "loyal", "social", "hope",
    "greed", "compassion", "suspicion", "resilience", "pride", "vice" }
Psy.TRAITS = TRAITS

Psy.TRAIT_TEXT = {
    brave = { "bold", "timid" }, temper = { "hot-headed", "even-tempered" }, loyal = { "loyal to the Combine", "quietly disloyal" },
    social = { "sociable", "a loner" }, hope = { "hopeful", "despairing" }, greed = { "greedy", "generous" },
    compassion = { "kind-hearted", "cold" }, suspicion = { "suspicious", "trusting" }, resilience = { "tough", "fragile" },
    pride = { "proud", "humble" }, vice = { "fond of a drink and a smoke", "sober" },
}

function Psy.Traits(p)
    if p.tr then return p.tr end
    local t = {}
    for i, name in ipairs(TRAITS) do t[name] = Roll(p.id, i * 7) end
    if p.role == "cop" then t.loyal = 0.3 + 0.7 * math.abs(t.loyal) end -- the force picks the loyal
    if p.rebel then t.loyal = -math.abs(t.loyal) end
    p.tr = t -- (cached on the mind's record at run time)
    return t
end

-- The two or three things most true of someone, in words.
function Psy.TraitWords(p, n)
    local t = Psy.Traits(p)
    local list = {}
    for _, name in ipairs(TRAITS) do list[#list + 1] = name end
    table.sort(list, function(a, b) return math.abs(t[a]) > math.abs(t[b]) end)
    local out = {}
    for i = 1, math.min(n or 3, #list) do
        local name = list[i]
        if math.abs(t[name]) >= 0.4 then out[#out + 1] = Psy.TRAIT_TEXT[name][t[name] > 0 and 1 or 2] end
    end
    return out
end

------------------------------------------------------------------------
-- Thoughts: kind -> value, how long it lasts, and who it bends
------------------------------------------------------------------------
-- v is the mood it adds; tr scales it by traits (value * (1 + k * trait), never below zero)
local THOUGHTS = {
    fed          = { v = 3,   dur = 1800, text = "had a meal" },
    denied       = { v = -6,  dur = 3600, text = "was turned away from the ration line", tr = { pride = 0.4 } },
    slept        = { v = 2,   dur = 2400, text = "slept at home" },
    chatted      = { v = 1,   dur = 900,  text = "had a word with someone", tr = { social = 1 } },
    beaten       = { v = -12, dur = 7200, text = "was beaten", tr = { brave = -0.3, pride = 0.4 } },
    saw_beating  = { v = -4,  dur = 2400, text = "saw someone beaten", tr = { loyal = -0.7, compassion = 0.6 } },
    friend_beaten= { v = -7,  dur = 4800, text = "saw a friend beaten", tr = { compassion = 0.4 } },
    friend_died  = { v = -10, dur = 10800,text = "lost a friend", tr = { compassion = 0.3 } },
    saw_death    = { v = -5,  dur = 3600, text = "saw someone die", tr = { compassion = 0.5 } },
    arrested     = { v = -8,  dur = 5400, text = "was taken to the cells", tr = { pride = 0.5 } },
    friend_taken = { v = -6,  dur = 5400, text = "had a friend taken away", tr = { compassion = 0.4 } },
    kindness     = { v = 6,   dur = 3600, text = "was shown a kindness", tr = { greed = 0.3, suspicion = -0.4 } },
    propaganda   = { v = 2,   dur = 1200, text = "heard the Administrator", tr = { loyal = 2 } }, -- loyal +, disloyal -
    rumour       = { v = -2,  dur = 1800, text = "heard bad news", tr = { loyal = -0.6, suspicion = 0.3 } },
    guilt        = { v = -5,  dur = 3600, text = "feels guilty", tr = { temper = -0.8, compassion = 0.6 } },
    vented       = { v = 4,   dur = 1200, text = "let it out" },
    comforted    = { v = 5,   dur = 2400, text = "was comforted by a friend" },
    attacked     = { v = -6,  dur = 3600, text = "was attacked on duty", tr = { pride = 0.4 } },
    hurt         = { v = -6,  dur = 3600, text = "was hurt" },
    -- (10 November, the second set)
    stopped      = { v = -3,  dur = 2400, text = "was stopped and searched", tr = { pride = 1, loyal = -0.4 } },
    curfew       = { v = -2,  dur = 2400, text = "is shut in for the curfew", tr = { pride = 0.4, social = 0.4 } },
    lockdown     = { v = -4,  dur = 2400, text = "is locked down", tr = { brave = -0.4, resilience = -0.3 } },
    sweep        = { v = -3,  dur = 1800, text = "lived through a sweep", tr = { brave = -0.5 } },
    city_red     = { v = -3,  dur = 3600, text = "is frightened by the city's mood", tr = { brave = -0.5, resilience = -0.4 } },
    city_black   = { v = -6,  dur = 5400, text = "thinks the city is falling apart", tr = { loyal = 0.5, resilience = -0.4 } },
    relief       = { v = 3,   dur = 2400, text = "is relieved the city has calmed", tr = { loyal = 0.5 } },
    defiance_good= { v = 3,   dur = 1800, text = "saw someone stand up to them" },
    defiance_bad = { v = -2,  dur = 1800, text = "saw a poster of the Administrator defaced", tr = { loyal = 0.8 } },
    robbed       = { v = -4,  dur = 3600, text = "caught someone with a hand in their pocket", tr = { greed = 0.6, suspicion = 0.4 } },
    burned       = { v = -12, dur = 9000, text = "was beaten as a rat by the Resistance", tr = { pride = 0.4 } },
    snitched     = { v = 2,   dur = 2400, text = "reported someone to a unit", tr = { greed = 1, compassion = -1.2, loyal = 0.8 } },
    indulged     = { v = 3,   dur = 1800, text = "had a drink or a smoke", tr = { vice = 1 } },
    accused      = { v = -6,  dur = 4800, text = "was called an informer", tr = { pride = 0.5 } },
    steadied     = { v = 3,   dur = 1800, text = "was steadied by someone calm" },
}
Psy.THOUGHTS = THOUGHTS

local function Clamp(x, a, b) if x < a then return a elseif x > b then return b end return x end

local function ThoughtValue(p, kind)
    local d = THOUGHTS[kind]
    local v = d.v
    if d.tr then
        local t = Psy.Traits(p)
        for name, k in pairs(d.tr) do v = v * math.max(0, 1 + k * t[name]) end
    end
    return v
end

function Psy.State(p)
    local s = p.psy
    if s then return s end
    s = { food = 0.8, rest = 0.8, company = 0.7, crave = 0, stress = 0, th = {}, ties = {}, news = {}, last = 0, broke = -1e9 }
    p.psy = s
    return s
end

-- Something happened to them. who: the other person's id, if any.
function Psy.Think(p, kind, now, who)
    local s = Psy.State(p)
    if hook and hook.Run then hook.Run("LivingCityThought", p, kind, who) end -- (what they see, said out loud: sv_livingcity_voicecues.lua)
    local d = THOUGHTS[kind]
    local th = s.th
    for _, t in ipairs(th) do
        if t.k == kind and t.who == who then t.untilT = now + d.dur return t end -- refreshed, not stacked
    end
    local t = { k = kind, v = ThoughtValue(p, kind), untilT = now + d.dur, who = who }
    th[#th + 1] = t
    if #th > Psy.cfg.thoughtCap then -- the faintest goes
        local wi, wv = 1, math.huge
        for i, x in ipairs(th) do if math.abs(x.v) < wv then wi, wv = i, math.abs(x.v) end end
        table.remove(th, wi)
    end
    return t
end

------------------------------------------------------------------------
-- Ties and news
------------------------------------------------------------------------
function Psy.Tie(p, other) local s = p.psy return s and s.ties[other] or 0 end

function Psy.Bond(p, other, d)
    if not other or other == p.id or d == 0 then return end
    local ties = Psy.State(p).ties
    local v = Clamp((ties[other] or 0) + d, -10, 10)
    ties[other] = v ~= 0 and v or nil
    local n, wk, wv = 0, nil, math.huge
    for k, x in pairs(ties) do
        n = n + 1
        if math.abs(x) < wv then wk, wv = k, math.abs(x) end
    end
    if n > Psy.cfg.tieCap then ties[wk] = nil end
end

-- news: { k = kind, about = id (who did it), to = id (who it was done to), w = weight, hop = tellings }
function Psy.Hear(p, item, now)
    local s = Psy.State(p)
    for _, n in ipairs(s.news) do
        if n.k == item.k and n.about == item.about and n.to == item.to then return false end -- already knew
    end
    local n = { k = item.k, about = item.about, to = item.to, w = item.w, hop = item.hop, at = now }
    s.news[#s.news + 1] = n
    if #s.news > Psy.cfg.newsCap then table.remove(s.news, 1) end
    return n
end

------------------------------------------------------------------------
-- Mood and the step
------------------------------------------------------------------------
function Psy.Mood(p, now)
    local s = Psy.State(p)
    -- the same kind of thought from several people counts less each time
    -- (beaten by three units hurts more than by one, not three times as much)
    local m, seen = 0, {}
    for _, t in ipairs(s.th) do
        local n = seen[t.k] or 0
        seen[t.k] = n + 1
        m = m + t.v / (n + 1) ^ 1.5
    end
    if s.food < 0.35 then m = m - 10 * (0.35 - s.food) / 0.35 end
    if s.rest < 0.3 then m = m - 6 * (0.3 - s.rest) / 0.3 end
    if s.company < 0.25 then m = m - 4 * (0.25 - s.company) / 0.25 end
    local vice = Psy.Traits(p).vice
    if vice > 0 and (s.crave or 0) > 0.6 then m = m - 8 * vice * ((s.crave - 0.6) / 0.4) end
    return m
end

local function Strongest(s)
    local best, bw
    for _, n in ipairs(s.news) do
        if n.hop < 3 and (not bw or math.abs(n.w) > bw) then best, bw = n, math.abs(n.w) end
    end
    return best
end

-- One person's turn. ctx: the game (or the test city). Returns what they did, if anything.
--   ctx.Partner(p)      someone they could talk to now, or nil
--   ctx.Person(id)      the record for an id
--   ctx.Break(p, kind)  something gave (or they were inspired); the game makes it seen
function Psy.Step(p, now, ctx)
    local s = Psy.State(p)
    local t = Psy.Traits(p)
    local dt = s.last > 0 and math.min(now - s.last, 600) or 0
    s.last = now
    local day = Psy.cfg.day

    -- needs fall with time (the game raises them when they eat, sleep, talk, drink)
    s.food = math.max(0, s.food - dt / (day * 0.9))
    s.rest = math.max(0, s.rest - dt / (day * 1.1))
    s.company = math.max(0, s.company - dt / (day * 0.5))
    if t.vice > 0 then s.crave = math.min(1, (s.crave or 0) + dt * t.vice / (day * 0.5)) end

    -- feelings about people fade without fresh cause (a point a day, the
    -- small ones go first): grudges cool, friendships need keeping up
    if dt > 0 then
        s.fade = (s.fade or 0) + dt / day
        if s.fade >= 1 then
            s.fade = s.fade - 1
            for id, v in pairs(s.ties) do
                local nv = v > 0 and v - 1 or v + 1
                s.ties[id] = nv ~= 0 and nv or nil
            end
        end
    end

    -- thoughts wear off
    local th = s.th
    for i = #th, 1, -1 do if th[i].untilT <= now then table.remove(th, i) end end

    -- stress: the tough take longer to wear down and get over it sooner
    local mood = Psy.Mood(p, now)
    s.mood = mood
    if mood < 0 then s.stress = math.min(Psy.cfg.stressCap, s.stress - mood * dt / 400 * (1 - 0.5 * t.resilience))
    else s.stress = math.max(0, s.stress - (mood + 1) * dt / 400 * (1 + 0.5 * t.resilience)) end

    -- a word with someone: company, a tie, and whatever news they carry
    if ctx.Partner and math.random() < 0.25 + 0.2 * t.social then
        local q = ctx.Partner(p)
        if q then Psy.Chat(p, q, now, ctx) end
    end

    -- something gives
    if s.stress >= Psy.cfg.breakAt and now - s.broke > Psy.cfg.breakCool then
        s.broke = now
        local kind = Psy.ChooseBreak(p, ctx)
        if ctx.Break then ctx.Break(p, kind) end
        s.stress = s.stress * 0.45
        if kind == "binge" then s.crave = 0 end
        return kind
    end
    -- or, at peace, they lift someone else (the kind-hearted more often)
    if mood > 8 and s.stress < 2 and now - s.broke > Psy.cfg.breakCool and math.random() < 0.05 + 0.05 * t.compassion then
        s.broke = now - Psy.cfg.breakCool * 0.5
        local kind = Psy.ChooseInspiration(p, ctx)
        if ctx.Break then ctx.Break(p, kind) end
        return kind
    end
end

function Psy.Chat(p, q, now, ctx)
    local sp, sq = Psy.State(p), Psy.State(q)
    sp.company = math.min(1, sp.company + 0.35)
    sq.company = math.min(1, sq.company + 0.35)
    local tp, tq = Psy.Traits(p), Psy.Traits(q)
    -- like and like: loyal with loyal, the hopeful with the hopeful; the suspicious warm slowly
    local fit = 1 - (math.abs(tp.loyal - tq.loyal) + math.abs(tp.hope - tq.hope)) / 2
    local d = fit > 0.3 and 1 or (fit < -0.3 and -1 or 0)
    if d > 0 and math.random() < 0.5 * tp.suspicion then d = 0 end
    Psy.Bond(p, q.id, d)
    d = fit > 0.3 and 1 or (fit < -0.3 and -1 or 0)
    if d > 0 and math.random() < 0.5 * tq.suspicion then d = 0 end
    Psy.Bond(q, p.id, d)
    Psy.Think(p, "chatted", now) Psy.Think(q, "chatted", now)
    -- a friend in a bad way is comforted (by the kind-hearted more often)
    if Psy.Tie(p, q.id) >= 4 and sq.stress > Psy.cfg.frayed and math.random() < 0.4 + 0.3 * tp.compassion then
        Psy.Think(q, "comforted", now, p.id)
        sq.stress = sq.stress * 0.8
    end
    -- the news goes both ways, weaker each time; the trusting believe anyone
    -- who isn't an enemy, the suspicious only a friend
    for _, pair in ipairs({ { p, q }, { q, p } }) do
        local a, b = pair[1], pair[2]
        local n = Strongest(Psy.State(a))
        local need = math.max(0, 3 * Psy.Traits(b).suspicion)
        if n and Psy.Tie(b, a.id) >= need and n.about ~= b.id then
            local heard = Psy.Hear(b, { k = n.k, about = n.about, to = n.to, w = n.w * 0.6, hop = n.hop + 1 }, now)
            if heard then Psy.OnNews(b, heard, now, ctx) end
        end
    end
end

-- What a piece of news does to the one who hears it.
function Psy.OnNews(p, n, now, ctx)
    local t = Psy.Traits(p)
    if n.k == "beating" or n.k == "killing" or n.k == "burning" then
        Psy.Bond(p, n.about, -3 * n.w * (1 + 0.5 * t.compassion))
        if Psy.Tie(p, n.to) >= 3 then Psy.Think(p, "friend_beaten", now, n.to)
        else Psy.Think(p, "rumour", now, n.about) end
    elseif n.k == "informer" or n.k == "accused" then
        -- the suspicious believe it more readily
        Psy.Bond(p, n.about, -(n.k == "informer" and 6 or 3) * n.w * (1 + 0.5 * t.suspicion))
        if Psy.Tie(p, n.to) >= 3 then Psy.Think(p, "rumour", now, n.about) end
    elseif n.k == "kindness" then
        Psy.Bond(p, n.about, 2 * n.w)
    end
    if ctx.Heard then ctx.Heard(p, n) end
end

------------------------------------------------------------------------
-- Breaking: how a person gives way, by who they are
------------------------------------------------------------------------
local function Pick(w)
    local total = 0
    for _, x in pairs(w) do total = total + math.max(0, x) end
    if total <= 0 then return next(w) end
    local r = math.random() * total
    for k, x in pairs(w) do
        r = r - math.max(0, x)
        if r <= 0 then return k end
    end
    return next(w)
end
Psy.Pick = Pick

function Psy.ChooseBreak(p, ctx)
    local t = Psy.Traits(p)
    local s = Psy.State(p)
    local grudge = 0
    for id, v in pairs(s.ties) do
        local q = ctx.Person and ctx.Person(id)
        if q and q.role == "cop" and v < grudge then grudge = v end
    end
    local craving = t.vice > 0 and (s.crave or 0) or 0
    local hungry = s.food < 0.3 and 1 or 0
    if p.role == "cop" then
        return Pick({
            brutal = 1 + 2 * t.temper + 0.5 * t.pride - t.compassion,  -- takes it out on the street
            drink  = 0.4 - 0.5 * t.temper + 2 * math.max(0, t.vice),   -- drinks on duty
            leak   = (1 - t.loyal) * 1.5 + hungry + 0.5 * t.compassion, -- quietly helps the Resistance
        })
    end
    return Pick({
        tantrum  = 0.5 + 1.5 * t.temper,                             -- shouts at a unit, kicks a bin
        despair  = 0.5 - 1.5 * t.hope - 0.5 * t.resilience,          -- won't work, won't queue
        defy     = (t.brave + 0.2) * (1 - t.loyal) + (-grudge / 5) + 0.5 * t.pride, -- a poster, a wall, the Resistance
        inform   = (0.6 - t.brave) * (0.5 + t.loyal) + hungry * 0.8 + t.greed - 0.5 * t.compassion, -- buys favour with a name
        seek     = 0.3 + t.social,                                    -- goes looking for a friend
        hoard    = 1.2 * t.greed + hungry,                            -- keeps food back, takes more than their share
        accuse   = 1.5 * t.suspicion - 0.3,                           -- calls someone an informer
        sabotage = t.pride * (1 - t.loyal) * 0.8 + 0.4 * t.brave,     -- quietly spoils their Union work
        binge    = 2.5 * craving * math.max(0, t.vice),               -- drinks and smokes everything they have
    })
end

function Psy.ChooseInspiration(p, ctx)
    local t = Psy.Traits(p)
    return Pick({
        share   = 0.6 + t.compassion - 0.5 * t.greed,                 -- shares their ration with a hungry friend
        shelter = (t.compassion + t.brave) * (1 - t.loyal) * 0.5,     -- would hide someone the Combine wants
        steady  = 0.3 + t.resilience + 0.5 * t.social,                -- calms the frightened around them
    })
end

------------------------------------------------------------------------
-- What the game asks: how should their ordinary choices bend right now?
-- (the ChooseCitizenTask chances, multiplied; not used yet)
------------------------------------------------------------------------
function Psy.Bias(p)
    local s = p.psy
    if not s then return nil end
    local t = Psy.Traits(p)
    local frayed = Clamp((s.stress - 4) / (Psy.cfg.breakAt - 4), 0, 1)
    return {
        line   = s.food < 0.4 and 1.8 or 1,                 -- hungry: the queue
        sit    = 1 + frayed * (t.hope < 0 and 1.5 or 0.5),  -- worn down: benches
        work   = 1 - frayed * 0.6,                          -- and less work
        home   = 1 + frayed * (t.brave < 0 and 1.2 or 0),   -- the timid go home
        avoidCops = frayed > 0.5 and t.brave < 0.2,         -- and keep away from units
        chatty = s.company < 0.3 and 2 or 1,
    }
end

-- How the whole city feels: a number the city's mood could listen to.
function Psy.Unrest(people)
    local sum, n = 0, 0
    for _, p in ipairs(people) do
        if p.alive ~= false and p.role == "citizen" and p.psy then
            local t = Psy.Traits(p)
            sum = sum + math.min(1, p.psy.stress / Psy.cfg.breakAt) * (1 - t.loyal) / 2
            n = n + 1
        end
    end
    return n > 0 and sum / n or 0
end

-- What a person is feeling, in words (for talking to them, the debug report, the editor).
function Psy.Describe(p, now, name)
    local s = Psy.State(p)
    local parts = {}
    table.sort(s.th, function(a, b) return math.abs(a.v) > math.abs(b.v) end)
    for i = 1, math.min(3, #s.th) do
        local x = s.th[i]
        parts[#parts + 1] = THOUGHTS[x.k].text .. (x.who and name and (" (" .. name(x.who) .. ")") or "")
    end
    if Psy.Traits(p).vice > 0 and (s.crave or 0) > 0.6 then parts[#parts + 1] = "craving a drink or a smoke" end
    return string.format("mood %+.0f, stress %.0f: %s", s.mood or 0, s.stress, table.concat(parts, "; "))
end

return Psy
