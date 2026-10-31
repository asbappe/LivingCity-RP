--[[
    Living City (client): the panels for the other hands-on jobs
    (sv_livingcity_moregames.lua): the records terminal, searching the dead,
    sorting uniforms, filing, tuning radios and pat-downs. And the outline on
    whatever your game wants you to look at (hiding places, residents,
    furniture to search, the body on the slab).
]]

LC_CL = LC_CL or {}

local function ReadCompressed()
    local len = net.ReadUInt(32)
    local data = net.ReadData(len)
    local json = util.Decompress(data or "")
    return json and util.JSONToTable(json) or nil
end

local function Act(action, v)
    net.Start("lc_jg_act")
    net.WriteString(action)
    net.WriteString(util.TableToJSON({ v = v }))
    net.SendToServer()
end
LC_CL.JobAct = Act

local BG, CARD, INK, DIM, ACC = Color(24, 27, 32), Color(36, 40, 47), Color(235, 235, 225), Color(170, 175, 180), Color(230, 190, 90)
local GOOD, BAD, WARN = Color(80, 160, 90), Color(170, 70, 60), Color(220, 170, 60)

local panel -- { frame, kind, data }
local BUILD = {}

local function Close(silent)
    if panel and IsValid(panel.frame) then
        panel.silent = silent
        panel.frame:Remove()
    end
    panel = nil
end

local function Frame(title, w, h)
    local f = vgui.Create("DFrame")
    f:SetTitle(title)
    f:SetSize(math.min(ScrW() - 40, w), math.min(ScrH() - 40, h))
    f:Center()
    f:MakePopup()
    f.Paint = function(s, pw, ph) draw.RoundedBox(6, 0, 0, pw, ph, BG) draw.RoundedBox(0, 0, 0, pw, 24, Color(14, 16, 20)) end
    local me = panel
    f.OnRemove = function() if me and not me.silent and panel == me then panel = nil Act("closed") end end
    return f
end

local function Button(parent, text, col, click)
    local b = vgui.Create("DButton", parent)
    b:SetText(text)
    b:SetTextColor(color_white)
    b.Paint = function(s, w, h)
        local c = s:GetDisabled() and Color(60, 60, 60) or col
        draw.RoundedBox(4, 0, 0, w, h, s:IsHovered() and Color(math.min(255, c.r + 25), math.min(255, c.g + 25), math.min(255, c.b + 25)) or c)
    end
    b.DoClick = click
    return b
end

net.Receive("lc_jg_panel", function()
    local t = ReadCompressed() or {}
    if not t.kind or not BUILD[t.kind] then return Close(true) end
    t.gotAt = CurTime() -- (a "secs" left counts down from here)
    if panel and panel.kind == t.kind and IsValid(panel.frame) and panel.update then
        panel.data = t
        panel.update(t)
        return
    end
    Close(true)
    t.gotAt = t.gotAt or CurTime()
    panel = { kind = t.kind, data = t }
    BUILD[t.kind](t)
end)
function LC_CL.JobPanel() return panel end

------------------------------------------------------------------------
-- Records terminal: stop the needle in the band
------------------------------------------------------------------------

BUILD.hack = function(t)
    local f = Frame("Records terminal: stop the needle in the band (click or space)", 560, 300)
    panel.frame = f
    local start = CurTime() - (t.t or 0)
    local function Needle()
        local d = panel and panel.data or t
        local ph = ((CurTime() - start) * (d.speed or 0.5)) % 2
        return ph < 1 and ph or 2 - ph
    end
    local function Try() Act("try", Needle()) end
    panel.update = function(d)
        start = CurTime() - (d.t or 0)
    end
    local bar = vgui.Create("DButton", f)
    bar:SetText("")
    bar:Dock(FILL)
    bar:DockMargin(10, 10, 10, 10)
    bar.DoClick = Try
    bar.Paint = function(s, w, h)
        local d = panel and panel.data or t
        draw.RoundedBox(4, 0, 0, w, h, CARD)
        local y, bh = h * 0.35, 40
        draw.RoundedBox(2, 20, y, w - 40, bh, Color(15, 18, 22))
        draw.RoundedBox(2, 20 + (w - 40) * (d.band or 0), y, (w - 40) * (d.w or 0.1), bh, GOOD)
        local nx = 20 + (w - 40) * Needle()
        surface.SetDrawColor(255, 255, 255)
        surface.DrawRect(nx - 2, y - 10, 4, bh + 20)
        draw.SimpleText(string.format("Bypassed %d of %d", d.got or 0, d.need or 4), "LCJobTitle", 20, 14, INK)
        draw.SimpleText(string.format("Seen %d of 2", d.alarms or 0), "LCJobTitle", w - 20, 14, (d.alarms or 0) > 0 and BAD or DIM, TEXT_ALIGN_RIGHT)
        local msg, col = "Clear", DIM
        if d.sweep then msg, col = "SCANNER OVERHEAD: HANDS OFF", BAD
        elseif d.warn then msg, col = "Scanner coming...", WARN end
        if d.sweep then draw.RoundedBox(4, 0, 0, w, h, Color(150, 20, 20, 40 + 30 * math.abs(math.sin(CurTime() * 6)))) end
        draw.SimpleText(msg, "LCJobTitle", w / 2, h - 30, col, TEXT_ALIGN_CENTER)
    end
    local away = Button(f, "Step away from it", Color(70, 80, 95), function() Act("away") end)
    away:Dock(BOTTOM)
    away:SetTall(30)
    away:DockMargin(10, 0, 10, 10)
    f.OnKeyCodePressed = function(_, key) if key == KEY_SPACE then Try() end end
    bar.OnKeyCodePressed = f.OnKeyCodePressed
end

------------------------------------------------------------------------
-- Searching the dead: pocket by pocket
------------------------------------------------------------------------

BUILD.search = function(t)
    local f = Frame(string.format("Searching the dead: %d of %d", t.n or 1, t.of or 3), 560, 380)
    panel.frame = f
    local banner = vgui.Create("DPanel", f)
    banner:Dock(TOP)
    banner:SetTall(30)
    banner.Paint = function(s, w, h)
        local d = panel and panel.data or t
        draw.RoundedBox(4, 0, 0, w, h, d.watching and BAD or CARD)
        draw.SimpleText(d.watching and "THE OVERSEER IS WATCHING" or "The overseer is out of the room", "LCJobTitle", w / 2, h / 2, INK, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    local list = vgui.Create("DPanel", f)
    list:Dock(FILL)
    list:DockMargin(0, 8, 0, 8)
    list.Paint = nil
    local burn = Button(f, "Done: into the fire", Color(150, 80, 40), function() Act("burn") end)
    burn:Dock(BOTTOM)
    burn:SetTall(34)
    local function Fill(d)
        list:Clear()
        for i, p in ipairs(d.pockets or {}) do
            local row = vgui.Create("DPanel", list)
            row:Dock(TOP)
            row:SetTall(46)
            row:DockMargin(0, 0, 0, 6)
            row.Paint = function(s, w, h)
                draw.RoundedBox(4, 0, 0, w, h, CARD)
                draw.SimpleText(p.name, "LCJobTitle", 10, 8, ACC)
                local text = not p.open and "Not searched" or (p.find or "Nothing")
                if p.done == "log" then text = text .. " (logged)" elseif p.done == "keep" then text = text .. " (yours now)"
                elseif p.done == "family" then text = text .. " (set aside for the family)" end
                draw.SimpleText(text, "LCJobLine", 10, 26, p.open and INK or DIM)
            end
            local function Btn(label, col, action)
                local b = Button(row, label, col, function() Act(action, i) end)
                b:Dock(RIGHT)
                b:SetWide(90)
                b:DockMargin(4, 8, 4, 8)
            end
            if not p.open then Btn("Search", Color(70, 90, 130), "open")
            elseif p.find and not p.done then
                Btn("Family", Color(90, 110, 90), "family")
                Btn("Keep", BAD, "keep")
                Btn("Log it", GOOD, "log")
            end
        end
    end
    panel.update = function(d) f:SetTitle(string.format("Searching the dead: %d of %d", d.n or 1, d.of or 3)) Fill(d) end
    Fill(t)
end

------------------------------------------------------------------------
-- Sorting uniforms
------------------------------------------------------------------------

BUILD.laundry = function(t)
    local f = Frame("Sorting: every uniform to its division", 600, 400)
    panel.frame = f
    local card = vgui.Create("DPanel", f)
    card:Dock(TOP)
    card:SetTall(140)
    card.Paint = function(s, w, h)
        local d = panel and panel.data or t
        draw.RoundedBox(4, 0, 0, w, h, Color(52, 62, 80))
        draw.SimpleText(string.format("Uniform %d of %d", d.n or 1, d.of or 12), "LCJobLine", 12, 8, DIM)
        draw.SimpleText(tostring(d.tag or ""), "DermaLarge", w / 2, 50, INK, TEXT_ALIGN_CENTER)
        if d.stain then draw.SimpleText("Bloodstained", "LCJobTitle", w / 2, 86, Color(220, 90, 80), TEXT_ALIGN_CENTER) end
        if d.pocket then draw.SimpleText("Something in the pocket: " .. d.pocket, "LCJobLine", 12, h - 22, WARN) end
        draw.SimpleText(string.format("%d s", d.secs or 0), "LCJobTitle", w - 12, 8, DIM, TEXT_ALIGN_RIGHT)
    end
    local pockets = vgui.Create("DPanel", f)
    pockets:Dock(TOP)
    pockets:SetTall(34)
    pockets:DockMargin(0, 6, 0, 6)
    pockets.Paint = nil
    local keep = Button(pockets, "Pocket it", BAD, function() Act("pocket") end)
    keep:Dock(LEFT) keep:SetWide(140)
    local give = Button(pockets, "Turn it in", GOOD, function() Act("turnin") end)
    give:Dock(LEFT) give:SetWide(140) give:DockMargin(8, 0, 0, 0)
    local bins = vgui.Create("DPanel", f)
    bins:Dock(FILL)
    bins.Paint = nil
    for i, b in ipairs(t.bins or {}) do
        local btn = Button(bins, b.label, i == 5 and Color(120, 50, 50) or Color(70, 90, 130), function() Act("sort", i) end)
        btn:Dock(TOP)
        btn:SetTall(30)
        btn:DockMargin(0, 0, 0, 4)
    end
    local function Upd(d) pockets:SetVisible(d.pocket ~= nil) end
    panel.update = Upd
    Upd(t)
end

------------------------------------------------------------------------
-- Filing
------------------------------------------------------------------------

-- The courier and the sender: take it, hand it back, report them, or open it
local SENDER_BTN = {
    take = { "Take it", GOOD }, refuse = { "Hand it back", Color(90, 90, 95) },
    report = { "Report the sender", Color(70, 90, 150) }, open = { "Open it", WARN },
}
BUILD.parcel = function(t)
    local f = Frame("A parcel to deliver", 560, 260)
    panel.frame = f
    local body = vgui.Create("DPanel", f)
    body:Dock(FILL)
    body:DockMargin(10, 10, 10, 8)
    body.Paint = function(s, w, h)
        local d = panel and panel.data or t
        draw.RoundedBox(4, 0, 0, w, h, CARD)
        local lines = LC_CL.WrapText and LC_CL.WrapText(d.text or "", "LCJobLine", w - 20) or { d.text or "" }
        for i, l in ipairs(lines) do draw.SimpleText(l, "LCJobLine", 10, 10 + (i - 1) * 18, INK) end
        if d.opened then draw.SimpleText("You opened it: Civil Standing lost, and half the pay if you deliver it.", "LCJobLine", 10, h - 22, WARN) end
    end
    local row = vgui.Create("DPanel", f)
    row:Dock(BOTTOM)
    row:SetTall(36)
    row:DockMargin(10, 0, 10, 10)
    row.Paint = nil
    local function Upd(d)
        row:Clear()
        for _, c in ipairs(d.choices or {}) do
            local spec = SENDER_BTN[c] or { c, DIM }
            local b = Button(row, spec[1], spec[2], function() Act("sender", c) end)
            b:Dock(LEFT)
            b:SetWide(126)
            b:DockMargin(0, 0, 8, 0)
        end
    end
    panel.update = Upd
    Upd(t)
end

BUILD.filing = function(t)
    local f = Frame("Filing: by citizen number; anything that doesn't match the register, to the discrepancy tray", 640, 400)
    panel.frame = f
    local card = vgui.Create("DPanel", f)
    card:Dock(TOP)
    card:SetTall(170)
    card.Paint = function(s, w, h)
        local d = panel and panel.data or t
        draw.RoundedBox(4, 0, 0, w * 0.55, h, Color(222, 214, 190))
        local ink = Color(40, 36, 30)
        draw.SimpleText("CIVIL STATUS FORM", "LCJobTitle", 12, 10, ink)
        draw.SimpleText("Name", "LCJobLine", 12, 46, Color(110, 100, 85)) draw.SimpleText(tostring(d.name or ""), "LCJobTitle", 110, 45, ink)
        draw.SimpleText("Citizen no.", "LCJobLine", 12, 76, Color(110, 100, 85)) draw.SimpleText(tostring(d.cid or ""), "LCJobTitle", 110, 75, ink)
        draw.SimpleText("Status", "LCJobLine", 12, 106, Color(110, 100, 85)) draw.SimpleText(tostring(d.status or ""), "LCJobTitle", 110, 105, ink)
        local x = w * 0.58
        draw.RoundedBox(4, x, 0, w - x, h, CARD)
        draw.SimpleText("THE REGISTER SAYS", "LCJobTitle", x + 10, 10, ACC)
        draw.SimpleText(tostring(d.regName or ""), "LCJobTitle", x + 10, 46, INK)
        draw.SimpleText(tostring(d.regCid or ""), "LCJobTitle", x + 10, 76, INK)
        draw.SimpleText(string.format("Form %d of %d    %d s", d.n or 1, d.of or 10, d.secs or 0), "LCJobLine", x + 10, h - 24, DIM)
    end
    local drawers = vgui.Create("DPanel", f)
    drawers:Dock(FILL)
    drawers:DockMargin(0, 8, 0, 0)
    drawers.Paint = nil
    for i, label in ipairs(t.drawers or {}) do
        local b = Button(drawers, label, i == 5 and Color(150, 70, 60) or Color(70, 90, 130), function() Act("file", i) end)
        b:Dock(LEFT)
        b:SetWide(math.floor((f:GetWide() - 30) / 5) - 4)
        b:DockMargin(0, 0, 4, 60)
    end
    local blank = Button(f, "Take a blank identity form from the cabinet", Color(90, 70, 50), function() Act("blank") end)
    blank:Dock(BOTTOM)
    blank:SetTall(28)
    local function Upd(d) blank:SetVisible(d.blank == true) end
    panel.update = Upd
    Upd(t)
end

------------------------------------------------------------------------
-- Repairing a radio: the dial, the screws, and what the set sounds like
------------------------------------------------------------------------

local LOW, HIGH = 87.5, 108
local STOCK_STATIC = "ambient/levels/prison/radio_random%d.wav" -- (when nobody has put a static recording in radio/static/)

-- How loud each track is at this point on the dial: static, the station, Freq 7.
-- They overlap: a station creeps in through the hiss a couple of points away,
-- and the hiss never quite goes until you're on it.
-- On a set being repaired, the trimmer screws shape all of it (turn: where they
-- are now, d.screws: where they should be):
--   the volume trimmer   how loud the station comes through
--   the squelch          how much hiss is left under it
--   the alignment        how sharp it is: off, and the station is weak and
--                        smeared across the dial, with more static bleeding in
local function ScrewQ(v, want) return math.Clamp(1 - math.abs((tonumber(v) or 0) - want) / 0.33, 0, 1) end
function LC_CL.RadioMix(dial, d, turn)
    if d.heard then return 0.12, 0, 1 end
    turn = turn or d.turn
    local qv, qs, qa = 1, 1, 1
    if d.screws and turn then
        qv, qs, qa = ScrewQ(turn[1], d.screws[1] or 0), ScrewQ(turn[2], d.screws[2] or 0), ScrewQ(turn[3], d.screws[3] or 0)
    end
    local width, peak = 1.0 + 1.2 * (1 - qa), 0.45 + 0.55 * qa
    local su = peak * math.exp(-((dial - (d.t or 0)) / width) ^ 2)
    local s7 = d.f7 and peak * math.exp(-((dial - d.f7) / width) ^ 2) or 0
    local floor = 0.12 + 0.55 * (1 - qs)
    local gain = 0.2 + 0.8 * qv
    return math.Clamp(1 - 0.85 * math.max(su, s7), floor, 1), su ^ 0.6 * gain, s7 ^ 0.6 * gain
end

-- How loud a set is from this far away: full right beside it, quieter as you
-- step back, and gone by about twenty feet.
local NEAR, RANGE = 40, 240
function LC_CL.RadioFalloff(dist)
    if dist >= RANGE then return 0 end
    if dist <= NEAR then return 1 end
    local f = 1 - (dist - NEAR) / (RANGE - NEAR)
    return f * f
end

-- Every set being tuned near you (the server sends each one's dial and what's
-- on it). Every track keeps playing and only its volume moves, so tuning never
-- cuts anything off; a file that ends starts again (the stock static picks another).
local benches = {} -- [entindex] = { paths = {}, static, union, f7, d, seen }

local function Track(ent, path)
    if not path or path == "" or not IsValid(ent) or not CreateSound then return nil end
    local snd = CreateSound(ent, path)
    if not snd then return nil end
    if snd.SetSoundLevel then snd:SetSoundLevel(0) end -- (the distance is ours to do: RadioFalloff)
    snd:Play()
    snd:ChangeVolume(0, 0)
    return snd
end

local function BenchStop(id)
    local b = benches[id]
    if b then for _, k in ipairs({ "static", "union", "f7" }) do if b[k] then b[k]:Stop() end end end
    benches[id] = nil
end

local function BenchTracks(b, ent)
    local want = { static = b.d.static or "", union = b.d.union or "", f7 = b.d.clip7 or "" }
    local keys = { f7 = (b.d.clip7 or "") .. "#" .. tostring(b.d.seq7 or "") } -- (Freq 7: each new thing on air starts afresh)
    for k, path in pairs(want) do
        if b.paths[k] ~= (keys[k] or path) then
            if b[k] then b[k]:Stop() end
            b.paths[k] = keys[k] or path
            b[k] = Track(ent, (k == "static" and path == "") and string.format(STOCK_STATIC, math.random(1, 15)) or path)
        end
    end
end

net.Receive("lc_radio_bench", function()
    local t = ReadCompressed() or {}
    local id = tonumber(t.e)
    if not id then return end
    if t.off then return BenchStop(id) end
    local b = benches[id] or { paths = {} }
    benches[id] = b
    b.d, b.seen = t, CurTime()
    BenchTracks(b, Entity(id))
end)

hook.Add("Think", "LivingCityRadioBench", function()
    if not next(benches) then return end
    local me = LocalPlayer()
    if not IsValid(me) then return end
    for id, b in pairs(benches) do
        local ent = Entity(id)
        if not IsValid(ent) or CurTime() - (b.seen or 0) > 1.5 then
            BenchStop(id)
        else
            local mine = ent == me
            local dial = b.d.dial or 98
            local turn
            if mine and panel and panel.kind == "radio" and IsValid(panel.dialCtl) then dial, turn = panel.dialCtl:GetValue(), panel.turn
            elseif mine and LC_CL.ListenDial then dial = LC_CL.ListenDial() or dial end
            local fall = mine and 1 or LC_CL.RadioFalloff(me:GetPos():Distance(ent:GetPos()))
            local vs, vu, v7 = LC_CL.RadioMix(dial, b.d, turn)
            for k, v in pairs({ static = vs, union = vu, f7 = v7 }) do
                local snd = b[k]
                if snd then
                    if not snd:IsPlaying() and not (k == "f7" and b.d.once7) then -- (Freq 7's program plays each thing once)
                        if k == "static" and b.paths.static == "" then
                            snd:Stop()
                            snd = Track(ent, string.format(STOCK_STATIC, math.random(1, 15)))
                            b.static = snd
                        else
                            snd:Play()
                        end
                    end
                    if snd then snd:ChangeVolume(v * fall, 0.15) end
                end
            end
        end
    end
end)
LC_CL.RadioBenches = function() return benches end

-- A trimmer screw: turn it with the screwdriver. Hold the mouse on it and go round, clockwise
-- or anticlockwise, like turning a real screw (or the mouse wheel, for the last little bit).
local function ScrewAngle(s, cx, cy)
    local x, y = s:LocalCursorPos()
    return math.deg(math.atan2(x - cx, -(y - cy))) -- (0 at the top, going round clockwise)
end
LC_CL.ScrewAngle = ScrewAngle
local function Screw(parent, name, get, set)
    local p = vgui.Create("DPanel", parent)
    p:SetSize(110, 96)
    p:SetCursor("hand")
    p.Paint = function(s, w, h)
        local cx, cy, r = w / 2, 38, 26
        surface.SetDrawColor(110, 112, 118)
        for k = 0, 3 do surface.DrawCircle(cx, cy, r - k, 150 - k * 10, 152 - k * 10, 158 - k * 10, 255) end
        draw.RoundedBox(r, cx - r + 4, cy - r + 4, (r - 4) * 2, (r - 4) * 2, s:IsHovered() and Color(150, 152, 160) or Color(125, 127, 134))
        local a = math.rad(-135 + 270 * get())
        local dx, dy = math.sin(a) * (r - 6), -math.cos(a) * (r - 6)
        surface.SetDrawColor(40, 40, 44)
        for o = -1, 1 do surface.DrawLine(cx - dx + o, cy - dy, cx + dx + o, cy + dy) end
        if s:IsHovered() or s.turning then
            -- which way is which
            draw.SimpleText("-", "LCJobLine", cx - r - 8, cy, DIM, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            draw.SimpleText("+", "LCJobLine", cx + r + 8, cy, DIM, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        draw.SimpleText(name, "LCJobLine", cx, h - 16, INK, TEXT_ALIGN_CENTER)
    end
    p.OnMousePressed = function(s) s.turning = true s.lastA = ScrewAngle(s, s:GetWide() / 2, 38) s:MouseCapture(true) end
    p.OnMouseReleased = function(s) s.turning = nil s:MouseCapture(false) end
    p.Think = function(s)
        if not s.turning then return end
        local a = ScrewAngle(s, s:GetWide() / 2, 38)
        local d = (a - (s.lastA or a) + 540) % 360 - 180 -- (the shortest way round since last time)
        s.lastA = a
        if d ~= 0 then set(math.Clamp(get() + d / 270, 0, 1)) end -- (three quarters of a turn: one end to the other)
    end
    p.OnMouseWheeled = function(_, delta) set(math.Clamp(get() + delta * 0.015, 0, 1)) return true end
    return p
end

BUILD.radio = function(t)
    local f = Frame("Radio repair: find its station, then set the screws by ear until it's clean", 600, 420)
    panel.frame = f
    panel.turn = table.Copy(t.turn or {})
    panel.set = t.n
    local dial = vgui.Create("DNumSlider", f)
    dial:Dock(TOP)
    dial:DockMargin(10, 90, 10, 0)
    dial:SetText("Frequency")
    dial:SetMin(LOW)
    dial:SetMax(HIGH)
    dial:SetDecimals(1)
    -- (opened again on the same set, it's still where you left it: the server remembers the dial)
    dial:SetValue(tonumber(t.dial) or (LOW + math.random() * (HIGH - LOW)))
    panel.dialCtl = dial
    -- (the server passes the dial and the screws on to whoever is standing near the bench)
    local sentAt, sentVal = 0, nil
    dial.OnValueChanged = function(_, v)
        if CurTime() - sentAt < 0.2 or v == sentVal then return end
        sentAt, sentVal = CurTime(), v
        Act("dial", math.floor(v * 10 + 0.5) / 10)
    end
    Act("dial", math.floor(dial:GetValue() * 10 + 0.5) / 10)
    local meter = vgui.Create("DPanel", f)
    meter:SetPos(10, 30)
    meter:SetSize(f:GetWide() - 20, 56)
    meter.Paint = function(s, w, h)
        local d = panel and panel.data or t
        local vs, vu, v7 = LC_CL.RadioMix(dial:GetValue(), d, panel and panel.turn)
        local station = math.max(vu, v7)
        draw.RoundedBox(4, 0, 0, w, h, CARD)
        draw.SimpleText(string.format("%.1f", dial:GetValue()), "DermaLarge", 12, h / 2, INK, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        local bw = w - 260
        draw.SimpleText("Station", "LCJobLine", 110, 8, DIM)
        draw.RoundedBox(2, 170, 9, bw * station, 14, station > 0.8 and GOOD or (station > 0.4 and WARN or BAD))
        draw.SimpleText("Static", "LCJobLine", 110, 32, DIM)
        draw.RoundedBox(2, 170, 33, bw * vs, 14, vs < 0.25 and GOOD or (vs < 0.6 and WARN or BAD))
        -- the time left on this set, ticking down (red near the end: it goes back on the shelf unfixed)
        local left = math.max(0, math.ceil((d.secs or 0) - (CurTime() - (d.gotAt or CurTime()))))
        draw.SimpleText(string.format("Set %d of %d", d.n or 1, d.of or 4), "LCJobLine", w - 10, h / 2 - 9, DIM, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
        draw.SimpleText(string.format("%d:%02d left", math.floor(left / 60), left % 60), "LCJobLine", w - 10, h / 2 + 9, left <= 15 and BAD or INK, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
    end
    local bench = vgui.Create("DPanel", f)
    bench:Dock(TOP)
    bench:SetTall(100)
    bench:DockMargin(10, 8, 10, 0)
    bench.Paint = function(s, w, h) draw.RoundedBox(4, 0, 0, w, h, Color(30, 33, 38)) end
    local screwSentAt = {}
    for i, name in ipairs(t.names or { "Volume trimmer", "Squelch", "Alignment" }) do
        local sc = Screw(bench, name, function() return panel and panel.turn and panel.turn[i] or 0 end, function(v)
            if not panel or not panel.turn then return end
            panel.turn[i] = v
            if CurTime() - (screwSentAt[i] or 0) > 0.2 then screwSentAt[i] = CurTime() Act("screw", { i, v }) end
        end)
        sc:SetPos(20 + (i - 1) * 130, 2)
    end
    local lock = Button(f, "Test it: is it clean?", GOOD, function()
        Act("lock", { f = math.floor(dial:GetValue() * 10 + 0.5) / 10, s = panel and panel.turn or {} })
    end)
    lock:Dock(TOP)
    lock:SetTall(34)
    lock:DockMargin(10, 10, 10, 0)
    local heard = vgui.Create("DPanel", f)
    heard:Dock(FILL)
    heard:DockMargin(10, 10, 10, 10)
    heard.Paint = function(s, w, h)
        local d = panel and panel.data or t
        if not d.heard then return end
        draw.RoundedBox(4, 0, 0, w, h, Color(60, 30, 30))
        local lines = LC_CL.WrapText and LC_CL.WrapText(d.heard, "LCJobLine", w - 20) or { d.heard }
        for i, l in ipairs(lines) do draw.SimpleText(l, "LCJobLine", 10, 4 + (i - 1) * 16, INK) end
    end
    local choices = {}
    for i, c in ipairs({ { "Report the frequency", "report", Color(70, 90, 150) }, { "Write it down", "note", Color(110, 80, 50) }, { "Tune past it", "past", Color(70, 70, 70) } }) do
        local b = Button(heard, c[1], c[3], function() Act("freq7", c[2]) end)
        b:SetSize(160, 28)
        choices[i] = b
    end
    heard.PerformLayout = function(s, w, h) for i, b in ipairs(choices) do b:SetPos(10 + (i - 1) * 168, h - 34) end end
    local function Upd(d)
        heard:SetVisible(d.heard ~= nil)
        lock:SetDisabled(d.heard ~= nil)
        -- the next set off the shelf: its screws are wherever they were left (and a moment to
        -- see the last one done, as it's taken off the bench)
        if panel and d.n ~= panel.set then
            if panel.set and d.n and d.n > panel.set then
                panel.between = { t = CurTime(), done = panel.set, of = d.of or 4, fixed = d.last ~= "timeout" }
                surface.PlaySound(d.last == "timeout" and "buttons/button10.wav" or "buttons/button14.wav")
            end
            panel.set = d.n
            panel.turn = table.Copy(d.turn or {})
        end
    end
    f.PaintOver = function(s, w, h)
        local b = panel and panel.between
        if not b then return end
        local k = (CurTime() - b.t) / 1.8
        if k >= 1 then panel.between = nil return end
        local a = k < 0.15 and k / 0.15 or (k > 0.75 and (1 - k) / 0.25 or 1)
        draw.RoundedBox(4, 0, 24, w, h - 24, Color(12, 14, 16, 235 * a))
        local col = b.fixed and GOOD or BAD
        draw.SimpleText(b.fixed and string.format("Set %d of %d: clean. Off the bench it goes.", b.done, b.of)
            or string.format("Set %d of %d: out of time. Back on the shelf, unfixed.", b.done, b.of), "DermaLarge", w / 2, h / 2 - 16, Color(col.r, col.g, col.b, 255 * a), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        if b.done < b.of then
            draw.SimpleText("The next one from the shelf...", "LCJobLine", w / 2, h / 2 + 18, Color(INK.r, INK.g, INK.b, 255 * a), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
    end
    panel.update = Upd
    Upd(t)
end

------------------------------------------------------------------------
-- Your own radio (Listen, from your pockets): the dial, and what's on it.
-- Close the window and it keeps playing where you left it; Switch off stops it.
------------------------------------------------------------------------

local listen -- { frame, dial value, data }

function LC_CL.ListenDial() return listen and listen.value or nil end

local function SendDial(v)
    net.Start("lc_radio_dial")
    net.WriteFloat(v)
    net.SendToServer()
end

local function ListenWindow()
    if not listen then return end
    if IsValid(listen.frame) then listen.frame:MakePopup() return end
    local d = listen.data
    local f = vgui.Create("DFrame")
    listen.frame = f
    f:SetTitle(d.tuned and "Radio (retuned)" or "Union radio")
    f:SetSize(math.min(ScrW() - 40, 460), 190)
    f:SetPos(ScrW() - f:GetWide() - 20, ScrH() - 230)
    f:MakePopup()
    f.Paint = function(s, w, h) draw.RoundedBox(6, 0, 0, w, h, BG) draw.RoundedBox(0, 0, 0, w, 24, Color(14, 16, 20)) end
    local meter = vgui.Create("DPanel", f)
    meter:Dock(TOP)
    meter:SetTall(50)
    meter:DockMargin(6, 4, 6, 0)
    local dial = vgui.Create("DNumSlider", f)
    meter.Paint = function(s, w, h)
        local mine = benches[LocalPlayer():EntIndex()]
        local vs, vu, v7 = LC_CL.RadioMix(dial:GetValue(), mine and mine.d or d) -- (the latest: Freq 7 moves)
        draw.RoundedBox(4, 0, 0, w, h, CARD)
        draw.SimpleText(string.format("%.1f", dial:GetValue()), "DermaLarge", 10, h / 2, INK, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        local st = math.max(vu, v7)
        draw.SimpleText("Station", "LCJobLine", 100, 6, DIM)
        draw.RoundedBox(2, 160, 7, (w - 170) * st, 12, st > 0.8 and GOOD or (st > 0.4 and WARN or BAD))
        draw.SimpleText("Static", "LCJobLine", 100, 28, DIM)
        draw.RoundedBox(2, 160, 29, (w - 170) * vs, 12, vs < 0.25 and GOOD or (vs < 0.6 and WARN or BAD))
    end
    dial:Dock(TOP)
    dial:DockMargin(6, 6, 6, 0)
    dial:SetText("Frequency")
    dial:SetMin(87.5)
    dial:SetMax(108)
    dial:SetDecimals(1)
    dial:SetValue(listen.value or d.dial or 96.4)
    listen.dialCtl = dial
    local sentAt = 0
    dial.OnValueChanged = function(_, v)
        if not listen then return end
        listen.value = v
        if CurTime() - sentAt > 0.2 then sentAt = CurTime() SendDial(math.floor(v * 10 + 0.5) / 10) end
    end
    local off = Button(f, "Switch it off", BAD, function() SendDial(0) end)
    off:Dock(BOTTOM)
    off:SetTall(28)
    off:DockMargin(6, 0, 6, 6)
    local hint = vgui.Create("DLabel", f)
    hint:Dock(BOTTOM)
    hint:DockMargin(8, 0, 8, 4)
    hint:SetTextColor(DIM)
    hint:SetText("Anyone within about twenty feet hears it too. Close this and it keeps playing.")
end
LC_CL.RadioListenWindow = ListenWindow

net.Receive("lc_radio_listen", function()
    local t = util.JSONToTable(net.ReadString() or "") or {}
    if t.follow then -- (a Resistance radio following Freq 7 to its new frequency)
        if listen then
            listen.value = t.follow
            if IsValid(listen.dialCtl) then listen.dialCtl:SetValue(t.follow) end
        end
        return
    end
    if not t.dial then
        if listen and IsValid(listen.frame) then listen.frame:Remove() end
        listen = nil
        return
    end
    if listen and IsValid(listen.frame) then listen.frame:Remove() end
    listen = { data = t, value = t.dial }
    ListenWindow()
end)

concommand.Add("lc_radio", function() if listen then ListenWindow() end end) -- (bring the window back: bindable)

------------------------------------------------------------------------
-- Pat-down
------------------------------------------------------------------------

BUILD.patdown = function(t)
    local f = Frame("Pat-down", 560, 360)
    panel.frame = f
    local head = vgui.Create("DPanel", f)
    head:Dock(TOP)
    head:SetTall(56)
    head.Paint = function(s, w, h)
        local d = panel and panel.data or t
        draw.RoundedBox(4, 0, 0, w, h, CARD)
        draw.SimpleText(d.tell or "They stand very still and look at nothing.", "LCJobLine", 10, 10, INK)
        draw.SimpleText(string.format("Their nerve: %d    Citizen %d of %d", d.nerve or 0, d.n or 1, d.of or 3), "LCJobLine", 10, 32, (d.nerve or 4) <= 1 and BAD or DIM)
    end
    local grid = vgui.Create("DPanel", f)
    grid:Dock(FILL)
    grid:DockMargin(0, 8, 0, 8)
    grid.Paint = nil
    local verdicts = vgui.Create("DPanel", f)
    verdicts:Dock(BOTTOM)
    verdicts:SetTall(34)
    verdicts.Paint = nil
    local vb = {}
    for i, v in ipairs({ { "Release", "release", Color(70, 70, 70) }, { "Confiscate", "confiscate", Color(110, 90, 50) }, { "Detain", "detain", BAD } }) do
        local b = Button(verdicts, v[1], v[3], function() Act("verdict", v[2]) end)
        b:Dock(LEFT)
        b:SetWide(150)
        b:DockMargin(i == 1 and 0 or 8, 0, 0, 0)
        vb[v[2]] = b
    end
    local function Fill(d)
        grid:Clear()
        for i, z in ipairs(d.zones or {}) do
            local b = Button(grid, z.done and (z.name .. ": " .. (z.found or "nothing")) or z.name, z.found and BAD or (z.done and Color(55, 60, 66) or Color(70, 90, 130)), function() Act("pat", i) end)
            b:SetDisabled(z.done)
            b:SetSize(math.floor((f:GetWide() - 30) / 2), 40)
            b:SetPos(((i - 1) % 2) * (math.floor((f:GetWide() - 30) / 2) + 8), math.floor((i - 1) / 2) * 46)
        end
        vb.confiscate:SetDisabled(d.found == nil)
    end
    panel.update = Fill
    Fill(t)
end

------------------------------------------------------------------------
-- What the game wants you to look at, outlined
------------------------------------------------------------------------

local MARK_COL = { target = Color(240, 200, 90), person = Color(120, 180, 255), danger = Color(230, 80, 70), done = Color(110, 200, 110) }

hook.Add("PreDrawHalos", "LivingCityJobMarks", function()
    if not halo then return end
    local me = LocalPlayer()
    if not IsValid(me) or not (LC_CL.JobGame and LC_CL.JobGame()) then return end
    local by = {}
    for _, e in ipairs(ents.FindInSphere(me:GetPos(), 1200)) do
        if IsValid(e) and e:GetNW2Entity("lc_jg_owner") == me then
            local m = e:GetNW2String("lc_jg_mark", "")
            if MARK_COL[m] then by[m] = by[m] or {} table.insert(by[m], e) end
        end
    end
    for m, list in pairs(by) do halo.Add(list, MARK_COL[m], 2, 2, 1, true, m ~= "done") end
end)
