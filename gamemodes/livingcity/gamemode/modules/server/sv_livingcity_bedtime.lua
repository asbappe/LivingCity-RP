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

    The foil hat (the lab; contraband). Put it on (F3) and sleep in it: it
    keeps the night's dream out only lc_foil_chance (a third) of the time (the
    owner, 8 November: "only stop dreaming 1/3 the time ... it's a hecking
    tin foil hat"), decided when it goes on and not told; it's spent come the
    dream either way. It lasts one in-game day if no dream comes.

    The chip (the lab: "Pull the chip"). Pulling it takes special one-time
    tools and the codes to shut it down safely: lc_chip_price (500) credits,
    thirty seconds under. Only once you've lived through lc_chip_dreams (3)
    of the city's dreams (they have to be endured at first): the foil hat
    needs the same. With no chip: no dreams at all, ever; still to bed at
    lights out, but sleep takes at most lc_chipless_sleep (90) seconds and
    you get up on your own; and a unit who checks your papers or searches you
    notices there's no implant signal one time in lc_chip_notice (0.15): a
    crime, and the papers fail.

    Woken in your sleep (the owner, 8 November: "being woken if injured/attacked
    ... if a resistance zone is raided by cp or overwatch, the human players and
    NPCs need to be woke in that rebel territory ... gunshots would obviously
    wake you up"). Hurt while asleep: you wake (as before). Dreaming: your
    sleeping body stays in the bed (a still copy, eyes shut), and if it's hit
    you're pulled out of the dream, wake in your bed, and take the hit. And
    on rebel ground (the owner, 8 November: "if anyone, NPC or player, in a
    rebel zone is shot (not just hurt, as we don't want prop damage or
    someone getting burned by a burn barrel waking everyone up) ... Also if
    someone in the rebel zone is arrested or hit by a cp arrest/stun baton or
    attacked at all by a cp or overwatch unit"): anyone there, player or NPC,
    attacked by an enemy of the camp (Civil Protection or Overwatch, players
    or the city's own units; the infested; a monster), shot or batoned or
    otherwise; or arrested: everyone asleep there wakes, players (out of a
    dream too) and the camp's own people. NOT by the Resistance's own, nor by
    any other player (the owner, 8 November: "is there a way to eliminate
    resistance members purposely shooting or harming their fellow rebels or
    an NPC in order to loophole a way to skip dreaming?"): a rebel on a
    stimulant (or in a foil hat, or with no chip) can't wake the camp with a
    shot at a friend. The same goes for anyone asleep, dreaming or not
    ("stop friends' hits from waking sleepers too"; "players and NPCs can't be
    hurt by friendlies and members of their faction when sleeping"): a hit
    from their own side does nothing at all (no wake, no harm), players and
    the city's sleeping NPCs alike; a rebel wakes only to an enemy of the
    camp. An enemy's hit, or the world's (a fire, a fall), wakes them,
    groggy. Woken early like that, you're groggy ("since
    they are woken up early, then the standard effects would apply such as
    the grogginess visual effect and very low stamina"), but not at once
    ("defer the groggy effect if woken by violence ... they would have
    adrenaline"): first adrenaline, wide awake with full stamina, and
    lc_startled_minutes (10) before lights out can make you tired; then "The
    adrenaline has worn off. You need rest.", and for lc_groggy_seconds (60)
    your eyelids droop and the world blurs (lighter as you come round), your
    stamina is gone and comes back at a quarter of the rate. Back in bed
    before then, no crash.
    Hunger and thirst wait while you sleep or dream: they never hurt or wake
    you (sv_livingcity_survival.lua).

      lc_bedtime 0/1, lc_nightshift_chance (0.85), lc_chip_price (500),
      lc_chip_dreams (3), lc_chipless_sleep (90), lc_chip_notice (0.15),
      lc_groggy_seconds (60), lc_startled_minutes (10), lc_foil_chance (0.33)
]]

if CLIENT then return end

LC = LC or {}

local FLAGS = bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED)
local cvBed     = CreateConVar("lc_bedtime", "1", FLAGS, "Every player is due in bed at the good night (21:00), whatever they slept in the day (a stimulant, once, or a unit's night shift excuses them)")
local cvShift   = CreateConVar("lc_nightshift_chance", "0.85", FLAGS, "Chance each night that Civil Protection's board has a night shift (no lights out, a free stimulant at a CP Commissary)")
local cvPrice   = CreateConVar("lc_chip_price", "500", FLAGS, "Credits to have the chip pulled at the Resistance lab (the one-time tools and codes; 0: not offered)")
local cvFoil    = CreateConVar("lc_foil_chance", "0.33", FLAGS, "Chance a foil hat keeps a night's dream out (it's spent either way)")
local cvNeed    = CreateConVar("lc_chip_dreams", "3", FLAGS, "Dreams someone must have lived through before the lab will pull their chip or make them a foil hat")
local cvSleep   = CreateConVar("lc_chipless_sleep", "90", FLAGS, "Most seconds a night's sleep takes with no chip (no dream to wait for: they get up on their own)")
local cvNotice  = CreateConVar("lc_chip_notice", "0.15", FLAGS, "Chance a unit checking papers or searching someone notices there's no implant signal")
local cvGroggy  = CreateConVar("lc_groggy_seconds", "60", FLAGS, "Seconds someone woken early (hurt, or their camp raided) is groggy: drooping eyelids, a blur, no stamina and slow to get it back")
local cvStartle = CreateConVar("lc_startled_minutes", "10", FLAGS, "Minutes someone woken by an attack or a raid has before lights out can make them tired")

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
hook.Add("LivingCityDreamWoke", "LivingCityBedtime", function(p, _, why)
    if not IsValid(p) or p.lcDreamWokeEnforcer or why == "test" then return end
    local f = Faction(p)
    if f ~= "citizen" and f ~= "resistance" then return end
    p:SetPData("lc_dreams_endured", tostring(LC.DreamsEndured(p) + 1))
end)
-- A new person: a new chip, and no dreams lived through yet.
hook.Add("LivingCityNewCharacter", "LivingCityBedtime", function(p)
    p:SetPData("lc_chipless", "0")
    p:SetPData("lc_dreams_endured", "0")
    p:SetPData("lc_stim_locked", "0")
    p.lcDreamFoilUntil = nil
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

function LC.FoilOn(p) return IsValid(p) and (p.lcDreamFoilUntil or 0) > CurTime() end
function LC.FoilHatUse(p, id)
    if LC.Chipless(p) then return false, "There's no chip in your head left for it to block." end
    if LC.FoilOn(p) then return false, "You've one on already." end
    if not LC.TakeItem(p, id or "foil_hat") then return false end
    p.lcDreamFoilUntil = CurTime() + DayLen()
    p.lcDreamFoilWorks = math.random() < math.Clamp(cvFoil:GetFloat(), 0, 1) -- (decided now, kept quiet: about one night in three)
    p:EmitSound("physics/metal/metal_box_scrape_rough_loop1.wav", 50, 160)
    -- (a loop: a second of crinkling, then stopped, or it went on for ever)
    timer.Simple(1.2, function() if IsValid(p) and p.StopSound then p:StopSound("physics/metal/metal_box_scrape_rough_loop1.wav") end end)
    Notice(p, "info", "Foil hat on", "It crinkles as you pull it down. Will it keep the dream out? Sometimes: about one night in three. "
        .. "The scientist says something about field harmonics; it's a tin foil hat. It's spent come the dream either way, and it's contraband: don't let a unit see you in it.", 10)
    return true
end
-- Kept out of every dream: no chip, or a foil hat on (sv_livingcity_dreams.lua asks).
function LC.DreamProof(p) return LC.Chipless(p) or (LC.FoilOn(p) and p.lcDreamFoilWorks == true) end
local function FoilSpent(p)
    p.lcDreamFoilUntil, p.lcDreamFoilWorks = nil, nil
    Notice(p, "info", "The foil hat", "You feel a static, a distant power pressing at your mind that can't quite break in. The foil hat holds, this time. (It's spent.)", 8)
end
local function FoilFailed(p)
    p.lcDreamFoilUntil, p.lcDreamFoilWorks = nil, nil
    Notice(p, "warn", "The foil hat", "Despite your tin foil hat, you feel a distant power, an electric vibration, enter your mind and overpower your senses. The tin foil hat didn't work this time.", 8)
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
    if LC.DreamAdminSkips and LC.DreamAdminSkips(p) then return false end -- (the Administrator: only her own dreams send her to bed: sv_livingcity_dreamplan.lua)
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
    if (p.lcStartledUntil or 0) > now then bed = math.max(bed, p.lcStartledUntil) end -- (woken by an attack: wide awake a while)
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
LC.NightShiftFrom, LC.NightShiftTo = 18, 21
function LC.NightShiftHour(h)
    h = h or (LC.Hour and LC.Hour()) or 12
    return h >= LC.NightShiftFrom and h < LC.NightShiftTo
end

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
        -- Only in the evening, 18:00 to 21:00 (the owner, 11 November: it was on the board in the middle of
        -- the day, "only available from like 6-9 ish"); checked again when it's taken.
        recheck = true, recheckWhy = "The night shift is only given out in the evening, from 18:00 to 21:00.",
        available = function(p)
            return cvBed:GetBool() and LC.NightShiftHour() and LC.NightShiftTonight() and p.lcNightShift ~= S.eve and p.lcNightShiftDone ~= S.eve
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
    if dream.test then return end -- (a test from the editor isn't tonight's dream)
    local ph = Phase()
    if ph == "dusk" or ph == "night" then S.dreamEve = S.eve end
    local forced = dream.forced or dream.mood == "nightmare"
    -- the hat kept someone asleep out of it (who'd have dreamt it otherwise): spent
    for _, p in ipairs(player.GetAll()) do
        if LC.FoilOn(p) and not LC.Chipless(p) then
            if p.lcDreaming == dream.id then FoilFailed(p) -- (two nights in three: in the dream anyway)
            elseif p.lcSleep and not p.lcDreaming then FoilSpent(p) end
        end
    end
end)

-- Woken from tonight's dream: done for the night; and dreamt through (not woken early), another stimulant allowed.
hook.Add("LivingCityDreamWoke", "LivingCityBedtimeNight", function(p, ok, why)
    if not IsValid(p) or why == "test" then return end
    local ph = Phase()
    if ph == "dusk" or ph == "night" then p.lcDreamtEve = S.eve end
    if why == "end" or why == "game" or (why == "optout" and p.lcDreamWokeFull) then Unlock(p) end
    p.lcDreamWokeFull = nil
end)

------------------------------------------------------------------------
-- Woken in your sleep: hurt, or the camp raided
------------------------------------------------------------------------

-- Wake someone asleep or dreaming (why: "hurt" or "raid"). True if they were.
function LC.WakeSleeper(p, why, text)
    if not IsValid(p) then return false end
    if p.lcDreaming then
        p.lcDreamWokenBy = { why = why, text = text } -- (out of the dream; once back in bed, up: the Woke hook below)
        if LC.DreamWakeOne then LC.DreamWakeOne(p, why) end
        return true
    elseif p.lcSleep then
        if LC.WakeUp then LC.WakeUp(p, "quiet") end
        LC.MakeGroggy(p)
        Notice(p, "warn", "You wake with a start", (text or "Something woke you.") .. " " .. LC.AdrenalineText, 7)
        return true
    end
    return false
end

-- Groggy (eyelids drooping, a blur: cl_livingcity_rest.lua), no stamina and slow to get it back
-- (sh_livingcity_stamina.lua).
function LC.Groggy(p)
    if not IsValid(p) then return end
    p:SetNW2Float("lc_groggy_until", CurTime() + math.max(0, cvGroggy:GetFloat()))
    p:SetNW2Float("lc_stamina", 0)
    p:SetNW2Bool("lc_winded", true)
end
-- Woken early, by violence (an enemy, a raid, a fire): adrenaline first (the owner, 8 November: "defer
-- the groggy effect if woken by violence ... they would have adrenaline. Then after 10 minutes it can say
-- the adrenaline had worn off; you need rest"): wide awake, full stamina, and lights out waits for
-- lc_startled_minutes (10). Then the crash: groggy, and lights out again (not if they're back in bed).
function LC.MakeGroggy(p)
    if not IsValid(p) then return end
    p.lcStartledUntil = CurTime() + math.max(0, cvStartle:GetFloat()) * 60
    p.lcGroggyPending = true
    p:SetNW2Float("lc_groggy_until", 0)
    p:SetNW2Float("lc_stamina", 100)
    p:SetNW2Bool("lc_winded", false)
end
LC.AdrenalineText = "Adrenaline has you wide awake, for now."
timer.Create("LivingCityAdrenaline", 2, 0, function()
    local now = CurTime()
    for _, p in ipairs(player.GetAll()) do
        if p.lcGroggyPending and now >= (p.lcStartledUntil or 0) then
            p.lcGroggyPending = nil
            if p:Alive() and not p.lcSleep and not p.lcDreaming then
                LC.Groggy(p)
                Notice(p, "warn", "The adrenaline wears off", "The adrenaline has worn off. You need rest.", 8)
            end
        end
    end
end)

-- The sleeping body a dreamer leaves in the bed: a still copy, eyes shut. Hit it and they wake.
function LC.DreamBodyMake(p, snap)
    local s = snap and snap.sleep
    if not s or not s.top then return nil end
    local top = Vector(tonumber(s.top[1]) or 0, tonumber(s.top[2]) or 0, tonumber(s.top[3]) or 0)
    if top == Vector(0, 0, 0) then return nil end
    local yaw = tonumber(s.yaw) or 0
    p.lcDreamBedPos = top
    local rag = ents.Create("prop_ragdoll")
    if not IsValid(rag) then return nil end
    local ok = LC.Try(function()
        rag:SetModel(p:GetModel())
        rag:SetSkin(p:GetSkin() or 0)
        for i = 0, (p.GetNumBodyGroups and p:GetNumBodyGroups() or 1) - 1 do rag:SetBodygroup(i, p:GetBodygroup(i)) end
        rag:SetPos(top + Vector(0, 0, 4))
        rag:SetAngles(Angle(0, yaw, 0))
        rag:Spawn()
        rag:Activate()
        rag:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
        -- the model as it stands, turned onto its back along the bed, and held still
        local head = Angle(0, yaw, 0):Forward()
        local m = Matrix()
        m:SetForward(Vector(0, 0, 1)) m:SetUp(head) m:SetRight(Vector(0, 0, 1):Cross(head))
        local lieAng = m:GetAngles()
        local base, baseAng = rag:GetPos(), Angle(0, yaw, 0)
        local origin = top - head * 38 + Vector(0, 0, 9)
        for i = 0, (rag.GetPhysicsObjectCount and rag:GetPhysicsObjectCount() or 0) - 1 do
            local phys = rag:GetPhysicsObjectNum(i)
            if IsValid(phys) then
                local lp, la = WorldToLocal(phys:GetPos(), phys:GetAngles(), base, baseAng)
                local wp, wa = LocalToWorld(lp, la, origin, lieAng)
                phys:SetPos(wp)
                phys:SetAngles(wa)
                phys:EnableMotion(false)
            end
        end
    end)
    if not ok then rag:Remove() return nil end
    rag:SetNW2Bool("lc_eyes_shut", true)
    rag:SetNW2Bool("lc_sleeper", true)
    if LC.SetNPCStr then
        LC.SetNPCStr(rag, "lc_pname", LC.CharacterName and LC.CharacterName(p) or p:Nick())
        LC.SetNPCStr(rag, "lc_doing", "asleep")
    end
    rag.lcDreamBodyOf = p
    p.lcDreamBody = rag
    return rag
end
local function BodyGone(p)
    if IsValid(p) and IsValid(p.lcDreamBody) then p.lcDreamBody:Remove() end
    if IsValid(p) then p.lcDreamBody = nil end
end
-- the sleeping body hit: out of the dream, and they take the hit once they're up
hook.Add("EntityTakeDamage", "LivingCityDreamBody", function(ent, dmg)
    local p = IsValid(ent) and ent.lcDreamBodyOf
    if not IsValid(p) then return end
    if p.lcDreaming and dmg:GetDamage() > 0 and LC.SleeperEnemy(p, dmg:GetAttacker()) then -- (a friend's hit does nothing: no waking a dreamer to skip it)
        p.lcDreamHurt = { amount = dmg:GetDamage(), attacker = dmg:GetAttacker() }
        LC.WakeSleeper(p, "hurt", "Something hit you in your sleep. You wake in your bed, hurt.")
    end
    return true -- (the copy itself is never hurt or knocked about)
end)
-- back in bed after being pulled out: up, and the hit taken; the body copy gone either way
hook.Add("LivingCityDreamWoke", "LivingCityDreamBody", function(p, ok, why)
    if not IsValid(p) then return end
    BodyGone(p)
    p.lcDreamBedPos = nil
    local by = p.lcDreamWokenBy
    p.lcDreamWokenBy = nil
    if not by then return end
    if p.lcSleep and LC.WakeUp then LC.WakeUp(p, "quiet") end
    LC.MakeGroggy(p)
    Notice(p, "warn", "You wake with a start", (by.text or "Something woke you.") .. " " .. LC.AdrenalineText, 7)
    local hurt = p.lcDreamHurt
    p.lcDreamHurt = nil
    if hurt and p:Alive() then
        local att = IsValid(hurt.attacker) and hurt.attacker or game.GetWorld()
        p:TakeDamage(hurt.amount, att, att)
    end
end)
hook.Add("LivingCityDreamEnded", "LivingCityDreamBody", function(dream)
    for _, p in ipairs(dream and dream.list or {}) do if IsValid(p) and not p.lcDreaming then BodyGone(p) end end
end)
hook.Add("PlayerDisconnected", "LivingCityDreamBody", BodyGone)

-- Rebel ground under attack: everyone asleep on it wakes (players, out of a dream too, and the camp's own).
local zoneWoke = setmetatable({}, { __mode = "k" })
function LC.WakeRebelZone(z, pos, force)
    if not z then return 0 end
    local now = CurTime()
    if not force and (zoneWoke[z] or -100) > now - 5 then return 0 end -- (a burst of shots wakes them once)
    zoneWoke[z] = now
    local n = 0
    local text = "Trouble in the camp! Gunfire, shouting: someone's under attack."
    for _, p in ipairs(player.GetAll()) do
        local at = p.lcDreaming and p.lcDreamBedPos or (p.lcSleep and p:GetPos())
        if at and LCZ and LCZ.Contains(z, at, 0) and LC.WakeSleeper(p, "raid", text) then n = n + 1 end
    end
    for npc, st in pairs(LC.NPCs or {}) do
        if IsValid(npc) and LC.RebelAsleep and LC.RebelAsleep(st) and LCZ and LCZ.Contains(z, npc:GetPos(), 120) then
            if LC.RebelLifeEnd then LC.RebelLifeEnd(npc, st) end
            n = n + 1
        end
    end
    if LC.RebelAlert then LC.RebelAlert(z, pos or z.pos, now) end
    return n
end
local function Combine(e)
    if not IsValid(e) then return false end
    if e:IsPlayer() then return LC.PlayerIsCP and LC.PlayerIsCP(e) or false end
    local st = LC.NPCs and LC.NPCs[e]
    return st ~= nil and LC.IsSecurity ~= nil and LC.IsSecurity(st) == true
end
LC.RaidWakeBy = Combine
-- Rebel ground, where something happened to someone (pos): wake it.
function LC.RaidWakeAt(pos)
    local z = pos and LC.RebelZoneAt and LC.RebelZoneAt(pos, 0)
    if z then return LC.WakeRebelZone(z, pos) end
    return 0
end
-- An enemy of a rebel camp: Civil Protection or Overwatch (players, or the city's units), the infested
-- (players or not), or a monster the map or the engine brought (not a citizen, a rebel, a vortigaunt or the like).
-- Never the Resistance, and never any other player: nobody wakes a camp (or a dreamer) by shooting a friend.
function LC.CampEnemy(att)
    if not IsValid(att) then return false end
    if att:IsPlayer() then return Combine(att) or (LC.PlayerIsZombie and LC.PlayerIsZombie(att)) or false end
    if not (att.IsNPC and att:IsNPC()) then return false end
    local st = LC.NPCs and LC.NPCs[att]
    if st then return Combine(att) or st.role == "zombie" end -- (the city's own: only its units and the infested)
    local cls = att.GetClass and att:GetClass() or ""
    return not (cls == "npc_citizen" or cls == "npc_vortigaunt" or cls == "npc_alyx" or cls == "npc_barney" or cls == "npc_eli" or cls == "npc_kleiner"
        or cls == "npc_magnusson" or cls == "npc_mossman" or cls == "npc_monk" or cls == "npc_dog")
end
-- Which side someone's on: "resistance", "combine", "citizen", "zombie", or nil (a monster, or nobody).
function LC.SideOf(e)
    if not IsValid(e) then return nil end
    if e:IsPlayer() then
        local f = e:GetNW2String("lcf_faction", "")
        if f == "resistance" or f == "vort" then return "resistance" end
        if f == "cp" or f == "admin" or f == "stalker" then return "combine" end
        if f == "zombie" then return "zombie" end
        return "citizen"
    end
    local st = LC.NPCs and LC.NPCs[e]
    if not st then return nil end
    if Combine(e) then return "combine" end
    if st.role == "rebel" or st.role == "vort" or st.role == "vortigaunt" then return "resistance" end
    if st.role == "zombie" then return "zombie" end
    if st.role == "citizen" then return "citizen" end
    return nil
end
-- Would this attacker's hit wake this sleeper? Only an enemy's (the owner, 8 November: "stop friends'
-- hits from waking sleepers too"). A rebel: only an enemy of the camp (never another player). Anyone
-- else: anyone not on their own side. Never their own hit.
function LC.SleeperEnemy(victim, att)
    if not IsValid(att) or att == victim then return false end
    local side = LC.SideOf(victim)
    if side == "resistance" then return LC.CampEnemy(att) end
    local theirs = LC.SideOf(att)
    if theirs == nil then return not att:IsPlayer() and LC.CampEnemy(att) end -- (a monster: as for a camp)
    return theirs ~= side
end

-- A hit on someone asleep (player or NPC) from their own side: a player or an NPC who isn't an enemy.
-- Blocked outright: no harm, no waking (sv_livingcity_rest.lua, sv_livingcity_rebellife.lua ask).
function LC.FriendHitsSleeper(victim, att)
    if not IsValid(att) or not (att:IsPlayer() or (att.IsNPC and att:IsNPC())) then return false end
    return not LC.SleeperEnemy(victim, att)
end

-- Does this hit wake the camp? Anyone there (player or NPC) attacked by an enemy of the camp.
function LC.RaidWakeHit(ent, dmg)
    if not IsValid(ent) or not (ent:IsPlayer() or (ent.IsNPC and ent:IsNPC())) then return false end
    return LC.CampEnemy(dmg:GetAttacker())
end
hook.Add("EntityTakeDamage", "LivingCityRaidWake", function(ent, dmg)
    if LC.RaidWakeHit(ent, dmg) then LC.RaidWakeAt(ent:GetPos()) end
end)
-- (arrested there: the arrest baton's arrest calls LC.RaidWakeAt where it happens, sv_livingcity_arrest.lua)

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
