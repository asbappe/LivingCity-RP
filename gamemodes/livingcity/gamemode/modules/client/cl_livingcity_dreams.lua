--[[
    Living City: shared dreams, your side (sv_livingcity_dreams.lua)

      C > Settings > Shared dreams: on, or opt out (and, in a dream, wake up now).
      While you dream, a line at the top of the screen says how to wake.
      Admins: C > Help > Dreams (or the Dreams button in the Endings menu): whether
      dreams can happen (a dream point placed), what's waiting for tonight and when,
      dream it now, wake everyone, and put back anyone's things from their snapshot.
]]

LC_CL = LC_CL or {}

function LC_CL.DreamAct(what, arg)
    net.Start("lc_dream_act")
    net.WriteString(tostring(what or ""))
    net.WriteString(tostring(arg or ""))
    net.SendToServer()
end

-- While you dream: how to wake.
hook.Add("HUDPaint", "LivingCityDreams", function()
    local me = LocalPlayer()
    if not IsValid(me) or not me:GetNW2Bool("lc_dreaming", false) then return end
    draw.SimpleTextOutlined(me:GetNW2Bool("lc_nightmare", false) and "A nightmare. You'll wake in your bed with everything you had, but you can't wake yourself until you're out of it."
        or "You're dreaming. You'll wake in your bed with everything you had. (Wake up now: C > Settings > Shared dreams)",
        "DermaDefaultBold", ScrW() / 2, 14, Color(215, 195, 255, 220), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, 1, Color(0, 0, 0, 200))
end)

------------------------------------------------------------------------
-- The admins' window
------------------------------------------------------------------------

local frame

local function Line(parent, text, col)
    local l = vgui.Create("DLabel", parent)
    l:Dock(TOP)
    l:DockMargin(6, 2, 6, 2)
    l:SetText(text)
    l:SetTextColor(col or Color(235, 235, 235))
    l:SetWrap(true)
    l:SetAutoStretchVertical(true)
    return l
end
local function Btn(parent, text, fn)
    local b = vgui.Create("DButton", parent)
    b:Dock(TOP)
    b:DockMargin(6, 2, 6, 2)
    b:SetText(text)
    b.DoClick = fn
    return b
end

local function Open(st)
    if IsValid(frame) then frame:Remove() end
    frame = vgui.Create("DFrame")
    frame:SetSize(math.min(460, ScrW() - 40), math.min(ScrH() - 80, 560))
    frame:Center()
    frame:SetTitle("Dreams")
    frame:MakePopup()
    local body = vgui.Create("DScrollPanel", frame)
    body:Dock(FILL)
    local GOLD, DIM = Color(255, 210, 90), Color(170, 170, 180)
    if not st.point then
        Line(body, "No dream point on this map, so the secret endings are as they always were (the whole city, then the map reloads). "
            .. "To make them dreams: the Living City Editor, Point: dream, somewhere out of the map nobody can walk to (and Zone: dream round it, for its edge).", GOLD)
    elseif not st.on then
        Line(body, "Dreams are switched off (lc_dreams 0): the endings are as they always were.", GOLD)
    else
        Line(body, "Dreams are on: a secret ending waits for the night, and everyone asleep dreams it together about "
            .. math.floor(st.delay or 60) .. " seconds after the Administrator says good night." .. (st.zone and "" or " (No dream zone: it keeps within lc_dream_radius of the point.)"), DIM)
    end
    if st.active then
        Line(body, string.format("Dreaming now: %s, %d asleep in it.", st.active.name or st.active.ending, st.active.n or 0), GOLD)
        Btn(body, "Wake everyone now (they wake in their beds, with everything they had)", function() LC_CL.DreamAct("wakeall") end)
    end
    if st.queued then
        Line(body, "Waiting for tonight's dream: " .. (st.queuedName or st.queued) .. (st.at and string.format(" (in about %d seconds)", st.at) or " (after the Administrator says good night)"), GOLD)
        Btn(body, "Forget it (nothing waits for tonight)", function() LC_CL.DreamAct("forget") end)
    else
        Line(body, "Nothing is waiting for tonight's dream" .. (st.every and " (lc_dream_every_night: a random one, at night)." or "."), DIM)
    end
    Line(body, string.format("Asleep right now (and not opted out): %d", st.asleep or 0), DIM)
    if st.point and st.on and not st.active then
        local row = vgui.Create("DPanel", body)
        row:Dock(TOP)
        row:DockMargin(6, 4, 6, 2)
        row:SetTall(26)
        row.Paint = function() end
        local pick = vgui.Create("DComboBox", row)
        pick:Dock(FILL)
        for _, e in ipairs(st.endings or {}) do pick:AddChoice(e.name, e.id, e.id == st.queued) end
        local go = vgui.Create("DButton", row)
        go:Dock(RIGHT)
        go:SetWide(150)
        go:SetText("Dream it now (with me)")
        go.DoClick = function()
            local _, id = pick:GetSelected()
            LC_CL.DreamAct("now", id or st.queued or "")
        end
    end
    Line(body, "Snapshots kept (everything about someone, saved as they began to dream; it goes once they've woken with it all back):", GOLD)
    if #(st.saved or {}) == 0 then Line(body, "None.", DIM) end
    for _, s in ipairs(st.saved or {}) do
        local txt = s.nick .. (s.online and "" or " (not on)") .. (s.applied and ": put back once already, not all of it matched" or "")
        Line(body, txt)
        if s.online then Btn(body, "Put back " .. s.nick .. "'s things", function() LC_CL.DreamAct("restore", s.sid) end) end
    end
    Btn(body, "Refresh", function() LC_CL.DreamAct("status") end)
end

net.Receive("lc_dream", function() Open(net.ReadTable() or {}) end)

function LC_CL.DreamsMenu()
    local me = LocalPlayer()
    if not (IsValid(me) and me:IsAdmin()) then return end
    LC_CL.DreamAct("status")
end
