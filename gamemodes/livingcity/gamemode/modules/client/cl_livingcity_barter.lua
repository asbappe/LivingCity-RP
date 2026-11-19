--[[
    Living City (client): the quartermaster's barter (sv_livingcity_armory.lua)

    From his window's Barter button. Two lists side by side: yours (what he'd buy from you, at what he pays)
    and his (his stock, at what he charges), each with a total in credits. Credits from your pocket can go
    on your side; when yours is worth more, the fund's part shows on his. Under it all, the Goodwill bar
    (what is left of his leniency against its full size, the number on hovering) with a short trade's
    shortfall shaded on it, and Trade, greyed when the shortfall is more than the bar holds. A refusal, if
    there was one, is one line above them. The server works it all out again; this only shows it.
]]

LC_CL = LC_CL or {}

local INK, DIM, ACCENT, WARN = Color(232, 226, 210), Color(170, 165, 150), Color(230, 180, 90), Color(235, 120, 100)
local ROW, BACK, FILL, SHADE, OVER = Color(30, 24, 22, 240), Color(50, 42, 38, 255), Color(120, 190, 120), Color(225, 190, 90), Color(225, 95, 80)
local frame

local function ReadCompressed()
    local len = net.ReadUInt(32)
    local data = net.ReadData(len)
    local json = util.Decompress(data or "")
    return json and util.JSONToTable(json) or nil
end

-- What the trade comes to, worked out the way the server will: each side's total in credits, the credits of
-- yours that are used, the fund's part, the shortfall, and whether Trade may be pressed.
function LC_CL.BarterSums(t, mine, his, credits)
    local Y, H, any = 0, 0, false
    for _, r in ipairs(t.yours or {}) do
        local n = mine[r.id] or 0
        if n > 0 then Y, any = Y + n * (r.price or 0), true end
    end
    for _, r in ipairs(t.his or {}) do H = H + (his[r.id] or 0) * (r.price or 0) end
    local c = math.min(math.max(0, math.floor(credits or 0)), t.credits or 0, math.max(0, H - Y))
    local short, fund = H - Y - c, 0
    if short < 0 then fund, short = math.min(-short, t.fund or 0), 0 end
    local left = math.floor((t.goodwill or 0) + 1e-9)
    return { yours = Y + c, his = H + fund, credits = c, fund = fund, short = short, can = any and short <= left, left = left }
end

-- The thin bar: what is left of the allowance against its full size; a shortfall shaded on its own scale.
function LC_CL.BarterBarPaint(t, short, w, h)
    local full = math.max(1, t.full or 0)
    local left = math.Clamp(t.goodwill or 0, 0, full)
    draw.RoundedBox(2, 0, 0, w, h, BACK)
    local lw = math.floor(w * left / full + 0.5)
    if lw > 0 then draw.RoundedBox(2, 0, 0, lw, h, FILL) end
    if (short or 0) > 0 then
        local sw = math.min(w, math.floor(w * short / full + 0.5))
        local x = math.max(0, lw - sw)
        surface.SetDrawColor(short <= math.floor(left + 1e-9) and SHADE or OVER)
        surface.DrawRect(x, 0, math.max(1, sw), h)
    end
end

net.Receive("lc_barter", function()
    local t = ReadCompressed()
    if not istable(t) then return end
    if IsValid(frame) then frame:Remove() end
    local mine, his, credits = {}, {}, 0
    for _, r in ipairs(t.yours or {}) do
        local n = istable(t.pre) and tonumber(t.pre[r.id]) or 0
        if n > 0 then mine[r.id] = math.min(n, r.n or 1) end
    end
    local state = LC_CL.BarterSums(t, mine, his, credits)

    frame = vgui.Create("DFrame")
    LC_CL.BarterFrame = frame
    if LC_CL.SetTheme then LC_CL.SetTheme(frame, "rebel") end
    frame:SetTitle("")
    frame:SetSize(math.min(ScrW() - 40, 660), math.min(ScrH() - 40, 520))
    frame:Center()
    frame:MakePopup()
    frame.Paint = function(self, w, h)
        draw.RoundedBox(4, 0, 0, w, h, Color(14, 12, 12, 245))
        draw.SimpleText("BARTER", "DermaLarge", 16, 28, ACCENT)
        draw.SimpleText(string.format("%d credits", t.credits or 0), "DermaDefault", w - 16, 38, ACCENT, TEXT_ALIGN_RIGHT)
    end

    -- under it all: the Goodwill bar, and Trade
    local bottom = vgui.Create("DPanel", frame)
    bottom:Dock(BOTTOM)
    bottom:SetTall(34)
    bottom:DockMargin(10, 4, 10, 8)
    bottom.Paint = function() end
    local trade = vgui.Create("DButton", bottom)
    trade:Dock(RIGHT)
    trade:SetWide(150)
    trade:SetText("Trade")
    local label = vgui.Create("DLabel", bottom)
    label:Dock(LEFT)
    label:SetWide(70)
    label:SetTextColor(DIM)
    label:SetText("Goodwill")
    local holder = vgui.Create("DPanel", bottom)
    holder:Dock(LEFT)
    holder:SetWide(170)
    holder.Paint = function() end
    local bar = vgui.Create("DPanel", holder)
    bar:Dock(FILL)
    bar:DockMargin(0, 13, 0, 13) -- (a thin bar: the owner chose it, 19 November)
    bar:SetTooltip(string.format("Goodwill: %d credits", math.floor((t.goodwill or 0) + 1e-9)))
    bar.Paint = function(self, w, h) LC_CL.BarterBarPaint(t, state.short, w, h) end
    LC_CL.BarterBar = bar
    if t.status then
        local s = vgui.Create("DLabel", frame)
        s:Dock(BOTTOM)
        s:DockMargin(12, 0, 12, 0)
        s:SetTall(18)
        s:SetTextColor(WARN)
        s:SetText(t.status)
    end

    -- the two sides
    local body = vgui.Create("DPanel", frame)
    body:Dock(FILL)
    body:DockMargin(6, 44, 6, 0)
    body.Paint = function() end
    local function Side(dock, title)
        local col = vgui.Create("DPanel", body)
        col:Dock(dock)
        if dock == LEFT then col:SetWide(math.floor((frame:GetWide() - 12) / 2)) col:DockMargin(0, 0, 6, 0) end
        col.Paint = function() end
        local head = vgui.Create("DLabel", col)
        head:Dock(TOP)
        head:SetFont("DermaDefaultBold")
        head:SetTextColor(ACCENT)
        head:SetText(title)
        local total = vgui.Create("DLabel", col)
        total:Dock(BOTTOM)
        total:SetTall(22)
        total:SetFont("DermaDefaultBold")
        total:SetTextColor(INK)
        local scroll = vgui.Create("DScrollPanel", col)
        scroll:Dock(FILL)
        return col, scroll, total
    end
    local yoursCol, yoursList, yoursTotal = Side(LEFT, "Yours")
    local _, hisList, hisTotal = Side(FILL, "His")
    local fundRow, wang

    local function Refresh()
        state = LC_CL.BarterSums(t, mine, his, credits)
        yoursTotal:SetText(string.format("%d credits", state.yours))
        hisTotal:SetText(string.format("%d credits", state.his))
        if IsValid(fundRow) then fundRow:SetVisible(state.fund > 0) end
        trade:SetEnabled(state.can)
    end

    -- one thing: its name (and how many you have), what it's worth, and how many go in the trade
    local function Row(list, r, counts, max, held)
        local row = vgui.Create("DPanel", list)
        row:Dock(TOP)
        row:DockMargin(0, 0, 0, 4)
        row:SetTall(28)
        row.Paint = function(self, w, h)
            draw.RoundedBox(3, 0, 0, w, h, ROW)
            local n = counts[r.id] or 0
            draw.SimpleText(held and string.format("%s  x%d", r.name, held) or r.name, "DermaDefault", 8, h / 2, n > 0 and INK or DIM, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            draw.SimpleText(tostring(r.price), "DermaDefault", w - 92, h / 2, DIM, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
            draw.SimpleText(tostring(n), "DermaDefaultBold", w - 46, h / 2, n > 0 and ACCENT or DIM, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        local plus = vgui.Create("DButton", row)
        plus:Dock(RIGHT)
        plus:SetWide(24)
        plus:DockMargin(0, 3, 4, 3)
        plus:SetText("+")
        plus.DoClick = function() counts[r.id] = math.min(max, (counts[r.id] or 0) + 1) Refresh() end
        local gap = vgui.Create("DPanel", row)
        gap:Dock(RIGHT)
        gap:SetWide(20)
        gap.Paint = function() end
        local minus = vgui.Create("DButton", row)
        minus:Dock(RIGHT)
        minus:SetWide(24)
        minus:DockMargin(0, 3, 0, 3)
        minus:SetText("-")
        minus.DoClick = function()
            local n = math.max(0, (counts[r.id] or 0) - 1)
            counts[r.id] = n > 0 and n or nil
            Refresh()
        end
        return row
    end
    for _, r in ipairs(t.yours or {}) do Row(yoursList, r, mine, r.n or 1, r.n or 1) end
    for _, r in ipairs(t.his or {}) do Row(hisList, r, his, r.max or 1) end

    -- credits from your pocket, on your side
    local cash = vgui.Create("DPanel", yoursCol)
    cash:Dock(BOTTOM)
    cash:SetTall(26)
    cash.Paint = function(self, w, h) draw.SimpleText("Credits", "DermaDefault", 8, h / 2, DIM, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER) end
    wang = vgui.Create("DNumberWang", cash)
    wang:Dock(RIGHT)
    wang:SetWide(80)
    wang:SetMin(0)
    wang:SetMax(math.max(0, t.credits or 0))
    wang:SetValue(0)
    wang.OnValueChanged = function(_, v) credits = math.floor(tonumber(v) or 0) Refresh() end
    -- the fund's part, on his side, when yours is worth more
    fundRow = vgui.Create("DPanel", hisList)
    fundRow:Dock(TOP)
    fundRow:SetTall(28)
    fundRow.Paint = function(self, w, h)
        draw.RoundedBox(3, 0, 0, w, h, ROW)
        draw.SimpleText("Fund", "DermaDefault", 8, h / 2, INK, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        draw.SimpleText(tostring(state.fund), "DermaDefaultBold", w - 46, h / 2, ACCENT, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    trade.DoClick = function()
        if not state.can then return end
        local function Write(counts)
            local list = {}
            for id, n in pairs(counts) do if n > 0 then list[#list + 1] = { id, n } end end
            net.WriteUInt(#list, 8)
            for _, e in ipairs(list) do net.WriteString(e[1]) net.WriteUInt(e[2], 16) end
        end
        net.Start("lc_barter")
        net.WriteUInt(2, 2)
        net.WriteUInt(state.credits, 32)
        Write(mine)
        Write(his)
        net.SendToServer()
    end
    LC_CL.BarterState = function() return state, mine, his end
    Refresh()
end)
