--[[
    A pretend city to run the city's minds in (sv_livingcity_psyche.lua, the gamemode's own): the roster's 30 citizens and 10 units
    in three districts, a week of days. Rations, curfew, units who lose their
    temper, deaths, a "player" who hands out food now and then, the
    Administrator on the screens. Everything the real game would feed in.
]]
local Psy = dofile(PSY_PATH)

local City = {}
local SEED, DAYS, CITIZENS, COPS, STEP_EVERY, PER_STEP = ...
math.randomseed(SEED or 7)
DAYS, CITIZENS, COPS = DAYS or 7, CITIZENS or 30, COPS or 10
STEP_EVERY, PER_STEP = STEP_EVERY or 0.5, PER_STEP or 1

local FIRST = { "Alyx", "Dara", "Ivan", "Mira", "Oleg", "Nina", "Pavel", "Sasha", "Tomas", "Vera", "Yuri", "Lena", "Boris", "Katya",
    "Milo", "Irena", "Gregor", "Anya", "Felix", "Rosa", "Anton", "Hana", "Lev", "Zoya", "Emil", "Olga", "Petr", "Sonia", "Viktor", "Ilse",
    "Marek", "Ada", "Kurt", "Eva", "Jonas", "Lidia", "Stefan", "Tanya", "Roman", "Nadia" }
local LAST = { "Novak", "Petrov", "Kral", "Weiss", "Horak", "Sokol", "Brandt", "Lenz", "Moravec", "Fischer", "Volkov", "Dvorak" }

local people, byId, nextId = {}, {}, 1
local function NewPerson(role)
    local p = { id = nextId, role = role, alive = true }
    nextId = nextId + 1
    if role == "cop" then
        local n repeat n = math.random(10, 99) until not byId["u" .. n]
        byId["u" .. n] = true
        p.name = "Unit " .. n
    else
        p.name = FIRST[math.random(#FIRST)] .. " " .. LAST[math.random(#LAST)]
        p.rebel = math.random() < 0.12 or nil
    end
    p.district = math.random(3)
    people[#people + 1] = p
    byId[p.id] = p
    Psy.State(p)
    return p
end
for _ = 1, CITIZENS do NewPerson("citizen") end
for _ = 1, COPS do NewPerson("cop") end

local now = 0
local DAY = Psy.cfg.day
local log, counts = {}, {}
local function Clock()
    local d = math.floor(now / DAY) + 1
    local m = math.floor((now % DAY) / DAY * 1440)
    return string.format("Day %d %02d:%02d", d, math.floor(m / 60), m % 60)
end
local function Log(fmt, ...) log[#log + 1] = Clock() .. "  " .. string.format(fmt, ...) end
local function Count(k) counts[k] = (counts[k] or 0) + 1 end
local function Name(id) local p = byId[id] return p and p.name or "someone" end

local function Living(role, district, except)
    local out = {}
    for _, p in ipairs(people) do
        if p.alive and (not role or p.role == role) and (not district or p.district == district) and p ~= except and not p.jailedUntil then
            out[#out + 1] = p
        end
    end
    return out
end
local function Any(t) return t[math.random(#t)] end

-- the news, told by whoever saw it
local function Witnesses(where, except, n, item, thought)
    local near = Living(nil, where, except)
    for _ = 1, math.min(n, #near) do
        local w = table.remove(near, math.random(#near))
        if w.role == "citizen" then
            if thought then Psy.Think(w, Psy.Tie(w, item.to) >= 3 and "friend_beaten" or thought, now, item.about) end
            local h = Psy.Hear(w, item, now)
            if h then Psy.Bond(w, item.about, -2) end
        end
    end
end

local function Arrest(p, by, why)
    if not p then return end
    if p.sheltered then p.sheltered = nil Log("  ...but %s is hidden, and the units find nobody", p.name) Count("sheltered_saved") return end
    p.jailedUntil = now + DAY * 0.15
    p.arrests = (p.arrests or 0) + 1
    Psy.Think(p, "arrested", now, by and by.id)
    if by then Psy.Bond(p, by.id, -4) end
    for _, q in ipairs(people) do
        if q.alive and q ~= p and Psy.Tie(q, p.id) >= 3 then Psy.Think(q, "friend_taken", now, p.id) end
    end
    Log("%s is taken to the cells (%s)", p.name, why)
    Count("arrests")
end

local function Kill(p, by, how)
    p.alive = false
    Count("deaths")
    Log("%s dies (%s)", p.name, how)
    for _, q in ipairs(people) do
        if q.alive and Psy.Tie(q, p.id) >= 3 then
            Psy.Think(q, "friend_died", now, p.id)
            if by then Psy.Bond(q, by.id, -5) end
        end
    end
    if by then Witnesses(p.district, p, 2, { k = "killing", about = by.id, to = p.id, w = 1, hop = 0 }, "saw_death") end
    local n = NewPerson(p.role)
    Log("%s arrives in the city", n.name)
end

local function Beating(cop, victim, why)
    Count("beatings")
    Psy.Think(victim, "beaten", now, cop.id)
    Psy.Bond(victim, cop.id, -6)
    Log("%s beats %s (%s)", cop.name, victim.name, why)
    if Psy.Traits(cop).temper < 0 then Psy.Think(cop, "guilt", now, victim.id) end
    Witnesses(victim.district, victim, math.random(0, 3), { k = "beating", about = cop.id, to = victim.id, w = 1, hop = 0 }, "saw_beating")
    if math.random() < 0.01 then Kill(victim, cop, "beaten to death by " .. cop.name) end
end

-- what a break looks like in the city
local ctx = {}
function ctx.Person(id) return byId[id] end
function ctx.Partner(p)
    if p.jailedUntil then return nil end
    -- a friend first, if one's about, else whoever's near
    local near = Living(p.role, p.district, p)
    if #near == 0 then return nil end
    for _ = 1, 3 do
        local q = Any(near)
        if Psy.Tie(p, q.id) > 0 then return q end
    end
    return Any(near)
end
function ctx.Break(p, kind)
    Count(kind)
    p.did = p.did or {}
    p.did[kind] = (p.did[kind] or 0) + 1
    local t = Psy.Traits(p)
    local s = p.psy
    local why = Psy.Describe(p, now, Name)
    if kind == "tantrum" then
        local cop = Any(Living("cop", p.district))
        if cop then
            Log("%s snaps and screams at %s  [%s]", p.name, cop.name, why)
            Psy.Think(p, "vented", now)
            if math.random() < 0.5 + 0.3 * Psy.Traits(cop).temper then Beating(cop, p, "talking back")
            else Arrest(p, cop, "disturbing the peace") end
        else
            Log("%s kicks a bin over and swears at nobody  [%s]", p.name, why)
            Psy.Think(p, "vented", now)
        end
    elseif kind == "despair" then
        p.despairUntil = now + DAY * 0.3
        Log("%s sits down on a bench and won't get up  [%s]", p.name, why)
    elseif kind == "defy" then
        local worst, wv
        for id, v in pairs(s.ties) do local q = byId[id] if q and q.role == "cop" and (not wv or v < wv) then worst, wv = q, v end end
        if not p.rebel and (wv or 0) <= -6 and math.random() < 0.5 then
            p.rebel = true
            t.loyal = -math.abs(t.loyal)
            Log("%s goes to the Resistance, because of %s  [%s]", p.name, worst.name, why)
            Count("joined_resistance")
        else
            Log("%s paints over a poster of the Administrator  [%s]", p.name, why)
            if math.random() < 0.3 then Arrest(p, Any(Living("cop", p.district)), "defacing") end
        end
        Psy.Think(p, "vented", now)
    elseif kind == "inform" then
        -- someone they don't like, or a rebel they know of
        local target, tv
        for id, v in pairs(s.ties) do
            local q = byId[id]
            if q and q.alive and q.role == "citizen" and not q.jailedUntil then
                local score = (q.rebel and v >= 3 and 4 or 0) - v
                if not tv or score > tv then target, tv = q, score end
            end
        end
        target = target or Any(Living("citizen", p.district, p))
        if target then
            Log("%s whispers %s's name to a unit, for a meal  [%s]", p.name, target.name, why)
            p.informed = (p.informed or 0) + 1
            s.food = math.min(1, s.food + 0.5)
            Psy.Think(p, "fed", now)
            Arrest(target, Any(Living("cop")), target.rebel and "named as a Resistance sympathizer" or "named by an informant")
            if math.random() < 0.35 then -- someone saw who it was
                Witnesses(p.district, p, 2, { k = "informer", about = p.id, to = target.id, w = 1, hop = 0 })
                Psy.Hear(target, { k = "informer", about = p.id, to = target.id, w = 1, hop = 0 }, now)
                Psy.Bond(target, p.id, -8)
                Log("  ...and %s finds out who named them", target.name)
            end
        end
    elseif kind == "seek" then
        local best, bv
        for id, v in pairs(s.ties) do local q = byId[id] if q and q.alive and q.role == "citizen" and (not bv or v > bv) then best, bv = q, v end end
        if best and bv > 0 then
            Log("%s goes looking for %s and talks for hours  [%s]", p.name, best.name, why)
            Psy.Think(p, "comforted", now, best.id)
            s.stress = s.stress * 0.6
        else
            Log("%s wanders the streets alone, looking for anyone to talk to  [%s]", p.name, why)
        end
    elseif kind == "hoard" then
        -- keeps food back: the hungriest near them go short, and someone notices
        s.food = math.min(1, s.food + 0.4)
        local near = Living("citizen", p.district, p)
        for _ = 1, math.min(2, #near) do local q = table.remove(near, math.random(#near)) q.psy.food = math.max(0, q.psy.food - 0.15) Psy.Bond(q, p.id, -2) end
        Log("%s hoards food and takes more than their share  [%s]", p.name, why)
    elseif kind == "accuse" then
        local target, tv
        for id, v in pairs(s.ties) do local q = byId[id] if q and q.alive and q.role == "citizen" and (not tv or v < tv) then target, tv = q, v end end
        target = target or Any(Living("citizen", p.district, p))
        if target then
            local right = target.informed and target.informed > 0
            Log("%s calls %s an informer, in the street%s  [%s]", p.name, target.name, right and " (and they're right)" or "", why)
            Psy.Think(target, "accused", now, p.id) Psy.Bond(target, p.id, -5)
            Witnesses(p.district, target, 2, { k = right and "informer" or "accused", about = target.id, to = p.id, w = 1, hop = 0 })
            Count(right and "accuse_right" or "accuse_wrong")
        end
    elseif kind == "sabotage" then
        Log("%s quietly spoils their Union work  [%s]", p.name, why)
        Psy.Think(p, "vented", now)
        if math.random() < 0.2 then Arrest(p, Any(Living("cop", p.district)), "sabotage") end
    elseif kind == "binge" then
        Log("%s drinks and smokes everything they have  [%s]", p.name, why)
        s.food = math.max(0, s.food - 0.2)
        Psy.Think(p, "indulged", now)
        if math.random() < 0.35 then Arrest(p, Any(Living("cop", p.district)), "drunk in public") end
    elseif kind == "shelter" then
        local best, bv
        for id, v in pairs(s.ties) do local q = byId[id] if q and q.alive and q.role == "citizen" and q.rebel and (not bv or v > bv) then best, bv = q, v end end
        if best and bv > 0 then
            best.sheltered = true
            Log("%s hides %s from the units for the night", p.name, best.name)
            Psy.Bond(best, p.id, 4) Psy.Think(best, "kindness", now, p.id)
        else Count("shelter_nobody") end
    elseif kind == "steady" then
        local near = Living("citizen", p.district, p)
        for _, q in ipairs(near) do if q.psy.stress > Psy.cfg.frayed and math.random() < 0.5 then q.psy.stress = q.psy.stress * 0.8 Psy.Think(q, "steadied", now, p.id) end end
        Log("%s keeps calm and steadies the frightened around them", p.name)
    elseif kind == "share" then
        -- shares food with the hungriest friend
        local best, bf
        for id, v in pairs(s.ties) do
            local q = byId[id]
            if q and q.alive and q.role == "citizen" and v > 0 and q.psy and (not bf or q.psy.food < bf) then best, bf = q, q.psy.food end
        end
        if best and bf < 0.5 then
            Log("%s, in good spirits, shares their ration with %s", p.name, best.name)
            best.psy.food = math.min(1, best.psy.food + 0.4)
            Psy.Think(best, "kindness", now, p.id)
            Psy.Bond(best, p.id, 3)
            Psy.Hear(best, { k = "kindness", about = p.id, to = best.id, w = 1, hop = 0 }, now)
        else Count("share_nobody") end
    elseif kind == "brutal" then
        local v = Any(Living("citizen", p.district))
        -- someone they've a grudge against, if one's about
        for id, x in pairs(s.ties) do local q = byId[id] if q and q.alive and q.role == "citizen" and x <= -3 and not q.jailedUntil then v = q break end end
        if v then Log("%s has had enough and takes it out on the street  [%s]", p.name, why) Beating(p, v, "no reason given") end
    elseif kind == "drink" then
        Log("%s is drinking on duty  [%s]", p.name, why)
        Psy.Think(p, "vented", now)
    elseif kind == "leak" then
        Log("%s quietly leaves a patrol route where the Resistance will find it  [%s]", p.name, why)
        Count("cop_leaks")
    end
end
function ctx.Heard(p, n)
    Count("news_passed")
    if n.k == "informer" and n.hop <= 2 then Count("informer_news") end
end

------------------------------------------------------------------------
-- The week
------------------------------------------------------------------------
local stepT, idx = 0, 0
local stepCost, stepCalls, stepMax = 0, 0, 0
local clock = os.clock
local shortDay = {}
local nextBroadcast, nextKind = DAY * 0.1, DAY * 0.05
local lastPhase = -1
local TICK = 0.5
local curfewDone, lastSocio = {}, nil

local unrestByDay = {}
while now < DAYS * DAY do
    now = now + TICK
    local f = (now % DAY) / DAY
    local d = math.floor(now / DAY)
    if shortDay[d] == nil then shortDay[d] = math.random() < 0.3 if shortDay[d] then Log("short rations today") end end

    -- rations, morning and evening
    local phase = (f > 0.3 and f < 0.31) and 1 or ((f > 0.7 and f < 0.71) and 2 or 0)
    if phase ~= 0 and phase ~= lastPhase then
        for _, p in ipairs(Living("citizen")) do
            if not p.despairUntil or p.despairUntil < now then
                if shortDay[d] and math.random() < 0.35 then Psy.Think(p, "denied", now)
                elseif math.random() < 0.85 then p.psy.food = math.min(1, p.psy.food + 0.55) Psy.Think(p, "fed", now) end
            end
        end
    end
    lastPhase = phase
    -- night: home and sleep (most of them)
    if f > 0.9 or f < 0.2 then
        for _, p in ipairs(people) do
            if p.alive and p.role == "citizen" and math.random() < TICK / 300 then p.psy.rest = math.min(1, p.psy.rest + 0.25) Psy.Think(p, "slept", now) end
        end
    else
        for _, p in ipairs(people) do -- cops rest by shift
            if p.alive and p.role == "cop" and math.random() < TICK / 900 then p.psy.rest = math.min(1, p.psy.rest + 0.3) end
        end
    end
    -- out of the cells
    for _, p in ipairs(people) do if p.jailedUntil and p.jailedUntil < now then p.jailedUntil = nil end end

    -- units on the street: their temper, their stress, their grudges
    for _, cop in ipairs(Living("cop")) do
        local t = Psy.Traits(cop)
        local rate = (BRUT or 1) * (0.6 + 0.5 * t.temper + cop.psy.stress / 40) / (DAY * 2.5)
        if math.random() < rate * TICK then
            local v = Any(Living("citizen", cop.district))
            if v then Beating(cop, v, Psy.Tie(cop, v.id) < 0 and "a grudge" or "failing to comply") end
        end
    end
    -- the Resistance's citizens hit back now and then
    for _, p in ipairs(Living("citizen")) do
        if p.rebel and math.random() < TICK / (DAY * 3) then
            local cop = Any(Living("cop", p.district))
            if cop then
                Log("%s ambushes %s", p.name, cop.name) Count("ambushes")
                Psy.Think(cop, "attacked", now, p.id) Psy.Bond(cop, p.id, -6)
                if math.random() < 0.5 then Arrest(p, cop, "attacking a unit") end
            end
        end
    end
    -- the city kills people sometimes
    if math.random() < TICK / (DAY * 3) then Kill(Any(Living("citizen")), nil, "a headcrab in the canals") end
    -- a player passing by hands someone food
    if math.random() < (KIND or 1) * TICK / (DAY * 0.4) then
        local hungriest, hf
        for _, p in ipairs(Living("citizen")) do if not hf or p.psy.food < hf then hungriest, hf = p, p.psy.food end end
        if hungriest then
            hungriest.psy.food = math.min(1, hungriest.psy.food + 0.5)
            Psy.Think(hungriest, "kindness", now) Count("player_kindness")
        end
    end
    -- units stop and search people in the street
    for _, cop in ipairs(Living("cop")) do
        if math.random() < TICK / (DAY * 0.4) then
            local v = Any(Living("citizen", cop.district))
            if v then Psy.Think(v, "stopped", now, cop.id) Psy.Bond(v, cop.id, -1) Count("stops") end
        end
    end
    -- curfew every night, a lockdown now and then
    if f > 0.9 and not curfewDone[d] then
        curfewDone[d] = true
        local kind = math.random() < 0.15 and "lockdown" or "curfew"
        for _, p in ipairs(Living("citizen")) do Psy.Think(p, kind, now) end
        Count(kind)
    end
    -- the city's mood (sociostability) follows how the people feel
    local u = Psy.Unrest(people)
    local socio = u > 0.55 and "red" or "green"
    if socio ~= lastSocio then
        for _, p in ipairs(Living("citizen")) do Psy.Think(p, socio == "red" and "city_red" or "relief", now) end
        if lastSocio then Log("the city turns %s", socio) Count("socio_" .. socio) end
        lastSocio = socio
    end
    -- someone paints over a poster (a player, or a sympathizer)
    if math.random() < TICK / (DAY * 0.5) then
        local where = math.random(3)
        for _, w in ipairs(Living("citizen", where)) do
            if math.random() < 0.4 then Psy.Think(w, Psy.Traits(w).loyal < 0 and "defiance_good" or "defiance_bad", now) end
        end
        Count("posters_defaced")
    end
    -- a pickpocket caught at it
    if math.random() < TICK / (DAY * 0.5) then
        local v = Any(Living("citizen"))
        if v then Psy.Think(v, "robbed", now) Count("pickpocket_caught") end
    end
    -- at home, those with the weakness drink and smoke when they can, and it costs them food
    for _, p in ipairs(people) do
        if p.alive and not p.jailedUntil and Psy.Traits(p).vice > 0 and p.psy.crave > 0.5 and math.random() < TICK / 400 then
            p.psy.crave = 0
            p.psy.food = math.max(0, p.psy.food - 0.08)
            Psy.Think(p, "indulged", now)
            Count("indulged")
        end
    end

    -- the Administrator on the screens
    if now > nextBroadcast then
        nextBroadcast = now + DAY / 3
        for _, p in ipairs(Living("citizen")) do Psy.Think(p, "propaganda", now) end
    end

    -- THE PART THAT WOULD SHIP: one person (or PER_STEP) every STEP_EVERY seconds
    stepT = stepT + TICK
    while stepT >= STEP_EVERY do
        stepT = stepT - STEP_EVERY
        for _ = 1, PER_STEP do
            idx = idx % #people + 1
            local p = people[idx]
            if p.alive and not p.jailedUntil then
                local c0 = clock()
                Psy.Step(p, now, ctx)
                p.stressSum, p.steps = (p.stressSum or 0) + p.psy.stress, (p.steps or 0) + 1
                local c = clock() - c0
                stepCost, stepCalls = stepCost + c, stepCalls + 1
                if c > stepMax then stepMax = c end
            end
        end
    end

    if math.floor((now - TICK) / DAY) ~= d then end
    if (now % DAY) < TICK then unrestByDay[#unrestByDay + 1] = Psy.Unrest(people) end
end
unrestByDay[#unrestByDay + 1] = Psy.Unrest(people)

-- every citizen who lived through the run, with their traits and what they did (for analyze_traits.py)
local recs = {}
for _, p in ipairs(people) do
    if p.role == "citizen" then
        local r = { stress = p.psy.stress, informed = p.informed or 0, rebel = p.rebel and 1 or 0, arrests = p.arrests or 0 }
        for _, k in ipairs(Psy.TRAITS) do r["t_" .. k] = p.tr and p.tr[k] or 0 end
        for k, v in pairs(p.did or {}) do r["b_" .. k] = v end
        r.stress_sum, r.steps = p.stressSum or 0, p.steps or 0
        recs[#recs + 1] = r
    end
end
City.recs = recs
City.log, City.counts, City.unrest = log, counts, unrestByDay
City.cost = { calls = stepCalls, avg_us = stepCost / math.max(1, stepCalls) * 1e6, max_us = stepMax * 1e6 }
-- a few people as they stand at the end
local snap = {}
local sorted = {}
for _, p in ipairs(people) do if p.alive then sorted[#sorted + 1] = p end end
table.sort(sorted, function(a, b) return a.psy.stress > b.psy.stress end)
for i = 1, math.min(6, #sorted) do
    local p = sorted[i]
    local t = p.tr
    local ties = {}
    for id, v in pairs(p.psy.ties) do if math.abs(v) >= 4 then ties[#ties + 1] = string.format("%s %+d", Name(id), v) end end
    snap[#snap + 1] = string.format("%-16s %s%s brave %+.1f temper %+.1f loyal %+.1f hope %+.1f | %s | feels strongly about: %s",
        p.name, p.role == "cop" and "(unit) " or "", p.rebel and "(rebel) " or "", t.brave, t.temper, t.loyal, t.hope,
        Psy.Describe(p, now, Name), #ties > 0 and table.concat(ties, ", ") or "nobody")
end
City.snap = snap
City.people = #people
return City
