--[[
    Living City: staging the dreams you play

    The owner, 10 November: "the same acting for the dreams' own figures: the Administrator's
    figure, the giant officers, the admirers", "set pieces inside individual dreams, such as a
    staged opening or a proper finish when someone wins", "giving real players' dream bodies the
    same flinch and cheer".

    Every dream you play (not the endings: they have their own choreography) is staged the same
    way, on top of whatever the dream does itself. Nothing here touches a dream's rules: who
    wins, who loses a life and when it ends are the dream's own.

      The opening. As it begins, every dreamer's screen has the dream's name between two black
      bars for a few seconds (cl_livingcity_dreamacting.lua), and the stand-ins stand together
      facing the middle of it, the way the dream calls for (kneeling to her, cowering, waving),
      before they scatter.

      Its own figures act. What a figure is doing is told to the dreamers' screens, which move
      its arms, head and back (the same way as the stand-ins'):
        Her figure (a propaganda dream)   stands regally; points at a dreamer who has just lost
                                          a life; holds out a hand in blessing to one who wins.
        The hunters (the giant officers,  the one nearest a dreamer who has just lost a life
        the dead)                         raises a fist over them; when a dreamer wins, they all
                                          hang their heads.
        Her admirers                      hold their arms out to her on their knees, each in
                                          their own time; they cheer a dreamer who wins.

      The dreamers' own bodies. A dreamer who loses a life flinches; one who is out of it
      cowers; one who wins cheers. The others see it (you don't see your own body).

      The finish. When a dreamer wins: a chime and a puff of light over them, the stand-ins
      cheer (sv_livingcity_dreamstandins.lua), the figures react as above, and every dreamer's
      screen has "Ada made it through" between the two bars. The first to win is "first".

      The close. The secret endings dreamt as dreams (the harpies, the plane, the fire...) can't
      be won: as each dreamer wakes at the end of one, their screen has "The dream is over"
      with a line of that dream's own. The same for whoever didn't win a dream you play.

    Hooks: LivingCityDreamStage(g, what, player) for "open", "hit", "out", "won".
]]

if CLIENT then return end

LC = LC or {}

util.AddNetworkString("lc_dream_stage") -- the opening and the finish, on the dreamers' screens

-- What something in a dream is doing, for the dreamers' screens (cl_livingcity_dreamacting.lua).
-- secs: for that long (then it's at rest again); nil: until told otherwise.
function LC.DreamActSet(e, name, secs, now)
    if not IsValid(e) or not e.SetNW2String then return false end
    now = now or CurTime()
    e:SetNW2Bool("lc_dream_actor", name ~= nil and name ~= "")
    e:SetNW2String("lc_dream_act", name or "")
    e:SetNW2Float("lc_dream_act_t", now)
    e:SetNW2Float("lc_dream_act_end", secs and (now + secs) or 0)
    if not e:IsPlayer() then e:SetNW2Bool("lc_dream_act_own", false) end
    e.lcDreamActBase = nil
    return true
end
-- What it does when it's doing nothing else (gone back to when a timed act is over).
function LC.DreamActBase(e, name)
    if not IsValid(e) then return end
    LC.DreamActSet(e, name)
    e.lcDreamActBase = name
end
local function Timed(e, name, secs, now)
    if not IsValid(e) then return end
    local base = e.lcDreamActBase
    LC.DreamActSet(e, name, secs, now)
    e.lcDreamActBase, e.lcDreamActBack = base, base and (now + secs) or nil
end

local function Dreamers(g)
    local out = {}
    for _, p in ipairs(LC.DreamersOf and LC.DreamersOf(g.dream) or {}) do out[#out + 1] = p end
    return out
end
local function Card(g, t)
    local to = Dreamers(g)
    if #to == 0 then return end
    net.Start("lc_dream_stage")
    net.WriteTable(t)
    net.Send(to)
end
local function Flat(a, b) local dx, dy = a.x - b.x, a.y - b.y return math.sqrt(dx * dx + dy * dy) end

-- Her, in a propaganda dream: her figure (not the Administrator starring: she moves herself).
local function Her(g) return IsValid(g.her) and not IsValid(g.star) and g.her or nil end
local function Hunters(g) return LC.DreamStandinThreats and LC.DreamStandinThreats(g) or {} end
local function Admirers(g)
    local out = {}
    for _, e in ipairs(g.admirers or {}) do if IsValid(e) then out[#out + 1] = e end end
    return out
end
LC.DreamStageFigures = function(g) return Her(g), Hunters(g), Admirers(g) end

-- The opening: the name on every screen, the stand-ins together, the figures in their places.
local OPEN_SECS = 3.5
local function Open(g, now)
    local def = g.def or {}
    local mood = g.dream and g.dream.mood or "neutral"
    local prop = LC.PropagandaDreams and LC.PropagandaDreams[g.id] or false
    Card(g, { k = "open", name = def.name or "A dream", mood = prop and "propaganda" or mood, secs = OPEN_SECS })
    local her = Her(g)
    if her then LC.DreamActBase(her, "regal") end
    for _, e in ipairs(Admirers(g)) do LC.DreamActBase(e, "kneel") end
    -- the stand-ins, together, facing the middle of it (or her)
    local Do = LC.DreamStandinDo
    local mid = (her and her:GetPos()) or (IsValid(g.star) and g.star:GetPos()) or (g.dream and g.dream.pos)
    if Do and mid then
        local act = prop and "kneel" or (mood == "nightmare" and "cower" or (mood == "happy" and "wave" or "look"))
        for _, b in ipairs(g.standins or {}) do
            if not b.out and IsValid(b.ent) then
                b.face, b.faceAt, b.target, b.idled = nil, mid, nil, true
                Do(b, act, now, OPEN_SECS * math.Rand(0.7, 1))
            end
        end
    end
    hook.Run("LivingCityDreamStage", g, "open")
end

-- A dreamer loses a life, is out of it, or wins.
local function Hit(g, p, now)
    Timed(p, "flinch", 1, now)
    local at = p:GetPos()
    local near, nd
    for _, e in ipairs(Hunters(g)) do
        local d = Flat(e:GetPos(), at)
        if d < 600 and (not nd or d < nd) then near, nd = e, d end
    end
    if near then Timed(near, "gloat", 1.8, now) end
    local her = Her(g)
    if her then Timed(her, "scorn", 2.2, now) end
    hook.Run("LivingCityDreamStage", g, "hit", p)
end
local function Out(g, p, now)
    Timed(p, "cower", 2.5, now)
    hook.Run("LivingCityDreamStage", g, "out", p)
end
local function Won(g, p, now)
    Timed(p, "cheer", 4, now)
    for _, e in ipairs(Hunters(g)) do Timed(e, "slump", 3.5, now) end
    local her = Her(g)
    if her then Timed(her, "bless", 4, now) end
    for _, e in ipairs(Admirers(g)) do Timed(e, "cheer", 3, now) end
    local K = LC.DreamGameKit or {}
    if K.Puff then
        local at = p:GetPos()
        for i = 1, 6 do
            local a = math.rad(i * 60)
            K.Puff(at + Vector(math.cos(a) * 40, math.sin(a) * 40, 60))
        end
    end
    if K.Snd then K.Snd(p, "buttons/bell1.wav", 70, 110) end
    g.stage.wins = (g.stage.wins or 0) + 1
    Card(g, { k = "finish", who = p.Nick and p:Nick() or "Someone", first = g.stage.wins == 1, name = g.def and g.def.name or "", secs = 3.5,
        sid = p.SteamID64 and p:SteamID64() or nil })
    hook.Run("LivingCityDreamStage", g, "won", p)
end

function LC.DreamStageTick(now)
    local dream = LC.DreamActive
    local g = dream and dream.game
    if not g or g.stopped then return end
    if not g.stage then
        g.stage = { seen = {} }
        Open(g, now)
    end
    local st = g.stage
    for p, s in pairs(g.pl or {}) do
        if IsValid(p) then
            local seen = st.seen[p]
            if not seen then
                seen = { lives = s.lives, how = s.how }
                st.seen[p] = seen
            end
            if s.how ~= seen.how and s.how == "won" then Won(g, p, now)
            elseif s.how ~= seen.how and s.how == "out" then Out(g, p, now)
            elseif (s.lives or 0) < (seen.lives or 0) and not s.done then Hit(g, p, now) end
            seen.lives, seen.how = s.lives, s.how
            -- (a dreamer's own act is over: at rest, and not looked at again)
            local till = p:GetNW2Float("lc_dream_act_end", 0)
            if till > 0 and now >= till and p:GetNW2Bool("lc_dream_actor", false) then LC.DreamActSet(p, nil) end
        end
    end
    -- a figure's timed act is over: back to what it does otherwise
    local her, hunters, admirers = LC.DreamStageFigures(g)
    local function Back(e)
        if IsValid(e) and e.lcDreamActBack and now >= e.lcDreamActBack then
            local base = e.lcDreamActBase
            e.lcDreamActBack = nil
            LC.DreamActBase(e, base)
        end
    end
    Back(her)
    for _, e in ipairs(hunters) do Back(e) end
    for _, e in ipairs(admirers) do Back(e) end
end
timer.Create("LivingCityDreamStage", 0.1, 0, function()
    local ok, err = pcall(LC.DreamStageTick, CurTime())
    if not ok and LC.Error then LC.Error("dream stage", err) end
end)

------------------------------------------------------------------------
-- The close: the dreams nobody can win (the owner, 11 November: "what about dreams that can't be won? Like the
-- harpies or plane or fire")
------------------------------------------------------------------------

-- The secret endings dreamt as dreams have their own opening (the ending's title comes up by itself) and their own
-- choreography, but nothing to win, so they used to just stop. Now, as each dreamer wakes at the end of one, their
-- screen has "The dream is over" between the two bars, with a line of that dream's own. The same closes a dream
-- you play for whoever didn't win it.
LC.DreamCloseLines = {
    harpies = "They took everyone they came for. You wake before they come back for you.",
    bus = "The bus drove on without you. You can still feel the bass in your teeth.",
    plane = "The plane flew on over the city. Your arms are still doing the dance.",
    standup = "The rope hangs empty, and the crowd has gone home.",
    hard = "The party stopped. Your ears will ring until morning.",
    shalom = "The ring let go of your hands. You're still humming it.",
    fire = "The fire went out. You check, to be sure.",
    base = "Somebody set up us the bomb. You wake before it goes off.",
    marrow = "The skeletons danced away into the dark, and took the music with them.",
    bloom = "The song ended at last. Your feet haven't noticed.",
    water = "The water went down. Your sheets are dry. You check twice.",
}
LC.DreamCloseMoods = {
    happy = "It was only a dream. A good one.",
    neutral = "It was only a dream. Probably.",
    nightmare = "It was only a dream. It will be back.",
    propaganda = "She is not pleased. Sleep on it.",
}
-- What a dreamer's screen says as they wake at the end of dream: { title, sub }, or nil for nothing (they won it).
function LC.DreamCloseFor(p, dream)
    if not dream or dream.test then return nil end
    local g = dream.game
    local mood = dream.mood or "neutral"
    local title = mood == "nightmare" and "The nightmare is over" or "The dream is over"
    if not g then
        return { title = title, sub = LC.DreamCloseLines[dream.ending or ""] or LC.DreamCloseMoods[mood] or LC.DreamCloseMoods.neutral }
    end
    local s = g.pl and g.pl[p]
    if not s or s.how == "won" then return nil end -- (not one of its players, or they've had their finish)
    if #(g.won or {}) > 0 then return { title = title, sub = "Someone made it through. Not you, this time." } end
    local prop = LC.PropagandaDreams and LC.PropagandaDreams[g.id]
    return { title = title, sub = prop and LC.DreamCloseMoods.propaganda or (mood == "nightmare" and "Nobody made it through. It will be back." or LC.DreamCloseMoods[mood]) }
end

-- Awake: their body is their own again; and when the dream ended (not when they left it early), the close.
hook.Add("LivingCityDreamWoke", "LivingCityDreamStage", function(p, _, why, dream)
    if not IsValid(p) then return end
    LC.DreamActSet(p, nil)
    if why ~= "end" or p.lcDreamWokeEnforcer then return end
    local t = LC.DreamCloseFor(p, dream)
    if not t then return end
    net.Start("lc_dream_stage")
    net.WriteTable({ k = "close", title = t.title, sub = t.sub, mood = dream.mood, secs = 5 })
    net.Send(p)
end)
