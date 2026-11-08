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
        The Stakhanov Shift (shift), Soviet labour heroes: stand at a work station and hammer
          (crouch, again and again) to beat the norm by 1400%. Double norm now and then. Idle for
          12 seconds and the foreman notices. The first to 1400% gets a giant portrait.
        Careless Talk (spy), "loose lips sink ships": a canteen of citizens with one rebel spy
          among them. A party game (the owner: "everyone has 30 seconds to pick the spy ... on
          their own and then it's revealed to everyone at the end"): four rounds of 30 seconds,
          three overheard clues each (which table, a man or a woman, what colour); crouch beside
          the one you suspect (change your mind as often as you like). Then the spy and
          everyone's pick are shown to all: a loyal citizen reported, or nobody, costs a life.
          Three spies found out of four wins.
        The Newsreel (newsreel), wartime newsreels: the dream is black and white and a narrator
          booms. A party game too: eight takes; as the camera rolls each dreamer is told to wave,
          salute or cheer (say it in chat) before the cut, and then everyone's take is shown to
          all. Wrong, or nothing, costs a life. Five good takes wins.
        Two Minutes of Hate (hate), Orwell's 1984: the enemy of the people on a giant screen, and
          everyone jeers in chat. Silence for 15 seconds is noticed; a kind word for him is
          thoughtcrime. Fill your Hatred to win.
        The Mass Games (massgames), North Korean card stunts: each dreamer has a seat in the
          stands and a card, gold (crouch) or red (stand). Show the colour you're told when the
          conductor calls "Flip!" and, picture by picture, the stands become her portrait.
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
          climbs from its pad (White Forest's, with Episode Two on the server, else Garry's Mod's
          own), and you crouch beside a table before the flash (two to a table). Six survived
          wins.

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
    shift_hello = { "The Foreman", "Comrades! Today's norm is one hundred percent. Tomorrow's is fourteen hundred. Why wait?" },
    shift_double = { "The Foreman", "Double norm! Every blow counts twice!" },
    shift_hero = { "The Foreman", "A new Hero of Labour! Hang the portrait!" },
    spy_hello = { "The Loudspeaker", "Careless talk costs lives. There is a traitor among you. Listen carefully." },
    spy_caught = { "The Loudspeaker", "Time is up. The traitor is revealed. The city thanks its vigilant citizens." },
    newsreel_hello = { "The Narrator", "City Seventeen! Where every citizen smiles, and every smile is sincere!" },
    newsreel_end = { "The Narrator", "And so another happy day draws to a close. Goodnight, City Seventeen!" },
    hate_hello = { "The Screen", "Citizens! Behold the enemy of the people. Let him hear you!" },
    hate_end = { "The Screen", "The enemy fades. Love returns. Love the Administrator." },
    massgames_hello = { "The Conductor", "Cards ready! Together, we are her portrait." },
    massgames_flip = { "The Conductor", "FLIP!" },
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
-- The Stakhanov Shift
------------------------------------------------------------------------

do
    local def = { id = "shift", name = "The Stakhanov Shift", mood = "happy", secs = 150, lives = 3, need = 1400, music = { "shift", "propaganda" },
        goal = "Stand at a glowing work station and hammer (crouch, again and again) to beat the norm by 1400%. Don't stand idle: the foreman is watching.",
        timeUp = { "The whistle blows", "The shift is over before you've beaten the norm. You wake." }, spawn = Spawn,
        woke = Woke({
            won = { "Hero of Labour", "You wake with aching arms and a strange pride. Somewhere, a giant portrait of you is drying." },
            out = { "Idler", "You wake with the foreman's whistle still in your ears. You should work harder. At what, you're not sure." },
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
        g.foreman = Actor(g, "models/police.mdl", Vector(x1 - 90, c.y, top), 180, 1.8, ACT_IDLE or 1)
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
                if Offend(g, p, "Idler!", "The foreman saw you standing about. The norm does not beat itself.") and IsValid(g.foreman) then
                    Snd(g.foreman, "npc/metropolice/vo/getbacktowork.wav", 85)
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
    LC.SpyRounds, LC.SpyRoundSecs, LC.SpyReveal = 4, 30, 6
    LC.SpyClueAt = { 3, 11, 19 } -- (seconds into a round)
    local def = { id = "spy", name = "Careless Talk", mood = "happy", secs = 8 + LC.SpyRounds * (LC.SpyRoundSecs + LC.SpyReveal) + 4, lives = 3, need = 3,
        music = { "spy", "propaganda" },
        goal = "One citizen in the canteen is a rebel spy. Listen to the clues, then crouch beside the one you suspect (you can change your mind). After 30 seconds, everyone's pick is revealed.",
        timeUp = { "The canteen empties", "The lights go off in the canteen, and you wake." }, spawn = Spawn,
        woke = Woke({
            won = { "Vigilant citizen", "You wake looking sideways at everyone, quietly proud. Loose lips sink ships. Not on your watch." },
            out = { "Informer", "You wake feeling you accused the wrong people in your sleep. Hopefully nobody remembers." },
            time = { "The canteen empties", "You wake listening hard, as if someone nearby were whispering." },
        }) }
    G.spy = def
    LC.SpyTables = { "by the window", "by the kitchen", "by the door", "under her portrait" }
    LC.SpyTints = { { "red", Color(230, 90, 90) }, { "green", Color(110, 210, 110) }, { "blue", Color(110, 150, 240) }, { "yellow", Color(235, 215, 90) } }
    local MEN = { "models/humans/group01/male_02.mdl", "models/humans/group02/male_04.mdl", "models/humans/group01/male_07.mdl" }
    local WOMEN = { "models/humans/group01/female_01.mdl", "models/humans/group02/female_02.mdl", "models/humans/group01/female_04.mdl" }
    local IDLE = { "LineIdle01", "lineidle01", "idle_subtle" }

    local function Combo(n) return n.tbl .. "/" .. n.man .. "/" .. n.tint end
    local function Describe(n) return string.format("the %s in %s %s", n.man == 1 and "man" or "woman", LC.SpyTints[n.tint][1], LC.SpyTables[n.tbl]) end
    LC.SpyDescribe = Describe
    local function Look(n)
        if not IsValid(n.e) then return end
        n.e:SetModel((n.man == 1 and MEN or WOMEN)[n.seat])
        n.e:SetColor(LC.SpyTints[n.tint][2])
        if n.e.SetNoDraw then n.e:SetNoDraw(false) end
        Pose(n.e, IDLE, ACT_IDLE)
    end
    -- A fresh canteen: everyone's sex and colour shuffled, and a new spy whose table, sex and
    -- colour together belong to nobody else.
    local function NewRound(g)
        for _, n in ipairs(g.npcs) do n.man, n.tint = math.random(2), math.random(#LC.SpyTints) Look(n) end
        local n = g.npcs[math.random(#g.npcs)]
        local taken = {}
        for _, o in ipairs(g.npcs) do if o ~= n then taken[Combo(o)] = true end end
        if taken[Combo(n)] then
            for man = 1, 2 do for tint = 1, #LC.SpyTints do
                if not taken[n.tbl .. "/" .. man .. "/" .. tint] then n.man, n.tint = man, tint end
            end end
            Look(n)
        end
        g.spyN = n
        local order = { "tbl", "man", "tint" }
        for i = #order, 2, -1 do local j = math.random(i) order[i], order[j] = order[j], order[i] end
        g.round, g.phase, g.roundT0, g.clueOrder, g.clues = g.round + 1, "pick", CurTime(), order, {}
        g.at, g.dirty = CurTime() + LC.SpyRoundSecs, true
        for _, s in pairs(g.pl) do s.pick = nil end
        for _, q in ipairs(Everyone(g)) do Notice(q, "info", string.format("Round %d of %d", g.round, LC.SpyRounds), "Someone in the canteen is a spy. Listen...", 4) end
    end
    LC.SpyNewRound = NewRound
    local function Clue(g)
        local n = g.spyN
        local what = n and g.clueOrder[#g.clues + 1]
        if not what then return end
        local text
        if what == "tbl" then text = "A whisper from the table " .. LC.SpyTables[n.tbl] .. ": \"...the old bridge, after curfew...\""
        elseif what == "man" then text = n.man == 1 and "The voice that said it was a man's." or "The voice that said it was a woman's."
        else text = "You catch a glimpse of a " .. LC.SpyTints[n.tint][1] .. " sleeve as someone hides a note." end
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
                lines[#lines + 1] = p:Nick() .. ": right!"
            elseif n then
                lines[#lines + 1] = p:Nick() .. ": reported " .. Describe(n) .. " (loyal)"
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
        timer.Simple(2, function() if g and not g.stopped and IsValid(spy.e) and spy.e.SetNoDraw then spy.e:SetNoDraw(true) end end) -- (dragged away)
    end

    function def.build(g, dream)
        local x0, x1, top = Hall(g, dream, 2, Color(95, 95, 85))
        local c = dream.pos
        local half = (x1 - x0) / 2
        local spots = { { c.x + half * 0.45, c.y + 200 }, { c.x + half * 0.45, c.y - 200 }, { c.x - half * 0.2, c.y - 200 }, { c.x - half * 0.2, c.y + 200 } }
        g.npcs = {}
        for t, xy in ipairs(spots) do
            if K.ValidModel("models/props_c17/furnituretable001a.mdl") then
                Block(g, "models/props_c17/furnituretable001a.mdl", Vector(xy[1], xy[2], top + 18), Angle(0, 0, 0))
            end
            for k, off in ipairs({ { -55, -50 }, { 55, -50 }, { 0, 62 } }) do
                local at = Vector(xy[1] + off[1], xy[2] + off[2], top)
                local e = Actor(g, MEN[k], at, math.deg(math.atan2(xy[2] - at.y, xy[1] - at.x)), 1, ACT_IDLE or 1)
                g.npcs[#g.npcs + 1] = { e = e, pos = at, tbl = t, seat = k, man = 1, tint = 1 }
            end
        end
        g.round, g.phase, g.at = 0, "wait", CurTime() + 8
        for _, n in ipairs(g.npcs) do n.man, n.tint = math.random(2), math.random(#LC.SpyTints) Look(n) end
        Starts(g, x0 + 90, c.y, top)
        return true
    end
    def.hello = Hello("propaganda", "spy_hello")

    function def.tick(g, dt, players)
        local now = CurTime()
        if g.phase == "pick" then
            local at = LC.SpyClueAt[#g.clues + 1]
            if at and now >= g.roundT0 + at then Clue(g) end
            for _, p in ipairs(players) do
                local s = g.pl[p]
                if Ducked(s, p) then
                    local pos, best, bd = p:GetPos(), nil, 80
                    for i, n in ipairs(g.npcs) do local d = Dist2(pos, n.pos) if d < bd then best, bd = i, d end end
                    if best and best ~= s.pick then
                        s.pick, g.dirty = best, true
                        Notice(p, "info", "Your pick", "You'll report " .. Describe(g.npcs[best]) .. ". Nobody else knows. Crouch beside someone else to change your mind.", 4)
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
                if n >= def.need then Done(g, p, "won", "Vigilant citizen", string.format("You found the spy %d times out of %d. The canteen applauds you.", n, LC.SpyRounds))
                else Done(g, p, "time", "The canteen empties", string.format("You found the spy %d times out of %d. The lights go off, and you wake.", n, LC.SpyRounds)) end
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
            big = s.pick and string.format("Your pick: %s (%d s to change your mind)", Describe(g.npcs[s.pick]), left) or string.format("Crouch beside the one you suspect. %d s.", left)
        elseif g.phase == "reveal" and g.spyN then
            big, notes = "The spy was " .. Describe(g.spyN) .. "!", g.results
        elseif g.phase == "wait" then big = "Listen. The first round is about to begin." end
        return { glows = glows, notes = notes, big = big, tone = g.phase == "reveal" and "warn" or "love",
            meterName = string.format("Round %d of %d     Spies found: %d of %d needed", math.max(1, g.round), LC.SpyRounds, s.score or 0, def.need) }
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
        "Here are happy citizens on their way to work! Look at that loyalty!",
        "Rations are up again this week. Nobody can remember them ever being down!",
        "The city's children are healthy, cheerful and remarkably quiet!",
        "A smile costs nothing, and in City Seventeen it is mandatory!",
        "Our brave Civil Protection: always watching, always caring!",
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
        Narrate(g, "The Narrator", LC.NewsreelLines[(g.take - 1) % #LC.NewsreelLines + 1])
        for _, q in ipairs(Everyone(g)) do Notice(q, "info", string.format("Cut! Take %d", g.take), table.concat(lines, ". ") .. ".", 6) end
        for _, p in ipairs(players) do
            local s = g.pl[p]
            if s.did and s.did ~= s.cue then Offend(g, p, "Wrong on camera", "The camera wanted you to " .. s.cue .. ", and you " .. PAST[s.did] .. ". Take two will not be needed.")
            elseif not s.did then Offend(g, p, "Caught looking glum", "The camera rolled and you just stood there. The narrator coughs.") end
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
                if n >= def.need then Done(g, p, "won", "Star of the screen", string.format("%d good takes out of %d. The narrator calls you the happiest citizen in the city.", n, LC.NewsreelTakes))
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
        return { board = board, big = big, tone = tone, meter = math.floor(math.min(1, (s.score or 0) / def.need) * 100),
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
        goal = "Stay on your seat in the stands. For each picture you're told your card's colour: gold, crouch; red, stand. Show it when the conductor calls FLIP!",
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
    local def = { id = "duck", name = "Duck and Cover", mood = "happy", secs = 150, lives = 3, need = 6, music = { "duck", "propaganda" },
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
    -- The rocket: the one from White Forest if the server has Episode Two, else Garry's Mod's own (and the size each needs).
    LC.DuckRockets = { { "models/props_silo/rocket.mdl", 0.3 }, { "models/props_silo/rocket_low.mdl", 0.3 }, { "models/props_phx/rocket1.mdl", 2 },
        { "models/weapons/w_missile_launch.mdl", 10 } }
    LC.DuckRise = 900

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
        -- the rebels' launch pad, in the far corner
        g.padAt = Vector(x1 - 90, c.y - PLATE8_S + 110, top)
        for _, r in ipairs(LC.DuckRockets) do
            if K.ValidModel(r[1]) then
                g.rocketModel = r[1]
                g.rocket = Actor(g, r[1], g.padAt, 0, r[2])
                break
            end
        end
        g.phase, g.at, g.tipAt, g.rounds = "calm", CurTime() + 10, CurTime() + 6, 0
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
            if g.phase == "siren" then local f = math.Clamp(1 - (g.at - now) / g.sirenLen, 0, 1) up = LC.DuckRise * f * f end
            g.rocket:SetPos(g.padAt + Vector(0, 0, up))
        end
        if g.phase == "calm" and now >= g.tipAt then
            g.tipAt = now + math.Rand(9, 13)
            Narrate(g, "Sunny the Scanner", LC.DuckTips[math.random(#LC.DuckTips)])
        end
        if now < g.at then return end
        if g.phase == "calm" then
            g.sirenLen = math.max(3, 6 - g.rounds * 0.4)
            g.phase, g.at, g.dirty = "siren", now + g.sirenLen, true
            SayAs(g, "duck_siren")
            for _, p in ipairs(Everyone(g)) do Snd(p, "ambient/alarms/alarm1.wav", 75) end
            if IsValid(g.rocket) then
                if g.rocket.SetNoDraw then g.rocket:SetNoDraw(false) end
                Snd(g.rocket, "weapons/rpg/rocketfire1.wav", 100, 60)
            end
        elseif g.phase == "siren" then
            g.rounds, g.phase, g.at, g.dirty = g.rounds + 1, "calm", now + math.Rand(7, 10), true
            local covered = LC.DuckCovered(g, players)
            for _, p in ipairs(Everyone(g)) do
                if p.ScreenFade then p:ScreenFade(SCREENFADE and SCREENFADE.IN or 1, Color(255, 255, 255, 255), 1.5, 0.3) end
            end
            if IsValid(g.rocket) and g.rocket.SetNoDraw then g.rocket:SetNoDraw(true) end -- (gone in the flash; they've another on the pad soon)
            timer.Simple(4, function() if g and not g.stopped and IsValid(g.rocket) and g.rocket.SetNoDraw then g.rocket:SetNoDraw(false) end end)
            for _, p in ipairs(players) do
                local s = g.pl[p]
                if covered[p] then
                    s.score = (s.score or 0) + 1
                    if s.score >= def.need then Done(g, p, "won", "Prepared citizen", "Sunny gives you a gold star sticker. It glows slightly. That's normal!")
                    else Notice(p, "info", "Safe and sound!", string.format("You ducked and covered. %d of %d.", s.score, def.need), 3) end
                else
                    Offend(g, p, "Caught in the flash", "You weren't covered when the rebels' rocket came down. Sunny looks very disappointed in you.")
                end
            end
            timer.Simple(1.5, function() if g and not g.stopped then SayAs(g, "duck_clear") end end)
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
        return { glows = glows, big = big, tone = tone, rocket = g.phase == "siren" and IsValid(g.rocket) and g.rocket:EntIndex() or nil,
            meter = math.floor(math.min(1, (s.score or 0) / def.need) * 100), meterName = string.format("Rockets survived: %d of %d", s.score or 0, def.need) }
    end
end
