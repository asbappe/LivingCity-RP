--[[
    Living City (client): on the screen, not just in chat

      Cards       warnings (red edge), notices (blue edge) and the city's
                  announcements (amber), stacked at the top under the status
                  boxes. The same line again bumps a counter instead of
                  stacking up.
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

local cards, subs = {}, {}

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
    for _, c in ipairs(list) do
        if c.title == title and c.text == text and c.ends > now then
            c.n = c.n + 1
            c.ends = now + dur
            return
        end
    end
    table.insert(list, 1, { kind = kind, title = title or "", text = text, born = now, ends = now + dur, n = 1 })
    while #list > (speech and 3 or 4) do table.remove(list) end
    if kind == "warn" and surface and surface.PlaySound then surface.PlaySound("buttons/blip2.wav") end
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
    print("[Living City] Can't play sound/" .. path .. ": " .. why)
    LC_CL.AddNotice("warn", "Sound missing", "Can't play " .. (string.match(path, "([^/]+)$") or path) .. ": " .. why ..
        ". Type lc_sound_check in the console to see why.", 12)
end

-- What this computer has of the city's sounds, and a test that one plays.
local SOUND_DIRS = { "livingcity/announce/overwatch", "livingcity/announce/administrator", "livingcity/announce/radio", "livingcity/endings" }
concommand.Add("lc_sound_check", function()
    local function Say(s) print("[Living City] " .. s) end
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
        Say("This computer has none of the city's sounds, so you hear none of them. Put the livingcity_sound folder in garrysmod/addons/ here too (and restart the game), or have the server send it: a Workshop addon, FastDL (sv_downloadurl), or sv_allowdownload 1.")
        return
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
    local y = math.max((LC_CL.StatusBottom or 0) + 6, math.floor(H * 0.12))
    for i = #cards, 1, -1 do if cards[i].ends <= now then table.remove(cards, i) end end
    for _, c in ipairs(cards) do
        local a = Alpha(c, now)
        c.lines = c.lines or Wrap(c.text, "LCNoticeText", cw - 28)
        local h = 30 + #c.lines * 19
        draw.RoundedBox(4, x, y, cw, h, A(BG, a))
        draw.RoundedBox(0, x, y, 4, h, A(EDGE[c.kind] or EDGE.info, a))
        local title = string.upper(c.title ~= "" and c.title or "Notice") .. (c.n > 1 and ("  x" .. c.n) or "")
        draw.SimpleText(title, "LCNoticeTitle", x + 14, y + 6, A(EDGE[c.kind] or EDGE.info, a))
        for i, l in ipairs(c.lines) do
            draw.SimpleText(l, "LCNoticeText", x + 14, y + 8 + i * 19, A(i == 1 and INK or BODY, a))
        end
        y = y + h + 6
    end
end

local function DrawSubs(now)
    local W, H = ScrW(), ScrH()
    for i = #subs, 1, -1 do if subs[i].ends <= now then table.remove(subs, i) end end
    local y = H * 0.76
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
    if #cards > 0 then DrawCards(now) end
    if #subs > 0 then DrawSubs(now) end
end)
