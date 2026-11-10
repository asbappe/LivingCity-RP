--[[
    Living City (client): the interrogation, question by question
    (sv_livingcity_interrogation.lua). The prisoner gets each question with
    the choices: tell the truth, lie, say nothing (not with no resolve
    left), bargain (once), or tell them everything. A Civil Protection
    player asking gets a window: the three questions, the baton, the
    answers so far, and Done.
]]

LC_CL = LC_CL or {}

local qWin, cpWin, cpState

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

local function Answer(c)
    net.Start("lc_intr_a")
    net.WriteString(c)
    net.SendToServer()
    if IsValid(qWin) then qWin:Remove() end
    qWin = nil
end

local function BuildQuestion(t)
    local BG, CARD, INK, DIM, ACC, GOOD, BAD = Look()
    if IsValid(LC_CL.InterrogateFrame) then LC_CL.InterrogateFrame:Remove() end
    if IsValid(qWin) then qWin:Remove() end
    local f = vgui.Create("DFrame")
    qWin = f
    f:SetTitle("Interrogation")
    f:SetSize(math.min(ScrW() - 40, 460), 330)
    f:Center()
    f:MakePopup()
    f:ShowCloseButton(false)
    f.openAt = CurTime()
    f.Paint = function(s, w, h) draw.RoundedBox(6, 0, 0, w, h, BG) draw.RoundedBox(0, 0, 0, w, 24, Color(14, 16, 20)) end
    local q = vgui.Create("DLabel", f)
    q:Dock(TOP)
    q:DockMargin(8, 6, 8, 2)
    q:SetWrap(true)
    q:SetAutoStretchVertical(true)
    q:SetTextColor(ACC)
    q:SetText(tostring(t.by or "The unit") .. ": \"" .. tostring(t.text or "") .. "\"")
    local info = vgui.Create("DPanel", f)
    info:Dock(TOP)
    info:SetTall(20)
    info.Paint = function(s, w, h)
        local left = math.max(0, math.ceil((t.secs or 12) - (CurTime() - f.openAt)))
        draw.SimpleText(string.format("Resolve: %d    No answer in %ds is silence.", t.resolve or 0, left), "DermaDefault", 8, 3, DIM)
    end
    local function Row(text, col, c, enabled)
        local b = Button(f, text, col, function() if enabled ~= false then Answer(c) end end)
        b:Dock(TOP)
        b:SetTall(32)
        b:DockMargin(8, 3, 8, 0)
        if enabled == false and b.SetEnabled then b:SetEnabled(false) end
        return b
    end
    Row("Tell the truth", Color(70, 110, 80), "truth")
    Row("Lie (he may see through it)", Color(110, 90, 50), "lie")
    if (t.resolve or 0) > 0 then
        Row("Say nothing (the baton)", Color(70, 90, 130), "silent")
    else
        Row("Say nothing (you can't take any more)", Color(55, 60, 66), "silent", false)
    end
    if t.bargain then Row("Bargain: the truth, for a shorter sentence", Color(90, 80, 120), "bargain") end
    Row("Tell them everything (and it stops)", BAD, "everything")
    local baseThink = f.Think
    f.Think = function(self)
        if baseThink then baseThink(self) end
        if CurTime() - self.openAt > (t.secs or 12) + 1 or not LocalPlayer():GetNW2Bool("lc_interrogated", false) then self:Remove() end
    end
end

------------------------------------------------------------------------
-- The unit asking
------------------------------------------------------------------------

local function Do(what, n)
    net.Start("lc_intr_cp_do")
    net.WriteString(what)
    net.WriteUInt(n or 0, 3)
    net.SendToServer()
end
LC_CL.InterrogationDo = Do

local function BuildCP()
    local BG, CARD, INK, DIM, ACC, GOOD, BAD = Look()
    if IsValid(cpWin) then return cpWin end
    local f = vgui.Create("DFrame")
    cpWin = f
    f:SetTitle("Interrogation")
    f:SetSize(math.min(ScrW() - 40, 480), math.min(ScrH() - 40, 460))
    f:SetPos(40, math.floor(ScrH() * 0.2))
    f:MakePopup()
    f.Paint = function(s, w, h) draw.RoundedBox(6, 0, 0, w, h, BG) draw.RoundedBox(0, 0, 0, w, 24, Color(14, 16, 20)) end
    f.OnRemove = function() if not f.silent then Do("done") end if cpWin == f then cpWin = nil end end
    local head = vgui.Create("DPanel", f)
    head:Dock(TOP)
    head:SetTall(40)
    head.Paint = function(s, w, h)
        local st = cpState or {}
        draw.SimpleText("Questioning " .. tostring(st.who or "the prisoner"), "DermaDefaultBold", 6, 2, INK)
        draw.SimpleText(string.format("Their resolve: %d    Blows: %d%s", st.resolve or 0, st.hits or 0, (st.waiting or 0) > 0 and "    (waiting for an answer)" or ""), "DermaDefault", 6, 20, DIM)
    end
    for i = 1, 3 do
        local b = Button(f, "", Color(70, 90, 130), function() Do("ask", i) end)
        b:Dock(TOP)
        b:SetTall(30)
        b:DockMargin(6, 3, 6, 0)
        b.Think = function(s)
            local st = cpState or {}
            local text = (st.questions or {})[i] or ("Question " .. i)
            if st.asked and st.asked[i] then text = text .. " (asked)" end
            if s.GetText and s:GetText() ~= text and s.SetText then s:SetText(text) end
        end
    end
    local baton = Button(f, "Use the baton", BAD, function() Do("baton") end)
    baton:Dock(TOP)
    baton:SetTall(30)
    baton:DockMargin(6, 6, 6, 0)
    local done = Button(f, "Done", Color(55, 60, 66), function() f:Remove() end)
    done:Dock(BOTTOM)
    done:SetTall(30)
    local list = vgui.Create("DPanel", f)
    list:Dock(FILL)
    list:DockMargin(6, 6, 6, 6)
    list.Paint = function(s, w, h)
        draw.RoundedBox(4, 0, 0, w, h, CARD)
        local st = cpState or {}
        draw.SimpleText("What they've said (true or not: you'll find out):", "DermaDefaultBold", 6, 4, ACC)
        local y = 24
        for _, a in ipairs(st.answers or {}) do
            local line = tostring(a.text or "")
            if #line > 70 then line = string.sub(line, 1, 68) .. "..." end
            draw.SimpleText(line, "DermaDefault", 6, y, INK)
            y = y + 16
        end
    end
    return f
end

net.Receive("lc_intr_q", function()
    local t = util.JSONToTable(net.ReadString() or "") or {}
    BuildQuestion(t)
end)
net.Receive("lc_intr_cp", function()
    local t = util.JSONToTable(net.ReadString() or "") or {}
    if t.done then
        if IsValid(cpWin) then cpWin.silent = true cpWin:Remove() end
        cpWin, cpState = nil, nil
        return
    end
    cpState = t
    BuildCP()
end)

function LC_CL.InterrogationWindows() return qWin, cpWin, cpState end
