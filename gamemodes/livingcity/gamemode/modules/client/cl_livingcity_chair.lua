--[[
    Living City (client): the interrogation chair (sv_livingcity_chair.lua)

    The window of the one asking (E on the chair while someone sits in it),
    and the lamp in the eyes of whoever is in the chair.
]]

LC_CL = LC_CL or {}

local INK, DIM = Color(232, 230, 224), Color(160, 160, 160)
local frame

local function Do(chair, what)
    net.Start("lc_chair_do")
    net.WriteEntity(chair)
    net.WriteString(what)
    net.SendToServer()
end

net.Receive("lc_chair", function()
    local chair = net.ReadEntity()
    if not IsValid(chair) then
        if IsValid(frame) then frame:Remove() end
        return
    end
    local name, said, hits, max = net.ReadString(), net.ReadString(), net.ReadUInt(4), net.ReadUInt(4)
    if IsValid(frame) then frame:Remove() end
    frame = vgui.Create("DFrame")
    frame:SetTitle(name .. ", in the chair")
    frame:SetSize(420, 290)
    -- low on the screen, off to the right, and see-through, as the talk window is
    frame:SetPos(math.floor(ScrW() * 0.62), ScrH() - 290 - 60)
    frame:MakePopup()
    frame.Paint = function(_, w, h)
        draw.RoundedBox(6, 0, 0, w, h, Color(16, 15, 13, 150))
        draw.RoundedBoxEx(6, 0, 0, w, 24, Color(30, 28, 24, 190), true, true, false, false)
    end
    local words = vgui.Create("DLabel", frame)
    words:Dock(TOP)
    words:DockMargin(8, 4, 8, 8)
    words:SetTall(84)
    words:SetWrap(true)
    words:SetContentAlignment(7)
    words:SetTextColor(INK)
    words:SetText(said)
    local function Button(label, what, enabled)
        local b = vgui.Create("DButton", frame)
        b:Dock(TOP)
        b:DockMargin(8, 0, 8, 4)
        b:SetTall(26)
        b:SetText(label)
        b:SetEnabled(enabled ~= false)
        b.DoClick = function() if what then Do(chair, what) else frame:Remove() end end
    end
    Button("Ask what they've done", "done")
    Button("Ask what they've seen", "seen")
    Button(hits >= max and "Hit them (any more would kill them)" or ("Hit them (" .. hits .. " of " .. max .. ")"), "hit", hits < max)
    Button("Let them go", "free")
    Button("Step back", nil)
end)

-- In the chair yourself: the lamp is all you can see.
hook.Add("RenderScreenspaceEffects", "LivingCityChair", function()
    local me = LocalPlayer()
    if not IsValid(me) or not IsValid(me:GetNW2Entity("lc_chair_in")) then return end
    if DrawBloom then DrawBloom(0.25, 3.5, 12, 12, 2, 1, 1, 1, 1) end
    surface.SetDrawColor(255, 250, 235, 150 + math.floor(math.sin(CurTime() * 2.3) * 22))
    surface.DrawRect(0, 0, ScrW(), ScrH())
end)
