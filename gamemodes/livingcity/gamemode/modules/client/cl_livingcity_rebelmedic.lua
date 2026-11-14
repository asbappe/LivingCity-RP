--[[
    Living City: the Resistance's medic, his offer (sv_livingcity_rebelmedic.lua). A quick menu
    (number keys), or a small window with lc_situation_windows 1.
]]

LC_CL = LC_CL or {}

local function Buy(what)
    net.Start("lc_medic_buy")
    net.WriteString(what)
    net.SendToServer()
end

net.Receive("lc_medic_menu", function()
    local npc = net.ReadEntity()
    local vp, vh = net.ReadUInt(8), net.ReadUInt(8)
    local kp, kh = net.ReadUInt(8), net.ReadUInt(8)
    local credits = net.ReadUInt(16)
    local items = {
        { label = string.format("A small health vial: %d health for %d credits", vh, vp), run = function() Buy("vial") end, disabled = credits < vp },
        { label = string.format("A large medkit: %d health for %d credits", kh, kp), run = function() Buy("kit") end, disabled = credits < kp },
        { label = "Leave", run = function() end },
    }
    local note = string.format("\"Hurt? I can patch you up.\" You have %d credits.", credits)
    if LC_CL.OpenSituation and not (LC_CL.SituationWindows and LC_CL.SituationWindows()) then
        LC_CL.OpenSituation({ id = "medic", title = "The medic", items = items, note = note,
            stay = function()
                local me = LocalPlayer()
                return IsValid(npc) and IsValid(me) and me:GetPos():DistToSqr(npc:GetPos()) <= 220 * 220
            end })
        return
    end
    local f = vgui.Create("DFrame")
    f:SetTitle("The medic")
    f:SetSize(380, 150)
    f:Center()
    f:MakePopup()
    local l = vgui.Create("DLabel", f)
    l:Dock(TOP)
    l:SetText(note)
    l:SizeToContents()
    for _, it in ipairs(items) do
        local b = vgui.Create("DButton", f)
        b:Dock(TOP)
        b:DockMargin(0, 4, 0, 0)
        b:SetText(it.label)
        b:SetEnabled(not it.disabled)
        b.DoClick = function() if it.run then it.run() end f:Remove() end
    end
end)
