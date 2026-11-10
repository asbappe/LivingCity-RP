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
    if LC_CL.SetTheme then LC_CL.SetTheme(frame, "rebel") end -- (the Resistance's lab, whoever stands at it)
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
    -- a new face (sv_livingcity_lab.lua)
    if t.surgery then
        local sg = t.surgery
        local row = vgui.Create("DPanel", scroll)
        row:Dock(TOP)
        row:DockMargin(0, 0, 0, 6)
        row:SetTall(62)
        row.Paint = function(self, w, h)
            draw.RoundedBox(3, 0, 0, w, h, Color(52, 40, 46, 240))
            draw.SimpleText(string.format("A new face (%d credits)", sg.price or 0), "LCLabItem", 10, 13, INK, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            draw.SimpleText("Twenty seconds under. Nobody's looking for the face you wake with: wanted, BOLOs and", "DermaDefault", 10, 33, HAVE, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            draw.SimpleText(sg.ok and "photos gone, and the records can't put your old name (or your standing) to it." or (sg.why or ""), "DermaDefault", 10, 49, sg.ok and HAVE or DIM, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end
        local b = vgui.Create("DButton", row)
        b:Dock(RIGHT)
        b:DockMargin(4, 14, 6, 14)
        b:SetWide(110)
        b:SetText("Change it")
        b:SetEnabled(sg.ok == true)
        b.DoClick = function()
            net.Start("lc_lab_surgery") net.SendToServer()
            if IsValid(frame) then frame:Remove() end
        end
    end
    -- pulling the chip (sv_livingcity_lab.lua, LC.LabChip; the owner, 8 November)
    if t.chip then
        local cp = t.chip
        local row = vgui.Create("DPanel", scroll)
        row:Dock(TOP)
        row:DockMargin(0, 0, 0, 6)
        row:SetTall(78)
        local why = vgui.Create("DLabel", row)
        why:SetPos(10, 40)
        why:SetWrap(true)
        why:SetTextColor(cp.ok and HAVE or DIM)
        why:SetText(cp.ok and "Special one-time tools, and the codes to shut it down without frying your head. No more dreams, ever; but a unit's scanner may notice there's no implant signal."
            or (cp.why or ""))
        row.PerformLayout = function(self, w, h) why:SetSize(math.max(100, w - 140), 34) end
        row.Paint = function(self, w, h)
            draw.RoundedBox(3, 0, 0, w, h, Color(40, 40, 58, 240))
            draw.SimpleText(string.format("Pull the chip (%d credits)", cp.price or 0), "LCLabItem", 10, 13, INK, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            draw.SimpleText("Thirty seconds under. The Combine's implant comes out, and with it the city's dreams.", "DermaDefault", 10, 31, HAVE, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end
        local b = vgui.Create("DButton", row)
        b:Dock(RIGHT)
        b:DockMargin(4, 22, 6, 22)
        b:SetWide(110)
        b:SetText("Pull it")
        b:SetEnabled(cp.ok == true and not t.busy)
        b.DoClick = function()
            net.Start("lc_lab_chip") net.SendToServer()
            if IsValid(frame) then frame:Remove() end
        end
    end
    -- (the owner, 1 November: long descriptions ran under the buttons: wrapped now, clear of them)
    local function Wrap(text, font, maxw)
        surface.SetFont(font)
        local lines, cur = {}, ""
        for word in string.gmatch(text or "", "%S+") do
            local try = cur == "" and word or (cur .. " " .. word)
            if (surface.GetTextSize(try) or 0) > maxw and cur ~= "" then lines[#lines + 1] = cur cur = word else cur = try end
        end
        if cur ~= "" then lines[#lines + 1] = cur end
        return lines
    end
    for _, it in ipairs(t.items or {}) do
        local row = vgui.Create("DPanel", scroll)
        row:Dock(TOP)
        row:DockMargin(0, 0, 0, 4)
        row:SetTall(76)
        local mats = {}
        for _, m in ipairs(it.mats or {}) do mats[#mats + 1] = string.format("%s %d/%d", string.lower(m.name), m.have, m.need) end
        local matsText = table.concat(mats, ", ")
        row.Paint = function(self, w, h)
            draw.RoundedBox(3, 0, 0, w, h, ROW)
            draw.SimpleText(it.name .. string.format("   (%ds)", it.secs or 0), "LCLabItem", 10, 12, INK, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            local lines = Wrap(it.desc or "", "DermaDefault", math.max(100, w - 270))
            for i = 1, math.min(2, #lines) do
                local txt = lines[i]
                if i == 2 and #lines > 2 then txt = txt .. "..." end
                draw.SimpleText(txt, "DermaDefault", 10, 17 + i * 13, DIM, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            end
            draw.SimpleText(matsText, "DermaDefault", 10, 62, it.canMats and HAVE or LACK, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end
        local pay = vgui.Create("DButton", row)
        pay:Dock(RIGHT)
        pay:DockMargin(4, 22, 6, 22)
        pay:SetWide(110)
        pay:SetText("Pay " .. (it.price or 0) .. " credits")
        pay:SetEnabled(it.canPay == true and not t.busy)
        pay.DoClick = function() Make(it.id, "pay") end
        local own = vgui.Create("DButton", row)
        own:Dock(RIGHT)
        own:DockMargin(4, 22, 0, 22)
        own:SetWide(130)
        own:SetText("Use my materials")
        own:SetEnabled(it.canMats == true and not t.busy)
        own.DoClick = function() Make(it.id, "mats") end
    end
end

net.Receive("lc_lab", function() LC_CL.OpenLab(ReadCompressed()) end)
