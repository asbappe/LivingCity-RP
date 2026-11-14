--[[
    Living City: bug reports and feedback from players (the owner, 14 November: "add a bug report and
    feedback feature ... paste a debug report into the same destination file so we have context ...
    max of 1 per minute").

    F1 > Out of character > Report a bug or feedback: a line of text. Each one is saved on the server as
    garrysmod/data/livingcity/feedback/<date>_<time>_<steamid64>.txt: who sent it, where they stood,
    their words, and under them the debug report as it was at that moment. One a minute for each
    player (LC.FeedbackGap, kept by Steam ID, so rejoining doesn't get round it).
]]

if CLIENT then return end

LC = LC or {}
util.AddNetworkString("lc_feedback")

LC.FeedbackGap = 60     -- seconds between one player's reports
LC.FeedbackMax = 1000   -- letters kept of what they wrote
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

-- Returns the file's name (under garrysmod/data/), or nil and why not.
function LC.Feedback(ply, text)
    if not IsValid(ply) or not ply:IsPlayer() then return nil, "nobody" end
    text = string.Trim(string.sub(tostring(text or ""), 1, LC.FeedbackMax))
    if text == "" then return nil, "empty" end
    local id = (ply.SteamID64 and ply:SteamID64()) or "0"
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
    return name
end

net.Receive("lc_feedback", function(_, ply)
    local name, why, secs = LC.Feedback(ply, net.ReadString())
    if name then
        ply:ChatPrint("[Miscount] Sent. Thank you.")
    elseif why == "wait" then
        ply:ChatPrint(string.format("[Miscount] One report a minute: try again in %d seconds.", secs))
    end
end)
