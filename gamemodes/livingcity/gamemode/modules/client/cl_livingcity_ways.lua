--[[
    Living City (client): ways to get by (sv_livingcity_ways.lua)

    F1 > What now? > Ways to get by, or !ways. One line each: what you can
    do, how, and (dimmed, in amber) what's missing. A button marks the way
    there or opens the screen it happens on.
]]

LC_CL = LC_CL or {}

local INK, DIM, OK, NEED = Color(232, 230, 224), Color(160, 160, 160), Color(130, 200, 140), Color(230, 170, 90)
local frame

local function ReadCompressed()
    local len = net.ReadUInt(32)
    local data = net.ReadData(len)
    local json = util.Decompress(data or "")
    return json and util.JSONToTable(json) or nil
end

-- where a way is done: your pockets (F3), or a tab of F4 (cl_livingcity_hub.lua)
local OPEN = { pockets = "gm_showspare1" }
local TAB = { jobs = true, factions = true, career = true }

local function Go(w)
    if IsValid(frame) then frame:Remove() end
    if w.way and w.way ~= "" and LC_CL.SendAction then LC_CL.SendAction("waypoint", w.way) end
    if w.open == "characters" and LC_CL.SendAction then LC_CL.SendAction("characters")
    elseif w.open and OPEN[w.open] then RunConsoleCommand(OPEN[w.open])
    elseif w.open and TAB[w.open] then if LC_CL.OpenHub then LC_CL.OpenHub(w.open) else RunConsoleCommand("gm_showspare2") end end
end

function LC_CL.OpenWays(list)
    if IsValid(frame) then frame:Remove() end
    frame = vgui.Create("DFrame")
    frame:SetTitle("Ways to get by")
    frame:SetSize(math.min(ScrW() - 40, 620), math.min(ScrH() - 60, 60 + #list * 52))
    frame:Center()
    frame:MakePopup()
    local scroll = vgui.Create("DScrollPanel", frame)
    scroll:Dock(FILL)
    for _, w in ipairs(list) do
        local row = vgui.Create("DPanel", scroll)
        row:Dock(TOP)
        row:DockMargin(4, 2, 4, 2)
        row:SetTall(48)
        row.Paint = function(s, wd, h)
            draw.RoundedBox(4, 0, 0, wd, h, Color(24, 26, 32, 240))
            draw.RoundedBox(0, 0, 0, 3, h, w.need and NEED or OK)
            draw.SimpleText(w.text or "", "DermaDefaultBold", 12, 6, w.need and DIM or INK)
            draw.SimpleText(w.need or w.how or "", "DermaDefault", 12, 26, w.need and NEED or DIM)
        end
        if w.need then row:SetTooltip(w.how or "") end
        if (w.way and w.way ~= "") or w.open then
            local b = vgui.Create("DButton", row)
            b:Dock(RIGHT)
            b:DockMargin(0, 10, 8, 10)
            b:SetWide(96)
            b:SetText((w.way and w.way ~= "") and "Show me" or "Open")
            b.DoClick = function() Go(w) end
        end
    end
end

net.Receive("lc_ways", function()
    local t = ReadCompressed()
    if t and t.ways then LC_CL.OpenWays(t.ways) end
end)
