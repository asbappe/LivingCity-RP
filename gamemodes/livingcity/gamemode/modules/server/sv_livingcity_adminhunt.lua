--[[
    Living City: the hunt for whoever tried to kill the Administrator

    The owner, 16 November: "for an assassination attempt, I would like the wanted
    status to be elevated: I want the combine to HUNT THEM, as in they will send in
    overwatch squads to rebel hideouts to catch the assassin, they will exhaust
    resources until they capture and arrest the assassin."

    Who      a player marked for an attempt on her life (LC.AdminNeverForgotten,
             sv_livingcity_adminsecurity.lua), while they are in the city, alive and
             free: not in custody, not a stalker. One hunt each.
    Squads   every lc_admin_hunt_minutes (4) a squad of up to four Overwatch soldiers
             is sent: by dropship where there is open sky near, else on foot from out
             of sight (the reaction force's way, sv_livingcity_imbalance.lua). It goes
             to where the assassin was last seen; with no sighting under two minutes
             old that has not been searched, to a Resistance hideout: the rebel ground
             searched longest ago (LC.NextSweepZone, the sweeps' own turn-taking). The
             soldiers walk the place's points, fight whoever fires on them, and move on
             to the next hideout, one after another. A squad is out for three of those
             intervals, then goes home and the next one comes. At most two squads out
             at a time, however many are hunted: the hunt that has waited longest gets
             the next one.
    Reserve  every soldier comes out of Overwatch's reserve (sv_livingcity_manpower.lua,
             in SpawnSoldier itself): the dead are lost, those who go home are back in
             it. With nobody left to send the hunt waits for the reserve and goes on.
             It does not stop of itself.
    Seen     a unit sees the assassin, or a scanner's flash catches them: every soldier
             of the hunt is told where, and comes for them, down ladders and off the
             usual ground (LC.ChaseWay, sv_livingcity.lua), into rebel territory too.
    Alive    they are taken as anyone is: unarmed, run down, the struggle and the cuffs;
             armed and shooting, shot at (LC.MakeOneHostile, LC.NPCTakesIn).
    Ends     in a cell, dead, made a stalker, gone from the server, or the mark cleared.
             Free again (a breakout, a rejoin), it starts again.
    Told     the units' radio hears it when a hunt starts, once. Nothing else is put on
             anyone's screen.

      lc_admin_hunt 1/0            the hunt (1)
      lc_admin_hunt_minutes <m>    minutes between the squads sent after one assassin (4)

    Hooks: LivingCityAdminHunt (ply, started): a hunt began (true) or ended (false).
]]

if CLIENT then return end

LC = LC or {}

local FLAGS = bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED)
local cvOn   = CreateConVar("lc_admin_hunt", "1", FLAGS, "Whoever tried to kill the Administrator is hunted: Overwatch squads are sent to where they were seen and to the Resistance's hideouts until they are caught (0: off)")
local cvMins = CreateConVar("lc_admin_hunt_minutes", "4", FLAGS, "Minutes between the Overwatch squads sent after one would-be assassin")

local SQUAD = 4         -- soldiers in a squad (fewer when the reserve is short)
local MAX_OUT = 2       -- squads out at once, in all
local FIRST = 15        -- seconds from the start of a hunt to its first squad
local RETRY = 30        -- nobody to send, or nowhere to come from: again this soon
local STAY = 3          -- a squad is out this many intervals, then goes home
local FRESH = 120       -- a sighting older than this is no longer where to look
local PLACE_SECS = 240  -- at most this long at one place
local LOOK = 3          -- seconds a soldier looks about at each point
local TOLD_EVERY = 600  -- the radio hears of one person's hunt at most this often
local REACH = 8500      -- a soldier this near a sighting goes straight for them (further: he walks there)
local LOOK_EVERY = 3    -- seconds between looks at whether someone marked is free to be hunted
local LOOK_SLOW = 30    -- and at whether someone who does not carry the mark's flag is marked after all
local UP = Vector(0, 0, 50)

LC.AdminHunts = LC.AdminHunts or {}           -- [ply] = { ply, started, nextSquad, seenAt, seenPos, searchedSeen }
LC.AdminHuntSquads = LC.AdminHuntSquads or {} -- { { hunt, units = { { npc, slot, n } }, place, placeAt, pts, untilT, pending }, ... }
local leaving = {}                            -- [npc] = { since, started }: soldiers on their way home
LC.AdminHuntLeaving = leaving

local function Interval() return math.max(0.5, cvMins:GetFloat()) * 60 end

local function Name(ply)
    local c = ply.GetNW2String and ply:GetNW2String("lc_char", "") or ""
    return c ~= "" and c or ply:Nick()
end

-- Marked, alive, and free in the city.
function LC.AdminHunted(ply)
    if not IsValid(ply) or not ply:IsPlayer() or not ply:Alive() then return false end
    if not (LC.AdminNeverForgotten and LC.AdminNeverForgotten(ply)) then return false end
    if (LC.InCustody and LC.InCustody(ply)) or (LC.HeldByCombine and LC.HeldByCombine(ply)) then return false end
    if LC.PlayerIsStalker and LC.PlayerIsStalker(ply) then return false end
    if LC.PlayerIsCP and LC.PlayerIsCP(ply) then return false end -- (the units' own: as for anyone wanted)
    if (ply.lcGraceUntil or 0) > CurTime() then return false end   -- (just let out: the head start anyone gets)
    if ply.lcDreaming or (LC.EditorHeld and LC.EditorHeld(ply)) then return false end
    return true
end

function LC.AdminHuntOf(ply) return LC.AdminHunts[ply] end

------------------------------------------------------------------------
-- Where to look
------------------------------------------------------------------------

-- Where the next squad goes (or a squad done with its place): the last sighting while it is
-- fresh and nobody has been sent to it, else the next hideout in turn.
local function NextPlace(h, now)
    if h.seenPos and h.seenAt ~= h.searchedSeen and now - h.seenAt < FRESH then
        h.searchedSeen = h.seenAt
        return { pos = h.seenPos, seen = true }
    end
    local z = LC.NextSweepZone and LC.NextSweepZone(now)
    if z then return { pos = LCZ and LCZ.Heart and LCZ.Heart(z) or z.pos, zone = z } end
    if h.seenPos then return { pos = h.seenPos, seen = true } end -- (no rebel ground on this map: back where they were last seen)
    return nil
end

local function Apart(pts, p)
    for _, q in ipairs(pts) do if q:DistToSqr(p) < 150 * 150 then return false end end
    return true
end

-- The points of a place: spots spread over a hideout, or the spot they were seen at and the ground round it.
local function Points(place)
    local pts = {}
    if place.zone then
        local want = math.Clamp(math.floor((place.zone.r or 300) / 120), 3, 8)
        for _ = 1, want * 3 do
            if #pts >= want then break end
            local p = LC.SpotInZone and LC.SpotInZone(place.zone)
            if p and Apart(pts, p) then pts[#pts + 1] = p end
        end
        if #pts == 0 then pts[1] = place.pos end
    else
        pts[1] = place.pos
        for _ = 1, 10 do
            if #pts >= 5 then break end
            local p = LC.RandomWanderPos and LC.RandomWanderPos("soldier", place.pos)
            if p and p:DistToSqr(place.pos) < 1200 * 1200 and math.abs(p.z - place.pos.z) < 150 and Apart(pts, p) then pts[#pts + 1] = p end
        end
    end
    return pts
end

local function SetPlace(sq, place, now)
    sq.place, sq.placeAt = place, now
    sq.pts = place and Points(place) or nil
    for _, u in ipairs(sq.units) do
        u.n, u.lookUntil, u.goal, u.tries, u.nextGo = 0, nil, nil, 0, 0
        local st = IsValid(u.npc) and LC.NPCs and LC.NPCs[u.npc]
        if st and place then st.holdPos = place.pos end
    end
end

------------------------------------------------------------------------
-- Sending a squad
------------------------------------------------------------------------

local function SquadsOut()
    local n = 0
    for _, sq in ipairs(LC.AdminHuntSquads) do n = n + 1 end
    return n
end
LC.AdminHuntSquadsOut = SquadsOut

-- One soldier of the squad, out at `at`.
local function Deploy(sq, at, i)
    local spawn = LC.Spawners and LC.Spawners.soldier
    if not spawn or sq.gone then return nil end
    local npc, st = spawn(at + Vector(math.cos(i * 1.6) * 60, math.sin(i * 1.6) * 60, 4))
    if not (IsValid(npc) and st) then return nil end -- (Overwatch's reserve is empty)
    st.unmanaged, st.leaveAt, st.routeGroup = true, nil, nil -- (on top of the city's own numbers, as any squad sent)
    st.adminHunt = sq
    st.holdPos = sq.place and sq.place.pos or nil -- (not sent home to the Combine's ground, not given a beat: LC.SoldierOnDuty)
    sq.units[#sq.units + 1] = { npc = npc, slot = #sq.units, n = 0, tries = 0, nextGo = 0 }
    return npc
end

-- The squad brought in near pos, as the reaction force is: by dropship where there is open sky,
-- else on foot from out of sight. How many are out or on their way.
local function Bring(sq, want, pos)
    local land = LC.QRFLandSpot and LC.QRFLandSpot(pos)
    if land and LC.FlyDropship then
        sq.pending = want
        local landed = false
        local ship = LC.FlyDropship({ pos = land, hold = 6 + want * 1.4, troops = true,
            onLanded = function(_, ground, _, door)
                landed = true
                local at = (door and door.pos) or ground or land
                for i = 1, want do
                    timer.Simple(0.8 + (i - 1) * 1.2, function()
                        sq.pending = math.max(0, (sq.pending or 0) - 1)
                        LC.Try(Deploy, sq, at, i)
                    end)
                end
            end,
            onGone = function() if not landed then sq.pending = 0 end end })
        if ship then return want end
        sq.pending = 0
    end
    local spot = (LC.QRFSpot and LC.QRFSpot(pos)) or (LC.AlarmSquadSpot and LC.AlarmSquadSpot(pos))
    if not spot then return 0 end
    local made = 0
    for i = 1, want do if Deploy(sq, spot, i) then made = made + 1 end end
    return made
end

-- A squad for this hunt. How many soldiers went (0: nobody to send, nowhere to look, or nowhere to come from).
function LC.AdminHuntSend(h, now)
    now = now or CurTime()
    if not LC.Running or not LC.Spawners or not LC.Spawners.soldier then return 0 end
    local want = SQUAD
    if LC.ManpowerOn and LC.ManpowerOn() and LC.ManpowerPool then
        want = math.min(want, math.floor(LC.ManpowerPool("ota").reserve))
    end
    if want <= 0 then return 0 end -- (the reserve is spent: the hunt waits for it)
    local place = NextPlace(h, now)
    if not place then return 0 end
    local sq = { hunt = h, units = {}, started = now, untilT = now + STAY * Interval(), pending = 0 }
    SetPlace(sq, place, now)
    local n = Bring(sq, want, place.pos)
    if n <= 0 then
        sq.gone = true
        if place.seen then h.searchedSeen = nil end -- (nobody went: it is still to be searched)
        return 0
    end
    table.insert(LC.AdminHuntSquads, sq)
    if LC.Log then
        LC.Log("info", string.format("Hunt for %s: a squad of %d sent to %s", IsValid(h.ply) and h.ply:Nick() or "?", n,
            place.zone and "a Resistance hideout" or "where they were last seen"))
    end
    return n
end

------------------------------------------------------------------------
-- Going home
------------------------------------------------------------------------

local function Retire(sq, now)
    sq.gone = true
    for _, u in ipairs(sq.units) do
        local st = IsValid(u.npc) and LC.NPCs and LC.NPCs[u.npc]
        if st then
            st.adminHunt, st.holdPos = nil, nil
            leaving[u.npc] = { since = now }
        end
    end
    sq.units = {}
    for i = #LC.AdminHuntSquads, 1, -1 do
        if LC.AdminHuntSquads[i] == sq then table.remove(LC.AdminHuntSquads, i) end
    end
end

local function LeavingTick(now)
    for npc, l in pairs(leaving) do
        local st = IsValid(npc) and LC.NPCs and LC.NPCs[npc]
        if not st or npc:Health() <= 0 then
            leaving[npc] = nil
        elseif not l.started then
            -- (walking a prisoner in, standing over one cuffed on the street, or in a fight: when that is done)
            local busy = st.marching or st.state == "event" or (st.state == "hostile" and now - l.since < 120)
            if not busy then
                if st.state == "hostile" and LC.CalmOne then LC.CalmOne(npc, st, now) end
                l.started, l.since = true, now
                st.withdrawing = true
                if LC.StartLeaving then LC.StartLeaving(npc, st, false, "a squad of the hunt for the Administrator's attacker going back") end
            end
        elseif now - l.since > 4 and (now - l.since > 180 or not (LC.IsSeen and LC.IsSeen(npc:GetPos() + UP))) then
            leaving[npc] = nil
            npc:Remove() -- (alive: back in Overwatch's reserve, sv_livingcity_manpower.lua)
        end
    end
end

------------------------------------------------------------------------
-- A hunt starts, and ends
------------------------------------------------------------------------

local function FewestSquads(but)
    local best, bn
    for _, h in pairs(LC.AdminHunts) do
        if h ~= but then
            local n = 0
            for _, sq in ipairs(LC.AdminHuntSquads) do if sq.hunt == h then n = n + 1 end end
            if not bn or n < bn then best, bn = h, n end
        end
    end
    return best
end

local function EndHunt(ply, h, now)
    if LC.AdminHunts[ply] ~= h then return end
    LC.AdminHunts[ply] = nil
    -- its squads go to another hunt if there is one, else home
    local other = FewestSquads(h)
    for i = #LC.AdminHuntSquads, 1, -1 do
        local sq = LC.AdminHuntSquads[i]
        if sq.hunt == h then
            if other then
                sq.hunt = other
                SetPlace(sq, NextPlace(other, now), now)
            else
                Retire(sq, now)
            end
        end
    end
    hook.Run("LivingCityAdminHunt", ply, false)
end

local function StartHunt(ply, now)
    local h = { ply = ply, started = now, nextSquad = now + FIRST }
    LC.AdminHunts[ply] = h
    if now - (ply.lcHuntTold or -1e9) > TOLD_EVERY then
        ply.lcHuntTold = now
        if LC.RadioNotice then
            LC.RadioNotice("cp", "Dispatch: all units, " .. Name(ply) .. " tried to kill the Administrator. Overwatch is hunting them. Take them alive.")
        end
    end
    if LC.Log then LC.Log("info", "Hunt for " .. ply:Nick() .. " (an attempt on the Administrator's life) begins") end
    hook.Run("LivingCityAdminHunt", ply, true)
    return h
end

------------------------------------------------------------------------
-- Seen is known
------------------------------------------------------------------------

-- Every soldier of this hunt is told where they are: the near ones go straight for them, the far ones walk there.
local function Converge(h, now)
    local ply, pos = h.ply, h.seenPos
    for _, sq in ipairs(LC.AdminHuntSquads) do
        if sq.hunt == h then
            if not sq.place or not sq.place.seen or sq.place.pos:DistToSqr(pos) > 600 * 600 then
                SetPlace(sq, { pos = pos, seen = true }, now)
            end
            h.searchedSeen = h.seenAt
            for _, u in ipairs(sq.units) do
                local npc = u.npc
                local st = IsValid(npc) and LC.NPCs and LC.NPCs[npc]
                if st and npc:Health() > 0 and not st.marching and (st.state == "idle" or st.state == "moving" or st.enemy == ply)
                    and npc:GetPos():DistToSqr(pos) < REACH * REACH then
                    if st.state ~= "hostile" and LC.MakeOneHostile then LC.MakeOneHostile(npc, st, ply) end
                    -- (as a unit who was shot at: right across the city, and into rebel territory. sv_livingcity.lua)
                    if st.enemy == ply then st.provokedBy, st.provokedUntil = ply, now + 60 end
                end
            end
        end
    end
end

-- Does anyone of the Combine's see them right now? A unit with a line to them, or a scanner's flash.
local function SeenNow(ply, now)
    if LC.FoolsSecurity and LC.FoolsSecurity(ply) then return false end -- (in a stolen uniform, nobody knows them)
    local flash = ply.GetNW2Float and ply:GetNW2Float("lc_spotted_until", 0) or 0
    local flashed = flash ~= (ply.lcHuntFlash or 0) and flash > now
    ply.lcHuntFlash = flash
    if flashed then return true end
    return LC.SeenBySecurity ~= nil and LC.SeenBySecurity(ply, 1500) == true
end

local function Sighted(h, now)
    local ply = h.ply
    h.seenAt, h.seenPos = now, ply:GetPos()
    ply.lcWantedSeen = now -- (dispatch has them: the units told are not calmed as "lost" at once, sv_livingcity_law.lua)
    Converge(h, now)
end

-- An attempt just made is a sighting: they were seen where they stand. (The mark carries its time.)
local function MarkTime(ply)
    return tonumber(ply:GetPData("lc_regicide", "")) or 0
end

------------------------------------------------------------------------
-- The squads at work
------------------------------------------------------------------------

local function Drive(sq, now)
    local pts = sq.pts
    local done, alive = 0, 0
    for i = #sq.units, 1, -1 do
        local u = sq.units[i]
        local npc = u.npc
        local st = IsValid(npc) and LC.NPCs and LC.NPCs[npc]
        if not st or npc:Health() <= 0 then
            table.remove(sq.units, i)
        else
            alive = alive + 1
            if not pts or #pts == 0 or u.n >= #pts then
                done = done + 1
            elseif st.state == "idle" or st.state == "moving" then
                local pt = pts[(u.slot + u.n) % #pts + 1]
                if npc:GetPos():DistToSqr(pt) < 160 * 160 then
                    -- there: a look about, then the next
                    if not u.lookUntil then
                        u.lookUntil = now + LOOK
                        if LC.FaceOut then LC.FaceOut(npc, sq.place.pos) end
                    elseif now >= u.lookUntil then
                        u.n, u.lookUntil, u.goal, u.tries, u.nextGo = u.n + 1, nil, nil, 0, 0
                    end
                elseif st.state == "idle" and now >= u.nextGo then
                    u.tries = u.goal == pt and u.tries + 1 or 1
                    if u.tries > 4 then
                        u.n, u.goal, u.tries, u.nextGo = u.n + 1, nil, 0, 0 -- (no way to this one: the next)
                    else
                        u.goal, u.nextGo = pt, now + 6
                        st.holdPos = pt
                        -- along the city's own routes (ladders and all); the engine's straight try if they have none
                        if not (LC.GoTo and LC.GoTo(npc, st, pt, true)) then
                            npc:SetLastPosition(pt)
                            npc:SetSchedule(SCHED_FORCED_GO_RUN)
                        end
                    end
                end
            end
        end
    end
    return alive, done
end

function LC.AdminHuntTick(now)
    now = now or CurTime()
    local on = cvOn:GetBool() and LC.Running and not (LC.EndingSession and LC.EndingSession())

    -- who is hunted
    for ply, h in pairs(LC.AdminHunts) do
        if not on or not LC.AdminHunted(ply) then EndHunt(ply, h, now) end
    end
    if on then
        for _, ply in ipairs(player.GetAll()) do
            -- (the mark itself is kept with the character, a read of the server's database: looked at every
            -- few seconds for those who carry its flag, at once when the flag changes, seldom for everyone else)
            local flagged = ply.GetNW2Bool ~= nil and ply:GetNW2Bool("lc_regicide", false) or false
            if not LC.AdminHunts[ply] and (now >= (ply.lcHuntLook or 0) or flagged ~= ply.lcHuntFlag) then
                ply.lcHuntFlag = flagged
                ply.lcHuntLook = now + (flagged and LOOK_EVERY or LOOK_SLOW)
                if LC.AdminHunted(ply) then StartHunt(ply, now) end
            end
        end
    end

    -- seen is known
    for ply, h in pairs(LC.AdminHunts) do
        -- (an attempt just made, a new mark or the old one made again: they were seen where they stand)
        local t = MarkTime(ply)
        local fresh = t ~= ply.lcHuntMark and os.time() - t < 60
        ply.lcHuntMark = t
        if fresh or SeenNow(ply, now) then Sighted(h, now) end
    end

    -- the squads out: at their place, on to the next, and home when their time is up
    for i = #LC.AdminHuntSquads, 1, -1 do
        local sq = LC.AdminHuntSquads[i]
        local alive, done = Drive(sq, now)
        if alive == 0 and (sq.pending or 0) <= 0 then
            sq.gone = true
            table.remove(LC.AdminHuntSquads, i)
        elseif now >= sq.untilT and not (sq.hunt.seenAt and now - sq.hunt.seenAt < 30) then
            Retire(sq, now) -- (never in the middle of a chase: once they have been out of sight half a minute)
        elseif alive > 0 and (not sq.place or done >= alive or now - sq.placeAt > PLACE_SECS) and now >= (sq.nextPlace or 0) then
            sq.nextPlace = now + 10
            local place = NextPlace(sq.hunt, now)
            if place then SetPlace(sq, place, now) end
        end
    end
    LeavingTick(now)

    -- the next squad: the hunt that has waited longest, while there is room for one
    if on and SquadsOut() < MAX_OUT then
        local due
        for _, h in pairs(LC.AdminHunts) do
            if now >= h.nextSquad and (not due or h.nextSquad < due.nextSquad) then due = h end
        end
        if due then
            local n = LC.AdminHuntSend(due, now)
            due.nextSquad = now + (n > 0 and Interval() or RETRY)
        end
    end
end

timer.Create("LivingCityAdminHunt", 1, 0, function()
    if next(LC.AdminHunts) == nil and next(leaving) == nil and #LC.AdminHuntSquads == 0 and #player.GetAll() == 0 then return end
    local ok, err = LC.Try(LC.AdminHuntTick, CurTime())
    if not ok and LC.Error then LC.Error("admin hunt", err) end
end)

-- An attempt while they are hunted already: they were seen making it.
hook.Add("LivingCityAdminAttempt", "LivingCityAdminHunt", function(_, who)
    local h = IsValid(who) and LC.AdminHunts[who]
    if h then LC.Try(Sighted, h, CurTime()) end
end)
-- In a cell: over, at once.
hook.Add("LivingCityIncarcerated", "LivingCityAdminHunt", function(ply)
    local h = IsValid(ply) and LC.AdminHunts[ply]
    if h then LC.Try(EndHunt, ply, h, CurTime()) end
end)
hook.Add("LivingCityStopped", "LivingCityAdminHunt", function()
    LC.AdminHunts, LC.AdminHuntSquads = {}, {}
    for npc in pairs(leaving) do leaving[npc] = nil end
end)
