--[[
    Living City: the dream flight recorder (the tester's side)

      The owner, 14 November: a way for the code chat to "see" a dream as it was really played,
      only for a dream tested from the Living City Editor (sv_livingcity_dreamrec.lua).

      While a test is recorded, this writes down what was really on the tester's screen:
        text    every line of text drawn (the HUD, the dream's own words, notices, signs in the
                world, windows), when it appeared and for how many seconds it could be read
        chat    what came up in chat
        sound   every sound played on this computer
        shot    a screenshot every few seconds (lc_dreamrec_shots, 5; 0 for none) and whenever a
                new sentence appears
        fps     when the picture slows down
      and puts it together with the server's lines (what the dream made, its workings, what the
      tester did) in one folder on the tester's own PC:

        garrysmod/data/livingcity/dreamrec/<date>_<time>_<dream>/log.txt   (and shot_*.jpg)

      log.txt starts with a pacing check: every text in order, how long it was up, how long it
      needs to be read (a second to notice it, then about 200 words a minute), and a verdict
      (TOO FAST, tight, ok, lingers). Then the whole dream second by second.

      Settings (the editor's "Dreams: test one"): "Record the test" (lc_dreamrec, on) and
      "A screenshot every ... seconds" (lc_dreamrec_shots). Nothing here runs outside a recorded test.
]]

if SERVER then return end

LC_CL = LC_CL or {}

CreateClientConVar("lc_dreamrec", "1", true, true, "Record a dream tested from the Living City Editor (a log and screenshots in data/livingcity/dreamrec, for the code chat)")
local cvShots = CreateClientConVar("lc_dreamrec_shots", "5", true, false, "While a dream test is recorded: a screenshot every this many seconds (0: none)")

local ROOT = "livingcity/dreamrec"
local MAX_SHOTS = 240
local READ_WPS = 3.3 -- (about 200 words a minute)

local R -- the recording under way

function LC_CL.DreamRecording() return R end

local function T() return CurTime() - R.t0 end

local function Add(kind, text, at)
    if not R then return end
    R.seq = R.seq + 1
    local line = { t = at or T(), k = kind, s = tostring(text), n = R.seq }
    R.lines[#R.lines + 1] = line
    R.pending[#R.pending + 1] = line
end

local function Fmt(line)
    return string.format("[%6.1f] %-7s %s", line.t, line.k, line.s)
end

------------------------------------------------------------------------
-- Text on screen
------------------------------------------------------------------------

local function Words(s)
    local n = 0
    for _ in string.gmatch(s, "%S+") do n = n + 1 end
    return n
end

-- A line of text is being drawn (or is in a window) right now.
local function Seen(text, font, x, y, src, hold)
    if not isstring(text) then return end
    text = string.Trim((string.gsub(text, "%s+", " ")))
    if #text < 2 then return end
    local now = T()
    local key = src .. "|" .. tostring(font) .. "|" .. string.gsub(text, "%d", "#")
    local e = R.active[key]
    if e then
        e.last = now
        e.text = text
        return
    end
    -- (a line being typed out, a letter at a time: the same line, growing)
    for k, o in pairs(R.active) do
        if o.src == src and o.font == font and o.y == y and now - o.last < 0.6
            and (string.sub(text, 1, #o.text) == o.text or string.sub(o.text, 1, #text) == text) then
            R.active[k] = nil
            o.last = now
            if #text > #o.text then o.full = text end
            o.text = text
            R.active[key] = o
            return
        end
    end
    R.active[key] = { text = text, font = font, x = x, y = y, src = src, first = now, last = now, hold = hold or 0.35 }
    if src ~= "window" and Words(text) >= 4 then R.shotSoon = R.shotSoon or (now + 0.7) end
end

local function Close(now, all)
    for k, e in pairs(R.active) do
        if all or now - e.last > e.hold then
            R.active[k] = nil
            e.text = e.full or e.text
            R.done[#R.done + 1] = e
        end
    end
end

-- Windows and their labels (drawn by the game itself, not by Lua).
local function Scan(pnl, depth)
    if depth > 14 or R.scanned > 700 then return end
    local kids = pnl.GetChildren and pnl:GetChildren()
    if not istable(kids) then return end
    for _, c in ipairs(kids) do
        if IsValid(c) and c:IsVisible() and c ~= g_SpawnMenu and c ~= g_ContextMenu and (not c.GetAlpha or c:GetAlpha() > 20) then
            R.scanned = R.scanned + 1
            local cls = c.GetClassName and c:GetClassName() or ""
            if (cls == "Label" or cls == "RichText" or cls == "TextEntry") and c.GetText then
                local ok, t = pcall(c.GetText, c)
                if ok and isstring(t) and t ~= "" then
                    local x, y = 0, 0
                    if c.LocalToScreen then x, y = c:LocalToScreen(0, 0) end
                    Seen((string.gsub(t, "\n", " / ")), c.GetFont and c:GetFont() or cls, x, y, "window", 0.9)
                end
            end
            Scan(c, depth + 1)
        end
    end
end

------------------------------------------------------------------------
-- Standing in front of the drawing, chat and sound functions (only while recording)
------------------------------------------------------------------------

local wraps = {}
local function Wrap(tbl, name, make)
    if not (istable(tbl) and type(tbl[name]) == "function") then return end
    local was = tbl[name]
    local mine = make(was)
    tbl[name] = mine
    wraps[#wraps + 1] = { tbl, name, was, mine }
end
local function Unwrap()
    -- (put back only what's still ours; anything wrapped over ours since stays, and ours does nothing with no recording)
    for i = #wraps, 1, -1 do
        local w = wraps[i]
        if w[1][w[2]] == w[4] then w[1][w[2]] = w[3] end
    end
    wraps = {}
end

local font, tx, ty, alpha, in3d = "?", 0, 0, 255, false

local function Heard(name, how)
    if not R then return end
    name = tostring(name)
    local now = T()
    if now - (R.heard[name] or -9) < 1 then return end
    R.heard[name] = now
    Add("sound", name .. (how and (" (" .. how .. ")") or ""))
end

local function Install()
    Wrap(surface, "SetFont", function(was) return function(f, ...) font = f return was(f, ...) end end)
    Wrap(surface, "SetTextPos", function(was) return function(x, y, ...) tx, ty = x, y return was(x, y, ...) end end)
    Wrap(surface, "SetTextColor", function(was) return function(r, g, b, a, ...)
        if istable(r) then alpha = r.a or 255 else alpha = a or 255 end
        return was(r, g, b, a, ...)
    end end)
    Wrap(surface, "DrawText", function(was) return function(text, ...)
        if R and alpha > 20 then
            if in3d then pcall(Seen, text, font, 0, math.floor(ty or 0), "world")
            elseif (tx or 0) > -400 and (ty or 0) > -100 and (tx or 0) < ScrW() and (ty or 0) < ScrH() then
                pcall(Seen, text, font, math.floor(tx or 0), math.floor(ty or 0), "screen")
            end
        end
        return was(text, ...)
    end end)
    Wrap(cam, "Start3D2D", function(was) return function(...) in3d = true return was(...) end end)
    Wrap(cam, "End3D2D", function(was) return function(...) in3d = false return was(...) end end)
    Wrap(chat, "AddText", function(was) return function(...)
        if R then
            local parts = {}
            for _, a in ipairs({ ... }) do if isstring(a) then parts[#parts + 1] = a end end
            if #parts > 0 then pcall(Add, "chat", table.concat(parts)) end
        end
        return was(...)
    end end)
    Wrap(surface, "PlaySound", function(was) return function(s, ...) pcall(Heard, s) return was(s, ...) end end)
    Wrap(sound, "PlayFile", function(was) return function(s, ...) pcall(Heard, s, "a file") return was(s, ...) end end)
    Wrap(sound, "Play", function(was) return function(s, ...) pcall(Heard, s, "in the world") return was(s, ...) end end)

    hook.Add("EntityEmitSound", "LivingCityDreamRec", function(data)
        if R and istable(data) then
            local e = data.Entity
            pcall(Heard, data.SoundName or data.OriginalSoundName or "?", IsValid(e) and ("from " .. e:GetClass()) or nil)
        end
    end)
    hook.Add("ChatText", "LivingCityDreamRec", function(_, _, text)
        if R and isstring(text) and text ~= "" then pcall(Add, "chat", text) end
    end)
    hook.Add("PostRender", "LivingCityDreamRec", function()
        if not (R and R.shotNow) then return end
        R.shotNow = nil
        if gui and gui.IsGameUIVisible and gui.IsGameUIVisible() then return end
        local ok, data = pcall(render.Capture, { format = "jpeg", quality = 60, x = 0, y = 0, w = ScrW(), h = ScrH() })
        if not (ok and isstring(data) and #data > 0) then return end
        local t = T()
        local name = string.format("shot_%04d_%d.jpg", math.floor(t), math.floor((t % 1) * 10))
        file.Write(R.dir .. "/" .. name, data)
        R.shots = R.shots + 1
        Add("shot", name)
    end)
end

local function Uninstall()
    Unwrap()
    hook.Remove("EntityEmitSound", "LivingCityDreamRec")
    hook.Remove("ChatText", "LivingCityDreamRec")
    hook.Remove("PostRender", "LivingCityDreamRec")
    timer.Remove("LivingCityDreamRec")
    in3d = false
end

------------------------------------------------------------------------
-- The file
------------------------------------------------------------------------

local function Append()
    if not R or #R.pending == 0 then return end
    local out = {}
    for i, line in ipairs(R.pending) do out[i] = Fmt(line) end
    R.pending = {}
    file.Append(R.dir .. "/log.txt", table.concat(out, "\n") .. "\n")
end

-- Lines of one wrapped paragraph (same font, came and went together) read as one text.
local function Blocks(done)
    local function Slot(e) return math.floor(e.first * 5 + 0.5) end -- (fifths of a second: what appeared together)
    table.sort(done, function(a, b)
        if Slot(a) ~= Slot(b) then return Slot(a) < Slot(b) end
        if a.src ~= b.src then return a.src < b.src end
        if tostring(a.font) ~= tostring(b.font) then return tostring(a.font) < tostring(b.font) end
        if (a.y or 0) ~= (b.y or 0) then return (a.y or 0) < (b.y or 0) end
        return a.text < b.text
    end)
    local out = {}
    for _, e in ipairs(done) do
        local b = out[#out]
        if b and b.src == e.src and b.font == e.font and math.abs(b.first - e.first) <= 0.25 and math.abs(b.last - e.last) <= 0.45 and b.y ~= e.y and b.n < 12 then
            b.text = b.text .. " / " .. e.text
            b.n = b.n + 1
            b.y = e.y
        else
            out[#out + 1] = { text = e.text, font = e.font, src = e.src, first = e.first, last = e.last, x = e.x, y = e.y, top = e.y, n = 1 }
        end
    end
    return out
end

local function Report(why)
    local len = math.max(0.1, T())
    Close(len, true)
    local blocks = Blocks(R.done)
    local judged, always, fast, tight = {}, {}, 0, 0
    for _, b in ipairs(blocks) do
        b.secs = math.max(0, b.last - b.first)
        b.words = Words((string.gsub(b.text, " / ", " ")))
        if len > 20 and b.secs >= len * 0.85 then
            always[#always + 1] = b
        else
            if b.words >= 3 then
                b.need = 1 + b.words / READ_WPS
                if b.secs < b.need * 0.8 then b.verdict = "TOO FAST" fast = fast + 1
                elseif b.secs < b.need then b.verdict = "tight" tight = tight + 1
                elseif b.secs > 15 and b.secs > b.need * 4 then b.verdict = "lingers"
                else b.verdict = "ok" end
            end
            judged[#judged + 1] = b
        end
    end
    -- (the longest stretch with nothing new to read)
    local gapFrom, gapLen, last = 0, 0, 0
    for _, b in ipairs(judged) do
        if b.words >= 3 then
            if b.first - last > gapLen then gapFrom, gapLen = last, b.first - last end
            last = math.max(last, b.first)
        end
    end
    if len - last > gapLen then gapFrom, gapLen = last, len - last end

    local o = {}
    local function P(s) o[#o + 1] = s end
    local info = R.info
    P("LIVING CITY: A DREAM TEST, RECORDED")
    P(string.format("Dream: \"%s\" (%s), %s, %s", tostring(info.title), tostring(info.id), tostring(info.mood), tostring(info.kind)))
    P(string.format("Map %s, %s. Length %.1f seconds. Ended: %s. The dreams' limit (lc_dream_max_minutes): %s.", tostring(info.map), R.date, len, tostring(why), tostring(info.max)))
    P(string.format("Screen %dx%d. Screenshots: %d (shot_SSSS_T.jpg: the second and tenth it was taken). Lowest frames a second: %s.", ScrW(), ScrH(), R.shots, R.minFps and tostring(math.floor(R.minFps)) or "?"))
    P("")
    P("How to read this (for the code chat):")
    P("  [seconds into the dream] kind, then what happened. Places are (x, y, z) from the dream point, in units (a person is 72 tall).")
    P("  From the server: start, made/gone (what the dream put out and took away), sound, notice (as sent: kind, seconds asked), state")
    P("  (the dream's own workings; \"at 45.0s\" is a moment of the dream), nw (networked about the tester), net (messages by name),")
    P("  you (the tester: place, looking at, pressed, used, idle, typed: a note typed in chat mid-dream), near, end.")
    P("  From the tester's screen: text (seconds it was readable, then the words; \"screen\" is drawn on the HUD, \"world\" is on something")
    P("  in the dream, \"window\" is in a window), chat, sound, shot, fps.")
    P("")
    P("== TEXT ON SCREEN, IN ORDER (the pacing check) ==")
    P(string.format("Reading time: 1 second to notice a text, then %.1f words a second. TOO FAST: up for under 80%% of that. tight: under it.", READ_WPS))
    P(string.format("Texts: %d. TOO FAST: %d. tight: %d. Longest stretch with no new text of three words or more: %.1fs (from %.1fs).", #judged, fast, tight, gapLen, gapFrom))
    P("  start    shown  words  needs  verdict   text")
    for _, b in ipairs(judged) do
        P(string.format("[%6.1f] %6.1fs %4dw %6s  %-8s  \"%s\" (%s, %s)", b.first, b.secs, b.words, b.need and string.format("%.1fs", b.need) or "-", b.verdict or "-", b.text, b.src, tostring(b.font)))
    end
    if #always > 0 then
        P("")
        P("On screen nearly the whole time (the HUD: not judged):")
        for _, b in ipairs(always) do P("  \"" .. b.text .. "\" (" .. b.src .. ", " .. tostring(b.font) .. ")") end
    end
    P("")
    P("== THE DREAM, SECOND BY SECOND ==")
    for _, b in ipairs(judged) do
        Add("text", string.format("%.1fs%s \"%s\" (%s)", b.secs, b.verdict and b.verdict ~= "ok" and (" " .. b.verdict) or "", b.text, b.src), b.first)
    end
    table.sort(R.lines, function(a, b)
        if a.t ~= b.t then return a.t < b.t end
        return a.n < b.n
    end)
    for _, line in ipairs(R.lines) do P(Fmt(line)) end
    return table.concat(o, "\n") .. "\n", fast, tight
end

local function Finish(why)
    local r = R
    if not r or r.finishing then return end
    r.finishing = true
    Uninstall()
    local ok, text, fast, tight = pcall(Report, why)
    if ok then
        file.Write(r.dir .. "/log.txt", text)
    else
        Append()
        file.Append(r.dir .. "/log.txt", "(the recorder could not write its summary: " .. tostring(text) .. ")\n")
    end
    R = nil
    local where = "garrysmod/data/" .. r.dir .. "/"
    local msg = "Saved on this computer: " .. where .. " (log.txt and " .. r.shots .. " screenshots)." ..
        (ok and (" Texts up too briefly to read: " .. tostring(fast) .. ".") or "") .. " Zip the folder and give it to the code chat."
    if LC_CL.AddNotice then LC_CL.AddNotice("info", "Dream recording", msg, 16) end
    if chat and chat.AddText then chat.AddText(Color(210, 180, 90), "[Dream recording] ", Color(230, 230, 230), msg) end
    LC_CL.DreamRecLast = { dir = r.dir, ok = ok, fast = fast, tight = tight, shots = r.shots }
end
LC_CL.DreamRecFinish = Finish

local function Tick()
    if not R then return end
    local now = T()
    local ok, err = pcall(function()
        R.ticks = R.ticks + 1
        Close(now)
        if R.ticks % 2 == 0 then
            R.scanned = 0
            if vgui.GetWorldPanel then pcall(Scan, vgui.GetWorldPanel(), 0) end
            if GetHUDPanel then pcall(Scan, GetHUDPanel(), 0) end
        end
        -- (frames a second, when it's slow)
        local ft = RealFrameTime and RealFrameTime() or 0
        if ft > 0 then
            local fps = 1 / ft
            if now > 1 and (not R.minFps or fps < R.minFps) then R.minFps = fps end
            if fps < 25 and now - (R.fpsAt or -9) >= 3 then R.fpsAt = now Add("fps", math.floor(fps) .. " frames a second") end
        end
        -- (screenshots: every few seconds, and soon after a new sentence appears)
        local every = cvShots:GetFloat()
        if every > 0 and R.shots < MAX_SHOTS then
            if R.shotSoon and now >= R.shotSoon then
                if now - R.shotAt >= 1.5 then R.shotNow, R.shotAt = true, now end
                R.shotSoon = nil
            elseif now - R.shotAt >= every then
                R.shotNow, R.shotAt = true, now
            end
        else
            R.shotSoon = nil
        end
        if R.ticks % 4 == 0 then Append() end
        -- (the server never said it was over: out of the dream for ten seconds is the end)
        local me = LocalPlayer()
        if R.ending then
            if now >= R.ending then Finish(R.endWhy) end
        elseif IsValid(me) and now > 10 and not me:GetNW2Bool("lc_dreaming", false) then
            R.awake = (R.awake or 0) + 1
            if R.awake > 40 then Finish("the tester was out of the dream (the server never said it was over)") end
        else
            R.awake = nil
        end
    end)
    if not ok and R then
        R.errors = (R.errors or 0) + 1
        if R.errors <= 3 then Add("recorder", "couldn't look (" .. tostring(err) .. ")") end
    end
end

local function Start(info)
    if R then Finish("another test began") end
    local date = os.date("%Y%m%d_%H%M%S")
    local id = string.gsub(string.lower(tostring(info.id or "dream")), "[^%w_]", "")
    local dir = ROOT .. "/" .. date .. "_" .. id
    file.CreateDir(dir)
    R = { info = info, t0 = tonumber(info.t0) or CurTime(), dir = dir, date = os.date("%d %B %Y, %H:%M"), lines = {}, pending = {}, seq = 0,
        active = {}, done = {}, heard = {}, shots = 0, shotAt = -99, ticks = 0, scanned = 0 }
    file.Write(dir .. "/log.txt", "(recording: this is rewritten in order, with the pacing check on top, when the dream ends)\n")
    Install()
    timer.Create("LivingCityDreamRec", 0.25, 0, Tick)
end

net.Receive("lc_dreamrec", function()
    local kind, info = net.ReadString(), net.ReadString()
    local n = net.ReadUInt(16) or 0
    local got = {}
    for i = 1, n do got[i] = { net.ReadFloat(), net.ReadString(), net.ReadString() } end
    if kind == "start" then
        Start(util.JSONToTable(info or "") or {})
    end
    if not R then return end
    for _, l in ipairs(got) do Add(l[2], l[3], l[1]) end
    if kind == "end" then
        -- (a moment more, so what's on screen as they wake is in it)
        R.ending, R.endWhy = T() + 1, (info ~= "" and info) or "the dream ended"
    end
end)
