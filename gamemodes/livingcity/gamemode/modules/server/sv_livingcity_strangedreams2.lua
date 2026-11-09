--[[
    Living City: ten more strange dreams (dreams you play)

      The owner, 8 November: "Please make 10 dreams, any category", among them "the 'I'm so hungry I
      could eat a horse' citizen line: dream it ... make it the black horse statue and have an old man
      (Father Grigori) shooting a shotgun at it infinitely" (a nod to the French horror film Devil Story,
      1986, where an old man shoots a demonic black horse that never dies), and "boxing dream, where
      players have to box in a boxing ring against something ridiculous". Every one can play the owner's
      music (a file named for its codeword in sound/livingcity/dreams/) and every line said in them can
      be a recording (sound/livingcity/dreams/voice/, named for the line; the list to record is
      docs/features/dream-lines.md).

        Hooves and All (horse, Nightmare): in the dark, Half-Life 2's citizens echo that they're so
          hungry they could eat a horse. Then a cliff at night, a wrecked ship on the rocks, and the
          black horse statue come alive, charging at you. Father Grigori stands on the rocks and
          shoots it, again and again, forever: each shot stops it for a moment. Run in and take a
          bite (Use). Eight bites wins; trampled costs a life.
        The Main Event (boxing, Neutral): a boxing ring and a cheering crowd. Three rounds against
          the ridiculous: Lamarr the debeaked headcrab, twelve feet tall; a soda machine; a giant
          baby doll. Punch (attack) next to it; when it winds up, crouch, or it knocks you down (a
          life). Knock out all three to be champion.
        The Exam (exam, Neutral): the exam you never studied for. You're stuck at a desk with your
          paper in front of you; Doctor Kleiner reads six questions with no answers, and you type
          A, B, C or D in chat. The right answer is whatever most of the class picks (alone:
          whatever you pick). Then he walks round, desk by desk, picks up each paper and eats it,
          loudly and with feeling, and only then do you find out your score (the owner, 9 November).
          Four of six passes.
        The Last Train (train, Neutral): the last train out of the city, its door at the end of the
          platform. It slides away while anyone looks at it, and creeps closer when nobody does
          (walk backwards). Reach it before it leaves.
        Where's Lamarr? (lamarr, Happy): a room full of hopping, harmless headcrabs; one is Lamarr,
          golden. Catch them (touch): one each, Lamarr three. Eight wins.
        Running in Molasses (molasses, Nightmare): everything you do is slow, and a giant zombie
          shambles after you. Reach the four glowing corners in turn. Caught costs a life.
        Hot Potato (potato, Neutral): a live grenade. Touch someone (or a stand-in) to pass it.
          Whoever holds it when it goes off loses a life. Six blasts survived wins.
        Overwatch Says (simon, Neutral): a giant officer barks orders: jump, crouch, freeze, walk.
          Do it only if he says "Overwatch says". Fourteen orders survived wins.
        Dance Marathon (dance, Happy): a disco floor and a dancing Strider. Jump on the big beat
          (every fourth). Twenty on the beat wins. With the owner's song (dance1.mp3, and a
          dance1.txt holding its BPM) it follows that; without, a thumping beat at LC.DanceBPM.
        Counting Headcrabs (sheep, Happy): close your eyes and count the headcrabs jumping the fence
          (not the watermelons). Say how many in chat. Exact: 2 points, one off: 1. Three rounds;
          4 points wins.

      Winning a Happy or Neutral one wakes you Unbroken (LC.DreamOutcome), losing costs nothing;
      the two Nightmares wake you as any nightmare does.
]]

if CLIENT then return end

LC = LC or {}

local K, S, G = LC.DreamGameKit, LC.StrangeKit, LC.DreamGames
if not K or not S or not G then return end
local Block, Actor, Animate, Floor, Snd, Puff, Send, Done, Hit, ToStart, InPlay = K.Block, K.Actor, K.Animate, K.Floor, K.Snd, K.Puff, K.Send, K.Done, K.Hit, K.ToStart, K.InPlay
local PLATE8, PLATE8_S, PLATE4, PLATE4_S = K.PLATE8, K.PLATE8_S, K.PLATE4, K.PLATE4_S
local Notice, Woke, Plain, AnyWhere, Ring, SpawnAt, Flat, Dist2 = S.Notice, S.Woke, S.Plain, S.AnyWhere, S.Ring, S.SpawnAt, S.Flat, S.Dist2
local OnGround, JumpPressed, Leave, FirstModel, Rainbow, SayAs, SayLater, IntroTick, IntroHello = S.OnGround, S.JumpPressed, S.Leave, S.FirstModel, S.Rainbow, S.SayAs, S.SayLater, S.IntroTick, S.IntroHello
local CITIZENS = S.CITIZENS

local MORE = { "horse", "boxing", "exam", "train", "lamarr", "molasses", "potato", "simon", "dance", "sheep" }
LC.StrangeDreams2 = MORE
for _, id in ipairs(MORE) do
    local have = false
    for _, o in ipairs(LC.DreamGameOrder) do if o == id then have = true end end
    if not have then LC.DreamGameOrder[#LC.DreamGameOrder + 1] = id end
end
-- (every dream you play, old and new, can have music named for its codeword)
if LC.PropagandaSongWords then
    local have = {}
    for _, w in ipairs(LC.PropagandaSongWords) do have[w] = true end
    for _, id in ipairs(LC.DreamGameOrder) do if not have[id] then have[id] = true LC.PropagandaSongWords[#LC.PropagandaSongWords + 1] = id end end
end
LC.StrangeFallbackSongs = LC.StrangeFallbackSongs or {}
for id, path in pairs({ boxing = "music/hl2_song20_submix0.mp3", exam = "music/hl2_song19.mp3", train = "music/hl2_song26_trainstation1.mp3",
    lamarr = "music/hl2_song10.mp3", molasses = "music/hl2_song16.mp3", potato = "music/hl2_song30.mp3", simon = "music/hl2_song13.mp3",
    sheep = "music/hl2_song2.mp3", horse = "music/hl2_song33.mp3" }) do
    LC.StrangeFallbackSongs[id] = LC.StrangeFallbackSongs[id] or path
end

local KEY_ATTACK, KEY_USE = IN_ATTACK or 1, IN_USE or 32
-- A key just pressed (call every tick for everyone in play; field: where its last state is kept).
local function Pressed(s, p, key, field)
    local down = p.KeyDown ~= nil and p:KeyDown(key) == true
    local was = s[field]
    s[field] = down
    return down and not was
end
LC.StrangePressed = Pressed
local function Crouched(p) return p.Crouching ~= nil and p:Crouching() == true end
local function Boom(pos)
    if not (util and util.Effect and EffectData) then return end
    local ed = EffectData()
    ed:SetOrigin(pos)
    ed:SetMagnitude(1)
    ed:SetScale(1)
    util.Effect("Explosion", ed, true, true)
end
local function Speed2D(p) local v = p.GetVelocity and p:GetVelocity() or Vector(0, 0, 0) return math.sqrt(v.x * v.x + v.y * v.y) end
local function Facing(p, to) -- (looking towards a spot, within about 35 degrees)
    local a = p.GetAimVector and p:GetAimVector()
    if not a then return false end
    local d = to - p:GetPos()
    local l = math.sqrt(d.x * d.x + d.y * d.y)
    local al = math.sqrt(a.x * a.x + a.y * a.y)
    if l < 1 or al < 0.01 then return false end
    return (a.x * d.x + a.y * d.y) / (l * al) > 0.82
end
LC.StrangeFacing = Facing
local function Yaw(from, to) return math.deg(math.atan2(to.y - from.y, to.x - from.x)) end
local function Model(list) local m = FirstModel(list) return K.ValidModel(m) and m or nil end
local function Board(at, yaw, title, lines) return { at.x, at.y, at.z, yaw, title = title, lines = lines } end
local function Nearest(players, pos)
    local best, bd
    for _, p in ipairs(players) do
        local d = Dist2(p:GetPos(), pos)
        if not bd or d < bd then best, bd = p, d end
    end
    return best, bd
end
local function InRing(pos, c, r)
    return Vector(math.Clamp(pos.x, c.x - r, c.x + r), math.Clamp(pos.y, c.y - r, c.y + r), pos.z)
end
local COP = "models/police.mdl"

------------------------------------------------------------------------
-- Hooves and All
------------------------------------------------------------------------

do
    -- ("I'm so hungry I could eat a horse": Half-Life 2's citizens. A recording named horse_intro_male /
    -- horse_intro_female in sound/livingcity/dreams/voice/ takes their place.)
    LC.HorseLines = { male = "vo/npc/male01/question09.wav", female = "vo/npc/female01/question09.wav" }
    LC.HorseStun = 1.8 -- (seconds a shot stops the horse)
    LC.HorseShot = { 1.8, 2.8 } -- (seconds between Father Grigori's shots)
    LC.HorseReach = 110 -- (how close to take a bite)
    local def = { id = "horse", name = "Hooves and All", mood = "nightmare", secs = 9 + 180, lives = 3, need = 8, leave = Leave, introSecs = 9,
        introText = { "I'm so hungry...", "I'm so hungry... I could eat a horse.", "...a horse...  ...a horse..." },
        goal = "The black horse won't die. When Father Grigori's shot stops it, run in and take a bite (Use, E). Don't get trampled.",
        timeUp = { "The horse is still standing", "Father Grigori is still shooting it as you wake. He'll be shooting it forever." } }
    G.horse = def
    local HORSE = { "models/props_c17/statue_horse.mdl", "models/props_c17/statue_horse01.mdl" }
    local MONK = { "models/monk.mdl", "models/humans/group01/male_09.mdl" }
    local SHIP = { "models/props_canal/boat001a.mdl", "models/props_canal/boat002b.mdl" }

    local function Voice(cue, hl2)
        local snd = LC.PropagandaVoice and LC.PropagandaVoice(cue)
        return snd or hl2
    end

    function def.build(g, dream)
        Plain(g, dream, 3, function(i, j) return (i + j) % 2 == 0 and Color(38, 44, 40) or Color(30, 34, 32) end)
        local c = dream.pos
        g.introUntil = g.t0 + def.introSecs
        def.introLines = { Voice("horse_intro_male", LC.HorseLines.male), Voice("horse_intro_female", LC.HorseLines.female) }
        -- the wrecked ship on the rocks, at the edge
        local ship = Model(SHIP)
        if ship then
            local e = Block(g, ship, Vector(c.x - g.half + 120, c.y + g.half - 160, g.top + 20), Angle(18, 35, 25), Color(70, 60, 50))
            if e and e.SetModelScale then e:SetModelScale(1.5) end
        end
        -- the black horse
        local hm = Model(HORSE) or "models/props_c17/oildrum001.mdl"
        g.horse = Actor(g, hm, Vector(c.x, c.y, g.top), 0, LC.HorseScale or 0.6, nil)
        if IsValid(g.horse) then
            g.horse:SetColor(Color(14, 12, 14))
            if g.horse.SetMaterial then g.horse:SetMaterial("models/debug/debugwhite") end
        end
        g.h = { pos = Vector(c.x, c.y, g.top), yaw = 0, state = "idle", til = 0, dir = Vector(1, 0, 0) }
        -- Father Grigori, on the rocks, shooting it forever
        g.monkAt = Vector(c.x + g.half - 70, c.y - g.half + 70, g.top)
        g.monk = Actor(g, FirstModel(MONK), g.monkAt, 135, 1.15, ACT_IDLE_ANGRY or ACT_IDLE or 1)
        g.nextShot, g.stunId, g.nextLine = 0, 0, 0
        g.song = LC.DreamSongFor and LC.DreamSongFor("horse")
        Ring(g, 200)
        return true
    end
    def.spawn = SpawnAt
    def.hello = IntroHello("horse")
    function def.begin(g)
        g.nextShot = CurTime() + 2
        g.nextLine = CurTime() + 1
    end

    local function Shoot(g, now)
        g.nextShot = now + math.Rand(LC.HorseShot[1], LC.HorseShot[2])
        if IsValid(g.monk) then
            Snd(g.monk, "weapons/shotgun/shotgun_fire7.wav", 95, math.random(95, 105))
            timer.Simple(0.5, function() if IsValid(g.monk) then Snd(g.monk, "weapons/shotgun/shotgun_cock.wav", 80) end end)
        end
        Puff(g.h.pos + Vector(0, 0, 70))
        g.h.state, g.h.til = "stun", now + LC.HorseStun
        g.stunId = g.stunId + 1
        g.dirty = true
    end
    LC.HorseShoot = Shoot

    function def.tick(g, dt, players)
        local now = CurTime()
        if IntroTick(g, players) then return end
        local h = g.h
        if now >= g.nextShot then Shoot(g, now) end
        if now >= g.nextLine then
            SayAs(g, "horse_grigori" .. math.random(1, 6))
            g.nextLine = now + math.Rand(9, 15)
        end
        if IsValid(g.monk) then g.monk:SetAngles(Angle(0, Yaw(g.monkAt, h.pos), 0)) end
        -- the horse: still under a shot, charging at someone, or catching its breath
        if h.state == "stun" then
            if now >= h.til then h.state, h.til = "idle", now + 0.4 end
        elseif h.state == "charge" then
            h.pos = InRing(h.pos + h.dir * 270 * dt, g.dream.pos, g.half - 60)
            if now >= h.til then h.state, h.til = "idle", now + 0.7 end
        elseif now >= h.til then
            local target = Nearest(players, h.pos)
            if target then
                local d = target:GetPos() - h.pos
                local l = math.max(1, math.sqrt(d.x * d.x + d.y * d.y))
                h.dir = Vector(d.x / l, d.y / l, 0)
                h.yaw = math.deg(math.atan2(h.dir.y, h.dir.x))
                h.state, h.til = "charge", now + 1.8
                if IsValid(g.horse) then Snd(g.horse, "npc/antlion_guard/angry1.wav", 85, 70) end
            end
        end
        if IsValid(g.horse) then
            g.horse:SetPos(h.pos)
            g.horse:SetAngles(Angle(h.state == "stun" and -22 or 0, h.yaw, 0))
        end
        for _, p in ipairs(players) do
            local s = g.pl[p]
            s.bites = s.bites or 0
            local d = Dist2(p:GetPos(), h.pos)
            local bite = Pressed(s, p, KEY_USE, "useWas")
            if h.state == "charge" and d < 75 then
                if Hit(g, p, "Trampled", "The black horse runs right over you.") then
                    Snd(p, "physics/body/body_medium_impact_hard2.wav", 80)
                end
            elseif bite and h.state == "stun" and d < LC.HorseReach and s.bitId ~= g.stunId then
                s.bites, s.bitId, g.dirty = s.bites + 1, g.stunId, true
                Snd(p, "npc/barnacle/barnacle_crunch2.wav", 75, math.random(90, 110))
                if s.bites >= def.need then
                    Done(g, p, "won", "Hooves and all", "You ate the horse. The whole horse. Father Grigori lowers his shotgun, for the first time in forever, and stares at you.")
                end
            end
        end
    end

    function def.state(g, p)
        local s = p and g.pl[p] or {}
        local now = CurTime()
        local big, tone
        if now >= (g.introUntil or 0) and not s.done then
            local near = p and Dist2(p:GetPos(), g.h.pos) < LC.HorseReach + 60
            if g.h.state == "stun" and s.bitId ~= g.stunId then big = near and "NOW! Take a bite (E)!" or "It's stopped! Run in and bite it!"
            elseif g.h.state == "charge" then big, tone = "It's charging!", "warn" end
        end
        return { horse = IsValid(g.horse) and g.horse:EntIndex() or nil, stunned = g.h.state == "stun", big = big, tone = tone, intro = g.introUntil,
            meter = math.floor(math.min(1, (s.bites or 0) / def.need) * 100), meterName = string.format("Bites: %d of %d", math.min(s.bites or 0, def.need), def.need) }
    end
end

------------------------------------------------------------------------
-- The Main Event
------------------------------------------------------------------------

do
    LC.BoxingFoes = {
        { name = "Lamarr, the Debeaked", models = { "models/lamarr.mdl", "models/headcrabclassic.mdl" }, scale = 7, hp = 1.0, reach = 150, cue = "boxing_foe1" },
        { name = "The Soda Machine", models = { "models/props_interiors/vendingmachinesoda01a.mdl" }, scale = 1.3, hp = 1.25, reach = 150, cue = "boxing_foe2" },
        { name = "The Baby", models = { "models/props_c17/doll01.mdl" }, scale = 14, hp = 1.5, reach = 170, cue = "boxing_foe3" },
    }
    LC.BoxingWindup = 1.1
    local def = { id = "boxing", name = "The Main Event", mood = "neutral", secs = 240, lives = 3,
        goal = "Box! Punch (attack) when you're next to it. When it winds up, crouch, or it knocks you down. Three rounds.",
        timeUp = { "Saved by the bell", "The bell rings, the crowd roars, and you wake with your fists up." },
        woke = Woke({ name = "The Main Event",
            won = { "Champion of the world", "You wake up shadow-boxing your pillow. You beat a baby. A big one. It counts." },
            out = { "Down for the count", "You wake up hearing a referee count to ten. Your jaw hurts in a way it can't." },
            time = { "Saved by the bell", "You wake up with your fists up and a crowd still cheering in your ears." },
        }) }
    G.boxing = def

    local function NewFoe(g, i)
        local f = LC.BoxingFoes[i]
        if IsValid(g.foe) then g.foe:Remove() end
        local c = g.dream.pos
        g.foeI, g.foeDef = i, f
        g.foePos = Vector(c.x + g.ringR * 0.5, c.y, g.top)
        g.foe = Actor(g, FirstModel(f.models), g.foePos, 180, f.scale, ACT_IDLE or 1)
        g.foeMax = LC.BoxingHP(f, #InPlay(g))
        g.foeHP = g.foeMax
        g.phase, g.at = "intro", CurTime() + 4
        g.nextSwing = CurTime() + 4 + math.Rand(2, 3.5)
        SayLater(g, i == 1 and 2.5 or 0.5, f.cue)
        g.dirty = true
    end
    LC.BoxingNewFoe = NewFoe
    -- How many punches a foe takes: more for more boxers.
    function LC.BoxingHP(f, n) return math.floor((12 + 8 * math.max(1, n or 1)) * f.hp) end

    function def.build(g, dream)
        Plain(g, dream, 2, function() return Color(225, 220, 205) end)
        local c = dream.pos
        g.ringR = math.min(g.half - 40, 330)
        local post = Model({ "models/props_c17/signpole001.mdl" })
        if post then for _, sx in ipairs({ -1, 1 }) do for _, sy in ipairs({ -1, 1 }) do
            Block(g, post, Vector(c.x + sx * g.ringR, c.y + sy * g.ringR, g.top), Angle(0, 0, 0), Color(200, 30, 30))
        end end end
        -- the crowd, round the ring
        for i = 1, 10 do
            local a = math.rad(i * 36)
            local at = Vector(c.x + math.cos(a) * (g.ringR + 110), c.y + math.sin(a) * (g.ringR + 110), g.top)
            if math.abs(at.x - c.x) < g.half and math.abs(at.y - c.y) < g.half then
                local e = Actor(g, CITIZENS[(i - 1) % #CITIZENS + 1], at, Yaw(at, c), 1, ACT_IDLE or 1)
                if Animate then Animate(e, ACT_IDLE, ({ "cheer1", "cheer2" })[i % 2 + 1]) end
            end
        end
        g.starts = {}
        for i = 1, 12 do g.starts[i] = Vector(c.x - g.ringR * 0.6 + (i % 3) * 50, c.y - 150 + math.floor((i - 1) / 3) * 90, g.top + 4) end
        g.song = LC.DreamSongFor and LC.DreamSongFor("boxing")
        return true
    end
    function def.spawn(g, p, i) return g.starts[((i - 1) % #g.starts) + 1], 0 end
    def.hello = function(g)
        NewFoe(g, 1)
        SayLater(g, 0.3, "boxing_hello")
        return { theme = "boxing", song = g.song, ring = { math.floor(g.dream.pos.x), math.floor(g.dream.pos.y), math.floor(g.top), g.ringR } }
    end

    function def.tick(g, dt, players)
        local now = CurTime()
        local c = g.dream.pos
        local f = g.foeDef
        for _, p in ipairs(players) do -- (the ropes)
            local pp = p:GetPos()
            if math.abs(pp.x - c.x) > g.ringR + 10 or math.abs(pp.y - c.y) > g.ringR + 10 then p:SetPos(InRing(pp, c, g.ringR)) end
        end
        if g.phase == "intro" then
            if now >= g.at then
                g.phase, g.dirty = "fight", true
                g.foeMax = LC.BoxingHP(f, #players) -- (counted now everyone's in the ring)
                g.foeHP = g.foeMax
                Snd(g.foe, "ambient/alarms/warningbell1.wav", 90, 110)
            end
        elseif g.phase == "ko" then
            if now >= g.at then
                if g.foeI < #LC.BoxingFoes then NewFoe(g, g.foeI + 1)
                else
                    SayAs(g, "boxing_champ")
                    for _, p in ipairs(players) do Done(g, p, "won", "Champion of the world", "All three of them, flat on the canvas. The belt is yours. It's made of cardboard. It's beautiful.") end
                end
            end
            return
        elseif g.phase == "fight" or g.phase == "windup" then
            local target = Nearest(players, g.foePos)
            if g.phase == "fight" and target then
                local d = target:GetPos() - g.foePos
                local l = math.sqrt(d.x * d.x + d.y * d.y)
                if l > f.reach * 0.6 then g.foePos = InRing(g.foePos + Vector(d.x / l, d.y / l, 0) * 95 * dt, c, g.ringR - 40) end
                if IsValid(g.foe) then g.foe:SetAngles(Angle(0, Yaw(g.foePos, target:GetPos()), 0)) end
            end
            if g.phase == "fight" and now >= g.nextSwing then
                g.phase, g.at, g.dirty = "windup", now + LC.BoxingWindup, true
                if IsValid(g.foe) then Snd(g.foe, "npc/vort/claw_swing1.wav", 85, 70) end
            elseif g.phase == "windup" and now >= g.at then
                g.phase, g.dirty = "fight", true
                g.nextSwing = now + math.Rand(2.2, 3.8) * math.max(0.6, 1 - (g.foeI - 1) * 0.15)
                for _, p in ipairs(players) do
                    local pp = p:GetPos()
                    if Dist2(pp, g.foePos) < f.reach and not Crouched(p) and Hit(g, p, "Knocked down", f.name .. " lands one right on your chin.") then
                        Snd(p, "physics/body/body_medium_impact_hard4.wav", 85)
                    end
                end
            end
            if IsValid(g.foe) then g.foe:SetPos(g.foePos + (g.phase == "windup" and Vector(0, 0, 10) or Vector(0, 0, 0))) end
        end
        for _, p in ipairs(players) do
            local s = g.pl[p]
            if Pressed(s, p, KEY_ATTACK, "atkWas") and (g.phase == "fight" or g.phase == "windup") and now >= (s.punchAt or 0)
                and Dist2(p:GetPos(), g.foePos) < f.reach - 10 then
                s.punchAt = now + 0.3
                s.punches = (s.punches or 0) + 1
                g.foeHP, g.dirty = g.foeHP - 1, true
                Snd(p, "physics/body/body_medium_impact_soft" .. math.random(1, 4) .. ".wav", 80, math.random(90, 115))
                if g.foeHP <= 0 then
                    g.phase, g.at = "ko", now + 4
                    if IsValid(g.foe) then g.foe:SetAngles(Angle(0, g.foe:GetAngles().y, 90)) Snd(g.foe, "ambient/alarms/warningbell1.wav", 95, 90) end
                    SayAs(g, "boxing_ko")
                    break
                end
            end
        end
    end

    function def.state(g, p)
        local s = p and g.pl[p] or {}
        local big, tone
        if g.phase == "intro" then big = "Round " .. g.foeI .. ": " .. g.foeDef.name
        elseif g.phase == "windup" then big, tone = "It winds up! CROUCH!", "warn"
        elseif g.phase == "ko" then big = "KNOCKOUT!" end
        return { big = big, tone = tone, foe = IsValid(g.foe) and g.foe:EntIndex() or nil, windup = g.phase == "windup",
            ring = { math.floor(g.dream.pos.x), math.floor(g.dream.pos.y), math.floor(g.top), g.ringR },
            meter = math.floor(math.max(0, g.foeHP) / math.max(1, g.foeMax) * 100),
            meterName = string.format("%s: %d of %d     Your punches: %d", g.foeDef.name, math.max(0, g.foeHP), g.foeMax, s.punches or 0) }
    end
end

------------------------------------------------------------------------
-- The Exam
------------------------------------------------------------------------

do
    LC.ExamQuestions = {
        { q = "What colour is the number seven?", a = { "Purple", "Loud", "Tuesday", "Yes" } },
        { q = "How many headcrabs fit in a hat?", a = { "One", "One, angrily", "Hats are illegal", "All of them" } },
        { q = "Solve for X.", a = { "X", "Twelve", "No", "Whisper it" } },
        { q = "Who was the fourteenth Administrator of Earth?", a = { "You", "A dog", "Nobody", "The fourteenth" } },
        { q = "Translate: \"Cheese.\"", a = { "Cheese", "Fromage", "Sometimes", "Shh" } },
        { q = "When did you last see your trousers?", a = { "This morning", "Never", "Don't look", "They're behind you" } },
        { q = "What does the Combine want?", a = { "Compliance", "A hug", "Your toast", "Seven" } },
        { q = "Spell \"crowbar\".", a = { "C-R-O-W-B-A-R", "Freeman", "Crow. Bar.", "Lambda" } },
        { q = "If a train leaves City 17 at noon, why?", a = { "To escape", "Lunch", "It was late", "It never left" } },
        { q = "Show your working.", a = { "I have", "I can't", "It's a secret", "Working is for the Union" } },
    }
    LC.ExamCount, LC.ExamRead, LC.ExamAnswer = 6, 3, 10
    LC.ExamPass = 4 -- (of the six, to pass)
    LC.ExamWalk = 120 -- (how fast he walks between the desks)
    LC.ExamGrab, LC.ExamEat, LC.ExamReveal = 1, 3, 2.5 -- (seconds: picking up the paper, eating it, and the score shown)
    local LETTERS = { "A", "B", "C", "D" }
    local def = { id = "exam", name = "The Exam", mood = "neutral", lives = 1,
        secs = 6 + LC.ExamCount * (LC.ExamRead + LC.ExamAnswer) + 4 + 12 * (5 + LC.ExamGrab + LC.ExamEat + LC.ExamReveal) + 6,
        goal = "The exam you didn't study for. You're stuck at your desk: type A, B, C or D in chat to answer. The right answer is whatever most of the class picks.",
        timeUp = { "Pencils down", "The bell rings. You wake before he gets to your paper." },
        woke = Woke({ name = "The Exam",
            won = { "Top of the class", "You wake certain you passed an exam you never sat. Somewhere, an old man is still chewing." },
            out = { "See me after class", "You wake in a cold sweat. You didn't study. He ate it anyway. He ate it and he didn't like it." },
            time = { "Pencils down", "You wake up with a pencil you don't own still in your hand. No: it's gone." },
        }) }
    G.exam = def
    local DESK = { "models/props_c17/furnituretable002a.mdl", "models/props_c17/furnituretable001a.mdl", "models/props_wasteland/cafeteria_table001a.mdl" }
    local CHAIR = { "models/props_c17/chair02a.mdl", "models/props_c17/furniturechair001a.mdl" }
    local PAPER = { "models/props_c17/paper01.mdl", "models/props_junk/garbage_newspaper001a.mdl" }
    local CRUNCH = { "npc/barnacle/barnacle_crunch2.wav", "npc/barnacle/barnacle_crunch3.wav" }

    -- Who chose what: the class's answer is the most chosen (every answer tied for most counts).
    function LC.ExamMarks(picks)
        local count, most = {}, 0
        for _, a in pairs(picks) do if a then count[a] = (count[a] or 0) + 1 most = math.max(most, count[a]) end end
        local right = {}
        if most > 0 then for a, n in pairs(count) do if n == most then right[a] = true end end end
        return right
    end
    -- An answer said in chat: a letter (A to D, "b", "C)"), or the answer's own words. Its number, or nil.
    function LC.ExamAnswerOf(text, q)
        local t = string.lower(string.Trim(text or ""))
        local l = string.match(t, "^([abcd])$") or string.match(t, "^([abcd])[%s%)%.:,!]")
        if l then return string.byte(l) - string.byte("a") + 1 end
        for i, a in ipairs(q and q.a or {}) do if t == string.lower(a) then return i end end
        return nil
    end

    function def.build(g, dream)
        Plain(g, dream, 2, function(i, j) return (i + j) % 2 == 0 and Color(120, 95, 70) or Color(105, 82, 60) end)
        local c = dream.pos
        g.seats, g.desks, g.papers, g.seatOf, g.deskTop = {}, {}, {}, {}, {}
        local desk, chair = Model(DESK), Model(CHAIR)
        for i = 1, 12 do -- (three rows of four, facing the board)
            local row, col = math.floor((i - 1) / 4), (i - 1) % 4
            local seat = Vector(c.x - 250 + row * 125, c.y + (col - 1.5) * 105, g.top + 4)
            g.seats[i] = seat
            g.desks[i] = seat + Vector(42, 0, 0)
            local de = desk and Block(g, desk, Vector(g.desks[i].x, g.desks[i].y, g.top), Angle(0, 90, 0), Color(140, 110, 80))
            local h = IsValid(de) and de.OBBMaxs and de:OBBMaxs().z or 30
            g.deskTop[i] = g.top + math.Clamp(h, 20, 50) + 1 -- (the paper lies on it)
            if chair then Actor(g, chair, seat - Vector(14, 0, 4), 0, 1, nil) end
        end
        g.boardAt = Vector(c.x + 300, c.y, g.top + 200)
        g.tAt = Vector(c.x + 220, c.y + 150, g.top)
        g.teacher = Actor(g, FirstModel({ "models/kleiner.mdl", "models/humans/group01/male_09.mdl" }), g.tAt, 180, 1.3, ACT_IDLE or 1)
        local order = {}
        for i = 1, #LC.ExamQuestions do order[i] = i end
        for i = #order, 2, -1 do local j = math.random(i) order[i], order[j] = order[j], order[i] end
        g.order, g.qi, g.phase, g.at = order, 0, "wait", CurTime() + 6
        g.answers = {} -- [question number] = { [player] = answer }
        return true
    end
    function def.spawn(g, p, i)
        local k = ((i - 1) % #g.seats) + 1
        g.seatOf[p] = k
        return g.seats[k], 0
    end
    def.hello = function(g) SayLater(g, 1, "exam_hello") return { theme = "exam" } end

    function def.say(g, p, text)
        local s = g.pl[p]
        if not s or s.done or g.phase ~= "answer" or not g.q then return false end
        local a = LC.ExamAnswerOf(text, g.q)
        if not a then return false end
        g.answers[g.qi][p] = a
        g.dirty = true
        return true
    end

    -- Everyone's score once the questions are done (kept secret until he's eaten their paper).
    function LC.ExamScore(g)
        local n = {}
        for qi = 1, g.qi do
            local picks = g.answers[qi] or {}
            local right = LC.ExamMarks(picks)
            for p, a in pairs(picks) do if right[a] then n[p] = (n[p] or 0) + 1 end end
        end
        for p, s in pairs(g.pl) do s.score = n[p] or 0 end
    end

    -- The papers on the desks of everyone sitting the exam.
    local function Papers(g)
        local paper = Model(PAPER)
        for p, k in pairs(g.seatOf) do
            if not g.papers[k] and g.pl[p] then
                local d = g.desks[k]
                local z = g.deskTop[k] or (g.top + 31)
                local e = paper and Actor(g, paper, Vector(d.x, d.y, z), math.Rand(-20, 20), 1, nil) or nil
                g.papers[k] = { ent = e, p = p, rest = Vector(d.x, d.y, z) }
            end
        end
    end
    -- Who's next to have their exam eaten: the desks in order.
    local function NextDesk(g)
        for k = 1, #g.seats do
            local pa = g.papers[k]
            if pa and not pa.eaten and IsValid(pa.p) and g.pl[pa.p] and not g.pl[pa.p].done then return k end
        end
        return nil
    end
    local function Walk(g, to, dt)
        local d = to - g.tAt
        local l = math.sqrt(d.x * d.x + d.y * d.y)
        if l <= LC.ExamWalk * dt + 1 then g.tAt = Vector(to.x, to.y, g.top) return true end
        g.tAt = g.tAt + Vector(d.x / l, d.y / l, 0) * LC.ExamWalk * dt
        if IsValid(g.teacher) then g.teacher:SetAngles(Angle(0, Yaw(g.tAt, to), 0)) end
        return false
    end

    function def.tick(g, dt, players)
        local now = CurTime()
        for _, p in ipairs(players) do -- (stuck at your desk)
            local s = g.pl[p]
            if s and s.start and Dist2(p:GetPos(), s.start) > 8 then
                p:SetPos(s.start)
                if p.SetVelocity and p.GetVelocity then p:SetVelocity(-p:GetVelocity()) end
            end
        end
        if g.phase == "collect" or g.phase == "walk" or g.phase == "grab" or g.phase == "eat" or g.phase == "reveal" then
            local k = g.desk
            local pa = k and g.papers[k]
            local mouth = g.tAt + Vector(0, 0, 66 * 1.3)
            if g.phase == "collect" then
                k = NextDesk(g)
                if not k then
                    SayAs(g, "exam_end")
                    for _, p in ipairs(players) do Done(g, p, (g.pl[p].score or 0) >= LC.ExamPass and "won" or "out", "Pencils down", "The exam's over.") end
                    g.phase = "over"
                    return
                end
                g.desk, g.phase, g.dirty = k, "walk", true
                if Animate then Animate(g.teacher, ACT_WALK, "walk_all") end
            elseif g.phase == "walk" then
                if Walk(g, g.desks[k] + Vector(48, 0, 0), dt) then
                    g.phase, g.at, g.dirty = "grab", now + LC.ExamGrab, true
                    if IsValid(g.teacher) then g.teacher:SetAngles(Angle(0, 180, 0)) end
                    if Animate then Animate(g.teacher, ACT_IDLE, "idle_all_01") end
                end
            elseif g.phase == "grab" then -- (he picks it up, slowly, and looks at it)
                local f = math.Clamp(1 - (g.at - now) / LC.ExamGrab, 0, 1)
                if pa and IsValid(pa.ent) then pa.ent:SetPos(pa.rest + (mouth + Vector(-14, 0, -10) - pa.rest) * f) end
                if now >= g.at then
                    g.phase, g.at, g.nextCrunch, g.dirty = "eat", now + LC.ExamEat, now, true
                    if math.random() < 0.6 then SayAs(g, "exam_eat" .. math.random(1, 4)) end
                end
            elseif g.phase == "eat" then -- (and eats it, the whole thing, with feeling)
                local f = math.Clamp(1 - (g.at - now) / LC.ExamEat, 0, 1)
                if IsValid(g.teacher) then
                    g.teacher:SetAngles(Angle(-25 * math.sin(f * math.pi) + math.Rand(-6, 6), 180 + math.Rand(-10, 10), math.Rand(-8, 8)))
                    if g.teacher.SetModelScale then g.teacher:SetModelScale(1.3 + 0.25 * math.abs(math.sin(now * 9))) end
                end
                if pa and IsValid(pa.ent) then
                    pa.ent:SetPos(mouth + Vector(-12, 0, -6 + math.sin(now * 20) * 3))
                    pa.ent:SetAngles(Angle(math.Rand(-40, 40), now * 400 % 360, math.Rand(-40, 40)))
                    if pa.ent.SetModelScale then pa.ent:SetModelScale(math.max(0.1, 1 - f)) end
                end
                if now >= g.nextCrunch then
                    if IsValid(g.teacher) then Snd(g.teacher, CRUNCH[math.random(#CRUNCH)], 105, math.random(80, 115)) end
                    g.nextCrunch = now + math.Rand(0.25, 0.45)
                end
                if now >= g.at then
                    if IsValid(g.teacher) then
                        Snd(g.teacher, "npc/barnacle/barnacle_gulp" .. math.random(1, 2) .. ".wav", 110, 85)
                        g.teacher:SetAngles(Angle(0, 180, 0))
                        if g.teacher.SetModelScale then g.teacher:SetModelScale(1.3) end
                    end
                    Puff(mouth)
                    if pa then
                        pa.eaten = true
                        if IsValid(pa.ent) then pa.ent:SetNoDraw(true) end
                        local s = IsValid(pa.p) and g.pl[pa.p]
                        if s then
                            s.revealed = true
                            local pass = (s.score or 0) >= LC.ExamPass
                            Notice(pa.p, pass and "info" or "warn", "Your exam", string.format("He's eaten it. Your score: %d out of %d. %s", s.score or 0, LC.ExamCount,
                                pass and "A pass!" or "A fail."), 6)
                            for _, q in ipairs(players) do
                                if q ~= pa.p and q.ChatPrint then q:ChatPrint(string.format("(in the dream) Doctor Kleiner ate %s's exam: %d out of %d.", pa.p:Nick(), s.score or 0, LC.ExamCount)) end
                            end
                        end
                    end
                    g.phase, g.at, g.dirty = "reveal", now + LC.ExamReveal, true
                end
            elseif g.phase == "reveal" then
                if now >= g.at then
                    local s = pa and IsValid(pa.p) and g.pl[pa.p]
                    if s and not s.done then
                        local pass = (s.score or 0) >= LC.ExamPass
                        Done(g, pa.p, pass and "won" or "out", pass and "Top of the class" or "See me after class",
                            string.format("%d out of %d. He chewed it thoughtfully, and %s.", s.score or 0, LC.ExamCount, pass and "nodded" or "spat out the margins"))
                    end
                    g.phase, g.desk = "collect", nil
                end
            end
            if IsValid(g.teacher) then g.teacher:SetPos(g.tAt) end
            return
        end
        if g.phase == "over" or now < g.at then return end
        if g.phase == "wait" then Papers(g) end
        if g.phase == "wait" or g.phase == "done" then
            if g.qi >= LC.ExamCount then
                LC.ExamScore(g)
                SayAs(g, "exam_collect")
                g.phase, g.at, g.dirty = "collect", now + 2, true
                return
            end
            g.qi = g.qi + 1
            g.q = LC.ExamQuestions[g.order[g.qi]]
            g.answers[g.qi] = {}
            g.phase, g.at, g.dirty = "read", now + LC.ExamRead, true
            if g.qi == 1 or math.random() < 0.35 then SayAs(g, "exam_q" .. math.random(1, 3)) end
        elseif g.phase == "read" then
            g.phase, g.at, g.dirty = "answer", now + LC.ExamAnswer, true
        elseif g.phase == "answer" then
            g.phase, g.at, g.dirty = "done", now + 0.5, true
        end
    end

    function def.state(g, p)
        local lines, title = {}, "THE EXAM"
        if g.q and (g.phase == "read" or g.phase == "answer" or g.phase == "done") then
            title = string.format("QUESTION %d OF %d", g.qi, LC.ExamCount)
            lines[1] = g.q.q
            for i, l in ipairs(LETTERS) do lines[#lines + 1] = l .. ": " .. g.q.a[i] end
        elseif g.qi >= LC.ExamCount then
            title, lines[1] = "PENCILS DOWN", "Your papers will now be collected."
        else lines[1] = "Take your seats." end
        local s = p and g.pl[p] or {}
        local big, tone
        if g.phase == "answer" then
            local mine = g.answers[g.qi] and g.answers[g.qi][p]
            big = mine and string.format("Your answer: %s. (Type another letter to change it.) %d", LETTERS[mine], math.max(0, math.ceil(g.at - CurTime())))
                or string.format("Type A, B, C or D in chat. %d", math.max(0, math.ceil(g.at - CurTime())))
        elseif g.phase == "read" then big = "Read the question..."
        elseif g.desk and g.papers[g.desk] then
            local who = g.papers[g.desk].p
            if who == p then big, tone = (g.phase == "eat" and "He's eating YOUR exam..." or g.phase == "reveal" and string.format("Your score: %d out of %d", s.score or 0, LC.ExamCount) or "He's coming for YOUR paper..."), "warn"
            elseif IsValid(who) then big = (g.phase == "eat" and "Doctor Kleiner is eating " or "Doctor Kleiner is collecting ") .. who:Nick() .. "'s exam." end
        end
        return { board = Board(g.boardAt, 180, title, lines), big = big, tone = tone,
            meterName = s.revealed and string.format("Your score: %d out of %d", s.score or 0, LC.ExamCount) or "Your score: ? (he hasn't eaten your paper yet)" }
    end
end

------------------------------------------------------------------------
-- The Last Train
------------------------------------------------------------------------

do
    LC.TrainAway, LC.TrainNear = 150, 75 -- (how fast the door slides away while watched, and creeps back while not)
    local def = { id = "train", name = "The Last Train", mood = "neutral", secs = 150, lives = 1,
        goal = "Catch the last train: reach its door at the end of the platform before it leaves.",
        timeUp = { "The train leaves without you", "The doors close, the train pulls away, and you wake up on the platform of your bed." },
        woke = Woke({ name = "The Last Train",
            won = { "All aboard", "You wake as the train pulls out, safe on board. Where was it going? Away. That was enough." },
            time = { "Missed it", "You wake up running. You missed it. You always miss it." },
        }) }
    G.train = def

    function def.build(g, dream)
        local P = LC.PropagandaKit
        local x0, x1, top = P.Hall(g, dream, 4, Color(85, 85, 90))
        local c = dream.pos
        g.minX, g.maxX = x0 + 300, x1 - 70
        g.doorX = x0 + (x1 - x0) * 0.62
        g.doorY = c.y
        g.door = Actor(g, FirstModel({ "models/props_c17/door01_left.mdl", "models/props_doors/door03_slotted_left.mdl" }), Vector(g.doorX, g.doorY, top), 180, 1.2, nil)
        if IsValid(g.door) then g.door:SetColor(Color(255, 230, 150)) end
        local car = Model({ "models/props_trainstation/train001.mdl", "models/props_combine/combine_train02a.mdl" })
        if car then Block(g, car, Vector((x0 + x1) / 2, c.y + PLATE8_S + 80, top), Angle(0, 0, 0)) end
        g.starts = {}
        for i = 0, 11 do g.starts[#g.starts + 1] = Vector(x0 + 90 + (i % 2) * 40, c.y - 330 + i * 60, top + 4) end
        g.nextHorn = CurTime() + 5
        return true
    end
    function def.spawn(g, p, i) return g.starts[((i - 1) % #g.starts) + 1], 0 end
    def.hello = function(g) SayLater(g, 1.5, "train_hello") return { theme = "train" } end

    function def.tick(g, dt, players)
        local now = CurTime()
        local door = Vector(g.doorX, g.doorY, g.top)
        local watched = false
        for _, p in ipairs(players) do if Facing(p, door) then watched = true break end end
        g.watched = watched
        local was = g.doorX
        g.doorX = math.Clamp(g.doorX + (watched and LC.TrainAway or -LC.TrainNear) * dt, g.minX, g.maxX)
        if IsValid(g.door) then g.door:SetPos(Vector(g.doorX, g.doorY, g.top)) end
        if math.floor(was / 40) ~= math.floor(g.doorX / 40) then g.dirty = true end
        if now >= g.nextHorn then
            if IsValid(g.door) then Snd(g.door, "ambient/alarms/train_horn2.wav", 90, 100) end
            g.nextHorn = now + math.Rand(12, 20)
        end
        if not g.hinted and now > g.t0 + 30 then g.hinted = true SayAs(g, "train_hint") end
        if not g.warned and now > g.ends - 30 then g.warned = true SayAs(g, "train_closing") end
        for _, p in ipairs(players) do
            if Dist2(p:GetPos(), door) < 75 then
                Done(g, p, "won", "All aboard", "You slip through the doors just as they close. The train pulls out of the dream.")
            end
        end
    end

    function def.state(g, p)
        local now = CurTime()
        local left = math.max(0, math.floor(g.ends - now))
        local big = string.format("The last train leaves in %d:%02d", math.floor(left / 60), left % 60)
        if g.hinted then big = big .. "     (it only moves while someone's looking at it)" end
        return { big = big, door = IsValid(g.door) and g.door:EntIndex() or nil, watched = g.watched }
    end
end

------------------------------------------------------------------------
-- Where's Lamarr?
------------------------------------------------------------------------

do
    LC.LamarrCrabs = 10
    local def = { id = "lamarr", name = "Where's Lamarr?", mood = "happy", secs = 150, lives = 1, need = 8,
        goal = "Doctor Kleiner's pet is loose among a room full of harmless headcrabs. Catch them (touch them). Lamarr, the golden one, counts three.",
        timeUp = { "Lamarr gets away", "Somewhere a kind old voice is still calling \"Lamarr?\" as you wake." },
        woke = Woke({ name = "Where's Lamarr?",
            won = { "Found her", "You wake up cuddling your pillow like a debeaked headcrab. It's oddly comforting." },
            time = { "Still looking", "You wake up checking under the bed for a headcrab. Just in case." },
        }) }
    G.lamarr = def
    local CRAB = "models/headcrabclassic.mdl"

    local function Hop(g, cr, now)
        cr.from = cr.pos
        local to = cr.pos + Vector(math.Rand(-220, 220), math.Rand(-220, 220), 0)
        local c, h = g.dream.pos, g.half - 50
        cr.to = Vector(math.Clamp(to.x, c.x - h, c.x + h), math.Clamp(to.y, c.y - h, c.y + h), g.top)
        cr.t0, cr.t1 = now, now + 0.7
        cr.rest = cr.t1 + math.Rand(0.4, 1.6)
    end
    local function Place(g, cr)
        cr.pos = AnyWhere(g, 60)
        cr.from, cr.to, cr.t0, cr.t1, cr.rest, cr.gone = cr.pos, cr.pos, 0, 0, CurTime() + math.Rand(0.5, 2), nil
        if IsValid(cr.ent) then cr.ent:SetNoDraw(false) cr.ent:SetPos(cr.pos) end
    end

    function def.build(g, dream)
        Plain(g, dream, 2, function(i, j) return (i + j) % 2 == 0 and Color(215, 222, 228) or Color(195, 205, 212) end)
        local c = dream.pos
        g.kleiner = Actor(g, FirstModel({ "models/kleiner.mdl", "models/humans/group01/male_09.mdl" }), Vector(c.x - g.half + 60, c.y, g.top), 0, 1.3, ACT_IDLE or 1)
        g.crabs = {}
        local lamarrModel = Model({ "models/lamarr.mdl" })
        for i = 1, LC.LamarrCrabs do
            local lam = i == 1
            local cr = { lamarr = lam }
            cr.ent = Actor(g, lam and lamarrModel or CRAB, c, math.Rand(0, 360), lam and 1.3 or 1.1, nil)
            if lam and IsValid(cr.ent) then cr.ent:SetColor(Color(255, 215, 80)) end
            Place(g, cr)
            g.crabs[i] = cr
        end
        Ring(g, 150)
        return true
    end
    def.spawn = SpawnAt
    def.hello = function(g) SayLater(g, 1.5, "lamarr_hello") return { theme = "lamarr" } end

    function def.tick(g, dt, players)
        local now = CurTime()
        for _, cr in ipairs(g.crabs) do
            if cr.gone then
                if now >= cr.gone then Place(g, cr) end
            else
                if now >= cr.rest then Hop(g, cr, now) end
                local f = cr.t1 > cr.t0 and math.Clamp((now - cr.t0) / (cr.t1 - cr.t0), 0, 1) or 1
                cr.pos = cr.from + (cr.to - cr.from) * f
                if IsValid(cr.ent) then
                    cr.ent:SetPos(cr.pos + Vector(0, 0, math.sin(f * math.pi) * 70))
                    if cr.to ~= cr.from then cr.ent:SetAngles(Angle(0, Yaw(cr.from, cr.to), 0)) end
                end
                for _, p in ipairs(players) do
                    local s = g.pl[p]
                    if not s.done and Dist2(p:GetPos(), cr.pos) < 48 then
                        cr.gone, g.dirty = now + 3, true
                        if IsValid(cr.ent) then cr.ent:SetNoDraw(true) end
                        s.got = (s.got or 0) + (cr.lamarr and 3 or 1)
                        Snd(p, "npc/headcrab/idle" .. math.random(1, 3) .. ".wav", 70, 130)
                        if cr.lamarr then SayAs(g, "lamarr_found") end
                        if s.got >= def.need then Done(g, p, "won", "Found her", "Your arms are full of wriggling, harmless headcrabs, and Lamarr is licking your ear. Probably licking.") end
                        break
                    end
                end
            end
        end
    end

    function def.state(g, p)
        local s = p and g.pl[p] or {}
        local lam = g.crabs[1]
        local glows = {}
        if lam and not lam.gone then glows[1] = Flat(lam.pos + Vector(0, 0, 30), 1) end
        return { glows = glows, big = (CurTime() < g.t0 + 6) and "Catch the headcrabs! Lamarr (golden) counts three." or nil,
            meter = math.floor(math.min(1, (s.got or 0) / def.need) * 100), meterName = string.format("Caught: %d of %d", math.min(s.got or 0, def.need), def.need) }
    end
end

------------------------------------------------------------------------
-- Running in Molasses
------------------------------------------------------------------------

do
    LC.MolassesSlow = 0.5 -- (how fast you move in it: half)
    LC.MolassesZombie = 45 -- (the zombie's speed at first; it grows by 12 a minute)
    local def = { id = "molasses", name = "Running in Molasses", mood = "nightmare", secs = 180, lives = 3, leave = Leave,
        goal = "Your legs won't go. Reach the four glowing corners in turn while the giant zombie shambles after you.",
        timeUp = { "Still running", "You run and run and get nowhere, and then you're awake, legs tangled in the sheets." } }
    G.molasses = def

    function def.build(g, dream)
        Plain(g, dream, 3, function(i, j) return (i + j) % 2 == 0 and Color(110, 75, 35) or Color(95, 62, 28) end)
        local c, h = dream.pos, g.half - 90
        g.corners = { Vector(c.x + h, c.y + h, g.top), Vector(c.x - h, c.y + h, g.top), Vector(c.x - h, c.y - h, g.top), Vector(c.x + h, c.y - h, g.top) }
        g.zPos = Vector(c.x + h, c.y - h, g.top)
        g.zombie = Actor(g, FirstModel({ "models/zombie/classic.mdl", "models/zombie/fast.mdl" }), g.zPos, 0, 2.5, ACT_WALK or ACT_IDLE or 1)
        g.nextMoan = CurTime() + 3
        Ring(g, 100)
        return true
    end
    function def.spawn(g, p, i)
        if p.SetLaggedMovementValue then p:SetLaggedMovementValue(LC.MolassesSlow) end
        return SpawnAt(g, p, i)
    end
    def.hello = function(g) SayLater(g, 2, "molasses_hello") return { theme = "molasses" } end

    function def.tick(g, dt, players)
        local now = CurTime()
        local target = Nearest(players, g.zPos)
        if target and now > g.t0 + 3 then
            local d = target:GetPos() - g.zPos
            local l = math.sqrt(d.x * d.x + d.y * d.y)
            local speed = LC.MolassesZombie + 12 * (now - g.t0) / 60
            if l > 1 then g.zPos = g.zPos + Vector(d.x / l, d.y / l, 0) * math.min(l, speed * dt) end
            if IsValid(g.zombie) then g.zombie:SetPos(g.zPos) g.zombie:SetAngles(Angle(0, Yaw(g.zPos, target:GetPos()), 0)) end
        end
        if now >= g.nextMoan then
            if IsValid(g.zombie) then Snd(g.zombie, "npc/zombie/zombie_voice_idle" .. math.random(1, 6) .. ".wav", 90, 70) end
            g.nextMoan = now + math.Rand(4, 8)
        end
        for _, p in ipairs(players) do
            local s = g.pl[p]
            s.next = s.next or 1
            local pp = p:GetPos()
            if Dist2(pp, g.zPos) < 55 then
                if Hit(g, p, "Caught", "It got you. You couldn't run.") then
                    g.zPos = g.corners[math.random(#g.corners)] -- (and it's somewhere else, as things are in dreams)
                end
            elseif Dist2(pp, g.corners[s.next]) < 75 then
                s.next, g.dirty = s.next + 1, true
                Snd(p, "buttons/bell1.wav", 60, 80 + s.next * 10)
                if s.next > #g.corners then Done(g, p, "won", "You got away", "The last corner, and the floor lets go of your feet. You beat the nightmare.") end
            end
        end
    end

    function def.state(g, p)
        local s = p and g.pl[p] or {}
        local glows = {}
        local nx = s.next or 1
        if g.corners[nx] then glows[1] = Flat(g.corners[nx] + Vector(0, 0, 40), 5) end
        return { glows = glows, meter = math.floor(math.min(1, (nx - 1) / 4) * 100), meterName = string.format("Corners: %d of 4", math.min(4, nx - 1)) }
    end
end

------------------------------------------------------------------------
-- Hot Potato
------------------------------------------------------------------------

do
    LC.PotatoRounds = 6
    LC.PotatoFuse = { 10, 20 }
    local def = { id = "potato", name = "Hot Potato", mood = "neutral", secs = 200, lives = 3,
        goal = "A live grenade! Touch someone (or a stand-in) to pass it on. Whoever's holding it when it goes off loses a life.",
        timeUp = { "The fuse fizzles", "The grenade fizzles out, and so does the dream." },
        woke = Woke({ name = "Hot Potato",
            won = { "Still in one piece", "You wake up and count your fingers. All there. Excellent." },
            out = { "Boom", "You wake up with your ears ringing. Which is odd, since it was a dream." },
            time = { "It fizzled", "You wake up holding nothing. Good." },
        }) }
    G.potato = def

    local function HolderPos(g)
        local h = g.holder
        if not h then return nil end
        if h.p and IsValid(h.p) then return h.p:GetPos() end
        if h.b and IsValid(h.b.ent) then return h.b.ent:GetPos() end
        return nil
    end
    local function Give(g, h, now)
        g.prev, g.prevUntil = g.holder, now + 2
        g.holder, g.passAt, g.dirty = h, now + 0.8, true
        if h.b then h.passAt = now + math.Rand(1.5, 3) end
        if IsValid(g.nade) then Snd(g.nade, "physics/metal/weapon_impact_soft2.wav", 70) end
    end
    LC.PotatoGive = Give
    local function NewRound(g, players, now)
        g.round = g.round + 1
        g.fuse = now + math.Rand(LC.PotatoFuse[1], LC.PotatoFuse[2])
        g.fuseLen = g.fuse - now
        g.holder = nil
        local who = players[math.random(math.max(1, #players))]
        if who then Give(g, { p = who }, now) end
        g.nextTick = now
    end
    LC.PotatoNewRound = NewRound
    local function Same(a, b) return a and b and ((a.p and a.p == b.p) or (a.b and a.b == b.b)) end

    function def.build(g, dream)
        Plain(g, dream, 2, function(i, j) return (i + j) % 2 == 0 and Color(230, 150, 70) or Color(210, 130, 55) end)
        g.nade = Actor(g, "models/weapons/w_grenade.mdl", dream.pos, 0, 4, nil)
        g.round, g.phase, g.at = 0, "wait", CurTime() + 4
        Ring(g, 220)
        return true
    end
    def.spawn = SpawnAt
    def.hello = function(g) SayLater(g, 1, "potato_hello") return { theme = "potato" } end

    function def.tick(g, dt, players)
        local now = CurTime()
        if g.phase == "wait" then
            if now >= g.at then
                if g.round >= LC.PotatoRounds then
                    for _, p in ipairs(players) do Done(g, p, "won", "Still in one piece", "Six blasts, and you're still standing. Mostly.") end
                    return
                end
                NewRound(g, players, now)
                g.phase = "live"
            end
            return
        end
        local h = g.holder
        if h and h.p and not (IsValid(h.p) and g.pl[h.p] and not g.pl[h.p].done) then h = nil g.holder = nil end
        if not h then
            local who = players[math.random(math.max(1, #players))]
            if who then Give(g, { p = who }, now) h = g.holder else return end
        end
        local hp = HolderPos(g)
        if IsValid(g.nade) and hp then g.nade:SetPos(hp + Vector(0, 0, 88)) g.nade:SetAngles(Angle(0, now * 180 % 360, 0)) end
        -- passing it on
        if now >= (g.passAt or 0) and hp then
            local cands = {}
            for _, p in ipairs(players) do cands[#cands + 1] = { p = p, pos = p:GetPos() } end
            for _, b in ipairs(g.standins or {}) do if IsValid(b.ent) then cands[#cands + 1] = { b = b, pos = b.ent:GetPos() } end end
            if h.b then -- (a stand-in throws it to whoever's nearest, after a moment)
                if now >= (h.passAt or 0) then
                    local best, bd
                    for _, cd in ipairs(cands) do
                        if cd.p then local d = Dist2(cd.pos, hp) if not bd or d < bd then best, bd = cd, d end end
                    end
                    if best then Give(g, { p = best.p }, now) end
                end
            else
                for _, cd in ipairs(cands) do
                    local them = { p = cd.p, b = cd.b }
                    if not Same(them, h) and not (Same(them, g.prev) and now < (g.prevUntil or 0)) and Dist2(cd.pos, hp) < 60 then
                        Give(g, them, now)
                        break
                    end
                end
            end
        end
        -- the fuse
        local rem = g.fuse - now
        if now >= g.nextTick then
            if IsValid(g.nade) then Snd(g.nade, "weapons/grenade/tick1.wav", 75, 100) end
            g.nextTick = now + math.Clamp(rem / 10, 0.12, 1)
        end
        if rem <= 0 then
            local at = HolderPos(g) or g.dream.pos
            Boom(at + Vector(0, 0, 60))
            local h2 = g.holder
            if h2 and h2.p then Hit(g, h2.p, "Boom", "It went off in your hands.")
            elseif h2 and h2.b then Puff(at) end
            g.holder, g.phase, g.at, g.dirty = nil, "wait", now + 3, true
            if IsValid(g.nade) then g.nade:SetPos(g.dream.pos + Vector(0, 0, -500)) end
        end
    end

    function def.state(g, p)
        local h = g.holder
        local mine = h and h.p == p
        local big, tone
        if g.phase == "wait" then big = string.format("Blast %d of %d coming up...", math.min(g.round + 1, LC.PotatoRounds), LC.PotatoRounds)
        elseif mine then big, tone = "YOU HAVE THE GRENADE! Touch someone to pass it!", "warn"
        elseif h then big = (h.p and IsValid(h.p) and h.p:Nick() or (h.b and h.b.name) or "Someone") .. " has the grenade!" end
        return { big = big, tone = tone, nade = IsValid(g.nade) and g.nade:EntIndex() or nil, meterName = string.format("Blasts: %d of %d", math.max(0, g.round - (g.phase == "live" and 1 or 0)), LC.PotatoRounds) }
    end
end

------------------------------------------------------------------------
-- Overwatch Says
------------------------------------------------------------------------

do
    LC.SimonOrders, LC.SimonWindow, LC.SimonGap, LC.SimonTrap = 14, 3, 2, 0.3
    local ACTS = { "jump", "crouch", "freeze", "walk" }
    local TRAPS = { "jump", "crouch" }
    local def = { id = "simon", name = "Overwatch Says", mood = "neutral", lives = 3, secs = 6 + LC.SimonOrders * (LC.SimonWindow + LC.SimonGap) + 4,
        goal = "Do what the giant officer says, but only when he says \"Overwatch says\". Jump, crouch, freeze, or walk about.",
        timeUp = { "Dismissed", "\"Dismissed,\" he says, and you wake standing to attention in bed." },
        woke = Woke({ name = "Overwatch Says",
            won = { "Model citizen", "You wake and jump out of bed before anyone tells you to. Then wonder why." },
            out = { "Overwatch didn't say", "You wake up crouching for no reason. He didn't say. He never said." },
            time = { "Dismissed", "You wake standing to attention in bed." },
        }) }
    G.simon = def

    -- Did they do it? act: what was ordered; says: "Overwatch says" or a trap; s: what they did in the window.
    function LC.SimonObeyed(act, says, s)
        local did
        if act == "jump" then did = s.jumped == true
        elseif act == "crouch" then did = s.crouchEnd == true
        elseif act == "freeze" then did = (s.fastest or 0) < 30
        elseif act == "walk" then did = (s.fastest or 0) > 60 end
        if says then return did == true end
        return not did
    end

    function def.build(g, dream)
        Plain(g, dream, 2, function(i, j) return (i + j) % 2 == 0 and Color(70, 80, 95) or Color(60, 70, 85) end)
        local c = dream.pos
        g.cop = Actor(g, COP, Vector(c.x + g.half - 80, c.y, g.top), 180, 3, ACT_IDLE or 1)
        g.n, g.phase, g.at = 0, "gap", CurTime() + 6
        Ring(g, 160)
        return true
    end
    def.spawn = SpawnAt
    def.hello = function(g) SayLater(g, 1, "simon_hello") return { theme = "simon" } end

    function def.tick(g, dt, players)
        local now = CurTime()
        for _, p in ipairs(players) do
            local s = g.pl[p]
            local jp = JumpPressed(s, p)
            if g.phase == "order" then
                if jp or not OnGround(p) then s.jumped = true end
                s.fastest = math.max(s.fastest or 0, now > g.orderAt + 0.6 and Speed2D(p) or 0) -- (a moment to stop)
            end
        end
        if now < g.at then return end
        if g.phase == "gap" then
            if g.n >= LC.SimonOrders then
                SayAs(g, "simon_end")
                for _, p in ipairs(players) do Done(g, p, "won", "Model citizen", "Every order, to the letter. The officer salutes you. You've never felt so proud, or so strange.") end
                return
            end
            g.n = g.n + 1
            g.says = math.random() >= LC.SimonTrap
            g.act = g.says and ACTS[math.random(#ACTS)] or TRAPS[math.random(#TRAPS)]
            g.phase, g.at, g.orderAt, g.dirty = "order", now + LC.SimonWindow, now, true
            for _, p in ipairs(players) do local s = g.pl[p] s.jumped, s.fastest, s.crouchEnd = false, 0, false end
            SayAs(g, (g.says and "simon_says_" or "simon_trap_") .. g.act)
            if IsValid(g.cop) then Snd(g.cop, "npc/metropolice/vo/" .. ({ "isaidmovealong.wav", "dontmove.wav", "holdit.wav", "move.wav" })[math.random(4)], 90, 80) end
        elseif g.phase == "order" then
            for _, p in ipairs(players) do
                local s = g.pl[p]
                s.crouchEnd = Crouched(p)
                if not LC.SimonObeyed(g.act, g.says, s) then
                    Hit(g, p, g.says and "Too slow" or "Overwatch didn't say", g.says and "You didn't do as you were told." or "He never said \"Overwatch says\".")
                end
            end
            g.phase, g.at, g.dirty = "gap", now + LC.SimonGap, true
        end
    end

    function def.state(g, p)
        local big, tone
        if g.phase == "order" and g.act then
            big = (g.says and "OVERWATCH SAYS: " or "") .. string.upper(g.act) .. "!"
            tone = "warn"
        end
        return { big = big, tone = tone, meterName = string.format("Order %d of %d", g.n, LC.SimonOrders) }
    end
end

------------------------------------------------------------------------
-- Dance Marathon
------------------------------------------------------------------------

do
    LC.DanceBPM = 100 -- (without the owner's song: the beat; with it, the number in its .txt, or this)
    LC.DanceEarly, LC.DanceLate = 0.2, 0.3 -- (seconds either side of the big beat that still count; late allows for the trip to the server)
    local def = { id = "dance", name = "Dance Marathon", mood = "happy", secs = 150, lives = 1, need = 20, ownMusic = true,
        goal = "Dance! Jump on the big beat (every fourth, when the floor flashes). Twenty on the beat wins.",
        timeUp = { "The last song", "The music slows, the lights come up, and you wake still tapping your foot." },
        woke = Woke({ name = "Dance Marathon",
            won = { "Dancing queen", "You wake up with your feet still moving. You've got rhythm. Who knew?" },
            time = { "The last song", "You wake humming something with a beat. Your foot taps on its own." },
        }) }
    G.dance = def

    -- The owner's song and its tempo (a number in a .txt of the same name), or none and LC.DanceBPM.
    function LC.DanceTempo(song)
        if song and file and file.Read then
            local txt = file.Read("sound/" .. string.gsub(song, "%.[%w]+$", ".txt"), "GAME")
            local n = txt and tonumber(string.match(txt, "(%d+%.?%d*)"))
            if n and n >= 40 and n <= 240 then return n end
        end
        return LC.DanceBPM
    end
    -- How far from the nearest big beat (seconds; minus is early).
    function LC.DanceOff(g, t)
        local bar = 4 * 60 / g.bpm
        local k = math.floor((t - g.beat0) / bar + 0.5)
        return t - (g.beat0 + k * bar), k
    end

    function def.build(g, dream)
        Plain(g, dream, 3, function(i, j) return Rainbow((i * 3 + j) / 9) end)
        local c = dream.pos
        local strider = Model({ "models/combine_strider.mdl" })
        if strider then g.strider = Actor(g, strider, Vector(c.x + g.half - 150, c.y, g.top), 180, 0.45, ACT_IDLE or 1) end
        g.song = LC.PropagandaSong and LC.PropagandaSong({ "dance" }) or nil
        g.bpm = LC.DanceTempo(g.song)
        g.beat0 = CurTime() + 4
        g.lastBeat = -1
        Ring(g, 200)
        return true
    end
    def.spawn = SpawnAt
    def.hello = function(g) SayLater(g, 0.5, "dance_hello") return { theme = "dance", song = g.song, bpm = g.bpm, beat0 = g.beat0 } end

    function def.tick(g, dt, players)
        local now = CurTime()
        if now >= g.beat0 then
            local beat = math.floor((now - g.beat0) / (60 / g.bpm))
            if beat ~= g.lastBeat then
                g.lastBeat = beat
                if not g.song and IsValid(g.strider) then -- (no song: a beat to dance to)
                    Snd(g.strider, beat % 4 == 0 and "ambient/machines/thumper_hit.wav" or "buttons/lightswitch2.wav", beat % 4 == 0 and 90 or 70, 100)
                end
                if IsValid(g.strider) then
                    g.strider:SetAngles(Angle(0, 180 + (beat % 2 == 0 and 15 or -15), 0))
                    g.strider:SetPos(Vector(g.dream.pos.x + g.half - 150, g.dream.pos.y, g.top + (beat % 4 == 0 and 30 or 0)))
                end
            end
        end
        for _, p in ipairs(players) do
            local s = g.pl[p]
            s.hits = s.hits or 0
            if JumpPressed(s, p) and now >= g.beat0 - 0.5 then
                local off, k = LC.DanceOff(g, now)
                if off >= -LC.DanceEarly and off <= LC.DanceLate and s.beat ~= k then
                    s.beat, s.hits, g.dirty = k, s.hits + 1, true
                    if s.hits >= def.need then Done(g, p, "won", "Dancing queen", "Twenty on the beat. The Strider bows to you. Striders can't bow. It bows anyway.")
                    elseif s.hits % 5 == 0 then Notice(p, "info", "On the beat", string.format("%d of %d!", s.hits, def.need), 2) end
                end
            end
        end
    end

    function def.state(g, p)
        local s = p and g.pl[p] or {}
        return { bpm = g.bpm, beat0 = g.beat0, big = (CurTime() < g.beat0) and "Get ready to jump on the big beat..." or nil,
            meter = math.floor(math.min(1, (s.hits or 0) / def.need) * 100), meterName = string.format("On the beat: %d of %d", math.min(s.hits or 0, def.need), def.need) }
    end
end

------------------------------------------------------------------------
-- Counting Headcrabs
------------------------------------------------------------------------

do
    LC.SheepRounds, LC.SheepWatch, LC.SheepAnswer, LC.SheepMark = 3, 24, 12, 4
    local def = { id = "sheep", name = "Counting Headcrabs", mood = "happy", lives = 1, need = 4,
        secs = 6 + LC.SheepRounds * (LC.SheepWatch + 2 + LC.SheepAnswer + LC.SheepMark) + 4,
        goal = "Count the headcrabs jumping over the fence (not the watermelons!). Then say how many in chat.",
        timeUp = { "Fast asleep", "You lose count, and drift off properly." },
        woke = Woke({ name = "Counting Headcrabs",
            won = { "Well rested", "You wake up having slept like a baby. A baby who counts headcrabs. Very accurately." },
            out = { "Lost count", "You wake up still counting. Forty-one? Forty-two? There were never that many." },
            time = { "Fast asleep", "You lost count somewhere, and slept the deepest sleep you've had in years." },
        }) }
    G.sheep = def
    local CRAB, MELON = "models/headcrabclassic.mdl", "models/props_junk/watermelon01.mdl"

    -- A round's jumps: how many headcrabs, and when each (and the odd watermelon) goes over.
    function LC.SheepPlan(now, watch)
        local n = math.random(8, 16)
        local jumps, left, t = {}, n, now + 1
        local step = (watch - 4) / n
        while left > 0 do
            local group = math.min(left, math.random() < 0.25 and math.random(2, 3) or 1)
            for i = 1, group do jumps[#jumps + 1] = { t = t + (i - 1) * 0.15, crab = true, y = math.Rand(-200, 200) } end
            left = left - group
            t = t + step * group * math.Rand(0.6, 1.3)
            if math.random() < 0.2 then jumps[#jumps + 1] = { t = t - step * 0.5, crab = false, y = math.Rand(-200, 200) } end
        end
        return n, jumps
    end
    function LC.SheepScore(answer, n)
        if not answer then return 0 end
        local d = math.abs(answer - n)
        return d == 0 and 2 or (d == 1 and 1 or 0)
    end

    function def.build(g, dream)
        Plain(g, dream, 2, function(i, j) return (i + j) % 2 == 0 and Color(60, 110, 60) or Color(50, 95, 50) end)
        local c = dream.pos
        if K.WallAt then
            for k = -1, 1 do K.WallAt(g, Vector(c.x, c.y + k * 190, g.top), false, g.top, Color(150, 110, 70)) end
        end
        g.round, g.phase, g.at, g.flying = 0, "wait", CurTime() + 6, {}
        g.starts = {}
        for i = 0, 11 do g.starts[#g.starts + 1] = Vector(c.x - 120 + (i % 3) * 30, c.y - g.half + 60 + math.floor(i / 3) * 40, g.top + 4) end
        return true
    end
    function def.spawn(g, p, i) return g.starts[((i - 1) % #g.starts) + 1], 90 end
    def.hello = function(g) SayLater(g, 1, "sheep_hello") return { theme = "sheep" } end

    function def.say(g, p, text)
        local s = g.pl[p]
        if not s or s.done or g.phase ~= "answer" then return false end
        local n = tonumber(string.match(text, "(%d+)"))
        if not n then return false end
        s.answer = n
        Notice(p, "info", "Your count", "You said " .. n .. ".", 3)
        return true
    end

    function def.tick(g, dt, players)
        local now = CurTime()
        local c = g.dream.pos
        for i = #g.flying, 1, -1 do -- (whatever's in the air)
            local f = g.flying[i]
            local k = (now - f.t0) / 1.4
            if k >= 1 then
                if IsValid(f.ent) then f.ent:Remove() end
                table.remove(g.flying, i)
            elseif IsValid(f.ent) then
                f.ent:SetPos(Vector(c.x - 320 + 640 * k, c.y + f.y, g.top + math.sin(k * math.pi) * 160))
            end
        end
        if g.phase == "watch" then
            while g.jumps[g.ji] and g.jumps[g.ji].t <= now do
                local j = g.jumps[g.ji]
                local e = Actor(g, j.crab and CRAB or MELON, Vector(c.x - 320, c.y + j.y, g.top), 0, j.crab and 1.2 or 1.4, nil)
                g.flying[#g.flying + 1] = { ent = e, t0 = now, y = j.y }
                g.ji = g.ji + 1
            end
        end
        if now < g.at then return end
        if g.phase == "wait" or g.phase == "mark" then
            if g.round >= LC.SheepRounds then
                for _, p in ipairs(players) do
                    local s = g.pl[p]
                    if (s.points or 0) >= def.need then Done(g, p, "won", "Well rested", string.format("%d points. You counted every last one.", s.points))
                    else Done(g, p, "out", "Lost count", string.format("%d points, of the %d it took. You drifted off.", s.points or 0, def.need)) end
                end
                return
            end
            g.round = g.round + 1
            g.n, g.jumps = LC.SheepPlan(now, LC.SheepWatch)
            g.ji = 1
            g.phase, g.at, g.dirty = "watch", now + LC.SheepWatch + 2, true
            for _, p in ipairs(players) do g.pl[p].answer = nil end
            if g.round > 1 then SayAs(g, "sheep_again") end
        elseif g.phase == "watch" then
            g.phase, g.at, g.dirty = "answer", now + LC.SheepAnswer, true
            SayAs(g, "sheep_ask")
        elseif g.phase == "answer" then
            for _, p in ipairs(players) do
                local s = g.pl[p]
                local got = LC.SheepScore(s.answer, g.n)
                s.points = (s.points or 0) + got
                Notice(p, got > 0 and "info" or "warn", "There were " .. g.n, s.answer and (got == 2 and "Exactly right: 2 points." or got == 1 and "One off: 1 point." or "Not even close.") or "You didn't say.", 5)
            end
            g.phase, g.at, g.dirty = "mark", now + LC.SheepMark, true
        end
    end

    function def.state(g, p)
        local s = p and g.pl[p] or {}
        local big
        if g.phase == "watch" then big = "Count the headcrabs... (not the watermelons)"
        elseif g.phase == "answer" then big = s.answer and ("You said " .. s.answer .. ". (Say another number to change it.)") or string.format("How many headcrabs? Say the number in chat. (%d)", math.max(0, math.ceil(g.at - CurTime())))
        elseif g.phase == "mark" then big = "There were " .. tostring(g.n) .. "." end
        return { big = big, meter = math.floor(math.min(1, (s.points or 0) / def.need) * 100),
            meterName = string.format("Round %d of %d     Points: %d of %d", math.max(1, g.round), LC.SheepRounds, s.points or 0, def.need) }
    end
end

------------------------------------------------------------------------
-- Chat in a strange dream (an answer, said in chat, stays in the dream)
------------------------------------------------------------------------

function LC.StrangeDreamSay(p, text)
    local dream = LC.DreamActive
    local g = dream and dream.game
    if not g or g.stopped or not g.def.say or not IsValid(p) or p.lcDreaming ~= dream.id or not g.pl[p] then return false end
    if LC.PropagandaDreams and LC.PropagandaDreams[g.id] then return false end
    text = string.Trim(text or "")
    local c = string.sub(text, 1, 1)
    if text == "" or c == "/" or c == "!" or c == "@" then return false end
    return g.def.say(g, p, text) == true
end
hook.Add("PlayerSay", "LivingCityStrangeDreams", function(p, text)
    if LC.StrangeDreamSay(p, text) then return "" end
end)

------------------------------------------------------------------------
-- Every line said in these dreams (to record: docs/features/dream-lines.md)
------------------------------------------------------------------------

LC.StrangeAddCues({
    horse_intro_male = { "A Hungry Man", "I'm so hungry... I could eat a horse.", "a weary, starving working man, far away, as if from the end of a long tunnel (replaces Half-Life 2's line)" },
    horse_intro_female = { "A Hungry Woman", "I'm so hungry... I could eat a horse.", "a tired, starving woman, distant and dreamy (replaces Half-Life 2's line)" },
    horse_grigori1 = { "Father Grigori", "Back! Back to the pit, foul beast!", "an old, wild-eyed priest with a booming, theatrical voice, laughing between words" },
    horse_grigori2 = { "Father Grigori", "It will not die! Why will it not die?!", "the old priest, delighted and horrified at once" },
    horse_grigori3 = { "Father Grigori", "Eat, my children! Eat, while it stands still!", "the old priest, preaching at the top of his lungs" },
    horse_grigori4 = { "Father Grigori", "I have been shooting this horse since the old days. I will shoot it until the end of days!", "the old priest, proud and completely mad" },
    horse_grigori5 = { "Father Grigori", "Hah! Feel the wrath of the Lord, and buckshot!", "the old priest, cackling" },
    horse_grigori6 = { "Father Grigori", "Hooves and all, children. Hooves and all.", "the old priest, suddenly quiet and tender" },
    boxing_hello = { "The Ring Announcer", "Ladies and gentlemen, citizens of all ages... welcome... to the Main Event!", "a classic big-fight ring announcer, stretching every vowel" },
    boxing_foe1 = { "The Ring Announcer", "In the far corner, weighing in at four hundred pounds of pure debeaked fury... Lamarr!", "the ring announcer, building to a roar" },
    boxing_foe2 = { "The Ring Announcer", "And now, undefeated in forty bouts, dispensing pain at a reasonable price... the Soda Machine!", "the ring announcer, deadly serious" },
    boxing_foe3 = { "The Ring Announcer", "And your final opponent... he's big, he's bald, he's barely a year old... the Baby!", "the ring announcer, almost screaming" },
    boxing_ko = { "The Ring Announcer", "It's a knockout!", "the ring announcer, ecstatic" },
    boxing_champ = { "The Ring Announcer", "Your new... champion... of the world!", "the ring announcer, over a roaring crowd" },
    exam_hello = { "Doctor Kleiner", "Good morning, class. Pencils ready. Oh dear. You did study, didn't you? And... where are your trousers?", "an elderly, fussy, kindly professor, absent-minded and a little alarmed" },
    exam_q1 = { "Doctor Kleiner", "Next question. Take your time. Actually, don't.", "the old professor, peering over his glasses" },
    exam_q2 = { "Doctor Kleiner", "This one will be on the test. This is the test.", "the old professor, puzzled by his own words" },
    exam_q3 = { "Doctor Kleiner", "Hmm. I'm not sure I know this one either.", "the old professor, mumbling" },
    exam_end = { "Doctor Kleiner", "Marvellous. All graded. I couldn't eat another bite.", "the old professor, very full, patting his stomach" },
    exam_collect = { "Doctor Kleiner", "Pencils down! I shall now collect your papers. Personally.", "the old professor, licking his lips" },
    exam_eat1 = { "Doctor Kleiner", "Mmm. A little dry.", "the old professor, chewing loudly, mouth full" },
    exam_eat2 = { "Doctor Kleiner", "Delicious. Absolutely delicious.", "the old professor, mouth full, ecstatic" },
    exam_eat3 = { "Doctor Kleiner", "I grade with my mouth. It's the only fair way.", "the old professor, chewing, matter-of-fact" },
    exam_eat4 = { "Doctor Kleiner", "Oh, this one has a lot of crossing out. Crunchy.", "the old professor, crunching, delighted" },
    train_hello = { "The Conductor", "Last train! Last train out of City Seventeen! All aboard!", "a hoarse old train conductor, echoing down a station platform" },
    train_hint = { "The Conductor", "You're looking right at it. That never works in dreams.", "the conductor, conspiratorial, a stage whisper" },
    train_closing = { "The Conductor", "Doors closing! Doors closing!", "the conductor, urgent" },
    lamarr_hello = { "Doctor Kleiner", "Lamarr? Lamarr! Oh, where has she got to now? Has anyone seen my headcrab?", "the old professor, fretting over a lost pet" },
    lamarr_found = { "Doctor Kleiner", "Lamarr! There you are, you naughty girl!", "the old professor, overjoyed" },
    molasses_hello = { "A Whisper", "Run. Why aren't you running? Run...", "a slow, breathy, menacing whisper, dragged out" },
    potato_hello = { "The Host", "Hot potato! Don't be holding it when the music... I mean the grenade... stops!", "a manic children's party host" },
    simon_hello = { "The Officer", "Citizens. You will do as Overwatch says. Only as Overwatch says.", "a Civil Protection officer through a gas mask radio, flat and clipped" },
    simon_says_jump = { "The Officer", "Overwatch says: jump.", "the masked officer, flat" },
    simon_says_crouch = { "The Officer", "Overwatch says: crouch.", "the masked officer, flat" },
    simon_says_freeze = { "The Officer", "Overwatch says: freeze.", "the masked officer, flat" },
    simon_says_walk = { "The Officer", "Overwatch says: walk.", "the masked officer, flat" },
    simon_trap_jump = { "The Officer", "Jump.", "the masked officer, flat, sly" },
    simon_trap_crouch = { "The Officer", "Crouch.", "the masked officer, flat, sly" },
    simon_end = { "The Officer", "Compliance noted. Dismissed.", "the masked officer, almost pleased" },
    dance_hello = { "The DJ", "City Seventeen, are you ready to move? Jump on the big beat!", "an over-excited club DJ with heavy reverb" },
    sheep_hello = { "A Sleepy Voice", "Close your eyes... and count the headcrabs. One... two...", "a soft, slow, yawning bedtime voice" },
    sheep_ask = { "A Sleepy Voice", "How many was that? Say it... before you drift off...", "the sleepy voice, half asleep" },
    sheep_again = { "A Sleepy Voice", "Again... from the beginning...", "the sleepy voice, yawning" },
})
