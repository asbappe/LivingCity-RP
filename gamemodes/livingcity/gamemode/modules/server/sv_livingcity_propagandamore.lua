--[[
    Living City: more propaganda dreams (dreams you play), drawn from real propaganda

      The owner, 8 November, of ten ideas offered in chat: "Honestly all of these are great. Can we
      build them all?" They sit beside the first five (sv_livingcity_propagandadreams.lua) and work
      the same way: on her tablet under Happy as "Propaganda: ...", built at the dream point out of
      plain props, not skippable, and every offence (a life lost) costs loyalty points as you wake
      (3 each, 5 more for being thrown out, at most 20). Nothing for winning, no health lost.

        Record Harvest (harvest), Soviet and Maoist harvest posters: carry glowing ration crates
          from the field to the depot while the quota board climbs to absurd numbers. A sickly
          green crate is spoiled: crouch to throw it away, because delivering it is wrecking.
          Five crates: a medal from her own hand.
        The Union Shift (shift), Soviet labour heroes: stand at a work station and hammer
          (crouch, again and again) to beat the norm by 1400%. Double norm now and then. Idle for
          12 seconds and she notices (no foreman: the owner, 8 November, "I prefer just using the administrator"). The first to 1400% gets a giant portrait.
        Careless Talk (spy), "loose lips sink ships": a canteen of citizens with one rebel spy
          among them. A party game (the owner: "everyone has 30 seconds to pick the spy ... on
          their own and then it's revealed to everyone at the end"): four rounds of 30 seconds,
          three overheard clues each (which table, a man or a woman, what colour); crouch beside
          the one you suspect (change your mind as often as you like). Then the spy and
          everyone's pick are shown to all: a loyal citizen reported, or nobody, costs a life.
          Three spies found out of four wins.
        The Newsreel (newsreel), wartime newsreels: the dream is black and white and she
          booms. A party game too: eight takes; as the camera rolls each dreamer is told to wave,
          salute or cheer (say it in chat) before the cut, and then everyone's take is shown to
          all. Wrong, or nothing, costs a life. Five good takes wins.
        Two Minutes of Hate (hate), Orwell's 1984: the enemy of the people on a giant screen, and
          everyone jeers in chat. Silence for 15 seconds is noticed; a kind word for him is
          thoughtcrime. Fill your Hatred to win.
        The Mass Games (massgames), North Korean card stunts: each dreamer has a seat in the
          stands and a card, gold (crouch) or red (stand). Show the colour you're told when the
          Administrator calls "Flip!" and, picture by picture, the stands become her portrait.
        On-the-Spot Guidance (guidance), leaders' factory visits: she tours a factory and points
          at things. Applaud (jump, or say "clap") each time: whoever doesn't, or is last, loses a
          life. Through the whole tour: she's pleased with you. (She can star in it herself.)
        The Scrap Drive (scrap), home-front scrap drives: gather scrap metal (three at a time) and
          fill the collection bins. A shady trader at the side wants to buy it: sell to him and
          it's the black market. Nine pieces wins.
        Flowers for the Liberators (flowers), troops welcomed with flowers: her soldiers march
          down the village street. Throw your flowers (jump) as one passes level with you. Never
          step into the road, and don't let a whole squad pass without a flower.
        Duck and Cover (duck), Cold War civil-defence films: the Resistance is firing rockets at
          the city (the owner: "framed as the resistance threat is launching a rocket"). Sunny the
          Scanner, a cheerful mascot, gives instructions; when the siren wails the rebels' rocket
          climbs from its pad (White Forest's rocket_low, sized to the room over the dream point, else Garry's Mod's
          own), with Doctor Magnusson, fifty feet tall and glowing red, cackling beside it and riding
          it up; you crouch beside a table before the flash (two to a table). Six survived wins.
        The Resistance in these dreams is goofy (the owner: "dreams are nonsensical and goofy ...
        glowing red and 50 feet tall flying through the air or w/e, that applies for all of
        these"): the unmasked spy in Careless Talk swells to a red giant and floats away; a giant
        red rebel floats over the Two Minutes of Hate screen.

      Music, flat in garrysmod/sound/livingcity/dreams/ like the others: each dream's codeword
      (harvest, shift, spy, newsreel, hate, massgames, guidance, scrap, flowers, duck) or
      propaganda for any of them. Voices in dreams/voice/, named for the line (LC.PropagandaCues).
]]

if CLIENT then return end

LC = LC or {}

local K, P, G = LC.DreamGameKit, LC.PropagandaKit, LC.DreamGames
if not K or not P or not G then return end
local Block, Actor, Floor, Snd, Done, ToStart = K.Block, K.Actor, K.Floor, K.Snd, K.Done, K.ToStart
local PLATE8_S, PLATE4, PLATE4_S = K.PLATE8_S, K.PLATE4, K.PLATE4_S
local Everyone, Line, Her, HerEnt, Follow, Woke, Hall, Starts, Spawn, Offend = P.Everyone, P.Line, P.Her, P.HerEnt, P.Follow, P.Woke, P.Hall, P.Starts, P.Spawn, P.Offend
local StarState, StarAt, Pose, Notice, ADMIRERS = P.StarState, P.StarAt, P.Pose, P.Notice, P.ADMIRERS

local MORE = { "harvest", "shift", "spy", "newsreel", "hate", "massgames", "guidance", "scrap", "flowers", "duck" }
LC.PropagandaMore = MORE
for _, id in ipairs(MORE) do
    LC.PropagandaDreams[id] = true
    local have = false
    for _, o in ipairs(LC.DreamGameOrder) do if o == id then have = true end end
    if not have then LC.DreamGameOrder[#LC.DreamGameOrder + 1] = id end
    LC.PropagandaSongWords[#LC.PropagandaSongWords + 1] = id
end
LC.PropagandaSongWords[#LC.PropagandaSongWords + 1] = "propaganda"

-- Every line, and who says it (a recording named for the line replaces the words with its .txt).
local CUES = {
    harvest_hello = { "The Administrator", "Citizens! The harvest is ripe and the quota is waiting. Bring it in!" },
    harvest_medal = { "The Administrator", "For glorious labour beyond the plan: the Order of the Golden Sheaf." },
    shift_hello = { "The Administrator", "My workers! Today's norm is one hundred percent. Tomorrow's is fourteen hundred. Why wait?" },
    shift_double = { "The Administrator", "Double norm! Every blow counts twice!" },
    shift_hero = { "The Administrator", "A new Hero of Labour! Hang their portrait beside mine!" },
    shift_idle = { "The Administrator", "I see you standing there. Back to work, citizen!" },
    spy_hello = { "The Administrator", "Careless talk costs lives, my children. There is a traitor among you. Watch them closely." },
    spy_caught = { "The Administrator", "Time is up. The traitor is revealed. I thank my vigilant citizens." },
    -- (Careless Talk's diners, a man's take and a woman's of each: one take is picked at random, its .txt the words.
    -- The chant is said by everyone at once; the spy says the flat one, bored, a beat late.)
    spy_chant_male = { "A diner (man), cheering", "Glory to the Administrator!" },
    spy_chant_female = { "A diner (woman), cheering", "Glory to the Administrator!" },
    spy_flat_male = { "The spy (man), flat and bored", "Glory to the Administrator." },
    spy_flat_female = { "The spy (woman), flat and bored", "Glory to the Administrator." },
    spy_whisper_male = { "The spy (man), whispering", "The old bridge. After curfew. Don't be late." },
    spy_whisper_female = { "The spy (woman), whispering", "The old bridge. After curfew. Don't be late." },
    spy_ready = { "The officer", "Ready!" },
    spy_aim = { "The officer", "Aim!" },
    spy_fire = { "The officer", "Fire!" },
    newsreel_hello = { "The Administrator", "Welcome to my City Seventeen, where every citizen smiles, and every smile is sincere!" },
    newsreel_end = { "The Administrator", "And so another happy day draws to a close. Goodnight, my City Seventeen!" },
    hate_hello = { "The Administrator", "Citizens! Behold the enemy of the people. Let him hear you!" },
    hate_end = { "The Administrator", "The enemy fades. Love returns. Love me." },
    massgames_hello = { "The Administrator", "Cards ready! Together, you are my portrait." },
    massgames_flip = { "The Administrator", "FLIP!" },
    guidance_hello = { "The Administrator", "Show me your work. I have so much guidance to give." },
    guidance_end = { "The Administrator", "Excellent. I have improved everything here simply by looking at it." },
    scrap_hello = { "The Administrator", "Every pot, every pan, every bucket. The city needs your scrap!" },
    flowers_hello = { "The Administrator", "My soldiers are marching home. Show them how much you love them." },
    duck_hello = { "Sunny the Scanner", "Hi, citizens! I'm Sunny! The nasty terrorists have built a rocket. If they launch it, what do we do? We duck, and cover!" },
    duck_siren = { "Sunny the Scanner", "Rocket launch! Duck and cover! Crouch beside a table, quick as you can!" },
    duck_clear = { "Sunny the Scanner", "All clear! The Combine protects us. Wasn't that fun?" },
}
LC.PropagandaCueWho = {}
for k, v in pairs(CUES) do LC.PropagandaCues[k], LC.PropagandaCueWho[k] = v[2], v[1] end

------------------------------------------------------------------------
-- Little helpers
------------------------------------------------------------------------

local function SayAs(g, cue)
    local snd, text = LC.PropagandaVoice(cue)
    g.said = g.said or {}
    g.said[#g.said + 1] = cue
    Line(g, text, snd, LC.PropagandaCueWho[cue])
end
local function Narrate(g, who, text) Line(g, text, nil, who) end
local function Hello(theme, cue, extra)
    return function(g)
        g.song = LC.PropagandaSong(g.def.music)
        if cue then timer.Simple(2, function() if g and not g.stopped then SayAs(g, cue) end end) end
        local t = { theme = theme, song = g.song, herEnt = HerEnt(g), her = g.herHead and { g.herHead.x, g.herHead.y, g.herHead.z } or nil }
        if extra then for k, v in pairs(extra(g) or {}) do t[k] = v end end
        return t
    end
end
local function Echo(g, p, text)
    for _, q in ipairs(Everyone(g)) do if q.ChatPrint then q:ChatPrint("(in the dream) " .. p:Nick() .. ": " .. text) end end
end
local function SetOf(list) local t = {} for _, w in ipairs(list) do t[w] = true end return t end
local function Flat(v) return { math.floor(v.x), math.floor(v.y), math.floor(v.z) } end
local function Dist2(a, b) return math.sqrt((a.x - b.x) ^ 2 + (a.y - b.y) ^ 2) end
local function Kneeling(p) return p.Crouching ~= nil and p:Crouching() == true end
-- Just pressed since the last tick (call every tick for everyone in play).
local function Jumped(s, p)
    local up = (p.KeyDown ~= nil and IN_JUMP ~= nil and p:KeyDown(IN_JUMP) == true) or (p.IsOnGround ~= nil and p:IsOnGround() == false)
    local was = s.jumpWas
    s.jumpWas = up
    return up and not was
end
local function Ducked(s, p)
    local d = Kneeling(p)
    local was = s.duckWas
    s.duckWas = d
    return d and not was
end
-- 1234567 as "1,234,567" (up to a thousand trillion).
function LC.PropagandaCommas(n)
    local s = string.format("%.0f", math.min(math.floor(n or 0), 1e15))
    local out = string.reverse(string.gsub(string.reverse(s), "(%d%d%d)", "%1,"))
    if string.sub(out, 1, 1) == "," then out = string.sub(out, 2) end
    return out
end
local Commas = LC.PropagandaCommas
-- The best few by a field, as board lines.
local function Top(g, field, n, fmt)
    local list = {}
    for p, s in pairs(g.pl) do if IsValid(p) and (s[field] or 0) > 0 then list[#list + 1] = { p:Nick(), s[field] } end end
    table.sort(list, function(a, b) return a[2] > b[2] end)
    local out = {}
    for i = 1, math.min(n, #list) do out[#out + 1] = string.format(fmt, i, list[i][1], list[i][2]) end
    return out
end
local function Board(at, yaw, title, lines, face) return { at.x, at.y, at.z, yaw, title = title, lines = lines, face = face } end
-- A crowd of citizens standing at (x, y) points, facing a spot, cheering.
local CHEER = { "cheer1", "cheer2", "Cheer1", "idle_subtle" }
local function Cheering(g, spots, face)
    for i, v in ipairs(spots) do
        local e = Actor(g, ADMIRERS[(i - 1) % #ADMIRERS + 1], v, math.deg(math.atan2(face.y - v.y, face.x - v.x)), 1, ACT_IDLE or 1)
        Pose(e, CHEER, ACT_IDLE)
    end
end
local function Grace(s) return CurTime() < (s.safe or 0) end
-- The Resistance, as dreams see it (the owner: "dreams are nonsensical and goofy, so if you need to
-- spawn magnusson or some rebel to represent the resistance, they can be glowing red and 50 feet
-- tall flying through the air"): a giant, glowing red figure. The first model the server has.
LC.PropagandaRebels = { "models/humans/group03/male_09.mdl", "models/humans/group03/male_01.mdl", "models/humans/group03/female_03.mdl" }
local RED = Color(255, 40, 40)
local function Redden(e, scale)
    if not IsValid(e) then return end
    e:SetColor(RED)
    if e.SetMaterial then e:SetMaterial("models/debug/debugwhite") end
    if scale and e.SetModelScale then e:SetModelScale(scale) end
end
local function Villain(g, models, pos, yaw, scale)
    local m = models[#models]
    for _, c in ipairs(models) do if K.ValidModel(c) then m = c break end end
    local e = Actor(g, m, pos, yaw, scale, ACT_IDLE or 1)
    Redden(e, scale)
    g.villains = g.villains or {}
    g.villains[#g.villains + 1] = e
    return e
end
LC.PropagandaVillain = Villain
-- (their entities, for the red halo on everyone's screen)
local function Villains(g)
    local out = {}
    for _, e in ipairs(g.villains or {}) do if IsValid(e) and not (e.GetNoDraw and e:GetNoDraw()) then out[#out + 1] = e:EntIndex() end end
    return #out > 0 and out or nil
end

------------------------------------------------------------------------
-- Record Harvest
------------------------------------------------------------------------

do
    local def = { id = "harvest", name = "Record Harvest", mood = "happy", secs = 180, lives = 3, need = 5, music = { "harvest", "propaganda" },
        goal = "Carry glowing ration crates from the field to the depot in front of her. Green ones are spoiled: crouch to throw one away, never deliver it.",
        starGoal = "You're the star, on your pedestal by the depot. They bring in the harvest for you; you hand out the medals. Say anything in chat and the dream hears you.",
        timeUp = { "The harvest is in", "The sun sets on the fields and you wake." }, starring = P.PedestalStar, starGone = P.PedestalGone, spawn = Spawn,
        woke = Woke({
            won = { "Hero of the Harvest", "You wake with your chest puffed out, feeling for a medal that isn't there. The quota was beaten. You beat it." },
            out = { "Wrecker", "You wake sure you ruined the harvest in your sleep. The quota board's numbers follow you into the morning." },
            time = { "The harvest is in", "You wake smelling grain that doesn't exist, and a little hungry." },
        }) }
    G.harvest = def
    LC.HarvestRotten = 0.25

    local function NewCrate(g, i)
        local c = g.crates[i]
        c.pos = Vector(math.Rand(g.fieldX0, g.fieldX1), g.midY + math.Rand(-g.halfW, g.halfW), g.top + 18)
        c.rotten = math.random() < LC.HarvestRotten
        c.gone = nil
    end
    function LC.HarvestPercent(n) return math.floor(100 * 1.9 ^ (n or 0)) end

    function def.build(g, dream)
        local x0, x1, top = Hall(g, dream, 4, Color(150, 120, 50))
        local c = dream.pos
        g.midY, g.halfW = c.y, PLATE8_S - 60
        Her(g, x1 - 110, c.y, top, 180)
        g.depotX = x1 - 300
        -- the depot: a gold strip across the hall
        local strip = Block(g, "models/hunter/plates/plate1x8.mdl", Vector(g.depotX, c.y, top + 2), Angle(0, 0, 0), P.GOLD, "models/debug/debugwhite")
        if strip then
            local mins, maxs = strip:OBBMins(), strip:OBBMaxs()
            if (maxs.x - mins.x) > (maxs.y - mins.y) then strip:SetAngles(Angle(0, 90, 0)) end
        end
        g.fieldX0, g.fieldX1 = x0 + 200, x0 + (x1 - x0) * 0.6
        g.crates = {}
        for i = 1, 8 do g.crates[i] = {} NewCrate(g, i) end
        g.tally = 0
        g.boardAt = Vector(x1 - 30, c.y + PLATE8_S - 140, top + 170)
        Starts(g, x0 + 90, c.y, top)
        return true
    end
    def.hello = Hello("harvest", "harvest_hello")

    function def.tick(g, dt, players)
        local now = CurTime()
        Follow(g)
        for i, cr in ipairs(g.crates) do if cr.gone and now >= cr.gone then NewCrate(g, i) g.dirty = true end end
        for _, p in ipairs(players) do
            local s = g.pl[p]
            s.given = s.given or 0
            local pos = p:GetPos()
            local threw = Ducked(s, p)
            if s.carrying and s.carrying.rotten and threw then
                s.carrying, g.dirty = nil, true
                Notice(p, "info", "Thrown away", "You toss the spoiled crate into a ditch. Nobody saw. Probably.", 3)
            elseif not s.carrying then
                for _, cr in ipairs(g.crates) do
                    if not cr.gone and cr.pos:Distance(pos + Vector(0, 0, 18)) < 50 then
                        s.carrying, cr.gone, g.dirty = { rotten = cr.rotten }, now + 4, true
                        Snd(p, "items/ammocrate_open.wav", 60, 120)
                        if cr.rotten then Notice(p, "warn", "Spoiled!", "This crate is rotten. Crouch to throw it away: delivering it would be wrecking.", 4) end
                        break
                    end
                end
            elseif pos.x >= g.depotX then
                local rotten = s.carrying.rotten
                s.carrying, g.dirty = nil, true
                if rotten then
                    Offend(g, p, "Wrecker!", "You delivered spoiled grain to the people's depot. An inspector writes your name down.")
                else
                    s.given, g.tally = s.given + 1, g.tally + 1
                    Snd(p, "garrysmod/save_load1.wav", 60, 120)
                    if s.given >= def.need then
                        SayAs(g, "harvest_medal")
                        Done(g, p, "won", "Hero of the Harvest", "She pins the Order of the Golden Sheaf to your chest herself. The quota board runs out of digits.")
                    else
                        Notice(p, "info", "Into the depot", string.format("The quota board leaps. %d to go.", def.need - s.given), 3)
                        ToStart(g, p, 1)
                    end
                end
            end
        end
    end

    function def.state(g, p)
        local glows = {}
        for _, cr in ipairs(g.crates) do if not cr.gone then local f = Flat(cr.pos) f[4] = cr.rotten and 2 or 1 glows[#glows + 1] = f end end
        local board = Board(g.boardAt, 180, "THE PEOPLE'S HARVEST", { "Plan: 100%", "Achieved: " .. Commas(LC.HarvestPercent(g.tally)) .. "%",
            "Crates: " .. g.tally, "Grain: " .. Commas(g.tally * 125000 + (g.tally > 0 and 7351 or 0)) .. " tonnes" })
        if p == g.star then local t = StarState(g, "They bring in the harvest for you.") t.glows, t.board = glows, board return t end
        local s = p and g.pl[p] or {}
        local big, tone = nil, "love"
        if not s.done then
            if s.carrying and s.carrying.rotten then big, tone = "Spoiled! Crouch to throw it away.", "warn"
            elseif s.carrying then big = "Carry it to the depot, past the gold line."
            else big = "Pick up a glowing crate in the field." end
        end
        return { glows = glows, board = board, big = big, tone = tone, herEnt = HerEnt(g), carryName = s.carrying and (s.carrying.rotten and "a spoiled crate" or "a ration crate") or nil,
            meter = math.floor((s.given or 0) / def.need * 100), meterName = string.format("Crates delivered: %d of %d", s.given or 0, def.need) }
    end
end

------------------------------------------------------------------------
-- The Union Shift
------------------------------------------------------------------------

do
    local def = { id = "shift", name = "The Union Shift", mood = "happy", secs = 150, lives = 3, need = 1400, music = { "shift", "propaganda" },
        goal = "Stand at a glowing work station and hammer (crouch, again and again) to beat the norm by 1400%. Don't stand idle: she is watching.",
        timeUp = { "The whistle blows", "The shift is over before you've beaten the norm. You wake." }, spawn = Spawn,
        woke = Woke({
            won = { "Hero of Labour", "You wake with aching arms and a strange pride. Somewhere, a giant portrait of you is drying." },
            out = { "Idler", "You wake with her whistle still in your ears. You should work harder. At what, you're not sure." },
            time = { "The whistle blows", "You wake counting hammer blows, and can't stop." },
        }) }
    G.shift = def
    LC.ShiftStroke, LC.ShiftIdle = 20, 12

    function def.build(g, dream)
        local x0, x1, top = Hall(g, dream, 3, Color(85, 75, 70))
        local c = dream.pos
        -- the conveyor, down the middle
        local n = math.floor((x1 - x0 - 300) / PLATE4_S)
        for i = 1, n do Floor(g, PLATE4, x0 + 200 + (i - 0.5) * PLATE4_S, c.y, top + 1, Color(40, 40, 45), "models/debug/debugwhite") end
        g.stations = {}
        local step = (x1 - x0 - 400) / 5
        for i = 0, 5 do for _, dy in ipairs({ -150, 150 }) do g.stations[#g.stations + 1] = Vector(x0 + 250 + i * step, c.y + dy, top) end end
        Her(g, x1 - 110, c.y, top, 180) -- (she watches the floor herself)
        g.boardAt = Vector(x1 - 30, c.y - PLATE8_S + 150, top + 170)
        g.portraitAt = Vector(x1 - 60, c.y + PLATE8_S - 150, top)
        g.doubleAt, g.doubleTil = CurTime() + math.Rand(20, 30), 0
        Starts(g, x0 + 90, c.y, top)
        return true
    end
    def.hello = Hello("propaganda", "shift_hello")

    local function AtStation(g, p)
        local pos = p:GetPos()
        for _, v in ipairs(g.stations) do if Dist2(pos, v) < 70 then return true end end
        return false
    end
    LC.ShiftAtStation = AtStation

    function def.tick(g, dt, players)
        local now = CurTime()
        if now >= g.doubleAt then
            g.doubleTil, g.doubleAt, g.dirty = now + 10, now + math.Rand(25, 35), true
            SayAs(g, "shift_double")
        end
        local double = now < g.doubleTil
        for _, p in ipairs(players) do
            local s = g.pl[p]
            s.pct, s.lastStroke = s.pct or 0, s.lastStroke or (g.t0 + 6)
            if Ducked(s, p) and AtStation(g, p) and now >= (s.strokeAt or 0) then
                s.strokeAt, s.lastStroke = now + 0.25, now
                s.pct = s.pct + LC.ShiftStroke * (double and 2 or 1)
                g.dirty = true
                if s.pct >= def.need then
                    if not g.hero then
                        g.hero = p:Nick()
                        local e = Actor(g, p.GetModel and p:GetModel() or "models/humans/group01/male_02.mdl", g.portraitAt, 180, 3, ACT_IDLE or 1)
                        Pose(e, { "pose_standing_02", "idle_subtle" }, ACT_IDLE)
                        SayAs(g, "shift_hero")
                    end
                    Done(g, p, "won", "Hero of Labour", g.hero == p:Nick() and "Fourteen hundred percent! They hang a giant portrait of you over the factory floor."
                        or "Fourteen hundred percent! A Hero of Labour, like the one on the wall.")
                end
            elseif now - s.lastStroke > LC.ShiftIdle and not Grace(s) then
                s.lastStroke = now
                if Offend(g, p, "Idler!", "She saw you standing about. The norm does not beat itself.") and now >= (g.idleSaidAt or 0) then
                    g.idleSaidAt = now + 10 -- (once in ten seconds, however many idle)
                    SayAs(g, "shift_idle")
                end
            end
        end
    end

    function def.state(g, p)
        local glows = {}
        for _, v in ipairs(g.stations) do glows[#glows + 1] = { math.floor(v.x), math.floor(v.y), math.floor(v.z) + 30, 5 } end
        local lines = Top(g, "pct", 4, "%d. %s  %d%%")
        if #lines == 0 then lines = { "Nobody has started yet. Shameful." } end
        if g.hero then table.insert(lines, 1, "HERO OF LABOUR: " .. g.hero) end
        local board = Board(g.boardAt, 180, "PRODUCTION NORM", lines)
        local s = p and g.pl[p] or {}
        local double = CurTime() < (g.doubleTil or 0)
        local big, tone = nil, "love"
        if not s.done and p and IsValid(p) then
            if double then big, tone = "DOUBLE NORM! Hammer!", "warn"
            elseif AtStation(g, p) then big = "Hammer! (crouch, again and again)"
            else big = "Get to a glowing work station." end
        end
        return { glows = glows, board = board, big = big, tone = tone, meter = math.floor(math.min(1, (s.pct or 0) / def.need) * 100),
            meterName = string.format("Your norm: %d%% of %d%%", s.pct or 0, def.need) }
    end
end

------------------------------------------------------------------------
-- Careless Talk (a party game: everyone picks on their own, then the reveal)
------------------------------------------------------------------------

do
    -- (the owner, 12 November: "the NPCs I saw were all just statues, which makes it pointless". Three rounds now,
    -- each with its own tell, and the pick is E on the one you suspect, not crouching beside them.)
    --   1 the canteen: they chat in pairs (the city's small talk, LC.StreetLines say_small_*); the spy keeps
    --     looking over their shoulder and mutters (spy_whisper); three clues as before
    --   2 the salute: everyone faces her portrait, salutes and cheers in unison (spy_chant); the spy salutes
    --     late and half-heartedly, in a flat voice (spy_flat)
    --   3 the firing squad: rebels against the wall under a spotlight, the diners in a line with rifles; on
    --     the officer's word (spy_ready, spy_aim, spy_fire) every rifle fires once but the spy's
    LC.SpyRounds, LC.SpyRoundSecs, LC.SpyReveal = 3, 30, 6
    LC.SpyKinds = { "chat", "salute", "squad" }
    LC.SpyClueAt = { 3, 11, 19 } -- (seconds into the canteen round)
    LC.SpyGlanceFrom, LC.SpyGlanceEvery, LC.SpyGlanceSecs = 4, { 3, 6 }, 1.5
    LC.SpyChantEvery, LC.SpyChantLate = 4, 1.2   -- (seconds between cheers; how late the spy's salute is)
    LC.SpyVolleyAt = { 7, 16, 25 }                -- (seconds into the firing squad round: "Fire!")
    LC.SpyPickReach, LC.SpyPickRadius = 220, 26   -- (E: how far, and how near your line of sight their body must be)
    local def = { id = "spy", name = "Careless Talk", mood = "happy", noDress = true, secs = 8 + LC.SpyRounds * (LC.SpyRoundSecs + LC.SpyReveal) + 4, lives = 3, need = 2,
        music = { "spy", "propaganda" },
        goal = "One of the diners is a rebel spy, and in each of the three rounds the spy gives themselves away: watch and listen. "
            .. "Press E on the one you suspect (you can change your mind). After 30 seconds, everyone's pick is shown. Find the spy twice to win.",
        timeUp = { "The canteen empties", "The lights go off in the canteen, and you wake." }, spawn = Spawn,
        woke = Woke({
            won = { "Vigilant citizen", "You wake looking sideways at everyone, quietly proud. Loose lips sink ships. Not on your watch." },
            out = { "Informer", "You wake with the feeling you accused the wrong people in your sleep. With luck, nobody remembers." },
            time = { "The canteen empties", "You wake listening hard, as if someone nearby were whispering." },
        }) }
    G.spy = def
    LC.SpyTables = { "by the window", "by the kitchen", "by the door", "under her portrait" }
    LC.SpyTints = { { "red", Color(230, 90, 90) }, { "green", Color(110, 210, 110) }, { "blue", Color(110, 150, 240) }, { "yellow", Color(235, 215, 90) } }
    LC.SpyRoundNotes = {
        chat = { "Round %d of %d: the canteen", "Everyone is chatting over lunch. The spy is jumpy: watch for whoever keeps looking over their shoulder, and listen for the clues." },
        salute = { "Round %d of %d: the salute", "Everyone salutes her portrait and cheers for her. The spy doesn't mean it: watch for the late, half-hearted salute, and listen for the flat voice." },
        squad = { "Round %d of %d: the firing squad", "The diners are handed rifles. When the officer says fire, every rifle fires, except the spy's." },
    }
    local MEN = { "models/humans/group01/male_02.mdl", "models/humans/group02/male_04.mdl", "models/humans/group01/male_07.mdl" }
    local WOMEN = { "models/humans/group01/female_01.mdl", "models/humans/group02/female_02.mdl", "models/humans/group01/female_04.mdl" }
    local IDLE = { "LineIdle01", "lineidle01", "idle_subtle" }
    -- (talking: they shift from one easy stance to another as they chat)
    local CHAT = { { "LineIdle02", "lineidle02" }, { "LineIdle03", "lineidle03" }, { "LineIdle04", "lineidle04" }, { "LineIdle01", "lineidle01" }, { "idle_subtle" } }
    local CHEER = { "cheer1", "cheer2", "Cheer1" }
    local ORD = { "first", "second", "third", "fourth", "fifth", "sixth", "seventh", "eighth", "ninth", "tenth", "eleventh", "twelfth" }

    local function Combo(n) return n.tbl .. "/" .. n.man .. "/" .. n.tint end
    local function Describe(n)
        local where = n.line and string.format("%s in the line", ORD[n.line] or tostring(n.line)) or ("at the table " .. LC.SpyTables[n.tbl])
        return string.format("the %s in %s, %s", n.man == 1 and "man" or "woman", LC.SpyTints[n.tint][1], where)
    end
    LC.SpyDescribe = Describe
    local function Gender(n) return n.man == 1 and "male" or "female" end
    -- The head turned (degrees, the model's head_yaw), when the model has it.
    local function Head(n, yaw)
        n.head = yaw
        if IsValid(n.e) and n.e.SetPoseParameter then n.e:SetPoseParameter("head_yaw", yaw) end
    end
    -- The right arm up to the brow (amount 0 to 1: 1 a smart salute, a half a limp one), or down (0).
    -- (the core's bone rules: on the arms yaw raises it forward, minus up; pitch out to the side, minus for
    -- the right arm; the forearm bends at the elbow on yaw)
    local function Salute(n, amount)
        n.salute = amount
        local e = n.e
        if not IsValid(e) or not e.ManipulateBoneAngles or not e.LookupBone then return end
        local up, fore = e:LookupBone("ValveBiped.Bip01_R_UpperArm"), e:LookupBone("ValveBiped.Bip01_R_Forearm")
        -- (the owner, 13 November: "the salute poses in careless talk had their arms inside their torso".
        -- The arm went forward and in across the chest. Now it goes out to the side first (pitch, minus
        -- for the right arm), up level with the shoulder, and only the forearm folds in to the brow.)
        if up then e:ManipulateBoneAngles(up, Angle(-70 * amount, -30 * amount, -20 * amount)) end
        if fore then e:ManipulateBoneAngles(fore, Angle(0, -125 * amount, 0)) end
        local hand = e:LookupBone("ValveBiped.Bip01_R_Hand")
        if hand then e:ManipulateBoneAngles(hand, Angle(0, 0, -40 * amount)) end
    end
    local function Rifle(g, n, on)
        if on and not IsValid(n.rifle) and LC.BattleLineHolding then n.rifle = LC.BattleLineHolding(g, n.e) end
        if not on and IsValid(n.rifle) then n.rifle:Remove() n.rifle = nil end
    end
    local function Look(n)
        if not IsValid(n.e) then return end
        n.e:SetModel((n.man == 1 and MEN or WOMEN)[n.seat])
        n.e:SetColor(LC.SpyTints[n.tint][2])
        if n.e.SetMaterial then n.e:SetMaterial("") end
        if n.e.SetModelScale then n.e:SetModelScale(1) end
        n.e:SetPos(n.pos)
        if n.yaw then n.e:SetAngles(Angle(0, n.yaw, 0)) end
        if n.e.SetNoDraw then n.e:SetNoDraw(false) end
        Pose(n.e, IDLE, ACT_IDLE)
        Head(n, 0)
        Salute(n, 0)
    end
    -- One of the dream's recordings for a diner (man or woman), or nil.
    local function Voice(cue) local snd = LC.PropagandaVoice(cue) return snd end
    local function Speak(n, path, lvl, pitch)
        if path and IsValid(n.e) then Snd(n.e, path, lvl or 70, pitch or 100) n.spoke = (n.spoke or 0) + 1 end
    end

    -- Where everyone stands for the round.
    local function Arrange(g)
        local kind = g.kind
        for i, n in ipairs(g.npcs) do
            Rifle(g, n, false)
            n.line = nil
            if kind == "squad" then
                n.line = i
                n.pos = Vector(g.squadX, g.squadY0 + (i - 1) * g.squadGap, g.top)
                n.yaw = 0
            else
                n.pos = n.seatPos
                -- the canteen: facing their table; the salute: facing her portrait, at the far end
                local to = kind == "salute" and g.portrait or n.tablePos
                n.yaw = math.deg(math.atan2(to.y - n.seatPos.y, to.x - n.seatPos.x))
            end
            Look(n)
            if kind == "squad" then Rifle(g, n, true) end
        end
        for _, e in ipairs(g.rebels or {}) do if IsValid(e) and e.SetNoDraw then e:SetNoDraw(kind ~= "squad") end end
        if IsValid(g.spot) and g.spot.Fire then g.spot:Fire(kind == "squad" and "TurnOn" or "TurnOff") end
    end

    -- A fresh round: everyone's sex and colour shuffled, and a new spy whose table, sex and colour
    -- together belong to nobody else.
    local function NewRound(g)
        for _, n in ipairs(g.npcs) do n.man, n.tint = math.random(2), math.random(#LC.SpyTints) end
        -- Never at a table the spy has already sat at in this dream, nor (for the first round) the table
        -- of the last dream's last spy: the owner, 13 November, "every time the correct spy was in thes
        -- same exact location".
        g.spyTbls = g.spyTbls or {}
        local pool = {}
        for _, o in ipairs(g.npcs) do
            if not g.spyTbls[o.tbl] and not (next(g.spyTbls) == nil and o.tbl == LC.SpyLastTbl) then pool[#pool + 1] = o end
        end
        if #pool == 0 then pool = g.npcs end
        local n = pool[math.random(#pool)]
        g.spyTbls[n.tbl] = true
        LC.SpyLastTbl = n.tbl
        local taken = {}
        for _, o in ipairs(g.npcs) do if o ~= n then taken[Combo(o)] = true end end
        if taken[Combo(n)] then
            for man = 1, 2 do for tint = 1, #LC.SpyTints do
                if not taken[n.tbl .. "/" .. man .. "/" .. tint] then n.man, n.tint = man, tint end
            end end
        end
        g.spyN = n
        g.round = g.round + 1
        g.kind = LC.SpyKinds[g.round] or "chat"
        Arrange(g)
        local order = { "tbl", "man", "tint" }
        for i = #order, 2, -1 do local j = math.random(i) order[i], order[j] = order[j], order[i] end
        g.phase, g.roundT0, g.clueOrder, g.clues = "pick", CurTime(), order, {}
        g.at, g.dirty = CurTime() + LC.SpyRoundSecs, true
        g.glanceAt, g.glanceTil = CurTime() + LC.SpyGlanceFrom, nil
        g.talkAt, g.chantAt, g.volley, g.fired = CurTime() + 1, CurTime() + 3, 0, nil
        for _, s in pairs(g.pl) do s.pick = nil end
        local note = LC.SpyRoundNotes[g.kind]
        for _, q in ipairs(Everyone(g)) do Notice(q, "info", string.format(note[1], g.round, LC.SpyRounds), note[2], 8) end
    end
    LC.SpyNewRound = NewRound

    -- The canteen: the spy's nerves, a look over the shoulder (the head turned right round and the body half
    -- turned, for a moment), every few seconds; nobody else does it.
    function LC.SpyGlance(g, now)
        local n = g.spyN
        if not n or not IsValid(n.e) or not n.yaw then return end
        if g.glanceTil then
            if now >= g.glanceTil then
                n.e:SetAngles(Angle(0, n.yaw, 0))
                Head(n, 0)
                g.glanceTil, g.glanceAt = nil, now + math.Rand(LC.SpyGlanceEvery[1], LC.SpyGlanceEvery[2])
            end
        elseif now >= (g.glanceAt or math.huge) then
            g.glanceTil = now + LC.SpyGlanceSecs
            g.glances = (g.glances or 0) + 1
            local side = math.random(2) == 1 and 1 or -1
            n.e:SetAngles(Angle(0, n.yaw + side * 55, 0))
            Head(n, side * 70)
        end
    end
    -- The canteen: someone at a table says something to the one beside them, who turns to listen.
    function LC.SpyTalk(g, now)
        if now < (g.talkAt or 0) then return end
        g.talkAt = now + math.Rand(1.2, 2.5)
        local t = math.random(4)
        local at = {}
        for _, n in ipairs(g.npcs) do if n.tbl == t and not (n == g.spyN and g.glanceTil) then at[#at + 1] = n end end
        if #at < 2 then return end
        local who, to = at[1], at[2]
        if math.random(2) == 1 then who, to = to, who end
        for _, n in ipairs(at) do Pose(n.e, CHAT[math.random(#CHAT)], ACT_IDLE) end
        -- heads turned to each other
        local function Toward(a, b)
            local want = math.deg(math.atan2(b.pos.y - a.pos.y, b.pos.x - a.pos.x))
            Head(a, math.Clamp(math.NormalizeAngle and math.NormalizeAngle(want - a.yaw) or 0, -60, 60))
        end
        Toward(who, to) Toward(to, who)
        if who == g.spyN then
            Speak(who, Voice("spy_whisper_" .. Gender(who)), 58)
        else
            local ids = LC.SpySmallTalk or {}
            local id = #ids > 0 and ids[math.random(#ids)] or nil
            local clip = id and LC.AdviceClip and LC.AdviceClip(id, Gender(who))
            Speak(who, clip or string.format("vo/npc/%s01/question%02d.wav", Gender(who), math.random(1, 20)), 66)
        end
        g.talks = (g.talks or 0) + 1
    end
    -- The salute: a cheer in unison every few seconds, arms up; the spy a beat late, half up, flat.
    function LC.SpyChant(g, now)
        if g.spyLateAt and now >= g.spyLateAt then
            g.spyLateAt = nil
            local n = g.spyN
            if n then Salute(n, 0.45) Speak(n, Voice("spy_flat_" .. Gender(n)), 66) end
        end
        if now < (g.chantAt or math.huge) then return end
        g.chantAt = now + LC.SpyChantEvery
        local male, female = Voice("spy_chant_male"), Voice("spy_chant_female")
        for _, n in ipairs(g.npcs) do
            if n ~= g.spyN then
                Salute(n, 1)
                Pose(n.e, CHEER, ACT_IDLE)
                Speak(n, (n.man == 1 and male or female) or string.format("vo/npc/%s01/yeah02.wav", Gender(n)), 72)
            else
                Salute(n, 0.15)
            end
        end
        g.spyLateAt = now + LC.SpyChantLate
        g.chants = (g.chants or 0) + 1
        if g.chants == 1 then Narrate(g, "The canteen", "Glory to the Administrator! Our city, our mother!") end
    end
    -- The firing squad: "Ready... aim... fire!", and every rifle but the spy's fires once.
    function LC.SpyVolley(g, now)
        local i = (g.volley or 0) + 1
        local at = LC.SpyVolleyAt[i]
        if not at then return end
        local t = now - g.roundT0
        if t >= at - 3 and not g.saidReady then g.saidReady = true SayAs(g, "spy_ready") end
        if t >= at - 1.5 and not g.saidAim then g.saidAim = true SayAs(g, "spy_aim") end
        if t < at then return end
        g.volley, g.saidReady, g.saidAim = i, nil, nil
        SayAs(g, "spy_fire")
        local targets = {}
        for _, e in ipairs(g.rebels or {}) do if IsValid(e) then targets[#targets + 1] = e end end
        g.fired = {}
        for k, n in ipairs(g.npcs) do
            if n ~= g.spyN and IsValid(n.e) then
                g.fired[n] = true
                Snd(n.e, "weapons/357/357_fire2.wav", 80, math.random(95, 105))
                local to = targets[(k - 1) % math.max(1, #targets) + 1]
                if to and LC.BattleLineTracer then LC.BattleLineTracer(n.e:GetPos() + Vector(30, 0, 52), to:GetPos() + Vector(0, 0, 50)) end
            end
        end
        -- the rebels drop, and the next ones are led to the wall
        for _, e in ipairs(targets) do if e.SetNoDraw then e:SetNoDraw(true) end end
        timer.Simple(2.5, function()
            if not g or g.stopped or g.kind ~= "squad" then return end
            for _, e in ipairs(g.rebels or {}) do if IsValid(e) and e.SetNoDraw then e:SetNoDraw(false) end end
        end)
    end

    local function Clue(g)
        local n = g.spyN
        local what = n and g.clueOrder[#g.clues + 1]
        if not what then return end
        local text
        if what == "tbl" then text = "You overhear a whisper from the table " .. LC.SpyTables[n.tbl] .. ": \"...the old bridge, after curfew...\""
        elseif what == "man" then text = n.man == 1 and "The whisper was in a man's voice." or "The whisper was in a woman's voice."
        else text = "You glimpse a " .. LC.SpyTints[n.tint][1] .. " sleeve as someone hides a note." end
        g.clues[#g.clues + 1] = text
        g.dirty = true
        for _, q in ipairs(Everyone(g)) do Notice(q, "info", "Overheard", text, 7) end
    end
    -- Time's up: the spy and everyone's pick, shown to everyone.
    local function Reveal(g, players)
        local spy = g.spyN
        g.phase, g.at, g.dirty = "reveal", CurTime() + LC.SpyReveal, true
        local lines = {}
        for _, p in ipairs(players) do
            local s = g.pl[p]
            local n = s.pick and g.npcs[s.pick]
            if n == spy then
                s.score = (s.score or 0) + 1
                lines[#lines + 1] = p:Nick() .. ": found the spy"
            elseif n then
                lines[#lines + 1] = p:Nick() .. ": reported " .. Describe(n) .. ", who is loyal"
            else
                lines[#lines + 1] = p:Nick() .. ": reported nobody"
            end
        end
        g.results = lines
        SayAs(g, "spy_caught")
        for _, q in ipairs(Everyone(g)) do Notice(q, "info", "The spy was " .. Describe(spy), table.concat(lines, ". ") .. ".", 8) end
        for _, p in ipairs(players) do
            local s = g.pl[p]
            local n = s.pick and g.npcs[s.pick]
            if n and n ~= spy then Offend(g, p, "A loyal citizen", "You reported " .. Describe(n) .. ", who is entirely loyal. The officer writes down your name instead.")
            elseif not n then Offend(g, p, "Reported nobody", "A good citizen always has someone to report.") end
        end
        -- unmasked: the spy swells to a giant, glows red and floats off into the sky
        Rifle(g, spy, false)
        Salute(spy, 0)
        Redden(spy.e, 6)
        g.villains = { spy.e }
        if IsValid(spy.e) then Snd(spy.e, "vo/npc/male01/no02.wav", 90, 60) end
        timer.Simple(LC.SpyReveal - 0.5, function() if g and not g.stopped and IsValid(spy.e) and spy.e.SetNoDraw then spy.e:SetNoDraw(true) end end)
    end

    -- E on a diner: the first one your line of sight passes through (within reach), as a press of E would.
    function LC.SpyAimed(g, p)
        local eye = p.GetShootPos and p:GetShootPos() or (p:GetPos() + Vector(0, 0, 64))
        local aim = p.GetAimVector and p:GetAimVector()
        local best, bestT
        for i, n in ipairs(g.npcs) do
            if IsValid(n.e) and not (n.e.GetNoDraw and n.e:GetNoDraw()) then
                for _, h in ipairs({ 20, 45, 70 }) do -- (their body, feet to head)
                    local v = (n.pos + Vector(0, 0, h)) - eye
                    local t = aim and v:Dot(aim) or v:Length()
                    local off = aim and (v - aim * t):Length() or 0
                    if t > 0 and t <= LC.SpyPickReach and off <= LC.SpyPickRadius and (not bestT or t < bestT) then best, bestT = i, t end
                end
            end
        end
        return best
    end
    local function Used(s, p)
        local d = p.KeyDown ~= nil and IN_USE ~= nil and p:KeyDown(IN_USE) == true
        local was = s.useWas
        s.useWas = d
        return d and not was
    end

    function def.build(g, dream)
        local x0, x1, top = Hall(g, dream, 2, Color(95, 95, 85))
        local c = dream.pos
        local half = (x1 - x0) / 2
        g.top = top
        local spots = { { c.x + half * 0.45, c.y + 200 }, { c.x + half * 0.45, c.y - 200 }, { c.x - half * 0.2, c.y - 200 }, { c.x - half * 0.2, c.y + 200 } }
        g.npcs = {}
        for t, xy in ipairs(spots) do
            if K.ValidModel("models/props_c17/furnituretable001a.mdl") then
                Block(g, "models/props_c17/furnituretable001a.mdl", Vector(xy[1], xy[2], top + 18), Angle(0, 0, 0))
            end
            for k, off in ipairs({ { -55, -50 }, { 55, -50 }, { 0, 62 } }) do
                local at = Vector(xy[1] + off[1], xy[2] + off[2], top)
                local yaw = math.deg(math.atan2(xy[2] - at.y, xy[1] - at.x))
                local e = Actor(g, MEN[k], at, yaw, 1, ACT_IDLE or 1)
                g.npcs[#g.npcs + 1] = { e = e, pos = at, seatPos = at, tablePos = Vector(xy[1], xy[2], top), tbl = t, seat = k, man = 1, tint = 1, yaw = yaw }
            end
        end
        -- Each table's corner dressed as what it's called (the owner, 13 November: "can we have a few props
        -- next to the table that says 'next to kitchen'? Like a fridge and stove or something? the dream is
        -- so bare"): a fridge, stove and sink by the kitchen, a radiator and plant pots under the window,
        -- a door and coat rack by the door, a frame and sideboard under her portrait. Each stands on the
        -- floor beyond its table, out of the way of the diners; a model this install lacks is left out.
        local function Stand(model, x, y, yaw)
            if not K.ValidModel(model) then return nil end
            local e = Block(g, model, Vector(x, y, top), Angle(0, yaw or 0, 0))
            if IsValid(e) and e.OBBMins then
                local mins = e:OBBMins()
                if mins and mins.z then e:SetPos(Vector(x, y, top - mins.z)) end
            end
            return e
        end
        LC.SpyDressing = {
            { { "models/props_interiors/radiator01a.mdl", -40, 0 }, { "models/props_junk/terracotta01.mdl", 30, 0 }, { "models/props_junk/terracotta01.mdl", 70, 0 } },
            { { "models/props_c17/furniturefridge001a.mdl", -60, 0 }, { "models/props_c17/furniturestove001a.mdl", 0, 0 }, { "models/props_interiors/sinkkitchen01a.mdl", 62, 0 } },
            { { "models/props_c17/door01_left.mdl", -30, 90 }, { "models/props_c17/coatrack001a.mdl", 45, 0 } },
            { { "models/props_c17/frame002a.mdl", 0, 0 }, { "models/props_c17/furnituredresser001a.mdl", 0, 0 } },
        }
        g.dressing = {}
        for t, xy in ipairs(spots) do
            local out = xy[2] >= c.y and 1 or -1 -- (the side of the hall this table is on)
            for _, d in ipairs(LC.SpyDressing[t] or {}) do
                local e = Stand(d[1], xy[1] + d[2], xy[2] + out * 170, (out > 0 and 270 or 90) + (d[3] or 0))
                if IsValid(e) then g.dressing[#g.dressing + 1] = e end
            end
        end
        -- (the frame hangs, it doesn't stand on the floor)
        for _, e in ipairs(g.dressing) do
            if IsValid(e) and e.GetModel and e:GetModel() == "models/props_c17/frame002a.mdl" then
                local v = e:GetPos()
                e:SetPos(Vector(v.x, v.y, top + 110))
            end
        end
        -- her portrait's end of the hall (the salute), and the wall the firing squad faces
        g.portrait = Vector(x1 - 40, c.y, top + 120)
        g.squadX, g.squadGap = x1 - 560, 56
        g.squadY0 = c.y - g.squadGap * (#g.npcs - 1) / 2
        g.rebels = {}
        for i, dy in ipairs({ -90, 0, 90 }) do
            local m = LC.PropagandaRebels[i] or LC.PropagandaRebels[1]
            local e = Actor(g, m, Vector(x1 - 70, c.y + dy, top), 180, 1, ACT_IDLE or 1)
            if IsValid(e) and e.SetNoDraw then e:SetNoDraw(true) end
            g.rebels[#g.rebels + 1] = e
        end
        -- a spotlight on the wall, lit for the firing squad
        if ents and ents.Create then
            local l = ents.Create("light_dynamic")
            if IsValid(l) then
                l:SetPos(Vector(x1 - 260, c.y, top + 220))
                l:SetAngles(Angle(35, 0, 0))
                if l.SetKeyValue then
                    l:SetKeyValue("_light", "255 245 215 900") l:SetKeyValue("distance", "520")
                    l:SetKeyValue("_cone", "40") l:SetKeyValue("_inner_cone", "25") l:SetKeyValue("brightness", "6")
                end
                l:Spawn()
                if l.Fire then l:Fire("TurnOff") end
                g.ents[#g.ents + 1] = l
                g.spot = l
            end
        end
        g.round, g.phase, g.at = 0, "wait", CurTime() + 8
        -- (a sign over each table, so "the table by the window" can be found: the client draws them, cl_livingcity_dreamgames.lua)
        g.signs = {}
        for t, xy in ipairs(spots) do g.signs[#g.signs + 1] = { math.floor(xy[1]), math.floor(xy[2]), math.floor(top + 120), "Table " .. LC.SpyTables[t] } end
        for _, n in ipairs(g.npcs) do n.man, n.tint = math.random(2), math.random(#LC.SpyTints) Look(n) end
        Starts(g, x0 + 90, c.y, top)
        return true
    end
    def.hello = Hello("propaganda", "spy_hello")

    function def.tick(g, dt, players)
        local now = CurTime()
        if g.phase == "reveal" and g.spyN and IsValid(g.spyN.e) then
            local v = g.spyN.e:GetPos()
            g.spyN.e:SetPos(Vector(v.x, v.y, v.z + 120 * dt))
            g.spyN.e:SetAngles(Angle(0, now * 90 % 360, 0))
        end
        if g.phase == "pick" then
            g.villains = nil
            if g.kind == "chat" then
                local at = LC.SpyClueAt[#g.clues + 1]
                if at and now >= g.roundT0 + at then Clue(g) end
                LC.SpyGlance(g, now)
                LC.SpyTalk(g, now)
            elseif g.kind == "salute" then
                LC.SpyChant(g, now)
            elseif g.kind == "squad" then
                LC.SpyVolley(g, now)
            end
            for _, p in ipairs(players) do
                local s = g.pl[p]
                if Used(s, p) then
                    local best = LC.SpyAimed(g, p)
                    if best and best ~= s.pick then
                        s.pick, g.dirty = best, true
                        Notice(p, "info", "Your pick", "You'll report " .. Describe(g.npcs[best]) .. ". Nobody else knows. Press E on someone else to change your mind.", 4)
                    end
                end
            end
        end
        if now < g.at then return end
        if g.phase == "pick" then Reveal(g, players) return end
        if g.round >= LC.SpyRounds then
            g.phase, g.at = "over", math.huge
            for _, p in ipairs(players) do
                local n = g.pl[p].score or 0
                if n >= def.need then Done(g, p, "won", "Vigilant citizen", string.format("You found the spy in %d of %d rounds. The canteen applauds you.", n, LC.SpyRounds))
                else Done(g, p, "time", "The canteen empties", string.format("You found the spy in %d of %d rounds. The lights go off, and you wake.", n, LC.SpyRounds)) end
            end
            return
        end
        NewRound(g)
    end

    function def.state(g, p)
        local glows = {}
        if g.phase == "reveal" and g.spyN then local v = g.spyN.pos glows[1] = { math.floor(v.x), math.floor(v.y), math.floor(v.z) + 85, 7 } end
        local s = p and g.pl[p] or {}
        if s.pick and g.phase == "pick" and g.npcs[s.pick] then local v = g.npcs[s.pick].pos glows[#glows + 1] = { math.floor(v.x), math.floor(v.y), math.floor(v.z) + 85, 6 } end
        local big, notes = nil, g.clues
        local left = math.max(0, math.ceil((g.at or 0) - CurTime()))
        if g.phase == "pick" then
            big = s.pick and string.format("Your pick: %s (%d seconds to change your mind)", Describe(g.npcs[s.pick]), left) or string.format("Press E on the one you suspect: %d seconds left.", left)
        elseif g.phase == "reveal" and g.spyN then
            big, notes = "The spy was " .. Describe(g.spyN) .. "!", g.results
        elseif g.phase == "wait" then big = "Watch and listen. The first round is about to begin." end
        return { glows = glows, notes = notes, big = big, tone = g.phase == "reveal" and "warn" or "love", villains = Villains(g),
            signs = g.kind ~= "squad" and g.signs or nil,
            meterName = string.format("Round %d of %d   |   Spies found: %d (you need %d)", math.max(1, g.round), LC.SpyRounds, s.score or 0, def.need) }
    end
end

------------------------------------------------------------------------
-- The Newsreel (a party game: everyone at once, each their own cue, then the reveal)
------------------------------------------------------------------------

do
    LC.NewsreelTakes, LC.NewsreelWindow, LC.NewsreelCut = 8, 5, 3
    local def = { id = "newsreel", name = "The Newsreel", mood = "happy", secs = 8 + LC.NewsreelTakes * (LC.NewsreelWindow + LC.NewsreelCut + 1) + 8, lives = 3, need = 5,
        music = { "newsreel", "propaganda" },
        goal = "Smile for the newsreel. When the camera rolls, each of you is told what to do: say wave, salute or cheer in chat before it cuts. The takes are shown at the end.",
        timeUp = { "The reel runs out", "The film flaps off the end of the reel, and you wake." }, spawn = Spawn,
        woke = Woke({
            won = { "Star of the screen", "You wake still smiling for a camera that isn't there. Your cheeks ache." },
            out = { "Cut!", "You wake feeling you ruined every take. In the morning you practise your salute in the mirror." },
            time = { "The reel runs out", "You wake, and for a moment the world is still black and white." },
        }) }
    G.newsreel = def
    LC.NewsreelActs = { wave = { "wave", "waves", "waving", "hello", "hi" }, salute = { "salute", "salutes", "saluting" },
        cheer = { "cheer", "cheers", "cheering", "hooray", "hurray", "hurrah", "huzzah", "yay" } }
    local WORD = {}
    for act, list in pairs(LC.NewsreelActs) do for _, w in ipairs(list) do WORD[w] = act end end
    local ACTS = { "wave", "salute", "cheer" }
    local PAST = { wave = "waved", salute = "saluted", cheer = "cheered" }
    LC.NewsreelLines = {
        "Here are my happy citizens on their way to work! Look at that loyalty!",
        "Rations are up again this week. Nobody can remember them ever being down!",
        "My city's children are healthy, cheerful and remarkably quiet!",
        "A smile costs nothing, and in my city it is mandatory!",
        "My brave Civil Protection: always watching, always caring!",
        "Look at that enthusiasm! You can't fake that!",
    }

    function def.build(g, dream)
        local x0, x1, top = Hall(g, dream, 2, Color(130, 130, 130))
        local c = dream.pos
        g.cam = Actor(g, "models/dav0r/camera.mdl", Vector(x1 - 120, c.y, top + 60), 180, 4)
        g.take, g.phase, g.at = 0, "wait", CurTime() + 8
        Cheering(g, { Vector(x1 - 260, c.y - PLATE8_S + 60, top), Vector(x1 - 260, c.y + PLATE8_S - 60, top) }, Vector(x0, c.y, top))
        Starts(g, x0 + 90, c.y, top)
        return true
    end
    def.hello = Hello("newsreel", "newsreel_hello")

    -- Cut: every take shown to everyone.
    local function Cut(g, players)
        g.phase, g.at, g.dirty = "cut", CurTime() + LC.NewsreelCut, true
        local lines = {}
        for _, p in ipairs(players) do
            local s = g.pl[p]
            if s.did == s.cue then
                s.score = (s.score or 0) + 1
                lines[#lines + 1] = p:Nick() .. " " .. PAST[s.cue] .. " beautifully"
            elseif s.did then
                lines[#lines + 1] = p:Nick() .. " " .. PAST[s.did] .. " instead of " .. (s.cue == "salute" and "saluting" or s.cue .. "ing")
            else
                lines[#lines + 1] = p:Nick() .. " just stood there"
            end
        end
        g.results = lines
        Narrate(g, "The Administrator", LC.NewsreelLines[(g.take - 1) % #LC.NewsreelLines + 1])
        for _, q in ipairs(Everyone(g)) do Notice(q, "info", string.format("Cut! Take %d", g.take), table.concat(lines, ". ") .. ".", 6) end
        for _, p in ipairs(players) do
            local s = g.pl[p]
            if s.did and s.did ~= s.cue then Offend(g, p, "Wrong on camera", "The camera wanted you to " .. s.cue .. ", and you " .. PAST[s.did] .. ". Take two will not be needed.")
            elseif not s.did then Offend(g, p, "Caught looking glum", "The camera rolled and you just stood there. She coughs.") end
        end
    end

    function def.tick(g, dt, players)
        local now = CurTime()
        if IsValid(g.cam) then g.cam:SetAngles(Angle(0, 180 + math.sin(now * 0.8) * 35, 0)) end
        if now < g.at then return end
        if g.phase == "roll" then Cut(g, players) return end
        if g.take >= LC.NewsreelTakes then
            g.phase, g.at = "over", math.huge
            SayAs(g, "newsreel_end")
            for _, p in ipairs(players) do
                local n = g.pl[p].score or 0
                if n >= def.need then Done(g, p, "won", "Star of the screen", string.format("%d good takes out of %d. The Administrator calls you the happiest citizen in the city.", n, LC.NewsreelTakes))
                else Done(g, p, "time", "The reel runs out", string.format("%d good takes out of %d. The film runs out, and you wake.", n, LC.NewsreelTakes)) end
            end
            return
        end
        g.take, g.phase, g.dirty = g.take + 1, "roll", true
        g.at = now + math.max(3.5, LC.NewsreelWindow - (g.take - 1) * 0.2)
        if IsValid(g.cam) then Snd(g.cam, "buttons/lightswitch2.wav", 75, 80) end
        for _, p in ipairs(players) do
            local s = g.pl[p]
            s.cue, s.did = ACTS[math.random(#ACTS)], nil
            Notice(p, "warn", string.format("Rolling! Take %d", g.take), "The camera wants you to " .. string.upper(s.cue) .. "! (say " .. s.cue .. " in chat)", 4)
        end
    end

    function LC.NewsreelSaid(g, p, text)
        local s = g.pl[p]
        if not s or s.done then return false end
        Echo(g, p, text)
        if g.phase ~= "roll" or s.did then return true end
        for w in string.gmatch(string.lower(text), "%a+") do
            if WORD[w] then
                s.did, g.dirty = WORD[w], true
                Notice(p, "info", "In the can", "You " .. PAST[s.did] .. " for the camera. Hold that smile until the cut.", 3)
                break
            end
        end
        return true
    end
    def.say = LC.NewsreelSaid

    function def.state(g, p)
        local s = p and g.pl[p] or {}
        local big, tone, notes = nil, "love", nil
        if g.phase == "roll" and s.cue then
            if s.did then big = "You " .. PAST[s.did] .. ". Hold that smile."
            else big, tone = "Rolling! The camera wants you to " .. string.upper(s.cue) .. " (say " .. s.cue .. ")", "warn" end
        elseif g.phase == "cut" then big, notes = "Cut!", g.results
        else big = "Smile, citizens. The camera is about to roll." end
        return { big = big, tone = tone, notes = notes,
            meterName = string.format("Take %d of %d     Good takes: %d of %d needed", math.max(1, g.take), LC.NewsreelTakes, s.score or 0, def.need) }
    end
end

------------------------------------------------------------------------
-- Two Minutes of Hate
------------------------------------------------------------------------

do
    local def = { id = "hate", name = "Two Minutes of Hate", mood = "happy", secs = 120, lives = 3, need = 15, music = { "hate", "propaganda" },
        goal = "The enemy of the people is on the screen. Jeer at him in chat (a word nobody has used yet counts double). Staying silent is noticed.",
        timeUp = { "The screen goes dark", "Two minutes are up. The screen goes dark, and you wake." }, spawn = Spawn,
        woke = Woke({
            won = { "Exemplary hatred", "You wake hoarse and oddly calm, as if something was let out of you. You feel very loyal." },
            out = { "Silence is noticed", "You wake with a dry mouth and the feeling that someone was watching you not shout." },
            time = { "The screen goes dark", "You wake with the face from the screen fading behind your eyes." },
        }) }
    G.hate = def
    LC.HateJeers = { "traitor", "traitors", "scum", "boo", "booo", "coward", "criminal", "terrorist", "vermin", "liar", "rat", "filth", "murderer",
        "thug", "enemy", "shame", "pathetic", "loser", "anticitizen", "degenerate", "villain", "monster", "menace", "worm", "snake", "heretic",
        "saboteur", "wrecker", "parasite", "nerd", "fraud", "deserter", "bandit", "hooligan", "lowlife", "weasel", "creep", "outlaw", "agitator",
        "malcontent", "disgrace", "disgusting", "despicable", "treacherous", "spineless", "vile", "wretch", "hate", "death", "down" }
    LC.HatePraise = { "hero", "heroes", "legend", "lambda", "revolution", "uprising", "overthrow", "liberator", "saviour", "savior", "messiah",
        "idol", "freedom", "inspiring", "brave" }
    local JEER, PRAISE = SetOf(LC.HateJeers), SetOf(LC.HatePraise)
    for _, w in ipairs(LC.CombineInsults or {}) do PRAISE[w] = true end
    LC.HateSilence = 15

    function def.build(g, dream)
        local x0, x1, top = Hall(g, dream, 2, Color(50, 50, 55))
        local c = dream.pos
        g.screenAt = Vector(x1 - 30, c.y, top + 180)
        g.rebelAt = Vector(x1 - 90, c.y + PLATE8_S - 120, top + 60)
        g.rebel = Villain(g, LC.PropagandaRebels, g.rebelAt, 180, 5)
        local spots = {}
        for i = 0, 3 do for _, dy in ipairs({ -PLATE8_S + 70, PLATE8_S - 70 }) do spots[#spots + 1] = Vector(x0 + 200 + i * 110, c.y + dy, top) end end
        Cheering(g, spots, g.screenAt)
        g.used = {}
        Starts(g, x0 + 90, c.y, top)
        return true
    end
    def.hello = Hello("hate", "hate_hello")

    function def.tick(g, dt, players)
        local now = CurTime()
        if IsValid(g.rebel) then -- (bobbing and turning in the air, glowing red, sneering at them all)
            g.rebel:SetPos(g.rebelAt + Vector(0, math.sin(now * 0.7) * 80, 40 + math.sin(now * 1.3) * 30))
            g.rebel:SetAngles(Angle(0, 180 + math.sin(now) * 40, 0))
        end
        if not g.ended and now >= g.ends - 3 then g.ended = true SayAs(g, "hate_end") end
        for _, p in ipairs(players) do
            local s = g.pl[p]
            s.lastJeer = s.lastJeer or (g.t0 + 6)
            if now - s.lastJeer > LC.HateSilence and not Grace(s) then
                s.lastJeer = now
                Offend(g, p, "Silence is noticed", "Everyone else was shouting. You weren't. The screen noticed.")
            end
        end
    end

    function LC.HateSaid(g, p, text)
        local s = g.pl[p]
        if not s or s.done then return false end
        Echo(g, p, text)
        s.mine, s.score = s.mine or {}, s.score or 0
        local jeered, praised, gain = false, nil, 0
        for w in string.gmatch(string.lower(text), "%a+") do
            if PRAISE[w] then praised = w
            elseif JEER[w] then
                jeered = true
                if not s.mine[w] then
                    s.mine[w] = true
                    gain = gain + 1
                    if not g.used[w] then g.used[w] = true gain = gain + 1 end
                end
            end
        end
        if praised then
            Offend(g, p, "Thoughtcrime", "\"" .. praised .. "\"? The shouting stops. Everyone turns to look at you.")
            return true
        end
        if not jeered then return true end
        s.lastJeer, s.score, g.dirty = CurTime(), s.score + gain, true
        if s.score >= def.need then Done(g, p, "won", "Exemplary hatred", "Your fury is magnificent. The people near you edge away, impressed.") end
        return true
    end
    def.say = LC.HateSaid

    function def.state(g, p)
        local s = p and g.pl[p] or {}
        local board = Board(g.screenAt, 180, "ENEMY OF THE PEOPLE", { "Wanted for crimes against the city", "Do not trust. Do not help. Report." }, "freeman")
        local big, tone = nil, "warn"
        if not s.done and p and IsValid(p) then
            local quiet = CurTime() - (s.lastJeer or g.t0)
            big = quiet > LC.HateSilence - 6 and "You've gone quiet. JEER!" or "Jeer at the enemy in chat!"
        end
        return { board = board, big = big, tone = tone, villains = Villains(g), meter = math.floor(math.min(1, (s.score or 0) / def.need) * 100),
            meterName = string.format("Hatred: %d of %d", s.score or 0, def.need) }
    end
end

------------------------------------------------------------------------
-- The Mass Games
------------------------------------------------------------------------

do
    LC.MassRounds, LC.MassReady, LC.MassShow = 10, 6, 3
    local def = { id = "massgames", name = "The Mass Games", mood = "happy", secs = 8 + LC.MassRounds * (LC.MassReady + LC.MassShow) + 6, lives = 3, need = 6,
        music = { "massgames", "propaganda" },
        goal = "Stay on your seat in the stands. For each picture you're told your card's colour: gold, crouch; red, stand. Show it when she calls FLIP!",
        timeUp = { "The stadium empties", "The floodlights go off and you wake." },
        woke = Woke({
            won = { "One of a hundred thousand", "You wake with your arms still raised, holding a card that isn't there. Together, you were her face." },
            out = { "A hole in her portrait", "You wake sure that, somewhere in the stands, everyone is still looking at the gap where you were." },
            time = { "The stadium empties", "You wake hearing a hundred thousand cards flip at once." },
        }) }
    G.massgames = def

    function def.build(g, dream)
        local x0, x1, top = Hall(g, dream, 2, Color(60, 60, 90))
        local c = dream.pos
        g.starts = {}
        for row = 0, 2 do for col = 0, 3 do g.starts[#g.starts + 1] = Vector(x0 + 160 + col * 110, c.y - 110 + row * 110, top + 4) end end
        g.mosaicAt = Vector(x1 - 20, c.y, top + 60)
        g.round, g.phase, g.at = 0, "wait", CurTime() + 8
        return true
    end
    function def.spawn(g, p, i) return Spawn(g, p, i) end
    def.hello = Hello("propaganda", "massgames_hello")

    function def.tick(g, dt, players)
        local now = CurTime()
        if now < g.at then return end
        if g.phase == "ready" then -- (FLIP!)
            g.phase, g.at, g.dirty = "show", now + LC.MassShow, true
            SayAs(g, "massgames_flip")
            local right = 0
            for _, p in ipairs(players) do
                local s = g.pl[p]
                local gold = Kneeling(p)
                local seated = Dist2(p:GetPos(), s.start) < 60
                if seated and (s.want == "gold") == gold then
                    s.score, right = (s.score or 0) + 1, right + 1
                    Notice(p, "info", "Perfect", string.format("Your card is exactly right. %d of %d.", s.score, def.need), 3)
                elseif not seated then
                    Offend(g, p, "Out of your seat", "Your seat in the stands was empty when the cards flipped.")
                else
                    Offend(g, p, "Wrong colour", "Your card was the wrong colour, and her portrait has a hole in it.")
                end
            end
            if right > 0 then g.shown = (g.shown or 0) + 1 end
            return
        end
        if g.round >= LC.MassRounds then
            g.at = math.huge
            for _, p in ipairs(players) do
                if (g.pl[p].score or 0) >= def.need then Done(g, p, "won", "One of a hundred thousand", "The last card flips and there she is, a hundred metres tall, made of all of you.")
                else Done(g, p, "time", "The stadium empties", "The portrait is finished without you. You wake.") end
            end
            return
        end
        g.round, g.phase, g.at, g.dirty = g.round + 1, "ready", now + LC.MassReady, true
        for _, p in ipairs(players) do g.pl[p].want = math.random(2) == 1 and "gold" or "red" end
    end

    function def.state(g, p)
        local s = p and g.pl[p] or {}
        local big, tone = nil, "love"
        if not s.done then
            if g.phase == "ready" and s.want then big, tone = string.format("Picture %d: your card is %s (%s)", g.round, string.upper(s.want), s.want == "gold" and "crouch" or "stand"), "warn"
            elseif g.phase == "show" then big = "Hold it..."
            else big = "Take your seat. Cards ready." end
        end
        return { mosaic = { g.mosaicAt.x, g.mosaicAt.y, g.mosaicAt.z, 180, shown = (g.shown or 0) / LC.MassRounds }, big = big, tone = tone,
            meter = math.floor(math.min(1, (s.score or 0) / def.need) * 100), meterName = string.format("Pictures right: %d of %d     Picture %d of %d", s.score or 0, def.need, math.max(1, g.round), LC.MassRounds) }
    end
end

------------------------------------------------------------------------
-- On-the-Spot Guidance
------------------------------------------------------------------------

do
    LC.GuidanceStops, LC.GuidanceClap = 8, 3
    local def = { id = "guidance", name = "On-the-Spot Guidance", mood = "happy", secs = 150, lives = 3, music = { "guidance", "propaganda" },
        goal = "Follow her round the factory. Each time she points at something, applaud (jump, or say clap): whoever doesn't, or is last, loses a life.",
        starGoal = "You're the star: tour the factory and give guidance. Every so often you point at something and they must applaud. Say anything in chat and the dream hears you.",
        timeUp = { "The tour is over", "She moves on to the next factory, and you wake." }, spawn = Spawn,
        woke = Woke({
            won = { "Model of enthusiasm", "You wake with stinging palms and the warm memory of her nod. The lathe has never been better." },
            out = { "Insufficient applause", "You wake clapping, alone, in the dark. It's a little embarrassing." },
            time = { "The tour is over", "You wake still nodding along to guidance you can't remember." },
        }) }
    G.guidance = def
    LC.GuidanceLines = {
        "This lathe! Excellent. Make more of it, faster.",
        "Who polished this bolt? Promote them.",
        "This pipe should go the other way. Write that down.",
        "I see great potential in this bucket.",
        "Paint this wall a more loyal colour.",
        "This machine is working. Good. It must never stop.",
        "These boxes are stacked with real devotion.",
        "Remarkable. I have no notes. Here are my notes.",
    }
    local CLAP = SetOf({ "clap", "claps", "clapping", "applaud", "applause", "applauds", "bravo", "hooray", "hurrah", "encore" })
    local MACHINES = { "models/props_c17/furnitureboiler001a.mdl", "models/props_wasteland/laundry_washer003.mdl", "models/props_c17/trappropeller_engine.mdl",
        "models/props_wasteland/kitchen_stove001a.mdl" }

    function def.build(g, dream)
        local x0, x1, top = Hall(g, dream, 4, Color(85, 90, 85))
        local c = dream.pos
        g.stops = {}
        local n = 4
        for i = 0, n - 1 do
            local x = x0 + 300 + i * (x1 - x0 - 500) / (n - 1)
            local side = (i % 2 == 0) and 1 or -1
            local m = MACHINES[i + 1]
            if K.ValidModel(m) then Block(g, m, Vector(x, c.y + side * (PLATE8_S - 90), top + 30), Angle(0, side * 90, 0)) end
            g.stops[#g.stops + 1] = Vector(x, c.y + side * (PLATE8_S - 220), top)
        end
        g.herStart = Vector(x0 + 160, c.y, top)
        if not g.star then
            g.her = Actor(g, LC.AdmireModel(), g.herStart, 0, 1.3, ACT_WALK or 1)
        end
        g.n, g.phase, g.at = 0, "start", CurTime() + 5
        Starts(g, x0 + 90, c.y, top)
        return true
    end
    function def.starring(g, p) StarAt(p, g.herStart, 0, 1.25, false) end
    function def.starGone(g, p)
        local at = IsValid(p) and p:GetPos() or g.herStart
        g.her = Actor(g, LC.AdmireModel(), at, 0, 1.3, ACT_IDLE or 1)
        g.dirty = true
    end
    def.hello = Hello("propaganda", "guidance_hello")

    local function Clapped(g, p)
        local s = g.pl[p]
        if g.phase ~= "clap" or s.clapAt then return end
        s.clapAt = CurTime()
        Snd(p, "player/footsteps/tile1.wav", 70, 160)
    end
    LC.GuidanceClapped = Clapped

    function def.tick(g, dt, players)
        local now = CurTime()
        for _, p in ipairs(players) do if Jumped(g.pl[p], p) then Clapped(g, p) end end
        local her = IsValid(g.star) and g.star or g.her
        if g.phase == "walk" and not IsValid(g.star) and IsValid(g.her) then
            local to = g.stops[(g.n - 1) % #g.stops + 1]
            local pos = g.her:GetPos()
            local d = to - pos
            d.z = 0
            local len = d:Length()
            if len > 4 then
                local step = math.min(len, 110 * dt)
                g.her:SetPos(pos + d:GetNormalized() * step)
                g.her:SetAngles(Angle(0, math.deg(math.atan2(d.y, d.x)), 0))
            else
                g.at = now
            end
        end
        if now < g.at then return end
        if g.phase == "start" or g.phase == "next" then
            if g.n >= LC.GuidanceStops then
                g.phase, g.at = "over", math.huge
                SayAs(g, "guidance_end")
                for _, p in ipairs(players) do Done(g, p, "won", "Model of enthusiasm", "She nods at you, once, on her way out. Your applause has been noted, favourably.") end
                return
            end
            g.n, g.phase, g.at = g.n + 1, "walk", now + (IsValid(g.star) and 9 or 12)
            if IsValid(g.her) and K.Animate then K.Animate(g.her, ACT_WALK) end
        elseif g.phase == "walk" then
            g.phase, g.at, g.dirty = "talk", now + 2.5, true
            if IsValid(g.her) and K.Animate then K.Animate(g.her, ACT_IDLE) end
            if IsValid(g.her) and IsValid(her) then
                local face = g.stops[(g.n - 1) % #g.stops + 1]
                g.her:SetAngles(Angle(0, face.y > g.dream.pos.y and 90 or -90, 0))
            end
            if not IsValid(g.star) then Narrate(g, "The Administrator", LC.GuidanceLines[(g.n - 1) % #LC.GuidanceLines + 1])
            else for _, q in ipairs(Everyone(g)) do Notice(q, "info", "Guidance", "She points at something.", 3) end end
        elseif g.phase == "talk" then
            g.phase, g.at, g.dirty = "clap", now + LC.GuidanceClap, true
            for _, p in ipairs(players) do g.pl[p].clapAt = nil end
        elseif g.phase == "clap" then
            g.phase, g.at, g.dirty = "next", now + 1, true
            local late, lateAt, missed = nil, -1, {}
            for _, p in ipairs(players) do
                local s = g.pl[p]
                if not s.clapAt then missed[#missed + 1] = p elseif s.clapAt > lateAt then late, lateAt = p, s.clapAt end
            end
            for _, p in ipairs(missed) do Offend(g, p, "No applause", "She pointed, and you didn't applaud. Her smile flickers.") end
            if #players >= 2 and #missed == 0 and late then Offend(g, late, "Last to applaud", "You were the last to applaud. Everyone saw.") end
        end
    end

    function LC.GuidanceSaid(g, p, text)
        local s = g.pl[p]
        if not s or s.done then return false end
        Echo(g, p, text)
        for w in string.gmatch(string.lower(text), "%a+") do if CLAP[w] then Clapped(g, p) break end end
        return true
    end
    def.say = LC.GuidanceSaid

    function def.state(g, p)
        local big, tone = nil, "love"
        if g.phase == "clap" then big, tone = "APPLAUD! (jump, or say clap)", "warn"
        elseif g.phase == "talk" then big = "She gives guidance..."
        else big = "Follow the tour." end
        if p == g.star then local t = StarState(g, g.phase == "clap" and "They applaud you." or "Tour your factory.") return t end
        local s = p and g.pl[p] or {}
        if s.clapAt and g.phase == "clap" then big, tone = "You're applauding. Wonderful.", "love" end
        return { big = big, tone = tone, herEnt = HerEnt(g), meterName = string.format("Stop %d of %d", math.max(1, g.n), LC.GuidanceStops) }
    end
end

------------------------------------------------------------------------
-- The Scrap Drive
------------------------------------------------------------------------

do
    local def = { id = "scrap", name = "The Scrap Drive", mood = "happy", secs = 180, lives = 3, need = 9, carry = 3, music = { "scrap", "propaganda" },
        goal = "Gather scrap metal (walk over it, three at a time) and put it in the collection bins. Don't sell it to the shady trader.",
        timeUp = { "The drive is over", "The lorries take the bins away, and you wake." }, spawn = Spawn,
        woke = Woke({
            won = { "Hero of the Home Front", "You wake and look at your cooking pot with suspicion. It could be a part for something." },
            out = { "Black marketeer", "You wake with the feeling you sold something you shouldn't have. You check your pockets." },
            time = { "The drive is over", "You wake hearing scrap clatter into a bin, very far away." },
        }) }
    G.scrap = def
    local JUNK = { "models/props_junk/metalbucket01a.mdl", "models/props_c17/metalpot001a.mdl", "models/props_junk/garbage_metalcan001a.mdl",
        "models/props_interiors/pot01a.mdl", "models/props_c17/metalpot002a.mdl", "models/props_junk/metalbucket02a.mdl" }

    local function Place(g, i)
        local j = g.junk[i]
        j.pos = Vector(math.Rand(g.x0 + 150, g.x1 - 450), g.midY + math.Rand(-g.halfW, g.halfW), g.top + 8)
        j.gone = nil
        if IsValid(j.e) then j.e:SetPos(j.pos) if j.e.SetNoDraw then j.e:SetNoDraw(false) end end
    end

    function def.build(g, dream)
        local x0, x1, top = Hall(g, dream, 4, Color(80, 72, 62))
        local c = dream.pos
        g.x0, g.x1, g.midY, g.halfW = x0, x1, c.y, PLATE8_S - 70
        g.junk = {}
        for i = 1, 12 do
            g.junk[i] = { e = Actor(g, JUNK[(i - 1) % #JUNK + 1], c, math.random(0, 359), 1) }
            Place(g, i)
        end
        g.bins = {}
        for _, dy in ipairs({ -200, 0, 200 }) do
            local at = Vector(x1 - 120, c.y + dy, top)
            g.bins[#g.bins + 1] = at
            Actor(g, "models/props_trainstation/trashcan_indoor001a.mdl", at, 180, 1.6)
        end
        g.spivAt = Vector(x0 + (x1 - x0) * 0.55, c.y + PLATE8_S - 50, top)
        local e = Actor(g, "models/humans/group02/male_08.mdl", g.spivAt, -90, 1, ACT_IDLE or 1)
        Pose(e, { "LineIdle01", "idle_subtle" }, ACT_IDLE)
        g.total = 0
        g.boardAt = Vector(x1 - 30, c.y - PLATE8_S + 150, top + 170)
        Starts(g, x0 + 90, c.y, top)
        return true
    end
    def.hello = Hello("propaganda", "scrap_hello")

    function def.tick(g, dt, players)
        local now = CurTime()
        for i, j in ipairs(g.junk) do if j.gone and now >= j.gone then Place(g, i) g.dirty = true end end
        for _, p in ipairs(players) do
            local s = g.pl[p]
            s.carry, s.given = s.carry or 0, s.given or 0
            local pos = p:GetPos()
            local spiv = Dist2(pos, g.spivAt)
            if s.carry > 0 and spiv < 90 and not Grace(s) then
                local n = s.carry
                s.carry, g.dirty = 0, true
                Offend(g, p, "Black market", string.format("You sold %d %s of the war effort for a handful of credits. Somebody saw.", n, n == 1 and "piece" or "pieces"))
            else
                if s.carry > 0 and spiv < 260 and now >= (s.psst or 0) then
                    s.psst = now + 10
                    Notice(p, "info", "A shady trader", "\"Psst. Nice bit of metal. I'll give you real money for it. Nobody needs to know.\"", 4)
                end
                if s.carry < def.carry then
                    for _, j in ipairs(g.junk) do
                        if not j.gone and Dist2(pos, j.pos) < 50 then
                            s.carry, j.gone, g.dirty = s.carry + 1, now + 3, true
                            if IsValid(j.e) and j.e.SetNoDraw then j.e:SetNoDraw(true) end
                            Snd(p, "physics/metal/metal_solid_impact_soft1.wav", 60)
                            break
                        end
                    end
                end
                if s.carry > 0 then
                    for _, b in ipairs(g.bins) do
                        if Dist2(pos, b) < 90 then
                            s.given, g.total, s.carry, g.dirty = s.given + s.carry, g.total + s.carry, 0, true
                            Snd(p, "physics/metal/metal_box_impact_hard1.wav", 70)
                            if s.given >= def.need then
                                if not g.first then g.first = p:Nick() end
                                Done(g, p, "won", "Hero of the Home Front", "Your bin overflows. Somewhere a factory turns your pots into something glorious.")
                            else
                                Notice(p, "info", "For the war effort", string.format("Clang. %d of %d.", s.given, def.need), 3)
                            end
                            break
                        end
                    end
                end
            end
        end
    end

    function def.state(g, p)
        local glows = {}
        for _, j in ipairs(g.junk) do if not j.gone then local f = Flat(j.pos) f[3] = f[3] + 20 f[4] = 3 glows[#glows + 1] = f end end
        for _, b in ipairs(g.bins) do glows[#glows + 1] = { math.floor(b.x), math.floor(b.y), math.floor(b.z) + 70, 1 } end
        local lines = Top(g, "given", 3, "%d. %s  %d")
        table.insert(lines, 1, "Total: " .. Commas(g.total * 4300) .. " kg of metal")
        if g.first then table.insert(lines, 2, "First to fill a bin: " .. g.first) end
        local s = p and g.pl[p] or {}
        local big = nil
        if not s.done then big = (s.carry or 0) >= def.carry and "Arms full: to the bins!" or ((s.carry or 0) > 0 and "Pick up more, or take it to the bins." or "Find scrap metal.") end
        return { glows = glows, board = Board(g.boardAt, 180, "SCRAP FOR THE WAR EFFORT", lines), big = big, tone = "love",
            carryName = (s.carry or 0) > 0 and string.format("%d scrap", s.carry) or nil,
            meter = math.floor(math.min(1, (s.given or 0) / def.need) * 100), meterName = string.format("Scrap given: %d of %d", s.given or 0, def.need) }
    end
end

------------------------------------------------------------------------
-- Flowers for the Liberators
------------------------------------------------------------------------

do
    local def = { id = "flowers", name = "Flowers for the Liberators", mood = "happy", secs = 150, lives = 3, need = 10, music = { "flowers", "propaganda" },
        goal = "Her soldiers march down the street. Throw flowers (jump) as one passes level with you. Never step into the road, and greet every squad.",
        timeUp = { "The parade is over", "The last boots fade down the street, and you wake." }, spawn = Spawn,
        woke = Woke({
            won = { "Grateful citizen", "You wake smelling carnations, and for a moment you love everyone in uniform." },
            out = { "A cold welcome", "You wake ashamed of something. The soldiers in your dream looked so hurt." },
            time = { "The parade is over", "You wake to the memory of marching boots, keeping time with your heart." },
        }) }
    G.flowers = def
    LC.FlowersSquad, LC.FlowersGap, LC.FlowersSpeed, LC.FlowersReach = 6, 140, 90, 70
    local SOLDIER = "models/combine_soldier.mdl"

    local function NewSquad(g)
        g.squadN = (g.squadN or 0) + 1
        for i, m in ipairs(g.marchers) do
            m.x = g.x0 - 40 - (i - 1) * LC.FlowersGap
            m.got = {}
            if IsValid(m.e) then m.e:SetPos(Vector(m.x, m.y, g.top)) if m.e.SetNoDraw then m.e:SetNoDraw(true) end end
        end
        g.squadT0 = CurTime()
        g.dirty = true
    end
    LC.FlowersNewSquad = NewSquad

    function def.build(g, dream)
        local x0, x1, top = Hall(g, dream, 4, Color(95, 88, 72))
        local c = dream.pos
        g.x0, g.x1, g.midY = x0, x1, c.y
        local n = math.floor((x1 - x0) / PLATE4_S)
        for i = 1, n do Floor(g, PLATE4, x0 + (i - 0.5) * PLATE4_S, c.y, top + 1, Color(60, 60, 62), "models/debug/debugwhite") end
        g.road = PLATE4_S / 2
        g.marchers = {}
        for i = 1, LC.FlowersSquad do
            local y = c.y + ((i % 2 == 0) and 40 or -40)
            g.marchers[i] = { e = Actor(g, SOLDIER, Vector(x0, y, top), 0, 1, ACT_WALK or 1), y = y }
        end
        g.starts = {}
        for i = 0, 11 do g.starts[#g.starts + 1] = Vector(x0 + 200 + math.floor(i / 2) * 120, c.y + ((i % 2 == 0) and -230 or 230), top + 4) end
        NewSquad(g)
        g.squadT0 = CurTime() + 4
        return true
    end
    function def.spawn(g, p, i) local at = Spawn(g, p, i) return at, at.y > g.midY and -90 or 90 end
    def.hello = Hello("propaganda", "flowers_hello")

    function def.tick(g, dt, players)
        local now = CurTime()
        local marching = now >= g.squadT0
        local inHall, allPast = false, true
        if marching then
            for _, m in ipairs(g.marchers) do
                m.x = m.x + LC.FlowersSpeed * dt
                local inside = m.x > g.x0 and m.x < g.x1 - 20
                if inside then inHall = true end
                if m.x < g.x1 - 20 then allPast = false end
                if IsValid(m.e) then
                    m.e:SetPos(Vector(m.x, m.y, g.top))
                    if m.e.SetNoDraw then m.e:SetNoDraw(not inside) end
                end
            end
        else
            allPast = false
        end
        for _, p in ipairs(players) do
            local s = g.pl[p]
            local pos = p:GetPos()
            if inHall and math.abs(pos.y - g.midY) < g.road and not Grace(s) then
                Offend(g, p, "Never block the liberators", "You stepped into the road in front of her soldiers. A sergeant moves you along, firmly.")
            elseif Jumped(s, p) and now >= (s.tossAt or 0) then
                s.tossAt = now + 0.8
                local hit
                for _, m in ipairs(g.marchers) do
                    if m.x > g.x0 and m.x < g.x1 - 20 and not m.got[p] and math.abs(m.x - pos.x) < LC.FlowersReach then hit = m break end
                end
                if hit then
                    hit.got[p] = true
                    s.score, s.squad, g.dirty = (s.score or 0) + 1, g.squadN, true
                    Snd(p, "items/flashlight1.wav", 60, 140)
                    if s.score >= def.need then
                        Done(g, p, "won", "Grateful citizen", "A soldier catches your flowers, tucks one into his mask, and salutes you. The whole street cheers.")
                    else
                        Notice(p, "info", "Welcome home!", string.format("A carnation lands at his boots. %d of %d.", s.score, def.need), 2)
                    end
                else
                    Notice(p, "info", "Too soon, or too late", "Your flowers land in the mud. Wait until a soldier is level with you.", 2)
                end
            end
        end
        if allPast then
            for _, p in ipairs(players) do
                local s = g.pl[p]
                if s.squad ~= g.squadN and not Grace(s) then
                    Offend(g, p, "A cold welcome", "A whole squad marched past and you didn't throw a single flower.")
                end
            end
            NewSquad(g)
            g.squadT0 = now + 3
        end
    end

    function def.state(g, p)
        local list = {}
        for _, m in ipairs(g.marchers) do if IsValid(m.e) then list[#list + 1] = m.e:EntIndex() end end
        local s = p and g.pl[p] or {}
        local big = nil
        if not s.done then big = "Stay off the road. Throw flowers (jump) as a soldier passes you." end
        return { marchers = list, nowR = LC.FlowersReach, big = big, tone = "love", meter = math.floor(math.min(1, (s.score or 0) / def.need) * 100),
            meterName = string.format("Flowers thrown: %d of %d", s.score or 0, def.need) }
    end
end

------------------------------------------------------------------------
-- Duck and Cover (the Resistance's rocket)
------------------------------------------------------------------------

do
    local def = { id = "duck", name = "Duck and Cover", mood = "happy", secs = 210, lives = 3, need = 6, music = { "duck", "propaganda" },
        goal = "The Resistance is firing rockets at the city. Listen to Sunny the Scanner: when the siren wails and the rocket goes up, crouch beside a table before the flash. Two to a table!",
        timeUp = { "Class dismissed", "Sunny waves goodbye with a little searchlight, and you wake." }, spawn = Spawn,
        woke = Woke({
            won = { "Prepared citizen", "You wake already crouching, and feel very safe. The terrorists can't touch you. Sunny would be proud." },
            out = { "Unprepared", "You wake blinking at a flash that wasn't there, and find yourself checking where the tables are." },
            time = { "Class dismissed", "You wake humming Sunny's little song. It won't leave." },
        }) }
    G.duck = def
    LC.DuckTips = {
        "The terrorists want to spoil our happy city with their nasty rocket. Don't let them spoil your posture!",
        "A table is your best friend! After the Administrator, of course.",
        "If you see a rocket, report it! Then duck and cover!",
        "When you see the flash, don't look at it! Look at the floor. The floor is very interesting.",
        "Only rebels build rockets. Good citizens build tables, and hide beside them!",
        "Keep calm and keep low! That's the Sunny way!",
    }
    LC.DuckReach, LC.DuckPerTable = 75, 2
    -- The pace (the owner, 12 November: "playing SOOOO fast I can't keep up ... I can't even read the words popping up"):
    -- the first siren once the hello has been read, a long calm between rounds, and the siren itself long enough to
    -- find a table. The alarm plays only while the siren lasts, and quietly ("GOODNESS MY EARS").
    LC.DuckFirst, LC.DuckCalm, LC.DuckSiren, LC.DuckTipEvery = 20, { 14, 18 }, { 7, 5 }, { 12, 16 }
    LC.DuckAlarm, LC.DuckAlarmLevel, LC.DuckAlarmVolume = "ambient/alarms/alarm1.wav", 60, 0.45
    -- The alarm, on everyone in the dream, for the siren only (it's a looping sound: stopped for sure).
    function LC.DuckAlarmOn(g, on)
        for _, p in ipairs(Everyone(g)) do
            if on then
                if p.EmitSound then p:EmitSound(LC.DuckAlarm, LC.DuckAlarmLevel, 100, LC.DuckAlarmVolume) end
            elseif p.StopSound then p:StopSound(LC.DuckAlarm) end
        end
        g.alarmOn = on or nil
    end
    -- The rocket: White Forest's (the owner, 9 November: "the model "models/props_silo/rocket_low.mdl" is the needed model, and it is 1299 units
    -- tall ... and ~180 units wide"), else Garry's Mod's own. { model, scale, its height at scale 1 (to fit the headroom), if known }.
    LC.DuckRockets = { { "models/props_silo/rocket_low.mdl", 0.3, 1299 }, { "models/props_silo/rocket.mdl", 0.3, 1299 }, { "models/props_phx/rocket1.mdl", 2 },
        { "models/weapons/w_missile_launch.mdl", 10 } }
    LC.DuckRise = 900
    -- The rocket's scale and how far it climbs, to fit the room over the dream point (headroom, and the dream zone's top).
    function LC.DuckFit(room, scale, height)
        if not height then return scale, math.max(200, math.min(LC.DuckRise, room - 300)) end
        local s2 = math.Clamp(room * 0.35 / height, 0.12, scale)
        return s2, math.max(150, math.min(LC.DuckRise, room - height * s2 - 40))
    end

    function def.build(g, dream)
        local x0, x1, top = Hall(g, dream, 3, Color(150, 160, 120))
        local c = dream.pos
        g.tables = {}
        for k = 1, 3 do for _, dy in ipairs({ -200, 200 }) do
            local at = Vector(x0 + (x1 - x0) * k / 4, c.y + dy, top)
            g.tables[#g.tables + 1] = at
            if K.ValidModel("models/props_c17/furnituretable001a.mdl") then Block(g, "models/props_c17/furnituretable001a.mdl", at + Vector(0, 0, 18), Angle(0, 0, 0)) end
        end end
        g.sunny = Actor(g, "models/combine_scanner.mdl", Vector(x1 - 120, c.y, top + 180), 180, 4)
        g.sunnyZ = top + 180
        LC.DuckMagnusson = LC.DuckMagnusson or { "models/magnusson.mdl", "models/kleiner.mdl", LC.PropagandaRebels[1] }
        -- the rebels' launch pad, in the far corner
        g.padAt = Vector(x1 - 90, c.y - PLATE8_S + 110, top)
        local room = math.min(LC.DreamGameHeadroom and LC.DreamGameHeadroom(dream) or 2000, (LC.DreamTop and LC.DreamTop(dream) or (top + 100000)) - top)
        for _, r in ipairs(LC.DuckRockets) do
            if K.ValidModel(r[1]) then
                local sc, rise = LC.DuckFit(room, r[2], r[3])
                g.rocketModel, g.rise = r[1], rise
                g.rocket = Actor(g, r[1], g.padAt, 0, sc)
                break
            end
        end
        g.mag = Villain(g, LC.DuckMagnusson, g.padAt + Vector(-60, 120, 40), 180, 5)
        g.phase, g.at, g.tipAt, g.rounds = "calm", CurTime() + LC.DuckFirst, CurTime() + 9, 0
        Starts(g, x0 + 90, c.y, top)
        return true
    end
    def.hello = Hello("civil", "duck_hello")

    -- Who's covered: crouching beside a table, the two nearest each.
    function LC.DuckCovered(g, players)
        local covered, count = {}, {}
        local claims = {}
        for _, p in ipairs(players) do
            if Kneeling(p) then
                local pos, best, bd = p:GetPos(), nil, LC.DuckReach
                for i, t in ipairs(g.tables) do local d = Dist2(pos, t) if d < bd then best, bd = i, d end end
                if best then claims[#claims + 1] = { p = p, t = best, d = bd } end
            end
        end
        table.sort(claims, function(a, b) return a.d < b.d end)
        for _, c in ipairs(claims) do
            count[c.t] = (count[c.t] or 0) + 1
            if count[c.t] <= LC.DuckPerTable then covered[c.p] = true end
        end
        return covered
    end

    function def.tick(g, dt, players)
        local now = CurTime()
        if IsValid(g.sunny) then local v = g.sunny:GetPos() g.sunny:SetPos(Vector(v.x, v.y, g.sunnyZ + math.sin(now * 2) * 12)) end
        if IsValid(g.rocket) then -- (on the pad while it's calm; climbing faster and faster once launched)
            local up = 0
            if g.phase == "siren" then local f = math.Clamp(1 - (g.at - now) / g.sirenLen, 0, 1) up = (g.rise or LC.DuckRise) * f * f end
            g.rocket:SetPos(g.padAt + Vector(0, 0, up))
        end
        if IsValid(g.mag) then -- (cackling beside his rocket; riding it up when it goes)
            local bob = math.sin(now * 2.5) * 20
            g.mag:SetPos(g.padAt + Vector(-60, 120, (IsValid(g.rocket) and (g.rocket:GetPos().z - g.padAt.z) or 0) + 40 + bob))
            g.mag:SetAngles(Angle(0, 180 + math.sin(now * 1.7) * 25, g.phase == "siren" and math.sin(now * 6) * 15 or 0))
        end
        if g.phase == "calm" and now >= g.tipAt and g.at - now > 6 then -- (never just before a siren: one thing to read at a time)
            g.tipAt = now + math.Rand(LC.DuckTipEvery[1], LC.DuckTipEvery[2])
            Narrate(g, "Sunny the Scanner", LC.DuckTips[math.random(#LC.DuckTips)])
        end
        if now < g.at then return end
        if g.phase == "calm" then
            g.sirenLen = math.max(LC.DuckSiren[2], LC.DuckSiren[1] - g.rounds * 0.3)
            g.phase, g.at, g.dirty = "siren", now + g.sirenLen, true
            SayAs(g, "duck_siren")
            LC.DuckAlarmOn(g, true)
            if IsValid(g.rocket) then
                if g.rocket.SetNoDraw then g.rocket:SetNoDraw(false) end
                Snd(g.rocket, "weapons/rpg/rocketfire1.wav", 100, 60)
            end
            if IsValid(g.mag) then
                if g.mag.SetNoDraw then g.mag:SetNoDraw(false) end
                if g.rounds == 0 then -- (said once: after that, everyone knows who he is)
                    for _, q in ipairs(Everyone(g)) do Notice(q, "warn", "The Resistance!", "A fifty-foot rebel scientist, glowing red, rides the rocket into the sky, shaking his fist and cackling.", 6) end
                end
            end
        elseif g.phase == "siren" then
            g.rounds, g.phase, g.at, g.dirty = g.rounds + 1, "calm", now + math.Rand(LC.DuckCalm[1], LC.DuckCalm[2]), true
            g.tipAt = math.max(g.tipAt or 0, now + 6)
            LC.DuckAlarmOn(g, false)
            local covered = LC.DuckCovered(g, players)
            for _, p in ipairs(Everyone(g)) do
                if p.ScreenFade then p:ScreenFade(SCREENFADE and SCREENFADE.IN or 1, Color(255, 255, 255, 255), 1.5, 0.3) end
            end
            for _, e in ipairs({ g.rocket, g.mag }) do -- (gone in the flash; back on the pad with another soon)
                if IsValid(e) and e.SetNoDraw then e:SetNoDraw(true) end
                timer.Simple(4, function() if g and not g.stopped and IsValid(e) and e.SetNoDraw then e:SetNoDraw(false) end end)
            end
            for _, p in ipairs(players) do
                local s = g.pl[p]
                if covered[p] then
                    s.score = (s.score or 0) + 1
                    if s.score >= def.need then Done(g, p, "won", "Prepared citizen", "Sunny gives you a gold star sticker. It glows slightly. That's normal!")
                    else Notice(p, "info", "Safe and sound!", string.format("You ducked and covered. %d of %d.", s.score, def.need), 5) end
                else
                    Offend(g, p, "Caught in the flash", "You weren't covered when the rebels' rocket came down. Sunny looks very disappointed in you.")
                end
            end
            timer.Simple(2.5, function() if g and not g.stopped then SayAs(g, "duck_clear") end end)
        end
    end

    function def.state(g, p)
        local s = p and g.pl[p] or {}
        local glows = {}
        if g.phase == "siren" then for _, t in ipairs(g.tables) do glows[#glows + 1] = { math.floor(t.x), math.floor(t.y), math.floor(t.z) + 60, 5 } end end
        local big, tone = nil, "love"
        if not s.done then
            if g.phase == "siren" then big, tone = "ROCKET LAUNCH! Duck and cover: crouch beside a table!", "warn"
            else big = "Listen to Sunny." end
        end
        return { glows = glows, big = big, tone = tone, rocket = g.phase == "siren" and IsValid(g.rocket) and g.rocket:EntIndex() or nil, villains = Villains(g),
            meter = math.floor(math.min(1, (s.score or 0) / def.need) * 100), meterName = string.format("Rockets survived: %d of %d", s.score or 0, def.need) }
    end
end

------------------------------------------------------------------------
-- Ravenholm (the owner, 8 November: "reminiscing of the ending to ravenholm: a graveyard with
-- the church but father gregori is glowing red and his voice lines pitch shifted to sound evil,
-- and zombies are rising from the graves ... if a vortigaunt is free it will appear and send out
-- an effect that is a green version of the portal storm effect from ep2 that washes over
-- gregori and shows that he is actually the good guy ... the administrator appears as actually
-- evil and father gregori starts killing the zombies ... and the administrator flies away defeated")
--
-- The Saviour turned inside out. The dead rise from the graves and come for the dreamers, who
-- have nothing to fight with (it hurts, in the dream); a giant, red Father Grigori rants from the
-- church. When someone is down to 25 health (or after 55 seconds) the dream turns:
--   No freed vortigaunt alive: propaganda wins. She descends, her soldiers kill the dead,
--     and Grigori flees into the sky. ("Saved.")
--   A freed vortigaunt still alive (a Free Vortigaunt player, awake or asleep, or an NPC cut loose
--     from its shackles): a vortigaunt appears
--     (the player themselves, if they're in the dream) and a green storm washes over everything.
--     Grigori's red is gone and his voice is his own; he blasts the dead with his shotgun before
--     they can hurt anyone, while a giant red figure of her shrieks and flies away defeated.
------------------------------------------------------------------------

do
    local def = { id = "ravenholm", name = "Ravenholm", mood = "happy", secs = 150, lives = 1, music = { "ravenholm", "propaganda" },
        goal = "The dead are rising from the graves, and you have nothing to fight with. Run. Dodge. Hold on.",
        timeUp = { "Dawn over the graves", "The sun comes up over the graveyard, and you wake." }, spawn = Spawn }
    G.ravenholm = def
    MORE[#MORE + 1] = "ravenholm"
    LC.PropagandaDreams.ravenholm = true
    LC.DreamGameOrder[#LC.DreamGameOrder + 1] = "ravenholm"
    LC.PropagandaSongWords[#LC.PropagandaSongWords + 1] = "ravenholm"
    LC.PropagandaSongWords[#LC.PropagandaSongWords + 1] = "ravenholm_truth"
    local LINES = {
        ravenholm_rise = { "Father Grigori", "RISE, my children! Rise from your graves and FEAST!" },
        ravenholm_stop = { "The Administrator", "Begone, false priest! These citizens are under MY protection." },
        ravenholm_safe = { "The Administrator", "You see? Only I can keep you safe. Never forget it." },
        ravenholm_vort = { "A Vortigaunt", "The Vortessence sees through the false light. Behold what is true." },
        ravenholm_good = { "Father Grigori", "Hah! Back to your rest, poor souls! Not one of these children shall be harmed!" },
        ravenholm_defeat = { "The Administrator", "No... NO! This is MY dream!" },
    }
    for k, v in pairs(LINES) do LC.PropagandaCues[k], LC.PropagandaCueWho[k] = v[2], v[1] end
    LC.RavenholmTimes = { horde = 4, low = 25, latest = 55, land = 5, soldiers = 3, storm = 3, flee = 4 }
    local T = LC.RavenholmTimes
    LC.RavenholmRants = { "vo/ravenholm/monk_rant01.wav", "vo/ravenholm/monk_rant02.wav", "vo/ravenholm/monk_rant03.wav", "vo/ravenholm/monk_kill01.wav",
        "vo/ravenholm/monk_kill03.wav", "vo/ravenholm/monk_kill05.wav" }
    LC.RavenholmEvil = { "Come, sinners, and be judged!", "The graves are hungry tonight!", "None shall leave my parish!", "Hahahaha! Run, little lambs!" }
    local DEAD = {
        { m = "models/zombie/classic.mdl", speed = 70, act = ACT_WALK, die = "npc/zombie/zombie_die1.wav", dmg = 10 },
        { m = "models/zombie/fast.mdl", speed = 160, act = ACT_RUN, die = "npc/fast_zombie/fz_alert_close1.wav", dmg = 6 },
        { m = "models/zombie/poison.mdl", speed = 55, act = ACT_WALK, die = "npc/zombie_poison/pz_die1.wav", dmg = 12 },
    }
    local STONES = { "models/props_c17/gravestone001a.mdl", "models/props_c17/gravestone002a.mdl", "models/props_c17/gravestone003a.mdl", "models/props_c17/gravestone_cross001a.mdl" }
    local CLAWS = { "npc/zombie/claw_strike1.wav", "npc/zombie/claw_strike2.wav" }
    local TRUTH = {} -- [steamid64] = true: they saw the truth (how they wake)
    local function Key(p) return tostring(p:SteamID64()) end

    -- A vortigaunt freed from its shackles, still alive (the owner: "any vortigaunt that had been
    -- freed from shackles even if an NPC"): a Free Vortigaunt player (awake or asleep), or one of the
    -- city's vortigaunts cut loose from a street crew or rescued from a work site. Nil: none.
    function LC.DreamFreeVort()
        for _, p in ipairs(player.GetAll()) do
            if IsValid(p) and p:GetNW2String("lcf_faction", "") == "resistance" and p:GetNW2String("lcf_special", "") == "vortigaunt" then return p end
        end
        for _, e in ipairs(ents.FindByClass and ents.FindByClass("npc_vortigaunt") or {}) do
            if IsValid(e) and e.lcVortFreed and (not e.Health or e:Health() > 0) then return e end
        end
        return nil
    end

    local function Toward(e, to, speed, dt, z)
        local pos = e:GetPos()
        local d = Vector(to.x - pos.x, to.y - pos.y, 0)
        local len = d:Length()
        if len > 1 then
            local step, n = math.min(len, speed * dt), d:GetNormalized()
            e:SetPos(Vector(pos.x + n.x * step, pos.y + n.y * step, z or pos.z))
            e:SetAngles(Angle(0, math.deg(math.atan2(n.y, n.x)), 0))
        end
        return len
    end
    local function Alive(g) local n = 0 for _, m in ipairs(g.dead) do if m.alive and IsValid(m.e) then n = n + 1 end end return n end
    LC.RavenholmAlive = Alive
    local function Kill(g, m, by, shot)
        m.alive = false
        if IsValid(by) then Snd(by, shot, 90) end
        if IsValid(m.e) then
            local pos = m.e:GetPos()
            if EffectData then
                local ed = EffectData()
                if IsValid(by) and ed.SetStart then ed:SetStart(by:GetPos() + Vector(0, 0, 45 * (by.GetModelScale and by:GetModelScale() or 1))) end
                ed:SetOrigin(pos + Vector(0, 0, 30))
                util.Effect(IsValid(by) and "AR2Tracer" or "BloodImpact", ed, true, true)
            end
            Snd(m.e, m.die, 75)
            m.e:Remove()
        end
    end
    local function Rant(g, evil)
        if IsValid(g.monk) then Snd(g.monk, LC.RavenholmRants[math.random(#LC.RavenholmRants)], 140, evil and 55 or 100) end
    end

    function def.build(g, dream)
        local x0, x1, top = Hall(g, dream, 3, Color(55, 60, 50))
        local c = dream.pos
        g.x0, g.x1, g.y0, g.y1 = x0 + 30, x1 - 30, c.y - PLATE8_S + 30, c.y + PLATE8_S - 30
        g.mid = Vector(c.x, c.y, top)
        local z = dream.zone
        local ceiling = (z and z.box and z.box.maxs.z) or (top + (LC.DreamGameHeadroom and LC.DreamGameHeadroom(dream) or 2000))
        g.skyZ = math.max(top + 250, math.min(ceiling - 120, top + 1500))
        -- the church: a dark front across the far end, a giant cross above it
        for row = 0, 2 do for i = -2, 1 do
            if not K.WallAt(g, Vector(x1 - 20, c.y + (i + 0.5) * 190, top), false, top + row * 95, Color(45, 40, 45)) then break end
        end end
        Actor(g, "models/props_c17/gravestone_cross001b.mdl", Vector(x1 - 30, c.y, top + 285), 180, 5)
        -- the graves, and where the dead come up
        g.graves = {}
        for i = 0, 3 do for j = -1, 1 do
            local at = Vector(x0 + 330 + i * (x1 - x0 - 560) / 3, c.y + j * 220, top)
            g.graves[#g.graves + 1] = at
            local m = STONES[(i + j + 2) % #STONES + 1]
            if K.ValidModel(m) then Block(g, m, at + Vector(30, 0, 0), Angle(0, 180, 0), Color(120, 120, 115)) end
        end end
        -- Father Grigori on the church steps: giant, glowing red
        g.monkAt = Vector(x1 - 110, c.y, top)
        g.monk = Villain(g, { "models/monk.mdl", LC.PropagandaRebels[1] }, g.monkAt, 180, 4)
        g.dead, g.soldiers, g.phase = {}, {}, "calm"
        Starts(g, x0 + 90, c.y, top)
        return true
    end
    def.hello = Hello("graveyard", nil)

    local function NewDead(g)
        local d = DEAD[math.random(#DEAD)]
        local at = g.graves[math.random(#g.graves)]
        local e = Actor(g, d.m, at - Vector(0, 0, 70), math.random(0, 359), 1, d.act)
        if not e then return end
        g.dead[#g.dead + 1] = { e = e, speed = d.speed, die = d.die, dmg = d.dmg, alive = true, rise = CurTime() + 1.5, from = at }
        if EffectData then local ed = EffectData() ed:SetOrigin(at) util.Effect("ThumperDust", ed, true, true) end
    end

    -- The dream turns: the truth, if a Free Vortigaunt is about; otherwise her version.
    local function Turn(g, players, now)
        g.turnAt, g.dirty = now, true
        for _, m in ipairs(g.dead) do if IsValid(m.e) and K.Animate then K.Animate(m.e, ACT_IDLE or 1) end end
        local vort = LC.DreamFreeVort()
        if vort then
            g.phase, g.truth = "storm", true
            local at = (vort.lcDreaming == g.dream.id and g.pl[vort]) and vort:GetPos() or nil
            if not at then
                at = Vector(g.x0 + 160, g.mid.y + 160, g.top)
                g.vort = Actor(g, "models/vortigaunt.mdl", at, 0, 1.5, ACT_IDLE or 1)
            end
            g.stormAt = { at.x, at.y, at.z, t = now }
            SayAs(g, "ravenholm_vort")
            if IsValid(vort) then Snd(IsValid(g.vort) and g.vort or vort, "npc/vort/attack_charge.wav", 100) end
            for _, p in ipairs(Everyone(g)) do
                if p.ScreenFade then p:ScreenFade(SCREENFADE and SCREENFADE.IN or 1, Color(60, 255, 90, 160), 2.5, 0.2) end
                Notice(p, "info", "A green storm", "A vortigaunt's light washes over the graveyard, and everything looks different.", 6)
                TRUTH[Key(p)] = true
            end
        else
            g.phase = "descend"
            g.land = Vector(g.mid.x, g.mid.y, g.top)
            g.sky = Vector(g.land.x, g.land.y, g.skyZ)
            g.her = Actor(g, LC.AdmireModel(), g.sky, 0, 1.6, ACT_IDLE or 1)
            Pose(g.her, { "pose_standing_02", "idle_subtle" }, ACT_IDLE)
            for _, p in ipairs(Everyone(g)) do Notice(p, "info", "Everything stops", "The dead freeze where they stand. A light breaks through the clouds.", 5) end
        end
    end
    LC.RavenholmTurn = Turn

    function def.tick(g, dt, players)
        local now = CurTime()
        local t = now - g.t0
        if g.phase == "calm" and t >= T.horde then g.phase, g.dirty, g.rantAt = "horde", true, now + 1 SayAs(g, "ravenholm_rise") Rant(g, true) end
        -- the dead: up out of the graves, then after the nearest dreamer (slower once the truth is out)
        if g.phase == "horde" or g.phase == "fight" then
            if g.phase == "horde" and now >= (g.spawnAt or 0) and Alive(g) < 14 then NewDead(g) g.spawnAt = now + 1.4 end
            if g.phase == "horde" and now >= g.rantAt then
                g.rantAt = now + math.Rand(7, 10)
                Rant(g, true)
                Narrate(g, "Father Grigori", LC.RavenholmEvil[math.random(#LC.RavenholmEvil)])
            end
            for _, m in ipairs(g.dead) do
                if m.alive and IsValid(m.e) then
                    if now < m.rise then
                        local f = 1 - (m.rise - now) / 1.5
                        local v = m.e:GetPos()
                        m.e:SetPos(Vector(v.x, v.y, g.top - 70 * (1 - f)))
                    else
                        local best, bd
                        for _, p in ipairs(players) do local d = p:GetPos():Distance(m.e:GetPos()) if not bd or d < bd then best, bd = p, d end end
                        if best then
                            local left = Toward(m.e, best:GetPos(), m.speed * (g.phase == "fight" and 0.5 or 1), dt, g.top)
                            if left < 45 and now >= (m.next or 0) and now >= (g.pl[best].safe or 0) then
                                m.next = now + 1.2
                                best:SetHealth(math.max(1, best:Health() - m.dmg)) -- (in the dream; it's all put back on waking)
                                Snd(best, CLAWS[math.random(#CLAWS)], 75)
                                if best.ScreenFade then best:ScreenFade(SCREENFADE and SCREENFADE.IN or 1, Color(160, 0, 0, 160), 0.4, 0.05) end
                                g.dirty = true
                            end
                        end
                    end
                end
            end
            if g.phase == "horde" then
                local low = false
                for _, p in ipairs(players) do if p:Health() <= T.low then low = true end end
                if low or t >= T.latest then Turn(g, players, now) end
            end
        end
        -- her version: she comes down, "Begone!", her soldiers, and Grigori flees
        if g.phase == "descend" then
            local f = math.Clamp((now - g.turnAt) / T.land, 0, 1)
            if IsValid(g.her) then g.her:SetPos(Vector(g.land.x, g.land.y, g.sky.z + (g.land.z - g.sky.z) * (1 - (1 - f) * (1 - f)))) end
            if f >= 1 then
                g.phase, g.dirty, g.stopAt = "soldiers", true, now
                SayAs(g, "ravenholm_stop")
                g.fleeFrom = IsValid(g.monk) and g.monk:GetPos() or g.monkAt
                for i = 1, 8 do
                    local at = Vector(g.land.x - 200, g.land.y + (i - 4.5) * 50, g.top)
                    local e = Actor(g, "models/combine_soldier.mdl", at, 0, 1, ACT_RUN or 1)
                    if e then g.soldiers[#g.soldiers + 1] = { e = e, next = now + T.soldiers + i * 0.1 } end
                end
            end
        end
        if g.stopAt and not g.truth and IsValid(g.monk) and not g.monk.lcFled then -- (fleeing up into the sky, spinning, shrinking)
            local f = math.Clamp((now - g.stopAt) / T.flee, 0, 1)
            g.monk:SetPos(g.fleeFrom + Vector(0, 0, f * 900))
            g.monk:SetAngles(Angle(0, now * 360 % 360, 0))
            if g.monk.SetModelScale then g.monk:SetModelScale(4 * (1 - f) + 0.1) end
            if f >= 1 then g.monk.lcFled = true if g.monk.SetNoDraw then g.monk:SetNoDraw(true) end end
        end
        if g.phase == "soldiers" then
            for _, s in ipairs(g.soldiers) do
                if IsValid(s.e) and now >= s.next then
                    local best, bd
                    for _, m in ipairs(g.dead) do if m.alive and IsValid(m.e) then local d = s.e:GetPos():Distance(m.e:GetPos()) if not bd or d < bd then best, bd = m, d end end end
                    if best then Kill(g, best, s.e, "weapons/ar2/fire1.wav") s.next, g.dirty = now + math.Rand(0.4, 0.8), true end
                end
            end
            if now >= g.stopAt + math.max(T.soldiers, T.flee) and Alive(g) == 0 then
                g.phase, g.safeAt, g.dirty = "safe", now + 3, true
                SayAs(g, "ravenholm_safe")
            end
        end
        -- the truth: the storm washes over him; he's himself again, and he blasts the dead; she's the monster
        if g.phase == "storm" and now >= g.turnAt + T.storm then
            g.phase, g.dirty = "fight", true
            if IsValid(g.monk) then
                g.monk:SetColor(Color(255, 255, 255))
                if g.monk.SetMaterial then g.monk:SetMaterial("") end
                if K.Animate then K.Animate(g.monk, ACT_WALK) end
            end
            g.villains = {}
            g.her = Villain(g, { LC.AdmireModel() }, Vector(g.mid.x + 150, g.mid.y, g.top + 260), 180, 4)
            SayAs(g, "ravenholm_good")
            Rant(g, false)
        end
        if g.phase == "fight" then
            if IsValid(g.her) then g.her:SetPos(Vector(g.mid.x + 150, g.mid.y + math.sin(now * 2) * 60, g.top + 260 + math.sin(now * 3) * 20)) end
            if IsValid(g.monk) then
                local best, bd
                for _, m in ipairs(g.dead) do if m.alive and IsValid(m.e) then local d = g.monk:GetPos():Distance(m.e:GetPos()) if not bd or d < bd then best, bd = m, d end end end
                if best then
                    if bd > 500 then Toward(g.monk, best.e:GetPos(), 260, dt, g.top)
                    elseif now >= (g.blastAt or 0) then Kill(g, best, g.monk, "weapons/shotgun/shotgun_dbl_fire.wav") g.blastAt, g.dirty = now + 0.45, true end
                end
            end
            if Alive(g) == 0 then
                g.phase, g.fleeAt, g.dirty = "defeat", now, true
                g.fleeFrom = IsValid(g.her) and g.her:GetPos() or g.mid
                SayAs(g, "ravenholm_defeat")
                if IsValid(g.monk) and K.Animate then K.Animate(g.monk, ACT_IDLE or 1) end
            end
        end
        if g.phase == "defeat" then
            local f = math.Clamp((now - g.fleeAt) / T.flee, 0, 1)
            if IsValid(g.her) then
                g.her:SetPos(g.fleeFrom + Vector(-f * 400, 0, f * 1000))
                g.her:SetAngles(Angle(f * 40, now * 540 % 360, 0))
                if g.her.SetModelScale then g.her:SetModelScale(4 * (1 - f) + 0.1) end
            end
            if f >= 1 then
                g.phase, g.safeAt = "safe", now + 2
                if IsValid(g.her) and g.her.SetNoDraw then g.her:SetNoDraw(true) end
            end
        end
        if g.phase == "safe" and g.safeAt and now >= g.safeAt then
            g.safeAt = nil
            for _, p in ipairs(players) do
                if g.truth then Done(g, p, "won", "The truth", "Father Grigori lowers his shotgun and laughs. The last of the dead lie still, and the false light is gone from the sky.")
                else Done(g, p, "won", "Saved", "Her soldiers stand over the last of the dead. She looks down at you, and you have never felt so safe.") end
            end
        end
    end

    function def.woke(p, how)
        local truth = TRUTH[Key(p)]
        TRUTH[Key(p)] = nil
        if how == "won" and truth then Notice(p, "info", "The truth", "You wake with green light behind your eyes and a priest's laughter in your ears. Something in the city's broadcasts sounds hollow this morning.", 9)
        elseif how == "won" then Notice(p, "info", "Saved", "You wake safe in your bed, and for a moment you'd swear you can still feel her light. The Combine protect you. They always have.", 9)
        else Notice(p, "info", "Dawn over the graves", "You wake with the smell of earth, and the sound of a priest laughing somewhere far away.", 9) end
    end

    local BIG = { calm = "A graveyard, under a red sky. Something stirs.", horde = "The dead are rising! Run!", descend = "Everything stops. A light from above...",
        soldiers = "Her soldiers are here!", storm = "A green storm...", fight = "Father Grigori fights for you!", defeat = "She flees!", safe = "It's over." }
    function def.state(g, p)
        return { big = BIG[g.phase], tone = (g.phase == "horde" or g.phase == "calm") and "warn" or "love", villains = Villains(g), storm = g.stormAt,
            truth = g.truth or nil, meterName = g.phase ~= "calm" and string.format("The dead: %d", Alive(g)) or nil }
    end
end
