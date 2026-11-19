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

      In a dream you play: they play along. Each one keeps to the players
      (a few steps off one of them) or runs about near the start, bolts from
      whatever hunts the dreamers when it comes close (the brave let it come
      nearer), and between runs stands a moment the way the dream calls for:
      kneeling to her in a propaganda dream, cowering or glancing about in a
      nightmare, waving and cheering in a happy one. They flinch when a
      player near them loses a life, cheer a player who wins, and say so in
      chat, by name. Now and then one loses a life (a red flash, back to where
      they began, a moment cowering), and most drop out of it before the end
      (a last word, a puff, and a line in chat). They never touch the game
      itself: they take no tokens, block nobody, and never take a win from a
      real player. Their arms, heads and backs are moved on the dreamers'
      screens (cl_livingcity_dreamacting.lua), on top of the model's own
      sequences.
      The Loyalty Quiz seats its own (they answer in chat, and the rebel is
      dragged off: sv_livingcity_propagandadreams.lua), up to the same
      number.

      In an ending: they stand in the dream with the dreamers (the ending
      brings its own crowd as well), turning to whoever is nearest and, by
      the dream's mood, waving, cheering, swaying, glancing about or cowering.

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
------------------------------------------------------------------------
-- How they act (the owner, 10 November: better animation and scripting for the dreams' scenes)
------------------------------------------------------------------------

-- An act is a sequence (the first name the model has, else the activity) and a name the dreamers'
-- screens know: cl_livingcity_dreamacting.lua moves the arms, head and back on top of it, so even a
-- model with no such sequence cowers, cheers or kneels.
local KNEEL = { "crouchidlehide", "Crouch_idleD", "crouch_idled", "pose_ducking_01" }
local ACTS = {
    idle   = { act = ACT_IDLE or 1 },
    run    = { act = ACT_RUN or 10 },
    panic  = { seq = { "run_all_panicked", "run_panicked", "run_protected_all" }, act = ACT_RUN or 10 },
    cower  = { seq = { "cower_Idle", "Fear_Reaction_Idle", "crouchidlehide", "Crouch_idleD" }, act = ACT_COWER or ACT_IDLE or 1 },
    flinch = { seq = { "Fear_Reaction", "photo_react_startle" }, act = ACT_IDLE or 1 },
    cheer  = { seq = { "cheer1", "cheer2" }, act = ACT_IDLE or 1 },
    wave   = { seq = { "Wave", "wave_close", "wave" }, act = ACT_IDLE or 1 },
    look   = { seq = { "lookoutidle", "LineIdle02", "lineidle02" }, act = ACT_IDLE or 1 },
    kneel  = { seq = KNEEL, act = ACT_COVER_LOW or ACT_IDLE or 1 },
    plead  = { seq = KNEEL, act = ACT_COVER_LOW or ACT_IDLE or 1 },
    sway   = { seq = { "LineIdle01", "lineidle01", "LineIdle03" }, act = ACT_IDLE or 1 },
}
LC.DreamStandinActs = ACTS

-- Start an act (nothing done when they're in it already). secs: hold still that long.
local function Do(b, name, now, secs)
    local e = b.ent
    if not IsValid(e) then return end
    if secs then b.busy = math.max(b.busy or 0, now + secs) end
    if b.act == name then return end
    b.act = name
    local A = ACTS[name] or ACTS.idle
    local seq = -1
    for _, n in ipairs(A.seq or {}) do
        seq = e.LookupSequence and e:LookupSequence(n) or -1
        if seq and seq >= 0 then break end
    end
    local own = seq ~= nil and seq >= 0 -- (the model has a sequence of its own for this: the screens add only the small things)
    if e.SetNW2Bool then e:SetNW2Bool("lc_dream_act_own", own) end
    if (not seq or seq < 0) and e.SelectWeightedSequence then seq = e:SelectWeightedSequence(A.act) end
    if seq and seq >= 0 and e.ResetSequence then e:ResetSequence(seq) if e.SetPlaybackRate then e:SetPlaybackRate(1) end end
    if e.SetNW2String then
        e:SetNW2String("lc_dream_act", name)
        e:SetNW2Float("lc_dream_act_t", now)
    end
end
LC.DreamStandinDo = Do

-- Turn towards a yaw, quickly but not at once.
local function Turn(b, want, dt)
    local d = (want - (b.yaw or want) + 180) % 360 - 180
    local step = 540 * dt
    b.yaw = (b.yaw or want) + math.Clamp(d, -step, step)
    if IsValid(b.ent) then b.ent:SetAngles(Angle(0, b.yaw, 0)) end
end
local function YawTo(from, to) return math.deg(math.atan2(to.y - from.y, to.x - from.x)) end
local function Flat(a, b) local dx, dy = a.x - b.x, a.y - b.y return math.sqrt(dx * dx + dy * dy) end

-- What they say when something happens (%s: the player's name).
LC.DreamStandinReact = {
    hit = { "%s! Get up, get up!", "No! Not %s!", "They got %s!", "%s, behind you!", "Careful, %s!" },
    out = { "%s is gone. They're gone.", "We've lost %s.", "Don't end up like %s." },
    won = { "%s did it! %s did it!", "Look at %s go!", "Well done, %s!", "I knew %s would make it." },
    flee = { "It's coming this way!", "Run! RUN!", "Not me, not me, not me!", "Get away from it!" },
    kneel = { "On your knees, quickly.", "She's looking this way. Kneel!", "Isn't she magnificent?", "Lower. Lower your eyes." },
    last = { "I can't... I can't keep going...", "Tell them I tried.", "It's got me.", "I'm waking up, I can feel it." },
}
-- A few words for the dream they're in (said among the mood's own lines).
LC.DreamStandinDreamLines = {
    maze = { "Which turn was it? They all look the same!", "I can hear his boots on the other side of the wall.", "Take the tokens, I'll draw him off!", "He's so big. Why is he so big?" },
    barrels = { "Don't touch the barrels!", "Keep climbing, don't look down.", "He's throwing another one!", "How high does this thing go?" },
    crumble = { "The floor! Keep moving!", "Don't stand still, it's going!", "There's nothing under us. Nothing!", "This way, it still holds here!" },
    freeze = { "Don't move. Don't even breathe.", "He's turning round. Stop!", "Now! Go, go, go!", "He saw someone. He always sees someone." },
    cheese = { "Sometimes I dream about cheese.", "It's all so... yellow.", "Mind the wheel!" },
}

local function Say(g, b, key, name)
    local now = CurTime()
    if (g.standinSaidAt or 0) > now - 5 then return end
    local lines = LC.DreamStandinReact[key]
    if not lines or not b or b.out then return end
    g.standinSaidAt = now
    Chat(g.dream, "(in the dream) " .. b.name .. ": " .. string.gsub(lines[math.random(#lines)], "%%s", function() return name or "someone" end))
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
    if not g or g.standins or g.id == "quiz" or (g.def and g.def.ownStandins) then return {} end -- (the quiz seats its own; the rally brings its own drivers)
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
            if e.SetNW2Bool then e:SetNW2Bool("lc_dream_standin", true) end
            if not Actor then g.ents[#g.ents + 1] = e end
            -- (each their own: how fast, how brave, how much they keep to the players)
            local b = { name = who.name, ent = e, home = at, pos = at, yaw = yaw, lives = g.def.lives or 1,
                speed = math.Rand(100, 135), brave = math.random(), pack = math.Rand(0.35, 0.75) }
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

-- The real players still in it.
local function Playing(g)
    local out = {}
    for p, s in pairs(g.pl or {}) do if IsValid(p) and not s.done then out[#out + 1] = p end end
    return out
end
-- Whatever hunts the dreamers in this dream (the giant officers, the dead, the giant on the tower).
local function Threats(g)
    local out = {}
    local function Add(e) if IsValid(e) then out[#out + 1] = e end end
    for _, k in ipairs({ "cops", "mons", "hunters", "zombies" }) do
        if istable(g[k]) then for _, c in pairs(g[k]) do Add(istable(c) and c.e or c) end end
    end
    return out
end
LC.DreamStandinThreats = Threats
-- Her, in a propaganda dream: the Administrator starring in it, or her figure.
local function Her(g)
    if not (LC.PropagandaDreams and LC.PropagandaDreams[g.id]) then return nil end
    if IsValid(g.star) then return g.star end
    return IsValid(g.her) and g.her or nil
end

-- Standing a moment, by the dream: kneeling to her, cowering, glancing about, waving at someone.
local function Idle(g, b, now)
    b.faceAt = nil
    local her = Her(g)
    local near, nd
    for _, p in ipairs(Playing(g)) do
        local d = Flat(p:GetPos(), b.pos)
        if not nd or d < nd then near, nd = p, d end
    end
    local mood = g.dream and g.dream.mood or "neutral"
    local r = math.random()
    if her then
        b.face = her
        if r < 0.7 then
            Do(b, r < 0.2 and "plead" or "kneel", now, math.Rand(3, 6))
            if r < 0.06 then Say(g, b, "kneel") end
        else Do(b, "cheer", now, math.Rand(1.5, 2.5)) end
    elseif mood == "nightmare" then
        b.face = near
        if r < 0.3 - b.brave * 0.2 then Do(b, "cower", now, math.Rand(1.5, 3))
        else Do(b, "look", now, math.Rand(0.8, 2.2)) end
    elseif mood == "happy" then
        b.face = near
        if near and nd < 500 and r < 0.4 then Do(b, "wave", now, math.Rand(1.5, 2.5))
        elseif r < 0.6 then Do(b, "cheer", now, math.Rand(1.2, 2))
        else Do(b, "sway", now, math.Rand(1, 2.5)) end
    else
        b.face = r < 0.5 and near or nil
        Do(b, r < 0.5 and "look" or "sway", now, math.Rand(0.8, 2.5))
    end
end

-- Somewhere to go: after one of the players (a few steps off, on their ground), or about near the start.
local function Target(g, b)
    local list = Playing(g)
    if #list > 0 and math.random() < b.pack then
        local p = list[math.random(#list)]
        local at = p:GetPos()
        if math.abs(at.z - b.pos.z) < 80 and Flat(at, b.pos) < 1400 then
            local a, r = math.Rand(0, math.pi * 2), math.Rand(60, 130)
            return Vector(at.x + math.cos(a) * r, at.y + math.sin(a) * r, at.z)
        end
    end
    local a, r = math.Rand(0, math.pi * 2), math.Rand(40, 200)
    return b.home + Vector(math.cos(a) * r, math.sin(a) * r, 0)
end

local function Step(g, b, now, dt, threats)
    if b.out or not IsValid(b.ent) then return end
    -- a life lost: a red flash, back to where they began, and a moment on the ground before they dare get up
    if b.hits[1] and now >= b.hits[1] then
        table.remove(b.hits, 1)
        b.lives = math.max(1, b.lives - 1)
        b.pos, b.target, b.pause, b.flee = b.home, nil, now + 1.5, nil
        b.ent:SetPos(b.home)
        if b.ent.SetColor then b.ent:SetColor(Color(255, 60, 60)) end
        b.flash = now + 0.8
        b.busy = nil
        Do(b, "cower", now, 1.8)
        if Kit().Snd then Kit().Snd(b.ent, "npc/metropolice/vo/finalverdictadministered.wav", 55) end
    end
    if b.flash and now >= b.flash then b.flash = nil if b.ent.SetColor then b.ent:SetColor(Color(255, 255, 255)) end end
    -- out of it: a last word and a stagger just before, then gone
    if b.outAt and not b.lastWord and now >= b.outAt - 1.5 and now < b.outAt then
        b.lastWord = true
        b.target, b.busy = nil, nil
        Do(b, "cower", now, 1.6)
        if math.random() < 0.5 then Say(g, b, "last") end
    end
    if b.outAt and now >= b.outAt then
        b.out = true
        if Kit().Puff then Kit().Puff(b.pos + Vector(0, 0, 40)) end
        b.ent:Remove()
        Chat(g.dream, "(in the dream) " .. b.name .. " is out of it.")
        return
    end
    -- something hunting them, close: they bolt (the brave let it come nearer)
    local danger, dd
    for _, t in ipairs(threats or {}) do
        local tp = t:GetPos()
        local d = Flat(tp, b.pos)
        if math.abs(tp.z - b.pos.z) < 200 and (not dd or d < dd) then danger, dd = tp, d end
    end
    local scare = 330 - 140 * (b.brave or 0.5)
    if danger and dd < scare and not (b.pause and now < b.pause) then
        if not b.flee or now >= b.flee then
            local away = Vector(b.pos.x - danger.x, b.pos.y - danger.y, 0)
            if away:Length() < 1 then away = Vector(1, 0, 0) end
            away:Normalize()
            local side = Vector(-away.y, away.x, 0) * math.Rand(-0.6, 0.6) -- (not all in one line)
            local to = b.pos + (away + side) * 240
            if Flat(to, b.home) > 600 then to = b.home + (to - b.home):GetNormalized() * 600 end -- (never far from where they began)
            to.z = b.pos.z
            b.target, b.flee, b.busy = to, now + 1.2, nil
            if not b.fled or now - b.fled > 12 then
                b.fled = now
                if math.random() < 0.35 then Say(g, b, "flee") end
            end
        end
        Do(b, "panic", now)
    elseif b.flee and now >= b.flee then
        b.flee = nil
    end
    -- holding still (cowering, kneeling, cheering, looking about): facing what they're looking at
    if (b.pause and now < b.pause) or (b.busy and now < b.busy) then
        local at = b.faceAt or (IsValid(b.face) and b.face:GetPos()) or nil
        if at and Flat(at, b.pos) > 8 then Turn(b, YawTo(b.pos, at), dt) end
        return
    end
    if not b.target then
        -- (between runs, most of the time, a moment standing: what the dream calls for)
        if not b.idled and math.random() < 0.65 then
            b.idled = true
            Idle(g, b, now)
            return
        end
        b.idled, b.face, b.faceAt = nil, nil, nil
        b.target = Target(g, b)
        Do(b, "run", now)
    end
    local d = b.target - b.pos
    local dz = d.z
    d.z = 0
    local len = d:Length()
    if len < 12 then
        b.target, b.flee, b.pause = nil, nil, now + math.Rand(0.3, 1.2)
        Do(b, "idle", now)
        return
    end
    local move = math.min(len, (b.speed or 115) * (b.flee and 1.5 or 1) * dt)
    b.pos = b.pos + d * (move / len)
    b.pos.z = b.pos.z + dz * (move / len)
    b.ent:SetPos(b.pos)
    Turn(b, math.deg(math.atan2(d.y, d.x)), dt)
end

-- What happens to the players, they see: a life lost near them, someone out of it, someone winning.
local function Watch(g, now)
    g.standinSeen = g.standinSeen or {}
    for p, s in pairs(g.pl or {}) do
        if IsValid(p) then
            local seen = g.standinSeen[p] or { lives = s.lives, how = s.how }
            g.standinSeen[p] = seen
            local what
            if s.how ~= seen.how and s.how == "won" then what = "won"
            elseif s.how ~= seen.how and s.how == "out" then what = "out"
            elseif (s.lives or 0) < (seen.lives or 0) then what = "hit" end
            seen.lives, seen.how = s.lives, s.how
            if what then
                local at, spoke = p:GetPos(), false
                for _, b in ipairs(g.standins) do
                    if not b.out and IsValid(b.ent) and not b.flash and (what == "won" or Flat(at, b.pos) < 700) then
                        b.face, b.faceAt, b.target, b.idled = nil, at, nil, nil
                        Do(b, what == "won" and "cheer" or (what == "out" and "cower" or "flinch"), now, what == "won" and 3 or (what == "out" and 1.6 or 1))
                        if not spoke then spoke = true Say(g, b, what, p.Nick and p:Nick() or "someone") end
                    end
                end
            end
        end
    end
end
LC.DreamStandinsWatch = Watch

local function Talk(dream, list, now, at)
    if not at or now < at then return at end
    local alive = {}
    for _, b in ipairs(list) do if not b.out and IsValid(b.ent) then alive[#alive + 1] = b end end
    if #alive > 0 then
        local lines = LC.DreamStandinLines[dream.mood or "neutral"] or LC.DreamStandinLines.neutral
        if LC.PropagandaDreams and LC.PropagandaDreams[dream.ending] then lines = LC.DreamStandinLines.happy end
        local own = LC.DreamStandinDreamLines[dream.ending or ""]
        if own and math.random() < 0.5 then lines = own end -- (half the time, about the dream they're in)
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
        local yaw = (dream.pos - at):Angle().y
        local e = Figure(who.model, at, yaw)
        if IsValid(e) then
            if e.SetNW2Bool then e:SetNW2Bool("lc_dream_standin", true) end
            dream.standins[#dream.standins + 1] = { name = who.name, ent = e, pos = at, yaw = yaw, hits = {}, brave = math.random(), nextAct = CurTime() + math.Rand(2, 6) }
        end
    end
    if #dream.standins > 0 then
        Chat(dream, "(in the dream) Also dreaming: " .. Names(dream.standins) .. ".")
        dream.standinLineAt = CurTime() + math.Rand(12, 25)
    end
    return dream.standins
end

-- In an ending they stay where they are (the ending has its own crowd and its own dance), but they
-- aren't statues: they turn to whoever is nearest, and by the dream's mood they wave, cheer, sway,
-- glance about or cower.
local function EndingStep(dream, b, now, dt)
    if not IsValid(b.ent) then return end
    local near, nd
    for _, p in ipairs(Dreamers(dream)) do
        local d = Flat(p:GetPos(), b.pos)
        if d > 8 and (not nd or d < nd) then near, nd = p, d end
    end
    local at = near and near:GetPos() or dream.pos
    if Flat(at, b.pos) > 8 then Turn(b, YawTo(b.pos, at), dt * 0.35) end -- (slowly: a look, not a snap)
    if b.busy and now < b.busy then return end
    if now < (b.nextAct or 0) then Do(b, "idle", now) return end
    b.nextAct = now + math.Rand(5, 11)
    local mood, r = dream.mood or "neutral", math.random()
    if mood == "nightmare" then Do(b, r < 0.45 - b.brave * 0.25 and "cower" or "look", now, math.Rand(1.5, 3.5))
    elseif mood == "happy" then Do(b, (near and nd < 400 and r < 0.35) and "wave" or (r < 0.7 and "cheer" or "sway"), now, math.Rand(1.5, 3))
    else Do(b, r < 0.5 and "look" or "sway", now, math.Rand(1.5, 3)) end
end

------------------------------------------------------------------------
-- Running them, and tidying up
------------------------------------------------------------------------

hook.Add("LivingCityDreamStarted", "LivingCityDreamStandins", function(dream)
    if LC.DreamMin() <= 0 then return end
    local ok, err = LC.Try(function()
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
        local threats = Threats(g)
        Watch(g, now)
        for _, b in ipairs(g.standins) do Step(g, b, now, dt, threats) end
        g.standinLineAt = Talk(dream, g.standins, now, g.standinLineAt)
    elseif not g and dream.standins then
        last = dream
        for _, b in ipairs(dream.standins) do EndingStep(dream, b, now, dt) end
        dream.standinLineAt = Talk(dream, dream.standins, now, dream.standinLineAt)
    end
end
timer.Create("LivingCityDreamStandins", 0.1, 0, function()
    local ok, err = LC.Try(LC.DreamStandinsTick, CurTime())
    if not ok and LC.Error then LC.Error("dream stand-ins", err) end
end)
