--[[
    Living City (client): the card table's window (sv_livingcity_resistancemoney.lua)

    One small window: your card and the house's, three bets (5, 10, 25), Deal, and the result in two words.
    A bet the table won't take now is greyed out. Nothing goes in the chat.
]]

LC_CL = LC_CL or {}

local BETS = { 5, 10, 25 }
local RANKS = { [11] = "J", [12] = "Q", [13] = "K", [14] = "A" }
local INK, DIM, ACCENT = Color(232, 226, 210), Color(120, 116, 106), Color(230, 180, 90)
local CARD_INK = Color(30, 28, 26)

local frame
local function RankText(r) return RANKS[r] or tostring(r) end

local function Card(parent, x, label, rank)
    local c = vgui.Create("DPanel", parent)
    c:SetPos(x, 40)
    c:SetSize(70, 96)
    c.Paint = function(_, w, h)
        draw.RoundedBox(6, 0, 0, w, h, rank and rank > 0 and Color(236, 230, 214) or Color(60, 52, 44))
        if rank and rank > 0 then
            draw.SimpleText(RankText(rank), "DermaLarge", w / 2, h / 2, CARD_INK, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
    end
    local l = vgui.Create("DLabel", parent)
    l:SetPos(x, 140)
    l:SetSize(70, 16)
    l:SetText(label)
    l:SetContentAlignment(5)
    l:SetTextColor(DIM)
    return c
end

local function Open(tbl, you, house, result, mask)
    local keepBet = IsValid(frame) and frame.lcBet or nil
    if IsValid(frame) then frame:Remove() end
    frame = vgui.Create("DFrame")
    if LC_CL.SetTheme then LC_CL.SetTheme(frame, "scrap") end
    frame:SetTitle("High card")
    frame:SetSize(260, 240)
    frame:Center()
    frame:MakePopup()
    frame.lcTable = tbl
    Card(frame, 40, "You", you)
    Card(frame, 150, "House", house)
    local res = vgui.Create("DLabel", frame)
    res:SetPos(10, 160)
    res:SetSize(240, 20)
    res:SetContentAlignment(5)
    res:SetFont("DermaDefaultBold")
    res:SetText(result == 1 and "You win" or (result == 2 and "House wins" or ""))
    res:SetTextColor(result == 1 and ACCENT or INK)
    -- the bets: the one picked stays picked; one the table won't take is greyed out
    local takes = {}
    for i, b in ipairs(BETS) do takes[b] = math.floor((mask or 0) / 2 ^ (i - 1)) % 2 == 1 end
    if not (keepBet and takes[keepBet]) then
        keepBet = nil
        for _, b in ipairs(BETS) do if takes[b] then keepBet = b break end end
    end
    frame.lcBet = keepBet
    local buttons = {}
    for i, b in ipairs(BETS) do
        local btn = vgui.Create("DButton", frame)
        btn:SetPos(10 + (i - 1) * 48, 192)
        btn:SetSize(44, 36)
        btn:SetText(tostring(b))
        btn:SetEnabled(takes[b] == true)
        btn.DoClick = function()
            frame.lcBet = b
            for _, o in ipairs(buttons) do o:SetSelected(o == btn) end
        end
        btn:SetSelected(b == keepBet)
        buttons[#buttons + 1] = btn
    end
    local deal = vgui.Create("DButton", frame)
    deal:SetPos(160, 192)
    deal:SetSize(90, 36)
    deal:SetText("Deal")
    deal:SetEnabled(keepBet ~= nil)
    local readyAt = (result and result > 0) and (CurTime() + 4) or 0 -- (the server deals one hand every four seconds)
    deal.Think = function(self)
        local can = frame.lcBet ~= nil and CurTime() >= readyAt
        if self:IsEnabled() ~= can then self:SetEnabled(can) end
    end
    deal.DoClick = function()
        if not frame.lcBet or CurTime() < readyAt then return end
        readyAt = CurTime() + 4
        net.Start("lc_cards_deal")
        net.WriteEntity(frame.lcTable)
        net.WriteUInt(frame.lcBet, 8)
        net.SendToServer()
    end
    return frame
end

net.Receive("lc_cards", function()
    local tbl = net.ReadEntity()
    local you, house = net.ReadUInt(5), net.ReadUInt(5)
    local result, mask = net.ReadUInt(2), net.ReadUInt(3)
    Open(tbl, you, house, result, mask)
end)

LC_CL.CardsFrame = function() return frame end
