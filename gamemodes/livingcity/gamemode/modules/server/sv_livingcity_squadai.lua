--[[
    Living City: squads

    Units hunting the same person move as one squad instead of each running
    straight at them on their own:

      The leader      the one nearest the target leads the chase (it changes
                      as they move), told where the suspect is by dispatch
      The rest        keep with the leader: a run to catch up when they fall
                      behind, a walk once they're close, and when they're with
                      the leader, they stand watch facing out, toward open
                      ground rather than a wall
      In a fight      whoever sees the target fights it; one who's hurt while
                      running stops running and fights back
      The radio       soldiers call it: contact, moving in, lost contact
      One squad       they share the engine's squad, so Half-Life 2's own
                      squad tactics work too (taking turns to shoot, flanking)

    Overwatch soldiers holding posts (a landing zone) face out as well.

      lc_squads 0     everyone hunts on their own, as before
]]

if CLIENT then return end

LC = LC or {}

local FLAGS = bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED)
local cvOn = CreateConVar("lc_squads", "1", FLAGS, "Units hunting the same person move as a squad: a leader, the rest keeping with him and watching the angles")

local FAR, NEAR = 380, 220   -- (followers run past FAR, settle inside NEAR)
local CS = "npc/combine_soldier/vo/"
local LINES = { contact = CS .. "contact.wav", movein = CS .. "movein.wav", lost = CS .. "lostcontact.wav" }

LC.Squads = LC.Squads or {} -- [target] = { leader, members = { [npc] = true }, seenAt, lostCalled, name }
local Squads = LC.Squads

local function Say(npc, what)
    local st = LC.NPCs and LC.NPCs[npc]
    if not st or st.role ~= "soldier" or not LINES[what] then return end
    npc:EmitSound(LINES[what], 80)
end

-- Which way to face: away from `from`, turned a step at a time until there's
-- open ground in front (not a wall), up to a full circle.
function LC.OpenDirection(npc, from)
    local eye = npc.EyePos and npc:EyePos() or (npc:GetPos() + Vector(0, 0, 60))
    local dir = eye - (from or eye)
    dir.z = 0
    if dir:LengthSqr() < 1 then dir = npc:GetForward() dir.z = 0 end
    dir:Normalize()
    local step = (math.random() < 0.5) and 22.5 or -22.5
    local best
    for _ = 1, 16 do
        local tr = util.TraceLine({ start = eye, endpos = eye + dir * 500, mask = MASK_SOLID_BRUSHONLY, filter = npc })
        if (tr.Fraction or 1) >= 0.99 then return dir end
        if not best then best = dir end
        local a = dir:Angle()
        a.y = a.y + step
        dir = a:Forward()
    end
    return best or dir
end

function LC.FaceOut(npc, from)
    local dir = LC.OpenDirection(npc, from)
    if npc.SetIdealYawAndUpdate then npc:SetIdealYawAndUpdate(dir:Angle().y, 1) end
    return dir
end

-- The squad hunting this target (made as it's needed).
local function SquadOf(target)
    local s = Squads[target]
    if not s then
        s = { members = {}, seenAt = 0, name = "lcsq" .. (IsValid(target) and target:EntIndex() or 0) }
        Squads[target] = s
    end
    return s
end

local function Join(npc, st, target)
    local s = SquadOf(target)
    if not s.members[npc] then
        s.members[npc] = true
        if npc.SetSquad then npc:SetSquad(s.name) end
        st.squadOf = target
    end
    return s
end

function LC.LeaveSquad(npc, st)
    local target = st and st.squadOf
    if target == nil then return end
    st.squadOf = nil
    local s = Squads[target]
    if s then
        s.members[npc] = nil
        if s.leader == npc then s.leader = nil end
        if next(s.members) == nil then Squads[target] = nil end
    end
    if IsValid(npc) and npc.SetSquad then npc:SetSquad("") end
end

-- The one nearest the target leads (looked at every few seconds, so it doesn't flicker).
local function Leader(s, target, now)
    if IsValid(s.leader) and s.members[s.leader] and now < (s.leadUntil or 0) then return s.leader end
    local best, bd
    local tpos = target:GetPos()
    for m in pairs(s.members) do
        if IsValid(m) and m:Health() > 0 then
            local d = m:GetPos():DistToSqr(tpos)
            if not bd or d < bd then best, bd = m, d end
        else
            s.members[m] = nil
        end
    end
    s.leader, s.leadUntil = best, now + 3
    return best
end

local function Count(s) local n = 0 for m in pairs(s.members) do if IsValid(m) then n = n + 1 end end return n end

-- Called as a unit pursues (sv_livingcity.lua). True if the squad moved them
-- (a follower keeping with the leader); false: pursue as usual.
function LC.SquadFollow(npc, st, target, now, sees)
    if not cvOn:GetBool() or not IsValid(target) then return false end
    local s = Join(npc, st, target)
    if sees then
        if now - (s.seenAt or 0) > 8 then Say(npc, "contact") end
        s.seenAt, s.lostCalled = now, nil
        return false
    end
    if Count(s) < 2 then return false end
    local lead = Leader(s, target, now)
    if not IsValid(lead) or lead == npc then
        -- the leader: lost them a while? call it once
        if now - (s.seenAt or now) > 12 and not s.lostCalled then s.lostCalled = true Say(npc, "lost") end
        return false
    end
    -- a follower: keep with the leader, at your own place beside him
    local slot = st.squadSlot or math.random(0, 359)
    st.squadSlot = slot
    local lpos = lead:GetPos()
    local d = npc:GetPos():Distance(lpos)
    local running = npc:IsCurrentSchedule(SCHED_FORCED_GO_RUN) or npc:IsCurrentSchedule(SCHED_FORCED_GO)
    if d > FAR then
        local beside = lpos + Angle(0, slot, 0):Forward() * 90
        if not running or not st.squadGoal or st.squadGoal:DistToSqr(beside) > 150 * 150 then
            st.squadGoal = beside
            npc:SetLastPosition(beside)
            npc:SetSchedule(d > FAR * 2 and SCHED_FORCED_GO_RUN or SCHED_FORCED_GO)
        end
        return true
    end
    if d < NEAR then
        -- with the leader: stop, and watch the angles
        if running then npc:SetSchedule(SCHED_ALERT_STAND) end
        if now > (st.watchNext or 0) then
            st.watchNext = now + 3
            LC.FaceOut(npc, lpos)
        end
        return true
    end
    return running -- (closing in: let them finish the walk)
end

-- Hurt while running somewhere: stop and fight.
hook.Add("EntityTakeDamage", "LivingCitySquads", function(victim, dmg)
    if not victim:IsNPC() then return end
    local st = LC.NPCs and LC.NPCs[victim]
    if not st or st.squadOf == nil then return end
    st.hurtAt = CurTime()
    if victim:IsCurrentSchedule(SCHED_FORCED_GO_RUN) or victim:IsCurrentSchedule(SCHED_FORCED_GO) then
        victim:SetSchedule(SCHED_COMBAT_FACE)
    end
end)

-- True for a moment after being hurt: the engine's own combat AI has them.
function LC.SquadHurt(st, now) return st and now - (st.hurtAt or -100) < 2.5 end

-- Tidy up, and soldiers holding posts face out
timer.Create("LivingCitySquads", 2, 0, function()
    local now = CurTime()
    for target, s in pairs(Squads) do
        for m in pairs(s.members) do
            local st = IsValid(m) and LC.NPCs and LC.NPCs[m]
            if not st or st.state ~= "hostile" or st.enemy ~= target then
                if st then LC.LeaveSquad(m, st) else s.members[m] = nil end
            end
        end
        if not IsValid(target) or next(s.members) == nil then Squads[target] = nil end
    end
    if not cvOn:GetBool() then return end
    for npc, st in pairs(LC.NPCs or {}) do
        if IsValid(npc) and st.holdPos and st.state ~= "hostile" and now > (st.watchNext or 0)
            and npc:GetPos():DistToSqr(st.holdPos) < 90 * 90 then
            st.watchNext = now + 8
            LC.FaceOut(npc, st.drop and st.drop.pos or nil)
        end
    end
end)
