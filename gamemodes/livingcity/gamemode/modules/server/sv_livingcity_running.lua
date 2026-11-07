--[[
    Living City: running in front of Civil Protection

    Running is suspicious. A metrocop who sees you sprinting nearby shouts at
    you to stop: you hear it, it's in chat with his name, and it flashes up
    in the middle of your screen. Stop, and that's the end of it. Keep
    running (after a moment to react), or start running again in front of a
    unit while he still remembers you, and Civil Protection comes after you:
    you're wanted for fleeing, and the units nearby give chase. Walk up to
    one and press E to give yourself up, as with any other charge.

    Units, people in a convincing uniform, the infested, people in custody,
    the wanted (already being chased), admins in build mode, rebel territory,
    the infestation zone (nobody is told to walk there) and the curfew grace
    period (when you're told to hurry home) are exempt.

    Caught, the first and second time in an hour, you're not jailed (the
    owner, 7 November): the unit cuffs you, gives you a few of the stick for
    disobeying, then takes the cuffs off with a laugh and "All right, you can
    go." No standing lost. The third time within the hour it's the cells, as
    for any other charge.

      lc_running_cops     1 on, 0 off
      lc_run_range        how close a unit has to be to notice (500)
      lc_run_react        seconds you get to stop after the shout (2)
      lc_run_memory       seconds a unit remembers warning you (30)
      lc_run_wanted       seconds wanted for fleeing (60)
]]

if CLIENT then return end

LC = LC or {}

local FLAGS = bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED)
local cvOn     = CreateConVar("lc_running_cops", "1", FLAGS, "Metrocops shout at people running near them, and chase them if they don't stop")
local cvRange  = CreateConVar("lc_run_range", "500", FLAGS, "How close a metrocop has to be to notice you running")
local cvReact  = CreateConVar("lc_run_react", "2", FLAGS, "Seconds to stop running after a metrocop shouts at you")
local cvMemory = CreateConVar("lc_run_memory", "30", FLAGS, "Seconds a metrocop remembers telling you to stop running")
local cvWanted = CreateConVar("lc_run_wanted", "60", FLAGS, "Seconds wanted for running from Civil Protection")

local SHOUTS = { "npc/metropolice/vo/holdit.wav", "npc/metropolice/vo/dontmove.wav" }
local CHASE_LINES = { "npc/metropolice/vo/finalwarning.wav", "npc/metropolice/vo/holdit.wav" }

LC.Runners = LC.Runners or {} -- [ply] = { warnedAt, by, ranFor }
local Runners = LC.Runners

-- A shout from a unit: chat, and the words across the middle of the screen.
function LC.CopShout(ply, npc, text, secs)
    if not IsValid(ply) then return end
    local who = IsValid(npc) and LC.NPCStr(npc, "lc_pname", "") or ""
    ply:ChatPrint("[Civil Protection] " .. (who ~= "" and ("Unit " .. who .. ": ") or "") .. text)
    ply:SetNW2String("lc_shout", string.upper(text))
    ply:SetNW2Float("lc_shout_until", CurTime() + (secs or 3))
end

-- Sprinting: holding the sprint key and actually moving, or plainly faster
-- than walking pace. Measured against this player's own speeds, so slower
-- movement settings (lc_walk_speed 110, lc_run_speed 190) still count: the
-- gap between a walk and a run is small, and a bare speed check sat too close
-- to it.
local function Speed(ply)
    local v = ply:GetVelocity()
    return math.sqrt(v.x * v.x + v.y * v.y)
end

local cvWalk
local function Running(ply)
    -- broken feet can't run, whatever the sprint key says (it counts again once they heal)
    if LC.IsCrippled and LC.IsCrippled(ply) then return false end
    if not ply:IsOnGround() or ply:Crouching() or ply:WaterLevel() >= 2 then return false end
    cvWalk = cvWalk or GetConVar("lc_walk_speed")
    local cv = cvWalk
    local walk = ply.GetWalkSpeed and ply:GetWalkSpeed() or 0
    if not walk or walk <= 0 then walk = cv and cv:GetFloat() or 110 end
    local run = ply.GetRunSpeed and ply:GetRunSpeed() or 0
    if not run or run <= walk then run = walk * 1.6 end
    local speed = Speed(ply)
    if ply.KeyDown and ply:KeyDown(IN_SPEED) and speed > walk * 0.9 then return true end
    return speed > (walk + run) / 2
end
LC.PlayerSprinting = Running

-- Why the cops wouldn't shout at this player, or nil if they would.
local function ExemptWhy(ply)
    if not ply:Alive() or ply:InVehicle() then return "dead or in a vehicle" end
    if ply:GetNW2Bool("lc_build", false) then return "build mode" end
    if LC.PlayerIsCP(ply) then return "a Civil Protection unit" end
    if LC.PlayerIsStalker and LC.PlayerIsStalker(ply) then return "a stalker (Combine property)" end
    if LC.FoolsSecurity and LC.FoolsSecurity(ply) then return "in a convincing uniform" end
    if LC.PlayerIsZombie and LC.PlayerIsZombie(ply) then return "infested" end
    if LC.PlayerIsWanted(ply) then return "already wanted" end -- already being chased
    if (LC.InCustody and LC.InCustody(ply)) or (LC.Prisoners and LC.Prisoners[ply]) then return "in custody" end
    if LC.Stops and LC.Stops[ply] then return "being stopped" end -- walking off from a stop is handled there
    if ply:GetNW2String("lcf_faction", "") == "admin" or LCF.IsOverwatch(ply) then return "Overwatch or the Administrator" end
    if LC.InRebelZone and LC.InRebelZone(ply:GetPos()) then return "in rebel territory" end
    if LC.InInfest and LC.InInfest(ply:GetPos()) then return "in the infestation zone" end -- (the owner, 7 November: you run for your life there)
    -- told to hurry home: running is what they want
    if (LC.Event == "curfew" or LC.Event == "lockdown") and (LC.EventGraceEnds or 0) > CurTime() then return "curfew grace period" end
    return nil
end
local function Exempt(ply) return ExemptWhy(ply) ~= nil end

-- The nearest metrocop on the street who can see ply.
local function Watcher(ply)
    local r = cvRange:GetFloat()
    local best, bd
    local eye = ply:EyePos()
    for npc, st in pairs(LC.NPCs or {}) do
        if IsValid(npc) and st.role == "cop" and not st.test and not st.questLock and st.state ~= "hostile" and not st.workEscort then
            local d = npc:GetPos():DistToSqr(ply:GetPos())
            if d < r * r and (not bd or d < bd) then
                if LC.LineOfSight(npc:EyePos(), eye, npc) then best, bd = npc, d end
            end
        end
    end
    return best
end

-- For the debug report: would a unit shout at this player right now, and if not, why not.
function LC.RunningStatus(ply)
    if not cvOn:GetBool() then return "off (lc_running_cops 0)" end
    if not LC.Running then return "city not running" end
    local why = ExemptWhy(ply)
    local cop = Watcher(ply)
    local walk = ply.GetWalkSpeed and ply:GetWalkSpeed() or 0
    local run = ply.GetRunSpeed and ply:GetRunSpeed() or 0
    return string.format("speed %d (walk %d, run %d)%s, %s, %s", Speed(ply), walk, run,
        Running(ply) and " sprinting" or "", why and ("exempt: " .. why) or "not exempt",
        IsValid(cop) and ("Civil Protection unit watching at " .. math.floor(cop:GetPos():Distance(ply:GetPos()))) or ("no Civil Protection unit in sight within " .. cvRange:GetInt()))
end

-- Running offences in the last hour (the chases that started), newest kept.
LC.RunOffences = LC.RunOffences or {} -- [ply] = { CurTime, ... }
function LC.RunningOffences(ply)
    local list, now, n = LC.RunOffences[ply], CurTime(), 0
    if not list then return 0 end
    for i = #list, 1, -1 do
        if now - list[i] <= 3600 then n = n + 1 else table.remove(list, i) end
    end
    return n
end
local function CountOffence(ply)
    local list = LC.RunOffences[ply] or {}
    LC.RunOffences[ply] = list
    list[#list + 1] = CurTime()
    while #list > 6 do table.remove(list, 1) end
    return LC.RunningOffences(ply)
end

local function Chase(ply, cop)
    Runners[ply] = nil
    local n = CountOffence(ply)
    local pos = IsValid(cop) and cop:GetPos() or ply:GetPos()
    if IsValid(cop) then cop:EmitSound(LC.Pick(CHASE_LINES), 85) end
    LC.CopShout(ply, cop, "I said stop running!", 4)
    ply:ChatPrint("[Civil Protection] You ran from a Civil Protection unit. Units are after you. Press E on one to give yourself up.")
    if n >= 3 then ply:ChatPrint("[Civil Protection] That's the third time this hour. This time it's the cells.") end
    LC.ReportCrime(ply, "Fleeing Civil Protection", cvWanted:GetFloat())
    LC.MakeCopsHostile(ply, pos, 1500)
end

local function Warn(ply, cop, now)
    if LC.Hint then LC.Hint(ply, "running") end
    Runners[ply] = { warnedAt = now, by = cop, ranFor = 0 }
    LC.Face(cop, ply:GetPos())
    cop:EmitSound(LC.Pick(SHOUTS), 85)
    LC.CopShout(ply, cop, "Stop running!", 3)
end

-- Caught for running, the first or second time in an hour: cuffed, a few of the stick, and let
-- go with a laugh (sv_livingcity_prison.lua asks before anyone is locked up or detained).
-- True when this took the place of an arrest.
LC.RoughingUp = LC.RoughingUp or {} -- [ply] = true while it happens
local BLOWS = 3
function LC.RunningBeating(unit, ply, reason)
    if not IsValid(ply) or not ply:IsPlayer() or not ply:Alive() then return false end
    if tostring(reason or "") ~= "Fleeing Civil Protection" then return false end
    if LC.RoughingUp[ply] or (LC.InCustody and LC.InCustody(ply)) then return false end
    if LC.RunningOffences(ply) >= 3 then return false end -- (the third time this hour: the cells)
    LC.RoughingUp[ply] = true
    Runners[ply] = nil
    if LC.ClearWanted then LC.ClearWanted(ply) end
    if LC.CalmCops then LC.CalmCops(ply) end
    local st = IsValid(unit) and LC.NPCs and LC.NPCs[unit]
    if st and LC.SetState then
        LC.SetState(unit, st, "event")
        st.eventUntil = CurTime() + 10
        if unit.SetSchedule and SCHED_IDLE_STAND then unit:SetSchedule(SCHED_IDLE_STAND) end
        LC.Face(unit, ply:GetPos())
        unit:EmitSound(LC.Pick(LC.Sounds and LC.Sounds.COP_ARREST or SHOUTS), 78)
    end
    if ply:InVehicle() then ply:ExitVehicle() end
    local tied = LC.TiePlayer and LC.TiePlayer(ply, nil)
    ply:Freeze(true)
    ply:ChatPrint("[Civil Protection] Cuffed. The unit has a few words, and the stick, for someone who runs when told to stop.")
    if LC.Notice then LC.Notice(ply, "warn", "Caught running", "You're cuffed for a moment. Run from a unit three times in an hour and it's the cells.", 6) end
    local function Alive() return IsValid(ply) and ply:Alive() and LC.RoughingUp[ply] end
    local function Done()
        LC.RoughingUp[ply] = nil
        if not IsValid(ply) then return end
        ply:Freeze(false)
        if tied and LC.IsTied and LC.IsTied(ply) then LC.Untie(ply, unit, true) end
        ply.lcGraceUntil = CurTime() + 60
        if ply:Alive() then
            ply:ChatPrint("[Civil Protection] The cuffs come off. \"All right, you can go.\" A warning, this time: a third time in the hour is the cells.")
        end
        if IsValid(unit) then
            unit:EmitSound("npc/metropolice/vo/allrightyoucango.wav", 78)
            local ust = LC.NPCs and LC.NPCs[unit]
            if ust and ust.state == "event" then ust.eventUntil = CurTime() + 1 end
        end
    end
    for i = 1, BLOWS do
        timer.Simple(1.2 + (i - 1) * 1.3, function()
            if not Alive() then return end
            if IsValid(unit) then
                LC.Face(unit, ply:GetPos())
                if unit.SetSchedule and SCHED_MELEE_ATTACK1 then unit:SetSchedule(SCHED_MELEE_ATTACK1) end
                unit:EmitSound("weapons/stunstick/stunstick_impact" .. math.random(1, 2) .. ".wav", 75)
            end
            local d = DamageInfo and DamageInfo()
            if d then
                d:SetDamage(math.min(8, math.max(0, ply:Health() - 15))) -- (never past the point of dropping them)
                d:SetDamageType(DMG_CLUB)
                if IsValid(unit) then d:SetAttacker(unit) d:SetInflictor(unit) end
                ply.lcSubdueHit = true
                ply:TakeDamageInfo(d)
                ply.lcSubdueHit = nil
            end
            ply:SetNW2Float("lc_dazed_until", CurTime() + 2)
            if ply.ViewPunch then ply:ViewPunch(Angle(math.random(6, 10), math.random(-6, 6), 0)) end
        end)
    end
    timer.Simple(1.2 + BLOWS * 1.3, function()
        if not Alive() then return end
        if IsValid(unit) then unit:EmitSound("npc/metropolice/vo/chuckle.wav", 78) end
    end)
    timer.Simple(2.4 + BLOWS * 1.3, function() if LC.RoughingUp[ply] then Done() end end)
    return true
end

function LC.RunningTick(now, dt)
    for ply, r in pairs(Runners) do
        if not IsValid(ply) or now - r.warnedAt > cvMemory:GetFloat() then Runners[ply] = nil end
    end
    if not cvOn:GetBool() then return end
    for _, ply in ipairs(player.GetAll()) do
        local r = Runners[ply]
        -- sprinting is cheap to check; why someone might be let off isn't, so it comes second
        if not (ply:Alive() and Running(ply)) then
            if r then r.ranFor = 0 end
        elseif not Exempt(ply) then
            local cop = Watcher(ply)
            if r and now - r.warnedAt > cvReact:GetFloat() then
                -- told to stop, and still running: from the one who shouted, or anyone else watching
                if cop or (IsValid(r.by) and r.by:GetPos():DistToSqr(ply:GetPos()) < (cvRange:GetFloat() * 2) ^ 2) then
                    r.ranFor = r.ranFor + dt
                    if r.ranFor >= 1 then Chase(ply, cop or r.by) end
                end
            elseif not r and cop then
                Warn(ply, cop, now)
            end
        end
    end
end

local last = 0
timer.Create("LivingCityRunning", 0.5, 0, function()
    if not LC.Running then return end
    local now = CurTime()
    local dt = last > 0 and math.min(now - last, 1) or 0.5
    last = now
    local ok, err = pcall(LC.RunningTick, now, dt)
    if not ok and LC.Error then LC.Error("running", err) end
end)

hook.Add("PlayerDeath", "LivingCityRunning", function(ply)
    Runners[ply] = nil
    if LC.RoughingUp[ply] then LC.RoughingUp[ply] = nil ply:Freeze(false) end
end)
hook.Add("PlayerDisconnected", "LivingCityRunning", function(ply) Runners[ply] = nil LC.RoughingUp[ply] = nil LC.RunOffences[ply] = nil end)
