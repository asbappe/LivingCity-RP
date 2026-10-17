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
    the wanted (already being chased), admins in build mode, rebel territory
    and the curfew grace period (when you're told to hurry home) are exempt.

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

local SHOUTS = { "npc/metropolice/vo/holdit.wav", "npc/metropolice/vo/freeze.wav" }
local CHASE_LINES = { "npc/metropolice/vo/finalwarning.wav", "npc/metropolice/vo/holdit.wav" }

LC.Runners = LC.Runners or {} -- [ply] = { warnedAt, by, ranFor }
local Runners = LC.Runners

-- A shout from a unit: chat, and the words across the middle of the screen.
function LC.CopShout(ply, npc, text, secs)
    if not IsValid(ply) then return end
    local who = IsValid(npc) and npc:GetNW2String("lc_pname", "") or ""
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
    if LC.FoolsSecurity and LC.FoolsSecurity(ply) then return "in a convincing uniform" end
    if LC.PlayerIsZombie and LC.PlayerIsZombie(ply) then return "infested" end
    if LC.PlayerIsWanted(ply) then return "already wanted" end -- already being chased
    if (LC.InCustody and LC.InCustody(ply)) or (LC.Prisoners and LC.Prisoners[ply]) then return "in custody" end
    if LC.Stops and LC.Stops[ply] then return "being stopped" end -- walking off from a stop is handled there
    if ply:GetNW2String("lcf_faction", "") == "admin" or LCF.IsOverwatch(ply) then return "Overwatch or the Administrator" end
    if LC.InRebelZone and LC.InRebelZone(ply:GetPos()) then return "in rebel territory" end
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

local function Chase(ply, cop)
    Runners[ply] = nil
    local pos = IsValid(cop) and cop:GetPos() or ply:GetPos()
    if IsValid(cop) then cop:EmitSound(LC.Pick(CHASE_LINES), 85) end
    LC.CopShout(ply, cop, "I said stop running!", 4)
    ply:ChatPrint("[Civil Protection] You ran from a Civil Protection unit. Units are after you. Press E on one to give yourself up.")
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

hook.Add("PlayerDeath", "LivingCityRunning", function(ply) Runners[ply] = nil end)
hook.Add("PlayerDisconnected", "LivingCityRunning", function(ply) Runners[ply] = nil end)
