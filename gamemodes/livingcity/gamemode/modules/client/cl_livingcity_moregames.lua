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
    if panel and panel.kind == t.kind and IsValid(panel.frame) and panel.update then
        panel.data = t
        panel.update(t)
        return
    end
    Close(true)
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
-- Tuning a radio
------------------------------------------------------------------------

local LOW, HIGH = 87.5, 108
local nextHiss = 0

function LC_CL.RadioSignal(dial, d)
    local s = math.exp(-((dial - (d.t or 0)) / 0.8) ^ 2)
    if d.f7 then s = math.max(s, math.exp(-((dial - d.f7) / 0.8) ^ 2)) end
    return s
end

BUILD.radio = function(t)
    local f = Frame("Tuning: turn the dial until the static clears, then lock it", 560, 330)
    panel.frame = f
    local dial = vgui.Create("DNumSlider", f)
    dial:Dock(TOP)
    dial:DockMargin(10, 90, 10, 0)
    dial:SetText("Frequency")
    dial:SetMin(LOW)
    dial:SetMax(HIGH)
    dial:SetDecimals(1)
    dial:SetValue(LOW + math.random() * (HIGH - LOW))
    local meter = vgui.Create("DPanel", f)
    meter:SetPos(10, 30)
    meter:SetSize(f:GetWide() - 20, 56)
    meter.Paint = function(s, w, h)
        local d = panel and panel.data or t
        local sig = LC_CL.RadioSignal(dial:GetValue(), d)
        draw.RoundedBox(4, 0, 0, w, h, CARD)
        draw.SimpleText(string.format("%.1f", dial:GetValue()), "DermaLarge", 12, h / 2, INK, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        draw.RoundedBox(2, 120, 18, (w - 220) * sig, 20, sig > 0.85 and GOOD or (sig > 0.4 and WARN or BAD))
        draw.SimpleText(string.format("Set %d of %d   %d s", d.n or 1, d.of or 4, d.secs or 0), "LCJobLine", w - 10, h / 2, DIM, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
        if CurTime() > nextHiss and sig < 0.85 then
            nextHiss = CurTime() + 1.2
            surface.PlaySound("ambient/levels/prison/radio_random" .. math.random(1, 15) .. ".wav")
        end
    end
    local lock = Button(f, "Lock it", GOOD, function() Act("lock", math.floor(dial:GetValue() * 10 + 0.5) / 10) end)
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
        if d.heard then surface.PlaySound("ambient/levels/prison/radio_random" .. math.random(1, 15) .. ".wav") end
    end
    panel.update = Upd
    Upd(t)
end

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
