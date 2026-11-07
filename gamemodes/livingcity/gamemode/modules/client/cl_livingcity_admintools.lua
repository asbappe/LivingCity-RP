--[[
    Living City (client): the admins' testing panel. !admintools, or the button
    on the F4 screen. Everything it does is checked again on the server.
]]

LC_CL = LC_CL or {}

local function ReadCompressed()
    local len = net.ReadUInt(32)
    local data = net.ReadData(len)
    local json = util.Decompress(data or "")
    return json and util.JSONToTable(json) or nil
end

local frame, state

local function Do(action, value)
    net.Start("lc_admintools_do")
    net.WriteString(action)
    net.WriteString(tostring(value or ""))
    net.WriteString(state and state.target or "")
    net.SendToServer()
end

local INK, DIM = Color(230, 230, 230), Color(160, 160, 160)

local function Section(parent, title)
    local p = vgui.Create("DPanel", parent)
    p:Dock(TOP)
    p:DockMargin(4, 4, 4, 4)
    p:DockPadding(10, 26, 10, 8)
    -- a docked panel doesn't grow to fit what's in it: without a height, the rows
    -- hang outside it, drawn but unclickable
    p.lcSection, p.lcH = true, 34
    p:SetTall(p.lcH)
    p.Paint = function(self, w, h)
        draw.RoundedBox(6, 0, 0, w, h, Color(24, 26, 32, 235))
        draw.SimpleText(title, "DermaDefaultBold", 10, 7, INK)
    end
    return p
end

local function Row(parent, h)
    local r = vgui.Create("DPanel", parent)
    r:Dock(TOP)
    r:SetTall(h or 26)
    r:DockMargin(0, 2, 0, 2)
    r.Paint = nil
    if parent.lcSection == true and type(parent.lcH) == "number" then
        parent.lcH = parent.lcH + (h or 26) + 4
        parent:SetTall(parent.lcH)
    end
    return r
end

local function Btn(row, text, fn, w)
    local b = vgui.Create("DButton", row)
    b:Dock(LEFT)
    b:SetWide(w or 92)
    b:DockMargin(0, 0, 4, 0)
    b:SetText(text)
    b.DoClick = fn
    return b
end

local function Label(row, text, w)
    local l = vgui.Create("DLabel", row)
    l:Dock(LEFT)
    l:SetWide(w or 150)
    l:SetTextColor(DIM)
    l:SetText(text)
    return l
end

local function Build()
    local x, y
    if IsValid(frame) then x, y = frame:GetPos() frame:Remove() end
    frame = vgui.Create("DFrame")
    frame:SetTitle("Admin: testing tools")
    frame:SetSize(math.min(ScrW() - 60, 600), math.min(ScrH() - 60, 640))
    if x then frame:SetPos(x, y) else frame:Center() end
    frame:MakePopup()

    -- who it's for
    local top = Row(frame, 26)
    top:DockMargin(4, 2, 4, 4)
    Label(top, "Acting on:", 70)
    local who = vgui.Create("DComboBox", top)
    who:Dock(FILL)
    for _, p in ipairs(state.players or {}) do who:AddChoice(p.name, p.id, p.id == state.target) end
    who.OnSelect = function(_, _, _, id) state.target = id Do("refresh") end

    local scroll = vgui.Create("DScrollPanel", frame)
    scroll:Dock(FILL)

    local f = LCF and LCF.Get and LCF.Get(state.faction or "")
    local xp = f and (state.xp or {})[f.id] or 0

    -- faction
    local sf = Section(scroll, "Faction  (switches straight away, no requirements)")
    local fr = Row(sf, 26)
    for _, fac in ipairs(LCF and LCF.Factions or {}) do
        local b = Btn(fr, fac.name, function() Do("faction", fac.id) end, 88)
        if fac.id == state.faction then b:SetEnabled(false) end
    end

    -- XP and rank
    local sx = Section(scroll, f and string.format("XP and rank  (%s: %d XP)", f.name, xp) or "XP and rank")
    if f and #f.ranks > 1 then
        local xr = Row(sx)
        for _, n in ipairs({ 50, 100, 500, 1000, 5000 }) do Btn(xr, "+" .. n, function() Do("xp", n) end, 64) end
        Btn(xr, "-100", function() Do("xp", -100) end, 64)
        local rr = Row(sx)
        Label(rr, "Set rank:", 70)
        local rank = vgui.Create("DComboBox", rr)
        rank:Dock(FILL)
        local cur = LCF.RankIndexFor and LCF.RankIndexFor(f, xp) or 1
        for i, r in ipairs(f.ranks) do rank:AddChoice(string.format("%d. %s  (%d XP)", i, r.name, r.xp or 0), i, i == cur) end
        rank.OnSelect = function(_, _, _, i) Do("rank", i) end
    else
        local nr = Row(sx)
        Label(nr, "This faction has no ranks to climb.", 300)
    end
    local zr = Row(sx)
    Btn(zr, "Reset all XP to 0", function() Do("resetxp") end, 160)

    -- credits and standing
    local sc = Section(scroll, string.format("Credits  (%s)", state.credits and tostring(state.credits) or "economy off"))
    local cr = Row(sc)
    for _, n in ipairs({ 50, 100, 500, 1000 }) do Btn(cr, "+" .. n, function() Do("credits", n) end, 64) end
    Btn(cr, "Reset to 0", function() Do("resetcredits") end, 100)
    local ss = Section(scroll, string.format("Civil Standing  (%s)", state.standing and tostring(state.standing) or "economy off"))
    local sr = Row(ss)
    for _, n in ipairs({ -100, 100 }) do Btn(sr, (n > 0 and "+" or "") .. n, function() Do("standing", n) end, 64) end
    Btn(sr, "Set -500", function() Do("setstanding", -500) end, 80)
    Btn(sr, "Set 0", function() Do("setstanding", 0) end, 64)
    Btn(sr, "Set 100 (CP)", function() Do("setstanding", 100) end, 100)
    Btn(sr, "Set 1000", function() Do("setstanding", 1000) end, 80)

    -- odds and ends
    local so = Section(scroll, "Handy")
    local orow = Row(so)
    Btn(orow, "Clear wanted", function() Do("clearwanted") end, 110)
    Btn(orow, "Feed and heal", function() Do("needs") end, 110)
    Btn(orow, "Clear conduct strikes", function() Do("pardon") end, 150)
    local ir = Row(so)
    Label(ir, "Give item:", 70)
    local items = vgui.Create("DComboBox", ir)
    items:Dock(FILL)
    local ids = {}
    for id, it in pairs(LCS and LCS.Items or {}) do ids[#ids + 1] = { id = id, name = it.name or id } end
    table.sort(ids, function(a, b) return a.name < b.name end)
    for _, it in ipairs(ids) do items:AddChoice(it.name, it.id) end
    items.OnSelect = function(_, _, _, id) Do("item", id) end

    -- the whole city (sv_livingcity_power.lua)
    local cs = Section(scroll, "The city")
    local br = Row(cs)
    Label(br, "Blackout:", 70)
    Btn(br, "Black out the city", function() Do("blackout", "on") end, 140)
    Btn(br, "Lights on", function() Do("blackout", "off") end, 90)
    Btn(br, "Follow the grid", function() Do("blackout", "auto") end, 120)
    -- territory: grow it now, for testing (superadmins; it grows along the path nodes)
    if state.superadmin then
        local tr = Row(cs)
        Label(tr, "Territory:", 70)
        Btn(tr, "Grow rebel ground now", function() Do("territory", "rebel") end, 160)
        Btn(tr, "Grow the infestation now", function() Do("territory", "infest") end, 170)
        for _, line in ipairs(state.territory or {}) do
            local lr = Row(cs, 34)
            local l = Label(lr, line, 600)
            l:Dock(FILL)
            l:SetWrap(true)
        end
        if #(state.territory or {}) == 0 then Label(Row(cs), "No rebel or infestation zones are placed.", 400) end
    end

    local sr2 = Section(scroll, "Start over")
    local rr2 = Row(sr2)
    local wipe = Btn(rr2, "Reset XP, credits and standing to 0", function() Do("resetme") end, 260)
    wipe:SetTextColor(Color(200, 60, 50))
end

net.Receive("lc_admintools", function()
    local t = ReadCompressed()
    if not t then return end
    state = t
    Build()
end)
