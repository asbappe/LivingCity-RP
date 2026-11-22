--[[
    Living City (client): the Advisor screens (sv_livingcity_advisors.lua)

    Her menu: E on an Advisor screen, or F2 > City orders > The Advisors. Its title says how patient they
    are, in words; her report when one is due, and the three things she can ask for. And what the screen
    shows: dark, the Advisor's shape against a slow pulse, red and quicker while her report is due.
]]

LC_CL = LC_CL or {}

local TITLE = { patient = "THE ADVISORS ARE PATIENT", impatient = "THE ADVISORS ARE GROWING IMPATIENT", out = "THE ADVISORS ARE OUT OF PATIENCE" }
local PHRASE = { [0] = "all is calm", [1] = "there is unease", [2] = "there is unrest", [3] = "the city is in revolt" }

-- What the server says (nil: no Advisors in this city)
local function State()
    local t = util.JSONToTable(GetGlobal2String("lc_advisors", "") or "")
    return istable(t) and t.w and t or nil
end
LC_CL.AdvisorState = State

local function Do(what) return function() net.Start("lc_advisors_do") net.WriteString(what) net.SendToServer() end end

function LC_CL.AdvisorPage()
    local s = State()
    if not s then return nil end
    local items = {}
    if s.due then
        items[#items + 1] = { label = "Report to the Advisors", page = function()
            local lvl = math.Clamp(math.floor(tonumber(s.lvl) or 0), 0, 3)
            local its = { { label = "The truth: " .. PHRASE[lvl], run = Do("report" .. lvl) } }
            for c = lvl - 1, 0, -1 do its[#its + 1] = { label = "Lie: " .. PHRASE[c], run = Do("report" .. c) } end
            return { title = "YOUR REPORT", items = its }
        end }
    end
    items[#items + 1] = { label = "Ask for Overwatch troops" .. (s.drop and " (they are here)" or ""), run = Do("troops"), disabled = s.drop or nil }
    items[#items + 1] = { label = "Ask for a supply drop" .. (s.sup and " (one is coming)" or ""), run = Do("supply"), disabled = s.sup or nil }
    items[#items + 1] = { label = "Ask for more Civil Protection" .. (s.cops and " (sent)" or ""), run = Do("cops"), disabled = s.cops or nil }
    return { title = TITLE[s.w] or TITLE.patient, items = items }
end

-- F2 > City orders (cl_livingcity_quick.lua, OrdersPage)
LC_CL.CityOrderExtras = LC_CL.CityOrderExtras or {}
if not LC_CL.AdvisorOrderAdded then
    LC_CL.AdvisorOrderAdded = true
    table.insert(LC_CL.CityOrderExtras, function(me)
        if not IsValid(me) or me:GetNW2String("lcf_faction", "") ~= "admin" then return nil end
        local s = State()
        if not s then return nil end
        return { label = s.due and "The Advisors (report due)" or "The Advisors",
            page = function() return LC_CL.AdvisorPage() or { title = TITLE.patient, items = {} } end }
    end)
end

-- E on the screen
net.Receive("lc_advisors_open", function()
    local scr = net.ReadEntity()
    local page = LC_CL.AdvisorPage()
    if not page or not LC_CL.OpenSituation then return end
    page.id = "advisors"
    page.stay = function()
        local me = LocalPlayer()
        return IsValid(scr) and IsValid(me) and me:GetPos():DistToSqr(scr:GetPos()) < 250 * 250
    end
    LC_CL.OpenSituation(page)
end)

------------------------------------------------------------------------
-- The screen (entities/lc_advisorscreen.lua draws it on its glass, 640 by 360 about the middle)
------------------------------------------------------------------------

local function Ellipse(cx, cy, rx, ry, n)
    local pts = {}
    for i = 0, n - 1 do -- (clockwise on the screen, as surface.DrawPoly wants)
        local a = i / n * math.pi * 2
        pts[#pts + 1] = { x = cx + math.cos(a) * rx, y = cy + math.sin(a) * ry }
    end
    return pts
end
-- its long swollen head, leaning, and the body under it going off the bottom; the glow behind
local SHAPE = {
    halo = Ellipse(14, -36, 128, 150, 28),
    head = Ellipse(14, -40, 96, 122, 28),
    body = { { x = -58, y = 50 }, { x = 74, y = 50 }, { x = 132, y = 180 }, { x = -112, y = 180 } },
}

function LC_CL.DrawAdvisorScreen()
    local s = State()
    local due = s and s.due
    local t = CurTime()
    local pulse = (math.sin(t * (due and 4 or 1.5)) + 1) / 2
    local r, g, b = 150, 190, 230
    if due then r, g, b = 220, 60, 50 end
    draw.NoTexture()
    surface.SetDrawColor(4, 6, 10, 255)
    surface.DrawRect(-320, -180, 640, 360)
    surface.SetDrawColor(r, g, b, 25 + 70 * pulse)
    surface.DrawPoly(SHAPE.halo)
    surface.SetDrawColor(10, 13, 18, 255)
    surface.DrawPoly(SHAPE.head)
    surface.DrawPoly(SHAPE.body)
    -- (the picture's own scan line, crawling down)
    surface.SetDrawColor(r, g, b, 16)
    surface.DrawRect(-320, (t * 60) % 360 - 180, 640, 2)
end
