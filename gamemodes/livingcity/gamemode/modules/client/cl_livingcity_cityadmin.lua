--[[
    Living City (client): the City Administrator election (a vote on screen) and the office
    (sv_livingcity_cityadmin.lua).
]]

LC_CL = LC_CL or {}

local function ReadCompressed()
    local len = net.ReadUInt(32)
    local data = net.ReadData(len)
    local json = util.Decompress(data or "")
    return json and util.JSONToTable(json) or nil
end

local function Act(what, arg, target)
    net.Start("lc_admin_do") net.WriteString(what) net.WriteString(arg or "") net.WriteEntity(IsValid(target) and target or NULL) net.SendToServer()
end

-- A recall (sv_livingcity_cityadmin.lua): Civil Protection and the Administration vote yes or no
net.Receive("lc_recall", function()
    local secs, sitting, rival = net.ReadFloat(), net.ReadString(), net.ReadString()
    if IsValid(LC_CL.RecallFrame) then LC_CL.RecallFrame:Remove() end
    local f = vgui.Create("DFrame")
    LC_CL.RecallFrame = f
    f:SetTitle("Recall: City Administrator")
    f:SetSize(380, 170)
    f:Center()
    f:MakePopup()
    local ends = CurTime() + secs
    local lbl = vgui.Create("DLabel", f)
    lbl:Dock(TOP) lbl:SetTall(48) lbl:SetWrap(true)
    lbl.Think = function(s) s:SetText(string.format("%s calls for %s to be removed, and to take the office. The vote closes in %d seconds.", rival, sitting, math.max(0, math.ceil(ends - CurTime())))) end
    for _, b in ipairs({ { "Yes: remove " .. sitting, true }, { "No: " .. sitting .. " stays", false } }) do
        local btn = vgui.Create("DButton", f)
        btn:Dock(TOP) btn:SetTall(34) btn:DockMargin(0, 4, 0, 0)
        btn:SetText(b[1])
        btn.DoClick = function() net.Start("lc_recall_vote") net.WriteBool(b[2]) net.SendToServer() f:Remove() end
    end
end)

net.Receive("lc_election", function()
    local secs = net.ReadFloat()
    local n = net.ReadUInt(6)
    local cands = {}
    for _ = 1, n do cands[#cands + 1] = { i = net.ReadUInt(6), name = net.ReadString() } end
    if IsValid(LC_CL.ElectionFrame) then LC_CL.ElectionFrame:Remove() end
    local f = vgui.Create("DFrame")
    LC_CL.ElectionFrame = f
    f:SetTitle("Election: City Administrator")
    f:SetSize(360, 80 + #cands * 44)
    f:Center()
    f:MakePopup()
    local ends = CurTime() + secs
    local lbl = vgui.Create("DLabel", f)
    lbl:Dock(TOP)
    lbl:SetTall(24)
    lbl.Think = function(s) s:SetText(string.format("Vote for one. The vote closes in %d seconds.", math.max(0, math.ceil(ends - CurTime())))) end
    for _, c in ipairs(cands) do
        local b = vgui.Create("DButton", f)
        b:Dock(TOP)
        b:SetTall(38)
        b:DockMargin(0, 4, 0, 0)
        b:SetText(c.name)
        b.DoClick = function()
            net.Start("lc_election_vote") net.WriteUInt(c.i, 6) net.SendToServer()
            f:Remove()
        end
    end
end)

------------------------------------------------------------------------
-- The office: the tablet's own window (the owner, 14 November: "the administrator's tablet opens a
-- hecking C menu? no, please make a custom screen ... even if it's just as simple looking as the F4
-- menu"). Tabs along the top, as on F4, and every act a button of its own: the old drop-down's lists
-- opened over each other, so a click meant for "A Combine parade" could land on the first job of
-- "A Union job bonus" (Sanitation Worker), which had opened on the same row.
------------------------------------------------------------------------

local PANEL, TAB, TAB_ON, TAB_HOVER = Color(16, 15, 13, 245), Color(26, 26, 28, 250), Color(44, 42, 38, 250), Color(34, 33, 31, 250)
local DIM, TEXT, ACCENT, ROW, ROW_HOVER = Color(160, 156, 146), Color(225, 222, 212), Color(110, 170, 240), Color(30, 30, 32, 250), Color(52, 50, 46, 250)

-- What the window holds, tab by tab. A row is { head = "..." } (a heading), { note = "..." } (a grey
-- line), { text = "...", act = function } (a button) or { name = "...", acts = { { text, act }, ... } }
-- (a person, with a row of small buttons). Do: what a button calls (the test's own, or Act).
function LC_CL.AdminOfficePages(t, Do)
    t = t or {}
    Do = Do or Act
    local pages = {}
    local function Page(id, name) local p = { id = id, name = name, rows = {} } pages[#pages + 1] = p return p.rows end
    local function B(rows, text, what, arg, target) rows[#rows + 1] = { text = text, act = function() Do(what, arg, target) end } end

    local city = Page("city", "The city")
    city[#city + 1] = { head = "Call a city event" }
    B(city, "A curfew", "event", "curfew")
    B(city, "A ration day", "event", "rations")
    B(city, "An inspection sweep", "event", "sweep")
    B(city, "A Combine parade", "event", "parade")
    city[#city + 1] = { head = "Rations for the hour" }
    B(city, "Generous (full packets for all)", "rations", "generous")
    B(city, "Austere (short packets for all)", "rations", "austere")
    B(city, "As usual", "rations", "normal")
    city[#city + 1] = { head = "Commissary prices for the hour" }
    for _, f in ipairs({ 0.75, 0.9, 1, 1.1, 1.25 }) do B(city, string.format("%d%%", f * 100), "prices", tostring(f)) end
    city[#city + 1] = { text = "The Commissary and the market", act = function() net.Start("lc_market_open") net.SendToServer() end } -- (cl_livingcity_market.lua)

    -- the sealed directives (cl_livingcity_directives.lua), and the orders their riddles need
    local orders = Page("orders", "Orders")
    orders[#orders + 1] = { text = "Sealed directives", act = function() net.Start("lc_directive_act") net.WriteString("open") net.WriteString("") net.SendToServer() end }
    orders[#orders + 1] = { head = "Orders" }
    B(orders, "Shut down the grid (a blackout, 15 minutes)", "blackout")
    B(orders, "Restore the power", "lift")
    B(orders, "Stand down the morticians (20 minutes)", "morticians")
    B(orders, "Ban weedkiller (20 minutes)", "weedkiller")
    B(orders, "Declare a Day of Cleansing", "cleansing")
    B(orders, "Permit Father Grigori's flock to worship", "worship")
    B(orders, "An amnesty: open every cell", "amnesty")

    local work = Page("work", "Job bonus")
    work[#work + 1] = { head = "A Union job bonus for the hour" }
    for _, j in ipairs(t.jobs or {}) do B(work, j.name, "bonus", j.id) end

    -- tonight's dream (sv_livingcity_dreams.lua): Happy, Neutral or Nightmare, for everyone asleep
    local d = t.dream
    if d then
        local dm = Page("dream", "Tonight's dream")
        local function Note(text) dm[#dm + 1] = { note = text } end
        if not d.ready then
            Note(d.why or "The city can't dream yet.")
        else
            -- (when the next one is: the countdown is as it was when the tablet was opened)
            local when = LC_CL.DreamWhenLine and LC_CL.DreamWhenLine(d)
            if when then Note(when) elseif d.busy then Note("The city is dreaming right now.") end
            if d.vort then Note(d.vort) end -- (freed vortigaunts breaking into her propaganda dreams)
            local pl = d.plan or {}
            if pl.feel then Note(pl.feel) end
            Note(string.format("You choose only a kind (Nightmare or propaganda), and only once every %d nights; the city chooses which dream, and every other night is Happy or Neutral.", pl.every or 3))
            if pl.chosen then
                Note("Chosen for tonight: " .. (pl.chosen == "nightmare" and "a Nightmare" or "a propaganda dream") .. (d.at and string.format(", in about %d seconds", d.at) or ", after you say good night") .. ". You'll be in it.")
                B(dm, "Take back tonight's choice (nothing spent)", "dream", "cancel")
            elseif pl.canPick then
                B(dm, "A Nightmare tonight (a punishment)", "dream", "nightmare")
                B(dm, "A propaganda dream tonight (instruction)", "dream", "propaganda")
            else
                Note(pl.why or "You can't choose tonight's dream.")
            end
            if d.waiting and not pl.chosen then Note("Tonight: " .. tostring(d.waiting.mood) .. (d.waiting.auto and ", the city's own choice" or "")) end
            local skip = pl.skip ~= false
            B(dm, skip and "Dreams you didn't choose: you skip them (click to join them)" or "Dreams you didn't choose: you join them (click to skip them)",
                "dream", skip and "join" or "skip")
            -- propaganda dreams: star in them herself (when she's asleep for one with someone else), or a giant figure of her
            local on = t.dreamStar ~= "off"
            B(dm, on and "Star in propaganda dreams yourself: on (click to use a giant figure of you)"
                or "Star in propaganda dreams yourself: off (click to star in them)", "dreamstar", on and "off" or "on")
        end
    end

    local people = Page("people", "People")
    for _, p in ipairs(t.people or {}) do
        local ent = Entity(p.idx or 0)
        local acts = {
            { "Commend (+15)", function() Do("commend", "15", ent) end },
            { "Censure (-15)", function() Do("censure", "15", ent) end },
        }
        if p.wanted then acts[#acts + 1] = { "Pardon", function() Do("pardon", "", ent) end } end
        acts[#acts + 1] = { "A week's free housing", function() Do("housing", "", ent) end }
        acts[#acts + 1] = { "A curfew permit", function() Do("permit", "", ent) end }
        people[#people + 1] = { name = tostring(p.name) .. (p.wanted and "  (wanted)" or ""), acts = acts }
    end
    if #people == 0 then people[1] = { note = "Nobody else is in the city." } end

    -- the Combine's manpower (sv_livingcity_manpower.lua): Civil Protection's and Overwatch's reserves, as F2 > Combine manpower shows them
    local mp = t.manpower or LC_CL.Manpower or {}
    if #mp > 0 then
        local rows = Page("manpower", "Manpower")
        for _, l in ipairs(mp) do rows[#rows + 1] = { note = l } end
    end
    return pages
end

local office, officeTab, officePages = nil, "city", {}

local function OfficeSelect(id)
    if not IsValid(office) then return end
    if not officePages[id] then id = "city" end
    officeTab = id
    for pid, p in pairs(officePages) do if IsValid(p) then p:SetVisible(pid == id) end end
end

-- Ask the server for the office again (after an act, so what the window says is still true).
local function OfficeAsk()
    net.Start("lc_quickmore") net.WriteString("office") net.WriteString("") net.WriteEntity(NULL) net.SendToServer()
end

local function OfficeButton(parent, text, act, wide)
    local b = vgui.Create("DButton", parent)
    b:SetText("")
    b:SetTall(26)
    if wide then b:SetWide(wide) end
    b.Paint = function(self, w, h)
        draw.RoundedBox(3, 0, 0, w, h, self:IsHovered() and ROW_HOVER or ROW)
        draw.SimpleText(text, "DermaDefault", wide and w / 2 or 10, h / 2, TEXT, wide and TEXT_ALIGN_CENTER or TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end
    b.DoClick = function()
        act()
        timer.Simple(0.5, function()
            local me = LocalPlayer()
            if IsValid(office) and IsValid(me) and me:GetNW2String("lcf_faction", "") == "admin" then OfficeAsk() end
        end)
    end
    return b
end

-- Build (or fill again, on the tab it was on) the tablet's window from what the server sent.
function LC_CL.AdminOffice(t)
    local pages = LC_CL.AdminOfficePages(t)
    if not IsValid(office) then
        office = vgui.Create("DFrame")
        office:SetTitle("")
        office:SetSize(math.min(ScrW() - 60, 720), math.min(ScrH() - 60, 600))
        office:Center()
        office:MakePopup()
        office.Paint = function(self, w, h) draw.RoundedBox(4, 0, 0, w, h, PANEL) end
    end
    if IsValid(office.lcBody) then office.lcBody:Remove() end
    local body = vgui.Create("DPanel", office)
    office.lcBody = body
    body:Dock(FILL)
    body.Paint = function() end
    officePages = {}
    local bar = vgui.Create("DPanel", body)
    bar:Dock(TOP)
    bar:SetTall(32)
    bar:DockMargin(2, 0, 2, 6)
    bar.Paint = function() end
    for _, pg in ipairs(pages) do
        local b = vgui.Create("DButton", bar)
        b:Dock(LEFT)
        b:SetWide(112)
        b:DockMargin(0, 0, 4, 0)
        b:SetText("")
        b.Paint = function(self, w, h)
            local on = officeTab == pg.id
            draw.RoundedBox(4, 0, 0, w, h, on and TAB_ON or (self:IsHovered() and TAB_HOVER or TAB))
            if on then draw.RoundedBox(0, 0, h - 3, w, 3, ACCENT) end
            draw.SimpleText(string.upper(pg.name), "DermaDefaultBold", w / 2, h / 2, on and ACCENT or DIM, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        b.DoClick = function() OfficeSelect(pg.id) end
        local sc = vgui.Create("DScrollPanel", body)
        sc:Dock(FILL)
        sc:SetVisible(false)
        officePages[pg.id] = sc
        for _, r in ipairs(pg.rows) do
            if r.head or r.note then
                local l = vgui.Create("DLabel", sc)
                l:Dock(TOP)
                l:DockMargin(8, r.head and 10 or 2, 8, 2)
                l:SetFont(r.head and "DermaDefaultBold" or "DermaDefault")
                l:SetTextColor(r.head and ACCENT or DIM)
                l:SetText(r.head and string.upper(r.head) or r.note)
                l:SetWrap(true)
                l:SetAutoStretchVertical(true)
            elseif r.acts then
                local line = vgui.Create("DPanel", sc)
                line:Dock(TOP)
                line:SetTall(30)
                line:DockMargin(8, 2, 8, 2)
                line.Paint = function(_, w, h) draw.SimpleText(r.name, "DermaDefaultBold", 2, h / 2, TEXT, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER) end
                for i = #r.acts, 1, -1 do
                    local a = r.acts[i]
                    local b2 = OfficeButton(line, a[1], a[2], 22 + #a[1] * 6)
                    b2:Dock(RIGHT)
                    b2:DockMargin(4, 2, 0, 2)
                end
            else
                local b2 = OfficeButton(sc, r.text, r.act)
                b2:Dock(TOP)
                b2:DockMargin(8, 2, 8, 2)
            end
        end
    end
    OfficeSelect(officeTab)
    return office
end
function LC_CL.AdminOfficeOpen() return IsValid(office) end
function LC_CL.AdminOfficeClose() if IsValid(office) then office:Remove() end office = nil end

net.Receive("lc_admin_office", function()
    LC_CL.AdminOffice(ReadCompressed() or {})
end)
