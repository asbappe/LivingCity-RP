--[[
    Living City (client): the two news feeds (lc_newsfeed, sv_livingcity_chronicle.lua)

    The Civil Protection incident feed (a Combine monitor: what was formally
    reported, in Overwatch's words, five lines at a time, rolling) and the
    Resistance's notice board (what the cell's people saw, by hand). Both are
    drawn 640 x 360 around the centre of the face they are on.
]]

LC_CL = LC_CL or {}
LC_CL.Feeds = LC_CL.Feeds or { cp = {}, rebel = {} }

surface.CreateFont("LCFeedHead", { font = "Trebuchet MS", size = 26, weight = 900 })
surface.CreateFont("LCFeedLine", { font = "Trebuchet MS", size = 23, weight = 700 })
surface.CreateFont("LCFeedTime", { font = "Trebuchet MS", size = 19, weight = 700 })

local function ReadCompressed()
    local len = net.ReadUInt(32)
    local data = net.ReadData(len)
    local json = util.Decompress(data or "")
    return json and util.JSONToTable(json) or nil
end

net.Receive("lc_feeds", function()
    local t = ReadCompressed()
    if not t then return end
    LC_CL.Feeds = { cp = t.cp or {}, rebel = t.rebel or {}, at = CurTime() }
end)

local function Ago(item)
    local mins = (tonumber(item.mins) or 0) + math.floor((CurTime() - (LC_CL.Feeds.at or CurTime())) / 60)
    if mins < 60 then return "-" .. mins .. "m" end
    return "-" .. math.floor(mins / 60) .. "h"
end

local CY, RED, INK, PAPER = Color(92, 200, 216), Color(194, 59, 42), Color(24, 33, 44), Color(221, 214, 194)

local function DrawCP(list)
    surface.SetDrawColor(8, 12, 18, 250)
    surface.DrawRect(-320, -180, 640, 360)
    surface.SetDrawColor(CY.r, CY.g, CY.b, 255)
    surface.DrawRect(-320, -180, 640, 4)
    surface.DrawRect(-320, -134, 640, 2)
    draw.SimpleText("CIVIL PROTECTION: INCIDENT FEED", "LCFeedHead", -304, -158, CY, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    if #list == 0 then
        draw.SimpleText("NO INCIDENTS LOGGED. SECTOR STABLE.", "LCFeedLine", -304, -100, Color(150, 170, 180), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        return
    end
    local show = math.min(5, #list)
    local first = #list > 5 and (math.floor(CurTime() / 6) % #list) or 0
    for i = 0, show - 1 do
        local item = list[(first + i) % #list + 1]
        local y = -100 + i * 56
        draw.SimpleText(Ago(item), "LCFeedTime", -304, y, Color(120, 140, 150), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        draw.SimpleText(item.text or "", "LCFeedLine", -244, y, item.hot and RED or Color(226, 232, 236), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        if item.more and item.more ~= "" then draw.SimpleText(item.more, "LCFeedTime", -244, y + 22, Color(150, 170, 180), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER) end
    end
end

local function DrawRebel(list)
    surface.SetDrawColor(PAPER.r, PAPER.g, PAPER.b, 255)
    surface.DrawRect(-320, -180, 640, 360)
    draw.SimpleText("What we know", "LCRebelHead", -300, -150, INK, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    surface.SetDrawColor(RED.r, RED.g, RED.b, 255)
    surface.DrawRect(-300, -124, 240, 3)
    if #list == 0 then
        draw.SimpleText("Nothing new. Keep your eyes open.", "LCRebelBody", -300, -90, INK, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        return
    end
    local show = math.min(6, #list)
    local first = #list > 6 and (math.floor(CurTime() / 8) % #list) or 0
    for i = 0, show - 1 do
        local item = list[(first + i) % #list + 1]
        draw.SimpleText("- " .. (item.text or ""), "LCRebelBody", -300, -90 + i * 44, INK, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end
end

function LC_CL.DrawFeed(kind)
    if kind == "rebelboard" then DrawRebel(LC_CL.Feeds.rebel or {}) else DrawCP(LC_CL.Feeds.cp or {}) end
end
