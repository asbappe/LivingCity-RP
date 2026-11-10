--[[
    Living City: learning the city by living in it

    The owner, 10 November: "integrate info to be more inferred and learned
    naturally through the environment and gamemode and city rather than just
    being told via text popups". The tip cards (sv_livingcity_hints.lua) stay
    as the fallback; this is what comes first:

      Cards wait until you seem stuck. A tip about something near you (a bin,
      a sink, the dealer), something in your pockets, or how you're doing
      (hungry, thirsty, hurt: your body shows it first, cl_livingcity_bodysigns.lua)
      doesn't show the first time. The clock starts, and the card comes only
      if you meet it again `lc_hints_wait` seconds (240) later and still
      haven't learned it. Things that happen to you (going down, wanted,
      custody, curfew) are never held back.

      Learning it any other way means no card: doing it (searching a bin,
      collecting a ration, fishing, picking a lock, getting a room), asking
      the Citizen Information clerk or the old-timer, reading the
      orientation pamphlet (LC.HintLearned).

      The PA's plain-words explanation ("  > what it means for you") comes
      the first `lc_pa_explain` times (3) each player hears each kind of
      announcement; after that, just what it said. Details that change
      (where, how long) always come.

      Old hands who help newcomers: someone new to the city (registered this
      session) gets a room, collects a first ration or finishes a first shift
      with someone nearby they know by name: that person earns
      `lc_mentor_xp` (25) XP, once per newcomer for each.
]]

if CLIENT then return end

LC = LC or {}

local FLAGS = bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED)
local cvWait = CreateConVar("lc_hints_wait", "240", FLAGS, "Seconds a tip about a place, an item or how you're doing waits for you to work it out before its card shows (0: cards straight away)")
local cvPA = CreateConVar("lc_pa_explain", "3", FLAGS, "How many times each player gets the PA's plain-words explanation of each kind of announcement (0: always)")
local cvMentor = CreateConVar("lc_mentor_xp", "25", FLAGS, "XP for being near a newcomer you've introduced yourself to as they get a room, a first ration or a first shift (0: off)")

------------------------------------------------------------------------
-- Cards wait until you seem stuck
------------------------------------------------------------------------

-- Tips that can wait: what's near you, what's in your pockets, how you're doing.
local WAITS = {}
for _, k in ipairs({
    "body", "bin", "locker", "apartment", "stall", "note", "lawboard", "water", "sink", "stove", "vending",
    "dispenser", "workbench", "transformer", "forcefield", "powerbank", "turret", "incinerator", "recycler",
    "console", "terminal", "cpsupply", "dealer", "cache", "pot", "tag", "quartermaster", "fighter",
    "citizen_npc", "cop_near", "stranger", "birds", "headcrab", "home_block", "dataterm", "masterterm",
    "hungry", "thirsty", "hurt", "parasites",
}) do WAITS[k] = true end
LC.HintWaits = WAITS

function LC.HintDeferSecs(ply, key, def)
    local w = cvWait:GetFloat()
    if w <= 0 or def.urgent then return nil end
    if WAITS[key] or string.sub(key, 1, 5) == "item_" then return w end
    return nil
end

local function Learn(ply, ...)
    if not LC.HintLearned then return end
    for _, k in ipairs({ ... }) do LC.HintLearned(ply, k) end
end
LC.Learn = Learn

-- Doing it is learning it.
hook.Add("LivingCityScavenged", "LivingCityLearning", function(ply) if IsValid(ply) and ply:IsPlayer() then Learn(ply, "bin") end end)
hook.Add("LivingCityRationCollected", "LivingCityLearning", function(ply) Learn(ply, "dispenser", "ration") end)
hook.Add("LivingCityFished", "LivingCityLearning", function(ply) if IsValid(ply) and ply:IsPlayer() then Learn(ply, "item_fishing", "water") end end)
hook.Add("LivingCityLockPicked", "LivingCityLearning", function(ply) if IsValid(ply) and ply:IsPlayer() then Learn(ply, "item_lockpick") end end)
hook.Add("LivingCityCrafted", "LivingCityLearning", function(ply) if IsValid(ply) and ply:IsPlayer() then Learn(ply, "workbench") end end)
hook.Add("LivingCityHoused", "LivingCityLearning", function(ply) if IsValid(ply) and ply:IsPlayer() then Learn(ply, "intake_housing") end end)

------------------------------------------------------------------------
-- The PA explains itself the first few times
------------------------------------------------------------------------

local function Heard(ply)
    if not ply.lcPAHeard then ply.lcPAHeard = util.JSONToTable(ply:GetPData("lc_pa_heard", "") or "") or {} end
    return ply.lcPAHeard
end

function LC.PAExplainDue(ply, kind)
    local n = cvPA:GetInt()
    if n <= 0 or not IsValid(ply) then return true end
    local h = Heard(ply)
    kind = tostring(kind or "")
    local had = tonumber(h[kind]) or 0
    if had >= n then return false end
    h[kind] = had + 1
    ply:SetPData("lc_pa_heard", util.TableToJSON(h))
    return true
end

------------------------------------------------------------------------
-- Old hands who help newcomers
------------------------------------------------------------------------

local NEWCOMER_SECS = 3 * 3600
local MENTOR_RANGE = 800

hook.Add("LivingCityRegistered", "LivingCityLearning", function(ply)
    if IsValid(ply) then ply.lcNewcomerUntil = CurTime() + NEWCOMER_SECS ply.lcMentored = {} end
end)

function LC.IsNewcomer(ply)
    return IsValid(ply) and (ply.lcNewcomerUntil or 0) > CurTime()
end

-- Anyone nearby the newcomer knows by name earns XP for this milestone (once each).
function LC.MentorCredit(ply, what, label)
    local xp = cvMentor:GetInt()
    if xp <= 0 or not LC.IsNewcomer(ply) or not LC.Recognizes then return 0 end
    ply.lcMentored = ply.lcMentored or {}
    if ply.lcMentored[what] then return 0 end
    ply.lcMentored[what] = true
    local paid = 0
    for _, vet in ipairs(player.GetAll()) do
        if vet ~= ply and vet:Alive() and not LC.IsNewcomer(vet) and vet:GetPos():DistToSqr(ply:GetPos()) < MENTOR_RANGE * MENTOR_RANGE
            and LC.Recognizes(ply, vet) then
            if LC.AddXP then LC.AddXP(vet, xp, "helped a newcomer") end
            if LC.Notice then LC.Notice(vet, "info", "Showing them the ropes", ply:GetNW2String("lc_char", "Someone new") .. " " .. label .. " with you there. (+" .. xp .. " XP)") end
            paid = paid + 1
        end
    end
    return paid
end

hook.Add("LivingCityHoused", "LivingCityMentor", function(ply) LC.MentorCredit(ply, "housed", "got a room") end)
hook.Add("LivingCityRationCollected", "LivingCityMentor", function(ply) LC.MentorCredit(ply, "ration", "collected a first ration") end)
hook.Add("LivingCityCounter", "LivingCityMentor", function(ply, counter)
    if counter == "shifts" then LC.MentorCredit(ply, "shift", "finished a first shift") end
end)

------------------------------------------------------------------------
-- Civil notice posters (entities/lc_civposter.lua): their words fit what's nearest
------------------------------------------------------------------------

LC.CivPosterTips = {
    dispenser = { "dispenser", "ration", "event_rations" }, commissary = { "terminal" },
    intake = { "intake_arrival", "item_papers" }, water = { "water", "sink", "parasites" },
    law = { "lawboard" }, curfew = { "curfew_warning", "running" },
}

function LC.CivPosterNotice(pos)
    local best, bd = "curfew", 700 * 700
    local function Try(kind, p)
        if not p then return end
        local d = p:DistToSqr(pos)
        if d < bd then best, bd = kind, d end
    end
    local function Class(cls, kind)
        for _, e in ipairs(LC.EntsOf and LC.EntsOf(cls) or ents.FindByClass(cls)) do if IsValid(e) then Try(kind, e:GetPos()) end end
    end
    Class("lc_dispenser", "dispenser")
    Class("lc_terminal", "commissary")
    Class("lc_intake", "intake")
    Class("lc_vending", "water")
    Class("lc_lawboard", "law")
    for _, fx in ipairs(LC.StaticFixtures or {}) do if fx.kind == "sink" then Try("water", fx.pos) end end
    return best
end

function LC.CivPosterRead(ply, kind)
    Learn(ply, unpack(LC.CivPosterTips[kind] or LC.CivPosterTips.curfew))
end

-- The owner's poster pictures, sent to players when the map starts (materials/livingcity/posters/)
local function SendPosterArt()
    if not (resource and resource.AddFile and file and file.Find) then return end
    for _, n in ipairs(file.Find("materials/livingcity/posters/*", "GAME") or {}) do
        local ext = string.lower(string.match(n, "%.(%w+)$") or "")
        if ext == "png" or ext == "jpg" then resource.AddFile("materials/livingcity/posters/" .. n) end
    end
end
hook.Add("Initialize", "LivingCityPosterArt", SendPosterArt)
