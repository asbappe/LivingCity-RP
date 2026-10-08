--[[
    Living City: on the screen, not just in chat

    Chat is busy, and the lines that matter get lost in it. These go on the
    screen as well (chat still keeps a copy, to scroll back through):

      Speech      someone talking to you: a rebel guarding the supplies, the
                  quartermaster, the scientist, an interrogator. A subtitle,
                  low in the middle of the screen.
      Warnings    Civil Protection, Overwatch, conduct strikes, custody, a
                  disguise slipping: a card at the top, edged in red.
      Notices     Civil Intake, Housing Allocation, your papers, rations, the
                  city: a card at the top, edged in blue.
      Events      what the city's loudspeakers just announced, and what it
                  means for you (sv_livingcity_events.lua).
      Waypoints   a marker on a place you asked the way to (the Civil
                  Protection Commissary, Housing Allocation, your block, the
                  lab). It's gone when you get there.

    A chat message to a player that starts with one of the tags below goes on
    screen by itself; LC.Notice puts anything else there. Each player can turn
    the cards off for themselves: the full menu's Settings (lc_notices 0).
]]

if CLIENT then return end

LC = LC or {}

util.AddNetworkString("lc_notice")
util.AddNetworkString("lc_waypoint")

-- [tag] = how it shows
local TAGS = {
    ["Rebel"] = "speech", ["Quartermaster"] = "speech", ["Interrogation"] = "speech", ["Scientist"] = "speech",
    ["Civil Protection"] = "warn", ["Overwatch"] = "warn", ["Conduct"] = "warn", ["Custody"] = "warn",
    ["Dispatch"] = "warn", ["Disguise"] = "warn", ["Search"] = "warn",
    ["Civil Intake"] = "info", ["Housing Allocation"] = "info", ["Papers"] = "info", ["Rations"] = "info",
    ["City"] = "info", ["Union"] = "info", ["CP Commissary"] = "info", ["Lab"] = "info",
}
LC.NoticeTags = TAGS

-- What a chat line shows on the screen: kind, title, text. Nil: chat only.
function LC.NoticeForChat(msg)
    local tag, rest = string.match(tostring(msg or ""), "^%[([^%]]+)%]%s*(.+)$")
    local kind = tag and TAGS[tag]
    if not kind then return nil end
    return kind, tag, rest
end

-- Sent a moment later, never in the middle of another net message being written.
local queue = {}

-- kind: "speech", "warn", "info" or "event". secs: how long (0: by length).
function LC.Notice(ply, kind, title, text, secs)
    if not IsValid(ply) or not ply:IsPlayer() then return end
    text = tostring(text or "")
    if text == "" then return end
    for _, q in ipairs(queue) do
        if q.ply == ply and q.title == title and q.text == text then return end -- (the same line, twice in a tick)
    end
    queue[#queue + 1] = { ply = ply, kind = kind or "info", title = tostring(title or ""), text = string.sub(text, 1, 400), secs = secs or 0 }
end

function LC.FlushNotices()
    if #queue == 0 then return end
    local q = queue
    queue = {}
    for _, n in ipairs(q) do
        if IsValid(n.ply) then
            net.Start("lc_notice")
            net.WriteString(n.kind)
            net.WriteString(n.title)
            net.WriteString(n.text)
            net.WriteFloat(n.secs)
            net.Send(n.ply)
        end
    end
end
timer.Create("LivingCityNotices", 0.1, 0, function() LC.FlushNotices() end)

-- Every tagged chat line to a player goes on the screen too.
local meta = FindMetaTable and FindMetaTable("Player")
if meta and meta.ChatPrint and not meta.lcNoticeBase then
    local base = meta.ChatPrint
    meta.lcNoticeBase = base
    meta.ChatPrint = function(self, msg)
        base(self, msg)
        local kind, title, text = LC.NoticeForChat(msg)
        if kind then LC.Notice(self, kind, title, text) end
    end
end

------------------------------------------------------------------------
-- Waypoints
------------------------------------------------------------------------

-- A marker on their screen at pos, until they're within `near` of it. No pos clears it.
function LC.SetWaypoint(ply, pos, label, near)
    if not IsValid(ply) then return end
    ply.lcWaypoint = pos and { pos = pos, label = label, near = near or 160 } or nil
    net.Start("lc_waypoint")
    net.WriteBool(pos ~= nil)
    net.WriteVector(pos or Vector(0, 0, 0))
    net.WriteString(label or "")
    net.WriteFloat(near or 160)
    net.Send(ply)
end

local function NearestEnt(pos, classes, test)
    local best, bd
    for _, cls in ipairs(classes) do
        for _, e in ipairs(LC.EntsOf and LC.EntsOf(cls) or {}) do
            if IsValid(e) and (not test or test(e)) then
                local d = e:GetPos():DistToSqr(pos)
                if not bd or d < bd then best, bd = e, d end
            end
        end
    end
    return best
end
LC.NearestEntOf = NearestEnt

-- The middle of a housing block (its zones, averaged).
function LC.BlockCenter(n)
    local sum, k = Vector(0, 0, 0), 0
    for _, z in ipairs(LC.ZonesOfKind and LC.ZonesOfKind("block") or {}) do
        if (z.group or 0) == n then
            local c = z.box and ((z.box.mins + z.box.maxs) * 0.5) or z.pos
            sum = sum + c
            k = k + 1
        end
    end
    return k > 0 and (sum / k) or nil
end

-- Where each kind of place is, for this person: pos, label (or nil and why not).
local PLACES = {
    cpsupply = function(ply)
        local e = NearestEnt(ply:GetPos(), { "lc_cpsupply" })
        if IsValid(e) then return e:GetPos(), "Civil Protection Commissary" end
        e = NearestEnt(ply:GetPos(), { "lc_terminal" })
        if IsValid(e) then return e:GetPos(), "Commissary (units are issued supplies here)" end
        return nil, "There's no Civil Protection Commissary in this city yet. Your grenades are topped up when you go on duty. (Staff: Living City Editor > Fixture: Civil Protection Commissary.)"
    end,
    intake = function(ply)
        local e = LC.NearestIntake and LC.NearestIntake(ply:GetPos(), "register")
        if IsValid(e) then return e:GetPos(), "Civil Intake" end
        return nil, "This city has no Civil Intake desk."
    end,
    housing = function(ply)
        local e = LC.NearestIntake and LC.NearestIntake(ply:GetPos(), "housing")
        if IsValid(e) then return e:GetPos(), "Housing Allocation" end
        return nil, "This city has no Housing Allocation desk."
    end,
    home = function(ply)
        local n = LC.PlayerBlock and LC.PlayerBlock(ply)
        local c = n and LC.BlockCenter(n)
        if c then return c, LC.BlockName(n) end
        return nil, n and "Your block isn't on the map." or "You have no room yet."
    end,
    lab = function(ply)
        local e = NearestEnt(ply:GetPos(), { "lc_workbench" })
        if IsValid(e) then return e:GetPos(), "The lab" end
        return nil, "No cell has a lab yet. (Staff: Living City Editor > Fixture: Resistance lab.)"
    end,
}
LC.WaypointPlaces = PLACES

-- Point them at a place by kind. True, or false and why not.
function LC.WaypointTo(ply, what)
    local find = PLACES[tostring(what or "")]
    if not IsValid(ply) or not find then return false end
    if what == "lab" and ply:GetNW2String("lcf_faction", "") ~= "resistance" then return false end
    local pos, label = find(ply)
    if not pos then
        if label then ply:ChatPrint("[Living City] " .. label) end
        return false, label
    end
    LC.SetWaypoint(ply, pos, label, what == "home" and 260 or 170)
    LC.Notice(ply, "info", "Waypoint", label .. ": it's marked on your screen.")
    return true
end
