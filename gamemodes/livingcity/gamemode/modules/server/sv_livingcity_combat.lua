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

-- A better shot, able to duck and to fire on the move: once each.
function LC.CombatTune(npc, st)
    if st.cmbTuned then return false end
    st.cmbTuned = true
    if npc.SetCurrentWeaponProficiency then npc:SetCurrentWeaponProficiency(WEAPON_PROFICIENCY_VERY_GOOD or 3) end
    if npc.CapabilitiesAdd then
        npc:CapabilitiesAdd(bit.bor(CAP_MOVE_SHOOT or 0, CAP_DUCK or 0, CAP_AIM_GUN or 0))
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

-- Each fighter with an enemy, every couple of seconds.
function LC.CombatStep(npc, st, now)
    local e = LC.CombatEnemy(npc)
    if not e then return nil end
    LC.CombatTune(npc, st)
    if st.questLock or st.state == "jailed" or st.state == "escort" then return nil end
    if Sees(npc, e) then st.cmbSeen = now return "fighting" end
    -- knows of them, can't see them: a line of fire, not a stare at the wall
    if LC.CombatArmed(npc) and now - (st.cmbLof or 0) >= LOF_EVERY and st.state ~= "moving"
        and npc:GetPos():DistToSqr(e:GetPos()) < LOF_RANGE * LOF_RANGE and npc.SetSchedule then
        st.cmbLof = now
        st.cmbLofN = (st.cmbLofN or 0) + 1
        npc:SetSchedule((st.cmbLofN % 2 == 1) and (SCHED_ESTABLISH_LINE_OF_FIRE or SCHED_CHASE_ENEMY) or (SCHED_CHASE_ENEMY or SCHED_ESTABLISH_LINE_OF_FIRE))
        return "closing"
    end
    return "waiting"
end

function LC.CombatTick(now)
    if not cvOn:GetBool() then return end
    for npc, st in pairs(LC.NPCs or {}) do
        if IsValid(npc) and LC.CombatRoles[st.role] and npc:Health() > 0 then
            local ok, err = pcall(LC.CombatStep, npc, st, now)
            if not ok and LC.Error then LC.Error("combat", err) end
        end
    end
end
timer.Create("LivingCityCombat", 2, 0, function() LC.CombatTick(CurTime()) end)

-- Hurt by an enemy: into cover, now and then.
function LC.CombatHurt(npc, st, attacker, dmg, now)
    if not cvOn:GetBool() or not LC.CombatRoles[st.role] or not Alive(attacker) or attacker == npc then return false end
    if st.questLock or st.state == "jailed" or not npc.SetSchedule or not SCHED_TAKE_COVER_FROM_ENEMY then return false end
    if now < (st.cmbCover or 0) then return false end
    local max = npc.GetMaxHealth and npc:GetMaxHealth() or 100
    local left = npc:Health() - (dmg or 0)
    if left <= 0 then return false end
    local chance = left < max * 0.5 and 0.7 or 0.3
    if math.random() >= chance then return false end
    st.cmbCover = now + COVER_EVERY
    if npc.SetEnemy and not LC.CombatEnemy(npc) and (attacker:IsNPC() or attacker:IsPlayer()) and st.state == "hostile" then npc:SetEnemy(attacker) end
    if not LC.CombatEnemy(npc) then return false end
    npc:SetSchedule(SCHED_TAKE_COVER_FROM_ENEMY)
    return true
end
hook.Add("EntityTakeDamage", "LivingCityCombat", function(victim, dmg)
    local st = IsValid(victim) and LC.NPCs and LC.NPCs[victim]
    if not st or not LC.CombatRoles[st.role] then return end
    local ok, err = pcall(LC.CombatHurt, victim, st, dmg:GetAttacker(), dmg:GetDamage(), CurTime())
    if not ok and LC.Error then LC.Error("combat cover", err) end
end)
