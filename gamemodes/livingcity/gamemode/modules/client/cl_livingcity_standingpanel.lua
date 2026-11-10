--[[
    Living City (client): "Where I stand" (sv_livingcity_standingpanel.lua).
    One window, every number grouped, each with a line on what it means.
]]

LC_CL = LC_CL or {}

local win

function LC_CL.OpenStandingPanel()
    net.Start("lc_standing_panel")
    net.SendToServer()
end

local function Build(rows)
    local l = LC_CL.JobLook or {}
    local BG, CARD, INK, DIM, ACC, BAD = l.BG or Color(24, 27, 32), l.CARD or Color(36, 40, 47), l.INK or Color(235, 235, 225),
        l.DIM or Color(170, 175, 180), l.ACC or Color(230, 190, 90), l.BAD or Color(200, 90, 80)
    if IsValid(win) then win:Remove() end
    local f = vgui.Create("DFrame")
    win = f
    f:SetTitle("Where I stand")
    f:SetSize(math.min(ScrW() - 40, 620), math.min(ScrH() - 40, 640))
    f:Center()
    f:MakePopup()
    f.Paint = function(s, w, h) draw.RoundedBox(6, 0, 0, w, h, BG) draw.RoundedBox(0, 0, 0, w, 24, Color(14, 16, 20)) end
    local scroll = vgui.Create("DScrollPanel", f)
    scroll:Dock(FILL)
    local last
    for _, r in ipairs(rows or {}) do
        if r.g ~= last then
            last = r.g
            local h = vgui.Create("DLabel", scroll)
            h:Dock(TOP)
            h:DockMargin(6, 10, 6, 2)
            h:SetFont("DermaDefaultBold")
            h:SetTextColor(ACC)
            h:SetText(string.upper(tostring(r.g or "")))
        end
        local card = vgui.Create("DPanel", scroll)
        card:Dock(TOP)
        card:DockMargin(6, 2, 6, 2)
        card:DockPadding(8, 4, 8, 6)
        card.Paint = function(s, w, h) draw.RoundedBox(4, 0, 0, w, h, CARD) end
        local top = vgui.Create("DLabel", card)
        top:Dock(TOP)
        top:SetFont("DermaDefaultBold")
        top:SetTextColor(r.w and BAD or INK)
        top:SetText(tostring(r.l or "") .. ":  " .. tostring(r.v or ""))
        top:SetWrap(true)
        top:SetAutoStretchVertical(true)
        local ex = vgui.Create("DLabel", card)
        ex:Dock(TOP)
        ex:SetTextColor(DIM)
        ex:SetText(tostring(r.e or ""))
        ex:SetWrap(true)
        ex:SetAutoStretchVertical(true)
        card:InvalidateLayout(true)
        card:SizeToChildren(false, true)
        card.PerformLayout = function(s) s:SizeToChildren(false, true) end
    end
    return f
end

net.Receive("lc_standing_panel", function()
    local rows = util.JSONToTable(net.ReadString() or "") or {}
    Build(rows)
end)

function LC_CL.StandingPanel() return win end
