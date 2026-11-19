--[[
    Living City (client): the card table's window (sv_livingcity_resistancemoney.lua)

    One small window: the four seats side by side (the card each had in the last hand, as a picture from the
    Resistance's own deck, the name under it, what the winner took, a chip by whoever dealt it), the last pot, the stake (three buttons for whoever sat first), Deal, and one line
    when you can't: out of hands this hour, or short of the stake. Closing it stands you up. The server decides
    everything; nothing goes in the chat.
]]

LC_CL = LC_CL or {}

local STAKES = { 5, 10, 25 }
local RANKS = { [11] = "J", [12] = "Q", [13] = "K", [14] = "A" }
local LINES = { "Out of hands this hour", "Short of the stake" }
local INK, DIM, ACCENT = Color(232, 226, 210), Color(120, 116, 106), Color(230, 180, 90)
local CARD, CARD_BACK, CARD_INK, MINE = Color(236, 230, 214), Color(60, 52, 44), Color(30, 28, 26), Color(255, 255, 255, 14)

local frame
local function RankText(r) return RANKS[r] or tostring(r) end

local function Tell(tbl, what, n)
    net.Start("lc_cards_deal")
    net.WriteEntity(tbl)
    net.WriteUInt(what, 2) -- 0 stand up, 1 deal, 2 the stake
    net.WriteUInt(n or 0, 2)
    net.SendToServer()
end

local function Label(parent, x, y, w, h, text, color, align)
    local l = vgui.Create("DLabel", parent)
    l:SetPos(x, y)
    l:SetSize(w, h)
    l:SetText(text)
    l:SetTextColor(color or INK)
    l:SetContentAlignment(align or 4)
    return l
end

-- The deck's pictures: materials/livingcity/cards/2.png to 14.png (the ace) and back.png, made by
-- _dev/posters/cards.js; loose in the server's garrysmod/ (livingcity_content.zip). Without one, that card is
-- drawn plainly.
local art = {}
local function Art(name)
    if art[name] == nil then
        art[name] = false
        local path = "livingcity/cards/" .. name .. ".png"
        if file and file.Exists and file.Exists("materials/" .. path, "GAME") then
            local m = Material(path, "smooth")
            if m and not (m.IsError and m:IsError()) then art[name] = m end
        end
    end
    return art[name]
end
LC_CL.CardArt = art

local CW, CH = 76, 106
local function Seat(parent, x, s)
    local row = vgui.Create("DPanel", parent)
    row:SetPos(x, 30)
    row:SetSize(CW + 8, CH + 36)
    row.Paint = function(_, w, h)
        if s.you then draw.RoundedBox(6, 0, 0, w, h, MINE) end
        local m = Art(s.card > 0 and tostring(s.card) or "back")
        if m then
            surface.SetDrawColor(255, 255, 255, 255)
            surface.SetMaterial(m)
            surface.DrawTexturedRect(4, 4, CW, CH)
        else
            draw.RoundedBox(6, 4, 4, CW, CH, s.card > 0 and CARD or CARD_BACK)
            if s.card > 0 then draw.SimpleText(RankText(s.card), "DermaLarge", 4 + CW / 2, 4 + CH / 2, CARD_INK, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER) end
        end
        if s.dealt then draw.RoundedBox(5, w - 12, 0, 10, 10, ACCENT) end
    end
    Label(row, 0, CH + 6, CW + 8, 16, s.name, s.won > 0 and ACCENT or (s.you and INK or DIM), 5)
    if s.won > 0 then Label(row, 0, CH + 20, CW + 8, 14, "+" .. s.won, ACCENT, 5) end
end

local function Open(t)
    local x, y
    if IsValid(frame) then x, y = frame:GetPos() frame:Remove() end
    frame = nil
    if t.you == 0 then return nil end
    frame = vgui.Create("DFrame")
    if LC_CL.SetTheme then LC_CL.SetTheme(frame, "scrap") end
    frame:SetTitle("High card")
    frame:SetSize(360, 258)
    if isnumber(x) and isnumber(y) then frame:SetPos(x, y) else frame:Center() end -- (where they left it)
    frame:MakePopup()
    frame:SetKeyboardInputEnabled(false) -- (they can walk off; out of reach, the server stands them up)
    frame.lcTable = t.tbl
    frame.OnClose = function() if t.you == 1 then Tell(t.tbl, 0) end end
    for i, s in ipairs(t.seats) do Seat(frame, 12 + (i - 1) * (CW + 8), s) end
    Label(frame, 10, 174, 340, 18, t.pot > 0 and ("Pot " .. t.pot) or "", INK, 5)
    Label(frame, 10, 192, 340, 18, LINES[t.line] or "", ACCENT, 5)
    -- the stake: three buttons for whoever sat first, the number for everyone else
    Label(frame, 10, 214, 40, 36, "Stake", DIM)
    local stake = STAKES[t.stake]
    if t.chooser then
        for i, b in ipairs(STAKES) do
            local btn = vgui.Create("DButton", frame)
            btn:SetPos(50 + (i - 1) * 38, 216)
            btn:SetSize(34, 32)
            btn:SetText(tostring(b))
            btn:SetEnabled(math.floor(t.mask / 2 ^ (i - 1)) % 2 == 1)
            btn:SetSelected(b == stake)
            btn.DoClick = function() Tell(t.tbl, 2, i) end
        end
    else
        Label(frame, 50, 214, 60, 36, stake and tostring(stake) or "", INK)
    end
    local deal = vgui.Create("DButton", frame)
    deal:SetPos(250, 216)
    deal:SetSize(100, 32)
    deal:SetText("Deal")
    local readyAt = CurTime() + (t.wait or 0)
    local function Can() return t.you == 1 and stake ~= nil and t.line == 0 and CurTime() >= readyAt end
    deal:SetEnabled(Can())
    deal.Think = function(self)
        local can = Can()
        if self:IsEnabled() ~= can then self:SetEnabled(can) end
    end
    deal.DoClick = function()
        if not Can() then return end
        readyAt = CurTime() + 4 -- (until the server answers; it deals one hand every few seconds at a table)
        Tell(t.tbl, 1)
    end
    return frame
end

net.Receive("lc_cards", function()
    local t = { tbl = net.ReadEntity() }
    t.you, t.line = net.ReadUInt(2), net.ReadUInt(2)
    t.chooser = net.ReadBool()
    t.stake, t.mask = net.ReadUInt(2), net.ReadUInt(3)
    t.pot, t.wait = net.ReadUInt(8), net.ReadUInt(3)
    t.seats = {}
    for i = 1, net.ReadUInt(3) do
        local s = { name = net.ReadString() }
        s.you = net.ReadBool()
        s.card, s.won = net.ReadUInt(4), net.ReadUInt(7)
        s.dealt = net.ReadBool()
        t.seats[i] = s
    end
    Open(t)
end)

LC_CL.CardsFrame = function() return frame end
