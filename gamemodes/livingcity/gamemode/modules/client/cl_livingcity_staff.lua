--[[
    Living City (client): the staff panel (!staff), and being warned.
]]

LC_CL = LC_CL or {}

local function ReadCompressed()
    local len = net.ReadUInt(32)
    local data = net.ReadData(len)
    local json = util.Decompress(data or "")
    return json and util.JSONToTable(json) or nil
end

local INK, DIM, RED, AMBER, CYAN = Color(230, 230, 230), Color(150, 150, 150), Color(230, 90, 80), Color(235, 190, 80), Color(110, 190, 230)
local frame, data, selectedTicket, logFilter, logSearch = nil, nil, nil, "all", ""

local function Do(action, a, b)
    net.Start("lc_staff_do")
    net.WriteString(action)
    net.WriteString(tostring(a or ""))
    net.WriteString(tostring(b or ""))
    net.SendToServer()
end

local function When(t)
    local ok, s = pcall(os.date, "%d/%m %H:%M", t or 0)
    return ok and s or ""
end

local function Label(parent, text, col, font)
    local l = vgui.Create("DLabel", parent)
    l:Dock(TOP)
    l:SetWrap(true)
    l:SetAutoStretchVertical(true)
    l:SetFont(font or "DermaDefault")
    l:SetTextColor(col or INK)
    l:SetText(text)
    l:DockMargin(0, 2, 0, 2)
    return l
end

local function Row(parent, h)
    local r = vgui.Create("DPanel", parent)
    r:Dock(TOP)
    r:SetTall(h or 26)
    r:DockMargin(0, 3, 0, 3)
    r.Paint = nil
    return r
end

local function Btn(row, text, w, fn)
    local b = vgui.Create("DButton", row)
    b:Dock(LEFT)
    b:SetWide(w)
    b:DockMargin(0, 0, 4, 0)
    b:SetText(text)
    b.DoClick = fn
    return b
end

local function Ask(title, prompt, fn)
    Derma_StringRequest(title, prompt, "", function(v) if string.Trim(v) ~= "" then fn(v) end end)
end

------------------------------------------------------------------------

local function TicketsTab(sheet)
    local p = vgui.Create("DPanel", sheet)
    p.Paint = nil
    local list = vgui.Create("DListView", p)
    list:Dock(LEFT)
    list:SetWide(300)
    list:SetMultiSelect(false)
    list:AddColumn("#"):SetFixedWidth(30)
    list:AddColumn("Player")
    list:AddColumn("Status"):SetFixedWidth(70)
    local detail = vgui.Create("DScrollPanel", p)
    detail:Dock(FILL)
    detail:DockMargin(8, 0, 0, 0)
    local canvas = detail:GetCanvas()
    local function Show(t)
        canvas:Clear()
        if not t then Label(canvas, "Pick a ticket.", DIM) return end
        Label(canvas, string.format("#%d  %s (%s)   %s", t.id, t.name or "?", t.char or "", t.status == "claimed" and ("claimed by " .. (t.claimedBy or "?")) or t.status), CYAN, "DermaDefaultBold")
        for _, m in ipairs(t.msgs or {}) do
            Label(canvas, When(m.t) .. "  " .. (m.from or "?") .. ": " .. (m.text or ""), m.staff and AMBER or INK)
        end
        local row = Row(canvas)
        Btn(row, "Claim", 70, function() Do("ticket", t.id .. "|claim") end)
        Btn(row, "Go to", 70, function() Do("ticket", t.id .. "|goto") end)
        Btn(row, "Bring", 70, function() Do("ticket", t.id .. "|bring") end)
        Btn(row, "Close", 70, function() Do("ticket", t.id .. "|close") end)
        local reply = vgui.Create("DTextEntry", canvas)
        reply:Dock(TOP)
        reply:SetTall(24)
        reply:SetPlaceholderText("Reply (Enter to send)")
        reply.OnEnter = function(self) if self:GetValue() ~= "" then Do("ticket", t.id .. "|reply", self:GetValue()) end end
    end
    for i = #(data.tickets or {}), 1, -1 do
        local t = data.tickets[i]
        local line = list:AddLine(t.id, t.name or "?", t.status)
        line.ticket = t
        if selectedTicket == t.id then list:SelectItem(line) end
    end
    list.OnRowSelected = function(_, _, line) selectedTicket = line.ticket.id Show(line.ticket) end
    local sel
    for _, t in ipairs(data.tickets or {}) do if t.id == selectedTicket then sel = t end end
    Show(sel)
    local open = 0
    for _, t in ipairs(data.tickets or {}) do if t.status ~= "closed" then open = open + 1 end end
    sheet:AddSheet("Tickets (" .. open .. " open)", p)
end

local KINDS = { "all", "chat", "kill", "arrest", "warning", "ticket", "admin", "charban", "connect", "system", "error" }

local function LogsTab(sheet)
    local p = vgui.Create("DPanel", sheet)
    p.Paint = nil
    local top = Row(p, 24)
    top:DockMargin(0, 0, 0, 4)
    local kind = vgui.Create("DComboBox", top)
    kind:Dock(LEFT)
    kind:SetWide(120)
    for _, k in ipairs(KINDS) do kind:AddChoice(k, k, k == logFilter) end
    local search = vgui.Create("DTextEntry", top)
    search:Dock(FILL)
    search:DockMargin(4, 0, 0, 0)
    search:SetPlaceholderText("Search (a name, a word, a SteamID)")
    search:SetValue(logSearch)
    local list = vgui.Create("DListView", p)
    list:Dock(FILL)
    list:AddColumn("When"):SetFixedWidth(90)
    list:AddColumn("Kind"):SetFixedWidth(60)
    list:AddColumn("What")
    local function Fill()
        list:Clear()
        local q = string.lower(logSearch or "")
        local logs = data.logs or {}
        for i = #logs, 1, -1 do
            local e = logs[i]
            if (logFilter == "all" or e.kind == logFilter) and (q == "" or string.find(string.lower(e.text or ""), q, 1, true) or (e.sid and string.find(string.lower(e.sid), q, 1, true))) then
                list:AddLine(When(e.t), e.kind, e.text)
            end
        end
    end
    kind.OnSelect = function(_, _, _, v) logFilter = v Fill() end
    search.OnChange = function(self) logSearch = self:GetValue() Fill() end
    Fill()
    sheet:AddSheet("Logs", p)
end

local function PlayersTab(sheet)
    local p = vgui.Create("DScrollPanel", sheet)
    local c = p:GetCanvas()
    for _, pl in ipairs(data.players or {}) do
        local box = vgui.Create("DPanel", c)
        box:Dock(TOP)
        box:SetTall(58)
        box:DockMargin(0, 2, 0, 2)
        box.Paint = function(self, w, h)
            draw.RoundedBox(4, 0, 0, w, h, Color(28, 30, 36, 240))
            draw.SimpleText(string.format("%s   as %s %s", pl.name or "?", pl.char or "?", pl.cid ~= "" and ("(" .. pl.cid .. ")") or ""), "DermaDefaultBold", 8, 6, INK)
            draw.SimpleText(string.format("%s   %s   warnings: %d", pl.sid or "", pl.faction or "", pl.warnings or 0), "DermaDefault", 8, 22,
                (pl.warnings or 0) > 0 and AMBER or DIM)
        end
        local row = vgui.Create("DPanel", box)
        row:Dock(BOTTOM)
        row:SetTall(22)
        row:DockMargin(8, 0, 8, 4)
        row.Paint = nil
        Btn(row, "Go to", 60, function() Do("goto", pl.sid) end)
        Btn(row, "Bring", 60, function() Do("bring", pl.sid) end)
        Btn(row, "Warn", 60, function() Ask("Warn " .. pl.name, "Why?", function(v) Do("warn", pl.sid, v) end) end)
        local cb = Btn(row, "Ban character", 100, function()
            Ask("Ban " .. (pl.char or "this character"), "The character is wiped and their name can't be used again. Why?", function(v) Do("charban", pl.sid, v) end)
        end)
        cb:SetTextColor(RED)
    end
    sheet:AddSheet("Players (" .. #(data.players or {}) .. ")", p)
end

local function WarningsTab(sheet)
    local p = vgui.Create("DScrollPanel", sheet)
    local c = p:GetCanvas()
    if #(data.warnings or {}) == 0 then Label(c, "No warnings.", DIM) end
    for _, w in ipairs(data.warnings or {}) do
        local row = Row(c, 24)
        local l = vgui.Create("DLabel", row)
        l:Dock(FILL)
        l:SetTextColor(INK)
        l:SetText(string.format("%s  %s: %s  (by %s)", When(w.t), w.name or w.sid, w.reason or "", w.by or "?"))
        local b = vgui.Create("DButton", row)
        b:Dock(RIGHT)
        b:SetWide(80)
        b:SetText("Strike off")
        b.DoClick = function() Do("unwarn", w.sid, w.idx) end
    end
    sheet:AddSheet("Warnings", p)
end

local function BansTab(sheet)
    local p = vgui.Create("DScrollPanel", sheet)
    local c = p:GetCanvas()
    if #(data.bans or {}) == 0 then Label(c, "No characters banned.", DIM) end
    for i, b in ipairs(data.bans or {}) do
        local row = Row(c, 24)
        local l = vgui.Create("DLabel", row)
        l:Dock(FILL)
        l:SetTextColor(INK)
        l:SetText(string.format("%s  %s (%s), player %s: %s  (by %s)", When(b.t), b.name or "?", b.cid or "", b.player or "?", b.reason or "", b.by or "?"))
        local x = vgui.Create("DButton", row)
        x:Dock(RIGHT)
        x:SetWide(80)
        x:SetText("Lift")
        x.DoClick = function() Do("unban", i) end
    end
    sheet:AddSheet("Character bans", p)
end

net.Receive("lc_staff", function()
    local t = ReadCompressed()
    if not t then return end
    data = t
    local x, y, tab
    if IsValid(frame) then
        x, y = frame:GetPos()
        local active = frame.sheet and frame.sheet:GetActiveTab()
        tab = active and active.GetText and active:GetText() or nil
        frame:Remove()
    end
    frame = vgui.Create("DFrame")
    if LC_CL.SetTheme then LC_CL.SetTheme(frame, "staff") end -- (out of character: cl_livingcity_theme.lua)
    frame:SetTitle("Staff")
    frame:SetSize(math.min(ScrW() - 40, 980), math.min(ScrH() - 40, 640))
    if x then frame:SetPos(x, y) else frame:Center() end
    frame:MakePopup()
    local sheet = vgui.Create("DPropertySheet", frame)
    sheet:Dock(FILL)
    frame.sheet = sheet
    TicketsTab(sheet)
    LogsTab(sheet)
    PlayersTab(sheet)
    WarningsTab(sheet)
    BansTab(sheet)
    if tab and type(sheet.Items) == "table" then
        for _, it in ipairs(sheet.Items) do
            if it.Tab and it.Tab.GetText and string.sub(it.Tab:GetText(), 1, 5) == string.sub(tab, 1, 5) then sheet:SetActiveTab(it.Tab) end
        end
    end
end)

-- Open tickets, for staff, under the clock
-- (made once here, not every frame)
local C_60_30_20_200 = Color(60, 30, 20, 200)
hook.Add("HUDPaint", "LivingCityStaffTickets", function()
    local ply = LocalPlayer()
    if not IsValid(ply) or not ply:IsAdmin() then return end
    local n = math.floor(GetGlobal2Float("lc_tickets_open", 0))
    if n <= 0 then return end
    draw.RoundedBox(4, ScrW() - 150, 40, 136, 22, C_60_30_20_200)
    draw.SimpleText(n .. (n == 1 and " open ticket" or " open tickets") .. " (!staff)", "DermaDefault", ScrW() - 82, 51, AMBER, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end)

------------------------------------------------------------------------
-- Being warned
------------------------------------------------------------------------

local warned
net.Receive("lc_warned", function()
    warned = { reason = net.ReadString(), by = net.ReadString(), n = net.ReadUInt(8), at = CurTime() }
    surface.PlaySound("buttons/button10.wav")
end)

hook.Add("HUDPaint", "LivingCityWarned", function()
    if not warned then return end
    local t = CurTime() - warned.at
    if t > 10 then warned = nil return end
    local a = math.Clamp(math.min(t / 0.3, (10 - t) / 0.6), 0, 1)
    local w, h = math.min(ScrW() - 80, 620), 96
    local x, y = ScrW() / 2 - w / 2, ScrH() * 0.3
    draw.RoundedBox(6, x, y, w, h, Color(40, 12, 10, 235 * a))
    draw.RoundedBox(0, x, y, w, 3, Color(RED.r, RED.g, RED.b, 255 * a))
    draw.SimpleText("YOU HAVE BEEN WARNED BY STAFF", "DermaLarge", ScrW() / 2, y + 26, Color(255, 200, 190, 255 * a), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    draw.SimpleText(warned.reason, "DermaDefaultBold", ScrW() / 2, y + 56, Color(240, 240, 240, 255 * a), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    draw.SimpleText(string.format("Warning %d, from %s", warned.n or 1, warned.by or "staff"), "DermaDefault", ScrW() / 2, y + 76,
        Color(200, 200, 200, 255 * a), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end)
