--[[
    Living City: stand-ins, so no dream is ever thin

    The owner, 8 November: "every dream needs a minimum of several human
    players, which are filled in by NPCs if human players are not available
    ... let's make it 6 for now".

    Every dream has at least lc_dream_min (6) dreamers. When fewer real
    players are asleep for it, the city's own named people (LC.People, the
    ones not out on the streets; made-up names when there aren't enough)
    dream it with them. A dream with nobody real asleep doesn't happen at all
    (as before). Enforcers (Civil Protection and the Administration, in a
    nightmare or a propaganda dream: sv_livingcity_dreamenforcers.lua) don't
    count: they watch over a dream, they don't dream it.

      In a dream you play: they play along, in a simple way. Each one runs
      about near the start, now and then loses a life (a red flash, back to
      where they began), and most drop out of it before the end (a puff, and
      a line in chat). They never touch the game itself: they take no
      tokens, block nobody, and never take a win from a real player.
      The Loyalty Quiz seats its own (they answer in chat, and the rebel is
      dragged off: sv_livingcity_propagandadreams.lua), up to the same
      number.

      In an ending: they stand about in the dream with the dreamers (the
      ending brings its own crowd as well).

    Either way their names go up in chat as the dream begins ("Also
    dreaming: ..."), and they say something now and then. Everything they
    are is removed when the dream ends.

      lc_dream_min (6; 0 turns stand-ins off)
]]

if CLIENT then return end

LC = LC or {}

local FLAGS = bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED)
local cvMin = CreateConVar("lc_dream_min", "6", FLAGS, "Every dream has at least this many dreamers: the city's own people fill in for missing players (0: no stand-ins)")

function LC.DreamMin() return math.max(0, cvMin:GetInt()) end

local MODELS = { "models/humans/group01/male_02.mdl", "models/humans/group01/female_01.mdl", "models/humans/group01/male_07.mdl",
    "models/humans/group01/female_04.mdl", "models/humans/group01/male_04.mdl", "models/humans/group01/female_06.mdl" }

-- What they say now and then, by the dream's mood.
LC.DreamStandinLines = {
    nightmare = { "Keep moving! Don't let it catch you!", "This isn't real. This isn't real.", "I can't feel my legs...", "Which way? Which way?!",
        "I want to wake up!", "Stay together!", "Don't look back.", "Why is it always us?" },
    happy = { "Isn't she wonderful?", "I've never been so happy.", "Glory to the Administrator!", "What a lovely dream.", "I could stay here forever.",
        "Thank you! Thank you!", "Look at her!" },
    neutral = { "Where are we?", "This is strange.", "Is anyone else seeing this?", "I don't remember falling asleep.", "Huh.", "Stay close." },
}

-- The city's own named citizens (alive, not out on the streets), or made-up names.
local function People(n)
    local out, pool = {}, {}
    for _, pp in ipairs(LC.People and LC.People.list or {}) do
        if pp.alive and pp.role ~= "cop" and pp.name and not IsValid(pp.npc) then pool[#pool + 1] = pp end
    end
    for i = 1, n do
        if #pool > 0 then
            local pp = table.remove(pool, math.random(#pool))
            out[i] = { name = pp.name, model = pp.model or MODELS[i % #MODELS + 1] }
        else
            local male = math.random() < 0.5
            out[i] = { name = LC.NewCharacterName and LC.NewCharacterName(male and "male" or "female") or ("Citizen " .. math.random(100, 999)),
                model = MODELS[i % #MODELS + 1] }
        end
    end
    return out
end
LC.DreamStandinPeople = People

local function Dreamers(dream)
    local out = {}
    for _, p in ipairs(LC.DreamersOf and LC.DreamersOf(dream) or dream.list or {}) do
        if IsValid(p) and not p.lcDreamEnforcer then out[#out + 1] = p end
    end
    return out
end
local function Chat(dream, text)
    for _, p in ipairs(LC.DreamersOf and LC.DreamersOf(dream) or dream.list or {}) do
        if IsValid(p) and p.ChatPrint then p:ChatPrint(text) end
    end
end
local function Names(list)
    local n = {}
    for _, b in ipairs(list) do n[#n + 1] = b.name end
    return table.concat(n, ", ")
end
local function Kit() return LC.DreamGameKit or {} end

-- A figure under the dream's hand (not solid, moved every tick).
local function Figure(model, pos, yaw)
    local e = ents.Create("prop_dynamic")
    if not IsValid(e) then return nil end
    e:SetModel(model)
    e:SetKeyValue("solid", "0")
    e:SetPos(pos)
    e:SetAngles(Angle(0, yaw or 0, 0))
    e:Spawn()
    if e.SetMoveType then e:SetMoveType(MOVETYPE_NONE) end
    if e.SetNotSolid then e:SetNotSolid(true) end
    local seq = e.SelectWeightedSequence and e:SelectWeightedSequence(ACT_IDLE or 1) or -1
    if seq and seq >= 0 and e.ResetSequence then e:ResetSequence(seq) end
    e.lcDreamStandin = true
    return e
end
local function Act(e, act)
    if not IsValid(e) or not e.SelectWeightedSequence then return end
    local seq = e:SelectWeightedSequence(act)
    if seq and seq >= 0 and e.ResetSequence then e:ResetSequence(seq) if e.SetPlaybackRate then e:SetPlaybackRate(1) end end
end

------------------------------------------------------------------------
-- In a dream you play
------------------------------------------------------------------------

-- When each stand-in loses a life, and when (if ever) they're out of it.
local function Plan(b, t0, secs, lives)
    b.hits = {}
    local survive = math.random() < 0.3
    local out = survive and nil or (t0 + secs * math.Rand(0.3, 0.95))
    local last = out or (t0 + secs)
    local n = survive and math.random(0, math.max(0, lives - 1)) or math.max(0, lives - 1)
    for i = 1, n do b.hits[i] = t0 + 8 + (last - t0 - 8) * (i / (n + 1)) end
    b.outAt = out
end

function LC.DreamStandinsGame(g)
    if not g or g.standins or g.id == "quiz" then return {} end -- (the quiz seats its own)
    g.standins = {}
    local want = LC.DreamMin() - table.Count(g.pl)
    if want <= 0 then return g.standins end
    local homes = {}
    for _, s in pairs(g.pl) do if s.start then homes[#homes + 1] = s.start end end
    if #homes == 0 then return g.standins end
    local Actor = Kit().Actor
    for i, who in ipairs(People(want)) do
        local home = homes[(i - 1) % #homes + 1]
        local a = math.rad(i * 360 / want)
        local at = home + Vector(math.cos(a) * 70, math.sin(a) * 70, 0)
        local yaw = math.Rand(0, 360)
        local e = Actor and Actor(g, who.model, at, yaw, 1, ACT_IDLE or 1) or Figure(who.model, at, yaw)
        if IsValid(e) then
            e.lcDreamStandin = true
            if not Actor then g.ents[#g.ents + 1] = e end
            local b = { name = who.name, ent = e, home = at, pos = at, yaw = yaw, lives = g.def.lives or 1 }
            Plan(b, g.t0 or CurTime(), g.def.secs or 180, b.lives)
            g.standins[#g.standins + 1] = b
        end
    end
    if #g.standins > 0 then
        Chat(g.dream, "(in the dream) Also dreaming: " .. Names(g.standins) .. ".")
        g.standinLineAt = CurTime() + math.Rand(12, 25)
    end
    return g.standins
end

local SPEED = 115
local function Step(g, b, now, dt)
    if b.out or not IsValid(b.ent) then return end
    -- a life lost: a red flash, and back to where they began
    if b.hits[1] and now >= b.hits[1] then
        table.remove(b.hits, 1)
        b.lives = math.max(1, b.lives - 1)
        b.pos, b.target, b.pause = b.home, nil, now + 1.5
        b.ent:SetPos(b.home)
        if b.ent.SetColor then b.ent:SetColor(Color(255, 60, 60)) end
        b.flash = now + 0.8
        if Kit().Snd then Kit().Snd(b.ent, "npc/metropolice/vo/finalverdictadministered.wav", 55) end
    end
    if b.flash and now >= b.flash then b.flash = nil if b.ent.SetColor then b.ent:SetColor(Color(255, 255, 255)) end end
    -- out of it
    if b.outAt and now >= b.outAt then
        b.out = true
        if Kit().Puff then Kit().Puff(b.pos + Vector(0, 0, 40)) end
        b.ent:Remove()
        Chat(g.dream, "(in the dream) " .. b.name .. " is out of it.")
        return
    end
    -- running about near the start
    if b.pause and now < b.pause then return end
    if not b.target then
        local a = math.Rand(0, math.pi * 2)
        local r = math.Rand(40, 200)
        b.target = b.home + Vector(math.cos(a) * r, math.sin(a) * r, 0)
        Act(b.ent, ACT_RUN or 10)
    end
    local d = b.target - b.pos
    d.z = 0
    local len = d:Length()
    if len < 12 then
        b.target, b.pause = nil, now + math.Rand(0.5, 2.5)
        Act(b.ent, ACT_IDLE or 1)
        return
    end
    local move = math.min(len, SPEED * dt)
    b.pos = b.pos + d * (move / len)
    b.yaw = math.deg(math.atan2(d.y, d.x))
    b.ent:SetPos(b.pos)
    b.ent:SetAngles(Angle(0, b.yaw, 0))
end

local function Talk(dream, list, now, at)
    if not at or now < at then return at end
    local alive = {}
    for _, b in ipairs(list) do if not b.out and IsValid(b.ent) then alive[#alive + 1] = b end end
    if #alive > 0 then
        local lines = LC.DreamStandinLines[dream.mood or "neutral"] or LC.DreamStandinLines.neutral
        if LC.PropagandaDreams and LC.PropagandaDreams[dream.ending] then lines = LC.DreamStandinLines.happy end
        local b = alive[math.random(#alive)]
        Chat(dream, "(in the dream) " .. b.name .. ": " .. lines[math.random(#lines)])
    end
    return now + math.Rand(20, 40)
end

------------------------------------------------------------------------
-- In an ending
------------------------------------------------------------------------

function LC.DreamStandinsEnding(dream)
    if not dream or dream.game or dream.standins then return {} end
    dream.standins = {}
    local want = LC.DreamMin() - #Dreamers(dream)
    if want <= 0 then return dream.standins end
    local spots = LC.EndingRingSpots and LC.EndingRingSpots(dream.pos, 150, want) or {}
    for i, who in ipairs(People(want)) do
        local at = spots[i] and spots[i].pos or (dream.pos + Vector(math.cos(i) * 150, math.sin(i) * 150, 0))
        local e = Figure(who.model, at, (dream.pos - at):Angle().y)
        if IsValid(e) then dream.standins[#dream.standins + 1] = { name = who.name, ent = e, pos = at, hits = {} } end
    end
    if #dream.standins > 0 then
        Chat(dream, "(in the dream) Also dreaming: " .. Names(dream.standins) .. ".")
        dream.standinLineAt = CurTime() + math.Rand(12, 25)
    end
    return dream.standins
end

------------------------------------------------------------------------
-- Running them, and tidying up
------------------------------------------------------------------------

hook.Add("LivingCityDreamStarted", "LivingCityDreamStandins", function(dream)
    if LC.DreamMin() <= 0 then return end
    local ok, err = pcall(function()
        if dream.game then LC.DreamStandinsGame(dream.game) else LC.DreamStandinsEnding(dream) end
    end)
    if not ok and LC.Error then LC.Error("dream stand-ins", err) end
end)

local last, lastT
function LC.DreamStandinsTick(now)
    local dream = LC.DreamActive
    -- the dream's over: anything of theirs still standing goes (an ending's own clean-up may have missed them)
    if last and last ~= dream then
        for _, b in ipairs(last.standins or {}) do if IsValid(b.ent) then b.ent:Remove() end end
        last.standins = nil
        last = nil
    end
    if not dream then return end
    local dt = math.Clamp(now - (lastT or now), 0, 0.25)
    lastT = now
    local g = dream.game
    if g and not g.stopped and g.standins then
        for _, b in ipairs(g.standins) do Step(g, b, now, dt) end
        g.standinLineAt = Talk(dream, g.standins, now, g.standinLineAt)
    elseif not g and dream.standins then
        last = dream
        dream.standinLineAt = Talk(dream, dream.standins, now, dream.standinLineAt)
    end
end
timer.Create("LivingCityDreamStandins", 0.1, 0, function()
    local ok, err = pcall(LC.DreamStandinsTick, CurTime())
    if not ok and LC.Error then LC.Error("dream stand-ins", err) end
end)
