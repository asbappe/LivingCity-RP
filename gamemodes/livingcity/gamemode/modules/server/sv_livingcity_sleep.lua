--[[
    Living City: NPCs far from everyone sleep

    The engine runs every NPC's AI each tick (senses, animation, its own path
    searches), wherever they are, and on a big map with a full city that is
    what makes the server fall behind (rubber-banding). Living City's own
    thinking already slows down for NPCs far from every player
    (lc_lod_distance); this stops the engine's too.

    An NPC sleeps when nobody is within lc_lod_distance of them, nobody can
    see them, and they're doing something calm (standing about, queueing,
    sitting, in a cell, walking somewhere). Living City still runs their day:
    one walking somewhere is moved along their route out of sight, a hop at a
    time, as fast as they'd have walked it. They wake the moment a player
    comes near or sees them, they're hurt, or something takes charge of them
    (a fight, an event, a quest).

    lc_npc_sleep 0 turns it off (editor panel: NPC budget section).
]]

LC = LC or {}

local cvSleep = CreateConVar("lc_npc_sleep", "1", FCVAR_ARCHIVE,
    "NPCs far from every player, out of sight and doing something calm stop running the engine's AI until someone comes near")

local NO_THINK = EFL_NO_THINK_FUNCTION or 4194304
local WALK = 110 -- units a second, out of sight

-- What a sleeping NPC may be doing: nothing that needs the engine's AI.
local CALM = { idle = true, busy = true, inline = true, moving = true, jailed = true, detained = true, lookout = true }
local ROLES = { citizen = true, cop = true, soldier = true, zombie = true, rebel = true }

LC.SleepStats = LC.SleepStats or { slept = 0, woke = 0, hops = 0 }
local Stats = LC.SleepStats

local function Asleep(npc) return npc.lcAsleep == true end
LC.NPCAsleep = Asleep

local function Sleep(npc, st)
    if not npc.AddEFlags then return end
    npc:AddEFlags(NO_THINK)
    npc.lcAsleep = true
    st.sleepNext = nil
    Stats.slept = Stats.slept + 1
end

function LC.WakeNPC(npc)
    if not IsValid(npc) or not npc.lcAsleep then return end
    npc.lcAsleep = nil
    if npc.RemoveEFlags then npc:RemoveEFlags(NO_THINK) end
    if npc.NextThink then npc:NextThink(CurTime()) end
    local st = LC.NPCs and LC.NPCs[npc]
    if st then
        st.sleepNext = nil
        -- whatever they were told while asleep, again, now they can hear it
        if st.state == "moving" and st.route and st.route[st.hop] and npc.SetLastPosition then
            npc:SetLastPosition(st.route[st.hop])
            npc:SetSchedule(st.run and SCHED_FORCED_GO_RUN or SCHED_FORCED_GO)
        end
    end
    Stats.woke = Stats.woke + 1
end

-- Called by the NPC loop (sv_livingcity.lua) for each NPC whose turn it is,
-- before their own thinking. near: a player is within lc_lod_distance.
function LC.NPCSleepTick(npc, st, now, near)
    local calm = cvSleep:GetBool() and ROLES[st.role] and CALM[st.state] and not st.test and not st.questLock
        and not (npc.GetEnemy and IsValid(npc:GetEnemy()))
    if Asleep(npc) then
        if not calm or near or LC.IsSeen(npc:GetPos() + Vector(0, 0, 40)) then return LC.WakeNPC(npc) end
        -- the engine re-arms an entity's think when anything schedules one: put it back
        if npc.IsEFlagSet and not npc:IsEFlagSet(NO_THINK) then npc:AddEFlags(NO_THINK) end
        -- walking somewhere: on to the next stop of the route when they'd have got there, unseen
        if st.state == "moving" and st.route then
            local target = st.route[st.hop]
            if target then
                st.sleepNext = st.sleepNext or (now + npc:GetPos():Distance(target) / WALK)
                if now >= st.sleepNext and not LC.IsSeen(target + Vector(0, 0, 40)) then
                    npc.lcUnseenMove = true -- (out of everyone's sight: the lag monitor doesn't count it as a snap)
                    npc:SetPos(target)
                    npc.lcUnseenMove = nil
                    st.lastPos, st.lastMoved = target, now
                    st.sleepNext = nil
                    Stats.hops = Stats.hops + 1
                end
            end
        end
        return
    end
    if calm and not near and not LC.IsSeen(npc:GetPos() + Vector(0, 0, 40)) then Sleep(npc, st) end
end

function LC.SleepingCount()
    local n = 0
    for npc in pairs(LC.NPCs or {}) do if IsValid(npc) and npc.lcAsleep then n = n + 1 end end
    return n
end

-- Hurt: awake at once.
hook.Add("EntityTakeDamage", "LivingCitySleep", function(ent)
    if IsValid(ent) and ent.lcAsleep then LC.WakeNPC(ent) end
end)

-- Turned off: everyone up.
cvars.AddChangeCallback("lc_npc_sleep", function(_, _, new)
    if tonumber(new) == 0 then
        for npc in pairs(LC.NPCs or {}) do LC.WakeNPC(npc) end
    end
end, "LivingCitySleep")
