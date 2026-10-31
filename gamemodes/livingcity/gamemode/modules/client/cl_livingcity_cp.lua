--[[
    Living City (client): Civil Protection's toolset.
      The records terminal (!records), the voice line menu (!vo, or bind a key
      to lc_vo_menu), the mask's view for units (lc_mask_overlay 0 turns it
      off), the sociostability level, and what being tied up looks like.
]]

LC_CL = LC_CL or {}

local cvMask = CreateClientConVar("lc_mask_overlay", "1", true, false, "Civil Protection units see through the mask's lenses")

local function ReadCompressed()
    local len = net.ReadUInt(32)
    local data = net.ReadData(len)
    local json = util.Decompress(data or "")
    return json and util.JSONToTable(json) or nil
end

local INK, DIM, RED, AMBER = Color(230, 232, 236), Color(150, 156, 166), Color(235, 90, 80), Color(235, 190, 80)
local PANEL_BG = Color(18, 22, 28, 240)
local CYAN = Color(110, 190, 230)

local function Masked(ply)
    local f = ply:GetNW2String("lcf_faction", "")
    return f == "cp" or ply:GetNW2String("lcd_disguise", "") == "cp"
end
LC_CL.Masked = Masked

local function SocioLevel() return GetGlobal2String("lc_socio", "green") end

------------------------------------------------------------------------
-- The records terminal
------------------------------------------------------------------------

local rec, recFrame, selectedKey

local function Do(action, key, text, num)
    net.Start("lc_records_do")
    net.WriteString(action)
    net.WriteString(key or "")
    net.WriteString(text or "")
    net.WriteString(tostring(num or ""))
    net.SendToServer()
end

local function When(t)
    if not t then return "" end
    local ok, s = pcall(os.date, "%d/%m %H:%M", t)
    return ok and s or ""
end

local function Text(parent, text, col, font)
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

local function Bar(parent, h)
    local r = vgui.Create("DPanel", parent)
    r:Dock(TOP)
    r:SetTall(h or 24)
    r:DockMargin(0, 3, 0, 3)
    r.Paint = nil
    return r
end

local function Button(row, text, w, fn)
    local b = vgui.Create("DButton", row)
    b:Dock(LEFT)
    b:SetWide(w)
    b:DockMargin(0, 0, 4, 0)
    b:SetText(text)
    b.DoClick = fn
    return b
end

-- One line to type into and a button to send it.
local function Entry(parent, placeholder, label, w, fn)
    local row = Bar(parent, 24)
    local e = vgui.Create("DTextEntry", row)
    e:Dock(FILL)
    e:SetPlaceholderText(placeholder)
    local b = vgui.Create("DButton", row)
    b:Dock(RIGHT)
    b:SetWide(w or 110)
    b:DockMargin(4, 0, 0, 0)
    b:SetText(label)
    b.DoClick = function() local v = e:GetValue() if v ~= "" then fn(v) e:SetValue("") end end
    e.OnEnter = b.DoClick
    return e
end

local function FindPerson(key)
    for _, p in ipairs(rec and rec.people or {}) do if p.key == key then return p end end
end

local function FillDetail(detail, p)
    detail:Clear()
    if not p then
        Text(detail, "Pick a citizen on the left.", DIM)
        return
    end
    Text(detail, p.name or "?", INK, "DermaLarge")
    Text(detail, "CID " .. (p.cid or "?") .. (p.online and "   (in the city now)" or ("   (last seen " .. When(p.seen) .. ")")), DIM)
    local status = {}
    if p.standing then status[#status + 1] = string.format("Loyalty points %d (%s)", p.standing, p.tier or "") end
    if p.wanted then status[#status + 1] = "WANTED" end
    if p.custody then status[#status + 1] = "in custody" end
    if p.tied then status[#status + 1] = "restrained" end
    for _, b in ipairs(rec.bolos or {}) do if b.key == p.key then status[#status + 1] = "BOLO: " .. b.text end end
    if #status > 0 then Text(detail, table.concat(status, "   |   "), (p.wanted or #status > 1) and AMBER or INK, "DermaDefaultBold") end

    if p.online and p.standing then
        local row = Bar(detail)
        local cap = rec.officer and 25 or 10
        Button(row, "+" .. cap .. " loyalty", 100, function() Do("loyalty", p.key, "", cap) end)
        Button(row, "-" .. cap .. " loyalty", 100, function() Do("loyalty", p.key, "", -cap) end)
        if rec.officer and p.license then Button(row, "Revoke business license", 170, function() Do("revoke", p.key) end) end
    end

    Text(detail, string.format("Violations (%d)", p.violations or 0), CYAN, "DermaDefaultBold")
    if #(p.v or {}) == 0 then Text(detail, "None on record.", DIM) end
    for i = #(p.v or {}), 1, -1 do
        local v = p.v[i]
        Text(detail, When(v.t) .. "   " .. v.text .. (v.by and ("   (" .. v.by .. ")") or ""))
    end
    Entry(detail, "Log a violation (e.g. 'False request')", "Add violation", 110, function(v) Do("violation", p.key, v) end)

    Text(detail, "Notes", CYAN, "DermaDefaultBold")
    if #(p.n or {}) == 0 then Text(detail, "No notes.", DIM) end
    for i = #(p.n or {}), 1, -1 do
        local n = p.n[i]
        Text(detail, When(n.t) .. "   " .. n.text .. (n.by and ("   (" .. n.by .. ")") or ""))
    end
    Entry(detail, "Add a note", "Add note", 110, function(v) Do("note", p.key, v) end)

    Text(detail, "Be on the lookout", CYAN, "DermaDefaultBold")
    Entry(detail, "What to look out for (30 minutes)", "Issue BOLO", 110, function(v) Do("bolo", p.key, v, 30) end)
end

local function BuildRecords()
    local x, y
    if IsValid(recFrame) then x, y = recFrame:GetPos() recFrame:Remove() end
    recFrame = vgui.Create("DFrame")
    recFrame:SetTitle("Civil Protection: records terminal")
    recFrame:SetSize(math.min(ScrW() - 40, 900), math.min(ScrH() - 40, 620))
    if x then recFrame:SetPos(x, y) else recFrame:Center() end
    recFrame:MakePopup()
    recFrame.Paint = function(self, w, h)
        draw.RoundedBox(6, 0, 0, w, h, PANEL_BG)
        draw.RoundedBox(0, 0, 24, w, 2, CYAN)
    end

    -- sociostability across the top; officers can set it
    local top = vgui.Create("DPanel", recFrame)
    top:Dock(TOP)
    top:SetTall(28)
    top:DockMargin(0, 2, 0, 4)
    local level = LCCP and LCCP.Socio[rec.socio or "green"]
    top.Paint = function(self, w, h)
        if level then draw.SimpleText("SOCIOSTABILITY: " .. level.name, "DermaDefaultBold", 4, h / 2, level.color, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER) end
    end
    if rec.officer then
        local holder = vgui.Create("DPanel", top)
        holder:Dock(RIGHT)
        holder:SetWide(330)
        holder.Paint = nil
        for _, lv in ipairs({ { "auto", "Auto" }, { "red", "Red" }, { "yellow", "Yellow" }, { "green", "Green" } }) do
            local b = vgui.Create("DButton", holder)
            b:Dock(RIGHT)
            b:SetWide(78)
            b:DockMargin(4, 0, 0, 0)
            b:SetText(lv[2])
            b.DoClick = function() Do("socio", lv[1], "", 15) end
        end
    end

    local sheet = vgui.Create("DPropertySheet", recFrame)
    sheet:Dock(FILL)

    -- citizens
    local people = vgui.Create("DPanel", sheet)
    people.Paint = nil
    local left = vgui.Create("DPanel", people)
    left:Dock(LEFT)
    left:SetWide(330)
    left.Paint = nil
    local search = vgui.Create("DTextEntry", left)
    search:Dock(TOP)
    search:SetPlaceholderText("Search by name or CID (people not in the city too)")
    search:SetValue(rec.search or "")
    search.OnEnter = function(self) Do("search", "", self:GetValue()) end
    local list = vgui.Create("DListView", left)
    list:Dock(FILL)
    list:DockMargin(0, 4, 0, 0)
    list:SetMultiSelect(false)
    list:AddColumn("Name")
    list:AddColumn("CID"):SetFixedWidth(80)
    list:AddColumn("Status"):SetFixedWidth(80)
    local detail = vgui.Create("DScrollPanel", people)
    detail:Dock(FILL)
    detail:DockMargin(8, 0, 0, 0)
    local canvas = detail:GetCanvas()
    for _, p in ipairs(rec.people or {}) do
        local st = p.wanted and "WANTED" or (p.custody and "custody" or (p.online and "here" or ""))
        for _, b in ipairs(rec.bolos or {}) do if b.key == p.key then st = "BOLO" end end
        local line = list:AddLine(p.name or "?", p.cid or "?", st)
        line.key = p.key
        if p.key == selectedKey then list:SelectItem(line) end
    end
    list.OnRowSelected = function(_, _, line)
        selectedKey = line.key
        FillDetail(canvas, FindPerson(line.key))
    end
    FillDetail(canvas, selectedKey and FindPerson(selectedKey) or nil)
    sheet:AddSheet("Citizens", people)

    -- BOLOs
    local bolos = vgui.Create("DScrollPanel", sheet)
    local bc = bolos:GetCanvas()
    Entry(bc, "A BOLO on a description, not a record ('male, red jacket, northbound')", "Issue BOLO", 110,
        function(v) Do("bolo", "", v, 30) end)
    if #(rec.bolos or {}) == 0 then Text(bc, "No BOLOs out.", DIM) end
    for i = #(rec.bolos or {}), 1, -1 do
        local b = rec.bolos[i]
        local row = Bar(bc, 40)
        local lbl = vgui.Create("DLabel", row)
        lbl:Dock(FILL)
        lbl:SetWrap(true)
        lbl:SetTextColor(INK)
        local left2 = math.max(0, math.floor(((b.untilT or 0) - os.time()) / 60))
        lbl:SetText(string.format("%s%s\n%s, %s, %d min left", b.name and (b.name .. " (" .. (b.cid or "") .. "): ") or "", b.text,
            b.by or "?", When(b.at), left2))
        local x2 = vgui.Create("DButton", row)
        x2:Dock(RIGHT)
        x2:SetWide(80)
        x2:SetText("Cancel")
        x2.DoClick = function() Do("clearbolo", b.id) end
    end
    sheet:AddSheet("BOLOs (" .. #(rec.bolos or {}) .. ")", bolos)

    -- requests
    local reqs = vgui.Create("DScrollPanel", sheet)
    local rc = reqs:GetCanvas()
    if #(rec.requests or {}) == 0 then Text(rc, "No requests.", DIM) end
    for _, q in ipairs(rec.requests or {}) do
        Text(rc, string.format("%s   %s (%s), %s:", When(q.t), q.name or "?", q.cid or "?", q.where or ""), CYAN, "DermaDefaultBold")
        Text(rc, "\"" .. (q.text or "") .. "\"")
    end
    sheet:AddSheet("Requests (" .. #(rec.requests or {}) .. ")", reqs)
end

net.Receive("lc_records", function()
    local t = ReadCompressed()
    if not t then return end
    rec = t
    BuildRecords()
end)

------------------------------------------------------------------------
-- Voice lines
------------------------------------------------------------------------

local voFrame

function LC_CL.OpenVoiceMenu()
    local ply = LocalPlayer()
    if not IsValid(ply) or not LCCP then return end
    local list = LCCP.VoiceFor(ply)
    if IsValid(voFrame) then voFrame:Remove() end
    voFrame = vgui.Create("DFrame")
    voFrame:SetTitle("Voice (or type the words, or /vo <word>)")
    voFrame:SetSize(math.min(ScrW() - 40, 560), math.min(ScrH() - 40, 600))
    voFrame:Center()
    voFrame:MakePopup()
    local filter = vgui.Create("DTextEntry", voFrame)
    filter:Dock(TOP)
    filter:SetPlaceholderText("Filter")
    local scroll = vgui.Create("DScrollPanel", voFrame)
    scroll:Dock(FILL)
    scroll:DockMargin(0, 4, 0, 0)
    local function Fill(f)
        scroll:Clear()
        local group
        f = string.lower(f or "")
        for i, l in ipairs(list) do
            if f == "" or string.find(string.lower(l[2]), f, 1, true) or string.find(l[1], f, 1, true) then
                if l[4] ~= group then
                    group = l[4]
                    local h = vgui.Create("DLabel", scroll)
                    h:Dock(TOP)
                    h:DockMargin(2, 8, 0, 2)
                    h:SetFont("DermaDefaultBold")
                    h:SetTextColor(CYAN)
                    h:SetText(string.upper(group))
                end
                local b = vgui.Create("DButton", scroll)
                b:Dock(TOP)
                b:SetTall(24)
                b:DockMargin(0, 1, 0, 1)
                b:SetText(l[2] .. "    /vo " .. l[1])
                b.DoClick = function() RunConsoleCommand("lc_vo", l[1]) end
            end
        end
    end
    filter.OnChange = function(self) Fill(self:GetValue()) end
    Fill("")
end

net.Receive("lc_vo_menu", function() LC_CL.OpenVoiceMenu() end)
concommand.Add("lc_vo_menu", function() LC_CL.OpenVoiceMenu() end)

------------------------------------------------------------------------
-- The mask's view, the sociostability level, and tied hands
------------------------------------------------------------------------


-- The lenses: dark at the edges, a cold tint, faint scanlines. Drawn under the
-- HUD, so the bars, the tracker and the tips stay readable on top of it.
local LENS_TINT, LENS_EDGE, LENS_LINE = { 10, 30, 45, 24 }, { 0, 6, 12, 190 }, { 120, 200, 255, 6 }
local function DrawLenses(w, h) LC_CL.DrawLens(w, h, LENS_TINT, LENS_EDGE, LENS_LINE) end

local function MaskOn(ply)
    if IsValid(ply:GetNW2Entity("lc_scanner")) then return false end -- looking through a scanner instead (cl_livingcity_scanner.lua)
    return Masked(ply) and cvMask:GetBool() -- stays on in build mode; it goes when you change faction
end

hook.Add("HUDPaintBackground", "LivingCityMaskLenses", function()
    local ply = LocalPlayer()
    if IsValid(ply) and ply:Alive() and MaskOn(ply) then DrawLenses(ScrW(), ScrH()) end
end)

local function DrawMask(w, h, level)
    -- the readout, top centre
    local ply = LocalPlayer()
    local socio = LCCP and LCCP.Socio[level] or { name = "?", color = INK }
    local who = ply:GetNW2String("lcf_title", "")
    if ply:GetNW2String("lcd_disguise", "") == "cp" then who = ply:GetNW2String("lcd_title", "CP") end
    local bolos = math.floor(GetGlobal2Float("lc_bolos", 0))
    local cx = w / 2
    draw.SimpleText("CIVIL PROTECTION  ::  " .. string.upper(who ~= "" and who or "UNIT"), "DermaDefaultBold", cx, 8, Color(150, 210, 240, 200), TEXT_ALIGN_CENTER)
    draw.SimpleText("SOCIOSTABILITY: " .. socio.name .. (bolos > 0 and ("     BOLO: " .. bolos) or ""), "DermaDefault", cx, 24,
        Color(socio.color.r, socio.color.g, socio.color.b, 220), TEXT_ALIGN_CENTER)
    -- the biosignal tick, so the readout feels alive
    local hp = math.Clamp(ply:Health() / math.max(1, ply:GetMaxHealth()), 0, 1)
    local bw = 120
    surface.SetDrawColor(40, 70, 90, 160)
    surface.DrawRect(cx - bw / 2, 42, bw, 3)
    surface.SetDrawColor(hp > 0.35 and 120 or 235, hp > 0.35 and 200 or 90, hp > 0.35 and 240 or 80, 220)
    surface.DrawRect(cx - bw / 2, 42, bw * hp, 3)
end

local function DrawSocioPill(w, level)
    local s = LCCP and LCCP.Socio[level]
    if not s then return end
    local text = "SOCIOSTABILITY: " .. s.name
    surface.SetFont("DermaDefaultBold")
    local tw = surface.GetTextSize(text)
    local pw = tw + 24
    local x, y = w / 2 - pw / 2, 8
    local pulse = level == "red" and (0.6 + 0.4 * math.abs(math.sin(CurTime() * 3))) or 1
    draw.RoundedBox(4, x, y, pw, 22, Color(12, 14, 18, 210))
    draw.RoundedBox(0, x, y + 20, pw, 2, Color(s.color.r, s.color.g, s.color.b, 255 * pulse))
    draw.SimpleText(text, "DermaDefaultBold", w / 2, y + 11, Color(s.color.r, s.color.g, s.color.b, 255 * pulse), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end

hook.Add("HUDPaint", "LivingCityCPHUD", function()
    local ply = LocalPlayer()
    if not IsValid(ply) or not ply:Alive() then return end
    local w, h = ScrW(), ScrH()
    local level = SocioLevel()
    if MaskOn(ply) then
        DrawMask(w, h, level)
    elseif level ~= "green" then
        DrawSocioPill(w, level)
    end
    if ply:GetNW2Bool("lc_tied", false) then
        draw.SimpleTextOutlined("YOUR HANDS ARE TIED", "DermaDefaultBold", w / 2, h * 0.82, AMBER, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, color_black)
        draw.SimpleTextOutlined("!struggle to work at the cuffs when nobody's looking", "DermaDefault", w / 2, h * 0.82 + 18, INK, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, color_black)
    elseif ply:GetNW2Bool("lc_handsup", false) then
        draw.SimpleTextOutlined("HANDS UP  (!handsup to lower them)", "DermaDefaultBold", w / 2, h * 0.82, Color(200, 220, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, color_black)
    end
end)
