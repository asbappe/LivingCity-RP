--[[
    Living City (client): "My career", from the full menu (C)

    Your rank, the XP to the next one, every rank of your faction and what it takes, and the
    way up in plain words (for Civil Protection, the way to the Overwatch). A button to ask
    Overwatch for a reassessment when you turned the conditioning down and the hour is up.
    The server side is sv_livingcity_career.lua.
]]

LC_CL = LC_CL or {}

local INK, DIM, GOOD, LOCK = Color(232, 226, 210), Color(160, 156, 146), Color(130, 205, 140), Color(150, 120, 110)
local PANEL, ROW, ME = Color(16, 18, 22, 245), Color(30, 33, 40, 240), Color(40, 60, 90, 240)

surface.CreateFont("LCCareerTitle", { font = "Trebuchet MS", size = 24, weight = 700 })
surface.CreateFont("LCCareerRow", { font = "Trebuchet MS", size = 16, weight = 700 })

local function ReadCompressed()
    local len = net.ReadUInt(32)
    local data = net.ReadData(len)
    local json = util.Decompress(data or "")
    return json and util.JSONToTable(json) or nil
end

local frame

-- A "My career" button for the top of the job board (F3) and the faction menu (F4): the owner, 7 November,
-- "this needs to be visible in F3 or F4". close: the menu it sits in, shut when the page opens.
function LC_CL.CareerButton(parent, close)
    local f = IsValid(LocalPlayer()) and LocalPlayer():GetNW2String("lcf_faction", "") or ""
    local unit = f == "cp" or f == "ota"
    local b = vgui.Create("DButton", parent)
    b:Dock(TOP)
    b:SetTall(28)
    b:DockMargin(4, 2, 4, 6)
    b:SetText(unit and "My career: rank, XP to the next, and the way to the Overwatch" or "My career: rank, XP to the next, and the way up")
    b:SetTooltip("Your rank, what the next one takes, and where your stories stand. (Also C > My career.)")
    b.DoClick = function()
        LC_CL.AskCareer("")
        if IsValid(close) then close:Remove() end
    end
    return b
end

function LC_CL.AskCareer(what)
    net.Start("lc_career_ask")
    net.WriteString(what or "")
    net.SendToServer()
end

local function Label(parent, text, col, font)
    local l = vgui.Create("DLabel", parent)
    l:Dock(TOP)
    l:DockMargin(6, 2, 6, 4)
    l:SetFont(font or "DermaDefault")
    l:SetWrap(true)
    l:SetAutoStretchVertical(true)
    l:SetTextColor(col or INK)
    l:SetText(text or "")
    return l
end

function LC_CL.OpenCareer(t)
    if IsValid(frame) then frame:Remove() end
    if not t then return end
    frame = vgui.Create("DFrame")
    frame:SetTitle("")
    frame:SetSize(math.min(ScrW() - 40, 620), math.min(ScrH() - 40, 600))
    frame:Center()
    frame:MakePopup()
    local col = Color(80, 140, 255)
    frame.Paint = function(self, w, h)
        draw.RoundedBox(6, 0, 0, w, h, PANEL)
        draw.SimpleText("MY CAREER" .. (t.faction and (": " .. string.upper(t.faction)) or ""), "LCCareerTitle", 16, 8, col)
    end
    local scroll = vgui.Create("DScrollPanel", frame)
    scroll:Dock(FILL)
    scroll:DockMargin(8, 28, 8, 8)
    if t.none then
        Label(scroll, "Your side has no ranks to climb. Your board (F3) still has work for you.", DIM)
        return
    end
    local ranks = t.ranks or {}
    local cur, nxt = ranks[t.rank or 1], ranks[(t.rank or 1) + 1]
    -- where you are, and the bar to the next rank
    local bar = vgui.Create("DPanel", scroll)
    bar:Dock(TOP)
    bar:DockMargin(4, 4, 4, 8)
    bar:SetTall(46)
    bar.Paint = function(self, w, h)
        draw.SimpleText((cur and cur.name or "?") .. string.format("   %d XP", t.xp or 0), "LCCareerRow", 2, 10, INK, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        local frac, txt = 1, "top rank"
        if nxt and nxt.overwatch and not t.conditioned then
            txt = "next: the Overwatch, after the conditioning"
        elseif nxt then
            local base, goal = cur and cur.xp or 0, nxt.xp or 0
            frac = goal > base and math.Clamp(((t.xp or 0) - base) / (goal - base), 0, 1) or 1
            txt = string.format("%d / %d XP to %s", t.xp or 0, goal, nxt.name)
        end
        draw.RoundedBox(3, 2, 24, w - 4, 16, Color(40, 38, 34, 230))
        draw.RoundedBox(3, 2, 24, math.max(0, (w - 4) * frac), 16, Color(col.r, col.g, col.b, 170))
        draw.SimpleText(txt, "DermaDefault", 8, 32, INK, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end
    -- the ladder
    Label(scroll, "THE RANKS", DIM, "DermaDefaultBold")
    for i, r in ipairs(ranks) do
        local row = vgui.Create("DPanel", scroll)
        row:Dock(TOP)
        row:DockMargin(4, 0, 4, 3)
        row:SetTall(24)
        local mine, done = i == t.rank, i < (t.rank or 1)
        local locked = r.overwatch and not t.conditioned
        row.Paint = function(self, w, h)
            draw.RoundedBox(3, 0, 0, w, h, mine and ME or ROW)
            draw.SimpleText((done and "[x] " or mine and "[>] " or "[ ] ") .. r.name, "LCCareerRow", 8, h / 2, done and GOOD or (locked and LOCK or INK), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            local right = string.format("%d XP", r.xp or 0) .. (locked and "  (needs the conditioning)" or "") .. (mine and "  (you)" or "")
            draw.SimpleText(right, "DermaDefault", w - 8, h / 2, locked and LOCK or DIM, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
        end
    end
    -- the way up, in words
    Label(scroll, "THE WAY UP", DIM, "DermaDefaultBold"):DockMargin(6, 10, 6, 4)
    for _, s in ipairs(t.steps or {}) do Label(scroll, "- " .. s, INK) end
    if t.canReassess or t.reassessIn then
        local b = vgui.Create("DButton", scroll)
        b:Dock(TOP)
        b:DockMargin(6, 8, 6, 4)
        b:SetTall(30)
        b:SetText(t.canReassess and "Ask Overwatch for a reassessment (the Overwatch Candidate story comes back)"
            or string.format("Ask Overwatch for a reassessment (in about %d minutes)", math.ceil((t.reassessIn or 0) / 60)))
        b:SetEnabled(t.canReassess == true)
        b.DoClick = function() LC_CL.AskCareer("reassess") end
    end
end

net.Receive("lc_career", function() LC_CL.OpenCareer(ReadCompressed()) end)
