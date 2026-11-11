--[[
    Living City (client): a unit's search as a short pat-down
    (sv_livingcity_patsearch.lua). The unit gets a body with four spots to
    click (Jacket, Waist, Legs, Boots), each checked for a second; the
    person searched gets a small panel: the four spots, which one is being
    checked, "Stand still", and R to slip one thing into a spot already
    checked, once. The look is the job games' (cl_livingcity_moregames.lua).
]]

LC_CL = LC_CL or {}

local unitWin, unitState, targetPanel, targetState
local checkStart, checkSpot, flashAt, flashSeen = 0, nil, -1e9, 0

local function Look()
    local l = LC_CL.JobLook or {}
    return l.BG or Color(24, 27, 32), l.CARD or Color(36, 40, 47), l.INK or Color(235, 235, 225), l.DIM or Color(170, 175, 180),
        l.ACC or Color(230, 190, 90), l.GOOD or Color(80, 160, 90), l.BAD or Color(170, 70, 60)
end

local function SendCheck(i) net.Start("lc_pat_check") net.WriteUInt(i, 3) net.SendToServer() end
local function SendClose() net.Start("lc_pat_close") net.SendToServer() end
local function SendSlip() net.Start("lc_pat_slip") net.SendToServer() end

local function CloseAll()
    if IsValid(unitWin) then unitWin.silent = true unitWin:Remove() end
    if IsValid(targetPanel) then targetPanel:Remove() end
    unitWin, unitState, targetPanel, targetState, checkSpot = nil, nil, nil, nil, nil
end

-- Where each spot sits on the body (fractions of the body area): x, y, w, h.
local PLACE = { { 0.30, 0.20, 0.40, 0.26 }, { 0.30, 0.47, 0.40, 0.08 }, { 0.32, 0.56, 0.36, 0.28 }, { 0.28, 0.85, 0.44, 0.10 } }

local function SpotText(sp)
    if not sp then return "" end
    if sp.state == 2 then return sp.name .. ": " .. ((sp.text == "Nothing.") and "nothing" or "FOUND") end
    if sp.state == 1 then return sp.name .. ": checking..." end
    return sp.name
end

local function BuildUnit()
    local BG, CARD, INK, DIM, ACC, GOOD, BAD = Look()
    local f = vgui.Create("DFrame")
    unitWin = f
    f:SetTitle("Pat-down")
    f:SetSize(math.min(ScrW() - 40, 380), math.min(ScrH() - 40, 500))
    f:Center()
    f:MakePopup()
    f.Paint = function(s, pw, ph) draw.RoundedBox(6, 0, 0, pw, ph, BG) draw.RoundedBox(0, 0, 0, pw, 24, Color(14, 16, 20)) end
    f.OnRemove = function() if not f.silent then SendClose() end if unitWin == f then unitWin, unitState = nil, nil end end

    local foot = vgui.Create("DPanel", f)
    foot:Dock(BOTTOM)
    foot:SetTall(150)
    foot.Paint = function(s, w, h)
        local st = unitState or {}
        local y = 0
        if st.flash and CurTime() - flashAt < 3 then
            local pulse = 0.5 + 0.5 * math.abs(math.sin(CurTime() * 8))
            draw.RoundedBox(4, 0, 0, w, 22, Color(BAD.r, BAD.g, BAD.b, 120 + 100 * pulse))
            draw.SimpleText(st.flash, "DermaDefaultBold", w / 2, 11, INK, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        y = 26
        for _, sp in ipairs(st.spots or {}) do
            if sp.state == 2 then
                draw.SimpleText(sp.name .. ": " .. tostring(sp.text or ""), "DermaDefault", 4, y, sp.text == "Nothing." and DIM or BAD)
                y = y + 16
            end
        end
        draw.SimpleText("Click a spot to check it. Spots you skip keep what's in them.", "DermaDefault", 4, h - 56, DIM)
    end
    local done = (LC_CL.JobLook and LC_CL.JobLook.Button or function(p, text, _, click)
        local b = vgui.Create("DButton", p) b:SetText(text) b.DoClick = click return b
    end)(foot, "Done", Color(70, 90, 130), function() if IsValid(f) then f:Remove() end end)
    done:Dock(BOTTOM)
    done:SetTall(32)
    -- their papers next (a citizen NPC's): the search ends as it stands (sv_livingcity_patsearch.lua)
    local papers = (LC_CL.JobLook and LC_CL.JobLook.Button or function(p, text, _, click)
        local b = vgui.Create("DButton", p) b:SetText(text) b.DoClick = click return b
    end)(foot, "Done searching: check their papers", Color(60, 110, 100), function()
        net.Start("lc_pat_papers") net.SendToServer()
        if IsValid(f) then f.silent = true f:Remove() end
    end)
    papers:Dock(BOTTOM)
    papers:DockMargin(0, 0, 0, 4)
    papers:SetTall(26)
    papers.Think = function(s) local st = unitState or {} s:SetVisible(st.papers == true and st.live == true) end

    local body = vgui.Create("DPanel", f)
    body:Dock(FILL)
    body:DockMargin(0, 6, 0, 6)
    body.Paint = function(s, w, h)
        local st = unitState or {}
        draw.SimpleText("Searching " .. tostring(st.who or "them"), "DermaDefaultBold", w / 2, 2, INK, TEXT_ALIGN_CENTER)
        local cx, r = w / 2, math.floor(h * 0.07)
        draw.RoundedBox(r, cx - r, math.floor(h * 0.05), r * 2, r * 2, CARD) -- (the head)
        draw.RoundedBox(4, math.floor(w * 0.18), math.floor(h * 0.21), math.floor(w * 0.11), math.floor(h * 0.30), CARD) -- (arms)
        draw.RoundedBox(4, math.floor(w * 0.71), math.floor(h * 0.21), math.floor(w * 0.11), math.floor(h * 0.30), CARD)
    end
    body.spots = {}
    for i = 1, 5 do -- (the fifth: what they carry, when they carry something)
        local b = vgui.Create("DButton", body)
        b:SetText("")
        b.Paint = function(s, w, h)
            local st = unitState or {}
            local sp = (st.spots or {})[i]
            if not sp then return end
            local col = Color(70, 90, 130)
            if sp and sp.state == 2 then col = (sp.text == "Nothing.") and Color(55, 60, 66) or BAD end
            draw.RoundedBox(4, 0, 0, w, h, s:IsHovered() and sp and sp.state == 0 and Color(90, 110, 150) or col)
            if sp and sp.state == 1 then
                local frac = math.Clamp((CurTime() - checkStart) / (st.secs or 1), 0, 1)
                draw.RoundedBox(4, 0, 0, math.floor(w * frac), h, ACC)
            end
            draw.SimpleText(SpotText(sp), "DermaDefaultBold", w / 2, h / 2, INK, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        b.DoClick = function()
            local st = unitState or {}
            local sp = (st.spots or {})[i]
            if st.live and sp and sp.state == 0 and not st.checking then SendCheck(i) end
        end
        body.spots[i] = b
    end
    body.PerformLayout = function(s, w, h)
        for i, b in ipairs(s.spots) do
            local p = PLACE[i] or { 0.02, 0.56, 0.24, 0.16 } -- (the case or parcel: beside the legs, at the hand)
            b:SetPos(math.floor(w * p[1]), math.floor(h * p[2]))
            b:SetSize(math.floor(w * p[3]), math.max(18, math.floor(h * p[4])))
        end
    end
    body:InvalidateLayout(true)
    return f
end

local function TargetPanel()
    local BG, CARD, INK, DIM, ACC, GOOD = Look()
    local p = vgui.Create("DPanel")
    p:SetSize(270, 230)
    if LC_CL.ThemeWindow then LC_CL.SetTheme(p, "custody") LC_CL.ThemeWindow(p, "DPanel") end -- (being searched looks the same whoever you are)
    p:SetMouseInputEnabled(false) -- (it only shows; the key is R)
    p:SetPos(ScrW() - 290, math.floor(ScrH() * 0.32))
    p.Paint = function(s, w, h)
        local st = targetState or {}
        draw.RoundedBox(6, 0, 0, w, h, BG)
        draw.SimpleText("Searched by " .. tostring(st.who or "a unit"), "DermaDefaultBold", 10, 8, INK)
        draw.SimpleText("Stand still.", "DermaLarge", 10, 26, ACC)
        local y = 62
        for _, sp in ipairs(st.spots or {}) do
            local tag, col = "not yet", DIM
            if sp.state == 1 then tag, col = "being checked", ACC elseif sp.state == 2 then tag, col = "checked", GOOD end
            if sp.state == 1 then draw.RoundedBox(4, 4, y - 2, w - 8, 34, CARD) end
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
        local down = input and input.IsKeyDown and input.IsKeyDown(KEY_R or 28) or false
        local typing = vgui.GetKeyboardFocus and IsValid(vgui.GetKeyboardFocus())
        if down and not s.wasDown and not typing and targetState and targetState.slip == "ready" then SendSlip() end
        s.wasDown = down
    end
    return p
end

net.Receive("lc_pat_open", function()
    local t = util.JSONToTable(net.ReadString() or "") or {}
    if t.role == "unit" then
        if t.checking and t.checking ~= checkSpot then checkStart = CurTime() end
        checkSpot = t.checking
        if t.flash and (t.flashId or 0) ~= flashSeen then flashSeen, flashAt = t.flashId or 0, CurTime() surface.PlaySound("buttons/button10.wav") end
        unitState = t
        if not IsValid(unitWin) then
            local ok = pcall(BuildUnit)
            if not ok or not IsValid(unitWin) then
                if IsValid(unitWin) then unitWin.silent = true unitWin:Remove() end
                unitWin, unitState = nil, nil
                SendClose() -- (no window: the server searches the old way)
                return
            end
            SendCheck(0) -- (the window is open)
        end
    elseif t.role == "target" then
        targetState = t
        if not IsValid(targetPanel) then targetPanel = TargetPanel() end
    end
end)
net.Receive("lc_pat_close", CloseAll)

function LC_CL.PatSearchWindow() return unitWin, unitState end
function LC_CL.PatSearchPanel() return targetPanel, targetState end
LC_CL.PatSearchClose = CloseAll
