--[[
    Living City (client): what now?

    The next step the server worked out for you (sv_livingcity_nextstep.lua):
    a quiet line under the status box for a new life's first hour, or
    whenever it's urgent (hungry, thirsty, nowhere to live), and slot 1 of
    the F1 quick menu: the step and why, show me the way, and Places (every
    place worth knowing, with a waypoint).

    lc_whatnow_show: 1 new lives and urgent things (the default), 2 always,
    0 never (F1 still has it). C > Settings has it too.
]]

LC_CL = LC_CL or {}

local cvShow = CreateClientConVar("lc_whatnow_show", "1", true, false, "Your next step on screen: 0 never, 1 new life and urgent, 2 always")

local function Send(...) if LC_CL.SendAction then LC_CL.SendAction(...) end end

function LC_CL.NextStep()
    local me = LocalPlayer()
    if not IsValid(me) then return nil end
    local text = me:GetNW2String("lc_next", "")
    if text == "" then return nil end
    return { text = text, why = me:GetNW2String("lc_next_why", ""), way = me:GetNW2String("lc_next_way", ""),
        urgent = me:GetNW2Bool("lc_next_urgent", false), new = me:GetNW2Bool("lc_next_new", false) }
end

function LC_CL.ShowNextStep(mode)
    if mode == nil then mode = (cvShow:GetInt() == 2) and 1 or 2 end
    RunConsoleCommand("lc_whatnow_show", tostring(mode))
end

------------------------------------------------------------------------
-- On screen
------------------------------------------------------------------------

surface.CreateFont("LCNextStep", { font = "Tahoma", size = 15, weight = 700 })
surface.CreateFont("LCNextWhy", { font = "Tahoma", size = 13, weight = 400 })

local BG, INK, DIM = Color(10, 12, 16, 190), Color(235, 235, 225), Color(170, 175, 180)
local NEXT, URGENT = Color(150, 200, 255), Color(255, 175, 90)

local function Wrap(text, font, w)
    surface.SetFont(font)
    local lines, line = {}, ""
    for word in string.gmatch(text, "%S+") do
        local try = line == "" and word or (line .. " " .. word)
        if surface.GetTextSize(try) > w and line ~= "" then lines[#lines + 1] = line line = word else line = try end
    end
    if line ~= "" then lines[#lines + 1] = line end
    return lines
end

hook.Add("HUDPaint", "LivingCityNextStep", function()
    local me = LocalPlayer()
    if not IsValid(me) or not me:Alive() then return end
    local s = LC_CL.NextStep()
    if not s then return end
    local mode = cvShow:GetInt()
    if mode == 0 or (mode == 1 and not s.new and not s.urgent) then return end
    -- Civil Intake has its own line on screen while you're being processed
    if me:GetNW2Bool("lc_unreg", false) or me:GetNW2Bool("lc_unhoused", false) then return end
    local w = math.min(340, ScrW() - 32)
    local x, y = 16, (LC_CL.StatusBottom or 60) + 8
    local why = Wrap(s.why, "LCNextWhy", w - 16)
    local h = 26 + #why * 15 + (s.way ~= "" and 15 or 0)
    draw.RoundedBox(4, x, y, w, h, BG)
    draw.RoundedBox(0, x, y, 3, h, s.urgent and URGENT or NEXT)
    draw.SimpleText(string.upper(s.text), "LCNextStep", x + 10, y + 5, s.urgent and URGENT or INK)
    for i, l in ipairs(why) do draw.SimpleText(l, "LCNextWhy", x + 10, y + 7 + i * 15, DIM) end
    if s.way ~= "" then
        draw.SimpleText("F1 > 1 shows you the way", "LCNextWhy", x + 10, y + 7 + (#why + 1) * 15, NEXT)
    end
end)

------------------------------------------------------------------------
-- F1, slot 1
------------------------------------------------------------------------

local function Item(label, run) return { label = label, run = run } end
local function Page(label, build) return { label = label, page = build } end

local PLACES = {
    { "dispenser", "Ration dispenser" }, { "water", "Water (a sink or a machine)" }, { "bin", "Bins to search" },
    { "home", "My block" }, { "work", "My workplace" }, { "shop", "The Commissary" },
    { "intake", "Civil Intake" }, { "housing", "Housing Allocation" },
}

function LC_CL.PlacesPage()
    local me = LocalPlayer()
    local f = IsValid(me) and me:GetNW2String("lcf_faction", "") or ""
    local items = {}
    for _, p in ipairs(PLACES) do
        items[#items + 1] = Item(p[2], function() Send("waypoint", p[1]) end)
    end
    if f == "cp" or f == "ota" then items[#items + 1] = Item("Civil Protection Commissary", function() Send("waypoint", "cpsupply") end) end
    if f == "resistance" then items[#items + 1] = Item("The lab", function() Send("waypoint", "lab") end) end
    while #items > 9 do table.remove(items) end
    return { title = "PLACES", items = items }
end

function LC_CL.WhatNowPage()
    local s = LC_CL.NextStep()
    local items = {}
    if s then
        items[#items + 1] = Item((s.way ~= "" and "Show me the way: " or "") .. s.text, function()
            if s.way ~= "" then Send("waypoint", s.way) end
            if LC_CL.AddNotice then LC_CL.AddNotice(s.urgent and "warn" or "info", s.text, s.why) end
        end)
    else
        items[#items + 1] = Item("Nothing pressing", function() end)
    end
    items[#items + 1] = Page("Places in the city", LC_CL.PlacesPage)
    local mode = cvShow:GetInt()
    items[#items + 1] = Item(mode == 2 and "Keep it on screen: always (change)" or (mode == 1 and "Keep it on screen: new life and urgent (change)" or "Keep it on screen: never (change)"),
        function() RunConsoleCommand("lc_whatnow_show", tostring((mode + 1) % 3)) end)
    return { title = "WHAT NOW?", items = items }
end
