--[[
    Living City: ten more strange dreams, nonsense on purpose

      The owner, 9 November: "Can you please draft 10 more dreams? Please keep in mind the concept of a
      psychedelic nonsensical experience (even if just the skybox, or background of filters or w/e, or
      just adding nonsense things to the base dreams you draft)." Every strange dream also gets the
      nonsense layer on your screen (cl_livingcity_strangedreams.lua): bathtubs, melons, clocks and
      toilets drifting and turning in the sky in every colour, and rainbow swirls overhead.

        Stop the Clocks (clocks, Neutral): giant clocks drift round a ring, melting and ticking. Touch
          one to stop it; it starts again after a while. Stop every clock at once and time is yours.
        The Tea Party (tea, Neutral): a table far too long, cups pouring upwards, and a host who keeps
          shouting "Change places!". Move round to the seat that glows for you before he's done.
        The Headcrab Derby (derby, Happy): four headcrabs race, and nothing about the race is fair.
          Stand on a lane's pad to back it before the off. Two winners out of four races wins.
        Say Cheese (photo, Neutral): a giant scanner wants your picture. When it says "say cheese",
          hide behind the giant bathtub, the giant shoe, the giant melon, before the flash.
        The Doors (doors, Neutral): six doors in a ring, and behind one a music box plays. Listen,
          and stand at that door before time's up.
        Splat! (paint, Happy): every tile you step on takes your colour. Hold your share of the
          floor when the bell goes.
        Conga! (conga, Happy): a conga line of citizens, a headcrab, a watermelon and a chair snakes
          round the floor. Keep in the glow at its tail to fill your groove.
        Shh! (shh, Neutral): a giant baby asleep under a mobile of headcrabs. Gather the toys, quietly:
          running and jumping make noise, and if the baby wakes everyone loses a life.
        Bubbles (bubbles, Happy): bubbles rise from the floor in every colour. Pop them (golden ones
          count three); big ones carry you up to the high ones.
        The Watchers (watchers, Nightmare): tall black figures that only move while nobody looks at
          them. Gather the glowing keys; let one touch you and it costs a life.

      Winning a Happy or Neutral one wakes you Unbroken (LC.DreamOutcome), losing costs nothing; the
      Watchers wake you as any nightmare does. Music: the owner's, named for the codeword, else
      Half-Life 2's own. Lines to record: docs/features/dream-lines.md.
]]

if CLIENT then return end

LC = LC or {}

local K, S, S2, G = LC.DreamGameKit, LC.StrangeKit, LC.StrangeKit2, LC.DreamGames
if not K or not S or not S2 or not G then return end
local Block, Actor, Animate, Snd, Puff, Send, Done, Hit, ToStart, InPlay = K.Block, K.Actor, K.Animate, K.Snd, K.Puff, K.Send, K.Done, K.Hit, K.ToStart, K.InPlay
local PLATE8_S, PLATE4, PLATE4_S = K.PLATE8_S, K.PLATE4, K.PLATE4_S
Snd = function(e, snd, lvl, pitch) K.Snd(e, snd, lvl, LC.DreamWarpPitch and LC.DreamWarpPitch(pitch or 100) or pitch) end -- (half of them warped: sv_livingcity_strangedreams.lua)
local Notice, Woke, Plain, AnyWhere, Ring, SpawnAt, Flat, Dist2 = S.Notice, S.Woke, S.Plain, S.AnyWhere, S.Ring, S.SpawnAt, S.Flat, S.Dist2
local OnGround, JumpPressed, Leave, FirstModel, Rainbow, SayAs, SayLater, Light = S.OnGround, S.JumpPressed, S.Leave, S.FirstModel, S.Rainbow, S.SayAs, S.SayLater, S.Light
local Crouched, Speed2D, Facing, Yaw, Model, Nearest, InRing = S2.Crouched, S2.Speed2D, S2.Facing, S2.Yaw, S2.Model, S2.Nearest, S2.InRing
local CITIZENS = S.CITIZENS

local MORE = { "clocks", "tea", "derby", "photo", "doors", "paint", "conga", "shh", "bubbles", "watchers" }
LC.StrangeDreams3 = MORE
for _, id in ipairs(MORE) do
    local have = false
    for _, o in ipairs(LC.DreamGameOrder) do if o == id then have = true end end
    if not have then LC.DreamGameOrder[#LC.DreamGameOrder + 1] = id end
    if LC.PropagandaSongWords then
        local w = false
        for _, x in ipairs(LC.PropagandaSongWords) do if x == id then w = true end end
        if not w then LC.PropagandaSongWords[#LC.PropagandaSongWords + 1] = id end
    end
end
for id, path in pairs({ clocks = "music/hl2_song10.mp3", tea = "music/hl2_song2.mp3", derby = "music/hl2_song20_submix0.mp3", photo = "music/hl2_song13.mp3",
    doors = "music/hl2_song19.mp3", paint = "music/hl2_song30.mp3", conga = "music/hl2_song27_trainstation2.mp3", shh = "music/hl2_song26.mp3",
    bubbles = "music/hl2_song10.mp3", watchers = "music/hl2_song16.mp3" }) do
    LC.StrangeFallbackSongs[id] = LC.StrangeFallbackSongs[id] or path
end
-- (the doors keep their own quiet: the music box behind the right one is the clue)
LC.StrangeFallbackSongs.doors = nil

local function Tint(e, col) if IsValid(e) then e:SetColor(col) if e.SetMaterial then e:SetMaterial("models/debug/debugwhite") end end end
local function Left(g) return math.max(0, math.ceil(g.at - CurTime())) end

------------------------------------------------------------------------
-- Stop the Clocks
------------------------------------------------------------------------

do
    LC.ClockCount = 8
    LC.ClockStop = 10 -- (seconds a stopped clock stays stopped, plus 16 shared out among the dreamers)
    local def = { id = "clocks", name = "Stop the Clocks", mood = "neutral", secs = 150, lives = 1,
        goal = "Giant melting clocks drift round, ticking. Touch one to stop it; it starts again after a while. Stop every clock at once.",
        timeUp = { "Time runs out", "Time, which was never really yours, runs out. You wake at twenty-five o'clock." },
        woke = Woke({ name = "Stop the Clocks",
            won = { "Time stands still", "You wake up and, for one second, nothing in the world moves. Then it does." },
            time = { "Twenty-five o'clock", "You wake up late. Or early. Your clock says something that isn't a time." },
        }) }
    G.clocks = def
    local CLOCK = { "models/props_c17/clock01.mdl", "models/props_trainstation/clock01.mdl", "models/props_combine/breenclock.mdl" }
    LC.ClockSillyTimes = { "It's twenty-five o'clock.", "It's half past a cheese.", "It's quarter to Tuesday.", "It's yesterday again.", "It's ten minutes to never.", "It's o'clock." }

    -- How long a stopped clock stays stopped: longer when there are fewer of you.
    function LC.ClockHold(n) return LC.ClockStop + 16 / math.max(1, n or 1) end

    function def.build(g, dream)
        Plain(g, dream, 3, function(i, j) return (i + j) % 2 == 0 and Color(90, 40, 120) or Color(30, 120, 120) end)
        g.clocks = {}
        local m = FirstModel(CLOCK)
        g.radius = g.half * 0.7
        for i = 1, LC.ClockCount do
            local e = Actor(g, m, g.dream.pos, 0, 4, nil)
            g.clocks[i] = { ent = e, a = (i - 1) / LC.ClockCount * math.pi * 2, running = true, til = 0, tick = CurTime() + math.Rand(0, 1) }
        end
        g.silly = CurTime() + 8
        Ring(g, 120)
        return true
    end
    def.spawn = SpawnAt
    def.hello = function(g) SayLater(g, 1.5, "clocks_hello") return { theme = "clocks" } end

    function def.tick(g, dt, players)
        local now = CurTime()
        local t = now - g.t0
        local stopped = 0
        for i, ck in ipairs(g.clocks) do
            if not ck.running and now >= ck.til then
                ck.running, g.dirty = true, true
                if IsValid(ck.ent) then Snd(ck.ent, "buttons/lever7.wav", 80, 70) end
            end
            if ck.running then ck.a = ck.a + dt * 0.12 end
            ck.pos = Vector(g.dream.pos.x + math.cos(ck.a) * g.radius, g.dream.pos.y + math.sin(ck.a) * g.radius, g.top + 40)
            if IsValid(ck.ent) then
                ck.ent:SetPos(ck.pos + Vector(0, 0, math.sin(t * 1.3 + i) * 20))
                -- (melting: drooping, more as it runs)
                ck.ent:SetAngles(Angle(ck.running and (25 + 15 * math.sin(t * 0.7 + i)) or 0, math.deg(ck.a) + 180, ck.running and 20 * math.sin(t * 0.5 + i) or 0))
            end
            if ck.running and now >= ck.tick then
                if IsValid(ck.ent) then Snd(ck.ent, "buttons/lightswitch2.wav", 75, 60 + i * 8) end
                ck.tick = now + 1
            end
            if not ck.running then stopped = stopped + 1 end
        end
        g.nStopped = stopped
        if stopped >= #g.clocks then
            SayAs(g, "clocks_won")
            for _, p in ipairs(players) do Done(g, p, "won", "Time stands still", "Every clock stopped at once. For a moment the whole dream holds its breath, and it's yours.") end
            return
        end
        if now >= g.silly then
            g.sillyText, g.silly, g.dirty = LC.ClockSillyTimes[math.random(#LC.ClockSillyTimes)], now + math.Rand(8, 14), true
        end
        for _, p in ipairs(players) do
            local pp = p:GetPos()
            for _, ck in ipairs(g.clocks) do
                if ck.running and Dist2(pp, ck.pos) < 80 then
                    ck.running, ck.til, g.dirty = false, now + LC.ClockHold(#players), true
                    if IsValid(ck.ent) then Snd(ck.ent, "buttons/button9.wav", 80, 90) end
                end
            end
        end
    end

    function def.state(g, p)
        local glows = {}
        for _, ck in ipairs(g.clocks) do if ck.pos then glows[#glows + 1] = Flat(ck.pos + Vector(0, 0, 100), ck.running and 7 or 3) end end
        return { glows = glows, big = g.sillyText, meterName = string.format("Clocks stopped: %d of %d", g.nStopped or 0, #g.clocks),
            meter = math.floor((g.nStopped or 0) / #g.clocks * 100) }
    end
end

------------------------------------------------------------------------
-- The Tea Party
------------------------------------------------------------------------

do
    LC.TeaRounds, LC.TeaMove, LC.TeaWait = 10, 4, 2.5
    local def = { id = "tea", name = "The Tea Party", mood = "neutral", lives = 3, secs = 6 + LC.TeaRounds * (LC.TeaMove + LC.TeaWait) + 6,
        goal = "A tea party at a table far too long. When the host shouts \"Change places!\", get to the seat that glows for you before he's done.",
        timeUp = { "Tea's over", "The cups pour themselves back into the pot, upwards, and you wake." },
        woke = Woke({ name = "The Tea Party",
            won = { "A very merry unbirthday", "You wake up and it isn't your birthday. Congratulations." },
            out = { "No room! No room!", "You wake up at the wrong end of your bed, which feels like the wrong seat." },
            time = { "Tea's over", "You wake up tasting tea that went up instead of down." },
        }) }
    G.tea = def
    local CUP = { "models/props_junk/garbage_coffeemug001a.mdl", "models/props_junk/metal_paintcan001a.mdl", "models/props_c17/metalpot002a.mdl" }

    function def.build(g, dream)
        Plain(g, dream, 2, function(i, j) return (i + j) % 2 == 0 and Color(250, 200, 220) or Color(200, 240, 210) end)
        local c = dream.pos
        local table_ = Model({ "models/props_c17/furnituretable001a.mdl", "models/props_c17/furnituretable002a.mdl" })
        for k = -2, 2 do if table_ then Block(g, table_, Vector(c.x + k * 70, c.y, g.top), Angle(0, 0, 0), Color(255, 255, 255)) end end
        -- twelve seats round the table: six each side, in a loop
        g.seats = {}
        for k = 0, 5 do g.seats[#g.seats + 1] = Vector(c.x - 175 + k * 70, c.y - 75, g.top + 4) end
        for k = 5, 0, -1 do g.seats[#g.seats + 1] = Vector(c.x - 175 + k * 70, c.y + 75, g.top + 4) end
        g.host = Actor(g, FirstModel({ "models/breen.mdl", "models/humans/group01/male_09.mdl" }), Vector(c.x - 260, c.y, g.top), 0, 1.6, ACT_IDLE or 1)
        g.cups = {}
        local cup = FirstModel(CUP)
        for k = 1, 8 do
            local e = Actor(g, cup, c, 0, 3, nil)
            Tint(e, Rainbow(k / 8))
            g.cups[k] = e
        end
        g.seatOf, g.round, g.phase, g.at = {}, 0, "wait", CurTime() + 6
        return true
    end
    function def.spawn(g, p, i)
        local k = ((i - 1) % #g.seats) + 1
        g.seatOf[p] = k
        return g.seats[k], 0
    end
    def.hello = function(g) SayLater(g, 1, "tea_hello") return { theme = "tea" } end

    function def.tick(g, dt, players)
        local now = CurTime()
        local t = now - g.t0
        for k, e in ipairs(g.cups) do -- (cups waltzing over the table, pouring upwards)
            if IsValid(e) then
                local a = t * 0.6 + k * 0.8
                e:SetPos(g.dream.pos + Vector(math.cos(a) * 160, math.sin(a) * 60, 110 + math.sin(t * 2 + k) * 30))
                e:SetAngles(Angle(180, t * 90 + k * 40, 0))
            end
        end
        if now < g.at then return end
        if g.phase == "wait" or g.phase == "check" then
            if g.round >= LC.TeaRounds then
                for _, p in ipairs(players) do Done(g, p, "won", "A very merry unbirthday", "Every change, every seat. The host raises his cup to you, upside down.") end
                return
            end
            g.round = g.round + 1
            g.move = (math.random() < 0.3 and -1 or 1) * math.random(1, 3)
            for _, p in ipairs(players) do
                local k = g.seatOf[p] or 1
                g.seatOf[p] = ((k - 1 + g.move) % #g.seats) + 1
            end
            g.phase, g.at, g.dirty = "move", now + LC.TeaMove, true
            SayAs(g, g.move > 0 and ("tea_down" .. math.abs(g.move)) or "tea_up")
            if IsValid(g.host) then Snd(g.host, "buttons/bell1.wav", 80, 60) end
        elseif g.phase == "move" then
            for _, p in ipairs(players) do
                local seat = g.seats[g.seatOf[p] or 1]
                local s = g.pl[p]
                if Dist2(p:GetPos(), seat) > 45 then
                    if Hit(g, p, "No room! No room!", "That's not your seat. Not any more.") then s.start = seat end
                end
                s.start = seat -- (back to your new seat, if you were sent back)
            end
            g.phase, g.at, g.dirty = "check", now + LC.TeaWait, true
        end
    end

    function def.state(g, p)
        local glows = {}
        local mine = p and g.seatOf[p]
        if mine and g.seats[mine] then glows[1] = Flat(g.seats[mine] + Vector(0, 0, 30), 5) end
        local big, tone
        if g.phase == "move" then
            big = (g.move > 0 and string.format("Change places! Move down %d! (%d)", g.move, Left(g)) or string.format("Clean cup! Move up %d! (%d)", -g.move, Left(g)))
            tone = "warn"
        end
        return { glows = glows, big = big, meterName = string.format("Round %d of %d", g.round, LC.TeaRounds) }
    end
end

------------------------------------------------------------------------
-- The Headcrab Derby
------------------------------------------------------------------------

do
    LC.DerbyRaces, LC.DerbyBet, LC.DerbyLen, LC.DerbyAfter = 4, 8, 16, 4
    LC.DerbyNames = { "Lamarr's Cousin", "Hooves", "Mister Leg", "Breen's Toupee" }
    LC.DerbyColours = { Color(255, 205, 70), Color(140, 220, 60), Color(150, 190, 230), Color(255, 120, 190) }
    LC.DerbyEvents = {
        "%s stops to admire itself.", "%s is briefly a watermelon.", "%s goes backwards, confidently.", "%s falls asleep.",
        "%s has found a shortcut through another dimension.", "%s is carried along by a passing pigeon.", "%s does a little dance.",
    }
    local def = { id = "derby", name = "The Headcrab Derby", mood = "happy", lives = 1, need = 2,
        secs = 6 + LC.DerbyRaces * (LC.DerbyBet + LC.DerbyLen + LC.DerbyAfter) + 4,
        goal = "Four headcrabs race and nothing is fair. Before the off, stand on a lane's pad to back that headcrab. Back two winners out of four races.",
        timeUp = { "The track closes", "The headcrabs keep running, out of the dream, and you wake." },
        woke = Woke({ name = "The Headcrab Derby",
            won = { "Winner's enclosure", "You wake up a lucky person. You don't know what at. Headcrabs, probably." },
            out = { "Lost your shirt", "You wake up sure you bet your shirt on a headcrab called Mister Leg." },
            time = { "Photo finish", "You wake up before the photo finish. You'll never know." },
        }) }
    G.derby = def

    function def.build(g, dream)
        Plain(g, dream, 3, function(i, j) return (i + j) % 2 == 0 and Color(70, 140, 70) or Color(60, 125, 60) end)
        local c = dream.pos
        g.x0, g.x1 = c.x - g.half + 120, c.x + g.half - 80
        g.lanes, g.pads, g.crabs = {}, {}, {}
        for i = 1, 4 do
            local y = c.y - 240 + (i - 1) * 110
            g.lanes[i] = y
            g.pads[i] = Vector(g.x0 - 60, y, g.top)
            local pad = Block(g, PLATE4, Vector(g.x0 - 60, y, g.top + 1), Angle(0, 0, 0), LC.DerbyColours[i], "models/debug/debugwhite")
            local e = Actor(g, "models/headcrabclassic.mdl", Vector(g.x0, y, g.top), 0, 1.6, nil)
            Tint(e, LC.DerbyColours[i])
            if IsValid(pad) then pad.lcKeepLook = true end
            if IsValid(e) then e.lcKeepLook = true end -- (each racer in its lane's colour)
            g.crabs[i] = { ent = e, x = g.x0 }
        end
        local finish = Model({ "models/props_c17/signpole001.mdl" })
        if finish then for i = 1, 4 do Block(g, finish, Vector(g.x1, g.lanes[i] + 55, g.top), Angle(0, 0, 0), Color(255, 255, 255)) end end
        g.race, g.phase, g.at = 0, "wait", CurTime() + 6
        g.starts = {}
        for i = 0, 11 do g.starts[#g.starts + 1] = Vector(g.x0 - 160, c.y - 300 + i * 50, g.top + 4) end
        return true
    end
    function def.spawn(g, p, i) return g.starts[((i - 1) % #g.starts) + 1], 0 end
    def.hello = function(g) SayLater(g, 1, "derby_hello") return { theme = "derby" } end

    function LC.DerbyPadOf(g, pos)
        for i, at in ipairs(g.pads) do
            if math.abs(pos.x - at.x) < PLATE4_S / 2 and math.abs(pos.y - at.y) < PLATE4_S / 2 then return i end
        end
        return nil
    end

    function def.tick(g, dt, players)
        local now = CurTime()
        if g.phase == "race" then
            for i, cr in ipairs(g.crabs) do
                if now >= (cr.next or 0) then
                    cr.speed = math.Rand(40, 200)
                    cr.next = now + math.Rand(0.6, 1.6)
                    if math.random() < 0.08 then -- (nonsense)
                        g.news, g.dirty = string.format(LC.DerbyEvents[math.random(#LC.DerbyEvents)], LC.DerbyNames[i]), true
                        if string.find(g.news, "backwards", 1, true) then cr.speed = -120 end
                        if string.find(g.news, "asleep", 1, true) or string.find(g.news, "admire", 1, true) then cr.speed = 0 end
                        if string.find(g.news, "dimension", 1, true) then cr.x = cr.x + 150 end
                    end
                end
                cr.x = math.Clamp(cr.x + (cr.speed or 0) * dt, g.x0, g.x1)
                if IsValid(cr.ent) then cr.ent:SetPos(Vector(cr.x, g.lanes[i], g.top + math.abs(math.sin(now * 8 + i)) * 20)) end
                if cr.x >= g.x1 and not g.winner then g.winner = i end
            end
            if g.winner then
                g.phase, g.at, g.dirty = "after", now + LC.DerbyAfter, true
                SayAs(g, "derby_win" .. g.winner)
                for _, p in ipairs(players) do
                    local s = g.pl[p]
                    if s.bet == g.winner then
                        s.points = (s.points or 0) + 1
                        Notice(p, "info", "A winner!", LC.DerbyNames[g.winner] .. " wins, and you backed it.", 4)
                    else
                        Notice(p, "warn", LC.DerbyNames[g.winner] .. " wins", s.bet and ("Your " .. LC.DerbyNames[s.bet] .. " didn't.") or "You didn't back anyone.", 4)
                    end
                end
            elseif now >= g.at then -- (nobody finished: the nearest wins)
                local best = 1
                for i, cr in ipairs(g.crabs) do if cr.x > g.crabs[best].x then best = i end end
                g.crabs[best].x = g.x1
            end
            return
        end
        if now < g.at then return end
        if g.phase == "wait" or g.phase == "after" then
            if g.race >= LC.DerbyRaces then
                for _, p in ipairs(players) do
                    local s = g.pl[p]
                    if (s.points or 0) >= def.need then Done(g, p, "won", "Winner's enclosure", string.format("%d winners backed. The headcrabs carry you round the track on their backs.", s.points))
                    else Done(g, p, "out", "Lost your shirt", string.format("%d winners backed, of the %d it took.", s.points or 0, def.need)) end
                end
                return
            end
            g.race, g.winner, g.news = g.race + 1, nil, nil
            for i, cr in ipairs(g.crabs) do cr.x, cr.speed, cr.next = g.x0, 0, 0 if IsValid(cr.ent) then cr.ent:SetPos(Vector(g.x0, g.lanes[i], g.top)) end end
            g.phase, g.at, g.dirty = "bet", now + LC.DerbyBet, true
        elseif g.phase == "bet" then
            for _, p in ipairs(players) do g.pl[p].bet = LC.DerbyPadOf(g, p:GetPos()) end
            g.phase, g.at, g.dirty = "race", now + LC.DerbyLen, true
            SayAs(g, "derby_off")
            Snd(g.crabs[1].ent, "weapons/357/357_fire2.wav", 80, 120)
        end
    end

    function def.state(g, p)
        local s = p and g.pl[p] or {}
        local glows = {}
        if g.phase == "bet" then for i, at in ipairs(g.pads) do glows[#glows + 1] = Flat(at + Vector(0, 0, 8), i) end end
        local big
        if g.phase == "bet" then
            local pad = p and LC.DerbyPadOf(g, p:GetPos())
            big = (pad and ("You're backing " .. LC.DerbyNames[pad] .. ".") or "Stand on a lane's pad to back its headcrab.") .. string.format(" (%d)", Left(g))
        elseif g.phase == "race" then big = g.news or ("And they're off!" .. (s.bet and (" You backed " .. LC.DerbyNames[s.bet] .. ".") or ""))
        elseif g.phase == "after" and g.winner then big = LC.DerbyNames[g.winner] .. " wins!" end
        return { glows = glows, big = big, meterName = string.format("Race %d of %d     Winners backed: %d of %d", math.max(1, g.race), LC.DerbyRaces, s.points or 0, def.need) }
    end
end

------------------------------------------------------------------------
-- Say Cheese
------------------------------------------------------------------------

do
    LC.PhotoShots, LC.PhotoWarn = 10, 2.2
    local def = { id = "photo", name = "Say Cheese", mood = "neutral", secs = 150, lives = 3,
        goal = "A giant scanner wants your picture. When it says \"say cheese\", hide behind something giant before the flash.",
        timeUp = { "The film runs out", "The scanner runs out of film and wanders off to develop its pictures. You wake." },
        woke = Woke({ name = "Say Cheese",
            won = { "Camera shy", "You wake up and check: no photographs of you anywhere. Good." },
            out = { "Snapped", "You wake up blinking spots out of your eyes. Somewhere there's a photo of you looking terrible." },
            time = { "The film runs out", "You wake up still hiding behind something that isn't there." },
        }) }
    G.photo = def
    -- Giant things to hide behind: model, scale, how wide it hides (radius).
    LC.PhotoCover = {
        { { "models/props_interiors/bathtub01a.mdl" }, 3, 90 }, { { "models/props_junk/shoe001a.mdl" }, 14, 80 },
        { { "models/props_junk/watermelon01.mdl" }, 7, 75 }, { { "models/props_junk/popcan01a.mdl" }, 16, 60 },
        { { "models/props_c17/doll01.mdl" }, 10, 60 }, { { "models/props_c17/furnituretoilet001a.mdl" }, 3, 70 },
    }
    LC.PhotoCaptions = { "a citizen pretending to be a lamp", "someone's elbow, very close", "a blur that might be you", "a perfectly ordinary toilet, enormous",
        "the back of a head, triumphant", "nobody at all (good)", "a shoe the size of a house, and a terrified face" }

    -- Is the dreamer at pos hidden from the scanner at cam (something giant in between)?
    function LC.PhotoHidden(g, cam, pos)
        local dx, dy = pos.x - cam.x, pos.y - cam.y
        local l2 = dx * dx + dy * dy
        if l2 < 1 then return false end
        for _, c in ipairs(g.cover) do
            local t = ((c.pos.x - cam.x) * dx + (c.pos.y - cam.y) * dy) / l2
            if t > 0 and t < 1 then
                local px, py = cam.x + dx * t, cam.y + dy * t
                if (c.pos.x - px) ^ 2 + (c.pos.y - py) ^ 2 < c.r * c.r then return true end
            end
        end
        return false
    end

    function def.build(g, dream)
        Plain(g, dream, 3, function(i, j) return (i + j) % 2 == 0 and Color(235, 235, 235) or Color(30, 30, 30) end)
        local c = dream.pos
        g.cover = {}
        for i, cv in ipairs(LC.PhotoCover) do
            local a = (i - 1) / #LC.PhotoCover * math.pi * 2 + 0.3
            local at = Vector(c.x + math.cos(a) * g.half * 0.45, c.y + math.sin(a) * g.half * 0.45, g.top)
            local e = Actor(g, FirstModel(cv[1]), at, math.Rand(0, 360), cv[2], nil)
            Tint(e, Rainbow(i / #LC.PhotoCover))
            g.cover[i] = { pos = at, r = cv[3], ent = e }
        end
        g.scanner = Actor(g, "models/combine_scanner.mdl", c + Vector(g.half, 0, 260), 180, 4, nil)
        g.camA, g.shots, g.phase, g.at = 0, 0, "roam", CurTime() + 6
        Ring(g, 80)
        return true
    end
    def.spawn = SpawnAt
    def.hello = function(g) SayLater(g, 1.5, "photo_hello") return { theme = "photo" } end

    function def.tick(g, dt, players)
        local now = CurTime()
        local c = g.dream.pos
        if g.phase ~= "warn" then g.camA = g.camA + dt * 0.35 end
        g.cam = Vector(c.x + math.cos(g.camA) * (g.half - 20), c.y + math.sin(g.camA) * (g.half - 20), g.top + 260 + math.sin(now) * 30)
        if IsValid(g.scanner) then g.scanner:SetPos(g.cam) g.scanner:SetAngles(Angle(20, math.deg(g.camA) + 180, 0)) end
        if now < g.at then return end
        if g.phase == "roam" then
            if g.shots >= LC.PhotoShots then
                for _, p in ipairs(players) do Done(g, p, "won", "Camera shy", "Ten flashes and not one good picture of you. The scanner sulks off.") end
                return
            end
            g.phase, g.at, g.dirty = "warn", now + LC.PhotoWarn, true
            SayAs(g, "photo_cheese")
            if IsValid(g.scanner) then Snd(g.scanner, "npc/scanner/scanner_photo1.wav", 95, 100) end
        elseif g.phase == "warn" then
            g.shots, g.flash, g.dirty = g.shots + 1, now, true
            if IsValid(g.scanner) then Snd(g.scanner, "npc/scanner/scanner_photo1.wav", 110, 70) end
            local snapped = 0
            for _, p in ipairs(players) do
                if not LC.PhotoHidden(g, g.cam, p:GetPos()) then
                    snapped = snapped + 1
                    Hit(g, p, "Snapped!", "It got a picture of you: " .. LC.PhotoCaptions[math.random(#LC.PhotoCaptions)] .. ".")
                end
            end
            g.phase, g.at = "roam", now + math.Rand(4, 7)
        end
    end

    function def.state(g, p)
        local big, tone
        if g.phase == "warn" then
            big, tone = "SAY CHEESE! Hide behind something giant!", "warn"
            if p and g.cam and LC.PhotoHidden(g, g.cam, p:GetPos()) then big, tone = "Hidden... stay there!", nil end
        end
        return { big = big, tone = tone, flash = g.flash, scanner = IsValid(g.scanner) and g.scanner:EntIndex() or nil,
            meterName = string.format("Flashes: %d of %d", g.shots, LC.PhotoShots) }
    end
end

------------------------------------------------------------------------
-- The Doors
------------------------------------------------------------------------

do
    LC.DoorRounds, LC.DoorListen, LC.DoorShow = 6, 12, 4
    LC.DoorBehind = { "a horse eating a wheel of cheese", "a smaller door", "your old school headmaster, crying", "the sea, standing up",
        "a headcrab in a tiny hat", "nothing, but loudly", "another dream, which is rude", "Doctor Breen's laundry", "a staircase to the floor" }
    local def = { id = "doors", name = "The Doors", mood = "neutral", lives = 3, ownMusic = true,
        secs = 6 + LC.DoorRounds * (LC.DoorListen + LC.DoorShow) + 4,
        goal = "Six doors, and behind one a music box plays. Listen. Stand at the right door before time's up.",
        timeUp = { "The doors close", "All six doors close at once, and the dream with them." },
        woke = Woke({ name = "The Doors",
            won = { "The right door", "You wake up and walk straight to the right door in your house, first time. Which is the front door. Well done." },
            out = { "The wrong door", "You wake up still hearing a music box from somewhere you can't find." },
            time = { "The doors close", "You wake up listening hard for a tune that isn't there." },
        }) }
    G.doors = def
    local DOOR = { "models/props_c17/door01_left.mdl", "models/props_doors/door03_slotted_left.mdl" }
    local TUNE = { "buttons/bell1.wav", "buttons/blip1.wav", "buttons/button17.wav" }

    function def.build(g, dream)
        Plain(g, dream, 2, function(i, j) return (i + j) % 2 == 0 and Color(40, 40, 60) or Color(50, 30, 60) end)
        local c = dream.pos
        g.doors = {}
        local m = FirstModel(DOOR)
        for i = 1, 6 do
            local a = (i - 1) / 6 * math.pi * 2
            local at = Vector(c.x + math.cos(a) * 270, c.y + math.sin(a) * 270, g.top)
            local e = Actor(g, m, at, math.deg(a) + 180, 1.2, nil)
            Tint(e, Rainbow((i - 1) / 6))
            g.doors[i] = { pos = at, ent = e }
        end
        g.round, g.phase, g.at = 0, "wait", CurTime() + 6
        Ring(g, 60)
        return true
    end
    def.spawn = SpawnAt
    def.hello = function(g) SayLater(g, 1, "doors_hello") return { theme = "doors" } end

    function LC.DoorAt(g, pos)
        for i, d in ipairs(g.doors) do if Dist2(pos, d.pos) < 80 then return i end end
        return nil
    end

    function def.tick(g, dt, players)
        local now = CurTime()
        if g.phase == "listen" and now >= g.tune then -- (the music box, behind the right door only)
            local d = g.doors[g.right]
            if d and IsValid(d.ent) then Snd(d.ent, TUNE[(g.note % #TUNE) + 1], 70, ({ 100, 112, 126, 133, 150, 126, 112 })[(g.note % 7) + 1]) end
            g.note, g.tune = g.note + 1, now + 0.45
        end
        if now < g.at then return end
        if g.phase == "wait" or g.phase == "show" then
            if g.round >= LC.DoorRounds then
                for _, p in ipairs(players) do Done(g, p, "won", "The right door", "Every time, the right door. The music box plays you out of the dream.") end
                return
            end
            g.round, g.right, g.note, g.tune = g.round + 1, math.random(6), 0, now + 0.5
            g.phase, g.at, g.dirty = "listen", now + LC.DoorListen, true
        elseif g.phase == "listen" then
            for _, p in ipairs(players) do
                local at = LC.DoorAt(g, p:GetPos())
                if at ~= g.right then
                    Hit(g, p, "The wrong door", at and ("Behind it: " .. LC.DoorBehind[math.random(#LC.DoorBehind)] .. ".") or "You didn't choose a door at all.")
                end
            end
            g.phase, g.at, g.dirty = "show", now + LC.DoorShow, true
            SayAs(g, "doors_open")
        end
    end

    function def.state(g, p)
        local glows = {}
        for i, d in ipairs(g.doors) do glows[#glows + 1] = Flat(d.pos + Vector(0, 0, 60), (g.phase == "show" and i == g.right) and 5 or 6) end
        local big
        if g.phase == "listen" then
            local at = p and LC.DoorAt(g, p:GetPos())
            big = (at and "You're at a door. Is the music coming from here?" or "Listen for the music box. Stand at its door.") .. string.format(" (%d)", Left(g))
        elseif g.phase == "show" then big = "That was the one." end
        return { glows = glows, big = big, meterName = string.format("Round %d of %d", math.max(1, g.round), LC.DoorRounds) }
    end
end

------------------------------------------------------------------------
-- Splat!
------------------------------------------------------------------------

do
    LC.PaintGrid = 6
    LC.PaintColours = { { "pink", Color(255, 80, 180) }, { "lime", Color(140, 255, 60) }, { "sky blue", Color(80, 200, 255) }, { "orange", Color(255, 150, 30) },
        { "purple", Color(170, 80, 255) }, { "yellow", Color(255, 240, 60) }, { "red", Color(255, 50, 50) }, { "teal", Color(40, 220, 190) } }
    local def = { id = "paint", name = "Splat!", mood = "happy", secs = 100, lives = 1,
        goal = "Every tile you step on takes your colour. Hold your share of the floor when the bell goes.",
        timeUp = { "The paint dries", "The paint dries and you wake." },
        woke = Woke({ name = "Splat!",
            won = { "A masterpiece", "You wake up with paint on your feet. No. Just a dream. Your feet are fine. Mostly." },
            out = { "Painted over", "You wake up feeling slightly beige." },
            time = { "The paint dries", "You wake up seeing colours that don't have names." },
        }) }
    G.paint = def

    -- How many tiles you need to hold: your share of the floor (36 split among the dreamers and one more), at least 8.
    function LC.PaintNeed(n) return math.max(8, math.floor(LC.PaintGrid * LC.PaintGrid / (math.max(1, n or 1) + 1))) end

    function def.build(g, dream)
        Plain(g, dream, 3, function() return Color(240, 240, 240) end)
        local c = dream.pos
        g.tiles = {}
        local step = PLATE4_S
        local x0, y0 = c.x - (LC.PaintGrid - 1) * step / 2, c.y - (LC.PaintGrid - 1) * step / 2
        for i = 1, LC.PaintGrid do for j = 1, LC.PaintGrid do
            local at = Vector(x0 + (i - 1) * step, y0 + (j - 1) * step, g.top)
            local e = Block(g, PLATE4, at + Vector(0, 0, 1), Angle(0, 0, 0), Color(250, 250, 250), "models/debug/debugwhite")
            if IsValid(e) then e.lcKeepLook = true end -- (whose colour it is must show)
            g.tiles[#g.tiles + 1] = { pos = at, ent = e }
        end end
        g.half2 = LC.PaintGrid * step / 2
        g.colourOf, g.nextColour = {}, 1
        Ring(g, 150)
        return true
    end
    function def.spawn(g, p, i)
        g.colourOf[p] = ((i - 1) % #LC.PaintColours) + 1
        return SpawnAt(g, p, i)
    end
    def.hello = function(g) SayLater(g, 1, "paint_hello") return { theme = "paint" } end

    function LC.PaintTileOf(g, pos)
        for k, t in ipairs(g.tiles) do
            if math.abs(pos.x - t.pos.x) < PLATE4_S / 2 and math.abs(pos.y - t.pos.y) < PLATE4_S / 2 then return k end
        end
        return nil
    end
    function LC.PaintCount(g, p) local n = 0 for _, t in ipairs(g.tiles) do if t.by == p then n = n + 1 end end return n end

    function def.tick(g, dt, players)
        local now = CurTime()
        g.need = g.need or LC.PaintNeed(#players)
        for _, p in ipairs(players) do
            local k = LC.PaintTileOf(g, p:GetPos())
            local t = k and g.tiles[k]
            if t and t.by ~= p then
                t.by, g.dirty = p, true
                local col = LC.PaintColours[g.colourOf[p] or 1][2]
                if IsValid(t.ent) then t.ent:SetColor(col) end
                if math.random() < 0.3 then Snd(p, "physics/flesh/flesh_squishy_impact_hard" .. math.random(1, 4) .. ".wav", 55, 150) end
            end
        end
        if now >= g.ends - 0.5 and not g.scored then
            g.scored = true
            for _, p in ipairs(players) do
                local n = LC.PaintCount(g, p)
                if n >= g.need then Done(g, p, "won", "A masterpiece", string.format("%d tiles in your colour when the bell went.", n))
                else Done(g, p, "out", "Painted over", string.format("%d tiles, of the %d it took.", n, g.need)) end
            end
        end
    end

    function def.state(g, p)
        local n = p and LC.PaintCount(g, p) or 0
        local c = p and LC.PaintColours[g.colourOf[p] or 1] or LC.PaintColours[1]
        return { big = (CurTime() < g.t0 + 6) and ("You're " .. c[1] .. "! Paint the floor.") or nil, colour = { c[2].r, c[2].g, c[2].b },
            meter = math.floor(math.min(1, n / math.max(1, g.need or 18)) * 100), meterName = string.format("Your tiles: %d (you need %d)", n, g.need or LC.PaintNeed(1)) }
    end
end

------------------------------------------------------------------------
-- Conga!
------------------------------------------------------------------------

do
    LC.CongaGain, LC.CongaReach = 9, 85 -- (groove a second in the glow, and how close counts)
    local def = { id = "conga", name = "Conga!", mood = "happy", secs = 120, lives = 1, need = 100,
        goal = "Join the conga! Keep in the glow at the tail of the line to fill your groove.",
        timeUp = { "The music stops", "The conga line dances off into the distance, and you wake." },
        woke = Woke({ name = "Conga!",
            won = { "Groovy", "You wake up and your hips are still going. One, two, three, kick." },
            time = { "The line moves on", "You wake up humming a conga. One, two, three, kick." },
        }) }
    G.conga = def
    LC.CongaDancers = { { "models/humans/group01/female_02.mdl", 1 }, { "models/headcrabclassic.mdl", 2 }, { "models/humans/group01/male_07.mdl", 1 },
        { "models/props_junk/watermelon01.mdl", 2.5 }, { "models/kleiner.mdl", 1 }, { "models/props_c17/chair02a.mdl", 1.4 }, { "models/humans/group01/male_02.mdl", 1 } }

    -- Where the line's head is at time t: a loop round the floor (a figure of eight).
    function LC.CongaPath(g, t)
        local c, r = g.dream.pos, g.half * 0.6
        return Vector(c.x + math.sin(t) * r, c.y + math.sin(t * 2) * r * 0.6, g.top)
    end
    local GAP = 0.18

    function def.build(g, dream)
        Plain(g, dream, 3, function(i, j) return (i + j) % 2 == 0 and Color(255, 230, 120) or Color(255, 170, 120) end)
        g.dancers = {}
        for i, d in ipairs(LC.CongaDancers) do
            local e = Actor(g, FirstModel({ d[1], "models/humans/group01/male_09.mdl" }), dream.pos, 0, d[2], ACT_WALK or ACT_IDLE or 1)
            g.dancers[i] = e
        end
        g.u = 0
        Ring(g, 300)
        return true
    end
    def.spawn = SpawnAt
    def.hello = function(g) SayLater(g, 1, "conga_hello") return { theme = "conga" } end

    function def.tick(g, dt, players)
        local now = CurTime()
        local speed = 0.25 + 0.15 * math.min(1, (now - g.t0) / 90)
        g.u = g.u + dt * speed
        local ents_ = {}
        for i, e in ipairs(g.dancers) do
            local u = g.u - (i - 1) * GAP
            local pos = LC.CongaPath(g, u)
            local ahead = LC.CongaPath(g, u + 0.02)
            if IsValid(e) then
                e:SetPos(pos + Vector(0, 0, math.abs(math.sin(now * 6 + i)) * 12))
                e:SetAngles(Angle(0, Yaw(pos, ahead), math.sin(now * 6 + i) * 12))
                ents_[#ents_ + 1] = e:EntIndex()
            end
        end
        g.ents_ = ents_
        g.tail = LC.CongaPath(g, g.u - #g.dancers * GAP)
        for _, p in ipairs(players) do
            local s = g.pl[p]
            s.groove = s.groove or 0
            local inside = Dist2(p:GetPos(), g.tail) < LC.CongaReach
            if inside ~= s.inside then s.inside, g.dirty = inside, true end
            if inside then
                s.groove = s.groove + LC.CongaGain * dt
                if s.groove >= def.need then Done(g, p, "won", "Groovy", "You've got the groove. The whole line, the headcrab and the watermelon included, cheers.") end
            end
        end
    end

    function def.state(g, p)
        local s = p and g.pl[p] or {}
        local glows = g.tail and { Flat(g.tail + Vector(0, 0, 10), 4) } or {}
        return { glows = glows, conga = g.ents_, big = s.inside and "Conga! One, two, three, kick!" or "Get in the glow at the back of the line!",
            meter = math.floor(math.min(100, s.groove or 0)), meterName = string.format("Groove: %d%%", math.floor(math.min(100, s.groove or 0))) }
    end
end

------------------------------------------------------------------------
-- Shh!
------------------------------------------------------------------------

do
    LC.ShhLoud, LC.ShhRun, LC.ShhJump, LC.ShhFade = 100, 22, 15, 10 -- (meter full at; per second running; per jump; fading per second)
    LC.ShhFast = 140 -- (moving faster than this is running)
    local def = { id = "shh", name = "Shh!", mood = "neutral", secs = 150, lives = 3, need = 6,
        goal = "A giant baby is asleep. Gather six toys, quietly: running and jumping make noise. If the baby wakes, everyone loses a life. Crouch-walk.",
        timeUp = { "Morning", "The baby wakes up for good, and so do you." },
        woke = Woke({ name = "Shh!",
            won = { "Quiet as a mouse", "You wake up and tiptoe to the bathroom without knowing why." },
            out = { "WAAAH", "You wake up to a crying you can't place. Nobody else heard it." },
            time = { "Morning", "You wake up sure you have to be very, very quiet. You don't." },
        }) }
    G.shh = def

    function def.build(g, dream)
        Plain(g, dream, 3, function(i, j) return (i + j) % 2 == 0 and Color(200, 220, 255) or Color(255, 220, 235) end)
        local c = dream.pos
        g.baby = Actor(g, FirstModel({ "models/props_c17/doll01.mdl" }), c + Vector(0, 0, 20), 0, 12, nil)
        if IsValid(g.baby) then g.baby:SetAngles(Angle(0, 0, 90)) end
        g.mobile = {}
        for i = 1, 5 do
            local e = Actor(g, "models/headcrabclassic.mdl", c, 0, 1.3, nil)
            Tint(e, Rainbow(i / 5))
            g.mobile[i] = e
        end
        g.toys = {}
        for i = 1, 8 do g.toys[i] = { pos = AnyWhere(g, 100) + Vector(0, 0, 24) } end
        g.noise, g.wake = 0, 0
        Ring(g, g.half * 0.8)
        return true
    end
    def.spawn = SpawnAt
    def.hello = function(g) SayLater(g, 1, "shh_hello") return { theme = "shh" } end

    function def.tick(g, dt, players)
        local now = CurTime()
        local t = now - g.t0
        for i, e in ipairs(g.mobile) do -- (the mobile turning over the crib)
            if IsValid(e) then
                local a = t * 0.5 + i / 5 * math.pi * 2
                e:SetPos(g.dream.pos + Vector(math.cos(a) * 90, math.sin(a) * 90, 260 + math.sin(t + i) * 10))
                e:SetAngles(Angle(0, math.deg(a) + 90, 0))
            end
        end
        if now < g.wake then return end -- (crying: nothing else happens for a moment)
        g.noise = math.max(0, g.noise - LC.ShhFade * dt)
        for _, p in ipairs(players) do
            local s = g.pl[p]
            s.got = s.got or 0
            if not Crouched(p) and Speed2D(p) > LC.ShhFast then g.noise = g.noise + LC.ShhRun * dt end
            if JumpPressed(s, p) then g.noise = g.noise + LC.ShhJump end
            for _, toy in ipairs(g.toys) do
                if not toy.gone and toy.pos:Distance(p:GetPos() + Vector(0, 0, 24)) < 50 then
                    toy.gone, g.dirty = now + 5, true
                    s.got = s.got + 1
                    Snd(p, "buttons/button14.wav", 45, 140)
                    if s.got >= def.need then Done(g, p, "won", "Quiet as a mouse", "Six toys, and not a peep. The baby smiles in its sleep.") end
                    break
                end
            end
        end
        for _, toy in ipairs(g.toys) do if toy.gone and now >= toy.gone then toy.gone, toy.pos, g.dirty = nil, AnyWhere(g, 100) + Vector(0, 0, 24), true end end
        if g.noise >= LC.ShhLoud then
            g.noise, g.wake, g.dirty = 0, now + 4, true
            if IsValid(g.baby) then Snd(g.baby, "npc/stalker/go_alert2a.wav", 120, 170) end
            SayAs(g, "shh_wake")
            for _, p in ipairs(players) do g.pl[p].safe = 0 Hit(g, p, "WAAAH!", "The baby woke up. Everyone heard it. Everyone.") end
        end
    end

    function def.state(g, p)
        local s = p and g.pl[p] or {}
        local glows = {}
        for _, toy in ipairs(g.toys) do if not toy.gone then glows[#glows + 1] = Flat(toy.pos, 4) end end
        local crying = CurTime() < g.wake
        return { glows = glows, noise = math.floor(g.noise), crying = crying, big = crying and "WAAAAAH!" or (g.noise > 60 and "Shhh! Too loud!" or nil), tone = "warn",
            meter = math.floor(math.min(1, (s.got or 0) / def.need) * 100), meterName = string.format("Toys: %d of %d     Noise: %d%%", s.got or 0, def.need, math.floor(g.noise)) }
    end
end

------------------------------------------------------------------------
-- Bubbles
------------------------------------------------------------------------

do
    LC.BubbleRise, LC.BubbleLife = 45, 14 -- (how fast they rise, and for how long)
    LC.BubbleGravity = 0.6
    local def = { id = "bubbles", name = "Bubbles", mood = "happy", secs = 150, lives = 1, need = 15, leave = Leave,
        goal = "Pop the bubbles (touch them). Golden ones count three. Big pale ones carry you up to the high ones.",
        timeUp = { "Pop", "The last bubble pops, and so does the dream." },
        woke = Woke({ name = "Bubbles",
            won = { "Bubbly", "You wake up light and fizzy, like you're full of bubbles. You probably aren't." },
            time = { "Pop", "You wake up with the feeling of something just popping." },
        }) }
    G.bubbles = def

    -- Where a bubble is now (it rises, and sways).
    function LC.BubbleAt(b, now)
        local t = now - b.t0
        return Vector(b.x + math.sin(t * 1.3 + b.x) * 30, b.y + math.cos(t * 1.1 + b.y) * 30, b.z + t * LC.BubbleRise)
    end
    local function NewBubble(g, i, now)
        local at = AnyWhere(g, 80)
        local r = math.random()
        g.bubbles[i] = { x = at.x, y = at.y, z = g.top + 30, t0 = now, kind = r < 0.1 and 2 or (r < 0.25 and 3 or 1) } -- (1 plain, 2 golden, 3 a lift)
    end

    function def.build(g, dream)
        Plain(g, dream, 3, function(i, j) return Rainbow((i + j) / 6, 255) end)
        g.bubbles = {}
        local now = CurTime()
        for i = 1, 18 do NewBubble(g, i, now - math.Rand(0, LC.BubbleLife)) end
        Ring(g, 160)
        return true
    end
    function def.spawn(g, p, i) Light(p, LC.BubbleGravity) return SpawnAt(g, p, i) end
    def.hello = function(g) SayLater(g, 1, "bubbles_hello") return { theme = "bubbles" } end

    function def.tick(g, dt, players)
        local now = CurTime()
        for i, b in ipairs(g.bubbles) do if now - b.t0 > LC.BubbleLife then NewBubble(g, i, now) g.dirty = true end end
        for _, p in ipairs(players) do
            local s = g.pl[p]
            s.got = s.got or 0
            local mid = p:GetPos() + Vector(0, 0, 36)
            for i, b in ipairs(g.bubbles) do
                local at = LC.BubbleAt(b, now)
                if at:Distance(mid) < (b.kind == 3 and 70 or 50) then
                    if b.kind == 3 and p.SetVelocity then p:SetVelocity(Vector(0, 0, 520)) end
                    s.got = s.got + (b.kind == 2 and 3 or (b.kind == 3 and 0 or 1))
                    Snd(p, "garrysmod/balloon_pop_cute.wav", 70, math.random(90, 130))
                    NewBubble(g, i, now)
                    g.dirty = true
                    if s.got >= def.need then Done(g, p, "won", "Bubbly", "Fifteen bubbles popped. The dream fizzes and lifts you out of it.") end
                    break
                end
            end
        end
    end

    function def.state(g, p)
        local s = p and g.pl[p] or {}
        local list = {}
        for _, b in ipairs(g.bubbles) do list[#list + 1] = { math.floor(b.x), math.floor(b.y), math.floor(b.z), b.t0, b.kind } end
        return { bubbles = list, rise = LC.BubbleRise,
            meter = math.floor(math.min(1, (s.got or 0) / def.need) * 100), meterName = string.format("Popped: %d of %d", math.min(s.got or 0, def.need), def.need) }
    end
end

------------------------------------------------------------------------
-- The Watchers
------------------------------------------------------------------------

do
    LC.WatcherCount, LC.WatcherSpeed = 5, 120
    local def = { id = "watchers", name = "The Watchers", mood = "nightmare", secs = 180, lives = 3, need = 6,
        goal = "Tall black figures, and they only move while nobody is looking at them. Gather six glowing keys. Don't let one touch you.",
        timeUp = { "Morning comes", "Grey light, and the figures are gone. You wake, and don't look at the corner of the room." } }
    G.watchers = def

    local function Edge(g)
        local c, h = g.dream.pos, g.half - 40
        local a = math.Rand(0, math.pi * 2)
        return Vector(c.x + math.cos(a) * h, c.y + math.sin(a) * h, g.top)
    end

    function def.build(g, dream)
        Plain(g, dream, 3, function(i, j) return (i + j) % 2 == 0 and Color(25, 25, 30) or Color(35, 30, 35) end)
        g.watch = {}
        for i = 1, LC.WatcherCount do
            local at = Edge(g)
            local e = Actor(g, CITIZENS[(i - 1) % #CITIZENS + 1], at, 0, 1.8, ACT_IDLE or 1)
            Tint(e, Color(5, 5, 8))
            if IsValid(e) then e.lcKeepLook = true end -- (black, always)
            g.watch[i] = { ent = e, pos = at }
        end
        g.keys = {}
        for i = 1, 3 do g.keys[i] = { pos = AnyWhere(g, 100) + Vector(0, 0, 30) } end
        Ring(g, 60)
        return true
    end
    def.spawn = SpawnAt
    def.hello = function(g) SayLater(g, 2, "watchers_hello") return { theme = "watchers" } end

    -- Is anyone looking at this one?
    function LC.WatcherSeen(players, pos)
        for _, p in ipairs(players) do if Facing(p, pos) then return true end end
        return false
    end

    function def.tick(g, dt, players)
        local now = CurTime()
        local moving = 0
        for _, w in ipairs(g.watch) do
            local seen = LC.WatcherSeen(players, w.pos)
            if not seen and now > g.t0 + 3 then
                local target = Nearest(players, w.pos)
                if target then
                    local d = target:GetPos() - w.pos
                    local l = math.sqrt(d.x * d.x + d.y * d.y)
                    if l > 1 then w.pos = w.pos + Vector(d.x / l, d.y / l, 0) * math.min(l, LC.WatcherSpeed * dt) end
                    if IsValid(w.ent) then w.ent:SetAngles(Angle(0, Yaw(w.pos, target:GetPos()), 0)) end
                    moving = moving + 1
                end
            end
            if IsValid(w.ent) then w.ent:SetPos(w.pos) end
        end
        g.moving = moving
        for _, p in ipairs(players) do
            local s = g.pl[p]
            s.got = s.got or 0
            local pp = p:GetPos()
            for _, w in ipairs(g.watch) do
                if Dist2(pp, w.pos) < 50 then
                    if Hit(g, p, "Touched", "A cold hand, from behind.") then w.pos = Edge(g) end
                    break
                end
            end
            if not s.done then
                for _, k in ipairs(g.keys) do
                    if k.pos:Distance(pp + Vector(0, 0, 30)) < 50 then
                        s.got = s.got + 1
                        k.pos, g.dirty = AnyWhere(g, 100) + Vector(0, 0, 30), true
                        Snd(p, "buttons/button3.wav", 60, 70)
                        if s.got >= def.need then Done(g, p, "won", "You got out", "The sixth key turns in a door you hadn't seen, and you're out. Don't look back.") end
                        break
                    end
                end
            end
        end
    end

    function def.state(g, p)
        local s = p and g.pl[p] or {}
        local glows = {}
        for _, k in ipairs(g.keys) do glows[#glows + 1] = Flat(k.pos, 5) end
        local ws = {}
        for _, w in ipairs(g.watch) do if IsValid(w.ent) then ws[#ws + 1] = w.ent:EntIndex() end end
        return { glows = glows, watchers = ws, big = (g.moving or 0) > 0 and "Something moved." or nil, tone = "warn",
            meter = math.floor(math.min(1, (s.got or 0) / def.need) * 100), meterName = string.format("Keys: %d of %d", math.min(s.got or 0, def.need), def.need) }
    end
end

------------------------------------------------------------------------
-- Every line said in these dreams (to record: docs/features/dream-lines.md)
------------------------------------------------------------------------

LC.StrangeAddCues({
    clocks_hello = { "The Clock Voice", "Tick. Tock. Tick. Tock. It's later than you think. It's earlier than you think. It's cheese.", "a slow, deep, echoing voice, like a grandfather clock talking in its sleep" },
    clocks_won = { "The Clock Voice", "Time... stops.", "the clock voice, slowing down to nothing" },
    tea_hello = { "The Host", "Welcome, welcome! No room! No room! Sit anywhere. No, not there.", "a manic, posh, very old-fashioned tea-party host, talking far too fast" },
    tea_down1 = { "The Host", "Change places! Move down one!", "the posh host, shrieking with delight" },
    tea_down2 = { "The Host", "Change places! Move down two!", "the posh host, shrieking with delight" },
    tea_down3 = { "The Host", "Change places! Move down three!", "the posh host, shrieking with delight" },
    tea_up = { "The Host", "Clean cup! Clean cup! Move up!", "the posh host, outraged" },
    derby_hello = { "The Commentator", "Welcome to the Headcrab Derby! Place your bets, place your bets!", "a breathless horse-racing commentator" },
    derby_off = { "The Commentator", "And they're off!", "the racing commentator, at full gallop" },
    derby_win1 = { "The Commentator", "And it's Lamarr's Cousin by a leg! It only has legs!", "the racing commentator, ecstatic" },
    derby_win2 = { "The Commentator", "Hooves wins it! Hooves! A headcrab called Hooves!", "the racing commentator, baffled and thrilled" },
    derby_win3 = { "The Commentator", "Mister Leg takes it! Mister Leg, everybody!", "the racing commentator, screaming" },
    derby_win4 = { "The Commentator", "Breen's Toupee! Breen's Toupee wins the Derby!", "the racing commentator, losing his mind" },
    photo_hello = { "The Scanner", "Hello! Hello! Lovely day for a photograph! Everybody smile!", "a chirpy robotic camera voice, slightly glitchy" },
    photo_cheese = { "The Scanner", "Say cheese!", "the chirpy robot camera, sing-song" },
    doors_hello = { "A Little Voice", "Six doors. One plays a song. Listen... listen...", "a small, sweet, slightly eerie child's voice, whispering" },
    doors_open = { "A Little Voice", "That one. It was always that one.", "the eerie child's voice, giggling" },
    paint_hello = { "The Painter", "A blank canvas! Make it yours! Splat!", "an over-the-top, flamboyant artist" },
    conga_hello = { "The Bandleader", "Everybody conga! One, two, three, kick!", "a jolly big-band leader, shouting over brass" },
    shh_hello = { "A Whisper", "Shhhh. The baby's sleeping. Don't wake the baby.", "a very quiet, tense whisper" },
    shh_wake = { "A Whisper", "You woke the baby.", "the whisper, cold and disappointed" },
    bubbles_hello = { "A Bubbly Voice", "Pop! Pop! Pop them all!", "a giggly, bubbly, high-pitched voice" },
    watchers_hello = { "A Whisper", "They don't move while you watch them. You can't watch them all.", "a slow, hollow whisper, very close to the ear" },
})
