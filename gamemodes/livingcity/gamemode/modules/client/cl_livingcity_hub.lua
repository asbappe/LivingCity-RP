--[[
    Living City (client): F4, one window for your work and your place in the city

    The owner, 7 November: "consolidate F3 and F4 ... a career/factions tab at the top".
    Three tabs along the top:

      Jobs       the job board: the Union employment card, the jobs and your stories
                 (cl_livingcity_quests.lua). The first tab, and the one a new session opens on.
      Career     your rank, the XP to the next one, the way up, and Overwatch's
                 reassessment (cl_livingcity_career.lua)
      Factions   who you can join, special roles, and the admin testing tools
                 (cl_livingcity_factions.lua)
      Me and settings  you, help and tips, and every setting (the owner, 19 November: these were
                 only in the C menu); built here, with nothing to ask the server for

    The last tab you looked at is remembered until you leave the server.

    The server fills each tab with its own message: lcq_board, lc_career, lcf_menu. F4
    (ShowSpare2, sv_livingcity_factions.lua) sends lc_hub first, then all three. Anything else
    that sends one of them (!jobs, !faction, C > My career, the board again after you take a
    job) opens this window on that tab and asks for the other two.
]]

LC_CL = LC_CL or {}

local TABS = {
    { id = "jobs", name = "Jobs", color = Color(230, 180, 90) },
    { id = "career", name = "Career", color = Color(80, 140, 255) },
    { id = "factions", name = "Factions", color = Color(160, 190, 160) },
    { id = "me", name = "Me and settings", color = Color(200, 170, 220) },
}
local DIM = Color(160, 156, 146)
local PANEL, TAB, TAB_ON, TAB_HOVER = Color(16, 15, 13, 245), Color(26, 26, 28, 250), Color(44, 42, 38, 250), Color(34, 33, 31, 250)

local hub, pages, filled = nil, {}, {}
local current
local last = "jobs" -- (the tab you looked at last, for this session)

local BuildMe -- (below)

-- ask the server for a tab's content
local function Ask(id)
    if id == "me" then if LC_CL.HubFill then LC_CL.HubFill("me", BuildMe) end
    elseif id == "jobs" then RunConsoleCommand("lcq_board")
    elseif id == "factions" then RunConsoleCommand("lcf_menu")
    elseif id == "career" and LC_CL.AskCareer then LC_CL.AskCareer("") end
end

local function Select(id)
    if not IsValid(hub) or not pages[id] then return end
    current, last = id, id
    for tid, p in pairs(pages) do if IsValid(p) then p:SetVisible(tid == id) end end
end

local function Build()
    hub = vgui.Create("DFrame")
    hub:SetTitle("")
    hub:SetSize(math.min(ScrW() - 60, 780), math.min(ScrH() - 60, 660))
    hub:Center()
    hub:MakePopup()
    if LC_CL.FMenu then LC_CL.FMenu("gm_showspare2", hub) end -- (F3 shuts it and opens the pockets: cl_livingcity_fmenus.lua)
    hub.Paint = function(self, w, h) draw.RoundedBox(4, 0, 0, w, h, PANEL) end
    pages, filled = {}, {}
    local bar = vgui.Create("DPanel", hub)
    bar:Dock(TOP)
    bar:SetTall(32)
    bar:DockMargin(2, 0, 2, 6)
    bar.Paint = function() end
    for _, t in ipairs(TABS) do
        local b = vgui.Create("DButton", bar)
        b:Dock(LEFT)
        b:SetWide(150)
        b:DockMargin(0, 0, 4, 0)
        b:SetText("")
        b.Paint = function(self, w, h)
            local on = current == t.id
            draw.RoundedBox(4, 0, 0, w, h, on and TAB_ON or (self:IsHovered() and TAB_HOVER or TAB))
            if on then draw.RoundedBox(0, 0, h - 3, w, 3, t.color) end
            draw.SimpleText(string.upper(t.name), "DermaDefaultBold", w / 2, h / 2, on and t.color or DIM, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        b.DoClick = function()
            Select(t.id)
            if not filled[t.id] then Ask(t.id) end
        end
        local p = vgui.Create("DPanel", hub)
        p:Dock(FILL)
        p.Paint = function() end
        p:SetVisible(false)
        local wait = vgui.Create("DLabel", p)
        wait:Dock(TOP)
        wait:DockMargin(8, 8, 8, 8)
        wait:SetTextColor(DIM)
        wait:SetText("One moment...")
        pages[t.id] = p
    end
end

-- Open the window (on `tab`, or the one you looked at last), and ask for every tab afresh.
-- quiet: the server is already sending every tab (F4), so nothing needs asking for.
function LC_CL.OpenHub(tab, quiet)
    if not IsValid(hub) then Build() end
    Select(tab or last)
    if not quiet then for _, t in ipairs(TABS) do Ask(t.id) end end
    return hub
end

-- A tab's content from the server, built in place by build(panel). With the window shut, it opens on
-- that tab and asks for the other two.
function LC_CL.HubFill(id, build)
    if not IsValid(hub) then
        LC_CL.OpenHub(id, true)
        for _, t in ipairs(TABS) do if t.id ~= id then Ask(t.id) end end
    end
    local p = pages[id]
    if not IsValid(p) then return end
    p:Clear()
    filled[id] = true
    build(p)
end

function LC_CL.CloseHub()
    if IsValid(hub) then hub:Remove() end
    hub = nil
end
function LC_CL.HubOpen() return IsValid(hub) end
function LC_CL.HubTab() return IsValid(hub) and current or nil end
function LC_CL.HubLastTab() return last end

net.Receive("lc_hub", function() LC_CL.OpenHub(nil, true) LC_CL.HubFill("me", BuildMe) end)

------------------------------------------------------------------------
-- Me and settings (the owner, 19 November): what was only in the C menu. The C menu still has it all.
------------------------------------------------------------------------

local function Send(...) if LC_CL.SendAction then LC_CL.SendAction(...) end end
local function AskFor(...) if LC_CL.AskAction then LC_CL.AskAction(...) end end
local INK = Color(225, 220, 210)

BuildMe = function(p)
    local me = LocalPlayer()
    local scroll = vgui.Create("DScrollPanel", p)
    scroll:Dock(FILL)
    local function Head(text)
        local l = vgui.Create("DLabel", scroll)
        l:Dock(TOP)
        l:DockMargin(8, 10, 8, 2)
        l:SetFont("DermaDefaultBold")
        l:SetTextColor(INK)
        l:SetText(text)
    end
    -- close: the window it opens comes up in F4's place
    local function Btn(text, fn, close)
        local b = vgui.Create("DButton", scroll)
        b:Dock(TOP)
        b:DockMargin(8, 2, 8, 0)
        b:SetTall(26)
        b:SetText(text)
        b.DoClick = function()
            fn()
            if close then LC_CL.CloseHub()
            else timer.Simple(0.15, function() if IsValid(hub) and pages.me then LC_CL.HubFill("me", BuildMe) end end) end
        end
        return b
    end
    local function Toggle(cv, on, off)
        local c = GetConVar(cv)
        local isOn = c and c:GetBool()
        Btn(isOn and (on .. ": on (turn off)") or (on .. ": off (turn on)"), function() RunConsoleCommand(cv, isOn and "0" or "1") end)
    end

    Head("Me")
    Btn("Where I stand (every number explained)", function() if LC_CL.OpenStandingPanel then LC_CL.OpenStandingPanel() end end, true)
    Btn("My credits and standing", function() Send("credits") end, true)
    Btn("My characters (switch, or start someone new)", function() Send("characters") end, true)
    Btn("Change my name and face", function() Send("character") end, true)
    Btn("Change how strangers see me", function()
        AskFor("How strangers see you", "Describe yourself (8 to 120 characters), e.g. tall, grey coat, a scar over one eye", "chardesc", me:GetNW2String("lc_desc", ""))
    end, true)
    Btn("Holster or draw", function() Send("holster") end, true)
    if me:GetNW2String("lcf_faction", "") ~= "admin" then Btn("Run for City Administrator", function() Send("run") end, true) end
    Btn("I'm stuck", function() Send("stuck") end, true)

    Head("Help")
    Btn("The guide", function() if LC_OpenGuide then LC_OpenGuide(me:IsAdmin()) else RunConsoleCommand("lc_help") end end, true)
    Btn("Ask staff for help...", function() AskFor("Ask staff", "What's wrong? Staff see this as a ticket.", "ticket") end, true)
    Btn("Tips I've seen", function() net.Start("lc_hints_list") net.SendToServer() end, true)
    Btn("Tips: turn on", function() Send("hints", "on") end)
    Btn("Tips: turn off", function() Send("hints", "off") end)
    Btn("Tips: show them all again, from the start", function() Send("hints", "reset") end)

    Head("Settings")
    local bob = GetConVar("lc_my_view_bob")
    Btn((bob and bob:GetBool()) and "Camera sway: on (turn off)" or "Camera sway: off (turn on)", function() RunConsoleCommand("lc_bob_toggle") end)
    local wn = GetConVar("lc_whatnow_show")
    local wm = wn and wn:GetInt() or 1
    Btn(wm == 2 and "Next step on screen: always (change)" or (wm == 1 and "Next step on screen: new life and urgent (change)" or "Next step on screen: never (change)"),
        function() RunConsoleCommand("lc_whatnow_show", tostring((wm + 1) % 3)) end)
    Toggle("lc_context_show", "What you can do here (on the right)")
    Toggle("lc_trail_show", "Quest trail on the ground")
    local scr = GetConVar("lc_screen_ui")
    Btn((scr and scr:GetBool()) and "Terminals' menus: on their own screen (use a window)" or "Terminals' menus: in a window (use their own screen)",
        function() RunConsoleCommand("lc_screen_ui", (scr and scr:GetBool()) and "0" or "1") end)
    Toggle("lc_act_thirdperson", "Third person while posing")
    Toggle("lc_notices", "Warnings and notices on screen")
    Toggle("lc_body_signs", "Hunger, thirst and pain shown on screen and in sound")
end
LC_CL.HubBuildMe = function(p) return BuildMe(p) end
