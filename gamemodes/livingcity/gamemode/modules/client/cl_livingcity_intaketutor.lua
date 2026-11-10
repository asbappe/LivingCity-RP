--[[
    Living City (client): the arrival search (sv_livingcity_intaketutor.lua).
    A copy of the pat-down's panels (cl_livingcity_patsearch.lua) for a new
    arrival searched by a unit at the desks: first a choice, "Show me how
    searches work" or "Just search me"; then the panel for the person
    searched (the four spots, which is being checked, R to slip something
    once), with every step explained in the lesson; at the end of the lesson
    a page on how searches work and a practice go at the other side: you
    search a pretend citizen (nothing real, nothing sent to the server).
]]

LC_CL = LC_CL or {}

local offerWin, statePanel, state, doneWin, practiceWin
local checkStart, checkSpot = 0, nil

local function Look()
    local l = LC_CL.JobLook or {}
    return l.BG or Color(24, 27, 32), l.CARD or Color(36, 40, 47), l.INK or Color(235, 235, 225), l.DIM or Color(170, 175, 180),
        l.ACC or Color(230, 190, 90), l.GOOD or Color(80, 160, 90), l.BAD or Color(170, 70, 60)
end

local function Button(parent, text, col, click)
    local make = LC_CL.JobLook and LC_CL.JobLook.Button
    if make then return make(parent, text, col, click) end
    local b = vgui.Create("DButton", parent)
    b:SetText(text)
    b.DoClick = click
    return b
end

local function Wrapped(parent, text, col)
    local l = vgui.Create("DLabel", parent)
    l:SetText(text or "")
    l:SetWrap(true)
    l:SetAutoStretchVertical(true)
    if col then l:SetTextColor(col) end
    return l
end

local function CloseState()
    if IsValid(offerWin) then offerWin:Remove() end
    if IsValid(statePanel) then statePanel:Remove() end
    offerWin, statePanel, state, checkSpot = nil, nil, nil, nil
end

------------------------------------------------------------------------
-- The choice
------------------------------------------------------------------------

local function Choose(learn)
    net.Start("lc_tut_choice")
    net.WriteBool(learn and true or false)
    net.SendToServer()
    if IsValid(offerWin) then offerWin:Remove() end
    offerWin = nil
end

local function BuildOffer(t)
    local BG, CARD, INK, DIM = Look()
    if IsValid(offerWin) then offerWin:Remove() end
    local f = vgui.Create("DFrame")
    offerWin = f
    f:SetTitle("Arrival search")
    f:SetSize(math.min(ScrW() - 40, 420), 220)
    f:Center()
    f:MakePopup()
    f.Paint = function(s, w, h) draw.RoundedBox(6, 0, 0, w, h, BG) draw.RoundedBox(0, 0, 0, w, 24, Color(14, 16, 20)) end
    f.openAt = CurTime()
    local msg = Wrapped(f, "A Civil Protection unit searches every new arrival. It's a good moment to learn how searches work: "
        .. "the same thing happens whenever a unit stops you in the city.", INK)
    msg:Dock(TOP)
    msg:DockMargin(8, 6, 8, 6)
    local learn = Button(f, t.seen and "Show me again how searches work" or "Show me how searches work", Color(70, 110, 80), function() Choose(true) end)
    learn:Dock(TOP)
    learn:SetTall(34)
    learn:DockMargin(8, 4, 8, 4)
    local quick = Button(f, "Just search me", Color(70, 90, 130), function() Choose(false) end)
    quick:Dock(TOP)
    quick:SetTall(34)
    quick:DockMargin(8, 4, 8, 4)
    local foot = vgui.Create("DPanel", f)
    foot:Dock(FILL)
    local secs = tonumber(t.secs) or 15
    foot.Paint = function(s, w, h)
        local left = math.max(0, math.ceil(secs - (CurTime() - f.openAt)))
        draw.SimpleText("No answer in " .. left .. "s: just searched.", "DermaDefault", 8, 4, DIM)
    end
    if t.seen then
        -- seen the lesson before: "Just search me" first
        learn:SetZPos(2)
        quick:SetZPos(1)
    end
end

------------------------------------------------------------------------
-- The panel for the person searched
------------------------------------------------------------------------

local function BuildState()
    local BG, CARD, INK, DIM, ACC, GOOD, BAD = Look()
    local p = vgui.Create("DPanel")
    statePanel = p
    p:SetSize(300, 330)
    p:SetMouseInputEnabled(false) -- (it only shows; the key is R)
    p:SetPos(ScrW() - 320, math.floor(ScrH() * 0.25))
    local tip = Wrapped(p, "", INK)
    tip:SetPos(10, 210)
    tip:SetWide(280)
    p.tip = tip
    p.Paint = function(s, w, h)
        local st = state or {}
        draw.RoundedBox(6, 0, 0, w, h, BG)
        draw.SimpleText(st.learn and "Arrival search (lesson)" or "Arrival search", "DermaDefaultBold", 10, 8, INK)
        draw.SimpleText("Stand still.", "DermaLarge", 10, 26, ACC)
        local y = 62
        for _, sp in ipairs(st.spots or {}) do
            local tag, col = "not yet", DIM
            if sp.state == 1 then tag, col = "being checked", ACC elseif sp.state == 2 then tag, col = (sp.found and "checked: found" or "checked"), (sp.found and BAD or GOOD) end
            if sp.state == 1 then
                draw.RoundedBox(4, 4, y - 2, w - 8, 34, CARD)
                local frac = math.Clamp((CurTime() - checkStart) / (st.secs or 1), 0, 1)
                draw.RoundedBox(2, 4, y + 30, math.floor((w - 8) * frac), 3, ACC)
            end
            draw.SimpleText(sp.name .. ": " .. tag, "DermaDefaultBold", 10, y, col)
            draw.SimpleText(sp.mine ~= "" and ("  " .. tostring(sp.mine)) or "  (nothing of yours)", "DermaDefault", 10, y + 15, DIM)
            y = y + 36
        end
        local key = tostring(st.key or "R")
        local line = st.slip == "used" and "You've tried your one move."
            or (st.slip == "ready" and (key .. ": slip something into a checked spot (once)")
            or (key .. ": once a spot is checked, slip something into it"))
        draw.SimpleText(line, "DermaDefault", 10, h - 18, st.slip == "ready" and INK or DIM)
    end
    p.Think = function(s)
        local st = state or {}
        local want = st.learn and tostring(st.tip or "") or ""
        if s.tip:GetText() ~= want then s.tip:SetText(want) end
        local down = input and input.IsKeyDown and input.IsKeyDown(KEY_R or 28) or false
        local typing = vgui.GetKeyboardFocus and IsValid(vgui.GetKeyboardFocus())
        if down and not s.wasDown and not typing and st.slip == "ready" then
            net.Start("lc_tut_slip")
            net.SendToServer()
        end
        s.wasDown = down
    end
    return p
end

------------------------------------------------------------------------
-- Practice: you search a pretend citizen (all on your screen)
------------------------------------------------------------------------

local PRETEND = {
    { "Ration card", false }, { "Identity papers", false }, { "Bread", false }, { "Cigarettes (Union)", false },
    { "Lockpick", true }, { "Pirate radio part", true }, { "Forged ration card", true }, { "Resistance pamphlet", true },
    { "Moonshine", true }, { "Pistol rounds", true },
}
local PLACE = { { 0.30, 0.20, 0.40, 0.26 }, { 0.30, 0.47, 0.40, 0.08 }, { 0.32, 0.56, 0.36, 0.28 }, { 0.28, 0.85, 0.44, 0.10 } }
local NAMES = { "Jacket", "Waist", "Legs", "Boots" }

local function BuildPractice()
    local BG, CARD, INK, DIM, ACC, GOOD, BAD = Look()
    if IsValid(practiceWin) then practiceWin:Remove() end
    local P = { spots = {}, checking = nil, at = 0, slipped = false, contraband = 0, caught = 0, over = false }
    for i = 1, 4 do P.spots[i] = { name = NAMES[i], items = {}, done = false } end
    local bag = table.Copy(PRETEND)
    for _ = 1, math.random(2, 4) do
        local it = table.remove(bag, math.random(#bag))
        table.insert(P.spots[math.random(4)].items, it)
        if it[2] then P.contraband = P.contraband + 1 end
    end
    if P.contraband == 0 then
        table.insert(P.spots[math.random(4)].items, { "Lockpick", true })
        P.contraband = 1
    end
    local f = vgui.Create("DFrame")
    practiceWin = f
    f:SetTitle("Practice: search a pretend citizen")
    f:SetSize(math.min(ScrW() - 40, 400), math.min(ScrH() - 40, 540))
    f:Center()
    f:MakePopup()
    f.Paint = function(s, w, h) draw.RoundedBox(6, 0, 0, w, h, BG) draw.RoundedBox(0, 0, 0, w, 24, Color(14, 16, 20)) end
    local foot = vgui.Create("DPanel", f)
    foot:Dock(BOTTOM)
    foot:SetTall(170)
    local note = Wrapped(foot, "You're the unit now. Click a spot to check it (a second each). Contraband is what you're after; "
        .. "ordinary things are left alone. They may try to slip something into a spot you've already checked.", DIM)
    note:Dock(TOP)
    foot.Paint = function(s, w, h)
        local y = h - 74
        if P.flash and CurTime() - P.flash < 3 then
            draw.RoundedBox(4, 0, y - 24, w, 20, Color(BAD.r, BAD.g, BAD.b, 180))
            draw.SimpleText("They tried to move something. You felt it.", "DermaDefaultBold", w / 2, y - 14, INK, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        if P.over then
            draw.SimpleText(string.format("You found %d of %d pieces of contraband.", P.caught, P.contraband), "DermaDefaultBold", 4, y, P.caught >= P.contraband and GOOD or ACC)
            if (P.hidden or 0) > 0 then
                draw.SimpleText("They slipped " .. P.hidden .. " into a spot you'd already checked.", "DermaDefault", 4, y + 18, DIM)
            end
        end
    end
    local done = Button(foot, "Done", Color(70, 90, 130), function()
        if P.over then f:Remove() return end
        P.over = true
    end)
    done:Dock(BOTTOM)
    done:SetTall(32)
    local body = vgui.Create("DPanel", f)
    body:Dock(FILL)
    body:DockMargin(0, 6, 0, 6)
    body.Paint = function(s, w, h)
        draw.SimpleText("Searching a pretend citizen", "DermaDefaultBold", w / 2, 2, INK, TEXT_ALIGN_CENTER)
        local cx, r = w / 2, math.floor(h * 0.07)
        draw.RoundedBox(r, cx - r, math.floor(h * 0.05), r * 2, r * 2, CARD)
        draw.RoundedBox(4, math.floor(w * 0.18), math.floor(h * 0.21), math.floor(w * 0.11), math.floor(h * 0.30), CARD)
        draw.RoundedBox(4, math.floor(w * 0.71), math.floor(h * 0.21), math.floor(w * 0.11), math.floor(h * 0.30), CARD)
    end
    body.btn = {}
    local function Finish(i)
        local sp = P.spots[i]
        sp.done = true
        local got = {}
        for _, it in ipairs(sp.items) do
            got[#got + 1] = it[1] .. (it[2] and " (contraband)" or "")
            if it[2] then P.caught = P.caught + 1 end
        end
        sp.text = #got > 0 and table.concat(got, ", ") or "Nothing."
        sp.items = {}
        P.checking = nil
        -- after the first spot, they try once to slip something from an unchecked spot into it
        if not P.slipped then
            P.slipped = true
            local from = {}
            for k, o in ipairs(P.spots) do
                if not o.done then for n, it in ipairs(o.items) do if it[2] then from[#from + 1] = { k = k, n = n } end end end
            end
            if #from > 0 and math.random() < 0.7 then
                local pick = from[math.random(#from)]
                local it = table.remove(P.spots[pick.k].items, pick.n)
                if math.random() < 0.6 then
                    P.hidden = (P.hidden or 0) + 1 -- (moved into a checked spot: you'll never find it now)
                else
                    P.flash = CurTime()
                    P.caught = P.caught + 1
                    sp.text = sp.text .. " + " .. it[1] .. " (they tried to move it)"
                    surface.PlaySound("buttons/button10.wav")
                end
            end
        end
    end
    for i = 1, 4 do
        local b = vgui.Create("DButton", body)
        b:SetText("")
        b.Paint = function(s, w, h)
            local sp = P.spots[i]
            local col = Color(70, 90, 130)
            if sp.done then col = (sp.text == "Nothing.") and Color(55, 60, 66) or Color(90, 75, 60) end
            draw.RoundedBox(4, 0, 0, w, h, s:IsHovered() and not sp.done and Color(90, 110, 150) or col)
            if P.checking == i then
                local frac = math.Clamp(CurTime() - P.at, 0, 1)
                draw.RoundedBox(4, 0, 0, math.floor(w * frac), h, ACC)
                if frac >= 1 then Finish(i) end
            end
            local label = sp.done and (sp.name .. ": " .. sp.text) or (P.checking == i and (sp.name .. ": checking...") or sp.name)
            draw.SimpleText(label, "DermaDefaultBold", w / 2, h / 2, INK, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        b.DoClick = function()
            local sp = P.spots[i]
            if P.over or sp.done or P.checking then return end
            P.checking, P.at = i, CurTime()
        end
        body.btn[i] = b
    end
    body.PerformLayout = function(s, w, h)
        for i, b in ipairs(s.btn) do
            local pl = PLACE[i]
            b:SetPos(math.floor(w * pl[1]), math.floor(h * pl[2]))
            b:SetSize(math.floor(w * pl[3]), math.max(18, math.floor(h * pl[4])))
        end
    end
    body:InvalidateLayout(true)
    LC_CL.TutorPractice = P
    return f
end
LC_CL.TutorOpenPractice = BuildPractice

------------------------------------------------------------------------
-- The lesson's last page
------------------------------------------------------------------------

local LESSON = {
    "How searches work in the city:",
    "- A unit (a player or one of the city's) checks your Jacket, Waist, Legs and Boots. What he finds that's contraband is taken, and that costs standing; guns and worse are a crime.",
    "- Once per search you may press R to slip one thing into a spot already checked. It works 6 times in 10.",
    "- Walking away from a search is Evading a search: you're wanted.",
    "- When one of the city's units finds something, you get five seconds: COMPLY (it's taken) or FIGHT (you keep it, and you're resisting).",
    "- Keep what you can't afford to lose in your stash at home, not in your pockets.",
    "- Model citizens are often waved through without a search.",
}

local function BuildDone(t)
    local BG, CARD, INK, DIM, ACC = Look()
    if IsValid(doneWin) then doneWin:Remove() end
    local f = vgui.Create("DFrame")
    doneWin = f
    f:SetTitle("Searches: what you've learned")
    f:SetSize(math.min(ScrW() - 40, 480), math.min(ScrH() - 40, 380))
    f:Center()
    f:MakePopup()
    f.Paint = function(s, w, h) draw.RoundedBox(6, 0, 0, w, h, BG) draw.RoundedBox(0, 0, 0, w, 24, Color(14, 16, 20)) end
    local btns = vgui.Create("DPanel", f)
    btns:Dock(BOTTOM)
    btns:SetTall(78)
    btns.Paint = function() end
    local got = Button(btns, "Got it", Color(70, 90, 130), function() f:Remove() end)
    got:Dock(BOTTOM)
    got:SetTall(32)
    got:DockMargin(0, 4, 0, 0)
    local try = Button(btns, "Try the other side: search someone (practice)", Color(70, 110, 80), function()
        f:Remove()
        BuildPractice()
    end)
    try:Dock(BOTTOM)
    try:SetTall(32)
    local scroll = vgui.Create("DScrollPanel", f)
    scroll:Dock(FILL)
    for i, line in ipairs(LESSON) do
        local l = Wrapped(scroll, line, i == 1 and ACC or INK)
        l:Dock(TOP)
        l:DockMargin(6, 4, 6, 0)
    end
    if t and t.found and t.found ~= "" then
        local l = Wrapped(scroll, "Taken from you just now: " .. t.found .. ". A warning this once.", DIM)
        l:Dock(TOP)
        l:DockMargin(6, 8, 6, 0)
    end
end

------------------------------------------------------------------------

local function Read() return util.JSONToTable(net.ReadString() or "") or {} end

net.Receive("lc_tut_offer", function() BuildOffer(Read()) end)
net.Receive("lc_tut_state", function()
    local t = Read()
    if t.checking and t.checking ~= checkSpot then checkStart = CurTime() end
    checkSpot = t.checking
    state = t
    if IsValid(offerWin) then offerWin:Remove() offerWin = nil end
    if not IsValid(statePanel) then BuildState() end
end)
net.Receive("lc_tut_close", CloseState)
net.Receive("lc_tut_done", function() BuildDone(Read()) end)

function LC_CL.TutorPanels() return offerWin, statePanel, state, doneWin, practiceWin end
LC_CL.TutorClose = CloseState
