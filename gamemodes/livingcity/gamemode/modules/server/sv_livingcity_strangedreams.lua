--[[
    Living City: strange dreams (Happy and Neutral dreams you play)

      The owner, 8 November: "Since we've made dreams more or less mandatory, we need a few more for
      variety. First up: as the citizens say 'sometimes I dream of cheese': we need a CHEESE DREAM!
      ... if it's psychedelic all the better, the dream has to start with the male and female voice
      lines echoing their cheese lines before the dream starts. Go ahead and draft a few others
      please and just make them, I will playtest them."

      Four dreams you play, built at the dream point out of plain props like the others
      (sv_livingcity_dreamgames.lua), on her tablet under their mood. Everything about dreaming is
      as it always was: everything put back on waking, nothing you do counts, and nobody wakes
      themselves until they're out of it.

        The Cheese Dream (cheese, Neutral): the screen goes dark and a man's voice, then a woman's,
          echo "Sometimes I dream about cheese" (Half-Life 2's own citizens) until the dream
          swims up out of the dark: a plain of cheese under a sky that won't keep one colour,
          giant citizens' heads floating overhead and humming the line, the music wobbling. Gather
          the glowing cheese (golden cheese counts three and turns the world inside out for a few
          seconds) while great wheels of cheese roll across the plain. You're light as a crumb
          here: jump onto the floating slabs. Ten pieces wins; a wheel rolling over you costs a life.
        Musical Chairs (chairs, Neutral): a ring of chairs that drift round you while the music
          plays, one too few. When it stops, crouch beside a free chair. No chair: you're out. One
          chair fewer each round; the last one sitting wins (alone: three rounds).
        Wings (flying, Happy): the dream where you can fly. Jump in the air to flap (you're light
          here) and fly through the golden rings among the pigeons. Eight rings wins. Nothing can
          hurt you.
        It's Raining Melons (melons, Happy): watermelons fall out of a clear sky. Stand where a
          green glow marks one's landing to catch it; a red glow is a lead melon, keep out from
          under it (a life). Twelve melons wins.

      Waking: whoever won wakes Unbroken with a second wind, as from any dream you play
      (LC.DreamOutcome); losing one of these costs nothing, it's only a strange dream (like the
      propaganda dreams, no health lost). Music, if the owner puts any in sound/livingcity/dreams/:
      named for the codeword (cheese, chairs, flying, melons); otherwise Half-Life 2's own.
]]

if CLIENT then return end

LC = LC or {}

local K, G = LC.DreamGameKit, LC.DreamGames
if not K or not G then return end
local Block, Actor, Floor, Snd, Puff, Send, Done, Hit, ToStart = K.Block, K.Actor, K.Floor, K.Snd, K.Puff, K.Send, K.Done, K.Hit, K.ToStart
local PLATE8, PLATE8_S, PLATE4, PLATE4_S = K.PLATE8, K.PLATE8_S, K.PLATE4, K.PLATE4_S
Snd = function(e, snd, lvl, pitch) K.Snd(e, snd, lvl, LC.DreamWarpPitch and LC.DreamWarpPitch(pitch or 100) or pitch) end -- (half of them warped: sv_livingcity_strangedreams.lua)

local function Notice(p, kind, title, text, secs)
    if not IsValid(p) then return end
    if LC.Notice then LC.Notice(p, kind, title, text, secs) elseif p.ChatPrint then p:ChatPrint(title .. ": " .. text) end
end

LC.StrangeDreams = { "cheese", "chairs", "flying", "melons" }
for _, id in ipairs(LC.StrangeDreams) do
    local have = false
    for _, o in ipairs(LC.DreamGameOrder) do if o == id then have = true end end
    if not have then LC.DreamGameOrder[#LC.DreamGameOrder + 1] = id end
    -- (their music: flat in sound/livingcity/dreams/, named for the codeword, found the same way as the propaganda dreams')
    if LC.PropagandaSongWords then LC.PropagandaSongWords[#LC.PropagandaSongWords + 1] = id end
end

-- The owner's song for a dream (its codeword), or Half-Life 2's own.
LC.StrangeFallbackSongs = {
    cheese = "music/hl2_song10.mp3",
    chairs = "music/hl2_song26_trainstation1.mp3",
    flying = "music/hl2_song2.mp3",
    melons = "music/hl2_song27_trainstation2.mp3",
}
function LC.StrangeSong(id)
    local own = LC.PropagandaSong and LC.PropagandaSong({ id })
    return own or LC.StrangeFallbackSongs[id]
end

-- A colour round the rainbow (h from 0 to 1).
function LC.StrangeRainbow(h, a)
    h = (h or 0) % 1
    local i = math.floor(h * 6)
    local f = h * 6 - i
    local q = 1 - f
    local rgb = ({ { 1, f, 0 }, { q, 1, 0 }, { 0, 1, f }, { 0, q, 1 }, { f, 0, 1 }, { 1, 0, q } })[i + 1]
    return Color(math.floor(rgb[1] * 255), math.floor(rgb[2] * 255), math.floor(rgb[3] * 255), a or 255)
end
local Rainbow = LC.StrangeRainbow

-- How these dreams leave you: a winner as from any dream you play; otherwise a line, nothing more.
local function Woke(lines)
    return function(p, how)
        if how == "won" and LC.DreamOutcome then
            local l = lines.won
            if l then Notice(p, "info", l[1], l[2], 9) end
            LC.DreamOutcome(p, "won", lines.name)
            return
        end
        local l = lines[how]
        if l then Notice(p, "info", l[1], l[2], 9) end
    end
end

-- A square floor of n by n plates round the dream point, its top at top; plates coloured by col(i, j).
local function Plain(g, dream, maxN, col)
    local half = LC.DreamGameHalf(dream)
    local n = math.Clamp(math.floor(half * 2 / PLATE8_S), 2, maxN or 2)
    local c = dream.pos
    local top = c.z + 2
    local x0, y0 = c.x - n * PLATE8_S / 2, c.y - n * PLATE8_S / 2
    for i = 1, n do for j = 1, n do
        local f = Floor(g, PLATE8, x0 + (i - 0.5) * PLATE8_S, y0 + (j - 0.5) * PLATE8_S, top, col(i, j), "models/debug/debugwhite")
        if IsValid(f) then f.lcKeepLook = true end -- (the floor stays readable)
    end end
    g.top, g.n = top, n
    g.half = n * PLATE8_S / 2
    g.bounds = { mins = Vector(x0 - 60, y0 - 60, top - 160), maxs = Vector(x0 + n * PLATE8_S + 60, y0 + n * PLATE8_S + 60, top + 900) }
    return top
end
-- Somewhere on the floor, at least edge in from its sides.
local function AnyWhere(g, edge)
    local c, h = g.dream.pos, g.half - (edge or 60)
    return Vector(c.x + math.Rand(-h, h), c.y + math.Rand(-h, h), g.top)
end
-- Starting spots: a ring round the middle.
local function Ring(g, r)
    g.starts = {}
    local c = g.dream.pos
    for i = 1, 12 do
        local a = math.rad(i * 30)
        g.starts[i] = Vector(c.x + math.cos(a) * r, c.y + math.sin(a) * r, g.top + 4)
    end
end
local function SpawnAt(g, p, i)
    local at = g.starts[((i - 1) % #g.starts) + 1]
    local c = g.dream.pos
    return at, math.deg(math.atan2(c.y - at.y, c.x - at.x))
end
local function Flat(v, kind) return { math.floor(v.x), math.floor(v.y), math.floor(v.z), kind } end
local function Dist2(a, b) return math.sqrt((a.x - b.x) ^ 2 + (a.y - b.y) ^ 2) end
local function OnGround(p) return p.IsOnGround == nil or p:IsOnGround() == true end
-- Jump just pressed (call every tick for everyone in play).
local function JumpPressed(s, p)
    local down = p.KeyDown ~= nil and IN_JUMP ~= nil and p:KeyDown(IN_JUMP) == true
    local was = s.jumpWas
    s.jumpWas = down
    return down and not was
end
local function Light(p, grav) if IsValid(p) and p.SetGravity then p:SetGravity(grav or 1) end end
local function Leave(g, p)
    Light(p, 1)
    if IsValid(p) and p.SetDSP then p:SetDSP(0, false) end
    if IsValid(p) and p.SetLaggedMovementValue then p:SetLaggedMovementValue(1) end
end

-- Lines said in these dreams: on everyone's screen, in a recording if the owner made one (flat in
-- sound/livingcity/dreams/voice/, named for the line: cheese_gold1.mp3, with a .txt of the same name
-- for its words), else just the words. { speaker, words, how it should sound (for whoever records it) }.
LC.StrangeCues = LC.StrangeCues or {}
function LC.StrangeAddCues(t)
    for k, v in pairs(t) do
        LC.StrangeCues[k] = v
        if LC.PropagandaCues then LC.PropagandaCues[k] = v[2] end
        if LC.PropagandaCueWho then LC.PropagandaCueWho[k] = v[1] end
    end
end
local function SayAs(g, cue)
    if not g or g.stopped then return end
    local snd, text
    if LC.PropagandaVoice then snd, text = LC.PropagandaVoice(cue) end
    local c = LC.StrangeCues[cue]
    text = text or (c and c[2]) or ""
    g.said = g.said or {}
    g.said[#g.said + 1] = cue
    local P = LC.PropagandaKit
    if P and P.Line then P.Line(g, text, snd, c and c[1] or "") end
end
LC.StrangeSay = SayAs
local function SayLater(g, secs, cue) timer.Simple(secs, function() if g and not g.stopped then SayAs(g, cue) end end) end

-- The voices in the dark before a dream begins (the cheese dream, the horse): everyone held still and
-- every sound far away, in a cavern's echo (the owner: "a dreamy distant echo effect"); then the dream,
-- and its music. True while it lasts (the dream's tick waits).
LC.DreamEchoDSP = 25 -- (Source's sound preset "cavern, large": long, distant echoes)
local function IntroTick(g, players)
    local now = CurTime()
    if now < (g.introUntil or 0) then
        for _, p in ipairs(players) do
            if not p.lcEndFrozen then
                p.lcEndFrozen = true
                if p.Freeze then p:Freeze(true) end
                if p.SetDSP then p:SetDSP(LC.DreamEchoDSP, false) end
            end
        end
        return true
    end
    if not g.begun then
        g.begun, g.dirty = true, true
        for _, p in ipairs(players) do
            if p.lcEndFrozen then p.lcEndFrozen = nil if p.Freeze then p:Freeze(false) end end
            local s = g.pl[p]
            if s then s.safe = now + 2 end
        end
        timer.Simple(1.5, function() for _, p in ipairs(players) do if IsValid(p) and p.SetDSP then p:SetDSP(0, false) end end end) -- (the echo dies away)
        Send(g, { k = "music", song = g.song })
        if g.def.begin then g.def.begin(g, players) end
    end
    return false
end
local function IntroHello(theme)
    return function(g)
        local d = g.def
        return { theme = theme, intro = g.introUntil, lines = d.introLines, introText = d.introText, introSecs = d.introSecs }
    end
end
-- Every dream you play can have music: the owner's file named for its codeword (its id), else the
-- strange dreams' Half-Life 2 fallback (sv_livingcity_dreamgames.lua asks this when a dream brings none).
-- (no song of its own and no fallback named for it: one of these, always the same one for that dream)
LC.DreamDefaultSongs = { "music/hl2_song19.mp3", "music/hl2_song26.mp3", "music/hl2_song30.mp3", "music/hl2_song33.mp3", "music/hl2_song16.mp3" }
function LC.DreamDefaultSong(id)
    local list = LC.DreamDefaultSongs
    if not id or #list == 0 then return nil end
    local h = 0
    for i = 1, #id do h = (h * 31 + string.byte(id, i)) % 9973 end
    return list[h % #list + 1]
end
function LC.DreamSongFor(id)
    local own = LC.PropagandaSong and LC.PropagandaSong({ id })
    return own or (LC.StrangeFallbackSongs and LC.StrangeFallbackSongs[id]) or LC.DreamDefaultSong(id)
end
-- (the owner, 12 November: "Freeze dream needs music, all of them need music": Half-Life 2's own for the
-- first dreams too, until the owner puts theirs in sound/livingcity/dreams/<codeword>/)
for id, path in pairs({ maze = "music/hl2_song3.mp3", barrels = "music/hl2_song4.mp3", crumble = "music/hl2_song29.mp3",
    freeze = "music/hl2_song13.mp3" }) do
    LC.StrangeFallbackSongs[id] = LC.StrangeFallbackSongs[id] or path
end
-- Every dream you play and its music, for the debug report: { { id, own songs found, the fallback or nil } }.
function LC.DreamMusicList()
    local out = {}
    for _, id in ipairs(LC.DreamGameOrder or {}) do
        local own = LC.PropagandaSongs and LC.PropagandaSongs(id) or {}
        out[#out + 1] = { id = id, own = #own, fallback = LC.StrangeFallbackSongs and LC.StrangeFallbackSongs[id] or LC.DreamDefaultSong(id) }
    end
    return out
end
local CITIZENS = { "models/humans/group01/male_07.mdl", "models/humans/group01/female_02.mdl", "models/humans/group01/male_02.mdl", "models/humans/group01/female_04.mdl" }
local function FirstModel(list)
    for _, m in ipairs(list) do if K.ValidModel(m) then return m end end
    return list[#list]
end

------------------------------------------------------------------------
-- The Cheese Dream
------------------------------------------------------------------------

do
    LC.CheeseIntro = 9 -- (seconds of the voices echoing in the dark before the dream begins)
    LC.CheeseLines = { male = "vo/npc/male01/question06.wav", female = "vo/npc/female01/question06.wav" } -- ("Sometimes, I dream about cheese.")
    LC.CheeseGravity = 0.35
    local def = { id = "cheese", name = "The Cheese Dream", mood = "neutral", secs = 9 + 180, lives = 3, need = 10, leave = Leave, introSecs = 9,
        introLines = { LC.CheeseLines.male, LC.CheeseLines.female }, introText = { "Sometimes...", "Sometimes... I dream about cheese.", "Sometimes... I dream... about... cheese." },
        goal = "Gather the glowing cheese (golden counts three). You're light as a crumb: jump onto the floating slabs. Keep out of the way of the rolling wheels.",
        timeUp = { "The cheese melts away", "The plain of cheese drips into the dark, and you wake, hungry." },
        woke = Woke({ name = "The Cheese Dream",
            won = { "The Big Cheese", "You wake with the taste of a cheese that doesn't exist anymore. Somewhere, a man and a woman are still talking about it." },
            out = { "Flattened", "You wake feeling rolled thin. It was only cheese. Only cheese." },
            time = { "Sometimes...", "You wake up. Sometimes you dream about cheese. Now you know why." },
        }) }
    G.cheese = def
    local CHEESE, RIND = Color(255, 205, 60), Color(235, 160, 40)
    local WHEEL = "models/hunter/tubes/circle4x4.mdl"
    local WEDGES = { "models/hunter/triangles/2x2x2.mdl", "models/hunter/triangles/1x1x1.mdl", "models/hunter/blocks/cube2x2x2.mdl" }

    local function NewCrumb(g, i)
        local cr = g.crumbs[i]
        local slab = (#g.slabs > 0 and math.random() < 0.4) and g.slabs[math.random(#g.slabs)] or nil
        if slab then
            cr.pos = slab + Vector(math.Rand(-60, 60), math.Rand(-60, 60), 26)
        else
            cr.pos = AnyWhere(g, 80) + Vector(0, 0, 26)
        end
        cr.gold = math.random() < 0.12
        cr.gone = nil
    end

    function def.build(g, dream)
        local top = Plain(g, dream, 3, function(i, j) return (i + j) % 2 == 0 and CHEESE or RIND end)
        local c = dream.pos
        g.introUntil = g.t0 + LC.CheeseIntro
        -- floating slabs of cheese, to jump onto
        g.slabs = {}
        for i = 1, 6 do
            local at = AnyWhere(g, 160) + Vector(0, 0, math.Rand(90, 150))
            local e = Block(g, PLATE4, at, Angle(0, math.Rand(0, 90), 0), CHEESE, "models/debug/debugwhite")
            if e then g.slabs[#g.slabs + 1] = at + Vector(0, 0, 1.5) end
        end
        -- giant heads floating overhead (the citizens who dream of it), and wedges turning in the sky
        g.heads = {}
        for i = 1, 4 do
            local a = math.rad(i * 90 + 45)
            local at = Vector(c.x + math.cos(a) * g.half * 0.8, c.y + math.sin(a) * g.half * 0.8, top + 380)
            local e = Actor(g, CITIZENS[i], at, math.deg(a) + 180, 5, ACT_IDLE or 1)
            if e then g.heads[#g.heads + 1] = { ent = e, at = at, phase = i * 1.7, female = (i % 2 == 0) } end
        end
        g.wedges = {}
        local wedge = FirstModel(WEDGES)
        for i = 1, 3 do
            local at = Vector(c.x + math.Rand(-g.half, g.half) * 0.6, c.y + math.Rand(-g.half, g.half) * 0.6, top + math.Rand(500, 650))
            local e = Actor(g, wedge, at, 0, 2, nil)
            if e then e:SetColor(CHEESE) if e.SetMaterial then e:SetMaterial("models/debug/debugwhite") end g.wedges[#g.wedges + 1] = { ent = e, at = at, spin = math.Rand(20, 60) } end
        end
        g.crumbs = {}
        for i = 1, 12 do g.crumbs[i] = {} NewCrumb(g, i) end
        g.wheels, g.nextWheel = {}, g.introUntil + 4
        g.hum = g.introUntil + math.Rand(6, 12)
        g.song = LC.StrangeSong("cheese")
        Ring(g, 140)
        return true
    end
    function def.spawn(g, p, i) Light(p, LC.CheeseGravity) return SpawnAt(g, p, i) end
    def.hello = IntroHello("cheese")
    function def.begin(g) SayLater(g, 3, "cheese_hello") end

    local function NewWheel(g)
        local c = g.dream.pos
        local a = math.Rand(0, math.pi * 2)
        local dir = Vector(math.cos(a), math.sin(a), 0)
        local side = Vector(-dir.y, dir.x, 0)
        local scale = 1.6
        local r = 95 * scale
        local from = c - dir * (g.half + r) + side * math.Rand(-g.half * 0.6, g.half * 0.6)
        from.z = g.top + r
        local e = Actor(g, FirstModel({ WHEEL, PLATE4 }), from, math.deg(a), scale, nil)
        if not e then return end
        e:SetColor(CHEESE)
        if e.SetMaterial then e:SetMaterial("models/debug/debugwhite") end
        e:SetAngles(Angle(0, math.deg(a), 90)) -- (stood on its edge, rolling along dir)
        g.wheels[#g.wheels + 1] = { ent = e, pos = from, dir = dir, side = side, r = r, speed = math.Rand(260, 380), went = 0, len = (g.half + r) * 2, spin = 0, yaw = math.deg(a) }
        Snd(e, "physics/wood/wood_box_impact_hard3.wav", 80, 60)
    end
    LC.CheeseNewWheel = NewWheel

    -- Is someone under a wheel? (within its width, along its length, and not above it)
    function LC.CheeseUnder(w, pos, top)
        local rel = pos - w.pos
        local along, side = rel.x * w.dir.x + rel.y * w.dir.y, rel.x * w.side.x + rel.y * w.side.y
        return math.abs(along) < w.r * 0.85 and math.abs(side) < 40 and pos.z < top + w.r * 1.6
    end

    function def.tick(g, dt, players)
        local now = CurTime()
        if IntroTick(g, players) then return end -- (the voices in the dark first)
        local t = now - g.t0
        -- the heads hum the line now and then, every colour of the rainbow
        for i, h in ipairs(g.heads) do
            if IsValid(h.ent) then
                h.ent:SetPos(h.at + Vector(0, 0, math.sin(t * 0.8 + h.phase) * 60))
                h.ent:SetAngles(Angle(math.sin(t + h.phase) * 15, (t * 25 + i * 90) % 360, math.cos(t * 0.7 + h.phase) * 20))
                if math.floor(t * 4) ~= h.tint then h.tint = math.floor(t * 4) h.ent:SetColor(Rainbow(t * 0.15 + i * 0.25)) end
            end
        end
        if now >= g.hum and #g.heads > 0 then
            local h = g.heads[math.random(#g.heads)]
            if IsValid(h.ent) then Snd(h.ent, h.female and LC.CheeseLines.female or LC.CheeseLines.male, 100, math.random(55, 140)) end
            g.hum = now + math.Rand(7, 14)
        end
        for _, w in ipairs(g.wedges) do
            if IsValid(w.ent) then w.ent:SetAngles(Angle(t * w.spin * 0.5, t * w.spin, t * w.spin * 0.3)) end
        end
        -- the wheels: more of them as it goes on
        local most = math.min(3, 1 + math.floor((now - g.introUntil) / 50))
        local alive = 0
        for i = #g.wheels, 1, -1 do
            local w = g.wheels[i]
            local step = w.speed * dt
            w.went = w.went + step
            w.pos = w.pos + w.dir * step
            w.spin = (w.spin + step / w.r * 57.3) % 360
            if not IsValid(w.ent) or w.went > w.len then
                if IsValid(w.ent) then w.ent:Remove() end
                table.remove(g.wheels, i)
            else
                w.ent:SetPos(w.pos)
                w.ent:SetAngles(Angle(w.spin, w.yaw, 90))
                alive = alive + 1
            end
        end
        if now >= g.nextWheel and alive < most then
            NewWheel(g)
            g.nextWheel = now + math.Rand(3.5, 7)
        end
        for i, cr in ipairs(g.crumbs) do if cr.gone and now >= cr.gone then NewCrumb(g, i) g.dirty = true end end
        for _, p in ipairs(players) do
            local s = g.pl[p]
            s.got = s.got or 0
            local pos = p:GetPos()
            for _, w in ipairs(g.wheels) do
                if LC.CheeseUnder(w, pos, g.top) and Hit(g, p, "Flattened", "A great wheel of cheese rolls right over you.") then
                    Snd(p, "physics/flesh/flesh_squishy_impact_hard1.wav", 75, 80)
                    break
                end
            end
            if not s.done then
                for _, cr in ipairs(g.crumbs) do
                    if not cr.gone and cr.pos:Distance(pos + Vector(0, 0, 26)) < 52 then
                        cr.gone, g.dirty = now + 3, true
                        s.got = s.got + (cr.gold and 3 or 1)
                        Snd(p, "garrysmod/save_load1.wav", 60, cr.gold and 70 or math.random(130, 160))
                        if cr.gold then
                            s.flip = now + 6
                            if (g.goldSaid or 0) < now then g.goldSaid = now + 20 SayAs(g, "cheese_gold") end
                            Notice(p, "info", "Golden cheese", "Three at once. The world turns inside out for a moment.", 3)
                        end
                        if s.got >= def.need then
                            Done(g, p, "won", "The Big Cheese", "Your arms are full of cheese. The heads in the sky sing your name. Well: they sing \"cheese\".")
                        end
                        break
                    end
                end
            end
        end
    end

    function def.state(g, p)
        local glows = {}
        for _, cr in ipairs(g.crumbs) do if not cr.gone then glows[#glows + 1] = Flat(cr.pos, cr.gold and 6 or 1) end end
        local s = p and g.pl[p] or {}
        local now = CurTime()
        local big
        if now < g.introUntil then big = nil
        elseif now < g.introUntil + 5 then big = "Gather the glowing cheese!" end
        return { glows = glows, big = big, intro = g.introUntil, flip = s.flip, wheels = #g.wheels,
            meter = math.floor(math.min(1, (s.got or 0) / def.need) * 100), meterName = string.format("Cheese: %d of %d", math.min(s.got or 0, def.need), def.need) }
    end
end

------------------------------------------------------------------------
-- Musical Chairs
------------------------------------------------------------------------

do
    LC.ChairsMusic = { 7, 14 } -- (seconds the music plays, at random between)
    LC.ChairsSit = 4 -- (seconds to find a chair once it stops)
    LC.ChairsSoloRounds = 3 -- (alone in it: rounds to sit through to win)
    LC.ChairsReach = 60
    LC.ChairsSeatUp = 22 -- (how high above a chair's foot its seat is, for the real seat: tune it if people sit too high or low)
    -- (three lives since 11 November: the owner, "if they sit while the music is still playing they lose a life". Before, one.)
    local def = { id = "chairs", name = "Musical Chairs", mood = "neutral", secs = 240, lives = 3, ownMusic = true,
        leave = function(g, p) if LC.DreamUnseat then LC.DreamUnseat(p) end end,
        goal = "Walk round the chairs while the music plays. When it stops, get to a free chair and press Use to sit in it. No chair, you're out. Try to sit while the music is still playing and you lose a life.",
        timeUp = { "The music never stops", "The chairs keep drifting round and round, and you drift awake." },
        woke = Woke({ name = "Musical Chairs",
            won = { "The last one sitting", "You wake up sitting bolt upright in bed, and nobody can take it from you." },
            out = { "No chair for you", "You wake with a tune stuck in your head and the feeling that a chair laughed at you." },
            time = { "Round and round", "You wake dizzy, humming. Were there always that many chairs?" },
        }) }
    G.chairs = def
    local CHAIR = { "models/props_c17/chair02a.mdl", "models/props_interiors/furniture_chair01a.mdl", "models/props_c17/furniturechair001a.mdl" }
    local PASTEL = { Color(255, 170, 210), Color(150, 230, 220), Color(200, 180, 255), Color(255, 230, 150) }

    -- (who's really in it: players; stand-ins wander, they don't take chairs)
    local function Seats(g, n)
        -- (anyone still sat in the last round's chairs stands up beside theirs)
        for _, ch in ipairs(g.chairs) do
            if IsValid(ch.by) and ch.by.lcDreamSeat and LC.DreamUnseat then
                LC.DreamUnseat(ch.by)
                local out = Vector(ch.pos.x - g.dream.pos.x, ch.pos.y - g.dream.pos.y, 0)
                if out:Length() > 1 then out:Normalize() end
                ch.by:SetPos(ch.pos + out * 60 + Vector(0, 0, 4))
            end
        end
        for _, ch in ipairs(g.chairs) do if IsValid(ch.ent) then ch.ent:Remove() end end
        g.chairs = {}
        local model = FirstModel(CHAIR)
        for i = 1, math.max(1, n) do
            local e = Actor(g, model, g.dream.pos, 0, 1.4, nil)
            if e then
                e:SetColor(PASTEL[(i - 1) % #PASTEL + 1])
                g.chairs[#g.chairs + 1] = { ent = e, pos = g.dream.pos }
            end
        end
        g.dirty = true
    end
    local function PlaceChairs(g, t)
        local n = #g.chairs
        for i, ch in ipairs(g.chairs) do
            local a = g.turn + (i - 1) / math.max(1, n) * math.pi * 2
            local pos = Vector(g.dream.pos.x + math.cos(a) * g.radius, g.dream.pos.y + math.sin(a) * g.radius, g.top)
            ch.pos, ch.yaw = pos, math.deg(a)
            if IsValid(ch.ent) then
                ch.ent:SetPos(pos + Vector(0, 0, g.phase == "music" and 8 + math.sin(t * 3 + i) * 8 or 0))
                ch.ent:SetAngles(Angle(0, math.deg(a), g.phase == "music" and math.sin(t * 2 + i) * 10 or 0))
            end
        end
    end

    function def.build(g, dream)
        Plain(g, dream, 2, function(i, j) return PASTEL[((i + j) % #PASTEL) + 1] end)
        g.radius = 170
        g.chairs, g.turn, g.round = {}, 0, 0
        g.phase, g.at = "ready", CurTime() + 5
        g.song = LC.StrangeSong("chairs")
        Ring(g, 320)
        return true
    end
    def.spawn = SpawnAt
    def.hello = function(g) SayLater(g, 1.5, "chairs_hello") return { theme = "chairs" } end

    local function NextRound(g, players)
        g.round = g.round + 1
        local n = #players
        g.solo = g.solo or (n <= 1)
        Seats(g, math.max(1, n - 1))
        for _, p in ipairs(players) do g.pl[p].chair = nil end
        g.phase, g.at = "music", CurTime() + math.Rand(LC.ChairsMusic[1], LC.ChairsMusic[2])
        Send(g, { k = "music", song = g.song })
        g.dirty = true
    end
    LC.ChairsNextRound = NextRound

    -- Use, just pressed (looked at every tick for everyone in play).
    local function UsePressed(s, p)
        local down = IN_USE ~= nil and p.KeyDown ~= nil and p:KeyDown(IN_USE) == true
        local was = s.useWas
        s.useWas = down
        return down and not was
    end
    function def.tick(g, dt, players)
        local now = CurTime()
        local t = now - g.t0
        if g.phase == "music" then g.turn = g.turn + dt * 0.6 end
        PlaceChairs(g, t)
        -- (the owner, 11 November: only the Use key sits you down, and trying it while the music still plays costs a life)
        local pressed = {}
        for _, p in ipairs(players) do pressed[p] = UsePressed(g.pl[p], p) end
        if g.phase == "music" then
            for _, p in ipairs(players) do
                if pressed[p] then
                    local pp = p:GetPos()
                    for _, ch in ipairs(g.chairs) do
                        if Dist2(pp, ch.pos) < LC.ChairsReach then
                            Hit(g, p, "Too soon!", "You tried to sit while the music was still playing.")
                            break
                        end
                    end
                end
            end
        end
        if g.phase == "ready" then
            if now >= g.at then NextRound(g, players) end
        elseif g.phase == "music" then
            if now >= g.at then
                g.phase, g.at, g.dirty = "sit", now + LC.ChairsSit, true
                Send(g, { k = "music" }) -- (the music stops)
                SayAs(g, "chairs_sit")
                for _, ch in ipairs(g.chairs) do if IsValid(ch.ent) then Snd(ch.ent, "buttons/button10.wav", 70, 60) break end end
            end
        elseif g.phase == "sit" then
            for _, p in ipairs(players) do
                local s = g.pl[p]
                if not s.chair and pressed[p] then
                    local pp = p:GetPos()
                    for i, ch in ipairs(g.chairs) do
                        if not ch.by and Dist2(pp, ch.pos) < LC.ChairsReach then
                            ch.by, s.chair, g.dirty = p, i, true
                            Snd(p, "garrysmod/save_load1.wav", 60, 130)
                            -- (really sat in it: Garry's Mod's own seat on the chair, LC.DreamSeat)
                            if LC.DreamSeat then
                                local seat = LC.DreamSeat(p, ch.pos + Vector(0, 0, LC.ChairsSeatUp), ch.yaw or 0)
                                if IsValid(seat) then seat.lcDreamGame = true g.ents[#g.ents + 1] = seat end
                            end
                            break
                        end
                    end
                end
            end
            if now >= g.at then
                g.phase, g.at, g.dirty = "result", now + 2.5, true
                local left = 0
                for _, p in ipairs(players) do
                    if not g.pl[p].chair then
                        Done(g, p, "out", "No chair for you", "The music stopped and every chair was taken. The chairs laugh at you (chairs can do that, here).")
                    else left = left + 1 end
                end
                g.left = left
            end
        elseif g.phase == "result" then
            if now >= g.at then
                if #players == 1 and (not g.solo or g.round >= LC.ChairsSoloRounds) then
                    Done(g, players[1], "won", "The last one sitting", "The music stops for good. Yours is the only chair left, and it's very comfortable.")
                elseif #players > 0 then
                    NextRound(g, players)
                end
            end
        end
    end

    function def.state(g, p)
        local s = p and g.pl[p] or {}
        local glows = {}
        if g.phase == "sit" then
            for _, ch in ipairs(g.chairs) do if not ch.by then glows[#glows + 1] = Flat(ch.pos + Vector(0, 0, 30), 6) end end
        end
        local big, tone
        if g.phase == "ready" then big = "Get ready: the music's about to start."
        elseif g.phase == "music" then big = "Keep walking round the chairs... (don't sit yet!)"
        elseif g.phase == "sit" then
            if s.chair then big = "You've got a chair." else big, tone = "SIT! Press Use at a free chair!", "warn" end
        elseif g.phase == "result" and not s.done then big = "Safe! One chair fewer..." end
        return { glows = glows, big = big, tone = tone, phase2 = g.phase,
            meterName = string.format("Round %d     Chairs: %d", g.round, #g.chairs) }
    end
end

------------------------------------------------------------------------
-- Wings
------------------------------------------------------------------------

do
    LC.WingsGravity = 0.5
    LC.WingsFlap = 300
    LC.WingsReach = 85
    local def = { id = "flying", name = "Wings", mood = "happy", secs = 150, lives = 1, need = 8, leave = Leave,
        goal = "You can fly! Jump, then jump again in the air to flap. Fly through the golden rings.",
        timeUp = { "Gently down", "You float down, softly, softly, into your own bed." },
        woke = Woke({ name = "Wings",
            won = { "You flew", "You wake up light as air. For a moment you're sure you could step off the roof and keep going. Don't." },
            time = { "Gently down", "You wake from a flying dream, arms spread, smiling." },
        }) }
    G.flying = def

    local function NewRing(g, i)
        local at = AnyWhere(g, 120)
        at.z = g.top + math.Rand(140, g.ceiling - g.top - 60)
        g.rings[i] = at
    end

    function def.build(g, dream)
        Plain(g, dream, 3, function(i, j) return (i + j) % 2 == 0 and Color(140, 210, 255) or Color(230, 245, 255) end)
        local room = LC.DreamGameHeadroom and LC.DreamGameHeadroom(dream) or 2000
        local roof = LC.DreamTop and LC.DreamTop(dream) or (g.top + 100000)
        g.ceiling = math.min(g.top + math.max(300, math.min(1400, room - 80)), roof - 40)
        if g.ceiling < g.top + 260 then g.ceiling = g.top + 260 end
        g.bounds.maxs.z = g.ceiling + 400
        g.rings = {}
        for i = 1, 5 do NewRing(g, i) end
        g.birds = {}
        local bird = FirstModel({ "models/pigeon.mdl", "models/crow.mdl", "models/seagull.mdl" })
        for i = 1, 5 do
            local e = Actor(g, bird, g.dream.pos, 0, 3, ACT_FLY or ACT_IDLE or 1)
            if e then g.birds[#g.birds + 1] = { ent = e, r = math.Rand(150, g.half), h = math.Rand(150, g.ceiling - g.top - 40), speed = math.Rand(0.3, 0.7) * (i % 2 == 0 and 1 or -1), phase = i } end
        end
        g.song = LC.StrangeSong("flying")
        Ring(g, 160)
        return true
    end
    function def.spawn(g, p, i) Light(p, LC.WingsGravity) return SpawnAt(g, p, i) end
    def.hello = function(g) SayLater(g, 2, "flying_hello") return { theme = "flying", song = g.song, center = Flat(g.dream.pos), ceiling = g.ceiling } end

    -- One flap: up, and a little the way you're looking.
    function LC.WingsFlapPush(p, ceiling)
        local v = p.GetVelocity and p:GetVelocity() or Vector(0, 0, 0)
        if p:GetPos().z > ceiling then return Vector(0, 0, 0) end
        local up = v.z < 150 and LC.WingsFlap - math.max(-200, v.z) * 0.5 or 90
        local fwd = Vector(0, 0, 0)
        if p.GetAimVector then local a = p:GetAimVector() fwd = Vector(a.x, a.y, 0) * 70 end
        return Vector(fwd.x, fwd.y, up)
    end

    function def.tick(g, dt, players)
        local now = CurTime()
        local t = now - g.t0
        for _, b in ipairs(g.birds) do
            if IsValid(b.ent) then
                local a = t * b.speed + b.phase
                b.ent:SetPos(g.dream.pos + Vector(math.cos(a) * b.r, math.sin(a) * b.r, b.h + math.sin(t * 2 + b.phase) * 30))
                b.ent:SetAngles(Angle(0, math.deg(a) + (b.speed > 0 and 90 or -90), 0))
            end
        end
        for _, p in ipairs(players) do
            local s = g.pl[p]
            s.rings = s.rings or 0
            local pos = p:GetPos()
            if JumpPressed(s, p) and not OnGround(p) and p.SetVelocity then
                p:SetVelocity(LC.WingsFlapPush(p, g.ceiling))
            end
            if pos.z > g.ceiling and p.GetVelocity and p.SetVelocity then
                local v = p:GetVelocity()
                if v.z > 0 then p:SetVelocity(Vector(0, 0, -v.z)) end -- (the sky's as high as it goes)
            end
            local mid = pos + Vector(0, 0, 36)
            for i, r in ipairs(g.rings) do
                if r:Distance(mid) < LC.WingsReach then
                    s.rings, g.dirty = s.rings + 1, true
                    Snd(p, "buttons/bell1.wav", 60, 90 + s.rings * 8)
                    NewRing(g, i)
                    if s.rings >= def.need then
                        Done(g, p, "won", "You flew", "Through every ring, round the pigeons, over the dream. You actually flew.")
                    end
                    break
                end
            end
        end
    end

    function def.state(g, p)
        local s = p and g.pl[p] or {}
        local rings = {}
        for _, r in ipairs(g.rings) do rings[#rings + 1] = Flat(r) end
        local now = CurTime()
        return { rings = rings, big = (now < g.t0 + 6) and "Jump, then jump again in the air to flap!" or nil,
            meter = math.floor(math.min(1, (s.rings or 0) / def.need) * 100), meterName = string.format("Rings: %d of %d", math.min(s.rings or 0, def.need), def.need) }
    end
end

------------------------------------------------------------------------
-- It's Raining Melons
------------------------------------------------------------------------

do
    LC.MelonFall = 2.6 -- (seconds from the sky to the ground)
    LC.MelonLead = 0.18 -- (the share that are lead)
    LC.MelonReach = 55
    local def = { id = "melons", name = "It's Raining Melons", mood = "happy", secs = 150, lives = 3, need = 12,
        goal = "Watermelons are falling! Stand on a green glow to catch one. A red glow is a lead melon: keep out from under it.",
        timeUp = { "The rain stops", "The last melon lands, the sun comes out, and you wake." },
        woke = Woke({ name = "It's Raining Melons",
            won = { "A feast", "You wake up full, and sticky, and happy. There's no melon anywhere. There never is." },
            out = { "Bonk", "You wake with a bump on your head that isn't there. Lead melons. Who grows those?" },
            time = { "The rain stops", "You wake to the sound of rain and, for a moment, hope." },
        }) }
    G.melons = def
    local MELON = "models/props_junk/watermelon01.mdl"

    local function Drop(g)
        local land = AnyWhere(g, 70)
        local lead = math.random() < LC.MelonLead
        local e = Actor(g, MELON, land + Vector(0, 0, 900), math.Rand(0, 360), lead and 1.8 or 1.5, nil)
        if e then e.lcKeepLook = lead or nil end -- (a lead melon must look like one)
        if e and lead then
            e:SetColor(Color(70, 70, 80))
            if e.SetMaterial then e:SetMaterial("models/debug/debugwhite") end
        end
        g.drops[#g.drops + 1] = { ent = e, land = land, lead = lead, t0 = CurTime(), t1 = CurTime() + LC.MelonFall }
        g.dirty = true
    end
    LC.MelonDrop = Drop

    function def.build(g, dream)
        Plain(g, dream, 2, function(i, j) return (i + j) % 2 == 0 and Color(120, 200, 90) or Color(160, 225, 110) end)
        g.drops, g.nextDrop = {}, CurTime() + 3
        g.song = LC.StrangeSong("melons")
        Ring(g, 150)
        return true
    end
    def.spawn = SpawnAt
    def.hello = function(g) SayLater(g, 2, "melons_hello") return { theme = "melons", song = g.song } end

    -- A melon lands: the nearest under it catches it (or is bonked by it).
    function LC.MelonLand(g, d, players)
        if IsValid(d.ent) then
            Puff(d.land + Vector(0, 0, 10))
            Snd(d.ent, d.lead and "physics/metal/metal_barrel_impact_hard1.wav" or ("physics/flesh/flesh_squishy_impact_hard" .. math.random(4) .. ".wav"), 75, 100)
            d.ent:Remove()
        end
        local best, bd
        for _, p in ipairs(players) do
            local s = g.pl[p]
            local pp = p:GetPos()
            local dd = Dist2(pp, d.land)
            if s and not s.done and dd < LC.MelonReach and pp.z < g.top + 90 and (not bd or dd < bd) then best, bd = p, dd end
        end
        if not best then return nil end
        local s = g.pl[best]
        if d.lead then
            Hit(g, best, "Bonk", "A lead melon. It's exactly as heavy as it sounds.")
        else
            s.got = (s.got or 0) + 1
            if s.got >= def.need then
                Done(g, best, "won", "A feast", "Your arms are full of melons and the sky is still raining them. A perfect dream.")
            end
        end
        g.dirty = true
        return best
    end

    function def.tick(g, dt, players)
        local now = CurTime()
        local t = now - g.t0
        for i = #g.drops, 1, -1 do
            local d = g.drops[i]
            if now >= d.t1 then
                table.remove(g.drops, i)
                LC.MelonLand(g, d, players)
            elseif IsValid(d.ent) then
                local f = (now - d.t0) / (d.t1 - d.t0)
                d.ent:SetPos(d.land + Vector(0, 0, 8 + 892 * (1 - f * f)))
                d.ent:SetAngles(Angle(t * 200, t * 90, 0))
            end
        end
        if now >= g.nextDrop and #g.drops < 12 then
            Drop(g)
            local n = math.max(1, #players)
            g.nextDrop = now + math.Rand(0.8, 1.4) / math.min(3, 0.6 + n * 0.4)
        end
    end

    function def.state(g, p)
        local s = p and g.pl[p] or {}
        local glows = {}
        for _, d in ipairs(g.drops) do glows[#glows + 1] = Flat(d.land + Vector(0, 0, 6), d.lead and 7 or 5) end
        return { glows = glows, big = (CurTime() < g.t0 + 6) and "Catch the melons! Stand on the green glows." or nil,
            meter = math.floor(math.min(1, (s.got or 0) / def.need) * 100), meterName = string.format("Melons: %d of %d", math.min(s.got or 0, def.need), def.need) }
    end
end

LC.StrangeAddCues({
    cheese_hello = { "The Heads in the Sky", "Cheeeeese. Cheeeeeeeese.", "a choir of giant floating heads, humming, slow, warm, reverb-heavy and slightly off-key" },
    cheese_gold = { "The Heads in the Sky", "The golden cheese! The golden cheese!", "the same choir, suddenly excited, overlapping, high-pitched" },
    chairs_hello = { "The Music Man", "Ladies and gentlemen, musical chairs! When the music stops... sit.", "a cheerful old game-show host, a little too close to the microphone" },
    chairs_sit = { "The Music Man", "SIT!", "the game-show host, sudden and loud" },
    flying_hello = { "A Gentle Voice", "Go on. You always knew you could. Just... flap.", "a soft, kind, dreamy narrator, almost whispering" },
    melons_hello = { "The Weatherman", "Today's forecast: melons. Heavy melons, with a chance of lead.", "a chirpy TV weatherman, completely serious about it" },
})

-- Nonsense (the owner, 9 November: "apply to a random percentage of items/NPCs and such, a random texture?
-- Gmod has the retexture tool... also just random face pose any NPCs"). In every strange dream, now and
-- then: some of its things and figures get a texture from Garry's Mod's own material tool, and some of
-- its people a face (their faces pulled about at random, on everyone's screen: cl_livingcity_strangedreams.lua).
-- Things that matter to playing it (a racer's colour, a lead melon, the floor) keep their look (lcKeepLook).
LC.DreamRetexture, LC.DreamFaces = 0.3, 0.6 -- (the share of things retextured, and of people given a face)
-- Effects stuck on things (the owner, 9 November: "attach emitters on like 10% of NPCs, or objects ... if you can conjure up
-- 10 different effects, then each one has a 10% chance on any item/prop/NPCs to apply"): each of LC.DreamFxNames, on
-- its own roll, for every thing in a strange dream; drawn on everyone's screen (cl_livingcity_strangedreams.lua).
LC.DreamFxChance = 0.1
LC.DreamFxNames = { "sparkles", "halo", "smoke", "bubbles", "hearts", "fire", "confetti", "moons", "beam", "disco" }
-- The effects for one thing: a number, one bit for each effect it got.
function LC.DreamFxRoll(chance)
    local mask = 0
    for k = 1, #LC.DreamFxNames do if math.random() < (chance or LC.DreamFxChance) then mask = mask + 2 ^ (k - 1) end end
    return mask
end
-- Sounds in a strange dream: half of them pitched up or down, slowed or sped (the owner: "voice pitch shifting, slow down/speed ups").
LC.DreamWarp = 0.5
function LC.DreamWarpPitch(p)
    p = p or 100
    if math.random() >= LC.DreamWarp then return p end
    return math.Clamp(math.floor(p * math.Rand(0.6, 1.5)), 30, 255)
end
LC.DreamMaterials = { "models/wireframe", "debug/env_cubemap_model", "models/shadertest/shader3", "models/shadertest/shader4", "models/shadertest/predator",
    "models/shiny", "models/effects/comball_sphere", "models/effects/comball_tape", "models/effects/splodearc_sheet", "models/props_combine/stasisshield_sheet",
    "models/props_combine/portalball001_sheet", "models/props_combine/com_shield001a", "models/props_c17/frostedglass_01a", "models/props_lab/tank_glass001",
    "models/props_combine/tprings_globe", "models/rendertarget", "brick/brick_model", "models/flesh", "phoenix_storms/stripes", "phoenix_storms/wire/pcb_green",
    "phoenix_storms/wire/pcb_red", "phoenix_storms/gear", "hunter/myplastic", "models/xqm/lightlinesred_tool", "models/props_c17/paper01" }
LC.StrangeAll = {}
local function Strange(id)
    if next(LC.StrangeAll) == nil then
        for _, list in ipairs({ LC.StrangeDreams, LC.StrangeDreams2, LC.StrangeDreams3 }) do for _, x in ipairs(list or {}) do LC.StrangeAll[x] = true end end
    end
    return LC.StrangeAll[id] == true
end
LC.StrangeIs = Strange
local FACEY = { "models/humans/", "models/kleiner", "models/breen", "models/monk", "models/alyx", "models/eli", "models/mossman", "models/barney", "models/odessa", "models/gman" }
function LC.DreamFacey(model)
    model = string.lower(model or "")
    for _, f in ipairs(FACEY) do if string.find(model, f, 1, true) then return true end end
    return false
end
-- Everything in the dream not looked at yet: a texture, a face, or as it was.
function LC.DreamNonsense(g)
    if not g or g.stopped then return 0 end
    local n = 0
    for _, e in ipairs(g.ents or {}) do
        if IsValid(e) and not e.lcNonsenseSeen then
            e.lcNonsenseSeen = true
            local facey = e.lcDreamActor and LC.DreamFacey(e.GetModel and e:GetModel())
            if facey and math.random() < LC.DreamFaces then e:SetNW2Bool("lc_dream_face", true) n = n + 1 end
            if not e.lcKeepLook and (e.lcDreamActor or not facey) and math.random() < LC.DreamRetexture and e.SetMaterial then
                e:SetMaterial(LC.DreamMaterials[math.random(#LC.DreamMaterials)])
                n = n + 1
            end
            local fx = (e.lcDreamActor or not e.lcKeepLook) and LC.DreamFxRoll() or 0 -- (not the floor)
            if fx > 0 then e:SetNW2Int("lc_dream_fx", fx) n = n + 1 end
        end
    end
    return n
end
hook.Add("LivingCityDreamStarted", "LivingCityStrangeNonsense", function(dream)
    local g = dream and dream.game
    if not g or not Strange(g.id) then return end
    timer.Create("LivingCityStrangeNonsense", 1, 0, function() -- (and whatever turns up later: stand-ins, melons, wheels)
        if g.stopped or not LC.DreamActive or LC.DreamActive.game ~= g then timer.Remove("LivingCityStrangeNonsense") return end
        LC.DreamNonsense(g)
    end)
end)

-- The pieces, for the strange dreams in the next file (sv_livingcity_strangedreams2.lua).
LC.StrangeKit = { Notice = Notice, Woke = Woke, Plain = Plain, AnyWhere = AnyWhere, Ring = Ring, SpawnAt = SpawnAt, Flat = Flat, Dist2 = Dist2,
    OnGround = OnGround, JumpPressed = JumpPressed, Light = Light, Leave = Leave, CITIZENS = CITIZENS, FirstModel = FirstModel, Rainbow = Rainbow,
    SayAs = SayAs, SayLater = SayLater, IntroTick = IntroTick, IntroHello = IntroHello }
