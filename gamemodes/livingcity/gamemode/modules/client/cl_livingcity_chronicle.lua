--[[
    Living City (client): what's been happening (sv_livingcity_chronicle.lua)

    F1 > What now? > What's been happening, or !news. The last day's stories
    in the city, the newest first: each a thing that happened and what led
    to it.
]]

LC_CL = LC_CL or {}

local INK, DIM, EDGE = Color(232, 230, 224), Color(160, 160, 160), Color(92, 200, 216)
local frame

local function ReadCompressed()
    local len = net.ReadUInt(32)
    local data = net.ReadData(len)
    local json = util.Decompress(data or "")
    return json and util.JSONToTable(json) or nil
end

local function Ago(mins)
    mins = tonumber(mins) or 0
    if mins < 2 then return "just now" end
    if mins < 90 then return mins .. " minutes ago" end
    return math.floor(mins / 60 + 0.5) .. " hours ago"
end

function LC_CL.OpenNews(t)
    if IsValid(frame) then frame:Remove() end
    local list = t.stories or {}
    frame = vgui.Create("DFrame")
    frame:SetTitle("The city's stories (staff)")
    frame:SetSize(math.min(ScrW() - 40, 680), math.min(ScrH() - 60, 90 + math.max(1, #list) * 84))
    frame:Center()
    frame:MakePopup()
    local scroll = vgui.Create("DScrollPanel", frame)
    scroll:Dock(FILL)
    if #list == 0 then
        local l = vgui.Create("DLabel", scroll)
        l:Dock(TOP)
        l:DockMargin(12, 12, 12, 12)
        l:SetTextColor(DIM)
        l:SetWrap(true)
        l:SetAutoStretchVertical(true)
        l:SetText(t.on == false and "Nobody is keeping track of the city's stories on this server."
            or "Nothing has been written down in the last day.")
        return
    end
    for _, s in ipairs(list) do
        local row = vgui.Create("DPanel", scroll)
        row:Dock(TOP)
        row:DockMargin(4, 2, 4, 2)
        row:SetTall(80)
        row.Paint = function(_, wd, h)
            draw.RoundedBox(4, 0, 0, wd, h, Color(24, 26, 32, 240))
            draw.RoundedBox(0, 0, 0, 3, h, EDGE)
            draw.SimpleText(Ago(s.mins), "DermaDefaultBold", 12, 6, DIM)
        end
        local l = vgui.Create("DLabel", row)
        l:SetPos(12, 24)
        l:SetSize(640, 52)
        l:SetTextColor(INK)
        l:SetWrap(true)
        l:SetContentAlignment(7)
        l:SetText(s.text or "")
        row.PerformLayout = function(_, wd) l:SetWide(wd - 24) end
    end
end

net.Receive("lc_chronicle", function()
    local t = ReadCompressed()
    if t then LC_CL.OpenNews(t) end
end)
