--[[
    Living City: the Combine's mounted gun on its barricade (server and client)

    The owner, 21 November: "there is a useable combine barricade with a mounted turret on top close
    to that double gate [in Valve's canals], can that be an entity in the editor?" It is Valve's
    turret_1 in d1_canals_07: a func_tank steering the bunker gun's own aim (its pose parameters),
    between two short Combine barricades, a Metrocop standing behind it. The entity, and where its
    barricades stand: entities/lc_turret.lua (editor kind mounted_gun).

    As Valve's: press E on it from behind (where Valve's control volume was) to man it. The gunner
    stays put, their own weapon is put away and can't fire, the gun turns toward the spot under
    their crosshair (up to 60 degrees either way across and 60 up and down, 200 and 120 degrees a
    second, slowing as it closes in), and holding attack fires it: 15 rounds a second from the
    muzzle in a small cone, AR2 tracers, the muzzle flash and Valve's sound. Every bullet is the
    gunner's (the attacker; the gun is the inflictor), so the city's laws, kills and sides see who
    shot. E again, a jump, dying, being knocked off it or the gun going lets go. It unfolds when
    someone takes it and folds up when they leave, as Valve's does.

    Who may man it is one function, LC.TurretMayUse: anyone, as the rebels take the Combine's guns
    in Half-Life 2 (the owner, 21 November: "anyone can use the gun").
]]

LC = LC or {}
local T = LC.Turret or {}
LC.Turret = T

T.CLASS = "lc_turret"
-- Valve's numbers (d1_canals_07, turret_1), and the owner's
T.DAMAGE = 26 / 3        -- about 9 a bullet: Valve's 26, cut to a third at the owner's asking (21 November: "cut that damage down to 1/3")
T.RATE = 15              -- rounds a second (firerate)
T.SPREAD = 0.025         -- the "small cone" (firespread 1)
T.YAW_RANGE = 60         -- degrees either way across its facing (yawrange)
T.PITCH_RANGE = 60       -- degrees up and down (pitchrange)
T.YAW_RATE = 200         -- degrees a second (yawrate)
T.PITCH_RATE = 120       -- degrees a second (pitchrate)
T.PITCH_CENTER = 7.5     -- the model's aim_pitch that holds the barrel level (gun_pitch_pose_center)
T.PIVOT = Vector(-2, 0, 13) -- where it turns, from the gun's foot (Valve's func_tank, from its gun)
T.BARREL = 26.27         -- the muzzle, from where it turns (the model's own "muzzle")
-- Where the gunner stands, from the gun's foot (x ahead, y to its left, z up; the floor is 33 below):
-- Valve's control volume behind the gun, as a player standing in it touches it
T.STAND = { back = 101, front = 12, side = 64, low = -60, high = 0 }
T.REACH = 110            -- how far E reaches it
T.SLIP = 36              -- knocked further than this from where they stood, and they let go
T.FIRE_RELAY = IN_BULLRUSH or 4194304 -- (a key nothing uses: a gunner's click reaches the server on it, never their own weapon)

-- (everything here is upright: the gun only ever turns about the vertical)
local function Turn(yaw, x, y)
    local r = math.rad(yaw)
    local c, s = math.cos(r), math.sin(r)
    return x * c - y * s, x * s + y * c
end
local function Norm(a) return (a + 180) % 360 - 180 end

-- A point given from the gun's foot (x ahead, y to its left, z up), in the world.
function T.ToWorld(gun, x, y, z)
    local wx, wy = Turn(gun:GetAngles().y, x, y)
    local p = gun:GetPos()
    return Vector(p.x + wx, p.y + wy, p.z + z)
end
-- A point in the world, from the gun's foot: x, y, z.
function T.ToLocal(gun, pos)
    local d = pos - gun:GetPos()
    local x, y = Turn(-gun:GetAngles().y, d.x, d.y)
    return x, y, d.z
end
-- The way a yaw and a pitch point (degrees; pitch down positive, as the game's).
function T.Dir(yaw, pitch)
    local y, p = math.rad(yaw), math.rad(pitch)
    return Vector(math.cos(p) * math.cos(y), math.cos(p) * math.sin(y), -math.sin(p))
end
function T.Clamp(yaw, pitch)
    return math.Clamp(yaw, -T.YAW_RANGE, T.YAW_RANGE), math.Clamp(pitch, -T.PITCH_RANGE, T.PITCH_RANGE)
end

-- Where a gunner looking from `eye` along `dir` wants the barrel: its yaw (left positive) and pitch
-- (down positive) from the gun's own facing, within its reach. As Valve's, it aims at the spot under
-- the crosshair, not merely the same way, so the bullets go where they look.
function T.AimFrom(gun, eye, dir, ignore)
    local target = eye + dir * 8192
    local tr = util.TraceLine({ start = eye + dir * 24, endpos = target, mask = MASK_SHOT, filter = ignore })
    if tr and tr.Hit and tr.HitPos then target = tr.HitPos end
    local d = target - T.ToWorld(gun, T.PIVOT.x, T.PIVOT.y, T.PIVOT.z)
    if d:LengthSqr() < T.BARREL * T.BARREL then d = dir end -- (too close to aim at: the way they look)
    local yaw = math.deg(math.atan2(d.y, d.x))
    local pitch = -math.deg(math.atan2(d.z, math.sqrt(d.x * d.x + d.y * d.y)))
    return T.Clamp(Norm(yaw - gun:GetAngles().y), pitch)
end

-- One step toward where it's wanted, as Valve's turns: ten times the distance a second, never
-- faster than its turn rate, so it slows as it closes in.
function T.Approach(cur, want, rate, dt)
    local diff = want - cur
    local step = math.Clamp(diff * 10, -rate, rate) * dt
    if math.abs(step) >= math.abs(diff) then return want end
    return cur + step
end

-- What the gun's own aim ignores: the gunner, the gun and its barricades.
function T.Ignore(gun, ply)
    local list = { gun }
    if IsValid(ply) then list[#list + 1] = ply end
    for i = 1, 2 do
        local p = gun:GetNW2Entity("lc_turret_part" .. i)
        if IsValid(p) then list[#list + 1] = p end
    end
    return list
end

-- A gunner's keys: they stay put and nothing of theirs fires; the click goes to the gun. The
-- player's own computer moves the click onto a key no weapon uses (their weapon never sees it, even
-- in the game's prediction), and the server takes it from there.
local ATTACK2, RELOAD, DUCK = IN_ATTACK2 or 2048, IN_RELOAD or 8192, IN_DUCK or 4
hook.Add("StartCommand", "LivingCityTurret", function(ply, cmd)
    if not IsValid(ply) or not cmd or not cmd.KeyDown then return end
    local gun = ply:GetNW2Entity("lc_turret")
    if not IsValid(gun) then return end
    local fire = cmd:KeyDown(IN_ATTACK) or cmd:KeyDown(T.FIRE_RELAY)
    cmd:RemoveKey(IN_ATTACK)
    cmd:RemoveKey(ATTACK2)
    cmd:RemoveKey(RELOAD)
    cmd:RemoveKey(DUCK)
    cmd:RemoveKey(T.FIRE_RELAY)
    cmd:ClearMovement()
    if CLIENT then
        if fire then cmd:SetButtons(bit.bor(cmd:GetButtons(), T.FIRE_RELAY)) end
        return
    end
    if LC.TurretInput then LC.TurretInput(ply, gun, fire, cmd:KeyDown(IN_JUMP)) end
end)

if SERVER then
    T.Gunners = T.Gunners or {} -- [gun] = the player manning it

    -- Who may man it: anyone (the owner, 21 November: "anyone can use the gun"). One place to change.
    function LC.TurretMayUse(ply, gun) return true end

    -- The gun this player mans, or nil.
    function LC.TurretOf(ply)
        local gun = IsValid(ply) and ply.lcTurret
        if IsValid(gun) and T.Gunners[gun] == ply then return gun end
        return nil
    end

    -- The gun this player is pressing E on (the gun itself or one of its barricades), within reach.
    function LC.TurretAimedAt(ply)
        local tr = ply:GetEyeTrace()
        local e = tr and tr.Entity
        if not IsValid(e) then return nil end
        if e:GetClass() ~= T.CLASS then e = e.lcTurretGun end
        if not IsValid(e) or e:GetClass() ~= T.CLASS then return nil end
        if tr.HitPos and tr.HitPos:DistToSqr(ply:EyePos()) > T.REACH * T.REACH then return nil end
        return e
    end

    -- Standing behind it, where Valve's gunner stands.
    function LC.TurretBehind(ply, gun)
        local x, y, z = T.ToLocal(gun, ply:GetPos())
        local s = T.STAND
        return x >= -s.back and x <= -s.front and math.abs(y) <= s.side and z >= s.low and z <= s.high
    end

    local function Unfit(ply)
        return not ply:Alive() or ply:InVehicle() or ply:GetMoveType() == MOVETYPE_NOCLIP
            or (LC.IsTied and LC.IsTied(ply)) or (LC.IsDowned and LC.IsDowned(ply))
    end

    -- An animation of Valve's gun, and the one to go back to after it (its "default animation").
    function LC.TurretAnim(gun, name, after)
        if not IsValid(gun) then return end
        local seq = gun:LookupSequence(name)
        if not seq or seq < 0 then return end
        gun:ResetSequence(seq)
        gun:SetCycle(0)
        gun.lcAnimAfter = after
        gun.lcAnimUntil = after and (CurTime() + math.max(gun:SequenceDuration(seq) or 0, 0.05)) or nil
    end
    -- (the gun's own think: the default animation again once one has played; true while busy)
    function LC.TurretAnimThink(gun)
        if gun.lcAnimUntil and CurTime() >= gun.lcAnimUntil then
            local after = gun.lcAnimAfter
            gun.lcAnimUntil, gun.lcAnimAfter = nil, nil
            LC.TurretAnim(gun, after)
        end
        return T.Gunners[gun] ~= nil or gun.lcAnimUntil ~= nil
    end

    -- Take the gun: true, or false (not from behind it, someone has it, or not now).
    function LC.TurretMan(ply, gun)
        if not (IsValid(ply) and ply:IsPlayer() and IsValid(gun) and gun:GetClass() == T.CLASS) then return false end
        if Unfit(ply) or LC.TurretOf(ply) then return false end
        local cur = T.Gunners[gun]
        if IsValid(cur) and cur ~= ply then return false end -- (one gunner at a time)
        if not LC.TurretBehind(ply, gun) or not LC.TurretMayUse(ply, gun) then return false end
        T.Gunners[gun] = ply
        ply.lcTurret, ply.lcTurretAt = gun, ply:GetPos()
        gun:SetNW2Entity("lc_turret_gunner", ply)
        ply:SetNW2Entity("lc_turret", gun)
        -- their own weapon put away, as Valve's gun does it, and back in hand when they let go
        local w = ply:GetActiveWeapon()
        ply.lcTurretWeapon = IsValid(w) and w:GetClass() ~= "weapon_lc_hands" and w:GetClass() or nil
        if LC.GiveHands then LC.GiveHands(ply, true) end
        gun.lcFire, gun.lcFireAt, gun.lcNextShot, gun.lcBurst = false, nil, 0, false
        gun.lcYaw, gun.lcPitch = gun:GetNW2Float("lc_turret_yaw", 0), gun:GetNW2Float("lc_turret_pitch", 0)
        gun:EmitSound("Func_Tank.BeginUse")
        LC.TurretAnim(gun, "activate", "idle")
        return true
    end

    -- Let go (`why`: "use" or "jump", or "left": knocked off it; their weapon comes back to hand. Not
    -- after "died", "unfit" (cuffed, down, in a car, flying), "spawn" or "gone").
    local GIVE_BACK = { use = true, jump = true, left = true }
    function LC.TurretRelease(ply, why)
        if not IsValid(ply) then return false end
        local gun = ply.lcTurret
        if gun == nil then return false end
        ply.lcTurret, ply.lcTurretAt = nil, nil
        ply.lcTurretUseAt = CurTime() + 0.4 -- (the same E doesn't take it straight back)
        ply:SetNW2Entity("lc_turret", NULL)
        if IsValid(gun) then
            if T.Gunners[gun] == ply then T.Gunners[gun] = nil end
            gun.lcFire, gun.lcBurst = false, false
            gun:SetNW2Entity("lc_turret_gunner", NULL)
            LC.TurretAnim(gun, "retract", "idle_inactive")
        end
        local back = ply.lcTurretWeapon
        ply.lcTurretWeapon = nil
        if back and GIVE_BACK[why] and ply:Alive() and ply:HasWeapon(back) then
            local w = ply:GetActiveWeapon()
            if not IsValid(w) or w:GetClass() == "weapon_lc_hands" then ply:SelectWeapon(back) end
        end
        return true
    end

    -- The gun going (removed with its editor point): its gunner lets go.
    function LC.TurretGone(gun)
        local ply = T.Gunners[gun]
        T.Gunners[gun] = nil
        if IsValid(ply) and ply.lcTurret == gun then LC.TurretRelease(ply, "gone") end
    end

    -- A gunner's keys, from StartCommand (above): fire held, or a jump to let go.
    function LC.TurretInput(ply, gun, fire, jump)
        if T.Gunners[gun] ~= ply then return end
        if jump then LC.TurretRelease(ply, "jump") return end
        gun.lcFire = fire == true
        if fire then gun.lcFireAt = CurTime() end
    end

    -- Where the bullets leave: the model's muzzle where the barrel is now, else worked out.
    function T.Muzzle(gun, dir)
        local id = gun:LookupAttachment("muzzle")
        local att = id and id > 0 and gun:GetAttachment(id)
        if att and att.Pos then return att.Pos end
        return T.ToWorld(gun, T.PIVOT.x, T.PIVOT.y, T.PIVOT.z) + dir * T.BARREL
    end

    -- One round, the gunner's own.
    function LC.TurretFire(gun, ply)
        local dir = T.Dir(gun:GetAngles().y + (gun.lcYaw or 0), gun.lcPitch or 0)
        local src = T.Muzzle(gun, dir)
        -- Valve's aim assistance for a player on the gun: someone the shot would just graze is hit square
        local tr = util.TraceHull({ start = src, endpos = src + dir * 8192, mins = Vector(-8, -8, -8), maxs = Vector(8, 8, 8),
            mask = MASK_SHOT, filter = T.Ignore(gun, ply) })
        local hit = tr and tr.Entity
        if IsValid(hit) and (hit:IsNPC() or hit:IsPlayer()) and hit:Health() > 0 then
            local to = hit:WorldSpaceCenter() - src
            if to:LengthSqr() > 1 then dir = to:GetNormalized() end
        end
        gun:FireBullets({
            Attacker = ply, Inflictor = gun, Damage = T.DAMAGE, Num = 1, Src = src, Dir = dir,
            Spread = Vector(T.SPREAD, T.SPREAD, 0), Tracer = 1, TracerName = "AR2Tracer", AmmoType = "AR2", IgnoreEntity = ply,
        })
        -- Valve's AR2 handling: the Combine muzzle flash at the muzzle, and the func_tank's shot
        local fx = EffectData()
        fx:SetEntity(gun)
        fx:SetAttachment(math.max(gun:LookupAttachment("muzzle") or 0, 0))
        fx:SetFlags(5) -- (MUZZLEFLASH_COMBINE)
        fx:SetScale(1)
        util.Effect("MuzzleFlash", fx)
        gun:MuzzleFlash()
        gun:EmitSound("Weapon_functank.Single")
        LC.TurretAnim(gun, "fire", "idle")
        -- a shot of theirs, as from their own gun: armed and fighting (sv_livingcity_law.lua), in a fight (the music)
        ply.lcFiredAt = CurTime()
        if LC.NoteFight then LC.NoteFight(ply) end
    end

    -- One tick of a manned gun: still theirs, the barrel turned toward their crosshair, and the rounds due.
    function LC.TurretStep(gun, dt)
        local ply = T.Gunners[gun]
        if not IsValid(gun) then
            T.Gunners[gun] = nil
            if IsValid(ply) then LC.TurretRelease(ply, "gone") end
            return
        end
        if not IsValid(ply) or ply.lcTurret ~= gun then T.Gunners[gun] = nil gun:SetNW2Entity("lc_turret_gunner", NULL) return end
        if Unfit(ply) then LC.TurretRelease(ply, ply:Alive() and "unfit" or "died") return end
        if not ply.lcTurretAt or ply:GetPos():DistToSqr(ply.lcTurretAt) > T.SLIP * T.SLIP then LC.TurretRelease(ply, "left") return end
        local wy, wp = T.AimFrom(gun, ply:EyePos(), ply:GetAimVector(), T.Ignore(gun, ply))
        gun.lcYaw = T.Approach(gun.lcYaw or 0, wy, T.YAW_RATE, dt)
        gun.lcPitch = T.Approach(gun.lcPitch or 0, wp, T.PITCH_RATE, dt)
        -- every screen turns it smoothly toward these (LC.TurretPose); the muzzle here goes where the barrel is
        if math.abs(gun:GetNW2Float("lc_turret_yaw", 0) - gun.lcYaw) > 0.05 then gun:SetNW2Float("lc_turret_yaw", gun.lcYaw) end
        if math.abs(gun:GetNW2Float("lc_turret_pitch", 0) - gun.lcPitch) > 0.05 then gun:SetNW2Float("lc_turret_pitch", gun.lcPitch) end
        gun:SetPoseParameter("aim_yaw", gun.lcYaw)
        gun:SetPoseParameter("aim_pitch", T.PITCH_CENTER + gun.lcPitch)
        local now = CurTime()
        if not gun.lcFire or not gun.lcFireAt or now - gun.lcFireAt > 0.3 then gun.lcBurst = false return end -- (attack held: its keys keep coming)
        local every = 1 / T.RATE
        if not gun.lcBurst or (gun.lcNextShot or 0) < now - 4 * every then gun.lcNextShot = now end -- (a new burst: the first round now)
        gun.lcBurst = true
        local n = 0
        while gun.lcNextShot <= now + 1e-6 and n < 4 and T.Gunners[gun] == ply do
            LC.TurretFire(gun, ply)
            gun.lcNextShot = gun.lcNextShot + every
            n = n + 1
        end
    end

    local lastThink
    hook.Add("Think", "LivingCityTurret", function()
        local now = CurTime()
        local dt = math.Clamp(now - (lastThink or now), 0, 0.25)
        lastThink = now
        if next(T.Gunners) == nil then return end
        for gun, ply in pairs(T.Gunners) do
            local ok = LC.Try(LC.TurretStep, gun, dt)
            if not ok then
                T.Gunners[gun] = nil
                if IsValid(ply) then LC.Try(LC.TurretRelease, ply, "left") end
            end
        end
    end)

    -- E on it from behind takes it; E again lets go.
    hook.Add("KeyPress", "LivingCityTurret", function(ply, key)
        if key ~= IN_USE or not IsValid(ply) or (ply.lcTurretUseAt or 0) > CurTime() then return end
        if LC.TurretOf(ply) then LC.TurretRelease(ply, "use") return end
        local gun = LC.TurretAimedAt(ply)
        if gun and LC.TurretMan(ply, gun) then ply.lcTurretUseAt = CurTime() + 0.4 end
    end)

    hook.Add("PlayerDeath", "LivingCityTurret", function(ply) if IsValid(ply) and ply.lcTurret ~= nil then LC.TurretRelease(ply, "died") end end)
    hook.Add("PlayerSilentDeath", "LivingCityTurret", function(ply) if IsValid(ply) and ply.lcTurret ~= nil then LC.TurretRelease(ply, "died") end end)
    hook.Add("PlayerSpawn", "LivingCityTurret", function(ply) if IsValid(ply) and ply.lcTurret ~= nil then LC.TurretRelease(ply, "spawn") end end)
    hook.Add("PlayerEnteredVehicle", "LivingCityTurret", function(ply) if IsValid(ply) and ply.lcTurret ~= nil then LC.TurretRelease(ply, "unfit") end end)
    hook.Add("EntityRemoved", "LivingCityTurret", function(ent)
        if T.Gunners[ent] ~= nil then LC.TurretGone(ent) end
        if ent.lcTurret ~= nil then LC.TurretRelease(ent, "gone") end
    end)
end

if CLIENT then
    -- The barrel where its gunner aims, turned smoothly on every screen (the gun's Draw: entities/lc_turret.lua):
    -- on the gunner's own screen toward their crosshair, on everyone else's toward where the server has it,
    -- at Valve's turn rates either way.
    function LC.TurretPose(gun)
        local now = CurTime()
        local dt = math.Clamp(now - (gun.lcPoseAt or now), 0, 0.1) -- (drawn twice in a frame: turned once)
        gun.lcPoseAt = now
        local wy, wp = gun:GetNW2Float("lc_turret_yaw", 0), gun:GetNW2Float("lc_turret_pitch", 0)
        local me = LocalPlayer()
        if IsValid(me) and gun:GetNW2Entity("lc_turret_gunner") == me then
            wy, wp = T.AimFrom(gun, me:EyePos(), me:GetAimVector(), T.Ignore(gun, me))
        end
        gun.lcShowYaw = T.Approach(gun.lcShowYaw or wy, wy, T.YAW_RATE, dt)
        gun.lcShowPitch = T.Approach(gun.lcShowPitch or wp, wp, T.PITCH_RATE, dt)
        gun:SetPoseParameter("aim_yaw", gun.lcShowYaw)
        gun:SetPoseParameter("aim_pitch", T.PITCH_CENTER + gun.lcShowPitch)
        gun:InvalidateBoneCache()
        return gun.lcShowYaw, gun.lcShowPitch
    end
end
