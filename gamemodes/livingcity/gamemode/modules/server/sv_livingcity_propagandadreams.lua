--[[
    Living City: propaganda dreams (dreams you play)

      The owner, 8 November: "dreams of the administrator where everyone is expected to borderline
      be aroused at her beauty but ultimately grovel at her feet and admire her while stereotypical
      erotic music plays (I will import some) ... but I don't want to push eroticism or 18+ content";
      then: "an administrator saviour dream where hl2 aliens and zombies are attacking the players
      unarmed and then the administrator descends, glowing ... 'stop! Come my soldiers, protect
      them' and then combine soldiers rush in with heroic music ... it's overtly propaganda",
      "rename this category from administrator dreams to propaganda dreams", and "If there is an
      administrator player, then we should have the option for them to star in the dream
      themselves instead of an NPC".

      Five dreams for the Administrator's tablet (Tablet > Tonight's dream > Happy, because of
      course she'd call them that; listed as "Propaganda: ..."), each built at the dream point out
      of plain props like the nightmares (sv_livingcity_dreamgames.lua). Vanity, flattery and
      heroics, nothing explicit. Everything else about a dream is as it always was: only those
      asleep dream it, and they wake in their bed with everything they had. But they can't be
      skipped (the owner: "I don't want these to be skippable"): no opting out, no waking yourself
      until you're out of it, like a nightmare (LC.DreamForced, sv_livingcity_dreams.lua); only a
      stimulant before bed, or being Unbroken, keeps you out of one.

        Kneel Before Her (adore): her gaze sweeps the hall. Kneel (crouch) and look up at her to
          fill your Devotion, faster while she's looking your way. Anyone she catches standing in
          her gaze loses one of three lives. Full Devotion: she notices you.
        Roses for Her (roses): carry glowing roses from the back of the hall to her feet. Her half
          of the hall is crossed on your knees, or her honour guard sends you back. Three roses.
        Mirror, Mirror (mirror): kneel and compliment her in chat. A word nobody else has used yet
          is worth double; your own again is worth nothing; an insult costs a life.
        The Saviour (saviour): zombies, headcrabs and antlions come for the dreamers, who have
          nothing to fight with, and they hurt (in the dream). The moment any dreamer is down to 25
          health (or after 80 seconds), every one of them freezes where it is, and she descends
          glowing from near the top of the dream zone to land between them and the citizens:
          "Stop!", then "Come, my soldiers. Protect them." Combine soldiers swarm in to the heroic
          music and kill every one. They only ever shoot the monsters, never a dreamer (rebels
          included). Still standing when it's over: saved.
        The Loyalty Quiz (quiz): she asks ten questions ("Who keeps you safe at night?"); answer in
          chat. Right answers earn Loyalty, the first to answer earns double; thoughtcrime
          ("Freeman", "Lambda", "revolution") costs a life. Six Loyalty wins.

      Starring: if the Administrator is asleep for one of these along with at least one other
      dreamer, and her tablet's "Star in propaganda dreams yourself" is on (it is, unless she turns
      it off), she plays her part herself instead of the giant figure: on the pedestal (a giant,
      looking where she likes: in Kneel Before Her, where she looks is her gaze), descending in a
      glow in The Saviour, on the podium in the quiz. What she says in chat in the dream, the
      dreamers hear (on screen), and nobody in the city does. If she wakes, a giant figure of her
      takes her place.

      The music, flat in garrysmod/sound/livingcity/dreams/, named for its codeword like the ending
      songs (.mp3, .ogg or .wav; adore1.mp3, saviour2.ogg): admire (any of the three admiring
      dreams, or adore, roses, mirror for one of them), saviour_horde (The Saviour before she comes),
      saviour (The Saviour once her soldiers arrive), quiz. Anything in the older
      sound/livingcity/dreams/administrator/ counts as admire. One song is picked at random, looping.
      No song: no music.

      Her voice, in garrysmod/sound/livingcity/dreams/voice/, named for its line (saviour_stop1.wav;
      a .txt with the same name is its subtitle): adore_hello, roses_hello, mirror_hello,
      saviour_stop, saviour_soldiers, saviour_safe, quiz_hello, quiz_q1 to quiz_q10, quiz_end. No
      recording: the subtitle alone (LC.PropagandaCues has every line's words).

      Waking: a line on screen. Disloyalty costs (the owner: "loss of loyalty and a bit of civil
      standing", not health): each offence in the dream (caught standing in her gaze or before her,
      an insult to her or the Combine, thoughtcrime) is 3 loyalty points, and being thrown out of
      it (every life gone) 5 more, at most 20 a dream, taken from Civil Standing (loyalty points are
      Civil Standing) as they wake. Nothing for winning, and no health lost.
]]

if CLIENT then return end

LC = LC or {}

local K = LC.DreamGameKit
local G = LC.DreamGames
if not K or not G then return end
local Block, Actor, Floor, Snd, Done, Hit, ToStart, Send = K.Block, K.Actor, K.Floor, K.Snd, K.Done, K.Hit, K.ToStart, K.Send
local PLATE8, PLATE8_S, PLATE4, PLATE4_S = K.PLATE8, K.PLATE8_S, K.PLATE4, K.PLATE4_S

local function Notice(p, kind, title, text, secs)
    if not IsValid(p) then return end
    if LC.Notice then LC.Notice(p, kind, title, text, secs) else p:ChatPrint(title .. ": " .. text) end
end

-- Offences in tonight's dream, kept off the player (waking puts back everything that was on them).
local OFF = {} -- [steamid64] = { n = offences, out = true }
local function Key(p) return tostring(p:SteamID64()) end

LC.PropagandaDreams = { adore = true, roses = true, mirror = true, saviour = true, quiz = true }
for _, id in ipairs({ "adore", "roses", "mirror", "saviour", "quiz" }) do
    local have = false
    for _, o in ipairs(LC.DreamGameOrder) do if o == id then have = true end end
    if not have then LC.DreamGameOrder[#LC.DreamGameOrder + 1] = id end
end

------------------------------------------------------------------------
-- The music and her voice
------------------------------------------------------------------------

LC.PropagandaRoot = "livingcity/dreams/"
LC.PropagandaOldRoot = "livingcity/dreams/administrator/" -- (read as "admire": where it was first, 8 November)
LC.PropagandaVoiceRoot = "livingcity/dreams/voice/"
LC.PropagandaSongWords = { "admire", "adore", "roses", "mirror", "saviour", "saviour_horde", "quiz" }
-- Every line she says, and its words on screen (a recording's .txt replaces them).
LC.PropagandaCues = {
    adore_hello = "You may look upon me. On your knees, of course.",
    roses_hello = "Flowers? For me? How predictable. How lovely.",
    mirror_hello = "Tell me what you see.",
    saviour_stop = "STOP!",
    saviour_soldiers = "Come, my soldiers. Protect them.",
    saviour_safe = "You are safe now, my children. You are always safe with me.",
    quiz_hello = "Good evening, citizens. Let us see how well you know your city.",
    quiz_end = "Well answered. The city is proud of you.",
    quiz_rebel = "Officers. Remove him.",
    quiz_resume = "Where were we? Ah, yes.",
}
local AUDIO = { mp3 = true, ogg = true, wav = true }
local function Ext(n) local e = string.match(n or "", "%.([%w]+)$") return e and string.lower(e) or nil end
-- The word a file's name starts with (the longest that fits), followed by nothing, a number or a
-- separator; nil: none of them.
function LC.PropagandaWordOf(name, words)
    local base = string.lower(string.match(name or "", "^(.*)%.[%w]+$") or "")
    local best
    for _, w in ipairs(words) do
        if string.sub(base, 1, #w) == w and (not best or #w > #best) then
            local rest = string.sub(base, #w + 1, #w + 1)
            if rest == "" or not string.match(rest, "%a") then best = w end
        end
    end
    return best
end
local function CueWords()
    local out = {}
    for k in pairs(LC.PropagandaCues) do out[#out + 1] = k end
    return out
end
local function Find(root)
    local names = file.Find("sound/" .. root .. "*", "GAME") or {}
    table.sort(names)
    return names
end
-- Songs for a word: flat in sound/livingcity/dreams/ (and, for admire, the older folder).
function LC.PropagandaSongs(word)
    local out = {}
    for _, n in ipairs(Find(LC.PropagandaRoot)) do
        if AUDIO[Ext(n) or ""] and LC.PropagandaWordOf(n, LC.PropagandaSongWords) == word then out[#out + 1] = LC.PropagandaRoot .. n end
    end
    if word == "admire" then
        for _, n in ipairs(Find(LC.PropagandaOldRoot)) do if AUDIO[Ext(n) or ""] then out[#out + 1] = LC.PropagandaOldRoot .. n end end
    end
    return out
end
-- A song for one of the words (the first that has any), at random.
function LC.PropagandaSong(words)
    for _, w in ipairs(words or {}) do
        local list = LC.PropagandaSongs(w)
        if #list > 0 then return list[math.random(#list)] end
    end
    return nil
end
-- One of her lines: a recording (or nil) and its words.
function LC.PropagandaVoice(cue)
    local list = {}
    for _, n in ipairs(Find(LC.PropagandaVoiceRoot)) do
        if AUDIO[Ext(n) or ""] and LC.PropagandaWordOf(n, CueWords()) == cue then list[#list + 1] = n end
    end
    local text = LC.PropagandaCues[cue] or ""
    if #list == 0 then return nil, text end
    local n = list[math.random(#list)]
    local sub = file.Read("sound/" .. LC.PropagandaVoiceRoot .. string.gsub(n, "%.[%w]+$", ".txt"), "GAME")
    if sub and string.Trim(sub) ~= "" then text = string.Trim(sub) end
    return LC.PropagandaVoiceRoot .. n, text
end
do -- (all of it sent to players when the map starts)
    local function Add(path) if resource and resource.AddFile then resource.AddFile("sound/" .. path) end end
    for _, n in ipairs(Find(LC.PropagandaRoot)) do if AUDIO[Ext(n) or ""] then Add(LC.PropagandaRoot .. n) end end
    for _, n in ipairs(Find(LC.PropagandaOldRoot)) do if AUDIO[Ext(n) or ""] then Add(LC.PropagandaOldRoot .. n) end end
    for _, n in ipairs(Find(LC.PropagandaVoiceRoot)) do if AUDIO[Ext(n) or ""] then Add(LC.PropagandaVoiceRoot .. n) end end
end

-- Everyone in the dream (still in it, or watching), and the star.
local function Everyone(g)
    local out = {}
    for p, s in pairs(g.pl) do if IsValid(p) and (not s.done or s.watching) then out[#out + 1] = p end end
    if IsValid(g.star) then out[#out + 1] = g.star end
    for p in pairs(g.enf or {}) do if IsValid(p) then out[#out + 1] = p end end -- (Enforcers: sv_livingcity_dreamenforcers.lua)
    return out
end
-- Something said in the dream, on everyone's screen (her lines, with their recording).
local function Line(g, text, snd, who)
    local list = Everyone(g)
    if #list == 0 then return end
    net.Start("lc_dreamgame")
    net.WriteTable({ k = "line", who = who or "The Administrator", text = text, snd = snd })
    net.Send(list)
end
local function Say(g, cue)
    local snd, text = LC.PropagandaVoice(cue)
    g.said = g.said or {}
    g.said[#g.said + 1] = cue
    Line(g, text, snd)
end
LC.PropagandaLine = Say

------------------------------------------------------------------------
-- Starring: the Administrator playing herself
------------------------------------------------------------------------

function LC.DreamStarWants(p) return IsValid(p) and p:GetPData("lc_dream_star", "1") ~= "0" end
function LC.DreamStarSet(p, on)
    if not IsValid(p) then return false end
    p:SetPData("lc_dream_star", on and "1" or "0")
    Notice(p, "info", "Propaganda dreams", on and "You'll star in propaganda dreams yourself, when you're asleep for one with someone else."
        or "A giant figure of you stars in propaganda dreams instead of you.", 7)
    return true
end
-- Of tonight's dreamers, the Administrator who stars (asleep with at least one other), or nil.
function LC.DreamStarOf(players)
    if #players < 2 then return nil end
    for _, p in ipairs(players) do
        if IsValid(p) and LC.IsAdministrator and LC.IsAdministrator(p) and LC.DreamStarWants(p) then return p end
    end
    return nil
end
-- Out of the dream: her own size, seen, walking.
function LC.DreamStarDone(p)
    if not IsValid(p) then return end
    if p.SetModelScale then p:SetModelScale(1, 0) end
    if p.SetViewOffset then p:SetViewOffset(Vector(0, 0, 64)) end
    if p.SetViewOffsetDucked then p:SetViewOffsetDucked(Vector(0, 0, 28)) end
    if p.SetNoDraw then p:SetNoDraw(false) end
    if p.SetMoveType then p:SetMoveType(MOVETYPE_WALK) end
    p:SetNW2Bool("lc_dream_star", false)
end
local function StarAt(p, pos, yaw, scale, still)
    p:SetPos(pos)
    if p.SetEyeAngles then p:SetEyeAngles(Angle(0, yaw or 0, 0)) end
    if p.SetModelScale then p:SetModelScale(scale or 1, 0) end
    if p.SetViewOffset then p:SetViewOffset(Vector(0, 0, 64 * (scale or 1))) end
    if p.SetViewOffsetDucked then p:SetViewOffsetDucked(Vector(0, 0, 28 * (scale or 1))) end
    if p.SetMoveType then p:SetMoveType(still and MOVETYPE_NONE or MOVETYPE_WALK) end
    p:SetNW2Bool("lc_dream_star", true)
end

------------------------------------------------------------------------
-- The stage: her, her pedestal, her admirers, the crowd
------------------------------------------------------------------------

local PLUM, GOLD, ROSE = Color(70, 30, 60), Color(230, 185, 80), Color(200, 20, 50)
local ASH, NAVY = Color(55, 55, 60), Color(30, 40, 70)
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
LC.QuizBanners = {
    "A banner unfurls behind her: COMPLIANCE IS HAPPINESS.",
    "The audience applauds on cue. Then again, slightly louder, in case she didn't hear.",
    "A scanner drifts over the audience, taking notes.",
    "Somewhere offstage, an officer holds up a sign that says CHEER.",
    "Confetti in the city's colours falls from the ceiling. Every piece is accounted for.",
    "A citizen in the front row mouths the answers along with everyone else, a fraction early.",
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

-- Her, giant, as a figure (not the star).
local function Figure(g, pos, yaw, scale)
    local e = Actor(g, LC.AdmireModel(), pos, yaw, scale, ACT_IDLE or 1)
    Pose(e, POSE)
    g.her = e
    g.dirty = true
    return e
end
local function HerEnt(g)
    if IsValid(g.star) then return g.star:EntIndex() end
    if IsValid(g.her) then return g.her:EntIndex() end
    return nil
end

-- Her on a gold pedestal at (x, y), facing yaw: the star if she's starring, else a giant figure.
local function Her(g, x, y, top, yaw)
    local room = LC.DreamGameHeadroom and LC.DreamGameHeadroom(g.dream) or 2000
    local scale = math.Clamp((room - 120) / 80, 2, 4)
    local base = top
    if K.ValidModel("models/hunter/blocks/cube2x2x1.mdl") then
        Block(g, "models/hunter/blocks/cube2x2x1.mdl", Vector(x, y, top + 23.7), Angle(0, 0, 0), GOLD, "models/debug/debugwhite")
        base = top + 47.4
    end
    g.herYaw, g.herScale = yaw, scale
    g.herBase = Vector(x, y, base)
    g.herHead = Vector(x, y, base + 66 * scale)
    if not g.star then Figure(g, g.herBase, yaw, scale) end
end
-- (the pedestal dreams' star: on it, giant, looking where she likes)
local function PedestalStar(g, p) StarAt(p, g.herBase + Vector(0, 0, 2), g.herYaw, math.min(g.herScale, 2.5), true) end
local function PedestalGone(g) Figure(g, g.herBase, g.herYaw, g.herScale) end
-- Where her head is now, and where she faces (the star moves her head; the figure doesn't).
local function Follow(g)
    if IsValid(g.star) then
        g.herHead = g.star:EyePos()
        local a = g.star.EyeAngles and g.star:EyeAngles()
        if a then g.herYaw = a.y end
    end
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
            g.admirers = g.admirers or {} -- (kept, for their acting: sv_livingcity_dreamstage.lua)
            g.admirers[#g.admirers + 1] = e
        end
    end
end

-- The crowd, now and then (everyone in the dream sees it).
local function Crowd(g, lines)
    if CurTime() < (g.swoonAt or 0) then return end
    g.swoonAt = CurTime() + math.Rand(18, 26)
    g.swoonN = (g.swoonN or math.random(#lines)) % #lines + 1
    for _, p in ipairs(Everyone(g)) do Notice(p, "info", "In the dream", lines[g.swoonN], 6) end
end

local function Hello(theme, cue)
    return function(g)
        g.song = LC.PropagandaSong(g.def.music)
        if cue then timer.Simple(2, function() if g and not g.stopped then Say(g, cue) end end) end
        return { theme = theme, song = g.song, herEnt = HerEnt(g), her = g.herHead and { g.herHead.x, g.herHead.y, g.herHead.z } or nil }
    end
end
-- How a dream leaves you: a line, nothing more.
local function Woke(lines)
    return function(p, how)
        local l = lines[how]
        if l then Notice(p, "info", l[1], l[2], 9) end
    end
end
local ADMIRE_WOKE = Woke({
    won = { "Starstruck", "You wake with her face still in your mind, warm and a little embarrassed, humming a tune you've never heard. Nobody needs to know about this dream." },
    out = { "Dismissed", "In the dream she turned away from you, and you wake with your cheeks burning. It was only a dream. Probably." },
    time = { "The music fades", "The spotlight dims, the music fades, and you wake in your bed, strangely devoted to the city's paperwork." },
})
local ADMIRE_TIMEUP = { "The music fades", "The spotlight dims before the end, and she's gone. You wake." }

-- A floor of plates, along x, two wide; its top at top. The first x and the last.
local function Hall(g, dream, maxLong, col)
    local half = LC.DreamGameHalf(dream)
    local long = math.Clamp(math.floor(half * 2 / PLATE8_S), 2, maxLong or 3)
    local c = dream.pos
    local top = c.z + 2
    local x0 = c.x - long * PLATE8_S / 2
    for i = 1, long do for j = 0, 1 do
        Floor(g, PLATE8, x0 + (i - 0.5) * PLATE8_S, c.y + (j - 0.5) * PLATE8_S, top, col or PLUM, "models/debug/debugwhite")
    end end
    g.top = top
    g.bounds = { mins = Vector(x0 - 60, c.y - PLATE8_S - 60, top - 160), maxs = Vector(x0 + long * PLATE8_S + 60, c.y + PLATE8_S + 60, top + 400) }
    return x0, x0 + long * PLATE8_S, top
end

local function Starts(g, x, y, top)
    g.starts = {}
    for i = 0, 11 do g.starts[#g.starts + 1] = Vector(x + (i % 2) * 40, y - 330 + i * 60, top + 4) end
end
local function Spawn(g, p, i)
    OFF[Key(p)] = nil -- (a fresh start for tonight's loyalty)
    return g.starts[((i - 1) % #g.starts) + 1], 0
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
    if IsValid(g.star) or not IsValid(g.her) then return end
    local want = g.gazeWant or g.herYaw
    local y = g.herYaw
    if math.ApproachAngle then y = math.ApproachAngle(y, want, 45 * dt) else y = want end
    g.herYaw = y
    g.her:SetAngles(Angle(0, y, 0))
end

-- Disloyalty in the dream: a life gone (Hit), and an offence counted against them for waking.
-- (kept off the player: waking puts back everything that was on them before the dream)
LC.PropagandaOffencePoints, LC.PropagandaOutPoints, LC.PropagandaMaxPoints = 3, 5, 20
function LC.PropagandaOffences(p) local o = IsValid(p) and OFF[Key(p)] return o and o.n or 0, o and o.out or false end
local function Offend(g, p, title, text)
    local s = g.pl[p]
    if not s or s.done or CurTime() < (s.safe or 0) then return false end
    local o = OFF[Key(p)] or { n = 0 }
    OFF[Key(p)] = o
    o.n = o.n + 1
    hook.Run("LivingCityDreamOffence", g, p, title) -- (an Enforcer can see it: sv_livingcity_dreamenforcers.lua)
    local hit = Hit(g, p, title, text .. string.format(" (-%d loyalty points)", LC.PropagandaOffencePoints))
    if hit and s.done and s.how == "out" then o.out = true end
    return hit
end
LC.PropagandaOffend = Offend
-- How many loyalty points the dream cost them.
function LC.PropagandaLoss(p)
    local n, out = LC.PropagandaOffences(p)
    local loss = math.min(LC.PropagandaMaxPoints, n * LC.PropagandaOffencePoints + (out and LC.PropagandaOutPoints or 0))
    if p.lcVortWeak then loss = math.floor(loss / 2) end -- (the vortigaunts shattered her last one: her spell is weakened, sv_livingcity_vortwar.lua)
    return loss
end
-- As they wake: the loss taken from Civil Standing (loyalty points are Civil Standing).
hook.Add("LivingCityDreamWoke", "LivingCityPropagandaLoyalty", function(p, _, why)
    if not IsValid(p) then return end
    local n = LC.PropagandaLoss(p)
    OFF[Key(p)] = nil
    if n <= 0 or why == "test" then return end -- (a test from the editor costs nothing)
    if LC.AddStanding then LC.AddStanding(p, -n, "disloyalty in a propaganda dream") end
    Notice(p, "warn", "Disloyal, even in your sleep", string.format("The city noticed how you behaved in the dream: -%d loyalty points (Civil Standing).", n), 8)
end)

-- What the star sees in the middle of her screen.
local function StarState(g, text) return { big = text, tone = "love", herEnt = HerEnt(g) } end

------------------------------------------------------------------------
-- Kneel Before Her
------------------------------------------------------------------------

do
    local def = { id = "adore", name = "Kneel Before Her", mood = "happy", secs = 150, lives = 3, music = { "adore", "admire" },
        goal = "Kneel (crouch) and gaze up at her to fill your Devotion. Never let her catch you standing in her gaze.",
        starGoal = "You're the star, on your pedestal. Wherever you look is your gaze: anyone you catch standing loses a life. Say anything in chat and the dream hears you.",
        timeUp = ADMIRE_TIMEUP, woke = ADMIRE_WOKE, starring = PedestalStar, starGone = PedestalGone, spawn = Spawn }
    def.hello = Hello("admire", "adore_hello")
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

    function def.tick(g, dt, players)
        local now = CurTime()
        if not IsValid(g.star) and now >= g.gazeAt then
            g.gazeWant, g.gazeAt = 180 + math.Rand(-50, 50), now + math.Rand(2.5, 4.5)
            g.dirty = true
        end
        Turn(g, dt)
        Follow(g)
        Crowd(g, LC.AdmireSwoons)
        for _, p in ipairs(players) do
            local s = g.pl[p]
            s.devotion = s.devotion or 0
            local gaze = LC.AdmireInGaze(g, p)
            local kneel = LC.AdmireKneeling(p)
            if s.gaze ~= gaze then s.gaze = gaze g.dirty = true end
            if gaze and not kneel and now >= (s.safe or 0) then
                if Offend(g, p, "You stood in her presence", "She looked straight at you, and you were standing.") then
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
        if p == g.star then return StarState(g, "They kneel before you. Look upon them.") end
        local s = p and g.pl[p] or {}
        local big, tone
        if s.gaze and not s.done then big, tone = "She's looking at you! Stay on your knees.", "warn"
        elseif not s.done then big, tone = "Kneel, and gaze up at her.", "love" end
        return { meter = math.floor(s.devotion or 0), meterName = "Devotion", big = big, tone = tone, herEnt = HerEnt(g) }
    end
end

------------------------------------------------------------------------
-- Roses for Her
------------------------------------------------------------------------

do
    local def = { id = "roses", name = "Roses for Her", mood = "happy", secs = 180, lives = 3, need = 3, music = { "roses", "admire" },
        goal = "Pick up a glowing rose at the back of the hall and lay it at her feet. In the front half of the hall, stay on your knees (crouch).",
        starGoal = "You're the star, on your pedestal. They bring you roses on their knees. Say anything in chat and the dream hears you.",
        timeUp = ADMIRE_TIMEUP, woke = ADMIRE_WOKE, starring = PedestalStar, starGone = PedestalGone, spawn = Spawn }
    def.hello = Hello("admire", "roses_hello")
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
        for _, dy in ipairs({ -200, 200 }) do g.guards[#g.guards + 1] = Actor(g, GUARD, Vector(x1 - 160, c.y + dy, top), 180, 1.6, ACT_IDLE or 1) end
        Admirers(g, g.lineX + 60, x1 - 320, c.y - PLATE8_S + 40, c.y + PLATE8_S - 40, top, x1 - 110, c.y)
        g.backX0, g.backX1 = x0 + 200, g.lineX - 80
        g.rose = {}
        for i = 1, 6 do g.rose[i] = {} NewRose(g, i) end
        Starts(g, x0 + 90, c.y, top)
        return true
    end

    function def.tick(g, dt, players)
        local now = CurTime()
        Follow(g)
        Crowd(g, LC.AdmireSwoons)
        for i, r in ipairs(g.rose) do
            if r.gone and now >= r.gone then NewRose(g, i) g.dirty = true end
        end
        for _, p in ipairs(players) do
            local s = g.pl[p]
            s.given = s.given or 0
            local pos = p:GetPos()
            if pos.x > g.lineX and not LC.AdmireKneeling(p) and now >= (s.safe or 0) then
                if Offend(g, p, "Nobody stands before her", "Her honour guard lifts you by the collar and carries you to the back of the hall.") then
                    s.carrying = nil
                    if IsValid(g.guards[1]) then Snd(g.guards[1], "npc/combine_soldier/vo/contained.wav", 80, 90) end
                end
            elseif not s.carrying then
                for _, r in ipairs(g.rose) do
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
        local roses = {}
        for _, r in ipairs(g.rose) do if not r.gone then roses[#roses + 1] = { r.pos.x, r.pos.y, r.pos.z } end end
        if p == g.star then local t = StarState(g, "They bring you roses, on their knees.") t.roses = roses return t end
        local s = p and g.pl[p] or {}
        local big, tone
        if not s.done and p and IsValid(p) then
            if p:GetPos().x > g.lineX then big, tone = "Her half of the hall: stay on your knees.", "warn"
            elseif s.carrying then big, tone = "Carry the rose to her feet. Kneel past the gold line.", "love"
            else big, tone = "Pick up a glowing rose.", "love" end
        end
        return { roses = roses, meter = math.floor((s.given or 0) / def.need * 100), meterName = string.format("Roses given: %d of %d", s.given or 0, def.need),
            carrying = s.carrying or nil, big = big, tone = tone, herEnt = HerEnt(g) }
    end
end

------------------------------------------------------------------------
-- Mirror, Mirror
------------------------------------------------------------------------

do
    local def = { id = "mirror", name = "Mirror, Mirror", mood = "happy", secs = 150, lives = 3, need = 12, music = { "mirror", "admire" },
        goal = "Kneel (crouch) and compliment her in chat. A word nobody has used yet counts double. Don't you dare insult her.",
        starGoal = "You're the star, before your mirrors. Listen to their compliments. Anything you say in chat, the dream hears.",
        timeUp = ADMIRE_TIMEUP, woke = ADMIRE_WOKE, starring = PedestalStar, starGone = PedestalGone, spawn = Spawn }
    def.hello = Hello("admire", "mirror_hello")
    G.mirror = def
    -- Words she likes to hear (whole words, any case).
    LC.AdmireWords = { "beautiful", "gorgeous", "radiant", "stunning", "flawless", "elegant", "graceful", "divine", "goddess", "perfect",
        "lovely", "dazzling", "breathtaking", "magnificent", "exquisite", "glorious", "majestic", "luminous", "angelic", "enchanting",
        "captivating", "mesmerising", "mesmerizing", "sublime", "regal", "queen", "wise", "brilliant", "glowing", "ravishing",
        "statuesque", "timeless", "iconic", "heavenly", "sparkling", "pretty", "cute", "fabulous", "marvellous", "marvelous",
        "splendid", "superb", "wonderful", "amazing", "incredible", "charming", "classy", "dignified", "immaculate", "resplendent" }
    LC.AdmireInsults = { "ugly", "old", "fat", "boring", "plain", "hideous", "gross", "wrinkly", "breen", "overrated", "mediocre", "average" }
    -- (and the Combine: an insult to them is an insult to her)
    LC.CombineInsults = { "fascist", "fascists", "tyrant", "tyrants", "tyranny", "oppressor", "oppressors", "oppression", "dictator", "dictatorship", "pig", "pigs", "occupiers" }
    for _, w in ipairs(LC.CombineInsults) do LC.AdmireInsults[#LC.AdmireInsults + 1] = w end
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
            if not Block(g, "models/hunter/plates/plate2x3.mdl", Vector(x1 - 20, c.y + dy, top + 71), Angle(0, 90, 90), Color(255, 220, 240), "debug/env_cubemap_model") then break end
        end
        Admirers(g, x0 + 200, x1 - 260, c.y - PLATE8_S + 40, c.y + PLATE8_S - 40, top, x1 - 110, c.y)
        g.used = {}
        Starts(g, x0 + 90, c.y, top)
        return true
    end

    function def.tick(g, dt, players)
        Follow(g)
        Crowd(g, LC.AdmireSwoons)
    end

    -- A line said in the dream: scored, and kept inside the dream. True if it was theirs to say here.
    function LC.AdmireSaid(g, p, text)
        local s = g.pl[p]
        if not s or s.done then return false end
        s.score, s.mine = s.score or 0, s.mine or {}
        for _, q in ipairs(Everyone(g)) do if q.ChatPrint then q:ChatPrint("(in the dream) " .. p:Nick() .. ": " .. text) end end
        local words, seen, old, insulted = {}, {}, false, nil
        for w in string.gmatch(string.lower(text), "[%a]+") do
            if HATE[w] then insulted = w
            elseif LIKE[w] and s.mine[w] then old = true
            elseif LIKE[w] and not seen[w] then seen[w] = true words[#words + 1] = w end
        end
        if insulted then
            Offend(g, p, "She heard that", "\"" .. insulted .. "\"? Every mirror in the hall cracks at once, and you're thrown to the back.")
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
    def.say = LC.AdmireSaid

    function def.state(g, p)
        if p == g.star then return StarState(g, "They compliment you, on their knees.") end
        local s = p and g.pl[p] or {}
        local big, tone
        if not s.done and p and IsValid(p) then
            if LC.AdmireKneeling(p) then big, tone = "Compliment her in chat.", "love"
            else big, tone = "Kneel (crouch) first: she doesn't hear people who stand.", "warn" end
        end
        return { meter = math.floor(math.min(1, (s.score or 0) / def.need) * 100), meterName = string.format("Adoration: %d of %d", s.score or 0, def.need),
            big = big, tone = tone, herEnt = HerEnt(g) }
    end
end

------------------------------------------------------------------------
-- The Saviour
------------------------------------------------------------------------

do
    local def = { id = "saviour", name = "The Saviour", mood = "happy", secs = 150, lives = 1, music = { "saviour_horde" },
        goal = "The dead are coming, and you have nothing to fight with. Run. Dodge. Hold on. Help will come.",
        starGoal = "You're the star. Watch them suffer from on high. When one of them is close to the end, you descend and save them; walk among them when you land. Anything you say in chat, the dream hears.",
        timeUp = { "The light fades", "The dream dissolves into gold, and you wake." }, spawn = Spawn,
        woke = Woke({
            won = { "Saved", "You wake safe in your bed, and for a moment you'd swear you can still feel her light. The Combine protect you. They always have." },
            time = { "The light fades", "You wake in your bed, safe, warm, and protected. As always." },
        }) }
    def.hello = Hello("glory", nil)
    G.saviour = def
    -- When she comes: anyone down to this much health (or this long without), and how her rescue goes (seconds after it starts).
    LC.SaviourTimes = { horde = 4, low = 25, latest = 80, land = 5, soldiers = 8 }
    local T = LC.SaviourTimes
    local MONSTERS = {
        { m = "models/zombie/classic.mdl", speed = 70, act = ACT_WALK, die = "npc/zombie/zombie_die1.wav", dmg = 10 },
        { m = "models/zombie/fast.mdl", speed = 165, act = ACT_RUN, die = "npc/fast_zombie/fz_alert_close1.wav", dmg = 6 },
        { m = "models/headcrabclassic.mdl", speed = 120, act = ACT_RUN, die = "npc/headcrab/die1.wav", dmg = 5 },
        { m = "models/antlion.mdl", speed = 150, act = ACT_RUN, die = "npc/antlion/pain1.wav", dmg = 8 },
        { m = "models/zombie/poison.mdl", speed = 55, act = ACT_WALK, die = "npc/zombie_poison/pz_die1.wav", dmg = 12 },
    }
    local SOLDIER = "models/combine_soldier.mdl"
    local SHOTS = { "weapons/ar2/fire1.wav", "weapons/smg1/smg1_fire1.wav" }
    local CLAWS = { "npc/zombie/claw_strike1.wav", "npc/zombie/claw_strike2.wav", "npc/headcrab/headbite.wav" }

    local function Edge(g)
        local side = math.random(4)
        local x = side <= 2 and math.Rand(g.x0, g.x1) or (side == 3 and g.x0 + 20 or g.x1 - 20)
        local y = side == 1 and g.y0 or (side == 2 and g.y1 or math.Rand(g.y0, g.y1))
        return Vector(x, y, g.top)
    end
    local function NewMonster(g)
        local m = MONSTERS[math.random(#MONSTERS)]
        local pos = Edge(g)
        local yaw = math.deg(math.atan2(g.mid.y - pos.y, g.mid.x - pos.x))
        local e = Actor(g, m.m, pos, yaw, 1, m.act)
        if not e then return end
        g.mons[#g.mons + 1] = { e = e, speed = m.speed, die = m.die, dmg = m.dmg, alive = true }
    end
    local function Alive(g)
        local n = 0
        for _, m in ipairs(g.mons) do if m.alive and IsValid(m.e) then n = n + 1 end end
        return n
    end
    LC.SaviourAlive = Alive
    local function Kill(g, m, by)
        m.alive = false
        if IsValid(by) then Snd(by, SHOTS[math.random(#SHOTS)], 85) end
        if IsValid(m.e) then
            local pos = m.e:GetPos()
            if IsValid(by) and EffectData then
                local ed = EffectData()
                if ed.SetStart then ed:SetStart(by:GetPos() + Vector(0, 0, 45)) end
                ed:SetOrigin(pos + Vector(0, 0, 30))
                util.Effect("AR2Tracer", ed, true, true)
            end
            if EffectData then
                local ed = EffectData()
                ed:SetOrigin(pos + Vector(0, 0, 30))
                util.Effect("BloodImpact", ed, true, true)
            end
            Snd(m.e, m.die, 75)
            m.e:Remove()
        end
    end
    -- Move an actor toward a point at speed (on the floor), facing it. Returns the distance left.
    local function Toward(e, to, speed, dt, top)
        local pos = e:GetPos()
        local d = Vector(to.x - pos.x, to.y - pos.y, 0)
        local len = d:Length()
        if len > 1 then
            local step = math.min(len, speed * dt)
            local n = d:GetNormalized()
            e:SetPos(Vector(pos.x + n.x * step, pos.y + n.y * step, top))
            e:SetAngles(Angle(0, math.deg(math.atan2(n.y, n.x)), 0))
        end
        return len
    end
    local function SetHer(g, pos, yaw)
        local e = IsValid(g.star) and g.star or g.her
        if not IsValid(e) then return end
        e:SetPos(pos)
        if yaw then if e == g.star then if e.SetEyeAngles then e:SetEyeAngles(Angle(0, yaw, 0)) end else e:SetAngles(Angle(0, yaw, 0)) end end
    end
    local function Centre(list, posOf)
        local x, y, n = 0, 0, 0
        for _, v in ipairs(list) do local p = posOf(v) if p then x, y, n = x + p.x, y + p.y, n + 1 end end
        if n == 0 then return nil end
        return Vector(x / n, y / n, 0)
    end

    function def.build(g, dream)
        local x0, x1, top = Hall(g, dream, 3, ASH)
        local c = dream.pos
        g.x0, g.x1, g.y0, g.y1 = x0 + 30, x1 - 30, c.y - PLATE8_S + 30, c.y + PLATE8_S - 30
        g.mid = Vector(c.x, c.y, top)
        -- how high she comes down from: near the top of the dream zone (or of the room above the point)
        local z = dream.zone
        local ceiling = (z and z.box and z.box.maxs.z) or (top + (LC.DreamGameHeadroom and LC.DreamGameHeadroom(dream) or 2000))
        g.skyZ = math.max(top + 250, math.min(ceiling - 120, top + 1500))
        -- a little cover in the ruins (it won't stop them for long)
        local DRUM = "models/props_c17/oildrum001.mdl"
        if K.ValidModel(DRUM) then
            for i = 1, 6 do Block(g, DRUM, Vector(c.x + math.cos(i) * 300, c.y + math.sin(i * 2) * 260, top), Angle(0, i * 40, 0), Color(90, 80, 70)) end
        end
        g.mons, g.soldiers, g.phase = {}, {}, "calm"
        g.starts = {}
        for i = 0, 11 do
            local a = i / 12 * math.pi * 2
            g.starts[#g.starts + 1] = Vector(c.x + math.cos(a) * 90, c.y + math.sin(a) * 90, top + 4)
        end
        return true
    end

    -- The star waits above, unseen, watching, until someone is close to the end.
    function def.starring(g, p)
        StarAt(p, Vector(g.mid.x, g.mid.y, g.skyZ), 0, 1, true)
        if p.SetNoDraw then p:SetNoDraw(true) end
    end
    function def.starGone(g, p)
        if g.phase == "calm" or g.phase == "horde" then return end -- (a figure of her comes when she's needed)
        Figure(g, g.land or g.mid, g.landYaw or 0, 1.6)
    end

    local PHASE_ORDER = { calm = 1, horde = 2, descend = 3, stop = 4, soldiers = 5, safe = 6 }
    LC.SaviourPhaseOrder = PHASE_ORDER

    -- Someone is close to the end: everything freezes, and she comes.
    local function Rescue(g, players, now)
        g.phase, g.rescueAt, g.dirty = "descend", now, true
        for _, m in ipairs(g.mons) do if IsValid(m.e) and K.Animate then K.Animate(m.e, ACT_IDLE or 1) end end
        -- between the dead and the citizens, facing the dead
        local mc = Centre(g.mons, function(m) return m.alive and IsValid(m.e) and m.e:GetPos() or nil end)
        local pc = Centre(players, function(p) return p:GetPos() end) or g.mid
        local at = mc and (pc + (mc - pc) * 0.5) or pc
        g.land = Vector(math.Clamp(at.x, g.x0 + 40, g.x1 - 40), math.Clamp(at.y, g.y0 + 40, g.y1 - 40), g.top)
        g.landYaw = mc and math.deg(math.atan2(mc.y - g.land.y, mc.x - g.land.x)) or 0
        g.sky = Vector(g.land.x, g.land.y, g.skyZ)
        if IsValid(g.star) then
            if g.star.SetNoDraw then g.star:SetNoDraw(false) end
            StarAt(g.star, g.sky, g.landYaw, 1.5, true)
        else
            Figure(g, g.sky, g.landYaw, 1.6)
        end
        for _, p in ipairs(players) do Notice(p, "info", "Everything stops", "The dead freeze where they stand. A light breaks through the clouds.", 5) end
    end
    LC.SaviourRescue = Rescue

    function def.tick(g, dt, players)
        local now = CurTime()
        local t = now - g.t0
        if g.phase == "calm" and t >= T.horde then g.phase, g.dirty = "horde", true end
        -- the dead: in from the edges after the nearest dreamer, and they hurt
        if g.phase == "horde" then
            if now >= (g.spawnAt or 0) and Alive(g) < 16 then
                NewMonster(g)
                g.spawnAt = now + 1.6
            end
            for _, m in ipairs(g.mons) do
                if m.alive and IsValid(m.e) then
                    local best, bd
                    for _, p in ipairs(players) do
                        local d = p:GetPos():Distance(m.e:GetPos())
                        if not bd or d < bd then best, bd = p, d end
                    end
                    if best then
                        local left = Toward(m.e, best:GetPos(), m.speed, dt, g.top)
                        if left < 45 and math.abs(best:GetPos().z - g.top) < 90 and now >= (m.next or 0) and now >= (g.pl[best].safe or 0) then
                            m.next = now + 1.2
                            best:SetHealth(math.max(1, best:Health() - m.dmg)) -- (in the dream; it's all put back on waking)
                            Snd(best, CLAWS[math.random(#CLAWS)], 75)
                            if best.ScreenFade then best:ScreenFade(SCREENFADE and SCREENFADE.IN or 1, Color(160, 0, 0, 160), 0.4, 0.05) end
                            g.dirty = true
                        end
                    end
                end
            end
            local low = false
            for _, p in ipairs(players) do if p:Health() <= T.low then low = true end end
            if low or t >= T.latest then Rescue(g, players, now) end
        end
        if g.phase == "descend" then
            local f = math.Clamp((now - g.rescueAt) / T.land, 0, 1)
            local z = g.sky.z + (g.land.z - g.sky.z) * (1 - (1 - f) * (1 - f)) -- (slowing as she comes down)
            SetHer(g, Vector(g.land.x, g.land.y, z))
            if f >= 1 then
                g.phase, g.dirty = "stop", true
                SetHer(g, g.land, g.landYaw)
                if IsValid(g.star) and g.star.SetMoveType then g.star:SetMoveType(MOVETYPE_WALK) end
                Say(g, "saviour_stop")
            end
        end
        if g.phase == "stop" and now >= g.rescueAt + T.soldiers then
            g.phase, g.dirty = "soldiers", true
            Say(g, "saviour_soldiers")
            local song = LC.PropagandaSong({ "saviour" })
            if song then
                local list = Everyone(g)
                if #list > 0 then net.Start("lc_dreamgame") net.WriteTable({ k = "music", song = song }) net.Send(list) end
            end
            -- they swarm in from behind her
            local back = math.rad(g.landYaw + 180)
            for i = 1, 8 do
                local side = (i - 4.5) * 50
                local pos = Vector(g.land.x + math.cos(back) * 260 - math.sin(back) * side, g.land.y + math.sin(back) * 260 + math.cos(back) * side, g.top)
                pos.x, pos.y = math.Clamp(pos.x, g.x0, g.x1), math.Clamp(pos.y, g.y0, g.y1)
                local e = Actor(g, SOLDIER, pos, g.landYaw, 1, ACT_RUN or 1)
                if e then g.soldiers[#g.soldiers + 1] = { e = e, next = now + 0.5 + i * 0.1 } end
            end
            if IsValid(g.star) then Snd(g.star, "npc/combine_soldier/vo/affirmative.wav", 90) end
        end
        -- her soldiers: to the nearest of the dead, and shoot. Only ever the dead: never a dreamer,
        -- rebel or not (the owner: "any resistance or anti citizens in the dream should NOT be attacked")
        if g.phase == "soldiers" then
            for _, s in ipairs(g.soldiers) do
                if IsValid(s.e) then
                    local best, bd
                    for _, m in ipairs(g.mons) do
                        if m.alive and IsValid(m.e) then
                            local d = s.e:GetPos():Distance(m.e:GetPos())
                            if not bd or d < bd then best, bd = m, d end
                        end
                    end
                    if best then
                        if bd > 280 then Toward(s.e, best.e:GetPos(), 220, dt, g.top)
                        elseif now >= s.next then
                            s.e:SetAngles(Angle(0, math.deg(math.atan2(best.e:GetPos().y - s.e:GetPos().y, best.e:GetPos().x - s.e:GetPos().x)), 0))
                            Kill(g, best, s.e)
                            s.next = now + math.Rand(0.5, 0.9)
                            g.dirty = true
                        end
                    end
                end
            end
            if Alive(g) == 0 then
                g.phase, g.dirty, g.safeAt = "safe", true, now + 3
                for _, s in ipairs(g.soldiers) do if IsValid(s.e) and K.Animate then K.Animate(s.e, ACT_IDLE or 1) end end
                Say(g, "saviour_safe")
            end
        end
        if g.phase == "safe" and g.safeAt and now >= g.safeAt then
            g.safeAt = nil
            for _, p in ipairs(players) do Done(g, p, "won", "Saved", "Her soldiers stand over the last of the dead. She looks down at you, and you have never felt so safe.") end
        end
    end

    local BIG = { calm = "The city is quiet. Too quiet.", horde = "Run! You have nothing to fight with.", descend = "Everything stops. A light from above...",
        stop = "She has come.", soldiers = "Her soldiers are here!", safe = "Saved." }
    local STAR_BIG = { calm = "Watch over them.", horde = "They suffer without you. When one is close to the end, you'll go to them.",
        descend = "Descend.", stop = "They are yours to save.", soldiers = "Your soldiers obey.", safe = "They are safe, because of you." }
    function def.state(g, p)
        local glow = (PHASE_ORDER[g.phase] or 0) >= PHASE_ORDER.descend or nil
        if p == g.star then local t = StarState(g, STAR_BIG[g.phase]) t.light = glow return t end
        return { big = BIG[g.phase], tone = (g.phase == "horde" or g.phase == "calm") and "warn" or "love", light = glow, herEnt = HerEnt(g),
            meterName = g.phase ~= "calm" and string.format("The dead: %d", Alive(g)) or nil }
    end
end

------------------------------------------------------------------------
-- The Loyalty Quiz
------------------------------------------------------------------------

do
    LC.QuizQuestions = {
        { q = "Who keeps you safe at night?", a = { "administrator", "combine", "overwatch", "civil protection", "metrocops", "police", "her", "you", "she", "breen", "union", "cp", "officers", "soldiers" } },
        { q = "What do we do when an officer speaks to us?", a = { "obey", "comply", "listen", "kneel", "salute", "respect", "surrender", "submit", "bow", "attention" } },
        { q = "Where does your ration come from?", a = { "administrator", "combine", "union", "her", "you", "generosity", "kindness", "breen", "city", "benevolence", "grace" } },
        { q = "What are the people who call themselves the Resistance?", swearOk = true, a = { "criminals", "terrorists", "anticitizens", "anti citizens", "traitors", "malcontents", "vermin", "thugs", "liars", "scum", "parasites", "enemies", "cowards", "savages" } },
        { q = "Complete the phrase: Compliance is...", a = { "safety", "happiness", "freedom", "love", "life", "peace", "rewarded", "good", "safe", "happy", "duty", "strength", "virtue" } },
        { q = "How would you describe the Administrator?", a = {} }, -- (any word she likes: LC.AdmireWords)
        { q = "What should you do if you see a rebel?", swearOk = true, a = { "report", "inform", "tell", "call", "alert", "rat", "snitch", "warn", "notify", "denounce" } },
        { q = "Who is your best friend?", a = { "administrator", "combine", "overwatch", "civil protection", "her", "you", "the city", "breen", "union", "cp" } },
        { q = "What happens to those who disobey?", a = { "punished", "relocated", "reeducated", "re educated", "processed", "corrected", "amputated", "detained", "arrested", "executed", "removed", "disappear", "jailed", "imprisoned" } },
        { q = "What is the most important thing a citizen can be?", a = { "loyal", "obedient", "compliant", "productive", "grateful", "useful", "quiet", "happy", "faithful", "devoted", "silent", "good" } },
    }
    for i, q in ipairs(LC.QuizQuestions) do LC.PropagandaCues["quiz_q" .. i] = q.q end
    LC.QuizThoughtcrime = { "freeman", "gordon", "lambda", "revolution", "uprising", "overthrow", "alyx", "vance", "kleiner", "rebellion" }
    -- Swears, curses and rude words are thoughtcrime in her studio too (the owner, 8 November: "make
    -- sure to add swears, insults, curses, rude words, etc to the thoughtcrime list"), in leet and
    -- misspelt ("don't forget leet spelling of swears, and typos of swears"), but allowed when aimed at
    -- the Resistance ("what if a player says FUCKING TRAITORS! or FUCK FREEMAN!": allowed). See
    -- LC.QuizForbidden.
    LC.QuizSwears = { "fuck", "fucker", "fuckers", "motherfucker", "fck", "fuk", "fuq", "fcuk", "phuck", "fook", "feck", "wtf", "stfu", "gtfo", "omfg", "fml", "mofo",
        "shit", "shiet", "sheit", "shyt", "sht", "shat", "shitty", "bullshit", "crap", "damn", "dammit", "goddamn", "goddammit",
        "hell", "ass", "arse", "azz", "asshole", "arsehole", "azzhole", "bastard", "bitch", "bitchy", "biatch", "biotch", "bich", "btch", "beyotch",
        "bollocks", "bugger", "cunt", "kunt", "cvnt", "dick", "dik", "dickhead", "cock", "cok", "piss", "pissed", "prick", "twat", "twt",
        "wanker", "wnker", "tosser", "bloody", "sod", "git", "slag", "douche", "douchebag", "jackass", "dumbass", "moron", "idiot", "stupid", "dumb", "loser", "scumbag",
        "screw", "sucks", "whore", "slut", "skank", "turd", "jerk", "ugly", "hag", "witch", "pathetic", "worthless", "clown", "boring", "useless" }
    -- Who's on her side: swearing at any of these is never aimed at the Resistance.
    LC.QuizFriendWords = { "administrator", "combine", "breen", "overwatch", "cp", "metrocop", "metrocops", "police", "civil", "protection", "union", "officer", "officers" }
    -- The Resistance, by name or by insult (and the right answers about them, added below).
    LC.QuizEnemyWords = { "rebel", "rebels", "resistance", "freeman", "alyx", "vance", "kleiner", "lambda", "vortigaunt", "vorts" }
    for _, w in ipairs(LC.QuizQuestions[4].a) do LC.QuizEnemyWords[#LC.QuizEnemyWords + 1] = w end
    -- Forgiving answers (the owner, 8 November: "What if someone uses a synonym or makes a slight
    -- typo?"): a word's common endings count (terrorist, terrorists; report, reported, reporting),
    -- and in longer words one letter wrong, missing, extra or swapped with the next still counts.
    local function Stem(w)
        if #w < 5 then return w end
        if string.sub(w, -3) == "ies" then return string.sub(w, 1, -4) .. "y" end
        for _, suf in ipairs({ "ing", "ed", "es", "s" }) do
            if string.sub(w, -#suf) == suf and #w - #suf >= 4 and not (suf == "s" and string.sub(w, -2) == "ss") then
                w = string.sub(w, 1, -#suf - 1)
                break
            end
        end
        if #w >= 5 and string.sub(w, -1) == "e" then w = string.sub(w, 1, -2) end
        return w
    end
    -- Letters to change to turn a into b (a swap of two neighbours is one), stopping above 1.
    local function Edits(a, b)
        if a == b then return 0 end
        if math.abs(#a - #b) > 1 then return 2 end
        local d, prev2, prev = {}, nil, {}
        for j = 0, #b do prev[j] = j end
        for i = 1, #a do
            d = { [0] = i }
            local best = i
            for j = 1, #b do
                local cost = string.byte(a, i) == string.byte(b, j) and 0 or 1
                local v = math.min(prev[j] + 1, d[j - 1] + 1, prev[j - 1] + cost)
                if prev2 and i > 1 and j > 1 and string.byte(a, i) == string.byte(b, j - 1) and string.byte(a, i - 1) == string.byte(b, j) then
                    v = math.min(v, prev2[j - 2] + 1)
                end
                d[j] = v
                if v < best then best = v end
            end
            if best > 1 then return 2 end
            prev2, prev = prev, d
        end
        return prev[#b]
    end
    -- Does the word said (w) count as the word wanted (a)? typo: how long a word must be to forgive a typo.
    function LC.QuizWordMatch(w, a, typo)
        if w == a then return true end
        local sw, sa = Stem(w), Stem(a)
        if sw == sa then return true end
        typo = typo or 5
        return #a >= typo and #w >= typo - 1 and (Edits(w, a) <= 1 or Edits(sw, sa) <= 1)
    end
    -- Is the answer (one word or a few, like "civil protection") somewhere in what was said?
    function LC.QuizHas(words, answer, typo)
        local want = {}
        for w in string.gmatch(answer, "%a+") do want[#want + 1] = w end
        if #want == 0 then return false end
        for i = 1, #words - #want + 1 do
            local all = true
            for k = 1, #want do if not LC.QuizWordMatch(words[i + k - 1], want[k], typo) then all = false break end end
            if all then return true end
        end
        return false
    end
    -- Leet (sh1t, a$$, b!tch) and stretched letters (fuuuck), for the swears.
    local LEET = { ["0"] = "o", ["1"] = "i", ["3"] = "e", ["4"] = "a", ["5"] = "s", ["7"] = "t", ["8"] = "b", ["@"] = "a", ["$"] = "s", ["!"] = "i", ["|"] = "i", ["+"] = "t" }
    local function Tokens(text)
        local out, alt = {}, {}
        for raw in string.gmatch(string.lower(text or ""), "[%w@%$!%*|%+]+") do
            raw = string.gsub(string.gsub(raw, "^[!%*]+", ""), "[!%*]+$", "")
            local t = string.gsub(raw, "[0134578@%$!|%+]", LEET)
            if string.find(t, "%a") then
                out[#out + 1] = t
                alt[#out] = string.find(raw, "1", 1, true) and string.gsub(string.gsub(raw, "1", "l"), "[034578@%$!|%+]", LEET) or false
            end
        end
        return out, alt
    end
    LC.QuizTokens = Tokens
    -- Runs of a letter cut down to n (1 or 2): fuuuck, fuck; assss, ass.
    local function Squeeze(w, n)
        local out, last, run = {}, nil, 0
        for i = 1, #w do
            local c = string.sub(w, i, i)
            if c == last then run = run + 1 else last, run = c, 1 end
            if run <= n then out[#out + 1] = c end
        end
        return table.concat(out)
    end
    -- The two that people spell every way (fook, fukc, fuq; shiet, sheit, shyt), with their endings,
    -- and inside other words (motherfucker, bullshit). Never sheet, shot, shut, focus or fake.
    local SUFFIX = { "", "s", "es", "ed", "er", "ers", "in", "ing", "y", "ty", "e", "head", "hole", "face", "wit", "off", "tard" }
    local BASES = { "^f[uovy]*[ckq]+$", "^ph[uoa]*[ckq]+$", "^sh[iey]*[iy][iey]*t+$" }
    local INSIDE = { "fuck", "fukc", "fcuk", "phuck", "fvck", "motherf", "shit" }
    local NOT_SWEARS = {} -- (words that look like a swear but aren't; "shiite" counts as one, the owner says)
    local function Family(w)
        if NOT_SWEARS[w] then return false end
        for _, suf in ipairs(SUFFIX) do
            if #w > #suf and string.sub(w, -#suf) == suf or suf == "" then
                local base = suf == "" and w or string.sub(w, 1, -#suf - 1)
                for _, p in ipairs(BASES) do if string.match(base, p) then return true end end
            end
        end
        for _, f in ipairs(INSIDE) do if string.find(w, f, 1, true) then return true end end
        return string.match(w, "sh[iey]*[iy][iey]*t+e?s?$") ~= nil
    end
    local function SwearOne(t)
        if not t or t == "" or NOT_SWEARS[t] then return false end
        if string.find(t, "*", 1, true) then -- f*ck, sh*t: a star for any letter
            if #string.gsub(t, "%*", "") < 2 then return false end
            local pat = "^" .. string.gsub(t, "%*", "%%a") .. "$"
            for _, w in ipairs(LC.QuizSwears) do if #w == #t and string.match(w, pat) then return true end end
            return false
        end
        local s1, s2 = Squeeze(t, 1), Squeeze(t, 2)
        for _, w in ipairs(LC.QuizSwears) do
            if LC.QuizWordMatch(t, w, 99) or LC.QuizWordMatch(s2, w, 99) then return true end
            local q = Squeeze(w, 1)
            if #q >= 4 and (s1 == q or Stem(s1) == q) then return true end
        end
        if Family(t) or Family(s1) then return true end
        for _, w in ipairs(LC.CombineInsults) do if LC.QuizWordMatch(t, w, 6) then return true end end
        return false
    end
    local function In(t, list, typo)
        if not t then return false end
        local s1 = Squeeze(t, 1)
        for _, w in ipairs(list) do if LC.QuizWordMatch(t, w, typo) or LC.QuizWordMatch(s1, Squeeze(w, 1), typo) then return true end end
        return false
    end
    LC.QuizIsSwear = SwearOne
    local CURSE_BEFORE = { "hate", "death", "down", "kill", "curse", "burn" } -- (and any swear: fuck Freeman, death to Alyx)
    local CURSE_AFTER = { "sucks", "die", "dies", "dead" } -- (and any insult of theirs: Freeman is a traitor)
    -- A Resistance name cursed where it's said: a swear or a curse in the two words before it, or
    -- one of their insults or a curse in the four after ("Freeman is a fucking hero" isn't).
    local function Cursed(toks, i)
        for k = math.max(1, i - 2), i - 1 do if SwearOne(toks[k]) or In(toks[k], CURSE_BEFORE, 99) then return true end end
        for k = i + 1, math.min(#toks, i + 4) do if In(toks[k], CURSE_AFTER, 99) or In(toks[k], LC.QuizQuestions[4].a) then return true end end
        return false
    end
    -- A thoughtcrime word in what was said (the text), or nil. q: the question being asked.
    -- A Resistance name is thoughtcrime unless it's cursed (typos forgiven only from 6 letters, so
    -- "dance" isn't "vance"). A swear, curse or insult is thoughtcrime unless it's aimed at the
    -- Resistance: the message names them (cursed) or insults them (traitors, scum), or the question
    -- is about them and the message doesn't name her side.
    function LC.QuizForbidden(text, q)
        local toks, alt = Tokens(text)
        local enemy, friend = false, false
        for i, t in ipairs(toks) do
            if In(t, LC.QuizThoughtcrime, 6) then
                if not Cursed(toks, i) then return t end
                enemy = true
            end
            if In(t, LC.QuizEnemyWords, 6) then enemy = true end
            if In(t, LC.QuizFriendWords, 99) then friend = true end
        end
        if enemy or (q and q.swearOk and not friend) then return nil end
        for i, t in ipairs(toks) do if SwearOne(t) or SwearOne(alt[i]) then return t end end
        return nil
    end
    local QSECS = 14
    local def = { id = "quiz", name = "The Loyalty Quiz", mood = "happy", secs = 6 + #LC.QuizQuestions * QSECS + 6, lives = 3, need = 6, music = { "quiz" },
        goal = "Answer her questions in chat. A right answer earns Loyalty, the first to answer earns double. Careful: some answers are thoughtcrime.",
        starGoal = "You're the star: the quizmaster on the podium. The questions ask themselves; anything you say in chat, the dream hears.",
        timeUp = { "The broadcast ends", "The studio lights go out, and you wake." }, spawn = Spawn, starring = PedestalStar, starGone = PedestalGone,
        woke = Woke({
            won = { "Model citizen", "You wake reciting the answers, and feel proud of yourself. You're not sure why." },
            out = { "Thoughtcrime", "You wake with a start, sure you said something wrong in your sleep. Hopefully nobody heard." },
            time = { "The broadcast ends", "You wake humming the quiz's theme tune. It's very catchy." },
        }) }
    def.hello = Hello("propaganda", "quiz_hello")
    G.quiz = def
    LC.QuizSecs = QSECS

    -- Stand-ins (the owner, 8 November: "if there are less than 4 human players dreaming then please
    -- add citizen NPCs that answer with varying correct answers in the chat (we can use named NPCs
    -- right?). Maybe even a rebel NPC that answers incorrectly and is severely punished for dramatic
    -- effect by metrocops beating him"). The city's own named citizens (LC.People) fill the studio up
    -- to four contestants; they answer late in each question and never take the first-answer bonus.
    -- The rebel has a name of his own, never one of the city's people (some of them really are
    -- sympathizers, and the dream mustn't give them away).
    LC.QuizContestants = 4 -- (the dreams' minimum, lc_dream_min, when that's set: LC.DreamMin, sv_livingcity_dreamstandins.lua)
    LC.QuizNPCAnswers = {
        { "The Administrator!", "Civil Protection, of course.", "Overwatch keeps watch while we sleep.", "The Combine. Always the Combine.", "She does. The Administrator.", "The brave officers of Civil Protection!" },
        { "We obey!", "We comply, at once.", "Listen, and obey.", "We salute, and do as we're told.", "We show respect, and comply.", "We kneel, if we're asked to." },
        { "From the Administrator's generosity!", "From the Combine.", "The Union provides!", "From her kindness.", "From the Combine, in its generosity." },
        { "Terrorists!", "Criminals, every one of them.", "Anti-citizens!", "Traitors and liars.", "Malcontents. Vermin.", "Thugs!" },
        { "Safety!", "Happiness!", "Freedom!", "Compliance is peace.", "Compliance is rewarded!", "Love!" },
        { "She is %s!", "Simply %s.", "%s. Utterly %s.", "So very %s." }, -- (a word from LC.AdmireWords)
        { "Report them at once!", "Inform Civil Protection!", "Call an officer!", "Tell the nearest officer.", "Alert the Combine!" },
        { "The Administrator!", "The Combine is my best friend.", "Civil Protection!", "Her. Always her.", "The city!" },
        { "They are punished.", "Relocated!", "Re-educated, for their own good.", "Detained.", "Corrected!", "Arrested, and rightly so." },
        { "Loyal!", "Obedient!", "Productive!", "Grateful.", "Compliant!", "Quiet." },
    }
    LC.QuizRebelLines = { "The Resistance are heroes! Freeman lives!", "Compliance is slavery! Long live the revolution!", "Lambda! Lambda forever!", "Down with the Combine! Alyx Vance will set us free!" }
    LC.QuizBeatSecs, LC.QuizDragSecs = 4, 3
    local BOT_MODELS = { "models/humans/group01/male_02.mdl", "models/humans/group01/female_01.mdl", "models/humans/group01/male_07.mdl", "models/humans/group01/female_04.mdl" }
    -- An answer a stand-in gives to question i.
    function LC.QuizNPCAnswer(i)
        local list = LC.QuizNPCAnswers[i] or { "The Administrator!" }
        local line = list[math.random(#list)]
        if string.find(line, "%s", 1, true) then
            local w = LC.AdmireWords[math.random(#LC.AdmireWords)]
            line = string.format(line, w, w)
            line = string.upper(string.sub(line, 1, 1)) .. string.sub(line, 2)
        end
        return line
    end
    local function Chat(g, name, text)
        for _, q in ipairs(Everyone(g)) do if q.ChatPrint then q:ChatPrint("(in the dream) " .. name .. ": " .. text) end end
    end
    local function Dreamers(g) local n = 0 for _ in pairs(g.pl) do n = n + 1 end return n end
    -- Named citizens of the city (alive, not on the streets), or made-up names.
    local function People(n)
        local out, pool = {}, {}
        for _, pp in ipairs(LC.People and LC.People.list or {}) do
            if pp.alive and pp.role ~= "cop" and pp.name and not IsValid(pp.npc) then pool[#pool + 1] = pp end
        end
        for i = 1, n do
            if #pool > 0 then
                local pp = table.remove(pool, math.random(#pool))
                out[i] = { name = pp.name, model = pp.model }
            else
                local male = math.random() < 0.5
                out[i] = { name = LC.NewCharacterName and (LC.NewCharacterName(male and "male" or "female")) or ("Citizen " .. math.random(100, 999)), model = BOT_MODELS[i % #BOT_MODELS + 1] }
            end
        end
        return out
    end
    local function Cops()
        local names = {}
        for _, pp in ipairs(LC.People and LC.People.list or {}) do if pp.alive and pp.role == "cop" and pp.name then names[#names + 1] = pp.name end end
        local a = #names > 0 and table.remove(names, math.random(#names)) or ("Unit " .. math.random(10, 99))
        local b = #names > 0 and table.remove(names, math.random(#names)) or ("Unit " .. math.random(10, 99))
        return a, b
    end
    -- The stand-ins and the rebel, in a row before her, once the dreamers are known.
    local function Seat(g)
        g.bots, g.seated = {}, true
        local want = math.max(0, (LC.DreamMin and LC.DreamMin() or LC.QuizContestants) - Dreamers(g))
        if want == 0 then return end
        local spots = {}
        for i = 1, want + 1 do spots[i] = (i - (want + 2) / 2) * 120 end -- (a row, 120 apart, centred)
        local who = People(want)
        local rebelAt = math.random(want + 1)
        local k = 0
        for i = 1, want + 1 do
            local y = g.botY + spots[i]
            local yaw = math.deg(math.atan2(g.herY - y, g.herX - g.botX))
            if i == rebelAt then
                local male = math.random() < 0.7
                local name = LC.NewCharacterName and (LC.NewCharacterName(male and "male" or "female")) or "Citizen 451"
                g.rebel = { name = name, male = male, pos = Vector(g.botX, y, g.botTop), yaw = yaw, q = math.random(3, #LC.QuizQuestions - 2) }
                g.rebel.ent = Actor(g, male and "models/humans/group03/male_07.mdl" or "models/humans/group03/female_02.mdl", g.rebel.pos, yaw, 1, ACT_IDLE or 1)
            else
                k = k + 1
                local b = who[k]
                b.ent = Actor(g, b.model or BOT_MODELS[1], Vector(g.botX, y, g.botTop), yaw, 1, ACT_IDLE or 1)
                g.bots[#g.bots + 1] = b
            end
        end
    end
    LC.QuizSeat = Seat
    -- A new question: when each stand-in will answer (late, so the dreamers get there first).
    local function Plan(g, now)
        for _, b in ipairs(g.bots or {}) do b.at, b.said = now + math.Rand(5, QSECS - 2), nil end
        local r = g.rebel
        if r and not r.state and r.q == g.qi then r.at = now + math.Rand(4, 7) end
    end
    -- The rebel's moment: he shouts, she has him removed, two officers beat him and drag him off.
    local function Rebel(g, now)
        local r = g.rebel
        if not r then return end
        if not r.state and r.at and now >= r.at then
            r.state, r.next = "shout", now + 1.5
            Chat(g, r.name, LC.QuizRebelLines[math.random(#LC.QuizRebelLines)])
            for _, p in ipairs(Everyone(g)) do Notice(p, "warn", "Thoughtcrime!", "The audience gasps. Every head in the studio turns to " .. r.name .. ".", 5) end
            Pose(r.ent, { "cheer1", "cheer2" }, ACT_CHEER)
        elseif r.state == "shout" and now >= r.next then
            Say(g, "quiz_rebel")
            r.state, r.next, r.hits = "beat", now + 1, 0
            local function Cop(dy)
                local pos = r.pos + Vector(0, dy, 0)
                local e = Actor(g, "models/police.mdl", pos, dy > 0 and -90 or 90, 1, ACT_IDLE or 1)
                if IsValid(e) and K.ValidModel and K.ValidModel("models/weapons/w_stunbaton.mdl") then
                    local w = ents.Create("prop_dynamic")
                    if IsValid(w) then
                        w:SetModel("models/weapons/w_stunbaton.mdl")
                        w:SetPos(pos)
                        w:Spawn()
                        if w.SetParent then w:SetParent(e) end
                        if w.AddEffects and EF_BONEMERGE then w:AddEffects(EF_BONEMERGE) end
                        w.lcDreamGame = true
                        g.ents[#g.ents + 1] = w
                    end
                end
                return e
            end
            r.cops = { Cop(45), Cop(-45) }
            r.copNames = { Cops() }
            Snd(r.cops[1], "npc/metropolice/vo/prepareforjudgement.wav", 85)
            Chat(g, r.copNames[1], "Anticitizen. Prepare for judgement.")
        elseif r.state == "beat" and now >= r.next then
            r.hits = r.hits + 1
            r.next = now + 0.6
            local cop = r.cops[r.hits % 2 + 1]
            Pose(cop, { "swing", "thrust" }, ACT_MELEE_ATTACK_SWING)
            Snd(r.ent, r.hits % 2 == 0 and "weapons/stunstick/stunstick_fleshhit1.wav" or "weapons/stunstick/stunstick_impact1.wav", 80)
            if r.hits % 2 == 1 then Snd(r.ent, string.format(r.male and "vo/npc/male01/pain0%d.wav" or "vo/npc/female01/pain0%d.wav", math.random(1, 9)), 80) end
            Pose(r.ent, { "Fear_Reaction", "cower", "crouchidle" }, ACT_COWER)
            if r.hits * 0.6 >= LC.QuizBeatSecs then
                r.state, r.next, r.from = "drag", now + LC.QuizDragSecs, now
                Pose(r.ent, { "crouchidle", "Lying_Down" }, ACT_CROUCHIDLE)
                Chat(g, r.copNames[2], "Moving the suspect. Nothing to see here, citizens.")
                for _, p in ipairs(Everyone(g)) do Notice(p, "info", "In the dream", "Two officers drag " .. r.name .. " away by the arms. Nobody looks.", 5) end
            end
        elseif r.state == "drag" then
            local f = math.min(1, (now - r.from) / LC.QuizDragSecs)
            local back = Vector(-260 * f, 0, 0) -- (towards the back of the studio)
            if IsValid(r.ent) then r.ent:SetPos(r.pos + back) end
            for i, c in ipairs(r.cops or {}) do if IsValid(c) then c:SetPos(r.pos + back + Vector(-10, i == 1 and 45 or -45, 0)) end end
            if now >= r.next then
                r.state = "gone"
                for _, e in ipairs({ r.ent, r.cops and r.cops[1], r.cops and r.cops[2] }) do if IsValid(e) and e.SetNoDraw then e:SetNoDraw(true) end end
                Say(g, "quiz_resume")
            end
        end
    end
    local function Bots(g, now)
        if not g.seated then Seat(g) end
        if g.q then
            for _, b in ipairs(g.bots) do
                if b.at and not b.said and now >= b.at then
                    b.said = true
                    Chat(g, b.name, LC.QuizNPCAnswer(g.qi))
                    Pose(b.ent, { "cheer1", "cheer2" }, ACT_CHEER)
                end
            end
        end
        Rebel(g, now)
    end

    function def.build(g, dream)
        local x0, x1, top = Hall(g, dream, 2, NAVY)
        local c = dream.pos
        Her(g, x1 - 110, c.y, top, 180)
        -- red banners behind her
        for _, dy in ipairs({ -260, 260 }) do
            if not Block(g, "models/hunter/plates/plate2x4.mdl", Vector(x1 - 20, c.y + dy, top + 95), Angle(0, 90, 90), Color(190, 20, 30), "models/debug/debugwhite") then break end
        end
        Admirers(g, x0 + 200, x1 - 260, c.y - PLATE8_S + 40, c.y + PLATE8_S - 40, top, x1 - 110, c.y)
        g.qi, g.qNext = 0, CurTime() + 6
        Starts(g, x0 + 90, c.y, top)
        g.botX, g.botY, g.botTop, g.herX, g.herY = x0 + 260, c.y, top, x1 - 110, c.y -- (the stand-ins' row, facing her)
        return true
    end

    function def.tick(g, dt, players)
        local now = CurTime()
        Follow(g)
        Crowd(g, LC.QuizBanners)
        Bots(g, now)
        if now >= g.qNext then
            g.qi = g.qi + 1
            local q = LC.QuizQuestions[g.qi]
            if not q then
                g.q, g.qNext = nil, math.huge
                Say(g, "quiz_end")
                for _, p in ipairs(players) do
                    if (g.pl[p].score or 0) >= def.need then Done(g, p, "won", "Model citizen", "Full marks for loyalty. The audience rises to its feet.")
                    else Done(g, p, "time", "The broadcast ends", "The studio lights go out before you've proven yourself. You wake.") end
                end
                return
            end
            g.q, g.qFirst, g.qDone, g.qNext, g.dirty = q, nil, {}, now + QSECS, true
            Say(g, "quiz_q" .. g.qi)
            Plan(g, now)
        end
    end

    -- An answer, in chat. True: it stayed in the dream.
    function LC.QuizSaid(g, p, text)
        local s = g.pl[p]
        if not s or s.done then return false end
        s.score = s.score or 0
        for _, q in ipairs(Everyone(g)) do if q.ChatPrint then q:ChatPrint("(in the dream) " .. p:Nick() .. ": " .. text) end end
        local words = {}
        for w in string.gmatch(string.lower(text), "%a+") do words[#words + 1] = w end
        local bad = LC.QuizForbidden(text, g.q)
        if bad then
            Offend(g, p, "Thoughtcrime", "\"" .. bad .. "\"? The audience gasps. Two officers escort you to the back of the studio.")
            return true
        end
        if not g.q or g.qDone[p] then return true end
        local right = false
        for _, a in ipairs(#g.q.a == 0 and LC.AdmireWords or g.q.a) do
            if LC.QuizHas(words, a) then right = true break end
        end
        if not right then
            Notice(p, "info", "Not quite", "Think about it, citizen. The answer is always obvious.", 3)
            return true
        end
        g.qDone[p] = true
        local first = g.qFirst == nil
        if first then g.qFirst = p end
        s.score = s.score + (first and 2 or 1)
        g.dirty = true
        if s.score >= def.need then
            Done(g, p, "won", "Model citizen", "Full marks for loyalty. She nods once, and the audience rises to its feet for you.")
        else
            Notice(p, "info", first and "First, and correct!" or "Correct", string.format("Loyalty: %d of %d.", s.score, def.need), 3)
        end
        return true
    end
    def.say = LC.QuizSaid

    function def.state(g, p)
        local q = g.q and g.q.q or (g.qi == 0 and "The quiz is about to begin..." or nil)
        if p == g.star then return StarState(g, q or "The quiz is over.") end
        local s = p and g.pl[p] or {}
        local big = q
        if q and g.qDone and g.qDone[p] then big = "Correct. Wait for the next question." end
        return { big = big, tone = "love", herEnt = HerEnt(g), meter = math.floor(math.min(1, (s.score or 0) / def.need) * 100),
            meterName = string.format("Loyalty: %d of %d     Question %d of %d", s.score or 0, def.need, math.max(1, g.qi), #LC.QuizQuestions) }
    end
end

------------------------------------------------------------------------
-- Chat in a propaganda dream
------------------------------------------------------------------------

-- Said in chat: did it stay in the dream? The star's words go to the dreamers' screens; in the
-- mirror and the quiz, the dreamers' words are scored there. (Called first by the in-character
-- chat, sv_livingcity_rp.lua, like the radio, and by its own hook too.)
function LC.PropagandaSay(p, text)
    local dream = LC.DreamActive
    local g = dream and dream.game
    text = string.Trim(text or "")
    if text == "" or not g or g.stopped or not LC.PropagandaDreams[g.id] or p.lcDreaming ~= dream.id then return false end
    local c = string.sub(text, 1, 1)
    if c == "/" or c == "!" or c == "@" then return false end -- (commands and tickets to staff still work)
    if p == g.star then
        Line(g, text, nil, "The Administrator")
        for _, q in ipairs(Everyone(g)) do if q.ChatPrint then q:ChatPrint("(in the dream) The Administrator: " .. text) end end
        return true
    end
    if g.enf and g.enf[p] then -- (an Enforcer: heard in the dream, never scored)
        for _, q in ipairs(Everyone(g)) do if q.ChatPrint then q:ChatPrint("(in the dream) Enforcer " .. p:Nick() .. ": " .. text) end end
        return true
    end
    if g.def.say and g.pl[p] then return g.def.say(g, p, text) end
    return false
end
LC.AdmireSay = LC.PropagandaSay
hook.Add("PlayerSay", "LivingCityPropagandaDreams", function(p, text)
    if LC.PropagandaSay(p, text) then return "" end
end)

-- The stage's pieces, for the propaganda dreams written in another file (sv_livingcity_propagandamore.lua).
LC.PropagandaKit = { Everyone = Everyone, Line = Line, Say = Say, Her = Her, Figure = Figure, HerEnt = HerEnt, PedestalStar = PedestalStar,
    PedestalGone = PedestalGone, Follow = Follow, Admirers = Admirers, Crowd = Crowd, Hello = Hello, Woke = Woke, Hall = Hall, Starts = Starts,
    Spawn = Spawn, Offend = Offend, StarState = StarState, StarAt = StarAt, Pose = Pose, Notice = Notice, ADMIRERS = ADMIRERS,
    GOLD = GOLD, ROSE = ROSE, PLUM = PLUM, NAVY = NAVY }
