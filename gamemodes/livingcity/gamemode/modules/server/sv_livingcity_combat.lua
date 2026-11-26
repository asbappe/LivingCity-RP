--[[
    Living City: fighters that fight (the owner, 11 November: "CAN WE FIX THE BLOODY COMBAT AI ... Take cover!
    Strafe or crouch! SHOOT YOUR GUNS LIKE YOU DO AT ME!!! these AI NPCs of both sides shoot ARSENALS at me
    as fast as they can, but against each other or other NPCs they shoot 1 or two bullets, almost as if
    they are unsure or computing something and it's stopping them"; and backup that "walked in staring at
    walls (seeing enemies through walls no doubt) and never fired a shot")

    What was stopping them was the city: a unit or a rebel being walked somewhere is given the next step of
    its way again and again, and a marching order comes before a fight. Against a player they had been made
    "hostile" and left alone to fight; against each other, they were marched past. So:

      - A fighter (Civil Protection, Overwatch, the Resistance) on the way somewhere who can see an enemy
        within COMBAT_RANGE, gun in hand, stops being marched and fights (LC.CombatHolds, used by the
        movement in sv_livingcity.lua), for at most HOLD_MOST seconds a journey; then on.
      - One who knows of an enemy but can't see them (through a wall) goes for a line of fire, every few
        seconds, instead of standing and staring.
      - One hurt by an enemy takes cover from them, now and then (more when badly hurt), then comes back.
      - Each is made a better shot once, may duck, and fires on the move.

    26 November (the owner: Background NPCs' fights "look more human and natural and yours looks stiff and odd
    ... mimic their code/behaviour to a tee ... then integrate our improvements/additions on top"). What made
    ours stiff: a unit after someone was told "run at them" again every time the engine's own fight took over to
    shoot, reload or step aside. Now the fight is handed to the engine the way that addon hands it over
    (Background NPCs by Shark_vil, Apache License 2.0: its brain/fsm/states/sv_defense.lua,
    actor/body/sv_npc_body.lua and actor/components/sh_movement.lua; written afresh here, not copied):

      - Every fighter can duck, shoot on the move, aim, turn its head, use things and work as a squad, from
        the first moment (not from its first fight).
      - Given an enemy: the enemy, the target, where it was last known, and the engine's combat state.
      - While the engine is shooting, reloading, hiding to reload or going for a line of fire, NOTHING is
        ordered (LC.CombatBusy).
      - Every 3 seconds, no oftener, one decision (LC.CombatDrive): the enemy in sight and over 700 away, run
        at them; under 500 with a gun, run back to a spot some 500 behind (the engine's own "move away from
        the enemy" if there is no way there); between, hold and let the engine fight; with a stick, the engine
        closes in by itself inside 700; out of sight, run to where they were last known.
      - A run is given to the engine twice a second at most, and not again while it is still on its way to
        about the same place (LC.CombatMove).

    Ours on top: the pursuit across the city, by ladders and as a squad (sv_livingcity.lua, sv_livingcity_squadai.lua)
    comes first; a marcher who stops to fight is driven the same way while it is held up; where theirs stands
    still at the last known place, ours goes for a line of fire; hurt, into cover (never out of a reload);
    and ours stay good shots.

      lc_combat_ai 0/1 (1)
]]

if CLIENT then return end

LC = LC or {}

local FLAGS = bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED)
local cvOn = CreateConVar("lc_combat_ai", "1", FLAGS, "Units and rebels stop to fight an enemy they can see, look for a line of fire and take cover (0: as before)")

LC.CombatRoles = { cop = true, soldier = true, rebel = true }
local COMBAT_RANGE = 2200
local HOLD_MOST = 60      -- seconds of fighting that hold up one journey
local LOF_EVERY = 4       -- seconds between going for a line of fire
local LOF_RANGE = 3000
local COVER_EVERY = 7     -- seconds between taking cover
-- Background NPCs' numbers (sv_defense.lua, sh_movement.lua)
local REPOSITION = 3      -- seconds between decisions
local FAR = 700           -- farther than this, in sight: run at them
local NEAR = 500          -- nearer than this, in sight, with a gun: back off
local MELEE_ENGINE = 700  -- with a stick, inside this the engine closes in by itself
local REACHED = 50        -- at the last known place
local WALK_DONE = 150     -- a run is over this close to where it was going
local WALK_SAME = 200     -- a run is not given again for a goal that moved less than this
local MELEE = { weapon_stunstick = true, weapon_crowbar = true }

local function Alive(e) return IsValid(e) and (not e.Health or e:Health() > 0) and (not e.Alive or e:Alive()) end

-- Who it is fighting, if anyone.
function LC.CombatEnemy(npc)
    local e = npc.GetEnemy and npc:GetEnemy()
    if Alive(e) and e ~= npc then return e end
    return nil
end

-- Has it something to shoot with in its hands?
function LC.CombatArmed(npc)
    local w = npc.GetActiveWeapon and npc:GetActiveWeapon()
    return IsValid(w) and not MELEE[w:GetClass()]
end

local function Sees(npc, e)
    if not npc.Visible then return true end
    return npc:Visible(e) == true
end

-- Is the engine in the middle of its own fight (a shot, a reload, hiding to reload, a line of fire, a swing)?
-- Then it is left alone: an order now is the shot that never lands, the reload that never ends.
local BUSY = { "SCHED_HIDE_AND_RELOAD", "SCHED_RELOAD", "SCHED_ESTABLISH_LINE_OF_FIRE", "SCHED_RANGE_ATTACK1", "SCHED_RANGE_ATTACK2",
    "SCHED_SPECIAL_ATTACK1", "SCHED_SPECIAL_ATTACK2", "SCHED_MELEE_ATTACK1", "SCHED_MELEE_ATTACK2", "SCHED_SLEEP", "SCHED_NPC_FREEZE" }
function LC.CombatBusy(npc)
    if not npc.IsCurrentSchedule then return false end
    for _, name in ipairs(BUSY) do
        local s = _G[name]
        if s and npc:IsCurrentSchedule(s) then return true end
    end
    return false
end

-- Give it its enemy the way the engine wants one: the enemy, the target, where they were last known, and
-- the combat state at once (not when the engine gets round to it).
function LC.CombatEngage(npc, e, known)
    if not IsValid(npc) or not IsValid(e) then return false end
    if npc.SetEnemy then npc:SetEnemy(e) end
    if npc.SetTarget then npc:SetTarget(e) end
    if known and npc.UpdateEnemyMemory then npc:UpdateEnemyMemory(e, known) end
    if npc.SetNPCState and NPC_STATE_COMBAT then npc:SetNPCState(NPC_STATE_COMBAT) end
    return true
end

-- A better shot, able to duck and to fire on the move: once each.
-- (Keep CAP_MOVE_SHOOT. The owner, 14 November: "They also backpedal when shooting at me which is a nice touch
-- ... please make sure that stays". Backing away from an enemy who is too close is Half-Life 2's own doing, not
-- scripted here; this capability is what lets them go on firing while they do it. LC.CombatMoveShoot says so.)
LC.CombatMoveShoot = true
function LC.CombatTune(npc, st)
    if st.cmbTuned then return false end
    st.cmbTuned = true
    if npc.SetCurrentWeaponProficiency then npc:SetCurrentWeaponProficiency(WEAPON_PROFICIENCY_VERY_GOOD or 3) end
    if npc.CapabilitiesAdd then
        npc:CapabilitiesAdd(bit.bor(CAP_MOVE_SHOOT or 0, CAP_DUCK or 0, CAP_AIM_GUN or 0, CAP_TURN_HEAD or 0, CAP_USE or 0, CAP_SQUAD or 0))
    end
    return true
end

-- Should the city leave off marching this one, because it has someone to shoot at in plain sight?
function LC.CombatHolds(npc, st, now)
    if not cvOn:GetBool() or not st or not LC.CombatRoles[st.role] then return false end
    if st.questLock or st.state == "jailed" or st.state == "escort" then return false end
    if (st.cmbHeldTotal or 0) + (st.cmbHold and (now - st.cmbHold) or 0) > HOLD_MOST then return false end
    local e = LC.CombatEnemy(npc)
    if not e or not LC.CombatArmed(npc) then return false end
    if npc:GetPos():DistToSqr(e:GetPos()) > COMBAT_RANGE * COMBAT_RANGE then return false end
    return Sees(npc, e)
end

-- Knows of them, can't see them: a line of fire, not a stare at the wall (never while the engine is busy).
local function LineOfFire(npc, st, e, now)
    if not LC.CombatArmed(npc) or now - (st.cmbLof or 0) < LOF_EVERY or st.state == "moving" or not npc.SetSchedule then return false end
    if npc:GetPos():DistToSqr(e:GetPos()) >= LOF_RANGE * LOF_RANGE or LC.CombatBusy(npc) then return false end
    st.cmbLof = now
    st.cmbLofN = (st.cmbLofN or 0) + 1
    npc:SetSchedule((st.cmbLofN % 2 == 1) and (SCHED_ESTABLISH_LINE_OF_FIRE or SCHED_CHASE_ENEMY) or (SCHED_CHASE_ENEMY or SCHED_ESTABLISH_LINE_OF_FIRE))
    return true
end

-- Where to fall back to: of the route points within 500 of a spot 500 behind it, the farthest from that
-- spot; with none, a little behind itself or behind the enemy, whichever is farther from the enemy.
function LC.CombatBackOffSpot(npc, e)
    local npos, epos = npc:GetPos(), e:GetPos()
    local centre = npos - npc:GetForward() * 500
    local best, bd
    for _, nd in ipairs(LC.NavNodesNear and LC.NavNodesNear(centre, 500) or {}) do
        local d = nd.pos:DistToSqr(centre)
        if not bd or d > bd then best, bd = nd.pos, d end
    end
    if best then return best end
    local a = epos - e:GetForward() * 200 + Vector(math.random(0, 200), math.random(0, 200), 0)
    local b = npos - npc:GetForward() * 200 + Vector(math.random(0, 200), math.random(0, 200), 0)
    if epos:DistToSqr(a) > epos:DistToSqr(b) then return a end
    return b
end

local function Running(npc)
    return npc.IsCurrentSchedule and (npc:IsCurrentSchedule(SCHED_FORCED_GO_RUN) or npc:IsCurrentSchedule(SCHED_FORCED_GO)) or false
end

-- One fighter's decision in a fight, every REPOSITION seconds (st.cmbDid says what it was). known: where
-- the enemy is known to be when out of sight (the pursuit is told by dispatch; otherwise where they were last
-- seen); track: follow them there as they move. Returns false when lc_combat_ai is off.
function LC.CombatDrive(npc, st, e, now, known, track)
    if not cvOn:GetBool() or not Alive(e) then return false end
    local npos, epos = npc:GetPos(), e:GetPos()
    local sees = Sees(npc, e)
    if sees then st.cmbSeen, st.cmbLast = now, epos end
    known = known or st.cmbLast
    if not sees then
        if now < (st.cmbNext or 0) then return true end
        st.cmbNext = now + REPOSITION
        if known and npos:DistToSqr(known) > REACHED * REACHED then
            st.cmbWalk = track and { ent = e } or { pos = known }
            st.cmbDid = "search"
        else
            st.cmbWalk = nil
            st.cmbDid = LineOfFire(npc, st, e, now) and "closing" or "stand" -- (theirs stands; ours looks for a line of fire)
        end
        return true
    end
    local d2 = npos:DistToSqr(epos)
    local gun = LC.CombatArmed(npc)
    if not gun and d2 <= MELEE_ENGINE * MELEE_ENGINE then
        -- a stick, and near: the engine closes in and swings
        st.cmbWalk = nil
        if Running(npc) and npc.SetSchedule then npc:SetSchedule(SCHED_CHASE_ENEMY) end
        st.cmbDid = "melee"
        return true
    end
    if now < (st.cmbNext or 0) then return true end
    st.cmbNext = now + REPOSITION
    if d2 > FAR * FAR then
        st.cmbWalk = { ent = e }
        st.cmbDid = "advance"
        return true
    end
    if LC.CombatBusy(npc) then st.cmbDid = "busy" return true end
    if gun and d2 < NEAR * NEAR then
        local spot = LC.CombatBackOffSpot(npc, e)
        if spot and not (LC.NavReachable and LC.NavReachable(npos, spot) == false) then
            st.cmbWalk = { pos = spot }
            st.cmbDid = "backoff"
        else
            st.cmbWalk = nil
            if npc.SetSchedule and SCHED_MOVE_AWAY_FROM_ENEMY then npc:SetSchedule(SCHED_MOVE_AWAY_FROM_ENEMY) end
            st.cmbDid = "away"
        end
        return true
    end
    st.cmbDid = "hold" -- (a run already begun goes on; otherwise the engine fights from here)
    return true
end

-- The run it decided on, given to the engine: twice a second at most (the timer), never while the engine is
-- busy with its own fight, and not again while it is still on its way to about the same place.
function LC.CombatMove(npc, st, now)
    local w = st.cmbWalk
    if not w then return false end
    local goal = w.pos
    if w.ent then goal = Alive(w.ent) and w.ent:GetPos() or nil end
    if not goal then st.cmbWalk = nil return false end
    if npc:GetPos():DistToSqr(goal) <= WALK_DONE * WALK_DONE then
        if w.pos then st.cmbWalk = nil end -- (there; one following an enemy just doesn't push into them)
        return false
    end
    if LC.CombatBusy(npc) or not npc.SetSchedule then return false end
    if w.issued and w.issued:DistToSqr(goal) < WALK_SAME * WALK_SAME and npc:IsCurrentSchedule(SCHED_FORCED_GO_RUN) then return false end
    w.issued = Vector(goal.x, goal.y, goal.z)
    npc:SetLastPosition(goal)
    npc:SetSchedule(SCHED_FORCED_GO_RUN)
    return true
end

-- Each fighter, once a second. What it returns: nil (nobody to fight), "fighting" (sees them), "closing"
-- (went for a line of fire), "waiting".
function LC.CombatStep(npc, st, now)
    LC.CombatTune(npc, st)
    local e = LC.CombatEnemy(npc)
    if not e then st.cmbWalk = nil return nil end
    if st.questLock or st.state == "jailed" or st.state == "escort" then st.cmbWalk = nil return nil end
    local sees = Sees(npc, e)
    if sees then st.cmbSeen = now end
    if st.state == "hostile" then
        -- after someone: the pursuit decides (sv_livingcity.lua calls LC.CombatDrive); hands on only, no run of ours
        if st.arrestOnly then st.cmbWalk = nil end
        return sees and "fighting" or "waiting"
    end
    if st.cmbHold then
        -- a marcher held up to fight: driven like the rest while it lasts
        LC.CombatDrive(npc, st, e, now)
        if sees then return "fighting" end
        return st.cmbDid == "closing" and "closing" or "waiting"
    end
    st.cmbWalk = nil
    if sees then return "fighting" end
    if LineOfFire(npc, st, e, now) then return "closing" end
    return "waiting"
end

function LC.CombatTick(now)
    if not cvOn:GetBool() then return end
    for npc, st in pairs(LC.NPCs or {}) do
        if IsValid(npc) and LC.CombatRoles[st.role] and npc:Health() > 0 then
            if now >= (st.cmbStepAt or 0) then
                st.cmbStepAt = now + 1
                local ok, err = LC.Try(LC.CombatStep, npc, st, now)
                if not ok and LC.Error then LC.Error("combat", err) end
            end
            if st.cmbWalk then
                local ok, err = LC.Try(LC.CombatMove, npc, st, now)
                if not ok and LC.Error then LC.Error("combat move", err) end
            end
        end
    end
end
timer.Create("LivingCityCombat", 0.5, 0, function() LC.CombatTick(CurTime()) end)

-- Hurt by an enemy: into cover, now and then.
function LC.CombatHurt(npc, st, attacker, dmg, now)
    if not cvOn:GetBool() or not LC.CombatRoles[st.role] or not Alive(attacker) or attacker == npc then return false end
    if st.questLock or st.state == "jailed" or not npc.SetSchedule or not SCHED_TAKE_COVER_FROM_ENEMY then return false end
    if now < (st.cmbCover or 0) then return false end
    -- (never out of a reload: the gun stays empty)
    if npc.IsCurrentSchedule and ((SCHED_RELOAD and npc:IsCurrentSchedule(SCHED_RELOAD)) or (SCHED_HIDE_AND_RELOAD and npc:IsCurrentSchedule(SCHED_HIDE_AND_RELOAD))) then return false end
    local max = npc.GetMaxHealth and npc:GetMaxHealth() or 100
    local left = npc:Health() - (dmg or 0)
    if left <= 0 then return false end
    local chance = left < max * 0.5 and 0.7 or 0.3
    if math.random() >= chance then return false end
    st.cmbCover = now + COVER_EVERY
    if npc.SetEnemy and not LC.CombatEnemy(npc) and (attacker:IsNPC() or attacker:IsPlayer()) and st.state == "hostile" then npc:SetEnemy(attacker) end
    if not LC.CombatEnemy(npc) then return false end
    st.cmbWalk, st.cmbNext = nil, now + REPOSITION -- (and no run of ours pulls it straight back out)
    npc:SetSchedule(SCHED_TAKE_COVER_FROM_ENEMY)
    return true
end
hook.Add("EntityTakeDamage", "LivingCityCombat", function(victim, dmg)
    local st = IsValid(victim) and LC.NPCs and LC.NPCs[victim]
    if not st or not LC.CombatRoles[st.role] then return end
    local ok, err = LC.Try(LC.CombatHurt, victim, st, dmg:GetAttacker(), dmg:GetDamage(), CurTime())
    if not ok and LC.Error then LC.Error("combat cover", err) end
end)

-- A player's shots at a Civil Protection NPC hit harder (the owner, 14 November: "As a citizen/
-- resistance member with a pistol, it takes about 20 shots to kill a metrocop, which is insane.
-- For a soldier? ehhhh that might be acceptable, but for a metrocop? I would expect 10-13 shots
-- from a pistol."). Metrocops have lc_cp_health (70); Half-Life 2's pistol does 5 a hit, so 14
-- hits. At lc_cp_damage_taken 1.5 it is 10 (fewer with a head shot). Soldiers and Elites, and
-- NPCs shooting each other, are as before.
local cvCPTaken = CreateConVar("lc_cp_damage_taken", "1.5", FLAGS, "Players' damage to Civil Protection NPCs is multiplied by this (1: Half-Life 2's own; 1.5: about 10 pistol hits on a metrocop)")
function LC.CPDamageTakenMul(victim, attacker)
    local st = IsValid(victim) and LC.NPCs and LC.NPCs[victim]
    if not st or st.role ~= "cop" or not IsValid(attacker) or not attacker:IsPlayer() then return 1 end
    return math.max(0, cvCPTaken:GetFloat())
end
hook.Add("EntityTakeDamage", "LivingCityCPDamageTaken", function(victim, dmg)
    local m = LC.CPDamageTakenMul(victim, dmg:GetAttacker())
    if m ~= 1 then dmg:ScaleDamage(m) end
end)
