--[[
    Living City (client): choosing which of your characters to play (!characters).
]]

LC_CL = LC_CL or {}

local function ReadCompressed()
    local len = net.ReadUInt(32)
    local data = net.ReadData(len)
    local json = util.Decompress(data or "")
    return json and util.JSONToTable(json) or nil
end

local INK, DIM, ACCENT = Color(232, 230, 224), Color(150, 150, 150), Color(235, 180, 70)
local frame

local function Do(action, n)
    net.Start("lc_slots_do")
    net.WriteString(action)
    net.WriteString(tostring(n))
    net.SendToServer()
end

local function Card(parent, i, s, active, can, why)
    local card = vgui.Create("DPanel", parent)
    card:Dock(TOP)
    card:SetTall(96)
    card:DockMargin(4, 4, 4, 4)
    card.Paint = function(self, w, h)
        draw.RoundedBox(6, 0, 0, w, h, Color(24, 26, 32, 240))
        draw.RoundedBox(0, 0, 0, 4, h, active and ACCENT or Color(70, 72, 80))
    end
    if s and s.model and s.model ~= "" then
        local icon = vgui.Create("SpawnIcon", card)
        icon:Dock(LEFT)
        icon:SetWide(80)
        icon:DockMargin(10, 8, 6, 8)
        icon:SetModel(s.model)
    end
    local info = vgui.Create("DPanel", card)
    info:Dock(FILL)
    info:DockMargin(8, 8, 8, 8)
    info.Paint = function(self, w, h)
        if not s then
            draw.SimpleText("Slot " .. i .. ": empty", "DermaLarge", 0, 4, DIM)
            draw.SimpleText("Someone new: a name, a face, nothing to their name.", "DermaDefault", 0, 40, DIM)
            return
        end
        draw.SimpleText(s.name or "?", "DermaLarge", 0, 0, INK)
        draw.SimpleText(string.format("Citizen %s   |   %s%s", s.cid or "?", s.faction or "Citizen", s.rank and (", " .. s.rank) or ""),
            "DermaDefault", 0, 34, active and ACCENT or DIM)
        draw.SimpleText(string.format("%s credits   |   standing %s%s", tostring(s.credits or "?"), tostring(s.standing or "?"),
            active and "   |   playing now" or ""), "DermaDefault", 0, 52, DIM)
    end
    local btns = vgui.Create("DPanel", card)
    btns:Dock(RIGHT)
    btns:SetWide(130)
    btns:DockMargin(0, 10, 10, 10)
    btns.Paint = nil
    if not active then
        local play = vgui.Create("DButton", btns)
        play:Dock(TOP)
        play:SetTall(32)
        play:SetText(s and "Play as them" or "Start someone new")
        play:SetEnabled(can == true)
        if not can and why then play:SetTooltip(why) end
        play.DoClick = function() Do("play", i) if IsValid(frame) then frame:Remove() end end
        if s then
            local del = vgui.Create("DButton", btns)
            del:Dock(TOP)
            del:DockMargin(0, 6, 0, 0)
            del:SetTall(24)
            del:SetText("Delete")
            del:SetTextColor(Color(200, 60, 50))
            del.DoClick = function()
                Derma_Query("Delete " .. (s.name or "them") .. "? Everything they had goes with them.", "Delete character",
                    "Delete", function() Do("delete", i) end, "Keep", function() end)
            end
        end
    end
end

net.Receive("lc_slots", function()
    local t = ReadCompressed()
    if not t then return end
    if IsValid(frame) then frame:Remove() end
    frame = vgui.Create("DFrame")
    frame:SetTitle("Your characters")
    local n = #(t.slots or {})
    frame:SetSize(math.min(ScrW() - 60, 620), math.min(ScrH() - 60, 70 + n * 104 + (t.can and 0 or 24)))
    frame:Center()
    frame:MakePopup()
    if not t.can and t.why then
        local note = vgui.Create("DLabel", frame)
        note:Dock(TOP)
        note:SetTextColor(ACCENT)
        note:SetText("  You can't switch right now: " .. t.why)
    end
    for i = 1, n do
        local s = t.slots[i]
        Card(frame, i, s ~= false and s or nil, i == t.active, t.can, t.why)
    end
end)
