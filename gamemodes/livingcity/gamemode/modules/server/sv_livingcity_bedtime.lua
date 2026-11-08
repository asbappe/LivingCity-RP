--[[
    Living City: lights out, the night shift, stimulants, the foil hat, and the chip

    The owner, 8 November: "citizens get sleepy around the same time every
    night before the dreams start so that they all go to bed and dream at the
    same time", "human player metrocops should definitely need to sleep like
    citizens, UNLESS they take a 'night shift' quest", "the administrator
    needs to go to bed just like citizens every night. Even in nightmares.
    Same for administration staff", "make it so that all human players get
    sleepy/exhausted at the same time and all need to sleep; the only way to
    avoid this is a stimulant, which cannot be used two days/dreams/nights in
    a row", "if they buy a stimulant to stay awake, then they miss the dream
    until the next night ... they can't take another until they have slept
    and dreamed fully", "the lab can make some sort of tin foil hat or maybe
    they can surgically remove the chip", and for no chip "they can just
    sleep for 90 seconds instead".

    Lights out (lc_bedtime 1). Every player (citizens, the Resistance, Civil
    Protection, the Administration and its staff, vortigaunts; not a stalker
    or the infested, who never sleep) is due in bed at the good night (21:00,
    the Administrator's "night" announcement), whatever they slept in the day,
    warned about six and two real minutes before ("Lights out soon"). Past it,
    out of bed, they're tired (eyes closing, no running, weaker) until they
    sleep. They're done for the night once they've slept after the good
    night, or woken from tonight's dream, or (with no dream coming tonight)
    slept since dusk (19:00). So the only ways to be up when the dream comes:
      - a stimulant shot: wide awake while it lasts, and lights out waits
        until it wears off; then they're tired, and by the time they've slept
        the dream has gone by: they miss it until the next night. ONE shot,
        then no more until they've slept and dreamt a dream through (to its
        end, or until they were out of it; on a night with no dream, a night's
        sleep will do). A second one is refused ("your body won't take it").
      - a Civil Protection unit on the night shift (below).

    The night shift (Civil Protection, Overwatch). Most nights
    (lc_nightshift_chance, 0.85) a "Night shift" directive goes up on their
    board (F4) from dusk: walk the patrol stops through the night. While on
    it (or once it's done) that night, no lights out for them, and a CP
    Commissary issues them one free stimulant shot (once a night; the one-shot
    rule still applies to taking it). The city's own units patrol whether or
    not anyone takes it.

    The foil hat (the lab; contraband). Put it on (F3) and sleep in it: no
    dream reaches you, and the hat's spent once it has kept one out. It lasts
    one in-game day if it isn't needed.

    The chip (the lab: "Pull the chip"). Pulling it takes special one-time
    tools and the codes to shut it down safely: lc_chip_price (500) credits,
    thirty seconds under. Only once you've lived through lc_chip_dreams (3)
    of the city's dreams (they have to be endured at first): the foil hat
    needs the same. With no chip: no dreams at all, ever; still to bed at
    lights out, but sleep takes at most lc_chipless_sleep (90) seconds and
    you get up on your own; and a unit who checks your papers or searches you
    notices there's no implant signal one time in lc_chip_notice (0.15): a
    crime, and the papers fail.

      lc_bedtime 0/1, lc_nightshift_chance (0.85), lc_chip_price (500),
      lc_chip_dreams (3), lc_chipless_sleep (90), lc_chip_notice (0.15)
]]

if CLIENT then return end

LC = LC or {}

local FLAGS = bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED)
local cvBed     = CreateConVar("lc_bedtime", "1", FLAGS, "Every player is due in bed at the good night (21:00), whatever they slept in the day (a stimulant, once, or a unit's night shift excuses them)")
local cvShift   = CreateConVar("lc_nightshift_chance", "0.85", FLAGS, "Chance each night that Civil Protection's board has a night shift (no lights out, a free stimulant at a CP Commissary)")
local cvPrice   = CreateConVar("lc_chip_price", "500", FLAGS, "Credits to have the chip pulled at the Resistance lab (the one-time tools and codes; 0: not offered)")
local cvNeed    = CreateConVar("lc_chip_dreams", "3", FLAGS, "Dreams someone must have lived through before the lab will pull their chip or make them a foil hat")
local cvSleep   = CreateConVar("lc_chipless_sleep", "90", FLAGS, "Most seconds a night's sleep takes with no chip (no dream to wait for: they get up on their own)")
local cvNotice  = CreateConVar("lc_chip_notice", "0.15", FLAGS, "Chance a unit checking papers or searching someone notices there's no implant signal")

local S = LC.BedtimeState or { eve = 0, roll = {} }
LC.BedtimeState = S

local function Notice(p, kind, title, text, secs) if LC.Notice then LC.Notice(p, kind, title, text, secs) elseif p.ChatPrint then p:ChatPrint(title .. ": " .. text) end end
local function DayLen() return math.max(60, GetGlobal2Float("lc_day_len", 1440)) end
local function Faction(p) return p:GetNW2String("lcf_faction", "") end
local function Sid(p) return p.SteamID64 and p:SteamID64() or tostring(p) end
local function Phase() return LC.DayPhase and LC.DayPhase() or "day" end

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
    p:SetPData("lc_stim_locked", "0")
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
    Notice(p, "info", "Foil hat on", "It crinkles as you pull it down. Sleep in it and no dream can reach you; it's spent once it has kept one out. "
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

-- Does lights out pull them? Everyone who sleeps (a stalker and the infested never do), except a
-- unit on the night shift (the owner, 8 November: "all human players get sleepy/exhausted at the same time").
function LC.BedtimeFor(p)
    if not cvBed:GetBool() or not IsValid(p) then return false end
    local f = Faction(p)
    if f == "stalker" or f == "zombie" then return false end
    if f == "cp" and LC.OnNightShift(p) then return false end
    return true
end

-- Tonight's good night (CurTime of 21:00; after midnight, last night's), and the hour now.
local function GoodNight(now, len)
    local h = ((now - GetGlobal2Float("lc_day_zero", 0)) / len * 24) % 24
    local bed = now - h / 24 * len + 21 / 24 * len
    if h < 5 then bed = bed - len end
    return bed, h
end

-- When they're due in bed (CurTime), or nil. The good night (21:00), unless they're done for the
-- night: slept after it, woken from tonight's dream, or (no dream tonight) slept since dusk. A
-- stimulant holds it off while it lasts. (sv_livingcity_rest.lua takes the sooner of this and their usual time.)
function LC.BedtimeDue(p)
    if not LC.BedtimeFor(p) then return nil end
    local len, now = DayLen(), CurTime()
    local bed, h = GoodNight(now, len)
    local tonight = h >= 19 or h < 5
    local since = p.lcAwakeSince or now
    local noDream = S.dreamEve ~= S.eve and not (LC.DreamTonightPending and LC.DreamTonightPending())
    if since >= bed or (tonight and p.lcDreamtEve == S.eve) or (tonight and noDream and since >= bed - 2 / 24 * len) then
        bed = bed + len -- (done for tonight: tomorrow night's)
    end
    if LC.Wired and LC.Wired(p) then bed = math.max(bed, p:GetNW2Float("lc_wired_until", 0)) end
    return bed
end
function LC.IsBedtimeDue(p, due)
    local b = LC.BedtimeDue(p)
    return b ~= nil and due ~= nil and math.abs(b - due) < 1
end

------------------------------------------------------------------------
-- Stimulants: one, then not again until you've slept and dreamt properly
------------------------------------------------------------------------

LC.StimLockedText = "Your body won't take another one. You haven't slept and dreamt properly since the last (sleep through a night, and its dream if there is one)."
function LC.StimLocked(p) return IsValid(p) and p.GetPData and p:GetPData("lc_stim_locked", "0") == "1" end
local function Unlock(p) if LC.StimLocked(p) then p:SetPData("lc_stim_locked", "0") end end
hook.Add("LivingCityConsumed", "LivingCityBedtime", function(p, id)
    local it = LCS and LCS.Items and LCS.Items[id]
    if not (it and it.vice == "stim") then return end
    p:SetPData("lc_stim_locked", "1")
    local h = LC.Hour and LC.Hour() or 12
    p.lcStimEve = (h >= 19 or h < 5) and S.eve or (S.eve + 1) -- (the night it keeps them up through)
end)

------------------------------------------------------------------------
-- The night shift
------------------------------------------------------------------------

hook.Add("LivingCityDayPhase", "LivingCityBedtime", function(phase)
    if phase == "dusk" then S.eve = (S.eve or 0) + 1 end
    if phase == "dawn" then
        -- a night's sleep (and not a night kept up on a stimulant): another shot allowed
        local dusk = CurTime() - 10 / 24 * DayLen()
        for _, p in ipairs(player.GetAll()) do
            if LC.StimLocked(p) and p.lcStimEve ~= S.eve and (p.lcAwakeSince or 0) >= dusk then Unlock(p) end
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
-- Tonight's dream: who's been in it, and the foil hat
------------------------------------------------------------------------

hook.Add("LivingCityDreamStarted", "LivingCityBedtime", function(dream)
    local ph = Phase()
    if ph == "dusk" or ph == "night" then S.dreamEve = S.eve end
    local forced = dream.forced or dream.mood == "nightmare"
    -- the hat kept someone asleep out of it (who'd have dreamt it otherwise): spent
    for _, p in ipairs(player.GetAll()) do
        if p.lcSleep and not p.lcDreaming and LC.FoilOn(p) and not LC.Chipless(p) and (forced or not (LC.DreamOptedOut and LC.DreamOptedOut(p))) then FoilSpent(p) end
    end
end)

-- Woken from tonight's dream: done for the night; and dreamt through (not woken early), another stimulant allowed.
hook.Add("LivingCityDreamWoke", "LivingCityBedtimeNight", function(p, ok, why)
    if not IsValid(p) then return end
    local ph = Phase()
    if ph == "dusk" or ph == "night" then p.lcDreamtEve = S.eve end
    if why ~= "optout" or p.lcDreamWokeFull then Unlock(p) end
    p.lcDreamWokeFull = nil
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
