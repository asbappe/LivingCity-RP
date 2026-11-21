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

    An officer on it (the owner, 21 November: "if there is an enemy within range of the turret and
    relatively in front of it, then yes"): while nobody mans it and an enemy of the Combine is in
    range and in front of it (in its arc, in sight), the nearest free Civil Protection officer runs to
    the spot behind it, as Valve's Metrocop stands, and mans it: the gun turns and fires at that enemy
    at Valve's rates. He lets go when no enemy has been in front for a few seconds, when he is badly
    hurt, or when a player of the Combine presses E on it (a player comes first); dead or called away,
    the gun is free. Who counts as an enemy: whom the Combine's own turrets shoot (LC.TurretAttitude),
    less the wanted who have hurt nobody (taken by hand, as the city's units do), and the infested and
    the Resistance's fighters among the city's people.
]]

LC = LC or {}
local T = LC.Turret or {}
LC.Turret = T

T.CLASS = "lc_turret"
-- Valve's numbers (d1_canals_07, turret_1), and the owner's
T.DAMAGE = 5             -- a bullet, to anyone: Valve's own against players (bullet_damage_vs_player), the owner's choice for all
                         -- (21 November: "and 5 against players when it's turned on you: yes this is the damage we want universally")
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
-- An officer on it (Valve's numbers for an NPC on turret_1)
T.SPOT = Vector(-41, 0, -33) -- where he stands, from the gun's foot (turret_1_standhere)
T.RANGE = 2500           -- how far an enemy can be (maxRange)
T.TOLERANCE = 15         -- degrees the barrel may be off them and still fire (yawtolerance, pitchtolerance)
T.PERSIST = 3            -- seconds with no enemy in front before he lets go (persistence 2, and a beat)
T.CALL = 1500            -- how far away an officer can be called to it
T.BREAK = 0.5            -- hurt below this share of his health, he breaks off (badly hurt, as the city's fighters count it)
T.RECALL = 5             -- seconds after one lets go before another is called

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

-- A way from where it turns, as its yaw (left positive) and pitch (down positive) from the gun's own
-- facing, before any limit.
local function Offsets(gun, d)
    local yaw = math.deg(math.atan2(d.y, d.x))
    local pitch = -math.deg(math.atan2(d.z, math.sqrt(d.x * d.x + d.y * d.y)))
    return Norm(yaw - gun:GetAngles().y), pitch
end
function T.Pivot(gun) return T.ToWorld(gun, T.PIVOT.x, T.PIVOT.y, T.PIVOT.z) end
-- The barrel's yaw and pitch onto a point, before any limit.
function T.AimAt(gun, pos) return Offsets(gun, pos - T.Pivot(gun)) end
-- In front of it: within its reach across and up and down.
function T.InArc(gun, pos)
    local y, p = T.AimAt(gun, pos)
    return math.abs(y) <= T.YAW_RANGE and math.abs(p) <= T.PITCH_RANGE
end

-- Where a gunner looking from `eye` along `dir` wants the barrel, within its reach. As Valve's, it
-- aims at the spot under the crosshair, not merely the same way, so the bullets go where they look.
function T.AimFrom(gun, eye, dir, ignore)
    local target = eye + dir * 8192
    local tr = util.TraceLine({ start = eye + dir * 24, endpos = target, mask = MASK_SHOT, filter = ignore })
    if tr and tr.Hit and tr.HitPos then target = tr.HitPos end
    local d = target - T.Pivot(gun)
    if d:LengthSqr() < T.BARREL * T.BARREL then d = dir end -- (too close to aim at: the way they look)
    return T.Clamp(Offsets(gun, d))
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
        if not LC.TurretBehind(ply, gun) or not LC.TurretMayUse(ply, gun) then return false end
        local cur = T.Gunners[gun]
        if IsValid(cur) and cur ~= ply then
            -- one gunner at a time; an officer on it gives way to a player of the Combine (and to anyone
            -- while he is still on his way to it): a player comes first
            if cur:IsPlayer() or not LC.TurretGivesWay(cur, ply) then return false end
            LC.TurretNPCRelease(cur, "player", gun)
        end
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
        local who = T.Gunners[gun]
        T.Gunners[gun] = nil
        if IsValid(who) and who:IsPlayer() then
            if who.lcTurret == gun then LC.TurretRelease(who, "gone") end
        elseif who ~= nil then
            LC.TurretNPCRelease(who, "gone", gun)
        end
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

    -- One round, the gunner's own (a player, or an officer).
    function LC.TurretFire(gun, ply)
        local dir = T.Dir(gun:GetAngles().y + (gun.lcYaw or 0), gun.lcPitch or 0)
        local src = T.Muzzle(gun, dir)
        if ply:IsPlayer() then
            -- Valve's aim assistance for a player on the gun: someone the shot would just graze is hit square
            local tr = util.TraceHull({ start = src, endpos = src + dir * 8192, mins = Vector(-8, -8, -8), maxs = Vector(8, 8, 8),
                mask = MASK_SHOT, filter = T.Ignore(gun, ply) })
            local hit = tr and tr.Entity
            if IsValid(hit) and (hit:IsNPC() or hit:IsPlayer()) and hit:Health() > 0 then
                local to = hit:WorldSpaceCenter() - src
                if to:LengthSqr() > 1 then dir = to:GetNormalized() end
            end
        end
        local bullet = {
            Attacker = ply, Inflictor = gun, Damage = T.DAMAGE, Num = 1, Src = src, Dir = dir,
            Spread = Vector(T.SPREAD, T.SPREAD, 0), Tracer = 1, TracerName = "AR2Tracer", AmmoType = "AR2", IgnoreEntity = ply,
        }
        gun:FireBullets(bullet)
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
        -- a shot of theirs, as from their own gun, for what watches who fires: armed and fighting (sv_livingcity_law.lua),
        -- the fight music (sv_livingcity_pacing.lua), a close call at the Administrator's address (sv_livingcity_adminsecurity.lua)
        if ply:IsPlayer() then
            ply.lcFiredAt = CurTime()
            if LC.NoteFight then LC.NoteFight(ply) end
        end
        if LC.AdminBulletCheck then LC.Try(LC.AdminBulletCheck, ply, bullet) end
    end

    -- The barrel a step toward a yaw and pitch, at Valve's rates: for every screen (LC.TurretPose turns it
    -- smoothly toward these) and for the muzzle here.
    local function Aim(gun, wy, wp, dt)
        gun.lcYaw = T.Approach(gun.lcYaw or 0, wy, T.YAW_RATE, dt)
        gun.lcPitch = T.Approach(gun.lcPitch or 0, wp, T.PITCH_RATE, dt)
        if math.abs(gun:GetNW2Float("lc_turret_yaw", 0) - gun.lcYaw) > 0.05 then gun:SetNW2Float("lc_turret_yaw", gun.lcYaw) end
        if math.abs(gun:GetNW2Float("lc_turret_pitch", 0) - gun.lcPitch) > 0.05 then gun:SetNW2Float("lc_turret_pitch", gun.lcPitch) end
        gun:SetPoseParameter("aim_yaw", gun.lcYaw)
        gun:SetPoseParameter("aim_pitch", T.PITCH_CENTER + gun.lcPitch)
    end
    -- The rounds due while the trigger is held (its keys keep coming): Valve's rate, a new burst's first at once.
    local function Rounds(gun, shooter, now)
        if not gun.lcFire or not gun.lcFireAt or now - gun.lcFireAt > 0.3 then gun.lcBurst = false return end
        local every = 1 / T.RATE
        if not gun.lcBurst or (gun.lcNextShot or 0) < now - 4 * every then gun.lcNextShot = now end
        gun.lcBurst = true
        local n = 0
        while gun.lcNextShot <= now + 1e-6 and n < 4 and T.Gunners[gun] == shooter do
            LC.TurretFire(gun, shooter)
            gun.lcNextShot = gun.lcNextShot + every
            n = n + 1
        end
    end

    -- One tick of a manned gun: still theirs, the barrel turned toward their crosshair, and the rounds due.
    function LC.TurretStep(gun, dt)
        local ply = T.Gunners[gun]
        if not IsValid(gun) then
            T.Gunners[gun] = nil
            if IsValid(ply) and ply:IsPlayer() then LC.TurretRelease(ply, "gone") elseif ply ~= nil then LC.TurretNPCRelease(ply, "gone", gun) end
            return
        end
        if ply ~= nil and not (IsValid(ply) and ply:IsPlayer()) then return LC.TurretNPCStep(gun, ply, dt) end
        if not IsValid(ply) or ply.lcTurret ~= gun then T.Gunners[gun] = nil gun:SetNW2Entity("lc_turret_gunner", NULL) return end
        if Unfit(ply) then LC.TurretRelease(ply, ply:Alive() and "unfit" or "died") return end
        if not ply.lcTurretAt or ply:GetPos():DistToSqr(ply.lcTurretAt) > T.SLIP * T.SLIP or not LC.TurretBehind(ply, gun) then
            LC.TurretRelease(ply, "left") -- (knocked off it, or the gun moved)
            return
        end
        local wy, wp = T.AimFrom(gun, ply:EyePos(), ply:GetAimVector(), T.Ignore(gun, ply))
        Aim(gun, wy, wp, dt)
        Rounds(gun, ply, CurTime())
    end

    ------------------------------------------------------------------------
    -- An officer on it
    ------------------------------------------------------------------------

    -- An enemy of the Combine: whom its own turrets shoot (LC.TurretAttitude: the infested, the wanted, the
    -- Resistance's known fighters), less the wanted who have hurt nobody (the city's units take them by hand,
    -- never shoot them: LC.MakeOneHostile), and among the city's people the infested and the Resistance's fighters.
    local HELD = { jailed = true, escorted = true, detained = true }
    function LC.TurretFoe(e)
        if not IsValid(e) then return false end
        if e:IsPlayer() then
            if not e:Alive() or (LC.EditorHeld and LC.EditorHeld(e)) or (LC.IsAdministrator and LC.IsAdministrator(e)) then return false end
            if not LC.TurretAttitude or LC.TurretAttitude(e) ~= D_HT then return false end
            if LC.PlayerIsZombie(e) then return true end
            return (not LC.Violent or LC.Violent(e)) and not (LC.TakenUnarmed and LC.TakenUnarmed(e))
        end
        local st = LC.NPCs and LC.NPCs[e]
        if not st or (st.role ~= "rebel" and st.role ~= "zombie") or e:Health() <= 0 then return false end
        return not HELD[st.state] and not e:GetNW2Bool("lc_cuffed", false) and not (LC.Prisoners and LC.Prisoners[e])
    end

    -- In range of it, in front of it (in its arc) and in its sight.
    function LC.TurretSights(gun, e, gunner)
        local c, from = e:WorldSpaceCenter(), T.Pivot(gun)
        if c:DistToSqr(from) > T.RANGE * T.RANGE or not T.InArc(gun, c) then return false end
        local tr = util.TraceLine({ start = from, endpos = c, mask = MASK_SHOT, filter = T.Ignore(gun, gunner) })
        return not tr or not tr.Hit or tr.Entity == e or (tr.Fraction or 0) > 0.97
    end

    -- The nearest enemy in its sights, or nil.
    function LC.TurretFoeInFront(gun, gunner)
        local from, best, bd = T.Pivot(gun), nil, nil
        local function Try(e)
            if e == gunner or not LC.TurretFoe(e) then return end
            local d = e:WorldSpaceCenter():DistToSqr(from)
            if (bd and d >= bd) or not LC.TurretSights(gun, e, gunner) then return end
            best, bd = e, d
        end
        for _, p in ipairs(player.GetAll()) do Try(p) end
        for npc in pairs(LC.NPCs or {}) do Try(npc) end
        return best
    end

    -- A Civil Protection officer with nothing more pressing on (the city's own test for a free unit).
    local FREE = { idle = true, moving = true, working = true }
    local function FreeOfficer(npc, st, now)
        return IsValid(npc) and st.role == "cop" and FREE[st.state] and npc:Health() > 0
            and npc:Health() >= (npc:GetMaxHealth() or 100) * T.BREAK
            and not st.questLock and not st.workEscort and not st.raid and not st.escortee and not st.subject and not st.skirmish
            and not st.cleanGuard and not st.marching and not st.arrestDuty and not st.holdPos and not st.turretGun
            and (st.stunnedUntil or 0) < now
    end
    function LC.TurretNearestOfficer(pos, now)
        local best, bst, bd
        for npc, st in pairs(LC.NPCs or {}) do
            if FreeOfficer(npc, st, now) then
                local d = npc:GetPos():DistToSqr(pos)
                if d < T.CALL * T.CALL and (not bd or d < bd) then best, bst, bd = npc, st, d end
            end
        end
        return best, bst
    end

    -- An officer gives way to a player of the Combine; to anyone while he is still on his way.
    function LC.TurretGivesWay(npc, ply)
        local st = LC.NPCs and LC.NPCs[npc]
        return LC.PlayerIsCP(ply) or st == nil or st.turretPhase ~= "manning"
    end

    -- Sent to it: he runs to the spot behind it and mans it, held to it (nothing else sends him off) till he lets go.
    function LC.TurretNPCTake(gun, npc, st, foe)
        if LC.Release then LC.Release(npc, st) end
        if LC.NPCWorkReset then LC.NPCWorkReset(npc, st) end
        local now = CurTime()
        st.turretGun, st.turretTarget, st.turretSeen, st.turretPhase, st.turretGiveUp = gun, foe, now, "coming", now + 25
        if not st.questLock then st.questLock, st.lcTurretLock = true, true end
        st.route, st.routeTo, st.goingTo, st.turretSteerAt = nil, nil, nil, nil
        npc.lcManning = gun
        LC.SetState(npc, st, "turretgun")
        T.Gunners[gun] = npc
        gun.lcFire, gun.lcBurst = false, false
        return true
    end

    -- He lets go (`why`: "clear", no enemy in front for a while; "hurt"; "player", a player takes it; "called",
    -- pulled off to something else; "lost", he couldn't get to it; "gone", dead, or the gun gone).
    function LC.TurretNPCRelease(npc, why, gun)
        local st = IsValid(npc) and LC.NPCs and LC.NPCs[npc] or nil
        gun = gun or (st and st.turretGun) or (IsValid(npc) and npc.lcManning) or nil
        if IsValid(npc) then npc.lcManning = nil end
        if gun and T.Gunners[gun] == npc then
            T.Gunners[gun] = nil
            if IsValid(gun) then
                gun.lcFire, gun.lcBurst = false, false
                gun.lcNPCNext = CurTime() + T.RECALL -- (a moment before another is called to it)
                if gun:GetNW2Entity("lc_turret_gunner") == npc then
                    gun:SetNW2Entity("lc_turret_gunner", NULL)
                    LC.TurretAnim(gun, "retract", "idle_inactive")
                end
            end
        end
        if not st then return false end
        st.turretGun, st.turretTarget, st.turretSeen, st.turretPhase, st.turretGiveUp, st.turretSteerAt = nil, nil, nil, nil, nil, nil
        if st.lcTurretLock then st.questLock, st.lcTurretLock = nil, nil end
        st.route, st.routeTo, st.goingTo = nil, nil, nil
        if st.state == "turretgun" and npc:Health() > 0 then
            LC.SetState(npc, st, "idle")
            st.untilT = CurTime() + 2
            npc:SetSchedule(SCHED_IDLE_STAND)
        end
        return true
    end

    -- On his way to the spot behind it, by the city's routes, at a run (asked again twice a second).
    local function Steer(npc, st, dest, now)
        if now < (st.turretSteerAt or 0) then return end
        st.turretSteerAt = now + 0.5
        if not st.route or not st.routeTo or st.routeTo:DistToSqr(dest) > 64 * 64 or now > (st.routeAt or 0) + 8 then
            local route = LC.BuildRoute and LC.BuildRoute(npc:GetPos(), dest, "cop")
            st.route = (type(route) == "table" and #route > 0) and route or { dest }
            st.hop, st.routeTo, st.routeAt = 1, dest, now
        end
        local pos = npc:GetPos()
        while st.hop < #st.route and pos:DistToSqr(st.route[st.hop]) < 96 * 96 do st.hop = st.hop + 1 end
        local to = st.hop >= #st.route and dest or st.route[st.hop]
        if not st.goingTo or st.goingTo:DistToSqr(to) > 40 * 40
            or not (npc:IsCurrentSchedule(SCHED_FORCED_GO_RUN) or npc:IsCurrentSchedule(SCHED_FORCED_GO)) then
            st.goingTo = to
            npc:SetLastPosition(to)
            npc:SetSchedule(SCHED_FORCED_GO_RUN)
        end
    end

    -- One tick of an officer's gun: still his, the enemy still in front, him at the spot, the barrel onto
    -- them and the rounds while it is on them (within Valve's tolerance).
    function LC.TurretNPCStep(gun, npc, dt)
        local st = IsValid(npc) and LC.NPCs and LC.NPCs[npc] or nil
        if not st or st.turretGun ~= gun or npc:Health() <= 0 then return LC.TurretNPCRelease(npc, "gone", gun) end
        local now = CurTime()
        if st.state == "hostile" then
            -- made to fight someone (a crime close by, a monster): still on the gun if they're in front of it, else off after them
            local e = st.enemy
            if st.arrestOnly or not (IsValid(e) and LC.TurretFoe(e) and LC.TurretSights(gun, e, npc)) then return LC.TurretNPCRelease(npc, "called", gun) end
            LC.SetState(npc, st, "turretgun")
            st.turretTarget, st.goingTo = e, nil
        elseif st.state ~= "turretgun" then
            return LC.TurretNPCRelease(npc, "called", gun)
        end
        if npc:Health() < (npc:GetMaxHealth() or 100) * T.BREAK then return LC.TurretNPCRelease(npc, "hurt", gun) end
        -- the enemy: the one he has while it is still in its sights, else the nearest that is (looked for twice a second)
        local e = st.turretTarget
        if not (IsValid(e) and LC.TurretFoe(e) and LC.TurretSights(gun, e, npc)) then
            e = nil
            if now >= (gun.lcScanAt or 0) then
                gun.lcScanAt = now + 0.5
                e = LC.TurretFoeInFront(gun, npc)
            end
            st.turretTarget = e
        end
        if e then st.turretSeen = now end
        if now - (st.turretSeen or now) > T.PERSIST then return LC.TurretNPCRelease(npc, "clear", gun) end
        -- to the spot behind it (or back onto it, pushed off it)
        local spot = T.ToWorld(gun, T.SPOT.x, T.SPOT.y, T.SPOT.z)
        if npc:GetPos():DistToSqr(spot) > 40 * 40 then
            if st.turretPhase ~= "manning" and now > (st.turretGiveUp or now) then return LC.TurretNPCRelease(npc, "lost", gun) end
            gun.lcFire = false
            return Steer(npc, st, spot, now)
        end
        if st.turretPhase ~= "manning" then
            st.turretPhase, st.goingTo = "manning", nil
            npc:SetSchedule(SCHED_IDLE_STAND)
            gun:SetNW2Entity("lc_turret_gunner", npc)
            gun.lcYaw, gun.lcPitch = gun:GetNW2Float("lc_turret_yaw", 0), gun:GetNW2Float("lc_turret_pitch", 0)
            gun.lcNextShot, gun.lcBurst = 0, false
            gun:EmitSound("Func_Tank.BeginUse")
            LC.TurretAnim(gun, "activate", "idle")
        end
        if not e then gun.lcFire = false return end -- (the barrel held where it was, for a moment)
        local c = e:WorldSpaceCenter()
        local wy, wp = T.AimAt(gun, c)
        local cy, cp = T.Clamp(wy, wp)
        Aim(gun, cy, cp, dt)
        if now >= (st.turretFaceAt or 0) then
            st.turretFaceAt = now + 1
            LC.Face(npc, c)
        end
        gun.lcFire = math.abs(wy - gun.lcYaw) < T.TOLERANCE and math.abs(wp - gun.lcPitch) < T.TOLERANCE
        if gun.lcFire then gun.lcFireAt = now end
        Rounds(gun, npc, now)
    end

    -- A gun nobody mans, with an enemy in front of it: the nearest free officer is sent to it (twice a second).
    function LC.TurretWatch(now)
        for _, gun in ipairs(ents.FindByClass(T.CLASS)) do
            if IsValid(gun) and T.Gunners[gun] == nil and gun.lcGround ~= nil and now >= (gun.lcNPCNext or 0) then
                local foe = LC.TurretFoeInFront(gun, nil)
                if foe then
                    local npc, st = LC.TurretNearestOfficer(T.ToWorld(gun, T.SPOT.x, T.SPOT.y, T.SPOT.z), now)
                    if npc then LC.TurretNPCTake(gun, npc, st, foe) else gun.lcNPCNext = now + 2 end
                end
            end
        end
    end
    timer.Create("LivingCityTurretWatch", 0.5, 0, function() LC.Try(LC.TurretWatch, CurTime()) end)

    local lastThink
    hook.Add("Think", "LivingCityTurret", function()
        local now = CurTime()
        local dt = math.Clamp(now - (lastThink or now), 0, 0.25)
        lastThink = now
        if next(T.Gunners) == nil then return end
        for gun, who in pairs(T.Gunners) do
            local ok = LC.Try(LC.TurretStep, gun, dt)
            if not ok then
                if IsValid(who) and who:IsPlayer() then LC.Try(LC.TurretRelease, who, "left") else LC.Try(LC.TurretNPCRelease, who, "gone", gun) end
                T.Gunners[gun] = nil
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
        if ent.lcManning ~= nil then LC.TurretNPCRelease(ent, "gone") end
    end)
    hook.Add("OnNPCKilled", "LivingCityTurret", function(npc) if IsValid(npc) and npc.lcManning ~= nil then LC.TurretNPCRelease(npc, "gone") end end)
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
