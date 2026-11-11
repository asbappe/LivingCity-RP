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
}
local DIM = Color(160, 156, 146)
local PANEL, TAB, TAB_ON, TAB_HOVER = Color(16, 15, 13, 245), Color(26, 26, 28, 250), Color(44, 42, 38, 250), Color(34, 33, 31, 250)

local hub, pages, filled = nil, {}, {}
local current
local last = "jobs" -- (the tab you looked at last, for this session)

-- ask the server for a tab's content
local function Ask(id)
    if id == "jobs" then RunConsoleCommand("lcq_board")
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

net.Receive("lc_hub", function() LC_CL.OpenHub(nil, true) end)
