--[[
    Living City: the Administrator's dreams (dreams you play)

      The owner, 8 November: "dreams of the administrator where everyone is expected to borderline
      be aroused at her beauty but ultimately grovel at her feet and admire her while stereotypical
      erotic music plays (I will import some), the point being if the administrator had control of
      dreams she would definitely do this ... but I don't want to push eroticism or 18+ content".

      So: vanity, not anything more. Three dreams for the Administrator's tablet (Tablet > Tonight's
      dream > Happy, because of course she would call them that), each built at the dream point out
      of plain props like the nightmares (sv_livingcity_dreamgames.lua), with a giant Administrator
      on a pedestal under a pink spotlight, kneeling admirers all round, hearts drifting up from her,
      and the crowd sighing and swooning (comic lines, nothing explicit). Everything else about a
      dream is as it always was: only those asleep dream it, nothing they do counts, and they wake in
      their bed with everything they had. A Happy dream can be opted out of, and woken from.

        Kneel Before Her (adore): her gaze sweeps the hall. Kneel (crouch) and look up at her to
          fill your Devotion, faster while she's looking your way. Anyone she catches standing in
          her gaze loses one of three lives. Full Devotion: she notices you.
        Roses for Her (roses): pick up glowing roses at the back of the hall and lay them at her
          feet. The front half of the hall is hers: cross it on your knees (crouch), or her honour
          guard sends you back. Three roses and you're adored.
        Mirror, Mirror (mirror): kneel and compliment her in chat ("radiant", "flawless", ...).
          A word nobody else has used yet is worth double; saying your own again is worth nothing;
          an insult costs a life. Compliments stay inside the dream (the city doesn't hear them).

      The music: any song in garrysmod/sound/livingcity/dreams/administrator/ (.mp3, .ogg or .wav,
      any name) plays during her dreams, one picked at random each time, looping. Sent to players
      with resource.AddFile when the map starts, like the ending songs. No songs: no music.

      Waking: devoted (won) wakes starstruck; dismissed (out of lives) wakes embarrassed; nothing
      else (no credits, no standing, no rewards or penalties: it's only a dream).
]]

if CLIENT then return end

LC = LC or {}

local K = LC.DreamGameKit
local G = LC.DreamGames
if not K or not G then return end
local Block, Actor, Floor, Snd, Done, Hit, ToStart = K.Block, K.Actor, K.Floor, K.Snd, K.Done, K.Hit, K.ToStart
local PLATE8, PLATE8_S, PLATE4, PLATE4_S = K.PLATE8, K.PLATE8_S, K.PLATE4, K.PLATE4_S

local function Notice(p, kind, title, text, secs)
    if not IsValid(p) then return end
    if LC.Notice then LC.Notice(p, kind, title, text, secs) else p:ChatPrint(title .. ": " .. text) end
end

for _, id in ipairs({ "adore", "roses", "mirror" }) do
    local have = false
    for _, o in ipairs(LC.DreamGameOrder) do if o == id then have = true end end
    if not have then LC.DreamGameOrder[#LC.DreamGameOrder + 1] = id end
end
LC.AdmireDreams = { adore = true, roses = true, mirror = true }

------------------------------------------------------------------------
-- The music: whatever the owner put in sound/livingcity/dreams/administrator/
------------------------------------------------------------------------

LC.AdmireSongRoot = "livingcity/dreams/administrator/"
local AUDIO = { mp3 = true, ogg = true, wav = true }
function LC.AdmireSongs()
    local out = {}
    local names = file.Find("sound/" .. LC.AdmireSongRoot .. "*", "GAME") or {}
    table.sort(names)
    for _, n in ipairs(names) do
        local ext = string.match(n, "%.([%w]+)$")
        if ext and AUDIO[string.lower(ext)] then out[#out + 1] = LC.AdmireSongRoot .. n end
    end
    return out
end
do -- (sent to players when the map starts)
    for _, path in ipairs(LC.AdmireSongs()) do
        if resource and resource.AddFile then resource.AddFile("sound/" .. path) end
    end
end
local function PickSong()
    local list = LC.AdmireSongs()
    if #list == 0 then return nil end
    return list[math.random(#list)]
end

------------------------------------------------------------------------
-- The stage: her, her pedestal, her admirers, the crowd's sighs
------------------------------------------------------------------------

local PLUM, GOLD, ROSE = Color(70, 30, 60), Color(230, 185, 80), Color(200, 20, 50)
local ADMIRERS = { "models/humans/group01/male_02.mdl", "models/humans/group01/female_01.mdl", "models/humans/group01/male_07.mdl",
    "models/humans/group01/female_04.mdl", "models/humans/group02/male_04.mdl", "models/humans/group02/female_02.mdl" }
local KNEEL = { "crouchidlehide", "Crouch_idleD", "crouch_idled", "pose_ducking_01" }
local POSE = { "pose_standing_02", "pose_standing_01", "idle_all_01", "idle_subtle" }

LC.AdmireSwoons = {
    "A sigh runs through the crowd. Someone at the back fans themselves with a ration card.",
    "She tilts her head a single degree. Three admirers forget their own names.",
    "The music swells. Your heart does something it is not authorised to do.",
    "An officer at the edge lifts his mask to see her better, then remembers himself and puts it back.",
    "Somebody whispers \"radiant\". Somebody else whispers \"more radiant than that\".",
    "Her hair moves in a breeze that blows only for her.",
    "You notice you're blushing. So is everyone else. Nobody mentions it.",
    "A man near the front faints with a small, happy sound.",
    "The spotlight finds her cheekbones and stays there, as if it can't look away either.",
    "A citizen tries to applaud, realises it might seem forward, and kneels lower instead.",
    "She almost smiles. The whole hall holds its breath.",
    "Rose petals drift down from nowhere. Nobody asks where they came from.",
}

local function Pose(e, names, act)
    if not IsValid(e) or not e.ResetSequence then return end
    for _, n in ipairs(names) do
        local seq = e.LookupSequence and e:LookupSequence(n) or -1
        if seq and seq >= 0 then e:ResetSequence(seq) if e.SetPlaybackRate then e:SetPlaybackRate(1) end return end
    end
    if act and K.Animate then K.Animate(e, act) end
end

-- Her model: the Administrator's own, if she's on the server; otherwise Dr. Mossman's.
function LC.AdmireModel()
    for _, p in ipairs(player.GetAll()) do
        if IsValid(p) and p.GetNW2String and p:GetNW2String("lcf_faction", "") == "admin" and p.GetModel then
            local m = p:GetModel()
            if m and m ~= "" then return m end
        end
    end
    return "models/mossman.mdl"
end

-- Her, giant, on a gold pedestal at (x, y), facing yaw; and her head (for the gaze).
local function Her(g, x, y, top, yaw)
    local room = LC.DreamGameHeadroom and LC.DreamGameHeadroom(g.dream) or 2000
    local scale = math.Clamp((room - 120) / 80, 2, 4)
    local base = top
    if K.ValidModel("models/hunter/blocks/cube2x2x1.mdl") then
        Block(g, "models/hunter/blocks/cube2x2x1.mdl", Vector(x, y, top + 23.7), Angle(0, 0, 0), GOLD, "models/debug/debugwhite")
        base = top + 47.4
    end
    local e = Actor(g, LC.AdmireModel(), Vector(x, y, base), yaw, scale, ACT_IDLE or 1)
    Pose(e, POSE)
    g.her, g.herYaw, g.herScale = e, yaw, scale
    g.herBase = Vector(x, y, base)
    g.herHead = Vector(x, y, base + 66 * scale)
    return e
end

-- Admirers kneeling along both sides, facing her.
local function Admirers(g, fromX, toX, y1, y2, top, faceX, faceY)
    local n = 0
    for i = 0, 3 do
        local x = fromX + (toX - fromX) * (i + 0.5) / 4
        for _, y in ipairs({ y1, y2 }) do
            n = n + 1
            local yaw = math.deg(math.atan2(faceY - y, faceX - x))
            local e = Actor(g, ADMIRERS[(n - 1) % #ADMIRERS + 1], Vector(x, y, top), yaw, 1, ACT_IDLE or 1)
            Pose(e, KNEEL, ACT_COVER_LOW)
        end
    end
end

-- The crowd sighs now and then (everyone in the dream sees it).
local function Swoon(g)
    if CurTime() < (g.swoonAt or 0) then return end
    g.swoonAt = CurTime() + math.Rand(18, 26)
    g.swoonN = (g.swoonN or math.random(#LC.AdmireSwoons)) % #LC.AdmireSwoons + 1
    local line = LC.AdmireSwoons[g.swoonN]
    for p, s in pairs(g.pl) do
        if IsValid(p) and (not s.done or s.watching) then Notice(p, "info", "In the dream", line, 6) end
    end
end

local function Hello(g)
    g.song = PickSong()
    return { theme = "admire", song = g.song, her = g.herHead and { g.herHead.x, g.herHead.y, g.herHead.z } or nil }
end

-- How her dreams leave you (instead of the nightmares' LC.DreamOutcome).
local function Woke(p, how)
    if how == "won" then
        Notice(p, "info", "Starstruck", "You wake with her face still in your mind, warm and a little embarrassed, humming a tune you've never heard. Nobody needs to know about this dream.", 10)
    elseif how == "out" then
        Notice(p, "info", "Dismissed", "In the dream she turned away from you, and you wake with your cheeks burning. It was only a dream. Probably.", 8)
    elseif how == "time" then
        Notice(p, "info", "The music fades", "The spotlight dims, the music fades, and you wake in your bed, strangely devoted to the city's paperwork.", 8)
    end
end

local TIMEUP = { "The music fades", "The spotlight dims before the end, and she's gone. You wake." }

-- A floor of plates, long plates along x, two wide; its top at top. The first x and the last.
local function Hall(g, dream, maxLong)
    local half = LC.DreamGameHalf(dream)
    local long = math.Clamp(math.floor(half * 2 / PLATE8_S), 2, maxLong or 3)
    local c = dream.pos
    local top = c.z + 2
    local x0 = c.x - long * PLATE8_S / 2
    for i = 1, long do for j = 0, 1 do
        Floor(g, PLATE8, x0 + (i - 0.5) * PLATE8_S, c.y + (j - 0.5) * PLATE8_S, top, PLUM, "models/debug/debugwhite")
    end end
    g.top = top
    g.bounds = { mins = Vector(x0 - 60, c.y - PLATE8_S - 60, top - 160), maxs = Vector(x0 + long * PLATE8_S + 60, c.y + PLATE8_S + 60, top + 400) }
    return x0, x0 + long * PLATE8_S, top
end

local function Starts(g, x, y, top)
    g.starts = {}
    for i = 0, 11 do g.starts[#g.starts + 1] = Vector(x + (i % 2) * 40, y - 330 + i * 60, top + 4) end
end

-- Kneeling, and looking up at her (within about 25 degrees of her face).
function LC.AdmireKneeling(p) return p.Crouching ~= nil and p:Crouching() == true end
function LC.AdmireLooking(g, p)
    if not g.herHead then return false end
    local aim = p.GetAimVector and p:GetAimVector()
    if not aim and p.EyeAngles then local a = p:EyeAngles() aim = a and a.Forward and a:Forward() end
    if not aim then return false end
    local to = (g.herHead - p:EyePos()):GetNormalized()
    return aim:Dot(to) >= 0.9
end
-- Inside her gaze: within 22 degrees of where she's facing.
function LC.AdmireInGaze(g, p)
    if not g.herBase then return false end
    local d = p:GetPos() - g.herBase
    d.z = 0
    if d:Length() < 1 then return true end
    local yaw = math.rad(g.herYaw or 0)
    local f = Vector(math.cos(yaw), math.sin(yaw), 0)
    return f:Dot(d:GetNormalized()) >= math.cos(math.rad(22))
end

local function Turn(g, dt)
    if not IsValid(g.her) then return end
    local want = g.gazeWant or g.herYaw
    local y = g.herYaw
    if math.ApproachAngle then y = math.ApproachAngle(y, want, 45 * dt) else y = want end
    g.herYaw = y
    g.her:SetAngles(Angle(0, y, 0))
end

------------------------------------------------------------------------
-- Kneel Before Her
------------------------------------------------------------------------

do
    local def = { id = "adore", name = "Kneel Before Her", mood = "happy", secs = 150, lives = 3, theme = "admire",
        goal = "Kneel (crouch) and gaze up at her to fill your Devotion. Never let her catch you standing in her gaze.",
        timeUp = TIMEUP, woke = Woke, hello = Hello }
    G.adore = def
    local SIGHS = { "vo/npc/female01/ohno.wav", "vo/npc/male01/ohno.wav", "vo/npc/female01/wow01.wav", "vo/npc/male01/wow01.wav" }

    function def.build(g, dream)
        local x0, x1, top = Hall(g, dream, 3)
        local c = dream.pos
        Her(g, x1 - 110, c.y, top, 180)
        Admirers(g, x0 + 150, x1 - 300, c.y - PLATE8_S + 40, c.y + PLATE8_S - 40, top, x1 - 110, c.y)
        g.gazeWant, g.gazeAt = 180, CurTime() + 3
        Starts(g, x0 + 90, c.y, top)
        return true
    end

    function def.spawn(g, p, i) return g.starts[((i - 1) % #g.starts) + 1], 0 end

    function def.tick(g, dt, players)
        local now = CurTime()
        if now >= g.gazeAt then
            g.gazeWant, g.gazeAt = 180 + math.Rand(-50, 50), now + math.Rand(2.5, 4.5)
            g.dirty = true
        end
        Turn(g, dt)
        Swoon(g)
        for _, p in ipairs(players) do
            local s = g.pl[p]
            s.devotion = s.devotion or 0
            local gaze = LC.AdmireInGaze(g, p)
            local kneel = LC.AdmireKneeling(p)
            if s.gaze ~= gaze then s.gaze = gaze g.dirty = true end
            if gaze and not kneel and now >= (s.safe or 0) then
                if Hit(g, p, "You stood in her presence", "She looked straight at you, and you were standing.") then
                    Snd(p, SIGHS[math.random(#SIGHS)], 70)
                    s.devotion = math.max(0, s.devotion - 20)
                end
            elseif kneel and LC.AdmireLooking(g, p) then
                s.devotion = math.min(100, s.devotion + (gaze and 14 or 5) * dt)
                if s.devotion >= 100 then
                    Done(g, p, "won", "She noticed you", "For one moment her eyes rest on you, and the whole hall sighs with envy. You are adored.")
                end
            end
        end
    end

    function def.state(g, p)
        local s = p and g.pl[p] or {}
        local big, tone
        if s.gaze and not s.done then big, tone = "She's looking at you! Stay on your knees.", "warn"
        elseif not s.done then big, tone = "Kneel, and gaze up at her.", "love" end
        return { meter = math.floor(s.devotion or 0), meterName = "Devotion", big = big, tone = tone }
    end
end

------------------------------------------------------------------------
-- Roses for Her
------------------------------------------------------------------------

do
    local def = { id = "roses", name = "Roses for Her", mood = "happy", secs = 180, lives = 3, theme = "admire", need = 3,
        goal = "Pick up a glowing rose at the back of the hall and lay it at her feet. In the front half of the hall, stay on your knees (crouch).",
        timeUp = TIMEUP, woke = Woke, hello = Hello }
    G.roses = def
    local GUARD = "models/combine_super_soldier.mdl"

    local function NewRose(g, i)
        local r = g.rose[i]
        r.pos = Vector(math.Rand(g.backX0, g.backX1), g.midY + math.Rand(-g.halfW, g.halfW), g.top + 20)
        r.gone = nil
    end

    function def.build(g, dream)
        local x0, x1, top = Hall(g, dream, 4)
        local c = dream.pos
        g.midY, g.halfW = c.y, PLATE8_S - 60
        -- the carpet, down the middle to her pedestal
        local n = math.floor((x1 - x0) / PLATE4_S)
        for i = 1, n do Floor(g, PLATE4, x0 + (i - 0.5) * PLATE4_S, c.y, top + 1, ROSE, "models/debug/debugwhite") end
        Her(g, x1 - 110, c.y, top, 180)
        g.lineX = x0 + (x1 - x0) / 2 -- (past this, on your knees)
        g.feetX = x1 - 230 -- (her feet)
        local line = Block(g, "models/hunter/plates/plate1x8.mdl", Vector(g.lineX, c.y, top + 2), Angle(0, 0, 0), GOLD, "models/debug/debugwhite")
        if line then
            local mins, maxs = line:OBBMins(), line:OBBMaxs()
            if (maxs.x - mins.x) > (maxs.y - mins.y) then line:SetAngles(Angle(0, 90, 0)) end
        end
        -- her honour guard, either side of her
        g.guards = {}
        for _, dy in ipairs({ -200, 200 }) do
            local e = Actor(g, GUARD, Vector(x1 - 160, c.y + dy, top), 180, 1.6, ACT_IDLE or 1)
            g.guards[#g.guards + 1] = e
        end
        Admirers(g, g.lineX + 60, x1 - 320, c.y - PLATE8_S + 40, c.y + PLATE8_S - 40, top, x1 - 110, c.y)
        g.backX0, g.backX1 = x0 + 200, g.lineX - 80
        g.rose = {}
        for i = 1, 6 do g.rose[i] = {} NewRose(g, i) end
        Starts(g, x0 + 90, c.y, top)
        return true
    end

    function def.spawn(g, p, i) return g.starts[((i - 1) % #g.starts) + 1], 0 end

    function def.tick(g, dt, players)
        local now = CurTime()
        Swoon(g)
        for i, r in ipairs(g.rose) do
            if r.gone and now >= r.gone then NewRose(g, i) g.dirty = true end
        end
        for _, p in ipairs(players) do
            local s = g.pl[p]
            s.given = s.given or 0
            local pos = p:GetPos()
            if pos.x > g.lineX and not LC.AdmireKneeling(p) and now >= (s.safe or 0) then
                if Hit(g, p, "Nobody stands before her", "Her honour guard lifts you by the collar and carries you to the back of the hall.") then
                    if s.carrying then s.carrying = nil end
                    if IsValid(g.guards[1]) then Snd(g.guards[1], "npc/combine_soldier/vo/contained.wav", 80, 90) end
                end
            elseif not s.carrying then
                for i, r in ipairs(g.rose) do
                    if not r.gone and r.pos:Distance(pos + Vector(0, 0, 20)) < 48 then
                        s.carrying, r.gone, g.dirty = true, now + 5, true
                        Snd(p, "items/flashlight1.wav", 60, 130)
                        break
                    end
                end
            elseif pos.x >= g.feetX then
                s.carrying, s.given, g.dirty = nil, s.given + 1, true
                Snd(p, "garrysmod/save_load1.wav", 60, 120)
                if s.given >= def.need then
                    Done(g, p, "won", "She accepts your roses", "She lets the roses rest at her feet, and for a heartbeat she almost smiles at you. You are adored.")
                else
                    Notice(p, "info", "A rose at her feet", string.format("She doesn't look down, but you're sure she noticed. %d to go.", def.need - s.given), 4)
                    ToStart(g, p, 1)
                end
            end
        end
    end

    function def.state(g, p)
        local s = p and g.pl[p] or {}
        local roses = {}
        for _, r in ipairs(g.rose) do if not r.gone then roses[#roses + 1] = { r.pos.x, r.pos.y, r.pos.z } end end
        local big, tone
        if not s.done and p and IsValid(p) then
            if p:GetPos().x > g.lineX then big, tone = "Her half of the hall: stay on your knees.", "warn"
            elseif s.carrying then big, tone = "Carry the rose to her feet. Kneel past the gold line.", "love"
            else big, tone = "Pick up a glowing rose.", "love" end
        end
        return { roses = roses, meter = math.floor((s.given or 0) / def.need * 100), meterName = string.format("Roses given: %d of %d", s.given or 0, def.need),
            carrying = s.carrying or nil, big = big, tone = tone }
    end
end

------------------------------------------------------------------------
-- Mirror, Mirror
------------------------------------------------------------------------

do
    local def = { id = "mirror", name = "Mirror, Mirror", mood = "happy", secs = 150, lives = 3, theme = "admire", need = 12,
        goal = "Kneel (crouch) and compliment her in chat. A word nobody has used yet counts double. Don't you dare insult her.",
        timeUp = TIMEUP, woke = Woke, hello = Hello }
    G.mirror = def
    -- Words she likes to hear (whole words, any case).
    LC.AdmireWords = { "beautiful", "gorgeous", "radiant", "stunning", "flawless", "elegant", "graceful", "divine", "goddess", "perfect",
        "lovely", "dazzling", "breathtaking", "magnificent", "exquisite", "glorious", "majestic", "luminous", "angelic", "enchanting",
        "captivating", "mesmerising", "mesmerizing", "sublime", "regal", "queen", "wise", "brilliant", "glowing", "ravishing",
        "statuesque", "timeless", "iconic", "heavenly", "sparkling", "pretty", "cute", "fabulous", "marvellous", "marvelous",
        "splendid", "superb", "wonderful", "amazing", "incredible", "charming", "classy", "dignified", "immaculate", "resplendent" }
    LC.AdmireInsults = { "ugly", "old", "fat", "boring", "plain", "hideous", "gross", "wrinkly", "breen", "overrated", "mediocre", "average" }
    local LIKE, HATE = {}, {}
    for _, w in ipairs(LC.AdmireWords) do LIKE[w] = true end
    for _, w in ipairs(LC.AdmireInsults) do HATE[w] = true end
    local REPLIES = { "She inclines her head, very slightly.", "Somewhere a violin agrees with you.", "Her reflection in every mirror smiles at once.",
        "She pretends not to have heard. She heard.", "The spotlight warms by a degree." }

    function def.build(g, dream)
        local x0, x1, top = Hall(g, dream, 2)
        local c = dream.pos
        Her(g, x1 - 110, c.y, top, 180)
        -- mirrors behind and either side of her
        for _, dy in ipairs({ -260, 0, 260 }) do
            local m = Block(g, "models/hunter/plates/plate2x3.mdl", Vector(x1 - 20, c.y + dy, top + 71), Angle(0, 90, 90), Color(255, 220, 240), "debug/env_cubemap_model")
            if not m then break end
        end
        Admirers(g, x0 + 200, x1 - 260, c.y - PLATE8_S + 40, c.y + PLATE8_S - 40, top, x1 - 110, c.y)
        g.used = {}
        Starts(g, x0 + 90, c.y, top)
        return true
    end

    function def.spawn(g, p, i) return g.starts[((i - 1) % #g.starts) + 1], 0 end

    function def.tick(g, dt, players)
        Swoon(g)
    end

    -- A line said in the dream: scored, and kept inside the dream. True if it was theirs to say here.
    function LC.AdmireSaid(g, p, text)
        local s = g.pl[p]
        if not s or s.done then return false end
        s.score, s.mine = s.score or 0, s.mine or {}
        -- everyone in the dream hears it (only them)
        for q, qs in pairs(g.pl) do
            if IsValid(q) and (not qs.done or qs.watching) and q.ChatPrint then q:ChatPrint("(in the dream) " .. p:Nick() .. ": " .. text) end
        end
        local words, seen, old, insulted = {}, {}, false, nil
        for w in string.gmatch(string.lower(text), "[%a]+") do
            if HATE[w] then insulted = w
            elseif LIKE[w] and s.mine[w] then old = true
            elseif LIKE[w] and not seen[w] then seen[w] = true words[#words + 1] = w end
        end
        if insulted then
            Hit(g, p, "She heard that", "\"" .. insulted .. "\"? Every mirror in the hall cracks at once, and you're thrown to the back.")
            return true
        end
        if #words == 0 then
            if old then Notice(p, "info", "She's heard that", "You've told her that already. She'd like something new.", 3) end
            return true
        end
        if not LC.AdmireKneeling(p) then
            Notice(p, "warn", "She didn't hear you", "She doesn't hear people who are standing. Kneel (crouch) first.", 4)
            return true
        end
        local liked, fresh = 0, 0
        for _, w in ipairs(words) do
            s.mine[w] = true
            liked = liked + 1
            if not g.used[w] then g.used[w] = true fresh = fresh + 1 end
        end
        s.score = s.score + liked + fresh
        g.dirty = true
        if s.score >= def.need then
            Done(g, p, "won", "The fairest of them all", "\"Yes,\" says every mirror in the hall, in her voice. \"You may adore me.\" You are adored.")
        else
            Notice(p, "info", fresh > 0 and "An original!" or "She liked that", REPLIES[math.random(#REPLIES)], 3)
        end
        return true
    end

    function def.state(g, p)
        local s = p and g.pl[p] or {}
        local big, tone
        if not s.done and p and IsValid(p) then
            if LC.AdmireKneeling(p) then big, tone = "Compliment her in chat.", "love"
            else big, tone = "Kneel (crouch) first: she doesn't hear people who stand.", "warn" end
        end
        return { meter = math.floor(math.min(1, (s.score or 0) / def.need) * 100), meterName = string.format("Adoration: %d of %d", s.score or 0, def.need), big = big, tone = tone }
    end

    -- Said in chat: theirs to say in the mirror dream? (Called first by the in-character chat,
    -- sv_livingcity_rp.lua, like the radio, and by its own hook too.) True: it stayed in the dream.
    function LC.AdmireSay(p, text)
        local dream = LC.DreamActive
        local g = dream and dream.game
        text = string.Trim(text or "")
        if text == "" or not g or g.stopped or g.id ~= "mirror" or not g.pl[p] or p.lcDreaming ~= dream.id then return false end
        local c = string.sub(text, 1, 1)
        if c == "/" or c == "!" or c == "@" then return false end -- (commands and tickets to staff still work)
        return LC.AdmireSaid(g, p, text)
    end
    hook.Add("PlayerSay", "LivingCityAdmireMirror", function(p, text)
        if LC.AdmireSay(p, text) then return "" end
    end)
end
