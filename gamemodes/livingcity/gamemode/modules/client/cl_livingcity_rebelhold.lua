--[[
    Living City (client): the Resistance's holding cage (sv_livingcity_rebelhold.lua)

    E on a side of the cage, as a Fighter or above: the gate, and for each of
    those held: to the interrogation chair, or let go.
]]

LC_CL = LC_CL or {}

local frame

local function Do(cage, what, npc)
    net.Start("lc_cage_do")
    net.WriteEntity(cage)
    net.WriteString(what)
    net.WriteEntity(IsValid(npc) and npc or NULL)
    net.SendToServer()
end

net.Receive("lc_cage", function()
    local cage = net.ReadEntity()
    if not IsValid(cage) then
        if IsValid(frame) then frame:Remove() end
        return
    end
    local open, chair = net.ReadBool(), net.ReadBool()
    local held = {}
    for _ = 1, net.ReadUInt(4) or 0 do held[#held + 1] = { npc = net.ReadEntity(), name = net.ReadString() } end
    local tall = 96 + math.max(1, #held) * 62
    if IsValid(frame) then frame:Remove() end
    frame = vgui.Create("DFrame")
    frame:SetTitle("The holding cage")
    frame:SetSize(420, tall)
    frame:SetPos(math.floor(ScrW() * 0.62), ScrH() - tall - 60)
    frame:MakePopup()
    frame.Paint = function(_, w, h)
        draw.RoundedBox(6, 0, 0, w, h, Color(16, 15, 13, 150))
        draw.RoundedBoxEx(6, 0, 0, w, 24, Color(30, 28, 24, 190), true, true, false, false)
    end
    local function Button(parent, label, fn, enabled)
        local b = vgui.Create("DButton", parent)
        b:SetText(label)
        b:SetEnabled(enabled ~= false)
        b.DoClick = fn
        return b
    end
    local gate = Button(frame, open and "Shut the gate" or "Open the gate", function() Do(cage, "gate") end)
    gate:Dock(TOP)
    gate:DockMargin(8, 4, 8, 6)
    gate:SetTall(26)
    if #held == 0 then
        local l = vgui.Create("DLabel", frame)
        l:Dock(TOP)
        l:DockMargin(8, 4, 8, 4)
        l:SetWrap(true)
        l:SetTall(40)
        l:SetText("Nobody is held here. To take someone prisoner: press E on a citizen nearby, then \"Take them prisoner\".")
    end
    for _, hd in ipairs(held) do
        local row = vgui.Create("DPanel", frame)
        row:Dock(TOP)
        row:DockMargin(8, 0, 8, 6)
        row:SetTall(56)
        row.Paint = function(_, w, h)
            draw.RoundedBox(4, 0, 0, w, h, Color(24, 26, 32, 220))
            draw.SimpleText(hd.name, "DermaDefaultBold", 8, 5, Color(232, 230, 224))
        end
        local a = Button(row, chair and "To the interrogation chair" or "To the interrogation chair (none free near)", function() Do(cage, "chair", hd.npc) end, chair)
        a:SetPos(8, 26) a:SetSize(250, 24)
        local f = Button(row, "Let them go", function() Do(cage, "free", hd.npc) end)
        f:SetPos(266, 26) f:SetSize(130, 24)
    end
end)
