--[[
    Living City (client): the card table's window (sv_livingcity_resistancemoney.lua)

    One small window: the four seats side by side (the card each had in the last hand, as a picture from the
    Resistance's own deck, the name under it, what the winner took, a chip by whoever dealt it), the last pot, the stake (three buttons for whoever sat first), Deal, and one line
    when you can't: out of hands this hour, or short of the stake. Closing it stands you up. The server decides
    everything; nothing goes in the chat.

    Twenty-one: whoever sat first has two buttons for the game. In a hand each seat's cards are fanned (the others'
    face down until it is over), the number under your name is what your hand is worth, Card and Stay take Deal's
    place, and a thin bar runs down the time left.
]]

LC_CL = LC_CL or {}

local STAKES = { 5, 10, 25 }
local RANKS = { [11] = "J", [12] = "Q", [13] = "K", [14] = "A" }
local LINES = { "Out of hands this hour", "Short of the stake" }
local GAMES = { "High card", "Twenty-one" }
local TURN = 20 -- (seconds for Card or Stay: sv_livingcity_resistancemoney.lua)
local INK, DIM, ACCENT = Color(232, 226, 210), Color(120, 116, 106), Color(230, 180, 90)
local CARD, CARD_BACK, CARD_INK, MINE = Color(236, 230, 214), Color(60, 52, 44), Color(30, 28, 26), Color(255, 255, 255, 14)

local frame
local function RankText(r) return RANKS[r] or tostring(r) end

local function Tell(tbl, what, n)
    net.Start("lc_cards_deal")
    net.WriteEntity(tbl)
    net.WriteUInt(what, 3) -- 0 stand up, 1 deal, 2 the stake, 3 Card (1) or Stay (2), 4 the game
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

-- The deck's pictures, in materials/livingcity/cards/ (made by _dev/posters/cards.js; loose in the server's
-- garrysmod/, livingcity_content.zip): a face for each rank, 2.png to 14.png (the ace), ink alone on nothing; the
-- card under it for each suit, suit1.png to suit4.png (the Resistance, the Combine, the Union, the vortigaunts);
-- and back.png. The face is laid over its suit. Without a picture, that part is drawn plainly.
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
local SW, SH = 48, 67 -- (a card in a fanned hand of Twenty-one)
local function Picture(m, x, y, w, h)
    surface.SetDrawColor(255, 255, 255, 255)
    surface.SetMaterial(m)
    surface.DrawTexturedRect(x, y, w, h)
end
local function Card(rank, suit, x, y, w, h)
    if rank <= 0 then -- (face down)
        local m = Art("back")
        if m then Picture(m, x, y, w, h) else draw.RoundedBox(6, x, y, w, h, CARD_BACK) end
        return
    end
    local under, face = Art("suit" .. math.Clamp(suit or 1, 1, 4)), Art(tostring(rank))
    if under then Picture(under, x, y, w, h) else draw.RoundedBox(6, x, y, w, h, CARD) end
    if face then
        Picture(face, x, y, w, h)
    else
        draw.SimpleText(RankText(rank), w > 60 and "DermaLarge" or "DermaDefaultBold", w > 60 and x + w / 2 or x + 8, w > 60 and y + h / 2 or y + 10, CARD_INK, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
end
-- What a hand of Twenty-one is worth; nil while a card of it is face down.
local function Total(cards)
    local sum, aces = 0, 0
    for _, c in ipairs(cards) do
        if c == 0 then return nil end
        if c == 14 then sum, aces = sum + 11, aces + 1 else sum = sum + math.min(c, 10) end
    end
    while sum > 21 and aces > 0 do sum, aces = sum - 10, aces - 1 end
    return sum
end
local function Seat(parent, x, s)
    local row = vgui.Create("DPanel", parent)
    row:SetPos(x, 30)
    row:SetSize(CW + 8, CH + 36)
    local n = #s.cards
    row.Paint = function(_, w, h)
        if s.you then draw.RoundedBox(6, 0, 0, w, h, MINE) end
        if n > 0 then
            local step = n > 1 and math.min(30, (CW - SW) / (n - 1)) or 0
            local x0 = 4 + (CW - SW - step * (n - 1)) / 2
            for i, c in ipairs(s.cards) do Card(c, s.suits[i], x0 + (i - 1) * step, 4 + (CH - SH) / 2, SW, SH) end
        else
            Card(s.card, s.suit, 4, 4, CW, CH)
        end
        if s.dealt then draw.RoundedBox(5, w - 12, 0, 10, 10, ACCENT) end
    end
    Label(row, 0, CH + 6, CW + 8, 16, s.name, s.won > 0 and ACCENT or (s.you and INK or DIM), 5)
    local total = n > 0 and Total(s.cards) or nil
    if s.won > 0 then Label(row, 0, CH + 20, CW + 8, 14, "+" .. s.won, ACCENT, 5)
    elseif total then Label(row, 0, CH + 20, CW + 8, 14, tostring(total), total > 21 and DIM or INK, 5) end
end

local function Open(t)
    local x, y
    if IsValid(frame) then x, y = frame:GetPos() frame:Remove() end
    frame = nil
    if t.you == 0 then return nil end
    frame = vgui.Create("DFrame")
    if LC_CL.SetTheme then LC_CL.SetTheme(frame, "scrap") end
    frame:SetTitle(GAMES[t.game] or GAMES[1])
    frame:SetSize(360, 284)
    if isnumber(x) and isnumber(y) then frame:SetPos(x, y) else frame:Center() end -- (where they left it)
    frame:MakePopup()
    frame:SetKeyboardInputEnabled(false) -- (they can walk off; out of reach, the server stands them up)
    frame.lcTable = t.tbl
    frame.OnClose = function() if t.you == 1 then Tell(t.tbl, 0) end end
    for i, s in ipairs(t.seats) do Seat(frame, 12 + (i - 1) * (CW + 8), s) end
    -- the game: two buttons for whoever sat first, between hands (everyone else reads it in the title)
    if t.chooser and not t.round then
        for i, name in ipairs(GAMES) do
            local btn = vgui.Create("DButton", frame)
            btn:SetPos(12 + (i - 1) * 116, 174)
            btn:SetSize(110, 22)
            btn:SetText(name)
            btn:SetSelected(i == t.game)
            btn.DoClick = function() Tell(t.tbl, 4, i) end
        end
    elseif t.round and t.move then -- (the time left for Card or Stay)
        local bar, endAt = vgui.Create("DPanel", frame), CurTime() + t.secs
        bar:SetPos(12, 182)
        bar:SetSize(336, 4)
        bar.Paint = function(_, w, h) draw.RoundedBox(2, 0, 0, w * math.Clamp((endAt - CurTime()) / TURN, 0, 1), h, ACCENT) end
    end
    Label(frame, 10, 200, 340, 18, t.pot > 0 and ("Pot " .. t.pot) or "", INK, 5)
    Label(frame, 10, 218, 340, 18, LINES[t.line] or "", ACCENT, 5)
    -- the stake: three buttons for whoever sat first, the number for everyone else
    Label(frame, 10, 240, 40, 36, "Stake", DIM)
    local stake = STAKES[t.stake]
    if t.chooser and not t.round then
        for i, b in ipairs(STAKES) do
            local btn = vgui.Create("DButton", frame)
            btn:SetPos(50 + (i - 1) * 38, 242)
            btn:SetSize(34, 32)
            btn:SetText(tostring(b))
            btn:SetEnabled(math.floor(t.mask / 2 ^ (i - 1)) % 2 == 1)
            btn:SetSelected(b == stake)
            btn.DoClick = function() Tell(t.tbl, 2, i) end
        end
    else
        Label(frame, 50, 240, 60, 36, stake and tostring(stake) or "", INK)
    end
    if t.round and t.move then -- (your hand of Twenty-one: Card or Stay where Deal was)
        for i, name in ipairs({ "Card", "Stay" }) do
            local btn = vgui.Create("DButton", frame)
            btn:SetPos(250 + (i - 1) * 52, 242)
            btn:SetSize(48, 32)
            btn:SetText(name)
            btn.DoClick = function() Tell(t.tbl, 3, i) end
        end
        return frame
    end
    local deal = vgui.Create("DButton", frame)
    deal:SetPos(250, 242)
    deal:SetSize(100, 32)
    deal:SetText("Deal")
    local readyAt = CurTime() + (t.wait or 0)
    local function Can() return t.you == 1 and stake ~= nil and t.line == 0 and not t.round and CurTime() >= readyAt end
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
        s.cards, s.suits = {}, {}
        t.seats[i] = s
    end
    t.game, t.round, t.move, t.secs = net.ReadUInt(2), net.ReadBool(), net.ReadBool(), net.ReadUInt(5)
    for _, s in ipairs(t.seats) do
        s.suit = net.ReadUInt(3)
        for c = 1, net.ReadUInt(3) do s.cards[c], s.suits[c] = net.ReadUInt(4), net.ReadUInt(3) end
    end
    Open(t)
end)

LC_CL.CardsFrame = function() return frame end
