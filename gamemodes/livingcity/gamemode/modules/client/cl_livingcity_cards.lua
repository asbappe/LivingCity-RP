--[[
    Living City (client): the card table's window (sv_livingcity_resistancemoney.lua)

    One small window: the four seats (a name each, the card each had in the last hand, what the winner took, a
    chip by whoever dealt it), the last pot, the stake (three buttons for whoever sat first), Deal, and one line
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

local function Seat(parent, y, s)
    local row = vgui.Create("DPanel", parent)
    row:SetPos(10, y)
    row:SetSize(260, 36)
    row.Paint = function(_, w, h)
        if s.you then draw.RoundedBox(4, 0, 0, w, h, MINE) end
        draw.RoundedBox(4, 2, 1, 26, h - 2, s.card > 0 and CARD or CARD_BACK)
        if s.card > 0 then draw.SimpleText(RankText(s.card), "DermaDefaultBold", 15, h / 2, CARD_INK, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER) end
        if s.dealt then draw.RoundedBox(4, 34, h / 2 - 4, 8, 8, ACCENT) end
    end
    Label(row, 48, 0, 160, 36, s.name, s.won > 0 and ACCENT or (s.you and INK or DIM))
    if s.won > 0 then Label(row, 206, 0, 50, 36, "+" .. s.won, ACCENT, 6) end
end

local function Open(t)
    local x, y
    if IsValid(frame) then x, y = frame:GetPos() frame:Remove() end
    frame = nil
    if t.you == 0 then return nil end
    frame = vgui.Create("DFrame")
    if LC_CL.SetTheme then LC_CL.SetTheme(frame, "scrap") end
    frame:SetTitle("High card")
    frame:SetSize(280, 280)
    if isnumber(x) and isnumber(y) then frame:SetPos(x, y) else frame:Center() end -- (where they left it)
    frame:MakePopup()
    frame:SetKeyboardInputEnabled(false) -- (they can walk off; out of reach, the server stands them up)
    frame.lcTable = t.tbl
    frame.OnClose = function() if t.you == 1 then Tell(t.tbl, 0) end end
    for i, s in ipairs(t.seats) do Seat(frame, 30 + (i - 1) * 40, s) end
    Label(frame, 10, 192, 260, 18, t.pot > 0 and ("Pot " .. t.pot) or "", INK, 5)
    Label(frame, 10, 212, 260, 18, LINES[t.line] or "", ACCENT, 5)
    -- the stake: three buttons for whoever sat first, the number for everyone else
    Label(frame, 10, 234, 40, 36, "Stake", DIM)
    local stake = STAKES[t.stake]
    if t.chooser then
        for i, b in ipairs(STAKES) do
            local btn = vgui.Create("DButton", frame)
            btn:SetPos(50 + (i - 1) * 38, 236)
            btn:SetSize(34, 32)
            btn:SetText(tostring(b))
            btn:SetEnabled(math.floor(t.mask / 2 ^ (i - 1)) % 2 == 1)
            btn:SetSelected(b == stake)
            btn.DoClick = function() Tell(t.tbl, 2, i) end
        end
    else
        Label(frame, 50, 234, 60, 36, stake and tostring(stake) or "", INK)
    end
    local deal = vgui.Create("DButton", frame)
    deal:SetPos(170, 236)
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
