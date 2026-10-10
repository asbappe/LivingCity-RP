--[[
    Living City: sleep

    Everyone needs a night's sleep: once in every in-game day (lc_tired_days,
    1, of the city's day length, lc_day_minutes). Go without and you're tired:
    your eyes keep drooping shut, you're a little unsteady on your feet, you
    can't run, and you've 25 less health at most until you sleep.

    Sleep in a bed (E on it: the editor's "Fixture: bed", a bunk point, or any
    bed or mattress the map has, a cell's too) at night, or any time you're
    exhausted. It takes lc_sleep_seconds (60) lying still; get up, or get
    hurt, and you've not slept. A good night leaves you well rested for the
    next in-game day: hunger and thirst come on a quarter more slowly, and
    you slowly heal (a point every ten seconds, up to full).

      lc_sleep 0/1, lc_sleep_seconds (60), lc_tired_days (1)
]]

if CLIENT then return end

LC = LC or {}

local FLAGS = bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED)
local cvOn   = CreateConVar("lc_sleep", "1", FLAGS, "People need sleep: tired after a day without it, well rested after a night in a bed")
local cvSecs = CreateConVar("lc_sleep_seconds", "60", FLAGS, "Seconds it takes to sleep in a bed")
local cvDays = CreateConVar("lc_tired_days", "1", FLAGS, "In-game days awake before you're tired")

local TIRED_HP = 25

local function DayLen() return math.max(60, GetGlobal2Float("lc_day_len", 1440)) end
local function Notice(ply, kind, title, text, secs) if LC.Notice then LC.Notice(ply, kind, title, text, secs) else ply:ChatPrint(title .. ": " .. text) end end
local function Exempt(ply) return not ply:Alive() or (LC.PlayerIsZombie and LC.PlayerIsZombie(ply)) or ply:GetNW2String("lcf_faction", "") == "admin" end

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

-- Find a bed where they're looking, or the nearest one within reach.
local function BedAt(ply, ent)
    if IsValid(ent) and (ent:GetClass() == "lc_bed" or (LC.AmenityKindOf and LC.AmenityKindOf(ent) == "bed")) then return ent:GetPos() end
    local best, bd
    for _, a in ipairs(LC.Amenities and LC.Amenities("bed") or {}) do
        local d = a.pos:DistToSqr(ply:GetPos())
        if d < 110 * 110 and (not bd or d < bd) then best, bd = a.pos, d end
    end
    return best
end
LC.BedNear = BedAt

-- Sleep in a bed. True, or false and why not.
function LC.SleepIn(ply, ent)
    if not cvOn:GetBool() or not IsValid(ply) or not ply:Alive() then return false end
    if not BedAt(ply, ent) then return false, "There's no bed here." end
    if not LC.IsNight() and not LC.IsTired(ply) then return false, "You're not tired, and it's broad daylight. Beds are for the night (or when you're exhausted)." end
    if LC.IsRested(ply) and not LC.IsTired(ply) then return false, "You slept already. You couldn't sleep again if you tried." end
    if not LC.StartTask then return false end
    ply:SetNW2Bool("lc_sleeping", true)
    local ok, why = LC.StartTask(ply, cvSecs:GetFloat(), "Sleeping...", {
        maxMove = 60, cancelText = "You get up before you've really slept.",
        cancel = function(p) if IsValid(p) then p:SetNW2Bool("lc_sleeping", false) end end,
        done = function(p)
            if not IsValid(p) then return end
            p:SetNW2Bool("lc_sleeping", false)
            p.lcAwakeSince = CurTime()
            p:SetNW2Bool("lc_tired", false)
            TiredHealth(p, false)
            p:SetNW2Float("lc_rested_until", CurTime() + DayLen())
            Notice(p, "info", "Well rested", "A night's sleep. For the next day: hunger and thirst come on more slowly, and you heal a little.", 8)
            hook.Run("LivingCitySlept", p)
        end,
    })
    if not ok then ply:SetNW2Bool("lc_sleeping", false) end
    return ok, why
end

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
            if LC.IsRested(ply) and (ply.lcRestHeal or 0) <= now and ply:Health() < ply:GetMaxHealth() then
                ply.lcRestHeal = now + 10
                ply:SetHealth(math.min(ply:GetMaxHealth(), ply:Health() + 1))
            end
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
    if not ply.lcAwakeSince then ply.lcAwakeSince = CurTime() end
end)
hook.Add("LivingCityNewCharacter", "LivingCityRest", function(ply) ply.lcAwakeSince = CurTime() ply:SetNW2Float("lc_rested_until", 0) end)

-- What now? (sv_livingcity_nextstep.lua)
function LC.RestStep(ply)
    if not cvOn:GetBool() then return nil end
    if LC.IsTired(ply) then
        return { key = "sleep", text = "Get some sleep", why = "You're exhausted: no running, and weaker until you've slept. Find a bed and press E on it.", way = "bed", urgent = true }
    end
    return nil
end
