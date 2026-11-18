--[[
    Living City: a lone wolf who tried to kill the Administrator and got away is taken in by the Resistance

    The owner, 17 November: "if a lonewolf attempts to assassinate the administrator, and gets
    away, they should be approached by the resistance and recruited (or if the lone wolf just
    goes to the resistance territory after assassination attempt)."

    Who        a citizen marked for an attempt on her life (LC.AdminAttacker,
               sv_livingcity_adminsecurity.lua) who held neither the job nor a leader's order
               when they made it (LC.AdminPlotHolds, sv_livingcity_adminplot.lua): that one is
               the Resistance's own already. Not one of the Resistance or the Combine, not a
               stalker, a vortigaunt or one of the infested, and never someone the Resistance
               would not take: a rat carved into their face, a burned informant. They are owed
               this from the attempt on, and it is kept with the character (so it holds over a
               reconnect) until it has been done, once, or is off for good.
    They go    Owed, they step onto rebel ground: the nearest of the Resistance's own people
               there who can see them (within 700 units; not one in a fight, in cuffs or
               asleep) says the line to them. No waiting: getting there is getting away.
    Or he      Otherwise, once they have got away (two minutes since the attempt, and no unit
    comes      has seen them for the last minute: ply.lcWantedSeen, sv_livingcity_law.lua), a
               contact comes out of one of the city's doorways or walking spots near them that
               nobody can see (LC.AdminPlotSpots: the same spots an ordered attack's fighters
               come from), walks up to them and says the line. He is one of the city's own
               fighters out of the Resistance's reserve (LC.SpawnRebel), unarmed and in plain
               clothes (LC.SquadCasual: a citizen, to the units), nobody's enemy and nobody's to
               move meanwhile. He stays by them a few seconds, then walks back the way he came
               and is taken out of the city once nobody can see him: back in the reserve.
    Never      while a unit can see either of them (a unit of the city's within 1500 units with
    watched    a clear line, or one of the Combine's players): then nobody is sent, and one on
               his way turns back. It is tried again three minutes later; so it is when there
               is nowhere unseen to come from, nobody left in the reserve, or he has not
               reached them in ninety seconds. Three contacts at most in one stay on the
               server. Stepping onto rebel ground stays open for as long as it is owed.
    The line   one, spoken: "We saw what you did. You're with us now." (LC.ResistanceLines,
               sv_livingcity_rebelvoice.lua: in chat as any of their lines, and from the one
               saying it once it is recorded; until then he says "Hi" aloud, in Half-Life 2's
               own voice, as the camp's medic does.) Nothing else is put on anyone's screen.
    With us    what a story's invitation does (The Pamphleteer's "join", sv_livingcity_stories.lua):
               a moment after the line they are proven (LC.ResistanceInvite) and one of the
               Resistance (LC.SetFaction), at the rank their experience gives. Where they
               stand, and with no line of its own about it, as when a team cuts a vortigaunt
               loose (sv_livingcity_vortstart.lua). The faction screen could not do it: nobody
               wanted may change sides there, and they are wanted for life. (Coming to as one of
               the Resistance, they are put in plain clothes and told so in its two usual lines,
               as any member is: sv_livingcity_underground.lua. That is not this file's doing.)
    Off for    caught (in cuffs or a cell), dead, or no longer someone it is for (one of the
    good       Resistance or the Combine by another road, a rat, burned, the mark cleared). A
               new character starts clean. Someone marked before this was built is owed
               nothing until they try again.

    Kept with the character (PData): lc_adminrecruit = when the attempt was (owed), "done" or "over".
    Hooks heard: LivingCityAdminExfil and LivingCityAdminAttempt (an attempt: who), PlayerDeath,
    LivingCityIncarcerated, LivingCityNewCharacter, PlayerDisconnected, LivingCityStopped.
    Nothing is answered to any of them. No settings: the numbers are the constants below.
]]

if CLIENT then return end

LC = LC or {}

local LINE = "saw_you"        -- (LC.ResistanceLines)
local KEY = "lc_adminrecruit" -- kept with the character: when the attempt was (owed), "done" or "over"
local GOT_AWAY = 120          -- seconds since the attempt before a contact is sent
local UNSEEN = 60             -- and no unit has seen them for this long
local RETRY = 180             -- it cannot be done now: again this much later
local TRIES = 3               -- contacts sent, at most
local COME_MAX = 90           -- a contact who has not reached them by then turns back
local TALK = 100              -- how near he comes before he speaks
local RUN_BEYOND = 500        -- further from them than this, he hurries
local SEE = 700               -- on rebel ground: one of theirs this near, who can see them
local WATCH = 1500            -- a unit this near with a clear line sees them
local JOIN_AFTER = 1.5        -- seconds from the line to being one of them (as a story's invitation)
local SHORT = 5               -- experience short of a Member they are given (the least a job pays: one job makes them one)
local LINGER = 4              -- seconds he stays by them once he has said it
local LEAVE_MAX = 120         -- a contact still watched this long after turning back goes anyway
local HELD_SECS = 5           -- the job or the order, held this recently, was held when the attempt was made
local FRESH = 30              -- a mark this new is an attempt just made
local LOOK_EVERY = 3          -- seconds between looks at the mark of a marked citizen nothing is kept for
local HOLD = 600              -- (the city leaves a contact alone this long at most: the "event" state)
local UP = Vector(0, 0, 50)
local TAKEN = { detained = true, escorted = true, jailed = true }

local owed = setmetatable({}, { __mode = "k" })  -- [ply] = { at, since, tries, nextTry, npc, sentAt, from }
local notes = setmetatable({}, { __mode = "k" }) -- [ply] = { flag, look, mark, held, closed }
local leaving = {}                               -- [npc] = { since, from, run, wait, to, toAt }: contacts on their way out

local function Note(ply)
    local n = notes[ply]
    if not n then n = {} notes[ply] = n end
    return n
end

-- What is owed to them (the record), or nil. And the contacts on their way out (tests).
function LC.AdminRecruitOwed(ply) return owed[ply] end
LC.AdminRecruitLeaving = leaving

local function Faction(p) return p:GetNW2String("lcf_faction", "") end

------------------------------------------------------------------------
-- Who it is for
------------------------------------------------------------------------

-- Someone the Resistance would never take this way, or who is somebody's already.
local function Never(ply)
    if Faction(ply) ~= "citizen" then return true end
    if LC.PlayerIsCP and LC.PlayerIsCP(ply) then return true end
    if ply:GetPData("lc_scar", "0") == "1" then return true end -- (a marked rat, never: sv_livingcity_snitches.lua)
    if LC.IsBurned and LC.IsBurned(ply) then return true end    -- (burned as an informant)
    if not (LC.AdminNeverForgotten and LC.AdminNeverForgotten(ply)) then return true end -- (the mark was cleared)
    return false
end

local function Caught(ply) return LC.InCustody ~= nil and LC.InCustody(ply) == true end
-- Not at this moment: held in a struggle, dreaming, or an admin at work on the city.
local function Busy(ply)
    return (LC.HeldByCombine and LC.HeldByCombine(ply)) or ply.lcDreaming or (LC.EditorHeld and LC.EditorHeld(ply)) or false
end

------------------------------------------------------------------------
-- Who is looking
------------------------------------------------------------------------

local function Clear(a, b, filter)
    if LC.SmokeBlocks and LC.SmokeBlocks(a, b) then return false end
    local tr = util.TraceLine({ start = a, endpos = b, mask = MASK_OPAQUE, filter = filter })
    return tr.Fraction > 0.97
end
local function Sees(a, b, range)
    if LC.RebelCanSee then return LC.RebelCanSee(a, b, range) end
    return a:GetPos():DistToSqr(b:GetPos()) < range * range
end
-- One of the Combine's players has a clear line to this spot.
local function UnitPlayerSees(pos, but)
    for _, p in ipairs(player.GetAll()) do
        if p ~= but and p:Alive() and LC.PlayerIsCP and LC.PlayerIsCP(p)
            and p:GetPos():DistToSqr(pos) < WATCH * WATCH and Clear(p:EyePos(), pos, p) then return true end
    end
    return false
end
-- One of the city's units has.
local function UnitSees(pos)
    for npc, st in pairs(LC.NPCs or {}) do
        if IsValid(npc) and LC.IsSecurity(st) and npc:Health() > 0
            and npc:GetPos():DistToSqr(pos) < WATCH * WATCH and Clear(npc:EyePos(), pos, npc) then return true end
    end
    return false
end
-- A unit can see them right now (the units' own way of seeing a player: LC.SeenBySecurity).
local function Watched(ply)
    if LC.SeenBySecurity and LC.SeenBySecurity(ply, WATCH) then return true end
    return UnitPlayerSees(ply:EyePos(), ply)
end
local function SpotWatched(pos) return UnitSees(pos) or UnitPlayerSees(pos) end

------------------------------------------------------------------------
-- The contact
------------------------------------------------------------------------

local function Go(npc, st, to, run)
    if LC.RebelHeadFor then return LC.RebelHeadFor(npc, st, to, run) end
    npc:SetLastPosition(to)
    npc:SetSchedule(run and SCHED_FORCED_GO_RUN or SCHED_FORCED_GO)
end

-- No longer the Resistance's to move: cuffed or in a cell, he is the Combine's prisoner as any fighter taken alive.
local function Release(npc, st)
    st.unmanaged, st.questLock, st.eventUntil = nil, nil, nil
    if st.foe == npc then st.foe = nil end
    npc.lcAdminRecruit = nil
end

-- He turns and goes (after `wait` seconds where he stands, if any): back the way he came, and out of the city
-- once nobody can see him.
local function Away(npc, from, now, run, wait)
    if not IsValid(npc) then return end
    local st = LC.NPCs and LC.NPCs[npc]
    if st then st.goingTo = nil end
    leaving[npc] = { since = now + (wait or 0), from = from, run = run or false }
end

local function LeavingTick(now)
    for npc, l in pairs(leaving) do
        local st = IsValid(npc) and npc:Health() > 0 and LC.NPCs[npc] or nil
        if not st then
            leaving[npc] = nil
        elseif TAKEN[st.state] or st.jailUntil then
            leaving[npc] = nil
            Release(npc, st)
        else
            st.eventUntil = now + HOLD
            if st.state ~= "event" then LC.SetState(npc, st, "event") end
            local pos, since = npc:GetPos(), now - l.since
            if since < 0 then
                -- (still by them: the line is being said)
            elseif since >= 2 and (since > LEAVE_MAX or not (LC.IsSeen and LC.IsSeen(pos + UP))) then
                leaving[npc] = nil
                npc:Remove() -- (alive: back in the Resistance's reserve, sv_livingcity_manpower.lua)
            else
                -- back the way he came; watched there too, on to somewhere nobody is looking
                local to = l.to
                if not to then
                    to = l.from
                elseif pos:DistToSqr(to) < 120 * 120 and now >= (l.toAt or 0) then
                    to = (LC.AlarmSquadSpot and LC.AlarmSquadSpot(pos)) or l.from
                end
                if to ~= l.to then l.to, l.toAt, st.goingTo = to, now + 3, nil end
                if to then Go(npc, st, to, l.run) end
            end
        end
    end
end

-- A contact for them, from somewhere near that nobody can see. The man, or nil when it cannot be done now.
local function Send(ply, rec, now)
    if not (LC.SpawnRebel and LC.AdminPlotSpots) then return nil end
    local okP, spots = LC.Try(LC.AdminPlotSpots, ply:GetPos(), 3)
    local pos
    for _, p in ipairs(okP and spots or {}) do
        if not SpotWatched(p + UP) then pos = p break end
    end
    if not pos then return nil end
    local okS, npc, st = LC.Try(LC.SpawnRebel, pos + Vector(0, 0, 4), nil, "") -- (no gun on him)
    if not (okS and IsValid(npc) and st) then return nil end -- (nobody left in the reserve: sv_livingcity_manpower.lua)
    if LC.SquadCasual then LC.SquadCasual(npc, st, true) end -- (plain clothes: a citizen, to the units)
    -- (on top of the city's own numbers, and nobody else's to move, lead or send home meanwhile)
    st.unmanaged, st.questLock, st.zone, st.leaveAt = true, true, nil, nil
    st.foe = npc -- (nobody's enemy, whoever hits him: as a fighter of an ordered attack with nobody to fight)
    st.eventUntil = now + HOLD
    LC.SetState(npc, st, "event")
    npc.lcAdminRecruit = true
    rec.npc, rec.sentAt, rec.from = npc, now, pos
    rec.tries = rec.tries + 1
    if LC.Log then LC.Log("info", string.format("A Resistance contact is sent to %s, who tried to kill the Administrator alone and got away", ply:Nick())) end
    return npc
end

------------------------------------------------------------------------
-- The line, and what it means
------------------------------------------------------------------------

-- It is off for good: caught, dead, or no longer someone it is for.
local function Over(ply, now)
    local rec = owed[ply]
    owed[ply] = nil
    Note(ply).closed = true
    if ply.SetPData then ply:SetPData(KEY, "over") end
    if rec and IsValid(rec.npc) then Away(rec.npc, rec.from, now or CurTime(), false) end
end

-- What a story's invitation does (JoinLater, sv_livingcity_stories.lua): proven, and one of the Resistance. Where
-- they stand and with no line of its own: the one spoken to them has said it. Only now is it kept as done: gone
-- from the server in the moment between, they are still owed it when they come back.
-- Where they arrive (the owner, 18 November: "have them spawn in resistance territory, whichever zone the leader is in;
-- if there is no leader or they aren't in a zone, then maybe wherever a lieutenant is or the zone furthest away (via
-- path node distance) from a combine zone"). The leader: a Commander who is playing and stands on rebel ground; then
-- a Lieutenant; then the rebel zone the longest walk, by the city's path nodes, from the nearest Combine zone (as the
-- crow flies where the paths do not say). In that zone: the Resistance's spawn point nearest whoever they are brought
-- to (or nearest its middle), else a free spot there. nil: no rebel ground on the map, and they stay where they stand.
local function Middle(z)
    if z.box then
        local c = (z.box.mins + z.box.maxs) * 0.5
        c.z = z.box.mins.z + 16
        return c
    end
    return z.pos
end
function LC.AdminRecruitSpot(ply)
    if not (LC.ZonesOfKindShared and LCZ and LCZ.Contains) then return nil end
    local zones = LC.ZonesOfKindShared("rebel") or {}
    if #zones == 0 then return nil end
    local zone, by
    for _, rank in ipairs({ 5, 4 }) do
        for _, p in ipairs(player.GetAll()) do
            if not zone and p ~= ply and p:Alive() and Faction(p) == "resistance" and p:GetNW2Int("lcf_rank", 1) == rank
                and not (LC.Prisoners and LC.Prisoners[p]) then
                for _, z in ipairs(zones) do
                    if not zone and LCZ.Contains(z, p:GetPos(), 0) then zone, by = z, p:GetPos() end
                end
            end
        end
    end
    if not zone then
        local best
        for _, z in ipairs(zones) do
            local m, near = Middle(z), math.huge
            for _, c in ipairs(LC.ZonesOfKindShared("combine") or {}) do
                local cm = Middle(c)
                local d = m and cm and LC.NavWalkDistance and LC.NavWalkDistance(m, cm)
                if not d and m and cm then d = m:Distance(cm) end -- (no path nodes, or no way between them)
                if d then near = math.min(near, d) end
            end
            if m and (not best or near > best) then best, zone = near, z end
        end
        if not zone then return nil end
        by = Middle(zone)
    end
    local spot, sd
    for _, pt in ipairs(LC.PointsOfKind and LC.PointsOfKind("rspawn") or {}) do
        if LCZ.Contains(zone, pt.pos, 0) then
            local d = pt.pos:DistToSqr(by)
            if not sd or d < sd then spot, sd = pt.pos, d end
        end
    end
    spot = spot or by
    return (LC.FreeSpawnPos and LC.FreeSpawnPos(spot + Vector(0, 0, 8))) or spot
end

function LC.AdminRecruitJoin(ply)
    if not (IsValid(ply) and ply:IsPlayer()) then return false end
    local n = notes[ply]
    if not (n and n.joining) then return false end -- (a new character since the line was said: not theirs)
    n.joining = nil
    ply:SetPData(KEY, "done")
    if LC.ResistanceInvite then LC.ResistanceInvite(ply) end
    if Faction(ply) ~= "citizen" or not LC.SetFaction then return false end
    -- a Sympathizer, one job short of a Member (the owner, 18 November: "they join as a sympathizer automatically; but
    -- make it so they get enough experience to be just 1 quest/job away from a member")
    local f = LCF and LCF.Get and LCF.Get("resistance")
    local need = f and f.ranks and f.ranks[2] and f.ranks[2].xp
    if need and (tonumber(ply:GetPData("lcf_xp_resistance", 0)) or 0) < need - SHORT then ply:SetPData("lcf_xp_resistance", need - SHORT) end
    LC.SetFaction(ply, "resistance", nil, true, true)
    -- and on the Resistance's own ground, by their leader (set again once the spawn has settled, as SetFaction does)
    local to = LC.AdminRecruitSpot(ply)
    if to then
        local function There() if IsValid(ply) and ply:Alive() and Faction(ply) == "resistance" then ply:SetPos(to) end end
        There()
        timer.Simple(0.05, There)
        timer.Simple(0.4, There)
    end
    return true
end

-- One of theirs says it to them, and it is done: once for a character.
local function Recruit(ply, npc, now)
    local rec = owed[ply]
    owed[ply] = nil
    local n = Note(ply)
    n.closed, n.joining = true, true
    -- (the contact has done what he came for; or they walked in among the Resistance while he was on his way)
    if rec and IsValid(rec.npc) then Away(rec.npc, rec.from, now, false, rec.npc == npc and LINGER or 0) end
    if npc.lcAdminRecruit then -- (the contact stops where he is and turns to them; one of theirs at home is left as he is)
        if npc.SetSchedule and SCHED_IDLE_STAND then npc:SetSchedule(SCHED_IDLE_STAND) end
        local d = ply:GetPos() - npc:GetPos()
        if d.x ~= 0 or d.y ~= 0 then npc:SetAngles(Angle(0, math.deg(math.atan2(d.y, d.x)), 0)) end
    end
    -- (not recorded yet: a word of greeting in his own voice, as the camp's medic gives, so that it is heard)
    if not (LC.ResistanceSay and LC.ResistanceSay(ply, npc, LINE)) then
        local st = LC.NPCs and LC.NPCs[npc]
        npc:EmitSound("vo/npc/" .. (st and st.gender == "female" and "female" or "male") .. "01/hi0" .. math.random(1, 2) .. ".wav", 70)
    end
    timer.Simple(JOIN_AFTER, function() LC.Try(LC.AdminRecruitJoin, ply) end)
    if LC.Log then LC.Log("info", string.format("%s, who tried to kill the Administrator alone and got away, is taken in by the Resistance", ply:Nick())) end
end

-- On rebel ground: the nearest of the Resistance's own people who can see them (not one in a fight, in cuffs or
-- asleep, nor a fighter of an ordered attack or a contact).
local function Greeter(ply)
    local pos, best, bd = ply:GetPos(), nil, nil
    for npc, st in pairs(LC.NPCs or {}) do
        if IsValid(npc) and st.role == "rebel" and npc:Health() > 0 and not st.test and not TAKEN[st.state] and not st.jailUntil
            and not st.foe and not npc.lcAdminPlot and not npc.lcAdminRecruit
            and not (LC.RebelAsleep and LC.RebelAsleep(st)) then
            local d = npc:GetPos():DistToSqr(pos)
            if d < SEE * SEE and (not bd or d < bd) and Sees(npc, ply, SEE) then best, bd = npc, d end
        end
    end
    return best
end

------------------------------------------------------------------------
-- The attempt
------------------------------------------------------------------------

-- Someone was marked for an attempt on her life. A lone wolf the Resistance would take is owed its welcome from
-- now on; anyone else (under orders, one of the Resistance or the Combine, a rat) is owed nothing. True when owed.
function LC.AdminRecruitAttempt(who, now)
    if not (IsValid(who) and who:IsPlayer() and who.GetPData) then return false end
    now = now or CurTime()
    if owed[who] then return true end
    local n = Note(who)
    if n.closed or (who:GetPData(KEY, "") or "") ~= "" then return false end -- (done or off already: once for a character)
    if (LC.AdminPlotHolds and LC.AdminPlotHolds(who)) or (n.held and now - n.held <= HELD_SECS) then return false end
    if Never(who) then return false end
    who:SetPData(KEY, tostring(os.time()))
    owed[who] = { at = now, since = now, tries = 0, nextTry = 0 }
    return true
end

-- A marked citizen nothing is known of yet: what is kept with the character, or an attempt just made.
local function Look(ply, n, now)
    local kept = ply:GetPData(KEY, "") or ""
    if kept == "done" or kept == "over" then
        n.closed = true
        return
    end
    local t = tonumber(kept)
    if t then -- (owed from before they left the server: the time since counts, the units' sight of them starts again)
        owed[ply] = { at = now - math.max(0, os.time() - t), since = now, tries = 0, nextTry = 0 }
        return
    end
    local mark = tonumber(ply:GetPData("lc_regicide", "")) or 0
    local fresh = mark ~= n.mark and os.time() - mark < FRESH
    n.mark = mark
    if fresh then LC.AdminRecruitAttempt(ply, now) end
end

------------------------------------------------------------------------
-- Twice a second
------------------------------------------------------------------------

local function Step(ply, rec, now)
    local f = Faction(ply)
    if f == "" then return end -- (not in the city yet)
    if f ~= "citizen" or not ply:Alive() or Caught(ply) then return Over(ply, now) end
    local npc = rec.npc
    local st = IsValid(npc) and npc:Health() > 0 and LC.NPCs[npc] or nil
    if npc and (not st or TAKEN[st.state] or st.jailUntil) then
        -- the contact is dead, gone or in cuffs: another, later
        if st then Release(npc, st) end
        rec.npc, rec.nextTry = nil, now + RETRY
        npc, st = nil, nil
    end
    if st then -- (still the Resistance's own to move, whatever else has tried to send him somewhere)
        st.eventUntil = now + HOLD
        if st.state ~= "event" then LC.SetState(npc, st, "event") end
    end
    local function TurnBack()
        if npc then Away(npc, rec.from, now, true) end
        rec.npc, rec.nextTry = nil, now + RETRY
    end
    if Busy(ply) then
        if npc then TurnBack() end
        return
    end
    local among = LC.InRebelZone ~= nil and LC.InRebelZone(ply:GetPos()) == true
    local due = not npc and rec.tries < TRIES and now >= rec.nextTry and now - rec.at >= GOT_AWAY
        and now - math.max(ply.lcWantedSeen or 0, rec.since) >= UNSEEN
    if not (npc or among or due) then return end
    local watched = Watched(ply)

    -- they went to the Resistance: one of its people there says it
    if among and not watched then
        local one = Greeter(ply)
        if one then
            if Never(ply) then return Over(ply, now) end
            return Recruit(ply, one, now)
        end
    end

    -- the Resistance comes to them
    if npc then
        if watched or SpotWatched(npc:EyePos()) or now - rec.sentAt > COME_MAX then return TurnBack() end
        local d2 = npc:GetPos():DistToSqr(ply:GetPos())
        if d2 <= TALK * TALK and Sees(npc, ply, TALK * 2) then
            if Never(ply) then return Over(ply, now) end
            return Recruit(ply, npc, now)
        end
        Go(npc, st, ply:GetPos(), d2 > RUN_BEYOND * RUN_BEYOND)
    elseif due then
        rec.nextTry = now + RETRY
        if watched then return end
        if Never(ply) then return Over(ply, now) end
        Send(ply, rec, now)
    end
end

function LC.AdminRecruitThink(now)
    now = now or CurTime()
    for _, ply in ipairs(player.GetAll()) do
        local n = Note(ply)
        -- (who holds the job or the order: an attempt ends both, and which hook hears it first is not promised)
        if LC.AdminPlotHolds and LC.AdminPlotHolds(ply) then n.held = now end
        -- (the mark is kept with the character, a read of the server's database: looked at when its flag
        -- changes, and every few seconds for a marked citizen nothing is kept for)
        local flagged = ply:GetNW2Bool("lc_regicide", false)
        if flagged ~= n.flag then n.flag, n.look = flagged, 0 end
        if flagged and not n.closed and not owed[ply] and now >= (n.look or 0) and Faction(ply) == "citizen" then
            n.look = now + LOOK_EVERY
            Look(ply, n, now)
        end
    end
    for ply, rec in pairs(owed) do
        if IsValid(ply) then
            Step(ply, rec, now)
        else
            owed[ply] = nil
            if IsValid(rec.npc) then Away(rec.npc, rec.from, now, false) end
        end
    end
    LeavingTick(now)
end

timer.Create("LivingCityAdminRecruit", 0.5, 0, function()
    if not LC.Running or (LC.EndingSession and LC.EndingSession()) then return end
    local okT, err = LC.Try(LC.AdminRecruitThink, CurTime())
    if not okT and LC.Error then LC.Error("admin recruit", err) end
end)

-- Her guards are getting her out: whoever set it off. A grenade by her (it may be heard with her guards switched off).
hook.Add("LivingCityAdminExfil", "LivingCityAdminRecruit", function(_, who)
    LC.Try(LC.AdminRecruitAttempt, who)
end)
hook.Add("LivingCityAdminAttempt", "LivingCityAdminRecruit", function(_, who)
    if LC.AdminNeverForgotten and LC.AdminNeverForgotten(who) then LC.Try(LC.AdminRecruitAttempt, who) end
end)

-- Dead or in a cell: it is off, for that character.
hook.Add("PlayerDeath", "LivingCityAdminRecruit", function(victim)
    if IsValid(victim) and owed[victim] then LC.Try(Over, victim) end
end)
hook.Add("LivingCityIncarcerated", "LivingCityAdminRecruit", function(ply)
    if IsValid(ply) and ply:IsPlayer() and owed[ply] then LC.Try(Over, ply) end
end)
-- A new character starts clean.
hook.Add("LivingCityNewCharacter", "LivingCityAdminRecruit", function(ply)
    if not IsValid(ply) then return end
    local rec = owed[ply]
    owed[ply], notes[ply] = nil, nil
    if ply.RemovePData then ply:RemovePData(KEY) end
    if rec and IsValid(rec.npc) then Away(rec.npc, rec.from, CurTime(), false) end
end)
-- Gone from the server: it is kept with the character; a contact on his way turns back.
hook.Add("PlayerDisconnected", "LivingCityAdminRecruit", function(ply)
    local rec = owed[ply]
    owed[ply], notes[ply] = nil, nil
    if rec and IsValid(rec.npc) then Away(rec.npc, rec.from, CurTime(), false) end
end)

-- It is over at once: every contact is taken out of the city where he stands (the city stopped; tests).
function LC.AdminRecruitEnd()
    for _, rec in pairs(owed) do
        if IsValid(rec.npc) then rec.npc:Remove() end
        rec.npc = nil
    end
    for npc in pairs(leaving) do
        leaving[npc] = nil
        if IsValid(npc) then npc:Remove() end
    end
end
hook.Add("LivingCityStopped", "LivingCityAdminRecruit", function() LC.AdminRecruitEnd() end)
