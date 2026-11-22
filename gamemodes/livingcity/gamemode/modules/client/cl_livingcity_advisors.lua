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

-- The real Advisor on the glass (the owner, 22 November: "yes please" to the Advisor itself rather than an outline):
-- Episode Two's models/advisor.mdl, moving, drawn on its own into a picture (no hidden room, no camera entity: only the
-- model is drawn, lit in the screen's colour), a few times a second while a screen is in view. With no such model, or
-- no way to draw a picture, the outline above stands in.
local ADVISOR = "models/advisor.mdl"
local FEED_W, FEED_H, FEED_FPS = 512, 288, 20
local feed = { wanted = 0, nextAt = 0 }
function LC_CL.AdvisorFeedReset()
    if IsValid(feed.mdl) then feed.mdl:Remove() end
    feed = { wanted = 0, nextAt = 0 }
end

local function FeedReady()
    if feed.failed then return false end
    if feed.mat and IsValid(feed.mdl) then return true end
    if not (GetRenderTarget and CreateMaterial and ClientsideModel and render and render.PushRenderTarget and cam and cam.Start3D) then
        feed.failed = true
        return false
    end
    if util and util.IsValidModel and not util.IsValidModel(ADVISOR) then feed.failed = true return false end
    local ok = LC.Try(function()
        feed.rt = GetRenderTarget("lc_advisor_feed", FEED_W, FEED_H)
        feed.mat = CreateMaterial("lc_advisor_feed_mat", "UnlitGeneric", { ["$basetexture"] = feed.rt:GetName(), ["$model"] = "0" })
        local m = ClientsideModel(ADVISOR, RENDERGROUP_OPAQUE)
        if not IsValid(m) then return end
        m:SetNoDraw(true)
        m:SetPos(Vector(0, 0, 0))
        m:SetAngles(Angle(0, 0, 0))
        local seq = m:LookupSequence("idle")
        if not seq or seq < 0 then seq = 0 end
        m:ResetSequence(seq)
        feed.seq, feed.dur = seq, math.max(1, m:SequenceDuration(seq) or 4)
        -- what to look at: its head, if a bone says so; else high on its body
        local mins, maxs = m:GetModelBounds()
        local look = Vector((mins.x + maxs.x) / 2, (mins.y + maxs.y) / 2, mins.z + (maxs.z - mins.z) * 0.7)
        if m.SetupBones then m:SetupBones() end
        for i = 0, (m:GetBoneCount() or 0) - 1 do
            local name = string.lower(m:GetBoneName(i) or "")
            if string.find(name, "head", 1, true) then
                local bp = m:GetBonePosition(i)
                if bp then look = bp end
                break
            end
        end
        feed.look, feed.size = look, math.max(64, (maxs - mins):Length())
        feed.mdl = m
    end)
    if not ok or not IsValid(feed.mdl) then feed.failed = true return false end
    return true
end

-- One picture, into the texture: before the scene is drawn, never inside another picture, only while a screen was
-- drawn a moment ago.
function LC_CL.AdvisorFeed()
    local now = CurTime()
    if now - feed.wanted > 0.5 or now < feed.nextAt or LC_CL.LiveCamRendering then return false end
    if not FeedReady() then return false end
    feed.nextAt = now + 1 / FEED_FPS
    local m = feed.mdl
    m:SetCycle((now % feed.dur) / feed.dur)
    -- a slow drift, as a feed's camera hangs: from in front of it and a little above, the head filling the picture
    local d = feed.size * 0.45
    local sway = math.sin(now * 0.2) * 12
    local at = feed.look + Angle(0, sway, 0):Forward() * d + Vector(0, 0, d * 0.12)
    local r, g, b, pulse = feed.r or 150, feed.g or 190, feed.b or 230, feed.pulse or 0.5
    local pushed = false
    local ok = LC.Try(function()
        render.PushRenderTarget(feed.rt)
        pushed = true
        render.Clear(4, 6, 10, 255, true, true)
        cam.Start3D(at, (feed.look - at):Angle(), 42, 0, 0, FEED_W, FEED_H)
            render.SuppressEngineLighting(true)
            local k = 0.35 + 0.65 * pulse
            render.ResetModelLighting(0.03, 0.035, 0.05)
            if BOX_FRONT then
                render.SetModelLighting(BOX_FRONT, r / 255 * k, g / 255 * k, b / 255 * k)
                render.SetModelLighting(BOX_TOP, r / 255 * 0.5 * k, g / 255 * 0.5 * k, b / 255 * 0.5 * k)
            end
            m:DrawModel()
            render.SuppressEngineLighting(false)
        cam.End3D()
        render.PopRenderTarget()
        pushed = false
    end)
    if pushed then render.PopRenderTarget() end -- (an error mid-picture mustn't leave the game drawing into the texture)
    if not ok then feed.failed = true return false end
    feed.drawn = true
    return true
end
hook.Add("RenderScene", "LivingCityAdvisorFeed", function() LC_CL.AdvisorFeed() end)

function LC_CL.DrawAdvisorScreen()
    local s = State()
    local due = s and s.due
    local t = CurTime()
    local pulse = (math.sin(t * (due and 4 or 1.5)) + 1) / 2
    local r, g, b = 150, 190, 230
    if due then r, g, b = 220, 60, 50 end
    feed.wanted, feed.r, feed.g, feed.b, feed.pulse = t, r, g, b, pulse
    if feed.drawn and not feed.failed and feed.mat then
        -- the Advisor itself, and a wash of the screen's colour over it
        surface.SetMaterial(feed.mat)
        surface.SetDrawColor(255, 255, 255, 255)
        surface.DrawTexturedRect(-320, -180, 640, 360)
        draw.NoTexture()
        surface.SetDrawColor(r, g, b, 10 + 18 * pulse)
        surface.DrawRect(-320, -180, 640, 360)
    else
        draw.NoTexture()
        surface.SetDrawColor(4, 6, 10, 255)
        surface.DrawRect(-320, -180, 640, 360)
        surface.SetDrawColor(r, g, b, 25 + 70 * pulse)
        surface.DrawPoly(SHAPE.halo)
        surface.SetDrawColor(10, 13, 18, 255)
        surface.DrawPoly(SHAPE.head)
        surface.DrawPoly(SHAPE.body)
    end
    -- (the picture's own scan line, crawling down)
    surface.SetDrawColor(r, g, b, 16)
    surface.DrawRect(-320, (t * 60) % 360 - 180, 640, 2)
end
