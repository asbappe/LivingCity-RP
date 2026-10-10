--[[
    Living City (client): the Resistance lab's window

    What the scientist can make, each with what it takes: "Use my materials"
    (from your pockets, for nothing) or "Pay" (credits). He works on it while
    you wait in the lab. The server side is sv_livingcity_lab.lua.
]]

LC_CL = LC_CL or {}

local INK, DIM, ACCENT = Color(232, 226, 210), Color(160, 156, 146), Color(235, 140, 90)
local HAVE, LACK = Color(130, 205, 140), Color(220, 110, 90)
local PANEL, ROW = Color(18, 16, 14, 245), Color(32, 28, 24, 240)

surface.CreateFont("LCLabTitle", { font = "Trebuchet MS", size = 26, weight = 700 })
surface.CreateFont("LCLabItem", { font = "Trebuchet MS", size = 17, weight = 700 })

local function ReadCompressed()
    local len = net.ReadUInt(32)
    local data = net.ReadData(len)
    local json = util.Decompress(data or "")
    return json and util.JSONToTable(json) or nil
end

local frame

local function Make(id, how)
    net.Start("lc_lab_make")
    net.WriteString(id)
    net.WriteString(how)
    net.SendToServer()
    if IsValid(frame) then frame:Remove() end
end

function LC_CL.OpenLab(t)
    if IsValid(frame) then frame:Remove() end
    if not t then return end
    frame = vgui.Create("DFrame")
    frame:SetTitle("")
    frame:SetSize(math.min(ScrW() - 40, 700), math.min(ScrH() - 40, 640))
    frame:Center()
    frame:MakePopup()
    frame.Paint = function(self, w, h)
        draw.RoundedBox(6, 0, 0, w, h, PANEL)
        draw.SimpleText("THE LAB", "LCLabTitle", 16, 10, ACCENT)
        draw.SimpleText(string.format("%d credits", t.credits or 0), "DermaDefaultBold", w - 40, 20, INK, TEXT_ALIGN_RIGHT)
    end
    local scroll = vgui.Create("DScrollPanel", frame)
    scroll:Dock(FILL)
    scroll:DockMargin(8, 30, 8, 8)
    local note = vgui.Create("DLabel", scroll)
    note:Dock(TOP)
    note:DockMargin(4, 0, 4, 8)
    note:SetWrap(true)
    note:SetAutoStretchVertical(true)
    note:SetTextColor(DIM)
    note:SetText(t.busy and string.format("He's busy with someone else's work for another %d seconds.", t.busy)
        or "Bring him the materials and he makes it for nothing, or pay him for it (cheaper than the dealer). Stay in the lab while he works.")
    -- the Combine's data, decoded (not made)
    for _, d in ipairs(t.decode or {}) do
        local row = vgui.Create("DPanel", scroll)
        row:Dock(TOP)
        row:DockMargin(0, 0, 0, 6)
        row:SetTall(50)
        row.Paint = function(self, w, h)
            draw.RoundedBox(3, 0, 0, w, h, Color(40, 52, 40, 240))
            draw.SimpleText(string.format("%s (%d)", d.name, d.n or 1), "LCLabItem", 10, 13, INK, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            draw.SimpleText(d.desc or "", "DermaDefault", 10, 35, HAVE, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end
        local b = vgui.Create("DButton", row)
        b:Dock(RIGHT)
        b:DockMargin(4, 10, 6, 10)
        b:SetWide(110)
        b:SetText("Decode it")
        b.DoClick = function()
            net.Start("lc_lab_decode") net.WriteString(d.id) net.SendToServer()
            if IsValid(frame) then frame:Remove() end
        end
    end
    for _, it in ipairs(t.items or {}) do
        local row = vgui.Create("DPanel", scroll)
        row:Dock(TOP)
        row:DockMargin(0, 0, 0, 4)
        row:SetTall(50)
        local mats = {}
        for _, m in ipairs(it.mats or {}) do mats[#mats + 1] = string.format("%s %d/%d", string.lower(m.name), m.have, m.need) end
        local matsText = table.concat(mats, ", ")
        row.Paint = function(self, w, h)
            draw.RoundedBox(3, 0, 0, w, h, ROW)
            draw.SimpleText(it.name, "LCLabItem", 10, 13, INK, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            surface.SetFont("LCLabItem")
            local nw = surface.GetTextSize(it.name) or 0
            draw.SimpleText((it.desc or "") .. string.format("   (%ds)", it.secs or 0), "DermaDefault", 22 + nw, 13, DIM,
                TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            draw.SimpleText(matsText, "DermaDefault", 10, 35, it.canMats and HAVE or LACK, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end
        local pay = vgui.Create("DButton", row)
        pay:Dock(RIGHT)
        pay:DockMargin(4, 10, 6, 10)
        pay:SetWide(110)
        pay:SetText("Pay " .. (it.price or 0) .. " credits")
        pay:SetEnabled(it.canPay == true and not t.busy)
        pay.DoClick = function() Make(it.id, "pay") end
        local own = vgui.Create("DButton", row)
        own:Dock(RIGHT)
        own:DockMargin(4, 10, 0, 10)
        own:SetWide(130)
        own:SetText("Use my materials")
        own:SetEnabled(it.canMats == true and not t.busy)
        own.DoClick = function() Make(it.id, "mats") end
    end
end

net.Receive("lc_lab", function() LC_CL.OpenLab(ReadCompressed()) end)
