--[[
    Living City (client): the Resistance fund screen's window (sv_livingcity_fundgear.lua)

    E on the screen in the camp: what the fund holds, its newest entries (newest first, one short
    line each), and three Donate buttons. A refusal, if there was one, is a line in the window.
]]

LC_CL = LC_CL or {}

local GAIN, SPEND, DIM, WARN = Color(150, 220, 140), Color(230, 150, 120), Color(170, 165, 150), Color(235, 120, 100)
local frame

local function Line(e)
    if e.n == 0 then return e.w end
    return string.format("%+d  %s", e.n, e.w)
end

net.Receive("lc_fundtv", function()
    local fund = net.ReadUInt(32) or 0
    local log = {}
    for i = 1, net.ReadUInt(8) or 0 do log[i] = { n = net.ReadInt(32) or 0, w = net.ReadString() or "" } end
    local amounts = {}
    for i = 1, net.ReadUInt(4) or 0 do amounts[i] = net.ReadUInt(16) or 0 end
    local status = net.ReadString() or ""
    if IsValid(frame) then frame:Remove() end
    frame = vgui.Create("DFrame")
    LC_CL.FundFrame = frame
    if LC_CL.SetTheme then LC_CL.SetTheme(frame, "rebel") end
    frame:SetTitle("Resistance fund")
    frame:SetSize(math.min(ScrW() - 40, 420), math.min(ScrH() - 40, 420))
    frame:Center()
    frame:MakePopup()
    local top = vgui.Create("DLabel", frame)
    top:Dock(TOP)
    top:SetTall(40)
    top:SetFont("DermaLarge")
    top:SetText(fund .. " credits")
    local bottom = vgui.Create("DPanel", frame)
    bottom:Dock(BOTTOM)
    bottom:SetTall(32)
    bottom:DockMargin(0, 6, 0, 0)
    bottom.Paint = function() end
    for i = #amounts, 1, -1 do
        local a = amounts[i]
        local b = vgui.Create("DButton", bottom)
        b:Dock(RIGHT)
        b:SetWide(110)
        b:DockMargin(4, 0, 0, 0)
        b:SetText("Donate " .. a)
        b.DoClick = function()
            net.Start("lc_fund_donate")
            net.WriteUInt(a, 16)
            net.WriteBool(false)
            net.SendToServer()
        end
    end
    if status ~= "" then
        local s = vgui.Create("DLabel", frame)
        s:Dock(BOTTOM)
        s:SetTall(18)
        s:SetTextColor(WARN)
        s:SetText(status)
    end
    local scroll = vgui.Create("DScrollPanel", frame)
    scroll:Dock(FILL)
    for _, e in ipairs(log) do
        local l = vgui.Create("DLabel", scroll)
        l:Dock(TOP)
        l:DockMargin(2, 0, 2, 4)
        l:SetWrap(true)
        l:SetAutoStretchVertical(true)
        l:SetTextColor(e.n > 0 and GAIN or (e.n < 0 and SPEND or DIM))
        l:SetText(Line(e))
    end
end)
