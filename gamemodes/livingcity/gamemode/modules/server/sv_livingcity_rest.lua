--[[
    Living City: sleep

    Everyone needs a night's sleep: once in every in-game day (lc_tired_days,
    1, of the city's day length, lc_day_minutes). Go without and you're tired:
    your eyes keep drooping shut, you're a little unsteady on your feet, you
    can't run, and you've 25 less health at most until you sleep.

    Sleep in a bed (E on it: the editor's "Fixture: bed", a bunk point, or any
    bed or mattress the map has, a cell's too) at night, or any time you're
    exhausted. You lie down on it (the camera goes with you, to your head on
    the pillow; others see you lying there) and can't move: Jump gets you up,
    beside the bed again. It takes
    lc_sleep_seconds (60) to sleep; get up before then, or get hurt, and
    you've not slept. You heal as you sleep, to full by the end of it, and
    stay asleep until you press Jump. A good night leaves you well rested for
    the next in-game day: hunger and thirst come on a quarter more slowly, and
    you slowly heal (a point every ten seconds, up to full). How long you've
    been awake is kept over a server restart.

    Citizens sleep too: at curfew, in a lockdown and at night, the city's
    people walk home to a free bed in a housing block (their own block first,
    then the nearest with one free), lie down on it and sleep till morning,
    getting up a few at a time. Beds: the editor's "Fixture: bed", bunk
    points, and the map's own beds, inside a "block" zone. With no bed free
    they go indoors and are gone, as before. Hurt one and they wake.
    lc_bed_head_flip 1 turns everyone on an editor bed round, if heads end up
    at the foot (sv_livingcity_rebellife.lua).

      lc_sleep 0/1, lc_sleep_seconds (60), lc_tired_days (1),
      lc_citizens_sleep 0/1 (1)
]]

if CLIENT then return end

LC = LC or {}

local FLAGS = bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED)
local cvOn   = CreateConVar("lc_sleep", "1", FLAGS, "People need sleep: tired after a day without it, well rested after a night in a bed")
local cvSecs = CreateConVar("lc_sleep_seconds", "60", FLAGS, "Seconds it takes to sleep in a bed")
local cvDays = CreateConVar("lc_tired_days", "1", FLAGS, "In-game days awake before you're tired")
local cvHomeSleep = CreateConVar("lc_citizens_sleep", "1", FLAGS, "At curfew and at night, citizens walk to a free bed in a housing block and sleep on it till morning (with none free, they go indoors and are gone, as before)")

local TIRED_HP = 25

local function DayLen() return math.max(60, GetGlobal2Float("lc_day_len", 1440)) end
local function Notice(ply, kind, title, text, secs) if LC.Notice then LC.Notice(ply, kind, title, text, secs) else ply:ChatPrint(title .. ": " .. text) end end
local function Exempt(ply)
    return not ply:Alive() or (LC.PlayerIsZombie and LC.PlayerIsZombie(ply)) or ply:GetNW2String("lcf_faction", "") == "admin"
        or ply:GetNW2String("lcf_faction", "") == "stalker" -- (a stalker doesn't sleep: it works)
end

function LC.IsNight()
    local phase = LC.DayPhase and LC.DayPhase() or "day"
    return phase == "night" or phase == "dusk"
end

function LC.IsTired(ply) return ply:GetNW2Bool("lc_tired", false) end
function LC.IsRested(ply) return ply:GetNW2Float("lc_rested_until", 0) > CurTime() end
function LC.AwakeFor(ply) return CurTime() - (ply.lcAwakeSince or CurTime()) end

-- The health limit that goes with being tired (on, or off again).
local function TiredHealth(ply, tired)
    if tired and not ply.lcTiredHP then
        ply.lcTiredHP = true
        ply:SetMaxHealth(math.max(1, ply:GetMaxHealth() - TIRED_HP))
        if ply:Health() > ply:GetMaxHealth() then ply:SetHealth(ply:GetMaxHealth()) end
    elseif not tired and ply.lcTiredHP then
        ply.lcTiredHP = nil
        ply:SetMaxHealth(ply:GetMaxHealth() + TIRED_HP)
    end
end

-- Find a bed where they're looking, or the nearest one within reach: its spot, and the bed ({ pos, ent?, ang?, point?, yaw? }).
local function BedAt(ply, ent)
    if IsValid(ent) and (ent:GetClass() == "lc_bed" or (LC.AmenityKindOf and LC.AmenityKindOf(ent) == "bed")) then return ent:GetPos(), { pos = ent:GetPos(), ent = ent } end
    local best, bd
    for _, a in ipairs(LC.Amenities and LC.Amenities("bed") or {}) do
        local d = a.pos:DistToSqr(ply:GetPos())
        if d < 110 * 110 and (not bd or d < bd) then best, bd = a, d end
    end
    return best and best.pos, best
end
LC.BedNear = BedAt

------------------------------------------------------------------------
-- Who's in which bed (players and citizens alike)
------------------------------------------------------------------------

LC.BedSleepers = LC.BedSleepers or {} -- [bed key] = the player or NPC in it (or on their way to it)

function LC.BedKey(a)
    if IsValid(a.ent) then return "e" .. a.ent:EntIndex() end
    return string.format("s%d_%d_%d", math.floor(a.pos.x), math.floor(a.pos.y), math.floor(a.pos.z))
end

function LC.BedFree(key, who)
    local e = LC.BedSleepers[key]
    if e == nil or e == who then return true end
    if IsValid(e) then
        if e:IsPlayer() then
            if e.lcSleep and e.lcBedKey == key then return false end
        else
            -- taken only while they're in it, or on their way to it (the owner, 7 November: "already
            -- asleep in this bed" on empty beds: a citizen sent off to do something else kept the key)
            local st = LC.NPCs and LC.NPCs[e]
            if st and st.bedKey == key and (st.state == "abed" or (st.state == "moving" and st.poi and st.poi.kind == "homebed")) then return false end
        end
    end
    LC.BedSleepers[key] = nil
    return true
end

-- Where to lie on a bed: { top, yaw, stand } (sv_livingcity_rebellife.lua works it out).
function LC.BedLie(a)
    if not a then return nil end
    local b = LC.RebelBedSpot and LC.RebelBedSpot({ ent = a.ent, pos = a.pos, ang = a.ang, point = a.point, yaw = a.yaw })
    return b and b.top and b or nil
end

-- Sleep in a bed. True, or false and why not. You lie still (you can't move) till you press Jump.
function LC.SleepIn(ply, ent)
    if not cvOn:GetBool() or not IsValid(ply) or not ply:Alive() then return false end
    if ply.lcSleep then return false end
    if ply:GetNW2String("lcf_faction", "") == "stalker" then return false, "A stalker doesn't sleep. It doesn't get tired either: it only works." end
    local where, bed = BedAt(ply, ent)
    if not where then return false, "There's no bed here." end
    local key = LC.BedKey(bed)
    if not LC.BedFree(key, ply) then return false, "Someone's already asleep in this bed." end
    if not LC.IsNight() and not LC.IsTired(ply) then return false, "You're not tired, and it's broad daylight. Beds are for the night (or when you're exhausted)." end
    -- rested for a day after a night's sleep, but you can sleep again 18 in-game hours after (the owner, 7 November)
    if LC.IsRested(ply) and not LC.IsTired(ply) then
        local left = ply:GetNW2Float("lc_rested_until", 0) - CurTime() - DayLen() * 0.25
        if left > 0 then
            local hrs = math.max(1, math.ceil(left / DayLen() * 24))
            return false, string.format("You slept not long ago. You could sleep again in about %d in-game hour%s.", hrs, hrs == 1 and "" or "s")
        end
    end
    local now = CurTime()
    ply.lcSleep = { t0 = now, done = now + math.max(1, cvSecs:GetFloat()), last = now }
    ply:SetNW2Bool("lc_sleeping", true)
    ply:SetNW2Float("lc_sleep_done", ply.lcSleep.done)
    ply:SetVelocity(-ply:GetVelocity())
    -- onto the bed, lying down (the pose and the camera: sh_livingcity_acts.lua, cl_livingcity_rest.lua)
    LC.BedSleepers[key] = ply
    ply.lcBedKey = key
    if LC.StopAct then LC.StopAct(ply) end
    if ply:HasWeapon("weapon_lc_hands") then ply:SelectWeapon("weapon_lc_hands") end
    local b = LC.BedLie(bed)
    if b then
        ply.lcBedFrom = ply:GetPos()
        local up = b.top + Vector(0, 0, 2)
        -- on top of it if they fit there (under a bunk's upper bed they may not): otherwise just beside it
        local tr = util.TraceHull({ start = up, endpos = up, mins = ply:OBBMins(), maxs = ply:OBBMaxs(), filter = ply })
        if tr and not tr.StartSolid then ply:SetPos(up) end
        ply:SetNW2Vector("lc_bed_top", b.top)
        ply:SetNW2Float("lc_bed_yaw", b.yaw or 0)
    end
    return true
end

-- Up again: Jump, or hurt. Before the sleep's done, it doesn't count.
function LC.WakeUp(ply, how)
    local s = IsValid(ply) and ply.lcSleep
    if not s then return false end
    ply.lcSleep = nil
    ply:SetNW2Bool("lc_sleeping", false)
    ply:SetNW2Float("lc_sleep_done", 0)
    if ply.lcBedKey and LC.BedSleepers[ply.lcBedKey] == ply then LC.BedSleepers[ply.lcBedKey] = nil end
    ply.lcBedKey = nil
    ply:SetNW2Vector("lc_bed_top", Vector(0, 0, 0))
    -- off the bed: back where they stood to get in, if nobody's standing there now
    local from = ply.lcBedFrom
    ply.lcBedFrom = nil
    if from and ply:Alive() then
        local tr = util.TraceHull({ start = from + Vector(0, 0, 2), endpos = from + Vector(0, 0, 2), mins = ply:OBBMins(), maxs = ply:OBBMaxs(), filter = ply })
        if tr and not tr.StartSolid then ply:SetPos(from + Vector(0, 0, 2)) end
    end
    if not s.slept and how ~= "quiet" then
        ply:ChatPrint(how == "hurt" and "You wake with a start. You've not slept." or "You get up before you've really slept.")
    end
    return true
end

-- Asleep: healing as you go, full by the end; then rested, and still asleep till you get up.
local function SleepStep(ply, now)
    local s = ply.lcSleep
    if not ply:Alive() then LC.WakeUp(ply, "quiet") return end
    local dt = now - (s.last or now)
    s.last = now
    if not s.slept then
        local left = s.done - now
        local max = ply:GetMaxHealth()
        if left > 0 then
            local hp = ply:Health()
            if hp < max then
                s.heal = (s.heal or 0) + (max - hp) * math.min(1, dt / left)
                local whole = math.floor(s.heal)
                if whole > 0 then ply:SetHealth(math.min(max, hp + whole)) s.heal = s.heal - whole end
            end
        else
            s.slept = true
            ply.lcAwakeSince = now
            ply:SetNW2Bool("lc_tired", false)
            TiredHealth(ply, false)
            ply:SetHealth(ply:GetMaxHealth())
            ply:SetNW2Float("lc_rested_until", now + DayLen())
            Notice(ply, "info", "Well rested", "A night's sleep, and you're healed. For the next day: hunger and thirst come on more slowly, and you heal a little. Press Jump to get up.", 9)
            hook.Run("LivingCitySlept", ply)
        end
    end
end
timer.Create("LivingCitySleepers", 0.5, 0, function()
    local now = CurTime()
    for _, ply in ipairs(player.GetAll()) do
        if ply.lcSleep then
            local ok, err = pcall(SleepStep, ply, now)
            if not ok and LC.Error then LC.Error("rest", err) end
        end
    end
end)
hook.Add("KeyPress", "LivingCitySleepWake", function(ply, key)
    if key == IN_JUMP and ply.lcSleep then LC.WakeUp(ply, "jump") end
end)
hook.Add("EntityTakeDamage", "LivingCitySleepWake", function(ent, dmg)
    if IsValid(ent) and ent:IsPlayer() and ent.lcSleep and dmg:GetDamage() > 0 then LC.WakeUp(ent, "hurt") end
end)
-- lying still: no walking about in your sleep (Jump still gets through, to wake you)
hook.Add("StartCommand", "LivingCitySleeping", function(ply, cmd)
    if not ply:GetNW2Bool("lc_sleeping", false) then return end
    cmd:ClearMovement()
    cmd:SetButtons(bit.band(cmd:GetButtons(), IN_JUMP))
end)

if LC.SlashCommands == nil then LC.SlashCommands = {} end
LC.SlashCommands.sleep = function(ply)
    local ok, why = LC.SleepIn(ply, ply:GetEyeTrace().Entity)
    if not ok and why then ply:ChatPrint(why) end
end

-- E on a bed the map has (a prop or part of the map itself).
hook.Add("KeyPress", "LivingCityBeds", function(ply, key)
    if key ~= IN_USE or not cvOn:GetBool() or not ply:Alive() then return end
    local tr = util.TraceLine({ start = ply:EyePos(), endpos = ply:EyePos() + ply:EyeAngles():Forward() * 100, filter = ply })
    local ent = tr.Entity
    if IsValid(ent) and ent:GetClass() == "lc_bed" then return end -- (its own Use)
    if IsValid(ent) and ent ~= game.GetWorld() then
        if not (LC.AmenityKindOf and LC.AmenityKindOf(ent) == "bed") then return end
    else
        -- part of the map: a bed the map file lists, right where you're looking
        local near = false
        for _, r in ipairs(LC.StaticRest or {}) do
            if r.kind == "bed" and tr.Hit and r.pos:DistToSqr(tr.HitPos) < 90 * 90 then near = true break end
        end
        if not near then return end
    end
    local ok, why = LC.SleepIn(ply, ent)
    if not ok and why then ply:ChatPrint(why) end
end)

-- Every five seconds: who's tired, and the rested heal.
function LC.RestTick(now)
    if not cvOn:GetBool() then return end
    local limit = DayLen() * cvDays:GetFloat()
    for _, ply in ipairs(player.GetAll()) do
        ply.lcAwakeSince = ply.lcAwakeSince or now
        if Exempt(ply) then
            if ply:GetNW2Bool("lc_tired", false) then ply:SetNW2Bool("lc_tired", false) TiredHealth(ply, false) end
        else
            local tired = now - ply.lcAwakeSince > limit
            if tired ~= ply:GetNW2Bool("lc_tired", false) then
                ply:SetNW2Bool("lc_tired", tired)
                if tired then Notice(ply, "warn", "Exhausted", "You haven't slept in a day. Your eyes keep closing, you can't run, and you're weaker. Find a bed at night (F1 > What now? > Places).", 9) end
            end
            TiredHealth(ply, tired)
        end
    end
end

timer.Create("LivingCityRest", 5, 0, function()
    local ok, err = pcall(LC.RestTick, CurTime())
    if not ok and LC.Error then LC.Error("rest", err) end
end)

-- A new life starts out rested enough; dying doesn't make you any less tired.
hook.Add("PlayerSpawn", "LivingCityRest", function(ply)
    ply.lcTiredHP = nil -- (spawning sets the health limit afresh; the tick takes it down again if need be)
    if ply.lcSleep then LC.WakeUp(ply, "quiet") end
    if not ply.lcAwakeSince then
        -- how long they'd been awake, and rested for, kept over a restart or a reconnect
        local awake = tonumber(ply:GetPData("lc_awake_for", "")) or 0
        ply.lcAwakeSince = CurTime() - math.max(0, awake)
        local rest = tonumber(ply:GetPData("lc_rested_for", "")) or 0
        if rest > 0 then ply:SetNW2Float("lc_rested_until", CurTime() + rest) end
    end
end)
local function SaveRest(ply)
    if not IsValid(ply) or not ply.lcAwakeSince then return end
    ply:SetPData("lc_awake_for", tostring(math.floor(CurTime() - ply.lcAwakeSince)))
    ply:SetPData("lc_rested_for", tostring(math.max(0, math.floor(ply:GetNW2Float("lc_rested_until", 0) - CurTime()))))
end
LC.SaveRest = SaveRest
hook.Add("PlayerDisconnected", "LivingCityRest", SaveRest)
hook.Add("ShutDown", "LivingCityRest", function() for _, p in ipairs(player.GetAll()) do SaveRest(p) end end)
timer.Create("LivingCityRestSave", 60, 0, function() for _, p in ipairs(player.GetAll()) do SaveRest(p) end end)
hook.Add("LivingCityNewCharacter", "LivingCityRest", function(ply) ply.lcAwakeSince = CurTime() ply:SetNW2Float("lc_rested_until", 0) SaveRest(ply) end)

-- What now? (sv_livingcity_nextstep.lua)
function LC.RestStep(ply)
    if not cvOn:GetBool() then return nil end
    if LC.IsTired(ply) then
        return { key = "sleep", text = "Get some sleep", why = "You're exhausted: no running, and weaker until you've slept. Find a bed and press E on it.", way = "bed", urgent = true }
    end
    return nil
end

------------------------------------------------------------------------
-- Citizens asleep at home: at curfew, in a lockdown and at night, people
-- go to a free bed in a housing block and sleep on it till morning
-- (sv_livingcity.lua sends them home; this puts them to bed and up again)
------------------------------------------------------------------------

function LC.CitizensSleep() return cvHomeSleep:GetBool() end
function LC.Bedtime() return LC.Event == "curfew" or LC.Event == "lockdown" or LC.IsNight() end

-- A free bed in a housing block zone: the bed (with .key), or nil.
function LC.FreeBedIn(z, who)
    if not z or not LCZ or not LCZ.Contains then return nil end
    local list = {}
    for _, a in ipairs(LC.Amenities and LC.Amenities("bed") or {}) do
        if LCZ.Contains(z, a.pos, 0) then
            a.key = LC.BedKey(a)
            if LC.BedFree(a.key, who) then list[#list + 1] = a end
        end
    end
    if #list == 0 then return nil end
    return list[math.random(#list)]
end

-- Take a bed for this citizen: where to walk to, or nil. Their own block first, then the nearest with one free.
function LC.NPCTakeBed(npc, st, zones)
    if not cvHomeSleep:GetBool() then return nil end
    for _, z in ipairs(zones) do
        local a = LC.FreeBedIn(z, npc)
        local b = a and LC.BedLie(a)
        if b then
            LC.BedSleepers[a.key] = npc
            st.bedKey, st.bedSpot = a.key, b
            return b.stand or b.top, z, b
        end
    end
    return nil
end

-- Arrived at their bed: lie down on it. False if they can't (no lying or sitting animation).
function LC.NPCBedDown(npc, st, now)
    local b = st.bedSpot
    if not b or not LC.NPCLieOnBed then LC.NPCBedUp(npc, st) return false end
    -- where they get up again: the spot beside the bed, on its floor (not wherever they came to a stop)
    local standAt = b.stand or (LC.GroundAt and LC.GroundAt(npc:GetPos())) or npc:GetPos()
    local L = { standAt = standAt }
    if not LC.NPCLieOnBed(npc, L, b) then LC.NPCBedUp(npc, st) return false end
    st.bedL = L
    st.ss = L.ss -- (so it goes with them if they're removed: sv_livingcity.lua)
    st.wakeAt = nil
    LC.SetState(npc, st, "abed")
    npc:SetNW2String("lc_doing", L.asleep and "asleep" or "resting")
    return true
end

-- Up again (or never got there): the bed's free.
function LC.NPCBedUp(npc, st)
    if not st then return end
    local L = st.bedL
    if st.bedKey and LC.BedSleepers[st.bedKey] == npc then LC.BedSleepers[st.bedKey] = nil end
    st.bedKey, st.bedSpot, st.bedL, st.wakeAt = nil, nil, nil, nil
    if not L then return end
    if LC.NPCBedDoubleGone then LC.NPCBedDoubleGone(npc, L) end
    if IsValid(L.ss) then
        L.ss:Fire("CancelSequence")
        SafeRemoveEntityDelayed(L.ss, 0.5)
    end
    if st.ss == L.ss then st.ss = nil end
    if IsValid(npc) then
        if L.gunHidden then local w = npc.GetActiveWeapon and npc:GetActiveWeapon() if IsValid(w) and w.SetNoDraw then w:SetNoDraw(false) end end
        if L.standAt then npc:SetPos(L.standAt + Vector(0, 0, 4)) end -- (up, and off the bed)
        if L.asleep then npc:SetNW2Bool("lc_eyes_shut", false) end
        npc:SetNW2String("lc_doing", "")
        if npc.SetSchedule then npc:SetSchedule(SCHED_IDLE_STAND) end
    end
end

-- In bed: asleep till morning, then up, a few at a time, and out into the day.
function LC.NPCBedThink(npc, st, now)
    if not (st.bedL and (IsValid(st.bedL.ss) or IsValid(st.bedL.double))) then
        LC.NPCBedUp(npc, st)
        LC.SetState(npc, st, "idle")
        st.untilT = now + 2
        return
    end
    if LC.Bedtime() and cvHomeSleep:GetBool() then st.wakeAt = nil return end
    st.wakeAt = st.wakeAt or (now + math.Rand(2, 45))
    if now < st.wakeAt then return end
    LC.NPCBedUp(npc, st)
    st.leaving, st.homeBlock = nil, nil
    LC.SetState(npc, st, "idle")
    st.untilT = now + math.Rand(2, 6)
end

-- Hurt in bed: awake at once.
hook.Add("EntityTakeDamage", "LivingCityBedWake", function(ent, dmg)
    if not IsValid(ent) or not ent:IsNPC() or dmg:GetDamage() <= 0 then return end
    local st = LC.NPCs and LC.NPCs[ent]
    if st and st.state == "abed" then
        LC.NPCBedUp(ent, st)
        st.leaving = nil
        LC.SetState(ent, st, "idle")
        st.untilT = CurTime() + 1
    end
end)
