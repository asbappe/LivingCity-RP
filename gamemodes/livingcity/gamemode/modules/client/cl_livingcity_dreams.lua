--[[
    Living City: shared dreams, your side (sv_livingcity_dreams.lua)

      F1 > Wake up from the dream (also C > Settings > Shared dreams, /dream wake): once you're
      out of it; nobody opts out.
      While you dream, a line at the top of the screen says whether you can wake yet and how,
      and a smaller one how long the dream can still last at the most.
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

-- Seconds this dream can still last at the most (nil: not dreaming, or no limit set).
function LC_CL.DreamTimeLeft()
    local me = LocalPlayer()
    if not IsValid(me) or not me:GetNW2Bool("lc_dreaming", false) then return nil end
    local ends = me:GetNW2Float("lc_dream_ends", 0)
    if ends <= 0 then return nil end
    return math.max(0, math.ceil(ends - CurTime()))
end

-- While you dream: how to wake.
-- (made once here, not every frame)
local C_0_0_0_200 = Color(0, 0, 0, 200)
local C_215_195_255_220 = Color(215, 195, 255, 220)
hook.Add("HUDPaint", "LivingCityDreams", function()
    local me = LocalPlayer()
    if not IsValid(me) or not me:GetNW2Bool("lc_dreaming", false) then return end
    local key = LC_CL.QuickKeyName and LC_CL.QuickKeyName() or "F1"
    draw.SimpleTextOutlined(me:GetNW2Bool("lc_dream_test", false) and "Testing a dream. Stop whenever you like: the editor's Stop the test, or " .. key .. " > Wake up from the dream. Nothing here counts."
        -- (out of it, an Enforcer, or the Administrator in a dream she didn't choose: the server says when, LC.DreamCanWake)
        or me:GetNW2Bool("lc_dream_canwake", false) and "You can wake up now: " .. key .. " > Wake up from the dream (or /dream wake). Or stay and watch: you wake in your bed with everything you had either way."
        or me:GetNW2Bool("lc_nightmare", false) and "A nightmare. You'll wake in your bed with everything you had, but you can't wake yourself until you're out of it."
        or "You're dreaming. You'll wake in your bed with everything you had, but you can't wake yourself until you're out of it.",
        "DermaDefaultBold", ScrW() / 2, 14, C_215_195_255_220, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, 1, C_0_0_0_200)
    -- (no dream lasts past lc_dream_max_minutes: how long this one can still go on, at the most)
    local left = LC_CL.DreamTimeLeft()
    if left then
        draw.SimpleTextOutlined(string.format("It ends in %d:%02d at the latest.", math.floor(left / 60), left % 60),
            "DermaDefault", ScrW() / 2, 32, C_215_195_255_220, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, 1, C_0_0_0_200)
    end
end)

------------------------------------------------------------------------
-- As the dream comes: the screen goes black, and the day's mood in a line (sv_livingcity_dreamplan.lua)
------------------------------------------------------------------------

local mood -- { text, t0, til }
net.Receive("lc_dream_mood", function()
    local t = net.ReadTable() or {}
    mood = { text = tostring(t.text or ""), t0 = CurTime(), til = tonumber(t.til) or (CurTime() + 7), kind = t.kind, hint = t.hint }
end)
LC_CL.DreamMoodShown = function() return mood end
-- Words broken into lines that fit (font set first).
local function Wrap(text, w)
    local lines, cur = {}, ""
    for word in string.gmatch(text, "%S+") do
        local try = cur == "" and word or (cur .. " " .. word)
        local tw = surface.GetTextSize(try)
        if tw > w and cur ~= "" then lines[#lines + 1] = cur cur = word else cur = try end
    end
    if cur ~= "" then lines[#lines + 1] = cur end
    return lines
end
LC_CL.DreamMoodWrap = Wrap
-- (made once here, not every frame)
local MOODCOL = { happy = Color(255, 230, 170), neutral = Color(215, 205, 255), nightmare = Color(230, 120, 120), propaganda = Color(255, 200, 120) }
local function DrawMood()
    if not mood then return end
    local now = CurTime()
    if now > mood.til + 2.5 then mood = nil return end
    local black = math.Clamp((now - mood.t0) / 1.5, 0, 1) * math.Clamp(1 - (now - mood.til) / 2.5, 0, 1) -- (fades in, holds, fades into the dream)
    surface.SetDrawColor(0, 0, 0, math.floor(255 * black))
    surface.DrawRect(0, 0, ScrW(), ScrH())
    local a = math.Clamp((now - mood.t0 - 1.5) / 1.5, 0, 1) * math.Clamp(1 - (now - mood.til) / 1.5, 0, 1)
    if a <= 0 then return end
    surface.SetFont("DermaLarge")
    local lines = Wrap(mood.text, math.min(900, ScrW() - 120))
    local _, lh = surface.GetTextSize("Ay")
    local y = ScrH() / 2 - #lines * (lh + 6) / 2
    local c = MOODCOL[mood.kind or ""] or Color(230, 230, 230)
    for _, l in ipairs(lines) do
        draw.SimpleText(l, "DermaLarge", ScrW() / 2, y, Color(c.r, c.g, c.b, math.floor(255 * a)), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
        y = y + lh + 6
    end
    if mood.hint then -- (a small note: they've earned the right to sit this kind out)
        draw.SimpleText(tostring(mood.hint), "DermaDefault", ScrW() / 2, y + 18, Color(190, 190, 200, math.floor(200 * a)), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
    end
end
LC_CL.DreamMoodDraw = DrawMood
hook.Add("DrawOverlay", "LivingCityDreamMood", DrawMood)

------------------------------------------------------------------------
-- The Administrator, lying down on a night whose dream she didn't choose: dream it, or sleep through it
------------------------------------------------------------------------

local ask
function LC_CL.DreamAskAnswer(what, remember)
    net.Start("lc_dream_ask")
    net.WriteString(what)
    net.WriteBool(remember == true)
    net.SendToServer()
    if IsValid(ask) then ask:Remove() end
    ask = nil
end
net.Receive("lc_dream_ask", function()
    local t = net.ReadTable() or {}
    if IsValid(ask) then ask:Remove() end
    local f = vgui.Create("DFrame")
    ask = f
    f:SetSize(440, 190)
    f:Center()
    f:SetTitle("Tonight's dream")
    f:MakePopup()
    local l = vgui.Create("DLabel", f)
    l:Dock(TOP)
    l:DockMargin(8, 4, 8, 4)
    l:SetWrap(true)
    l:SetAutoStretchVertical(true)
    l:SetText("The city will dream tonight, and you didn't choose this one. Dream it with them, or sleep through it?"
        .. " (Joining, you can wake from it whenever you like.)")
    local remember = vgui.Create("DCheckBoxLabel", f)
    remember:Dock(BOTTOM)
    remember:DockMargin(8, 2, 8, 6)
    remember:SetText("Remember this for every night I don't choose (the tablet's setting)")
    remember:SetValue(false)
    local row = vgui.Create("DPanel", f)
    row:Dock(BOTTOM)
    row:SetTall(30)
    row.Paint = function() end
    local skip = vgui.Create("DButton", row)
    skip:Dock(LEFT)
    skip:SetWide(210)
    skip:SetText("Sleep through it" .. (t.skip ~= false and " (as usual)" or ""))
    skip.DoClick = function() LC_CL.DreamAskAnswer("skip", remember:GetChecked()) end
    local join = vgui.Create("DButton", row)
    join:Dock(RIGHT)
    join:SetWide(210)
    join:SetText("Dream it with the city" .. (t.skip == false and " (as usual)" or ""))
    join.DoClick = function() LC_CL.DreamAskAnswer("join", remember:GetChecked()) end
end)
LC_CL.DreamAskOpen = function() return ask ~= nil end

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
-- A line whose words change as time passes (fn gives them); the label's own Think (its auto-stretch) still runs.
local function Live(parent, fn, col)
    local l = Line(parent, fn(), col)
    local was = l.Think
    l.Think = function(s)
        local txt = fn()
        if s.lcTxt ~= txt then s.lcTxt = txt s:SetText(txt) end
        if was then was(s) end
    end
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
    local MOODS = { happy = "Happy", neutral = "Neutral", nightmare = "a Nightmare" }
    local got = CurTime() -- (the countdowns below run on from what the server said)
    local function Clock(secs) secs = math.max(0, math.floor(secs)) return string.format("%d:%02d", math.floor(secs / 60), secs % 60) end
    if st.active then
        Line(body, string.format("Dreaming now: %s%s, %d asleep in it.", st.active.name or st.active.ending,
            st.active.test and " (a test from the editor)" or (MOODS[st.active.mood or ""] and (" (" .. MOODS[st.active.mood] .. ")") or ""), st.active.n or 0), GOLD)
        if st.active.left then
            Live(body, function() return "The safeguard ends it in " .. Clock(st.active.left - (CurTime() - got)) .. " at the latest (lc_dream_max_minutes)." end, DIM)
        end
        if #(st.active.who or {}) > 0 then Line(body, "In it: " .. table.concat(st.active.who, ", ") .. ".", DIM) end
        Btn(body, "Wake everyone now (they wake in their beds, with everything they had)", function() LC_CL.DreamAct("wakeall") end)
    end
    if st.queued then
        local name = (st.queuedName or st.queued) .. (MOODS[st.queuedMood or ""] and (", " .. MOODS[st.queuedMood]) or "")
        Live(body, function()
            return "Waiting for tonight's dream: " .. name .. (st.at and (" (in about " .. Clock(st.at - (CurTime() - got)) .. ")") or " (after the Administrator says good night)")
        end, GOLD)
        Btn(body, "Forget it (nothing waits for tonight)", function() LC_CL.DreamAct("forget") end)
    else
        Line(body, st.dreamt and "Tonight's dream has been dreamt: the next one is tomorrow night's."
            or ("Nothing is waiting for tonight's dream" .. (st.every and " (lc_dream_every_night: a random one, at night)." or ".")), DIM)
    end
    Line(body, string.format("Asleep right now: %d", st.asleep or 0), DIM)
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
        -- (only a superadmin is taken along awake: an admin's goes to whoever is asleep)
        local me = LocalPlayer()
        go:SetText((IsValid(me) and me.IsSuperAdmin and me:IsSuperAdmin()) and "Dream it now (with me)" or "Dream it now (the sleepers)")
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

------------------------------------------------------------------------
-- Testing a dream from the Living City Editor (sv_livingcity_dreamtest.lua)
------------------------------------------------------------------------

function LC_CL.DreamTestAct(what, arg)
    net.Start("lc_dream_test")
    net.WriteString(tostring(what or ""))
    net.WriteString(tostring(arg or ""))
    net.SendToServer()
end
LC_CL.DreamTestWatchers = LC_CL.DreamTestWatchers or {}
net.Receive("lc_dream_test", function()
    local t = net.ReadTable() or {}
    if t.k ~= "list" then return end
    LC_CL.DreamTestList = t
    for _, fn in pairs(LC_CL.DreamTestWatchers) do pcall(fn, t) end
end)

function LC_CL.DreamsMenu()
    local me = LocalPlayer()
    if not (IsValid(me) and me:IsAdmin()) then return end
    LC_CL.DreamAct("status")
end
