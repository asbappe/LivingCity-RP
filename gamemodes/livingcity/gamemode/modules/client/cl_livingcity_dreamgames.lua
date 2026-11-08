--[[
    Living City: the nightmare dreams you play, your side (sv_livingcity_dreamgames.lua)

      While you're in one: its name, what to do, your lives and the time left, at the top of the
      screen. The Patrol Maze's tokens glow in the corridors (golden ones pulse), and the screen
      goes cold blue while the officers are afraid. Freeze, Citizen says when to stop, in red.
      Out of lives, or won: wake up now, or watch the rest until it's over.
      Propaganda dreams (sv_livingcity_propagandadreams.lua): the admiring ones go pink (hearts
      drifting up from her, glowing roses, a meter: Devotion, Roses, Adoration); The Saviour goes
      gold, with a heavenly glow round her and a column of light as she comes down; the quiz goes
      red and gold. Her lines come up at the bottom of the screen, with her recording if there is
      one; the music plays if the owner put any in sound/livingcity/dreams/. The Administrator,
      starring, is told so.
      The ten more (sv_livingcity_propagandamore.lua): glowing things to pick up or stand at
      (crates, scrap, work stations, tables), boards hanging in the air (the quota board, the
      production norm, the enemy of the people on his screen), her portrait in cards growing
      picture by picture in the Mass Games, clues overheard in Careless Talk, the screen black and
      white in the Newsreel, "NOW!" as a soldier passes you in Flowers for the Liberators, and the
      rebels' rocket climbing on its flame in Duck and Cover. Careless Talk and the Newsreel show
      everyone's pick or take at the reveal.
]]

LC_CL = LC_CL or {}

local st -- the game you're in, as the server last said
local choice -- the "wake up, or watch?" window

local function CloseChoice() if IsValid(choice) then choice:Remove() end choice = nil end
-- The music (propaganda dreams), looping until the dream's over for you.
local song
local function StopSong() if IsValid(song) then song:Stop() end song = nil end
local function PlaySong(path, want)
    StopSong()
    if not path or path == "" or not (sound and sound.PlayFile) then return end
    sound.PlayFile("sound/" .. path, "noblock", function(ch)
        if not IsValid(ch) then return end
        if st ~= want then ch:Stop() return end -- (it's over already)
        song = ch
        if ch.EnableLooping then ch:EnableLooping(true) end
        if ch.SetVolume then ch:SetVolume(0.8) end
        ch:Play()
    end)
end
LC_CL.DreamGameSongStop = StopSong
function LC_CL.DreamGameSongChannel() return song end -- (the strange dreams wobble it: cl_livingcity_strangedreams.lua)
-- Her lines: the words at the bottom of the screen, and her recording.
local sub, voice
local function StopVoice() if IsValid(voice) then voice:Stop() end voice = nil end
local function SayLine(t)
    sub = { who = t.who, text = t.text or "", til = CurTime() + math.Clamp(3 + #(t.text or "") / 18, 4, 9) }
    if not t.snd or t.snd == "" or not (sound and sound.PlayFile) then return end
    StopVoice()
    sound.PlayFile("sound/" .. t.snd, "noblock", function(ch)
        if not IsValid(ch) then return end
        if not st then ch:Stop() return end
        voice = ch
        ch:Play()
    end)
end
-- Out of it (or won): wake now, or watch the rest.
function LC_CL.DreamGameChoice(t)
    CloseChoice()
    local f = vgui.Create("DFrame")
    choice = f
    f:SetSize(420, 170)
    f:Center()
    f:SetTitle(t.title or "Out of it")
    f:MakePopup()
    local l = vgui.Create("DLabel", f)
    l:Dock(TOP)
    l:DockMargin(8, 4, 8, 4)
    l:SetWrap(true)
    l:SetAutoStretchVertical(true)
    l:SetText((t.text or "") .. "\n\nWake up now, or watch the rest until it's over? (You wake in your bed with everything you had either way.)")
    local row = vgui.Create("DPanel", f)
    row:Dock(BOTTOM)
    row:SetTall(30)
    row.Paint = function() end
    local wake = vgui.Create("DButton", row)
    wake:Dock(LEFT)
    wake:SetWide(200)
    wake:SetText("Wake up now")
    wake.DoClick = function() CloseChoice() if LC_CL.DreamAct then LC_CL.DreamAct("wake") end end
    local watch = vgui.Create("DButton", row)
    watch:Dock(RIGHT)
    watch:SetWide(200)
    watch:SetText("Watch until it's over")
    watch.DoClick = CloseChoice
end

net.Receive("lc_dreamgame", function()
    local t = net.ReadTable() or {}
    if t.k == "start" then
        st = t
        st.got = {}
        StopSong()
        if t.song then PlaySong(t.song, st) end
    elseif t.k == "line" then
        if st then SayLine(t) end
    elseif t.k == "music" then
        if st then PlaySong(t.song, st) end
    elseif t.k == "got" then
        if st and st.got then st.got[t.i] = true st.left = math.max(0, (st.left or 1) - 1) end
    elseif t.k == "state" then
        if st then for k, v in pairs(t) do if k ~= "k" then st[k] = v end end end
    elseif t.k == "out" then
        if st then st.out = t.how or "out" end
        LC_CL.DreamGameChoice(t)
    elseif t.k == "stop" then
        st, sub = nil, nil
        StopSong()
        StopVoice()
        CloseChoice()
    end
end)
function LC_CL.DreamGame() return st end

local glow = Material("sprites/light_glow02_add")
local BLUE, GOLD = Color(120, 210, 255), Color(255, 205, 70)
local PINK, ROSE = Color(255, 120, 190), Color(255, 40, 90)
local HALO, PROP = Color(255, 240, 200), Color(255, 70, 60)
-- the glows' colours: a crate, a spoiled crate, scrap, a flower, somewhere to stand, white
local GLOWS = { Color(255, 205, 70), Color(140, 220, 60), Color(150, 190, 230), Color(255, 120, 190), Color(90, 255, 140), Color(255, 255, 255), Color(255, 40, 40) }
local THEMES = { harvest = Color(255, 205, 70), newsreel = Color(235, 235, 235), hate = Color(255, 60, 50), civil = Color(140, 210, 255), graveyard = Color(200, 60, 60),
    cheese = Color(255, 215, 70), chairs = Color(255, 170, 210), flying = Color(150, 215, 255), melons = Color(140, 230, 110) } -- (the strange dreams: cl_livingcity_strangedreams.lua)
-- Where she is: her figure or the star (as an entity, when you can see it), else where she was.
local function HerPos()
    local e = st.herEnt and Entity and Entity(st.herEnt)
    if IsValid(e) then return e:GetPos(), (e.GetModelScale and e:GetModelScale() or 1) end
    if st.her then return Vector(st.her[1], st.her[2], st.her[3] - 66), 1 end
    return nil
end

hook.Add("PostDrawTranslucentRenderables", "LivingCityDreamGames", function(_, sky)
    if sky or not st then return end
    render.SetMaterial(glow)
    -- The Saviour: a heavenly glow round her, and a column of light from above
    if st.theme == "glory" and st.light then
        local at, sc = HerPos()
        if at then
            local now = CurTime()
            local mid = at + Vector(0, 0, 40 * sc)
            local s = 260 + 40 * math.sin(now * 3)
            render.DrawSprite(mid, s, s, HALO)
            render.DrawSprite(mid, s * 0.5, s * 0.5, Color(255, 255, 255))
            for i = 1, 10 do render.DrawSprite(at + Vector(0, 0, i * 90), 140, 140, Color(255, 235, 180, 120)) end
            if DynamicLight then
                local d = DynamicLight(4242)
                if d then d.pos, d.r, d.g, d.b, d.brightness, d.decay, d.size, d.dietime = mid, 255, 235, 190, 4, 1000, 900, now + 0.2 end
            end
        end
    end
    -- the admiring dreams: hearts drifting up from her, and the roses
    if st.theme == "admire" then
        local at, sc = HerPos()
        if at then
            local now = CurTime()
            local head = at + Vector(0, 0, 66 * sc)
            for i = 1, 10 do
                local f = (now * 0.25 + i / 10) % 1
                local p = Vector(head.x + math.sin(i * 2.3 + now) * 60, head.y + math.cos(i * 1.7 + now) * 60, head.z - 80 + f * 260)
                local sz = 22 * (1 - f) + 6
                render.DrawSprite(p, sz, sz, Color(PINK.r, PINK.g, PINK.b, math.floor(255 * (1 - f))))
            end
        end
        for _, r in ipairs(st.roses or {}) do
            local pulse = 0.8 + 0.2 * math.sin(CurTime() * 5 + r[1])
            render.DrawSprite(Vector(r[1], r[2], r[3]), 30 * pulse, 30 * pulse, ROSE)
        end
    end
    -- the ten more: glows, boards hanging in the air, her portrait in cards
    for _, gl in ipairs(st.glows or {}) do
        local c = GLOWS[gl[4] or 1] or GOLD
        local pz = 0.85 + 0.15 * math.sin(CurTime() * 4 + gl[1] * 0.01)
        render.DrawSprite(Vector(gl[1], gl[2], gl[3]), 34 * pz, 34 * pz, c)
    end
    if st.rocket and Entity then -- (Duck and Cover: the rebels' rocket, flame and smoke under it as it climbs)
        local e = Entity(st.rocket)
        if IsValid(e) then
            local base = e:GetPos()
            local fl = 0.8 + 0.2 * math.sin(CurTime() * 30)
            render.DrawSprite(base, 140 * fl, 140 * fl, Color(255, 170, 60))
            render.DrawSprite(base - Vector(0, 0, 40), 90 * fl, 90 * fl, Color(255, 240, 200))
            for i = 1, 6 do render.DrawSprite(base - Vector(0, 0, 60 + i * 70), 120 + i * 30, 120 + i * 30, Color(200, 200, 200, 120 - i * 15)) end
        end
    end
    for _, i in ipairs(st.villains or {}) do -- (the Resistance, as dreams see it: a red halo round the giant)
        local e = Entity and Entity(i)
        if IsValid(e) then
            local sc = e.GetModelScale and e:GetModelScale() or 1
            local hp = 0.85 + 0.15 * math.sin(CurTime() * 5)
            render.DrawSprite(e:GetPos() + Vector(0, 0, 40 * sc), 120 * sc * hp, 120 * sc * hp, Color(255, 30, 30, 160))
        end
    end
    if st.storm then -- (Ravenholm: the vortigaunt's green storm, rolling out over everything)
        local s = st.storm
        local age = CurTime() - (s.t or CurTime())
        local r = math.min(3000, age * 700)
        local c = Vector(s[1], s[2], s[3] + 40)
        if age < 6 then
            for i = 1, 36 do
                local a = i / 36 * math.pi * 2 + age
                render.DrawSprite(c + Vector(math.cos(a) * r, math.sin(a) * r, 20 + math.sin(age * 8 + i) * 30), 200, 200, Color(80, 255, 110, math.floor(200 * (1 - age / 6))))
            end
        end
        render.DrawSprite(c + Vector(0, 0, 40 + math.sin(CurTime() * 3) * 10), 160, 160, Color(80, 255, 110, 180))
        if DynamicLight then
            local d = DynamicLight(4243)
            if d then d.pos, d.r, d.g, d.b, d.brightness, d.decay, d.size, d.dietime = c, 60, 255, 90, 3, 1000, math.max(600, r), CurTime() + 0.2 end
        end
    end
    if st.board then LC_CL.DreamBoard(st.board) end
    if st.mosaic then LC_CL.DreamMosaic(st.mosaic) end
    if not st.tokens then return end
    local pulse = 0.75 + 0.25 * math.sin(CurTime() * 6)
    for i, t in ipairs(st.tokens) do
        if not st.got[i] then
            local big = t[4] == 1
            local s = big and 40 * pulse or 16
            render.DrawSprite(Vector(t[1], t[2], t[3]), s, s, big and GOLD or BLUE)
        end
    end
end)

-- A board hanging in the air, facing its yaw: a title and lines (the enemy of the people: his face).
function LC_CL.DreamBoard(b)
    if not (cam and cam.Start3D2D) then return end
    local w, lh = 520, 40
    local h = 70 + #(b.lines or {}) * lh + (b.face and 230 or 0)
    cam.Start3D2D(Vector(b[1], b[2], b[3]), Angle(0, (b[4] or 0) + 90, 90), 0.5)
        surface.SetDrawColor(b.face and 235 or 25, b.face and 230 or 20, b.face and 220 or 20, 235)
        surface.DrawRect(-w / 2, -h / 2, w, h)
        surface.SetDrawColor(200, 20, 30, 255)
        surface.DrawRect(-w / 2, -h / 2, w, 56)
        draw.SimpleText(b.title or "", "DermaLarge", 0, -h / 2 + 28, Color(255, 230, 120), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        local y = -h / 2 + 80
        if b.face then -- (no photograph of him survives: a lambda, crossed out, and his name)
            draw.SimpleText("FREEMAN", "DermaLarge", 0, y + 10, Color(20, 20, 20), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
            draw.SimpleText("\206\187", "DermaLarge", 0, y + 110, Color(200, 120, 20), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            surface.SetDrawColor(200, 20, 30, 255)
            surface.DrawRect(-90, y + 104, 180, 12)
            y = y + 230
        end
        for _, l in ipairs(b.lines or {}) do
            draw.SimpleText(l, "DermaLarge", 0, y, b.face and Color(30, 30, 30) or Color(235, 235, 235), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
            y = y + lh
        end
    cam.End3D2D()
end
-- Her portrait in cards (the Mass Games): row by row, as the pictures are got right.
LC_CL.MosaicArt = {
    "rrrrhhhhrrrr", "rrrhhhhhhrrr", "rrhhsssshhrr", "rrhsssssshrr", "rrhsesseshrr", "rrhsssssshrr",
    "rrhssllsshrr", "rrrhsssshrrr", "rrrrhsshrrrr", "rrgggssgggrr", "rggggggggggr", "gggggggggggg" }
local CARD = { r = Color(180, 20, 30), h = Color(45, 28, 22), s = Color(235, 200, 170), e = Color(30, 30, 60), l = Color(200, 40, 70), g = Color(230, 185, 80) }
function LC_CL.DreamMosaic(m)
    if not (cam and cam.Start3D2D) then return end
    local art, cell = LC_CL.MosaicArt, 24
    local rows = math.floor(math.Clamp(m.shown or 0, 0, 1) * #art + 0.001)
    local half = #art * cell / 2
    cam.Start3D2D(Vector(m[1], m[2], m[3] + #art * cell), Angle(0, (m[4] or 0) + 90, 90), 1)
        for r, line in ipairs(art) do
            for col = 1, #line do
                local c = r <= rows and CARD[string.sub(line, col, col)] or Color(90, 90, 100)
                surface.SetDrawColor(c.r, c.g, c.b, 255)
                surface.DrawRect(-half + (col - 1) * cell + 1, (r - 1) * cell + 1, cell - 2, cell - 2)
            end
        end
    cam.End3D2D()
end

-- The Newsreel: black and white, like an old film.
hook.Add("RenderScreenspaceEffects", "LivingCityDreamGames", function()
    if not st or st.theme ~= "newsreel" or not DrawColorModify then return end
    DrawColorModify({ ["$pp_colour_addr"] = 0, ["$pp_colour_addg"] = 0, ["$pp_colour_addb"] = 0, ["$pp_colour_brightness"] = 0,
        ["$pp_colour_contrast"] = 1.2, ["$pp_colour_colour"] = 0, ["$pp_colour_mulr"] = 0, ["$pp_colour_mulg"] = 0, ["$pp_colour_mulb"] = 0 })
end)

local function Line(text, y, col, font)
    draw.SimpleTextOutlined(text, font or "DermaDefaultBold", ScrW() / 2, y, col or Color(235, 235, 235), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, 1, Color(0, 0, 0, 220))
end

hook.Add("HUDPaint", "LivingCityDreamGames", function()
    if not st then return end
    local me = LocalPlayer()
    if not IsValid(me) or not me:GetNW2Bool("lc_dreaming", false) then st, sub = nil, nil StopSong() StopVoice() CloseChoice() return end
    local now = CurTime()
    -- the screen's mood
    local admire = st.theme == "admire"
    local head = admire and PINK or (st.theme == "glory" and GOLD) or (st.theme == "propaganda" and PROP) or THEMES[st.theme or ""] or nil
    if admire then
        surface.SetDrawColor(255, 90, 170, 22 + math.floor(8 * math.sin(now * 1.5)))
        surface.DrawRect(0, 0, ScrW(), ScrH())
    elseif st.theme == "glory" and st.light then
        surface.SetDrawColor(255, 235, 190, 26)
        surface.DrawRect(0, 0, ScrW(), ScrH())
    elseif st.theme == "propaganda" or st.theme == "harvest" then
        surface.SetDrawColor(200, st.theme == "harvest" and 150 or 20, 20, 14)
        surface.DrawRect(0, 0, ScrW(), ScrH())
    elseif st.theme == "hate" then
        surface.SetDrawColor(220, 0, 0, 20 + math.floor(14 * math.abs(math.sin(now * 3))))
        surface.DrawRect(0, 0, ScrW(), ScrH())
    elseif st.theme == "graveyard" then -- (a red sky; green once the truth is out)
        if st.truth then surface.SetDrawColor(60, 255, 90, 22) else surface.SetDrawColor(150, 0, 0, 26) end
        surface.DrawRect(0, 0, ScrW(), ScrH())
    elseif st.theme == "civil" then
        surface.SetDrawColor(120, 200, 255, 14)
        surface.DrawRect(0, 0, ScrW(), ScrH())
    elseif st.theme == "newsreel" then -- (scratches on the film)
        surface.SetDrawColor(255, 255, 255, 30)
        for i = 1, 3 do surface.DrawRect(math.floor((math.sin(now * (7 + i) + i * 40) * 0.5 + 0.5) * ScrW()), 0, 1, ScrH()) end
    elseif st.afraid and st.afraid > now then
        surface.SetDrawColor(40, 80, 255, 35)
        surface.DrawRect(0, 0, ScrW(), ScrH())
    elseif st.phase == "red" then
        surface.SetDrawColor(255, 0, 0, 40)
        surface.DrawRect(0, 0, ScrW(), ScrH())
    end
    local y = 34
    Line(st.name or "A nightmare", y, head or Color(255, 120, 120), "DermaLarge")
    -- her lines, at the bottom
    if sub and now < sub.til then
        Line((sub.who and sub.who ~= "" and (sub.who .. ": ") or "") .. sub.text, ScrH() * 0.78, HALO, "DermaLarge")
    end
    y = y + 34
    Line(st.goal or "", y, Color(225, 225, 225))
    y = y + 18
    if st.star then
        Line("You're the star of this dream. What you say in chat, the dreamers see.", y, GOLD)
        y = y + 18
    end
    if st.enforcer then -- (sv_livingcity_dreamenforcers.lua)
        Line("You're an Enforcer: nothing here touches you. Wake whenever you like (C > Settings > Shared dreams).", y, BLUE)
        y = y + 18
    end
    local left = math.max(0, math.floor((st.ends or now) - now))
    local bits = { string.format("Time left: %d:%02d", math.floor(left / 60), left % 60) }
    if (st.maxLives or 1) > 1 and not st.enforcer then bits[#bits + 1] = string.format("Lives: %d of %d", st.lives or 0, st.maxLives) end
    if st.left then bits[#bits + 1] = string.format("Tokens left: %d", st.left) end
    if st.alive then bits[#bits + 1] = string.format("Still standing: %d", st.alive) end
    if st.meterName then bits[#bits + 1] = st.meterName end
    if st.carrying then bits[#bits + 1] = "You're carrying a rose" end
    if st.carryName then bits[#bits + 1] = "You're carrying " .. st.carryName end
    Line(table.concat(bits, "     "), y, Color(255, 215, 120))
    if st.meter then -- (a bar: Devotion, Roses, Adoration)
        local w, bx = 300, ScrW() / 2 - 150
        surface.SetDrawColor(30, 10, 25, 200)
        surface.DrawRect(bx, y + 20, w, 10)
        surface.SetDrawColor(PINK.r, PINK.g, PINK.b, 255)
        surface.DrawRect(bx, y + 20, math.floor(w * math.Clamp(st.meter / 100, 0, 1)), 10)
        y = y + 14
    end
    for _, n in ipairs(st.notes or {}) do -- (Careless Talk: what you've overheard)
        y = y + 18
        Line("Overheard: " .. n, y + 4, Color(200, 220, 255))
    end
    if st.out then
        Line(st.out == "won" and "You won. Watching until it's over (wake up: C > Settings > Shared dreams)."
            or "You're out. Watching until it's over (wake up: C > Settings > Shared dreams).", y + 20, Color(200, 200, 255))
        return
    end
    -- the big word, in the middle (Flowers for the Liberators: NOW, as a soldier passes you)
    local now2 = false
    if st.marchers and Entity then
        local mp = me:GetPos()
        for _, i in ipairs(st.marchers) do
            local e = Entity(i)
            if IsValid(e) and not (e.GetNoDraw and e:GetNoDraw()) then
                local ep = e:GetPos()
                if math.abs(ep.x - mp.x) < (st.nowR or 70) and math.abs(ep.y - mp.y) < 400 then now2 = true break end
            end
        end
    end
    if now2 then
        Line("NOW! Throw your flowers (jump)", ScrH() * 0.3, Color(255, 120, 190), "DermaLarge")
    elseif st.big then
        Line(st.big, ScrH() * 0.3, st.tone == "warn" and Color(255, 200, 80) or head or PINK, "DermaLarge")
    elseif st.phase == "red" then
        Line("FREEZE!", ScrH() * 0.3, Color(255, 60, 60), "DermaLarge")
    elseif st.phase == "green" then
        Line("Move! His back is turned.", ScrH() * 0.3, Color(120, 255, 140), "DermaLarge")
    elseif st.afraid and st.afraid > now then
        Line(string.format("They're afraid of you: catch them! (%d)", math.ceil(st.afraid - now)), ScrH() * 0.3, Color(140, 180, 255), "DermaLarge")
    end
end)
