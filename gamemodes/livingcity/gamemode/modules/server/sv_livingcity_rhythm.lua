--[[
    Living City: the city's day

    The city keeps to the clock (sv_livingcity_atmos.lua):

      05:00 to 07:00  morning      people come out and go to work
      07:00 to 12:00  the work day most of the city at its job
      12:00 to 14:00  midday       the ration lines fill up
      14:00 to 18:00  afternoon    back to work
      18:00 to 21:00  evening      work winds down; people sit, talk, wander
      21:00 to 05:00  night        most go home; the streets thin out, and
                                   only the night shift works (maintenance,
                                   radio repair, the mortuary, the clinic,
                                   sanitation)

    How many people are out is lc_citizens at its fullest; fewer in the
    morning and evening, and fewer still at night. lc_daily_rhythm 0 keeps
    the city the same all day.
]]

if CLIENT then return end

LC = LC or {}

local FLAGS = bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED)
local cvOn = CreateConVar("lc_daily_rhythm", "1", FLAGS, "The city keeps to the clock: work by day, rations at midday, quieter evenings, thin streets at night")
local cvNight = CreateConVar("lc_night_population", "40", FLAGS, "Percent of lc_citizens out on the streets at night")

local PHASES = {
    { id = "morning",   from = 5,  to = 7,  pop = 0.7,  work = 1.4 },
    { id = "work",      from = 7,  to = 12, pop = 1,    work = 1.15 },
    { id = "midday",    from = 12, to = 14, pop = 1,    work = 0.8 },
    { id = "afternoon", from = 14, to = 18, pop = 1,    work = 1.15 },
    { id = "evening",   from = 18, to = 21, pop = 0.85, work = 0.45 },
    { id = "night",     from = 21, to = 29, pop = nil,  work = 0 },
}
LC.RhythmPhases = PHASES

-- The ones who work through the night.
local NIGHT_JOBS = { maintenance = true, radio = true, mortuary = true, medic = true, sanitation = true }
LC.NightJobs = NIGHT_JOBS

local function On()
    if not cvOn:GetBool() or not LC.Hour then return false end
    local atm = GetConVar("lc_atmosphere")
    return not atm or atm:GetBool()
end

local function Phase()
    if not On() then return nil end
    local h = LC.Hour()
    if h < 5 then h = h + 24 end
    for _, p in ipairs(PHASES) do
        if h >= p.from and h < p.to then return p end
    end
    return PHASES[2]
end

function LC.RhythmPhase()
    local p = Phase()
    return p and p.id or nil
end

-- Share of lc_citizens out on the streets right now.
function LC.RhythmPopulation()
    local p = Phase()
    if not p then return 1 end
    return p.pop or math.Clamp(cvNight:GetFloat() / 100, 0, 1)
end

-- How likely an employed citizen is to pick work right now (times the usual).
function LC.RhythmWorkMul(job)
    local p = Phase()
    if not p then return 1 end
    if p.id == "night" then return NIGHT_JOBS[job] and 0.8 or 0 end
    return p.work
end

-- Too many people out for the hour: this one heads home (the night shift stays).
function LC.RhythmGoHome(npc, st, now)
    local p = Phase()
    if not p or st.questLock or st.test then return false end
    local job = st.profile and st.profile.job
    if p.id == "night" and NIGHT_JOBS[job] then return false end
    local out = LC.RoleCounts and LC.RoleCounts.citizen or 0
    if out <= (LC.CitizenTarget and LC.CitizenTarget() or 0) then return false end
    return math.random() < 0.5
end

-- Ration lines draw people at midday; evenings are for sitting about.
function LC.RhythmLineChance(base)
    local id = LC.RhythmPhase()
    if id == "midday" then return math.max(base, 0.4) end
    if id == "night" then return base * 0.3 end
    return base
end
function LC.RhythmSitChance(base)
    local id = LC.RhythmPhase()
    if id == "evening" then return 0.55 end
    return base
end
