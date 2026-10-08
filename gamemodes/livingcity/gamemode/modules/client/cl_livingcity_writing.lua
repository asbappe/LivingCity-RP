--[[
    Living City (client): writing and reading notes, the Administrator's
    broadcasts, city screens and the law board.
]]

LC_CL = LC_CL or {}

local function ReadCompressed()
    local len = net.ReadUInt(32)
    local data = net.ReadData(len)
    local json = util.Decompress(data or "")
    return json and util.JSONToTable(json) or nil
end

local PAPER, INKC, DIM = Color(226, 218, 196), Color(34, 30, 26), Color(110, 104, 94)
local SCREEN_BG, SCREEN_INK, SCREEN_HEAD = Color(8, 18, 28, 245), Color(170, 215, 240), Color(110, 190, 230)

-- Lines of text that fit a width, keeping the writer's own line breaks.
-- Remembered per text, font and width: law boards and screens ask every frame.
-- (The lines it gives back are shared: read them, don't change them.)
local wrapped, wrappedN = {}, 0
local WrapUncached
function LC_CL.WrapText(text, font, width)
    text = text or ""
    local key = font .. "|" .. width
    local byKey = wrapped[key]
    if byKey and byKey[text] then return byKey[text] end
    if wrappedN > 200 then wrapped, wrappedN = {}, 0 end
    local out = WrapUncached(text, font, width)
    wrapped[key] = wrapped[key] or {}
    wrapped[key][text] = out
    wrappedN = wrappedN + 1
    return out
end

function WrapUncached(text, font, width)
    surface.SetFont(font)
    local out = {}
    for para in string.gmatch((text or "") .. "\n", "(.-)\n") do
        local line = ""
        for word in string.gmatch(para, "%S+") do
            local try = line == "" and word or (line .. " " .. word)
            if line ~= "" and surface.GetTextSize(try) > width then
                out[#out + 1] = line
                line = word
            else
                line = try
            end
        end
        out[#out + 1] = line
    end
    while #out > 0 and out[#out] == "" do table.remove(out) end
    return out
end

------------------------------------------------------------------------
-- Writing
------------------------------------------------------------------------

local function OpenWriter()
    local f = vgui.Create("DFrame")
    f:SetTitle("Write")
    f:SetSize(math.min(ScrW() - 60, 460), math.min(ScrH() - 60, 460))
    f:Center()
    f:MakePopup()
    local e = vgui.Create("DTextEntry", f)
    e:Dock(FILL)
    e:SetMultiline(true)
    e:SetFont("DermaDefaultBold")
    e:SetPlaceholderText("What do you want to write? (up to 600 characters)")
    local opts = vgui.Create("DPanel", f)
    opts:Dock(BOTTOM)
    opts:SetTall(64)
    opts.Paint = nil
    local sign = vgui.Create("DCheckBoxLabel", opts)
    sign:Dock(TOP)
    sign:DockMargin(2, 4, 0, 4)
    sign:SetText("Sign it with your name")
    sign:SetValue(false)
    local row = vgui.Create("DPanel", opts)
    row:Dock(FILL)
    row.Paint = nil
    local function Send(mode)
        local text = e:GetValue()
        if string.Trim(text) == "" then return end
        net.Start("lc_write")
        net.WriteString(string.sub(text, 1, 600))
        net.WriteString(mode)
        net.WriteBool(sign:GetChecked())
        net.SendToServer()
        f:Remove()
    end
    for _, b in ipairs({ { "Leave it here", "note" }, { "Put it up on the wall", "poster" }, { "Keep it", "keep" } }) do
        local btn = vgui.Create("DButton", row)
        btn:Dock(LEFT)
        btn:SetWide(146)
        btn:DockMargin(0, 0, 4, 0)
        btn:SetText(b[1])
        btn.DoClick = function() Send(b[2]) end
    end
end
LC_CL.OpenWriter = OpenWriter
net.Receive("lc_write_open", OpenWriter)

------------------------------------------------------------------------
-- Reading
------------------------------------------------------------------------

local function ReadDo(what, ref)
    net.Start("lc_read_do")
    net.WriteString(what)
    net.WriteString(tostring(ref or ""))
    net.SendToServer()
end

net.Receive("lc_read", function()
    local t = ReadCompressed()
    if not t then return end
    local f = vgui.Create("DFrame")
    f:SetTitle(t.poster and "A notice" or (t.letter and "A letter") or "A note")
    f:SetSize(math.min(ScrW() - 60, 420), math.min(ScrH() - 60, 480))
    f:Center()
    f:MakePopup()
    local paper = vgui.Create("DPanel", f)
    paper:Dock(FILL)
    paper:DockMargin(4, 4, 4, 4)
    local lines
    paper.Paint = function(self, w, h)
        draw.RoundedBox(2, 0, 0, w, h, PAPER)
        lines = lines or LC_CL.WrapText(t.text or "", "DermaDefaultBold", w - 30)
        local y = 14
        for _, l in ipairs(lines) do
            draw.SimpleText(l, "DermaDefaultBold", 15, y, INKC)
            y = y + 18
        end
        draw.SimpleText(t.sig and ("  " .. t.sig) or "(unsigned)", "DermaDefault", w - 15, h - 22, DIM, TEXT_ALIGN_RIGHT)
    end
    local row = vgui.Create("DPanel", f)
    row:Dock(BOTTOM)
    row:SetTall(28)
    row.Paint = nil
    local function B(text, fn)
        local b = vgui.Create("DButton", row)
        b:Dock(LEFT)
        b:SetWide(120)
        b:DockMargin(0, 0, 4, 0)
        b:SetText(text)
        b.DoClick = function() fn() f:Remove() end
    end
    if t.world then
        if t.take then B("Take it", function() ReadDo("take", t.world) end) end
        if t.tear then B("Tear it down", function() ReadDo("tear", t.world) end) end
    elseif t.carried then
        B("Leave it here", function() ReadDo("drop", t.carried) end)
        B("Put it up", function() ReadDo("post", t.carried) end)
        if t.to and #t.to > 0 then
            -- post it to someone (sv_livingcity_mail.lua): at the post office
            local b = vgui.Create("DButton", row)
            b:Dock(LEFT)
            b:SetWide(120)
            b:DockMargin(0, 0, 4, 0)
            b:SetText("Send as a letter")
            b.DoClick = function()
                local m = DermaMenu()
                for _, r in ipairs(t.to) do
                    m:AddOption(r[2], function() ReadDo("letter", t.carried .. "|" .. r[1]) f:Remove() end)
                end
                m:Open()
            end
        end
        B("Tear it up", function() ReadDo("destroy", t.carried) end)
    end
end)

function LC_CL.ReadCarriedNote(i) ReadDo("read", i) end

------------------------------------------------------------------------
-- The Administrator's broadcasts
------------------------------------------------------------------------

local cast -- { text, by, at, lines }

net.Receive("lc_broadcast", function()
    cast = { text = net.ReadString(), by = net.ReadString(), at = CurTime() }
    surface.PlaySound("npc/overwatch/radiovoice/on3.wav")
end)

hook.Add("HUDPaint", "LivingCityBroadcast", function()
    if not cast then return end
    local t = CurTime() - cast.at
    if t > 16 then cast = nil return end
    local a = math.Clamp(math.min(t / 0.4, (16 - t) / 0.8), 0, 1)
    local w = math.min(ScrW() - 80, 760)
    cast.lines = cast.lines or LC_CL.WrapText(cast.text, "DermaLarge", w - 40)
    local h = 50 + #cast.lines * 30
    local x, y = ScrW() / 2 - w / 2, ScrH() * 0.16
    draw.RoundedBox(6, x, y, w, h, Color(SCREEN_BG.r, SCREEN_BG.g, SCREEN_BG.b, 230 * a))
    draw.RoundedBox(0, x, y, w, 3, Color(SCREEN_HEAD.r, SCREEN_HEAD.g, SCREEN_HEAD.b, 255 * a))
    draw.SimpleText(string.upper(cast.by or "The City Administrator"), "DermaDefaultBold", ScrW() / 2, y + 16,
        Color(SCREEN_HEAD.r, SCREEN_HEAD.g, SCREEN_HEAD.b, 255 * a), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    for i, l in ipairs(cast.lines) do
        draw.SimpleText(l, "DermaLarge", ScrW() / 2, y + 36 + (i - 1) * 30, Color(235, 240, 245, 255 * a), TEXT_ALIGN_CENTER)
    end
end)

-- On a city screen (lc_screen): the latest broadcast, until there's another.
local screenCache = {}
function LC_CL.DrawCityScreen(ent)
    draw.RoundedBox(4, -320, -180, 640, 360, SCREEN_BG)
    draw.RoundedBox(0, -320, -180, 640, 4, SCREEN_HEAD)
    draw.SimpleText("THE CITY ADMINISTRATOR", "DermaLarge", 0, -150, SCREEN_HEAD, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    local text = GetGlobal2String("lc_broadcast", "")
    if text == "" then text = "Compliance is its own reward. Your cooperation is noted." end
    if screenCache.text ~= text then screenCache = { text = text, lines = LC_CL.WrapText(text, "DermaLarge", 580) } end
    for i = 1, math.min(#screenCache.lines, 8) do
        draw.SimpleText(screenCache.lines[i], "DermaLarge", 0, -100 + (i - 1) * 34, SCREEN_INK, TEXT_ALIGN_CENTER)
    end
    -- a slow scanline, so it reads as a screen
    local sy = -180 + (CurTime() * 60) % 360
    surface.SetDrawColor(120, 200, 240, 18)
    surface.DrawRect(-320, sy, 640, 6)
end

------------------------------------------------------------------------
-- The law
------------------------------------------------------------------------

local lawCache = {}
local function CurrentLaws()
    local raw = GetGlobal2String("lc_laws", "")
    if lawCache.raw ~= raw then lawCache = { raw = raw, list = util.JSONToTable(raw) or {} } end
    return lawCache.list
end

function LC_CL.DrawLawBoard(ent)
    draw.RoundedBox(4, -320, -180, 640, 360, Color(26, 24, 22, 255))
    draw.RoundedBox(0, -320, -180, 640, 4, Color(200, 190, 160))
    draw.SimpleText("CITY LAWS", "DermaLarge", 0, -150, Color(225, 215, 185), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    local y = -118
    for i, law in ipairs(CurrentLaws()) do
        if y > 150 then break end
        local lines = LC_CL.WrapText(i .. ". " .. law, "DermaDefaultBold", 580)
        for _, l in ipairs(lines) do
            draw.SimpleText(l, "DermaDefaultBold", -290, y, Color(220, 215, 200))
            y = y + 18
        end
        y = y + 4
    end
    draw.SimpleText("Press E to read", "DermaDefault", 0, 165, Color(150, 145, 130), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end

local function LawsDo(action, n, text)
    net.Start("lc_laws_do")
    net.WriteString(action)
    net.WriteString(tostring(n or ""))
    net.WriteString(text or "")
    net.SendToServer()
end

local lawFrame
net.Receive("lc_laws", function()
    local t = ReadCompressed()
    if not t then return end
    local x, y
    if IsValid(lawFrame) then x, y = lawFrame:GetPos() lawFrame:Remove() end
    lawFrame = vgui.Create("DFrame")
    lawFrame:SetTitle("The city's laws")
    lawFrame:SetSize(math.min(ScrW() - 60, 560), math.min(ScrH() - 60, 520))
    if x then lawFrame:SetPos(x, y) else lawFrame:Center() end
    lawFrame:MakePopup()
    local scroll = vgui.Create("DScrollPanel", lawFrame)
    scroll:Dock(FILL)
    for i, law in ipairs(t.laws or {}) do
        local row = vgui.Create("DPanel", scroll)
        row:Dock(TOP)
        row:DockMargin(0, 2, 0, 2)
        row:SetTall(t.edit and 28 or 22)
        row.Paint = nil
        if t.edit then
            local e = vgui.Create("DTextEntry", row)
            e:Dock(FILL)
            e:SetValue(law)
            e.OnEnter = function(self) LawsDo("set", i, self:GetValue()) end
            local d = vgui.Create("DButton", row)
            d:Dock(RIGHT)
            d:SetWide(60)
            d:DockMargin(4, 0, 0, 0)
            d:SetText("Delete")
            d.DoClick = function() LawsDo("del", i) end
        else
            local l = vgui.Create("DLabel", row)
            l:Dock(FILL)
            l:SetWrap(true)
            l:SetAutoStretchVertical(true)
            l:SetText(i .. ". " .. law)
        end
    end
    if t.edit then
        local add = vgui.Create("DTextEntry", lawFrame)
        add:Dock(BOTTOM)
        add:SetPlaceholderText("A new law (Enter to add). Edit one above and press Enter to change it.")
        add.OnEnter = function(self) if self:GetValue() ~= "" then LawsDo("add", nil, self:GetValue()) end end
    end
end)

------------------------------------------------------------------------
-- Civil Protection reads the mail (sv_livingcity_mail.lua)
------------------------------------------------------------------------

net.Receive("lc_mail_list", function()
    local t = ReadCompressed()
    if not t then return end
    if IsValid(LC_CL.mailFrame) then LC_CL.mailFrame:Remove() end
    local f = vgui.Create("DFrame")
    LC_CL.mailFrame = f
    f:SetTitle("The mail, waiting to go out")
    f:SetSize(math.min(ScrW() - 60, 560), math.min(ScrH() - 60, 520))
    f:Center()
    f:MakePopup()
    local scroll = vgui.Create("DScrollPanel", f)
    scroll:Dock(FILL)
    if #(t.letters or {}) == 0 then
        local l = vgui.Create("DLabel", scroll)
        l:Dock(TOP)
        l:SetText("Nothing waiting.")
        return
    end
    for _, letter in ipairs(t.letters) do
        local p = vgui.Create("DPanel", scroll)
        p:Dock(TOP)
        p:DockMargin(0, 0, 0, 6)
        p:SetTall(110)
        local head = vgui.Create("DLabel", p)
        head:Dock(TOP)
        head:DockMargin(6, 4, 6, 0)
        head:SetText(string.format("To %s, posted by %s%s", letter.to or "?", letter.from or "?", letter.sig and ("  (signed \"" .. letter.sig .. "\")") or "  (unsigned)"))
        local body = vgui.Create("DLabel", p)
        body:Dock(FILL)
        body:DockMargin(6, 2, 6, 2)
        body:SetWrap(true)
        body:SetText(letter.text or "")
        local b = vgui.Create("DButton", p)
        b:Dock(BOTTOM)
        b:SetTall(22)
        b:SetText("Confiscate it")
        b.DoClick = function()
            net.Start("lc_mail_do") net.WriteString("confiscate") net.WriteString(letter.id) net.SendToServer()
        end
    end
end)
