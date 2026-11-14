--[[
    Living City: bug reports and feedback from players (the owner, 14 November: "add a bug report and
    feedback feature ... paste a debug report into the same destination file so we have context ...
    max of 1 per minute").

    F1 > Out of character > Report a bug or feedback: a line of text. Each one is saved on the server as
    garrysmod/data/livingcity/feedback/<date>_<time>_<steamid64>.txt: who sent it, where they stood,
    their words, and under them the debug report as it was at that moment. One a minute for each
    player (LC.FeedbackGap, kept by Steam ID, so rejoining doesn't get round it). Admins who are on
    are told one came in.

    What they wrote is never trusted (LC.FeedbackClean): it must be text, of a sane size; broken
    characters and control characters (line breaks too, so nothing can be made to look like part of
    the report under it) become spaces, runs of spaces become one, it is cut to LC.FeedbackMax letters
    and needs LC.FeedbackMin of them. The file's name is made only from the date and the Steam ID.
]]

if CLIENT then return end

LC = LC or {}
util.AddNetworkString("lc_feedback")

LC.FeedbackGap = 60     -- seconds between one player's reports
LC.FeedbackMax = 1000   -- letters kept of what they wrote
LC.FeedbackMin = 10     -- fewer than this says nothing
LC.FeedbackDir = "livingcity/feedback"
LC.FeedbackLast = LC.FeedbackLast or {} -- [steamid64] = when they last sent one

-- The debug report is heavy: many players reporting the same thing at once share one.
local REPORT_KEEP = 20
local cached, cachedAt

local function Report()
    local now = CurTime()
    if cached and cachedAt and now - cachedAt < REPORT_KEEP then return cached end
    local ok, text = LC.Try(LC.BuildReport)
    if not ok then text = "Report failed to build: " .. tostring(text) end
    cached, cachedAt = text, now
    return text
end

-- What a player typed, made safe to keep: one line of plain text, or nil when there's nothing in it.
function LC.FeedbackClean(text)
    if type(text) ~= "string" or #text > LC.FeedbackMax * 8 then return nil end
    if utf8 and utf8.force then text = utf8.force(text) end -- (broken characters out)
    text = string.gsub(text, "[%z\1-\31\127]", " ")           -- (control characters, line breaks and tabs)
    text = string.Trim(string.gsub(text, "%s+", " "))
    if #text > LC.FeedbackMax then
        text = string.sub(text, 1, LC.FeedbackMax)
        text = string.gsub(text, "[\192-\255][\128-\191]*$", "") -- (never half a letter at the cut)
    end
    local letters = select(2, string.gsub(text, "[%w\128-\255]", ""))
    if letters < LC.FeedbackMin then return nil end
    return text
end

-- Returns the file's name (under garrysmod/data/), or nil and why not.
function LC.Feedback(ply, text)
    if not IsValid(ply) or not ply:IsPlayer() then return nil, "nobody" end
    text = LC.FeedbackClean(text)
    if not text then return nil, "empty" end
    local id = string.gsub(tostring((ply.SteamID64 and ply:SteamID64()) or "0"), "%D", "")
    if id == "" then id = "0" end
    local now = CurTime()
    local last = LC.FeedbackLast[id]
    if last and now - last < LC.FeedbackGap then return nil, "wait", math.ceil(LC.FeedbackGap - (now - last)) end
    LC.FeedbackLast[id] = now

    local pos = ply:GetPos()
    local fac = ply:GetNW2String("lcf_faction", "?")
    local out = {
        "MISCOUNT PLAYER REPORT",
        string.format("%s | map %s | version %s", os.date("%Y-%m-%d %H:%M:%S"), game.GetMap(), tostring(LC.VERSION or "?")),
        string.format("from %s (%s) | faction %s", ply:Nick(), ply.SteamID and ply:SteamID() or id, tostring(fac)),
        string.format("at setpos %d %d %d", pos.x, pos.y, pos.z),
        "",
        "WHAT THEY WROTE",
        text,
        "",
        "----------------------------------------------------------------",
        Report(),
    }
    file.CreateDir(LC.FeedbackDir)
    local name = string.format("%s/%s_%s.txt", LC.FeedbackDir, os.date("%Y%m%d_%H%M%S"), id)
    file.Write(name, table.concat(out, "\n"))
    -- admins who are on hear of it (the owner, 14 November)
    local short = #text > 120 and (string.sub(text, 1, 117) .. "...") or text
    for _, a in ipairs(player.GetAll()) do
        if a ~= ply and a:IsAdmin() and LC.Notice then LC.Notice(a, "info", "Report from " .. ply:Nick(), short, 8) end
    end
    return name
end

net.Receive("lc_feedback", function(len, ply)
    if not IsValid(ply) then return end
    local now = CurTime()
    if (ply.lcFeedbackNet or 0) > now then return end -- (the message itself, never faster than one a second)
    ply.lcFeedbackNet = now + 1
    if (len or 0) > (LC.FeedbackMax * 4 + 16) * 8 then return end -- (far more than the box can send)
    local name, why, secs = LC.Feedback(ply, net.ReadString())
    if name then
        ply:ChatPrint("[Miscount] Sent. Thank you.")
    elseif why == "wait" then
        ply:ChatPrint(string.format("[Miscount] One report a minute: try again in %d seconds.", secs))
    elseif why == "empty" then
        ply:ChatPrint("[Miscount] Not sent: write a few words.")
    end
end)
