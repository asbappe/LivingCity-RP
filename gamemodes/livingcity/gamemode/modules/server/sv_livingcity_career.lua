--[[
    Living City: your career, on one page (the owner's 7 November playtest: "playing as a
    metrocop, I have no idea what I'm working towards")

    The full menu (C) > "My career": your rank, the XP to the next one, every rank of your
    faction and what it takes, and for Civil Protection the way to the Overwatch: Division
    Leader first, then the Overwatch Candidate story on your board (F3), then the transhuman
    conditioning. Where that story stands for you is spelled out (waiting on a few more jobs,
    a failed part coming back, on your board now), and the Man Inside too, if it's yours: a
    failed part of a story always comes back to try again, and nothing you fail locks you out.

    Turned the conditioning down? An hour later you can ask Overwatch for a reassessment from
    this page: the Overwatch Candidate story comes back to your board from its first part.
    The client side is cl_livingcity_career.lua.
]]

if CLIENT then return end

LC = LC or {}

util.AddNetworkString("lc_career")
util.AddNetworkString("lc_career_ask")

local REASSESS_SECS = 3600 -- (after turning the conditioning down, how long before you can ask again)
LC.CareerReassessSecs = REASSESS_SECS

local function Fmt(n) return tostring(math.floor(n)) end

-- When a story ended (so a reassessment can wait its hour).
hook.Add("LivingCityStoryEnded", "LivingCityCareer", function(ply, chainId, ending)
    if not IsValid(ply) or chainId ~= "candidate" then return end
    local cs = LC.ChainState and LC.ChainState(ply, "candidate")
    if cs then
        cs.endedAt = os.time()
        if LC.SaveStory then LC.SaveStory(ply) end
    end
end)

-- Can this player ask for a reassessment now? true, or false and how many seconds to wait (or nil: not theirs to ask).
function LC.CanReassess(ply)
    if not IsValid(ply) or ply:GetNW2String("lcf_faction", "") ~= "cp" then return false end
    if LC.Conditioned and LC.Conditioned(ply) then return false end
    local cs = LC.Story and LC.Story(ply).chains.candidate
    if not cs or cs.done ~= "human" then return false end
    local wait = (cs.endedAt or 0) + REASSESS_SECS - os.time()
    if wait > 0 then return false, wait end
    return true
end

function LC.CareerReassess(ply)
    local ok, wait = LC.CanReassess(ply)
    if not ok then
        if wait and LC.Notice then
            LC.Notice(ply, "info", "Not yet", string.format("Overwatch will hear you out in about %d minutes.", math.ceil(wait / 60)), 6)
        end
        return false
    end
    local cs = LC.ChainState(ply, "candidate")
    cs.done, cs.part, cs.readyAt = nil, "evaluation", 0
    cs.reassessed = (cs.reassessed or 0) + 1
    LC.SaveStory(ply)
    if ply.lcStoryPostings then ply.lcStoryPostings.candidate = nil end
    ply:ChatPrint("[Story] Overwatch will look at you again. The Overwatch Candidate story is back on your board (F3), from the evaluation.")
    if LC.Notice then
        LC.Notice(ply, "info", "Reassessment granted", "The Overwatch Candidate story is back on your board (F3), from its first part. Pass it, and the conditioning is offered again.", 8)
    end
    LC.Log("info", "Career: " .. ply:Nick() .. " asked for an Overwatch reassessment")
    return true
end

-- Where the Overwatch Candidate story stands for this player, in a line.
local function CandidateLine(ply, idx, f)
    local s = LC.Story and LC.Story(ply)
    local cs = s and s.chains.candidate
    local chain = LC.Chains and LC.Chains.candidate
    local dvl = f.ranks[3] and f.ranks[3].name or "Division Leader"
    if idx < 3 then
        return string.format("At %s, the Overwatch Candidate story comes to your board (F3): an evaluation, then the transhuman conditioning.", dvl)
    end
    if cs and cs.done == "human" then
        local ok, wait = LC.CanReassess(ply)
        if ok then return "You turned the conditioning down. You can ask Overwatch for a reassessment now (the button below): the story comes back from its first part." end
        return string.format("You turned the conditioning down. In about %d minutes you can ask Overwatch for a reassessment here, and the story comes back from its first part.", math.ceil((wait or 0) / 60))
    end
    if cs and cs.part then
        local def = chain and chain.parts[cs.part]
        local num = def and def.num or 1
        local left = (cs.readyAt or 0) - os.time()
        if left > 0 then
            return string.format("The Overwatch Candidate, part %d, comes back to your board (F3) in about %d minutes. (A part that failed always comes back to try again.)", num, math.ceil(left / 60))
        end
        return string.format("The Overwatch Candidate, part %d, is on your board (F3) now. Pass it and the conditioning is offered.", num)
    end
    local open, need = true, 0
    if LC.StoryGateOpen then open, need = LC.StoryGateOpen(ply) end
    if not open then
        return string.format("Do %d more job%s from your board (F3), and the Overwatch Candidate story appears there.", need, need == 1 and "" or "s")
    end
    return "The Overwatch Candidate story is on your board (F3) now: an evaluation, then the conditioning."
end

-- Everything the page shows.
function LC.CareerInfo(ply)
    local f = LCF and LCF.ById and LCF.ById[ply:GetNW2String("lcf_faction", "")]
    if not f or #(f.ranks or {}) < 2 then return { none = true } end
    local xp = ply:GetNW2Int("lcf_xp", 0)
    local idx = math.Clamp(ply:GetNW2Int("lcf_rank", 1), 1, #f.ranks)
    local conditioned = LC.Conditioned and LC.Conditioned(ply) or false
    local t = { faction = f.name, xp = xp, rank = idx, ranks = {}, steps = {}, conditioned = conditioned }
    for i, r in ipairs(f.ranks) do
        t.ranks[i] = { name = r.name, xp = r.xp or 0, overwatch = r.overwatch == true }
    end
    local nextR = f.ranks[idx + 1]
    local function Step(s) t.steps[#t.steps + 1] = s end
    if f.id == "cp" then
        if nextR and not (nextR.overwatch and not conditioned) then
            Step(string.format("Earn %s more XP to make %s. Jobs from your board (F3), answering 10-20s and calls for backup, arrests, and shutting down Resistance labs all count.",
                Fmt(math.max(0, (nextR.xp or 0) - xp)), nextR.name))
        elseif not nextR then
            Step("You hold the top rank. The Overwatch Commander (one at a time, from the Elite) is taken from Factions (F4).")
        end
        if not conditioned then
            Step(CandidateLine(ply, idx, f))
            Step("Accept the conditioning and the Overwatch ranks open at once: Prison Guard, Soldier and Elite, by your XP (it all counts already). There's no going back from it.")
        end
        local inside = LC.Story and LC.Story(ply).chains.inside
        if inside and inside.done == "insider" then
            Step("You're also the Resistance's man inside. That doesn't stand in the way of promotion.")
        elseif inside and inside.part then
            Step("The Man Inside is still under way on your board (F3). However it goes, it doesn't stop you being promoted.")
        end
        Step("Nothing you fail locks you out: a story part that failed comes back to your board to try again.")
        t.canReassess, t.reassessIn = LC.CanReassess(ply)
    else
        if nextR then
            Step(string.format("Earn %s more XP to make %s: the jobs and stories on your board (F3) are the way.", Fmt(math.max(0, (nextR.xp or 0) - xp)), nextR.name))
        else
            Step("You hold the top rank.")
        end
    end
    return t
end

function LC.SendCareer(ply)
    if not IsValid(ply) or not LC.SendCompressed then return end
    LC.SendCompressed("lc_career", LC.CareerInfo(ply), { ply })
end

net.Receive("lc_career_ask", function(_, ply)
    if not IsValid(ply) then return end
    local what = net.ReadString()
    if (ply.lcCareerAsk or 0) > CurTime() then return end
    ply.lcCareerAsk = CurTime() + 0.5
    if what == "reassess" then LC.CareerReassess(ply) end
    LC.SendCareer(ply)
end)
