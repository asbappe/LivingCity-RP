--[[
    Living City: noise, and the unit who comes to look

    One rule for every noise (the owner, 25 November: after reading how the
    Jeff bot hears). Something makes a noise somewhere, this loud; the nearest
    Civil Protection unit free to leave what it is doing, near enough to hear
    it, walks to about where it came from, looks round for a moment and goes
    back to its rounds. It is not sure of the spot: it arrives near, not on it.
    A louder noise takes it off a quieter one.

    What makes a noise:
      running     during a curfew, outside the habitation blocks only (the
                  owner, 26 November): heard through walls (a unit who can
                  SEE you running shouts instead: sv_livingcity_running.lua)
      jumping     the same, a little nearer
      a thrown thing landing (what you threw with E or the gravity gun):
                  throw a can down an alley and the unit goes there
      a shot      a player's gunfire

    Walking and crouching make none: that is how you get past a patrol
    after curfew. At any other time, and inside any habitation block, running
    and jumping bring nobody.

    Units on a post (a door, a checkpoint, a lane, a zone's guard), in a fight,
    escorting, in a raid or walking somewhere on an errand do not leave for a noise. Civil Protection players,
    people in a convincing uniform, build mode, rebel territory and the curfew
    grace period make none that counts (the running rule's own exemptions).

      lc_noise        1 on, 0 off
      lc_noise_run    how far running carries (450)
      lc_noise_jump   how far a jump carries (350)
      lc_noise_max    the farthest any noise carries (1500)
]]

if CLIENT then return end

LC = LC or {}

local FLAGS = bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED)
local cvOn   = CreateConVar("lc_noise", "1", FLAGS, "Civil Protection units hear running, jumping, thrown things and shots, and one comes to look")
local cvRun  = CreateConVar("lc_noise_run", "450", FLAGS, "How far the sound of running carries to a unit")
local cvJump = CreateConVar("lc_noise_jump", "350", FLAGS, "How far the sound of a jump carries to a unit")
local cvMax  = CreateConVar("lc_noise_max", "1500", FLAGS, "The farthest any noise carries to a unit")

local OFF_BY    = 60  -- how wrong a unit may be about where the noise was
local LOOK_SECS = 3   -- looking round once there
local GIVE_UP   = 20  -- seconds to get there before it shrugs and goes back
local REST      = 25  -- seconds before the same unit goes after another noise as quiet
local LOUDER    = 1.2 -- a noise this much louder takes a unit off the one it is after

-- How far a sound carries, from the engine's own sound level and volume
-- (a dropped can: about 800; a shot: over 1000), never past lc_noise_max.
function LC.NoiseRange(level, volume)
    local r = 0.5 * ((level or 75) + 400 + (volume or 1) * 1600)
    return math.min(r, cvMax:GetFloat())
end

-- May this unit leave what it is doing for a noise?
local FREE = { idle = true, moving = true }
function LC.NoiseUnitFree(npc, st, now)
    if not IsValid(npc) or st.role ~= "cop" or st.test or st.questLock or st.subject then return false end
    if st.raid or st.skirmish or st.workEscort or st.doorPost or st.guardZone or st.holdPos or st.lane then return false end
    if not FREE[st.state or ""] then return false end
    -- on the way somewhere: only from its own rounds (no errand, or a guard's spot), never off an errand
    if st.state == "moving" and st.poi and not (st.heard and st.poi == st.heard.poi) and st.poi.kind ~= "guard" then return false end
    if st.leaving then return false end
    return npc:Health() > 0
end

-- A noise at pos that carries range units, made by maker (may be nil).
-- seen = true: a unit who can see the maker does not count (it has eyes for that).
-- Returns the unit that set off to look, or nil.
function LC.Noise(pos, range, maker, seen, now)
    if not cvOn:GetBool() or not pos or not LC.GoTo then return nil end
    now = now or CurTime()
    range = math.min(range or 0, cvMax:GetFloat())
    if range <= 0 then return nil end
    local eye = seen and IsValid(maker) and maker.EyePos and maker:EyePos() or nil
    local best, bd = nil, nil
    for npc, st in pairs(LC.NPCs or {}) do
        if LC.NoiseUnitFree(npc, st, now) then
            local busy = st.heard and st.heard.range * LOUDER > range
            local resting = not st.heard and (st.heardNext or 0) > now
            local d = npc:GetPos():DistToSqr(pos)
            if not busy and not resting and d < range * range and (not bd or d < bd) then
                if not (eye and LC.LineOfSight and LC.LineOfSight(npc:EyePos(), eye, npc)) then best, bd = npc, d end
            end
        end
    end
    if not best then return nil end
    local st = LC.NPCs[best]
    local spot = pos + Vector(math.Rand(-OFF_BY, OFF_BY), math.Rand(-OFF_BY, OFF_BY), 0)
    local poi = { kind = "noise", pos = spot }
    local fresh = not st.heard
    if st.state ~= "idle" and LC.AbandonTask then LC.AbandonTask(best, st, now) end
    if not LC.GoTo(best, st, spot, false, poi) then st.heard = nil return nil end
    st.heard = { poi = poi, range = range, untilT = now + GIVE_UP }
    if fresh then best:EmitSound("npc/metropolice/vo/investigating10-103.wav", 75) end
    LC.NoiseStats.went = LC.NoiseStats.went + 1
    return best
end
LC.NoiseStats = LC.NoiseStats or { went = 0, found = 0, gaveUp = 0 }

-- There: a look round, then back to its rounds.
LC.ArriveHandlers = LC.ArriveHandlers or {}
LC.ArriveHandlers.noise = function(npc, st, now, poi)
    if not st.heard or st.heard.poi ~= poi then return false end
    st.heard, st.poi = nil, nil
    st.heardNext = now + REST
    st.untilT = now + LOOK_SECS
    if SCHED_ALERT_SCAN and npc.SetSchedule then npc:SetSchedule(SCHED_ALERT_SCAN) end
    LC.NoiseStats.found = LC.NoiseStats.found + 1
    return true
end

-- Whose noise does not count (the running rule's list; the wanted are still heard).
local function Quiet(ply)
    if not IsValid(ply) or not ply:IsPlayer() then return true end
    if LC.RunningExemptWhy then return LC.RunningExemptWhy(ply, true) ~= nil end
    return not ply:Alive() or (LC.PlayerIsCP and LC.PlayerIsCP(ply)) or false
end
LC.NoiseQuiet = Quiet

-- Do this player's steps count? Only during a curfew, outside every habitation block
-- (the owner, 26 November: "we don't want running or jumping to draw a CP unless it's
-- outside a habitation block during curfew").
function LC.NoiseStepsCount(ply)
    if LC.Event ~= "curfew" then return false end
    local pos = ply:GetPos()
    for _, z in ipairs(LC.ZonesOfKind and LC.ZonesOfKind("block") or {}) do
        if LCZ.Contains(z, pos, LCZ.Mercy()) then return false end
    end
    return true
end

-- A player's own noise (running, a jump), no more than one every few seconds.
function LC.PlayerNoise(ply, range, now)
    now = now or CurTime()
    if (ply.lcNoiseAt or 0) > now or not LC.NoiseStepsCount(ply) or Quiet(ply) then return nil end
    ply.lcNoiseAt = now + 3
    return LC.Noise(ply:GetPos(), range, ply, true, now)
end

-- Every half second: who is running, and who has been too long getting to a noise.
function LC.NoiseTick(now)
    if not cvOn:GetBool() then return end
    for npc, st in pairs(LC.NPCs or {}) do
        local h = st.heard
        if h then
            if not IsValid(npc) or st.poi ~= h.poi or st.state ~= "moving" then
                st.heard = nil -- (something else took it: a fight, an order, a dead end)
            elseif now > h.untilT then
                st.heard = nil
                st.heardNext = now + REST
                if LC.AbandonTask then LC.AbandonTask(npc, st, now) end
                LC.NoiseStats.gaveUp = LC.NoiseStats.gaveUp + 1
            end
        end
    end
    if not LC.PlayerSprinting or LC.Event ~= "curfew" then return end
    for _, ply in ipairs(player.GetAll()) do
        if (ply.lcNoiseAt or 0) <= now and LC.PlayerSprinting(ply) then LC.PlayerNoise(ply, cvRun:GetFloat(), now) end
    end
end

timer.Create("LivingCityNoise", 0.5, 0, function()
    if not LC.Running then return end
    local ok, err = LC.Try(LC.NoiseTick, CurTime())
    if not ok and LC.Error then LC.Error("noise", err) end
end)

-- A jump (from the ground: not a second press in the air).
hook.Add("KeyPress", "LivingCityNoise", function(ply, key)
    if key ~= IN_JUMP or not LC.Running or not cvOn:GetBool() then return end
    if not IsValid(ply) or not ply:IsOnGround() or ply:InVehicle() then return end
    local ok, err = LC.Try(LC.PlayerNoise, ply, cvJump:GetFloat())
    if not ok and LC.Error then LC.Error("noise jump", err) end
end)

-- A shot.
hook.Add("EntityFireBullets", "LivingCityNoise", function(ent, data)
    if not LC.Running or not cvOn:GetBool() or not IsValid(ent) or not ent:IsPlayer() then return end
    local now = CurTime()
    if (ent.lcShotNoiseAt or 0) > now or Quiet(ent) then return end
    ent.lcShotNoiseAt = now + 3
    local ok, err = LC.Try(LC.Noise, data and data.Src or ent:GetPos(), LC.NoiseRange(140, 1), ent, true, now)
    if not ok and LC.Error then LC.Error("noise shot", err) end
end)

-- A thrown thing landing. Who threw it: the engine's own carry with E
-- (sv_livingcity_jobgames.lua keeps lcDroppedAt and lcThrown) or the gravity gun.
hook.Add("GravGunPunt", "LivingCityNoise", function(ply, ent)
    if IsValid(ent) then ent.lcDroppedAt, ent.lcThrown, ent.lcThrownBy = CurTime(), true, ply end
end)
hook.Add("GravGunOnDropped", "LivingCityNoise", function(ply, ent)
    if IsValid(ent) then ent.lcDroppedAt, ent.lcThrown, ent.lcThrownBy = CurTime(), true, ply end
end)

-- Was this sound a thing a player threw, landing? Returns how far it carries, or nil.
function LC.ThrownLanding(data, now)
    local ent = data and data.Entity
    if not IsValid(ent) or not ent.lcThrown or not ent.lcDroppedAt then return nil end
    if now - ent.lcDroppedAt > 6 or now - ent.lcDroppedAt < 0.15 then return nil end
    local name = string.lower((data.OriginalSoundName or "") .. " " .. (data.SoundName or ""))
    if not string.find(name, "impact", 1, true) and not string.find(name, "physics", 1, true) then return nil end
    if (data.Volume or 1) < 0.3 then return nil end
    return LC.NoiseRange(data.SoundLevel, data.Volume)
end

hook.Add("EntityEmitSound", "LivingCityNoise", function(data)
    local ent = data and data.Entity
    if not ent or not ent.lcThrown or not LC.Running or not cvOn:GetBool() then return end
    local now = CurTime()
    local range = LC.ThrownLanding(data, now)
    if not range then return end
    ent.lcThrown = nil -- (the first landing only: not every bounce)
    local by = ent.lcThrownBy
    if IsValid(by) and Quiet(by) then return end
    local ok, err = LC.Try(LC.Noise, data.Pos or ent:GetPos(), range, nil, false, now)
    if not ok and LC.Error then LC.Error("noise thrown", err) end
end)
