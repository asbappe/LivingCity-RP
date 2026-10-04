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
local EXEMPT_FACTIONS = { ota = true, admin = true }

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

local function Running(ply)
    if not ply:IsOnGround() or ply:Crouching() or ply:WaterLevel() >= 2 then return false end
    local walk = GetConVar("lc_walk_speed")
    local limit = (walk and walk:GetFloat() or 110) * 1.25
    local v = ply:GetVelocity()
    return v.x * v.x + v.y * v.y > limit * limit
end

local function Exempt(ply)
    if not ply:Alive() or ply:InVehicle() then return true end
    if ply:GetNW2Bool("lc_build", false) then return true end
    if LC.PlayerIsCP(ply) or (LC.FoolsSecurity and LC.FoolsSecurity(ply)) then return true end
    if LC.PlayerIsZombie and LC.PlayerIsZombie(ply) then return true end
    if LC.PlayerIsWanted(ply) then return true end -- already being chased
    if (LC.InCustody and LC.InCustody(ply)) or (LC.Prisoners and LC.Prisoners[ply]) then return true end
    if LC.Stops and LC.Stops[ply] then return true end -- walking off from a stop is handled there
    if LC.FactionsActive and LC.FactionsActive() and EXEMPT_FACTIONS[ply:GetNW2String("lcf_faction", "")] then return true end
    if LC.InRebelZone and LC.InRebelZone(ply:GetPos()) then return true end
    -- told to hurry home: running is what they want
    if (LC.Event == "curfew" or LC.Event == "lockdown") and (LC.EventGraceEnds or 0) > CurTime() then return true end
    return false
end

-- The nearest metrocop on the street who can see ply.
local function Watcher(ply)
    local r = cvRange:GetFloat()
    local best, bd
    local eye = ply:EyePos()
    for npc, st in pairs(LC.NPCs or {}) do
        if IsValid(npc) and st.role == "cop" and not st.test and not st.questLock and st.state ~= "hostile" then
            local d = npc:GetPos():DistToSqr(ply:GetPos())
            if d < r * r and (not bd or d < bd) then
                local tr = util.TraceLine({ start = npc:EyePos(), endpos = eye, mask = MASK_OPAQUE, filter = npc })
                if tr.Fraction > 0.97 then best, bd = npc, d end
            end
        end
    end
    return best
end

local function Chase(ply, cop)
    Runners[ply] = nil
    local pos = IsValid(cop) and cop:GetPos() or ply:GetPos()
    if IsValid(cop) then cop:EmitSound(LC.Pick(CHASE_LINES), 85) end
    LC.CopShout(ply, cop, "I said stop running!", 4)
    ply:ChatPrint("[Civil Protection] You ran from a unit. Units are after you. Press E on one to give yourself up.")
    LC.ReportCrime(ply, "Fleeing Civil Protection", cvWanted:GetFloat())
    LC.MakeCopsHostile(ply, pos, 1500)
end

local function Warn(ply, cop, now)
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
        if not Exempt(ply) then
            local r = Runners[ply]
            if Running(ply) then
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
            elseif r then
                r.ranFor = 0
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
