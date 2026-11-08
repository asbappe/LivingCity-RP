--[[
    Living City: which dream tonight (the rules, and the city's own pick)

    The owner, 8 November: "make it so the administrator (or NPC / automated
    administrator if no player) cannot select nightmares or propaganda only;
    preferably nightmares on bad sociostatus days, and a healthy mix of
    propaganda and neutral on other days, and happy dreams if no socio
    negative events happen".

    The day (from dawn to the dream) is watched:
      - how low sociostability fell (green, yellow or red);
      - anything bad: sociostability below green, a curfew, a sweep, a block
        raid, a lockdown, an outbreak, a rebel attack or a sweep of rebel
        ground.

    What tonight's dream may be, for the Administrator's pick and the city's:
      - a Nightmare only after a bad day: sociostability fell to
        lc_dream_bad_socio (red) at some point today;
      - a Happy dream (not a propaganda one) only after a clean day: nothing
        bad at all;
      - a propaganda dream any night, but never two nights running;
      - a Neutral dream any night.
    The tablet greys out what isn't allowed tonight, and says why. A pick made
    earlier in the day that's no longer allowed by dream time (a curfew came
    after she picked a Happy one) gives way to the city's own pick, and she's
    told.

    The city's own pick (lc_dream_auto 1): with nobody playing the
    Administrator, every night has a dream, chosen by the same rules: a
    Nightmare after a bad day, a Happy dream after a clean one, otherwise
    propaganda and Neutral by turns. (A player Administrator who chooses "No
    dream tonight" is obeyed.)

      lc_dream_rules 0/1 (1; 0: she picks anything, as before), lc_dream_auto 0/1 (1),
      lc_dream_bad_socio red/yellow (red)
]]

if CLIENT then return end

LC = LC or {}

local FLAGS = bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED)
local cvRules = CreateConVar("lc_dream_rules", "1", FLAGS, "Tonight's dream follows the day: Nightmares only after a bad day, Happy only after a clean one, no two propaganda nights running (0: the Administrator picks anything)")
local cvAuto = CreateConVar("lc_dream_auto", "1", FLAGS, "With nobody playing the Administrator, the city picks a dream every night itself, by the same rules as hers")
local cvBad  = CreateConVar("lc_dream_bad_socio", "red", FLAGS, "How low sociostability must fall during the day for a Nightmare that night (red or yellow)")

local D = LC.DreamRules or { worst = "green", events = {} }
LC.DreamRules = D

local RANK = { green = 0, yellow = 1, red = 2 }
local EVENT_NAMES = { curfew = "a curfew", sweep = "a contraband sweep", raid = "a block raid", lockdown = "a lockdown" }

local function Phase() return LC.DayPhase and LC.DayPhase() or "day" end
local function Note(why)
    for _, e in ipairs(D.events) do if e == why then return end end
    D.events[#D.events + 1] = why
end

-- A Nightmare, Happy, Neutral or propaganda dream.
function LC.DreamKind(id)
    if LC.PropagandaDreams and LC.PropagandaDreams[id] then return "propaganda" end
    return LC.DreamMood and LC.DreamMood(id) or "neutral"
end

-- The day so far: { bad, clean, worst, events }.
function LC.DreamDay()
    local need = RANK[string.lower(cvBad:GetString())] or 2
    return { bad = (RANK[D.worst] or 0) >= math.max(1, need), clean = #D.events == 0, worst = D.worst, events = D.events, last = D.lastKind }
end

-- May tonight's dream be this one? True, or false and why not.
function LC.DreamAllowed(id)
    if not cvRules:GetBool() then return true end
    local kind = LC.DreamKind(id)
    local day = LC.DreamDay()
    if kind == "nightmare" and not day.bad then
        return false, string.format("Nightmares are for bad days, and sociostability hasn't fallen to %s today.", string.lower(cvBad:GetString()))
    end
    if kind == "happy" and not day.clean then
        return false, "Happy dreams are a reward for a day with nothing wrong in it, and today had " .. tostring(day.events[1]) .. "."
    end
    if kind == "propaganda" and D.lastKind == "propaganda" then
        return false, "Not two propaganda dreams in a row: last night's was one."
    end
    return true
end

-- Today's state in a line, for the tablet.
function LC.DreamDayLine()
    if not cvRules:GetBool() then return nil end
    local day = LC.DreamDay()
    if day.bad then return "A bad day (sociostability fell to " .. day.worst .. "): a Nightmare is allowed tonight." end
    if day.clean then return "A clean day, nothing wrong in it: a Happy dream is allowed tonight." end
    return "An ordinary day (" .. tostring(day.events[1]) .. "): a Neutral or propaganda dream tonight."
end

-- Playable tonight: a dream you play, or an ending with a song to dream it to.
local function Playable(id)
    if LC.DreamGames and LC.DreamGames[id] then return true end
    return LC.Endings and LC.Endings[id] and #(LC.EndingSongs and LC.EndingSongs(id) or { 1 }) > 0
end
local function OfKind(kind)
    local out = {}
    for _, id in ipairs(LC.EndingOrder or {}) do if LC.DreamKind(id) == kind and Playable(id) then out[#out + 1] = id end end
    for _, id in ipairs(LC.DreamGameOrder or {}) do if LC.DreamKind(id) == kind and Playable(id) then out[#out + 1] = id end end
    return out
end
LC.DreamsOfKind = OfKind

-- The city's own pick, by the rules: a Nightmare after a bad day, a Happy dream after a clean one,
-- else propaganda and Neutral by turns. nil if there's nothing to dream.
function LC.DreamAutoPick()
    local day = LC.DreamDay()
    local order
    if day.bad then order = { "nightmare", "neutral" }
    elseif day.clean then order = { "happy", "neutral" }
    elseif D.lastKind == "propaganda" then order = { "neutral" }
    elseif D.lastKind == "neutral" then order = { "propaganda", "neutral" }
    else order = math.random() < 0.5 and { "propaganda", "neutral" } or { "neutral", "propaganda" } end
    for _, kind in ipairs(order) do
        local list = {}
        for _, id in ipairs(OfKind(kind)) do if LC.DreamAllowed(id) then list[#list + 1] = id end end
        if #list > 0 then return list[math.random(#list)] end
    end
    return nil
end

-- Does the city pick tonight (nobody plays the Administrator)?
function LC.DreamCityPicks()
    return cvAuto:GetBool() and not (LC.HumanAdministrator and LC.HumanAdministrator())
end

------------------------------------------------------------------------
-- Watching the day
------------------------------------------------------------------------

function LC.DreamDayReset()
    D.worst, D.events = LC.Socio or "green", {}
    if D.worst ~= "green" then Note("sociostability at " .. D.worst) end
end
hook.Add("LivingCityDayPhase", "LivingCityDreamRules", function(phase)
    if phase == "dawn" then LC.DreamDayReset() end
end)
hook.Add("LivingCitySocioChanged", "LivingCityDreamRules", function(level)
    if (RANK[level] or 0) > (RANK[D.worst] or 0) then D.worst = level end
    if level ~= "green" then Note("sociostability falling to " .. level) end
end)
hook.Add("LivingCityEventStarted", "LivingCityDreamRules", function(name)
    if EVENT_NAMES[name] then Note(EVENT_NAMES[name]) end
end)
hook.Add("LivingCityOutbreak", "LivingCityDreamRules", function() Note("an outbreak") end)
hook.Add("LivingCitySkirmish", "LivingCityDreamRules", function(kind)
    Note(kind == "raid" and "a rebel attack" or "a sweep of rebel ground")
end)
-- the night's dream, remembered (for "not two propaganda dreams in a row")
hook.Add("LivingCityDreamStarted", "LivingCityDreamRules", function(dream)
    local ph = Phase()
    if ph == "night" or ph == "dusk" then D.lastKind = LC.DreamKind(dream.ending) end
end)
