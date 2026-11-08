--[[
    Living City: bedtime, the night shift, missed dreams, and the chip

    The owner, 8 November: "citizens get sleepy around the same time every
    night before the dreams start so that they all go to bed and dream at the
    same time", "human player metrocops should definitely need to sleep like
    citizens, UNLESS they take a 'night shift' quest that is available for
    them most nights ... and give a free stimulant shot if they visit a CP
    commissary", "we don't want all rebels to purposely sleep only during the
    day to avoid the dreams altogether", "the lab can make some sort of tin
    foil hat or maybe they can surgically remove the chip", "if rebels get the
    chip pulled, and if they can't dream, then they shouldn't have to sleep
    with a black screen ... they can just sleep for 90 seconds instead".

    Bedtime (lc_bedtime 1). The chip pulls citizens and Civil Protection to
    bed: whatever they slept in the day, they're due for bed at the good
    night (21:00, the Administrator's "night" announcement), warned at the
    usual six and two real minutes before ("Lights out soon"). Past it, out
    of bed, they're tired (eyes closing, no running, weaker) until they
    sleep. Anyone who has slept since dusk (19:00) is not pulled again that
    night. The Resistance keep their own hours. The Administration doesn't
    get tired at all, as before (and can still go to bed at night).

    The night shift (Civil Protection, Overwatch). Most nights
    (lc_nightshift_chance, 0.85) a "Night shift" directive goes up on their
    board (F4) from dusk: walk the patrol stops through the night. While on
    it (or once it's done) that night, no lights out for them, and a CP
    Commissary issues them one free stimulant shot (once a night). The
    city's own units patrol whether or not anyone takes it.

    A dream you missed waits (lc_dream_catchup 1). Anyone with the chip
    (citizens and the Resistance; not Civil Protection or the Administration)
    who was awake when tonight's dream ran has it waiting behind their eyes:
    the next time they sleep, they dream it alone (with stand-ins), before the
    next dream night. Sleeping in the day doesn't get out of it. The ways out:
    stay awake on stimulant shots without a break from the dream until dawn
    (about two shots: then it fades at dawn), wear a foil hat to bed, or have
    the chip pulled. Opting out of Happy and Neutral dreams still works.

    The foil hat (the lab; contraband). Put it on (F3) and sleep in it: no
    dream reaches you (tonight's or one waiting), and the hat's spent once
    it has kept one out. It lasts one in-game day if it isn't needed.

    The chip (the lab: "Pull the chip"). Pulling it takes special one-time
    tools and the codes to shut it down safely: lc_chip_price (500) credits,
    thirty seconds under. Only once you've lived through lc_chip_dreams (3)
    of the city's dreams (they have to be endured at first): the foil hat
    needs the same. With no chip: no dreams at all, ever; sleep takes at most
    lc_chipless_sleep (90) seconds and you get up on your own; but a unit who
    checks your papers or searches you notices there's no implant signal one
    time in lc_chip_notice (0.15): a crime, and you're marked.

      lc_bedtime 0/1, lc_nightshift_chance (0.85), lc_dream_catchup 0/1,
      lc_chip_price (500), lc_chip_dreams (3), lc_chipless_sleep (90),
      lc_chip_notice (0.15)
]]

if CLIENT then return end

LC = LC or {}

local FLAGS = bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED)
local cvBed     = CreateConVar("lc_bedtime", "1", FLAGS, "Citizens and Civil Protection are due in bed at the good night (21:00), whatever they slept in the day (a night shift excuses a unit)")
local cvShift   = CreateConVar("lc_nightshift_chance", "0.85", FLAGS, "Chance each night that Civil Protection's board has a night shift (no lights out, a free stimulant at a CP Commissary)")
local cvCatch   = CreateConVar("lc_dream_catchup", "1", FLAGS, "Someone with the chip who was awake for tonight's dream dreams it alone the next time they sleep (unless kept awake on stimulants till dawn)")
local cvPrice   = CreateConVar("lc_chip_price", "500", FLAGS, "Credits to have the chip pulled at the Resistance lab (the one-time tools and codes; 0: not offered)")
local cvNeed    = CreateConVar("lc_chip_dreams", "3", FLAGS, "Dreams someone must have lived through before the lab will pull their chip or make them a foil hat")
local cvSleep   = CreateConVar("lc_chipless_sleep", "90", FLAGS, "Most seconds a night's sleep takes with no chip (no dream to wait for: they get up on their own)")
local cvNotice  = CreateConVar("lc_chip_notice", "0.15", FLAGS, "Chance a unit checking papers or searching someone notices there's no implant signal")

local S = LC.BedtimeState or { eve = 0, roll = {}, missed = {} }
LC.BedtimeState = S

local function Notice(p, kind, title, text, secs) if LC.Notice then LC.Notice(p, kind, title, text, secs) elseif p.ChatPrint then p:ChatPrint(title .. ": " .. text) end end
local function DayLen() return math.max(60, GetGlobal2Float("lc_day_len", 1440)) end
local function Faction(p) return p:GetNW2String("lcf_faction", "") end
local function Sid(p) return p.SteamID64 and p:SteamID64() or tostring(p) end
local function Phase() return LC.DayPhase and LC.DayPhase() or "day" end
local function BySid(sid) for _, p in ipairs(player.GetAll()) do if Sid(p) == sid then return p end end return nil end

------------------------------------------------------------------------
-- The chip
------------------------------------------------------------------------

function LC.Chipless(p) return IsValid(p) and p.GetPData and p:GetPData("lc_chipless", "0") == "1" end
-- The chip the Combine put in them, still there: citizens and the Resistance.
function LC.Chipped(p)
    if not IsValid(p) then return false end
    local f = Faction(p)
    return (f == "citizen" or f == "resistance") and not LC.Chipless(p)
end
function LC.DreamsEndured(p) return IsValid(p) and tonumber(p:GetPData("lc_dreams_endured", "0")) or 0 end
-- Lived through enough dreams for the lab to help them out of the rest. True, or false and why not.
function LC.DreamOptOutEarned(p)
    local need, have = math.max(0, cvNeed:GetInt()), LC.DreamsEndured(p)
    if have >= need then return true end
    return false, string.format("\"Not yet. You've only lived through %d of the city's dreams. Endure %d more, and come back. I need to see how it takes you first.\"", have, need - have)
end
-- One more dream lived through (not as an Enforcer: they're not dreaming it).
hook.Add("LivingCityDreamWoke", "LivingCityBedtime", function(p)
    if not IsValid(p) or p.lcDreamWokeEnforcer then return end
    local f = Faction(p)
    if f ~= "citizen" and f ~= "resistance" then return end
    p:SetPData("lc_dreams_endured", tostring(LC.DreamsEndured(p) + 1))
end)
-- A new person: a new chip, and no dreams lived through yet.
hook.Add("LivingCityNewCharacter", "LivingCityBedtime", function(p)
    p:SetPData("lc_chipless", "0")
    p:SetPData("lc_dreams_endured", "0")
    p.lcFoilUntil = nil
    p:SetNW2Bool("lc_chipless", false)
end)
hook.Add("PlayerSpawn", "LivingCityBedtime", function(p) p:SetNW2Bool("lc_chipless", LC.Chipless(p)) end)

-- No implant signal: a unit notices, now and then (once a stop: the papers and the search don't both roll).
function LC.ImplantNoticed(p)
    if not LC.Chipless(p) then return false end
    local now = CurTime()
    if (p.lcImplantRolled or -100) > now - 8 then return false end
    p.lcImplantRolled = now
    return math.random() < math.max(0, cvNotice:GetFloat())
end
LC.NoImplantText = "The unit's scanner finds no implant signal: your chip has been pulled. Only anticitizens do that."
hook.Add("LivingCitySearched", "LivingCityBedtime", function(searcher, target)
    if not IsValid(target) or not target:IsPlayer() or not LC.ImplantNoticed(target) then return end
    target:ChatPrint("[Civil Protection] " .. LC.NoImplantText)
    if IsValid(searcher) and searcher:IsPlayer() then
        searcher:ChatPrint("[Search] No implant signal: " .. target:Nick() .. "'s chip has been pulled. That's an anticitizen.")
    end
    if LC.ReportCrime then LC.ReportCrime(target, "No implant signal (chip removed)", 300) end
    hook.Run("LivingCityNoImplant", target, searcher)
end)

------------------------------------------------------------------------
-- The foil hat
------------------------------------------------------------------------

function LC.FoilOn(p) return IsValid(p) and (p.lcFoilUntil or 0) > CurTime() end
function LC.FoilHatUse(p, id)
    if LC.Chipless(p) then return false, "There's no chip in your head left for it to block." end
    if LC.FoilOn(p) then return false, "You've one on already." end
    if not LC.TakeItem(p, id or "foil_hat") then return false end
    p.lcFoilUntil = CurTime() + DayLen()
    p:EmitSound("physics/metal/metal_box_scrape_rough_loop1.wav", 50, 160)
    Notice(p, "info", "Foil hat on", "It crinkles as you pull it down. Sleep in it and no dream can reach you (tonight's, or one waiting for you); it's spent once it has kept one out. "
        .. "It's contraband: don't let a unit see you in it.", 9)
    return true
end
-- Kept out of every dream: no chip, or a foil hat on (sv_livingcity_dreams.lua asks).
function LC.DreamProof(p) return LC.Chipless(p) or LC.FoilOn(p) end
local function FoilSpent(p)
    p.lcFoilUntil = nil
    Notice(p, "info", "The foil hat", "Something presses at the edge of your sleep, and the foil hat crackles. It slips past you. The hat's spent.", 8)
end

------------------------------------------------------------------------
-- Bedtime
------------------------------------------------------------------------

-- Is the night shift theirs tonight (on it, or done with it)?
function LC.OnNightShift(p)
    if not IsValid(p) then return false end
    local ph = Phase()
    if ph ~= "dusk" and ph ~= "night" then return false end
    local q = LC.QuestOf and LC.QuestOf[p]
    if q and q.tmpl and q.tmpl.id == "cp_nightshift" and p.lcNightShift == S.eve then return true end
    return p.lcNightShiftDone == S.eve
end

-- Does the chip's bedtime pull them?
function LC.BedtimeFor(p)
    if not cvBed:GetBool() or not IsValid(p) then return false end
    local f = Faction(p)
    if f == "citizen" then return true end
    if f == "cp" then return not LC.OnNightShift(p) end
    return false
end

-- When they're due in bed (CurTime), or nil: the good night (21:00), unless they've slept since dusk.
-- (sv_livingcity_rest.lua takes the sooner of this and their usual time.)
function LC.BedtimeDue(p)
    if not LC.BedtimeFor(p) then return nil end
    local len, now = DayLen(), CurTime()
    local h = ((now - GetGlobal2Float("lc_day_zero", 0)) / len * 24) % 24
    local bed = now - h / 24 * len + 21 / 24 * len -- (today's 21:00)
    if h < 5 then bed = bed - len end -- (after midnight: last night's)
    if (p.lcAwakeSince or now) >= bed - 2 / 24 * len then bed = bed + len end -- (slept since dusk: tomorrow night's)
    return bed
end
function LC.IsBedtimeDue(p, due)
    local b = LC.BedtimeDue(p)
    return b ~= nil and due ~= nil and math.abs(b - due) < 1
end

------------------------------------------------------------------------
-- The night shift
------------------------------------------------------------------------

hook.Add("LivingCityDayPhase", "LivingCityBedtime", function(phase)
    if phase == "dusk" then S.eve = (S.eve or 0) + 1 end
    if phase == "dawn" then
        -- kept awake on stimulants all night: what they missed fades
        for sid, m in pairs(S.missed) do
            local p = BySid(sid)
            if m.wired and IsValid(p) and LC.Wired and LC.Wired(p) then
                S.missed[sid] = nil
                Notice(p, "info", "Morning", "You kept yourself awake all night. Whatever the city dreamt has slipped past you.", 8)
            end
        end
    end
end)
function LC.NightShiftTonight()
    local n = S.eve or 0
    if S.roll[n] == nil then S.roll[n] = math.random() < math.Clamp(cvShift:GetFloat(), 0, 1) end
    return S.roll[n]
end

-- One free stimulant shot at a CP Commissary, once a night on the night shift (sv_livingcity_cpsupply.lua).
function LC.NightShiftIssue(p)
    if not LC.OnNightShift(p) or p.lcShiftStim == S.eve or not LC.GiveItem then return false end
    if not LC.GiveItem(p, "stimulant", 1) then return false end
    p.lcShiftStim = S.eve
    p:ChatPrint("[CP Commissary] Night shift: one stimulant shot, issued. It keeps you sharp for fifteen minutes. Then the crash.")
    return true
end

local function NightLeft()
    local len = DayLen()
    local h = LC.Hour and LC.Hour() or 21
    local to5 = (5 - h) % 24
    return to5 / 24 * len
end

local function AddTemplate()
    if not LC.QuestTemplates or not LC.QB or S.template then return end
    S.template = true
    local QB = LC.QB
    LC.QuestTemplates[#LC.QuestTemplates + 1] = {
        id = "cp_nightshift", factions = { cp = true, ota = true }, first = true,
        available = function(p)
            local ph = Phase()
            return cvBed:GetBool() and (ph == "dusk" or ph == "night") and LC.NightShiftTonight() and p.lcNightShift ~= S.eve and p.lcNightShiftDone ~= S.eve
        end,
        build = function(p)
            local stops = {}
            local beats = {}
            for _, pt in ipairs(LC.PointsOfKind and LC.PointsOfKind("patrol") or {}) do if (pt.group or 0) > 0 then beats[pt.group] = true end end
            local groups = table.GetKeys(beats)
            if #groups > 0 then
                for _, pt in ipairs(LC.PointsOfKind("patrol", groups[math.random(#groups)])) do if #stops < 6 then stops[#stops + 1] = pt.pos end end
            end
            if #stops < 4 and QB.Route then stops = QB.Route(p, 6, 400, 1100) end
            if not stops or #stops < 2 then return nil end
            local stages = {}
            for i, s in ipairs(stops) do
                stages[i] = QB.Goto(s, string.format("Night shift: walk to patrol stop %d of %d, %s", i, #stops, QB.Place and QB.Place(s, p:GetPos()) or ""), 150)
            end
            stages[#stages].onDone = function(q) if IsValid(q.owner) then q.owner.lcNightShiftDone = S.eve end end
            return {
                title = "Night shift", reward = 30 + 5 * #stops, limit = math.max(600, math.floor(NightLeft()) + 120), stages = stages,
                desc = "Keep order while the city sleeps: walk the patrol stops through the night. On a night shift there's no lights out for you, "
                    .. "and a CP Commissary issues you one stimulant shot to stay sharp. The city's own units patrol too.",
                intro = "Dispatch needs eyes on the streets tonight. Long hours, quiet streets. Stay awake.",
            }
        end,
    }
end
AddTemplate()
hook.Add("Initialize", "LivingCityBedtime", AddTemplate)
hook.Add("LivingCityQuestAccepted", "LivingCityBedtime", function(p, q)
    if not (q and q.tmpl and q.tmpl.id == "cp_nightshift") then return end
    p.lcNightShift = S.eve
    Notice(p, "info", "Night shift", "You're on the night shift: no lights out for you tonight. A CP Commissary will issue you a stimulant shot (once a night).", 9)
end)

------------------------------------------------------------------------
-- A dream you missed waits for your next sleep
------------------------------------------------------------------------

function LC.DreamMissed(p) return IsValid(p) and S.missed[Sid(p)] or nil end

hook.Add("LivingCityDreamStarted", "LivingCityBedtime", function(dream)
    if S.solo then return end -- (a missed dream, dreamt alone: nobody else's business)
    local forced = dream.forced or dream.mood == "nightmare"
    -- the hat kept someone asleep out of it (who'd have dreamt it otherwise): spent
    for _, p in ipairs(player.GetAll()) do
        if p.lcSleep and not p.lcDreaming and LC.FoilOn(p) and not LC.Chipless(p) and (forced or not (LC.DreamOptedOut and LC.DreamOptedOut(p))) then FoilSpent(p) end
    end
    if not cvCatch:GetBool() then return end
    S.missed = {} -- (a new dream: whatever was waiting from the last one is gone)
    for _, p in ipairs(player.GetAll()) do
        if p:Alive() and not p.lcDreaming and not p.lcSleep and LC.Chipped(p)
            and (forced or not (LC.DreamOptedOut and LC.DreamOptedOut(p)))
            and not (LC.Unbroken and LC.Unbroken(p)) then
            S.missed[Sid(p)] = { id = dream.ending, wired = (LC.Wired and LC.Wired(p)) or false, t = CurTime() }
            p:ChatPrint("You feel a pull behind your eyes, as if something is waiting for you to fall asleep.")
        end
    end
end)

function LC.DreamCatchupTick(now)
    if not cvCatch:GetBool() then return end
    for sid, m in pairs(S.missed) do
        local p = BySid(sid)
        if m.t and now - m.t > DayLen() * 2 then S.missed[sid] = nil -- (two days on: gone)
        elseif IsValid(p) then
            -- the stimulant chain: one break in it during the night and the dream keeps waiting
            local ph = Phase()
            if m.wired and (ph == "night" or ph == "dusk") and not (LC.Wired and LC.Wired(p)) then m.wired = false end
            if not LC.Chipped(p) then S.missed[sid] = nil
            elseif p.lcSleep and p.lcSleep.done and not p.lcDreaming and now >= (p.lcSleep.t0 or now) + 8 and not LC.DreamActive and not (LC.EndingBusy and LC.EndingBusy()) then
                S.missed[sid] = nil
                if LC.FoilOn(p) then FoilSpent(p)
                elseif LC.DreamStart then
                    S.solo = true
                    local ok, why = LC.DreamStart(m.id, nil, false, nil, true, { p })
                    S.solo = nil
                    if ok then
                        Notice(p, "warn", "The dream you missed", "It was waiting for you. Tonight's dream takes you as you fall asleep: you dream it now, on your own. "
                            .. "You'll wake in your bed with everything you had.", 10)
                    elseif LC.Log then LC.Log("info", "Missed dream for " .. p:Nick() .. " didn't happen: " .. tostring(why)) end
                end
            end
        end
    end
end
timer.Create("LivingCityDreamCatchup", 2, 0, function()
    local ok, err = pcall(LC.DreamCatchupTick, CurTime())
    if not ok and LC.Error then LC.Error("bedtime", err) end
end)

------------------------------------------------------------------------
-- No chip: a short sleep, and up on your own
------------------------------------------------------------------------

-- Seconds a night's sleep takes for them (sv_livingcity_rest.lua asks).
function LC.SleepSecsFor(p, secs)
    if LC.Chipless(p) then return math.min(secs, math.max(5, cvSleep:GetFloat())) end
    return secs
end
hook.Add("LivingCitySlept", "LivingCityBedtime", function(p)
    if not LC.Chipless(p) then return end
    timer.Simple(0, function()
        if IsValid(p) and p.lcSleep and LC.WakeUp then
            LC.WakeUp(p, "quiet")
            p:ChatPrint("No chip, no dreams: you wake on your own, rested.")
        end
    end)
end)

------------------------------------------------------------------------
-- Pulling the chip (the lab's window: sv_livingcity_lab.lua)
------------------------------------------------------------------------

function LC.ChipPrice() return math.max(0, cvPrice:GetInt()) end
function LC.ChipSurgeryReady(p)
    if Faction(p) ~= "resistance" then return false, "He only works for the Resistance." end
    local price = LC.ChipPrice()
    if price <= 0 then return false, "\"Pull the chip? Not here. Not without the proper tools.\"" end
    if LC.Chipless(p) then return false, "\"It's out already. There's nothing left in there to take.\"" end
    local earned, why = LC.DreamOptOutEarned(p)
    if not earned then return false, why end
    if not LC.Credits or LC.Credits(p) < price then return false, string.format("%d credits for the tools and the codes, and you don't have them.", price) end
    return true
end
