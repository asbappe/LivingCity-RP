--[[
    Living City (client): the tip cards that slide in on the right.
    One at a time; urgent ones go straight to the front. Keys are shown as
    the player's own bindings.
]]

LC_CL = LC_CL or {}
LC_CL.hintQueue = LC_CL.hintQueue or {}
LC_CL.hintLog = LC_CL.hintLog or {}

surface.CreateFont("LCHintTitle", { font = "Trebuchet MS", size = 19, weight = 700 })
surface.CreateFont("LCHintBody", { font = "Trebuchet MS", size = 16, weight = 500 })
surface.CreateFont("LCHintTag", { font = "Trebuchet MS", size = 13, weight = 700 })

local W = 380
local BG = Color(14, 16, 20, 232)
local ACCENT = Color(235, 180, 70)
local URGENT = Color(235, 95, 80)
local INK = Color(238, 236, 230)
local BODY = Color(200, 202, 206)
local DIM = Color(140, 142, 148)

-- What each binding is usually on, if the player hasn't bound it.
local DEFAULT_KEYS = { ["+use"] = "E", ["+reload"] = "R", ["+attack"] = "MOUSE1", ["+attack2"] = "MOUSE2",
    gm_showhelp = "F1", gm_showteam = "F2", gm_showspare1 = "F3", gm_showspare2 = "F4", ["+menu_context"] = "C" }
local NICE = { MOUSE1 = "Left click", MOUSE2 = "Right click", MOUSE3 = "Middle click" }

local function KeyName(bind)
    local k = input and input.LookupBinding and input.LookupBinding(bind)
    k = k and string.upper(k) or DEFAULT_KEYS[bind]
    return NICE[k] or k
end

function LC_CL.HintKeys(text)
    return (string.gsub(text or "", "{([%w_%+]+)}", function(n)
        if not DEFAULT_KEYS[n] then return nil end
        return "[" .. KeyName(n) .. "]"
    end))
end

local function Wrap(text, font, width)
    surface.SetFont(font)
    local lines, line = {}, ""
    for word in string.gmatch(text, "%S+") do
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

function LC_CL.ShowHint(t)
    if not t or not t.x then return end
    local h = { title = t.t or "Tip", text = LC_CL.HintKeys(t.x), urgent = t.u and true or false, dur = tonumber(t.d) or 9, key = t.k }
    MsgC(ACCENT, "[Tip] ", INK, h.title, ": ", BODY, h.text, "\n")
    table.insert(LC_CL.hintLog, h)
    while #LC_CL.hintLog > 20 do table.remove(LC_CL.hintLog, 1) end
    if h.urgent then
        -- straight to the front; whatever was showing comes back afterwards
        local cur = LC_CL.hintCur
        if cur and not cur.urgent then
            cur.start = nil
            table.insert(LC_CL.hintQueue, 1, cur)
            LC_CL.hintCur = nil
        end
        table.insert(LC_CL.hintQueue, 1, h)
    else
        table.insert(LC_CL.hintQueue, h)
    end
end

local function ReadCompressed()
    local len = net.ReadUInt(32)
    local data = net.ReadData(len)
    local json = util.Decompress(data or "")
    return json and util.JSONToTable(json) or nil
end

net.Receive("lc_hint", function() LC_CL.ShowHint(ReadCompressed()) end)

concommand.Add("lc_hint_dismiss", function()
    if LC_CL.hintCur then LC_CL.hintCur.start = CurTime() - LC_CL.hintCur.dur + 0.3 end
end)

local function Ease(f) f = math.Clamp(f, 0, 1) return 1 - (1 - f) * (1 - f) * (1 - f) end

hook.Add("HUDPaint", "LivingCityHints", function()
    local now = CurTime()
    local h = LC_CL.hintCur
    if h and h.start and now - h.start > h.dur then h = nil LC_CL.hintCur = nil end
    if not h then
        h = table.remove(LC_CL.hintQueue, 1)
        if not h then return end
        LC_CL.hintCur = h
    end
    if not h.start then
        h.start = now
        if surface.PlaySound then surface.PlaySound(h.urgent and "buttons/blip2.wav" or "buttons/blip1.wav") end
    end
    if not h.lines then h.lines = Wrap(h.text, "LCHintBody", W - 34) end

    local t = now - h.start
    local shown = Ease(t / 0.3)
    local fade = math.Clamp((h.dur - t) / 0.4, 0, 1)
    local alpha = math.min(shown, fade)
    if alpha <= 0 then return end

    local H = 54 + #h.lines * 19 + 16
    local x = ScrW() - W - 24 + (1 - shown) * (W + 40)
    local y = ScrH() - 170 - H
    local accent = h.urgent and URGENT or ACCENT
    local function A(c, mul) return Color(c.r, c.g, c.b, (c.a or 255) * alpha * (mul or 1)) end

    draw.RoundedBox(6, x, y, W, H, A(BG))
    draw.RoundedBoxEx(6, x, y, 4, H, A(accent), true, false, true, false)
    draw.SimpleText(h.urgent and "HEADS UP" or "TIP", "LCHintTag", x + 16, y + 10, A(accent))
    local more = #LC_CL.hintQueue
    if more > 0 then draw.SimpleText("+" .. more .. " more", "LCHintTag", x + W - 12, y + 10, A(DIM), TEXT_ALIGN_RIGHT) end
    draw.SimpleText(h.title, "LCHintTitle", x + 16, y + 24, A(INK))
    local ly = y + 48
    for _, l in ipairs(h.lines) do
        draw.SimpleText(l, "LCHintBody", x + 16, ly, A(BODY))
        ly = ly + 19
    end
    -- gone before you finished reading? it's kept
    draw.SimpleText("Read it again any time: " .. LC_CL.HintKeys("{+menu_context}") .. " > Tips I've seen", "LCHintTag", x + 16, ly + 2, A(DIM))
    -- how long it stays up
    local left = math.Clamp(1 - t / h.dur, 0, 1)
    draw.RoundedBox(0, x + 4, y + H - 3, (W - 8) * left, 2, A(accent, 0.6))
end)

------------------------------------------------------------------------
-- Tips I've seen (the full menu, C): every tip you've had, to read at your own pace
------------------------------------------------------------------------

local function ReadSeen()
    local len = net.ReadUInt(32)
    local data = net.ReadData(len)
    local json = util.Decompress(data or "")
    return json and util.JSONToTable(json) or nil
end

local tipsFrame
net.Receive("lc_hints_seen", function()
    local t = ReadSeen() or {}
    local list = t.list or {}
    if IsValid(tipsFrame) then tipsFrame:Remove() end
    local FW, FH = math.min(ScrW() - 40, 620), math.min(ScrH() - 40, 640)
    tipsFrame = vgui.Create("DFrame")
    tipsFrame:SetTitle("")
    tipsFrame:SetSize(FW, FH)
    tipsFrame:Center()
    tipsFrame:MakePopup()
    tipsFrame.Paint = function(self, w, h)
        draw.RoundedBox(6, 0, 0, w, h, BG)
        draw.SimpleText("TIPS YOU'VE SEEN", "LCHintTitle", 16, 12, ACCENT)
        draw.SimpleText(#list == 0 and "None yet: they come as you meet things." or (#list .. " so far, this session's first"), "LCHintBody", w - 40, 14, DIM, TEXT_ALIGN_RIGHT)
    end
    local scroll = vgui.Create("DScrollPanel", tipsFrame)
    scroll:Dock(FILL)
    scroll:DockMargin(6, 22, 6, 44)
    for _, tip in ipairs(list) do
        local text = LC_CL.HintKeys(tip.x or "")
        local lines = Wrap(text, "LCHintBody", FW - 70)
        local p = vgui.Create("DPanel", scroll)
        p:Dock(TOP)
        p:DockMargin(0, 0, 0, 6)
        p:SetTall(34 + #lines * 19)
        p.Paint = function(self, w, h)
            draw.RoundedBox(4, 0, 0, w, h, Color(26, 29, 35, 235))
            draw.RoundedBoxEx(4, 0, 0, 4, h, tip.now and ACCENT or DIM, true, false, true, false)
            draw.SimpleText(tip.t or "Tip", "LCHintTitle", 14, 6, INK)
            local y = 28
            for _, l in ipairs(lines) do draw.SimpleText(l, "LCHintBody", 14, y, BODY) y = y + 19 end
        end
    end
    local function Btn(label, x, w, fn)
        local b = vgui.Create("DButton", tipsFrame)
        b:SetPos(x, FH - 38)
        b:SetSize(w, 28)
        b:SetText(label)
        b.DoClick = fn
        return b
    end
    local function Hints(arg)
        if LC_CL.SendAction then LC_CL.SendAction("hints", arg) end
        timer.Simple(0.4, function() net.Start("lc_hints_list") net.SendToServer() end)
    end
    Btn(t.off and "Tips are off: turn them on" or "Tips are on: turn them off", 10, 220, function() Hints(t.off and "on" or "off") end)
    Btn("Show me them all again, from the start", 240, 260, function() Hints("reset") end)
    Btn("Close", FW - 90, 80, function() tipsFrame:Remove() end)
end)

