--[[
    Living City (client): on the screen, not just in chat

      Cards       warnings (red edge), notices (blue edge) and the city's
                  announcements (amber), at the top under the status boxes.
                  One at a time (the owner, 7 November: eight at once on a
                  new character couldn't be read), the rest wait their turn;
                  a warning goes to the front. The same line again bumps a
                  counter instead of queueing up. Cards and tips take turns
                  (cl_livingcity_hints.lua).
      Subtitles   someone talking to you, low in the middle.
      Waypoint    a marker on a place you asked the way to, with how far it
                  is; at the edge of the screen when it's behind you. Gone
                  when you get there.

    lc_notices 0 turns the cards and subtitles off (they're always in chat).
    The server side is sv_livingcity_notices.lua.
]]

LC_CL = LC_CL or {}

local cvShow = CreateClientConVar("lc_notices", "1", true, false, "Warnings and notices on screen (they're always in chat too)")

local INK = Color(238, 236, 230)
local BODY = Color(205, 207, 212)
local BG = Color(12, 14, 18, 225)
local EDGE = { warn = Color(230, 90, 80), info = Color(110, 180, 245), event = Color(240, 190, 70), speech = Color(240, 170, 90) }
local WAY = Color(120, 230, 160)

surface.CreateFont("LCNoticeTitle", { font = "Trebuchet MS", size = 18, weight = 700 })
surface.CreateFont("LCNoticeText", { font = "Trebuchet MS", size = 17, weight = 500 })
surface.CreateFont("LCSubtitle", { font = "Trebuchet MS", size = 22, weight = 600 })

local cards, subs = {}, {} -- cards: waiting their turn (cards[1] is next)
local cur                   -- the card on screen
local cardFreeAt = 0        -- a short gap after one card before the next

function LC_CL.NoticeShowing() return cur ~= nil end

local function Wrap(text, font, width)
    surface.SetFont(font)
    local lines, line = {}, ""
    for word in string.gmatch(text or "", "%S+") do
        local try = line == "" and word or (line .. " " .. word)
        if line ~= "" and surface.GetTextSize(try) > width then
            lines[#lines + 1] = line
            line = word
        else
            line = try
        end
    end
    if line ~= "" then lines[#lines + 1] = line end
    return lines
end

function LC_CL.AddNotice(kind, title, text, secs)
    if not cvShow:GetBool() then return end
    text = tostring(text or "")
    if text == "" then return end
    local now = CurTime()
    local speech = kind == "speech"
    local list = speech and subs or cards
    local dur = (secs and secs > 0) and secs or ((speech and 4.5 or (kind == "event" and 10 or 7)) + math.min(6, #text / 45))
    if speech then
        for _, c in ipairs(list) do
            if c.title == title and c.text == text and c.ends > now then
                c.n = c.n + 1
                c.ends = now + dur
                return
            end
        end
        table.insert(list, 1, { kind = kind, title = title or "", text = text, born = now, ends = now + dur, n = 1 })
        while #list > 3 do table.remove(list) end
        return
    end
    -- the same line again: a count on the one showing, or the one waiting
    if cur and cur.title == title and cur.text == text then
        cur.n = cur.n + 1
        cur.ends = math.max(cur.ends or now, now + dur)
        return
    end
    for _, c in ipairs(cards) do
        if c.title == title and c.text == text then c.n = c.n + 1 return end
    end
    local card = { kind = kind, title = title or "", text = text, dur = dur, n = 1 }
    if kind == "warn" then
        -- straight to the front; whatever was showing comes back afterwards
        table.insert(cards, 1, card)
        if cur and cur.kind ~= "warn" then
            cur.born, cur.ends = nil, nil
            table.insert(cards, 2, cur)
            cur = nil
        end
        if surface and surface.PlaySound then surface.PlaySound("buttons/blip2.wav") end
    else
        cards[#cards + 1] = card
    end
    while #cards > 8 do table.remove(cards) end -- (chat keeps every line anyway)
end

-- A sound the server asked for that this computer can't play: said once per
-- file, on screen and in the console, with why. Announcements and songs play
-- on each player's own computer, so the sound addon has to be on it too.
local soundWarned = {}
function LC_CL.SoundTrouble(path, why)
    path = tostring(path or "")
    if path == "" or soundWarned[path] then return end
    if not why then
        if not file.Exists("sound/" .. path, "GAME") then why = "it isn't on this computer" else return end
    end
    soundWarned[path] = true
    print("[Miscount] Can't play sound/" .. path .. ": " .. why)
    LC_CL.AddNotice("warn", "Sound missing", "Can't play " .. (string.match(path, "([^/]+)$") or path) .. ": " .. why ..
        ". Type lc_sound_check in the console to see why.", 12)
end

-- What this computer has of the city's sounds, and a test that one plays.
local STOCK_LINES = {
    "f_anticitizenreport_spkr", "f_capitalmalcompliance_spkr", "f_citizenshiprevoked_6_spkr", "f_confirmcivilstatus_1_spkr",
    "f_evasionbehavior_2_spkr", "f_innactionisconspiracy_spkr", "f_protectionresponse_1_spkr", "f_rationunitsdeduct_3_spkr",
    "f_sociostabilizationrestored_spkr", "f_trainstation_assemble_spkr", "f_trainstation_assumepositions_spkr",
    "f_trainstation_cooperation_spkr", "f_trainstation_inform_spkr", "f_unrestprocedure1_spkr",
}
local SOUND_DIRS = { "livingcity/announce/overwatch", "livingcity/announce/administrator", "livingcity/announce/radio",
    "livingcity/overwatch", "livingcity/administrator", "livingcity/radio", "livingcity/endings" }
concommand.Add("lc_sound_check", function()
    local function Say(s) print("[Miscount] " .. s) end
    local first, total = nil, 0
    for _, d in ipairs(SOUND_DIRS) do
        local n = 0
        local function Count(dir)
            for _, f in ipairs(file.Find("sound/" .. dir .. "/*", "GAME") or {}) do
                local ext = string.lower(string.match(f, "%.(%w+)$") or "")
                if ext == "wav" or ext == "mp3" or ext == "ogg" then
                    n = n + 1
                    first = first or (dir .. "/" .. f)
                end
            end
        end
        Count(d)
        if d == "livingcity/endings" then
            local _, sub = file.Find("sound/" .. d .. "/*", "GAME")
            for _, s in ipairs(sub or {}) do Count(d .. "/" .. s) end
        end
        total = total + n
        Say(string.format("sound/%s/: %d file(s) on this computer", d, n))
    end
    local vol = GetConVar("volume")
    Say("Game volume: " .. (vol and vol:GetString() or "?") .. ", lc_breencast_volume (the Administrator): " ..
        (GetConVar("lc_breencast_volume") and GetConVar("lc_breencast_volume"):GetString() or "?"))
    if total == 0 then
        Say("This computer has none of the city's sounds, so you hear none of them. The server sends them through FastDL: after a sound is added there, press FastDL sync, change the map, and reconnect. (For a game of your own, put them in garrysmod/sound/livingcity/ here.)")
        return
    end
    -- the ending songs: every one on this computer, opened (not played) to see the game can play it
    local songs = {}
    for _, f in ipairs(file.Find("sound/livingcity/endings/*", "GAME") or {}) do
        local ext = string.lower(string.match(f, "%.(%w+)$") or "")
        if ext == "mp3" or ext == "ogg" or ext == "wav" then songs[#songs + 1] = f end
    end
    table.sort(songs)
    if #songs > 0 then Say("Ending songs on this computer (checking each one opens):") end
    for _, f in ipairs(songs) do
        local path = "sound/livingcity/endings/" .. f
        local kb = math.floor(((file.Size and file.Size(path, "GAME")) or 0) / 1024)
        sound.PlayFile(path, "noplay noblock", function(ch, err, errName)
            if IsValid(ch) then
                Say(string.format("  %s (%d KB): plays", f, kb))
                ch:Stop()
            else
                Say(string.format("  %s (%d KB): the game can't open it (%s)%s", f, kb, tostring(errName or err),
                    kb == 0 and ": it's empty, a download that didn't finish (delete it here and reconnect)" or ": re-encode it as a 44100 Hz MP3"))
            end
        end)
    end
    Say("(A song added to the server only reaches players after the server changes map and they reconnect: FastDL sync, then a map change.)")
    -- the stock Half-Life 2 Overwatch lines the city uses: which this install has
    Say("Half-Life 2's own Overwatch lines the city uses (found here, or missing):")
    for _, n in ipairs(STOCK_LINES) do
        local p = "npc/overwatch/cityvoice/" .. n .. ".wav"
        local plain = "npc/overwatch/cityvoice/" .. string.gsub(n, "_spkr$", "") .. ".wav"
        local have = file.Exists("sound/" .. p, "GAME")
        local alt = not have and plain ~= p and file.Exists("sound/" .. plain, "GAME")
        Say("  " .. n .. ": " .. (have and "found" or (alt and ("missing, but " .. string.gsub(n, "_spkr$", "") .. " is here (used instead)") or "MISSING")))
    end
    Say("Playing " .. first .. " now...")
    sound.PlayFile("sound/" .. first, "noblock", function(ch, err, errName)
        if IsValid(ch) then
            ch:Play()
            Say("It plays. If you heard nothing, check your game volume. If you heard it but not in the city, tell the server's admin to run lc_announce_clips.")
        else
            Say("It's here but the game can't play it (" .. tostring(errName or err) .. "): the file isn't what its name says. Rename an MP3 to .mp3; a WAV must be 16-bit, 44100 Hz.")
        end
    end)
end)

net.Receive("lc_notice", function()
    local kind, title, text, secs = net.ReadString(), net.ReadString(), net.ReadString(), net.ReadFloat()
    LC_CL.AddNotice(kind, title, text, secs)
end)

local function Alpha(c, now)
    local a = math.min(1, (now - c.born) / 0.2, (c.ends - now) / 0.6)
    return math.Clamp(a, 0, 1)
end
local function A(col, a) return Color(col.r, col.g, col.b, (col.a or 255) * a) end

local function DrawCards(now)
    local W, H = ScrW(), ScrH()
    local cw = math.min(W - 40, 560)
    local x = W / 2 - cw / 2
    local dreaming = LC_CL.DreamQuietHUD and LC_CL.DreamQuietHUD()
    -- (in a dream: below the dream's own lines and its big word, out of their way)
    local y = dreaming and math.floor(H * 0.62) or math.max((LC_CL.StatusBottom or 0) + 6, math.floor(H * 0.12))
    if cur and cur.ends and cur.ends <= now then cur = nil cardFreeAt = now + 0.8 end
    if not cur then
        local nxt = cards[1]
        if not nxt then return end
        -- its turn: after a short gap, and not over a tip (a warning doesn't wait)
        if nxt.kind ~= "warn" then
            if now < cardFreeAt then return end
            if LC_CL.HintShowing and LC_CL.HintShowing() then return end
        end
        cur = table.remove(cards, 1)
    end
    local c = cur
    if not c.born then c.born, c.ends = now, now + c.dur end
    local a = Alpha(c, now)
    c.lines = c.lines or Wrap(c.text, "LCNoticeText", cw - 28)
    local h = 30 + #c.lines * 19
    -- (the card is your side's: its plate and its line, cl_livingcity_theme.lua; the edge still says what kind of notice)
    local T = LC_CL.ThemeOn and LC_CL.ThemeOn() and LC_CL.Themes and LC_CL.Themes[LC_CL.ThemeName()] or nil
    if T then
        draw.RoundedBox(0, x, y, cw, h, A(T.bg, a))
        draw.RoundedBox(0, x, y, cw, 1, A(T.line, a))
        draw.RoundedBox(0, x, y + h - 2, cw, 2, A(T.dim, a))
    else
        draw.RoundedBox(4, x, y, cw, h, A(BG, a))
    end
    draw.RoundedBox(0, x, y, 4, h, A(EDGE[c.kind] or EDGE.info, a))
    local title = string.upper(c.title ~= "" and c.title or "Notice") .. (c.n > 1 and ("  x" .. c.n) or "")
    draw.SimpleText(title, "LCNoticeTitle", x + 14, y + 6, A(EDGE[c.kind] or EDGE.info, a))
    if #cards > 0 and not dreaming then draw.SimpleText("+" .. #cards .. " more", "LCNoticeTitle", x + cw - 12, y + 6, A(BODY, a * 0.7), TEXT_ALIGN_RIGHT) end
    for i, l in ipairs(c.lines) do
        draw.SimpleText(l, "LCNoticeText", x + 14, y + 8 + i * 19, A(i == 1 and INK or BODY, a))
    end
end

-- Where the subtitles go: low in the middle, or, when a window is open there (the
-- quartermaster's, the lab's...), just below it (or above it, with no room below):
-- the HUD is drawn under windows, so words behind one can't be read.
local function SubsY(W, H, rows)
    local y = H * 0.76
    local top, bottom
    local ok = pcall(function()
        local world = vgui and vgui.GetWorldPanel and vgui.GetWorldPanel()
        for _, c in ipairs(world and world:GetChildren() or {}) do
            if IsValid(c) and c:IsVisible() and (c.ClassName == "DFrame" or c.Base == "DFrame") then
                local x, py = c:GetPos()
                local cw, ch = c:GetSize()
                if ch < H * 0.95 and x < W / 2 and x + cw > W / 2 and py < y and py + ch > y - rows * 26 then
                    top = math.min(top or py, py)
                    bottom = math.max(bottom or 0, py + ch)
                end
            end
        end
    end)
    if not ok or not bottom then return y end
    if bottom + 20 + rows * 26 <= H - 8 then return bottom + 20 + (rows - 1) * 26 end
    return math.max(30 + (rows - 1) * 26, top - 20)
end
LC_CL.SubsY = SubsY

local function DrawSubs(now)
    local W, H = ScrW(), ScrH()
    for i = #subs, 1, -1 do if subs[i].ends <= now then table.remove(subs, i) end end
    local rows = 0
    for _, c in ipairs(subs) do
        c.lines = c.lines or Wrap(c.text, "LCSubtitle", math.min(W - 80, 900))
        rows = rows + #c.lines
    end
    local y = rows > 0 and SubsY(W, H, rows) or H * 0.76
    for _, c in ipairs(subs) do
        local a = Alpha(c, now)
        c.lines = c.lines or Wrap(c.text, "LCSubtitle", math.min(W - 80, 900))
        for i = #c.lines, 1, -1 do
            local l = c.lines[i]
            if i == 1 then
                surface.SetFont("LCSubtitle")
                local who = (c.title ~= "" and c.title or "Someone") .. ": "
                local ww = surface.GetTextSize(who)
                local lw = surface.GetTextSize(l)
                local x0 = W / 2 - (ww + lw) / 2
                draw.SimpleTextOutlined(who, "LCSubtitle", x0, y, A(EDGE.speech, a), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER, 1, A(color_black, a))
                draw.SimpleTextOutlined(l, "LCSubtitle", x0 + ww, y, A(INK, a), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER, 1, A(color_black, a))
            else
                draw.SimpleTextOutlined(l, "LCSubtitle", W / 2, y, A(INK, a), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, A(color_black, a))
            end
            y = y - 26
        end
        y = y - 8
    end
end

------------------------------------------------------------------------
-- Waypoint
------------------------------------------------------------------------

local way -- { pos, label, near }

net.Receive("lc_waypoint", function()
    local on, pos, label, near = net.ReadBool(), net.ReadVector(), net.ReadString(), net.ReadFloat()
    way = on and { pos = pos, label = label, near = near } or nil
end)

function LC_CL.Waypoint() return way end
function LC_CL.SetWaypoint(pos, label, near) way = pos and { pos = pos, label = label or "", near = near or 160 } or nil end

local function DrawWaypoint()
    if not way then return end
    local me = LocalPlayer()
    local W, H = ScrW(), ScrH()
    local dist = me:GetPos():Distance(way.pos)
    if dist < way.near then
        LC_CL.AddNotice("info", "Waypoint", "You're here: " .. way.label .. ".")
        way = nil
        return
    end
    local m = math.max(1, math.floor(dist / 40 + 0.5))
    local label = string.upper(way.label)
    local s = (way.pos + Vector(0, 0, 48)):ToScreen()
    if s and s.visible and s.x > 40 and s.x < W - 40 and s.y > 40 and s.y < H - 40 then
        draw.RoundedBox(2, s.x - 5, s.y - 5, 10, 10, WAY)
        draw.SimpleTextOutlined(label, "DermaDefaultBold", s.x, s.y - 18, WAY, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, color_black)
        draw.SimpleTextOutlined(m .. " m", "DermaDefault", s.x, s.y + 16, INK, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, color_black)
    else
        -- behind you, or off to the side: at the edge, the way to turn
        local yawTo = (way.pos - me:GetPos()):Angle().y
        local rel = math.rad(math.NormalizeAngle(yawTo - EyeAngles().y))
        local ax, ay = W / 2 - math.sin(rel) * (H * 0.36), H / 2 - math.cos(rel) * (H * 0.36)
        local turn = math.sin(rel) > 0.2 and "< " or ""
        local after = math.sin(rel) < -0.2 and " >" or ""
        draw.SimpleTextOutlined(turn .. label .. "  " .. m .. " m" .. after, "DermaDefaultBold", ax, ay, WAY, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, color_black)
    end
end

hook.Add("HUDPaint", "LivingCityNotices", function()
    local me = LocalPlayer()
    if not IsValid(me) then return end
    local now = CurTime()
    if me:Alive() then DrawWaypoint() end
    if cur or #cards > 0 then DrawCards(now) end
    if #subs > 0 then DrawSubs(now) end
end)
