--[[
    Living City: the nightmare dreams you play, your side (sv_livingcity_dreamgames.lua)

      While you're in one: its name, what to do, your lives and the time left, at the top of the
      screen. The Patrol Maze's tokens glow in the corridors (golden ones pulse), and the screen
      goes cold blue while the officers are afraid. Freeze, Citizen says when to stop, in red.
      Out of lives, or won: wake up now, or watch the rest until it's over.
      The Administrator's dreams (sv_livingcity_admiredreams.lua) go pink: a soft spotlight
      glow, hearts drifting up from her, glowing roses, a meter (Devotion, Roses, Adoration), and
      her music, if the owner put any in sound/livingcity/dreams/administrator/.
]]

LC_CL = LC_CL or {}

local st -- the game you're in, as the server last said
local choice -- the "wake up, or watch?" window

local function CloseChoice() if IsValid(choice) then choice:Remove() end choice = nil end
-- Her music (the Administrator's dreams), looping until the dream's over for you.
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
    elseif t.k == "got" then
        if st and st.got then st.got[t.i] = true st.left = math.max(0, (st.left or 1) - 1) end
    elseif t.k == "state" then
        if st then for k, v in pairs(t) do if k ~= "k" then st[k] = v end end end
    elseif t.k == "out" then
        if st then st.out = t.how or "out" end
        LC_CL.DreamGameChoice(t)
    elseif t.k == "stop" then
        st = nil
        StopSong()
        CloseChoice()
    end
end)
function LC_CL.DreamGame() return st end

local glow = Material("sprites/light_glow02_add")
local BLUE, GOLD = Color(120, 210, 255), Color(255, 205, 70)
local PINK, ROSE = Color(255, 120, 190), Color(255, 40, 90)

hook.Add("PostDrawTranslucentRenderables", "LivingCityDreamGames", function(_, sky)
    if sky or not st then return end
    render.SetMaterial(glow)
    -- her dreams: hearts drifting up from her, and the roses
    if st.theme == "admire" then
        if st.her then
            local now = CurTime()
            for i = 1, 10 do
                local f = (now * 0.25 + i / 10) % 1
                local p = Vector(st.her[1] + math.sin(i * 2.3 + now) * 60, st.her[2] + math.cos(i * 1.7 + now) * 60, st.her[3] - 80 + f * 260)
                local sz = 22 * (1 - f) + 6
                render.DrawSprite(p, sz, sz, Color(PINK.r, PINK.g, PINK.b, math.floor(255 * (1 - f))))
            end
        end
        for _, r in ipairs(st.roses or {}) do
            local pulse = 0.8 + 0.2 * math.sin(CurTime() * 5 + r[1])
            render.DrawSprite(Vector(r[1], r[2], r[3]), 30 * pulse, 30 * pulse, ROSE)
        end
    end
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

local function Line(text, y, col, font)
    draw.SimpleTextOutlined(text, font or "DermaDefaultBold", ScrW() / 2, y, col or Color(235, 235, 235), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, 1, Color(0, 0, 0, 220))
end

hook.Add("HUDPaint", "LivingCityDreamGames", function()
    if not st then return end
    local me = LocalPlayer()
    if not IsValid(me) or not me:GetNW2Bool("lc_dreaming", false) then st = nil StopSong() CloseChoice() return end
    local now = CurTime()
    -- the screen's mood
    local admire = st.theme == "admire"
    if admire then
        surface.SetDrawColor(255, 90, 170, 22 + math.floor(8 * math.sin(now * 1.5)))
        surface.DrawRect(0, 0, ScrW(), ScrH())
    elseif st.afraid and st.afraid > now then
        surface.SetDrawColor(40, 80, 255, 35)
        surface.DrawRect(0, 0, ScrW(), ScrH())
    elseif st.phase == "red" then
        surface.SetDrawColor(255, 0, 0, 40)
        surface.DrawRect(0, 0, ScrW(), ScrH())
    end
    local y = 34
    Line(st.name or "A nightmare", y, admire and PINK or Color(255, 120, 120), "DermaLarge")
    y = y + 34
    Line(st.goal or "", y, Color(225, 225, 225))
    y = y + 18
    local left = math.max(0, math.floor((st.ends or now) - now))
    local bits = { string.format("Time left: %d:%02d", math.floor(left / 60), left % 60) }
    if (st.maxLives or 1) > 1 then bits[#bits + 1] = string.format("Lives: %d of %d", st.lives or 0, st.maxLives) end
    if st.left then bits[#bits + 1] = string.format("Tokens left: %d", st.left) end
    if st.alive then bits[#bits + 1] = string.format("Still standing: %d", st.alive) end
    if st.meterName then bits[#bits + 1] = st.meterName end
    if st.carrying then bits[#bits + 1] = "You're carrying a rose" end
    Line(table.concat(bits, "     "), y, Color(255, 215, 120))
    if st.meter then -- (a bar: Devotion, Roses, Adoration)
        local w, bx = 300, ScrW() / 2 - 150
        surface.SetDrawColor(30, 10, 25, 200)
        surface.DrawRect(bx, y + 20, w, 10)
        surface.SetDrawColor(PINK.r, PINK.g, PINK.b, 255)
        surface.DrawRect(bx, y + 20, math.floor(w * math.Clamp(st.meter / 100, 0, 1)), 10)
        y = y + 14
    end
    if st.out then
        Line(st.out == "won" and "You won. Watching until it's over (wake up: C > Settings > Shared dreams)."
            or "You're out. Watching until it's over (wake up: C > Settings > Shared dreams).", y + 20, Color(200, 200, 255))
        return
    end
    -- the big word, in the middle
    if st.big then
        Line(st.big, ScrH() * 0.3, st.tone == "warn" and Color(255, 200, 80) or PINK, "DermaLarge")
    elseif st.phase == "red" then
        Line("FREEZE!", ScrH() * 0.3, Color(255, 60, 60), "DermaLarge")
    elseif st.phase == "green" then
        Line("Move! His back is turned.", ScrH() * 0.3, Color(120, 255, 140), "DermaLarge")
    elseif st.afraid and st.afraid > now then
        Line(string.format("They're afraid of you: catch them! (%d)", math.ceil(st.afraid - now)), ScrH() * 0.3, Color(140, 180, 255), "DermaLarge")
    end
end)
