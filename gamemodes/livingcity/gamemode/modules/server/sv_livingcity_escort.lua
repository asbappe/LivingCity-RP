--[[
    Living City: escorts through Combine doors

    A Union worker on a job (a shift or an assignment from their board) whose
    work is behind Combine doors asks for an escort: the quick menu (F2 or
    C: Getting by > Ask for a Civil Protection escort), or !escort. The
    nearest free unit comes for them; or a player unit takes it, from their
    own actions menu (Civil Protection > Escort requests), whenever they like.

    While their escort is close, Combine doors open for them (E on one: the
    unit buzzes them through), forcefields let them by, and they aren't
    trespassing in Combine-only areas. The unit follows them about, and opens
    the doors it walks through.

    The unit watches the doors it opens. If someone else slips through behind
    the worker (a rebel, anyone with no business in there), or a prisoner gets
    out through one, it breaks off to deal with them: it goes after the
    intruder, or marches the prisoner back to their cell. It radios that the
    worker is unattended, and the nearest free unit comes to take over. It
    goes on the worker's file and costs them standing; let it happen twice on
    one job and dispatch won't send anyone else with them for a while. A unit
    called away by anything else (a crime nearby, being shot at) hands over
    the same way.

    When the job's over, the escort walks them out to the release point (the
    way out of the prison, outside the Combine area) and leaves them there.
    With no release point on the map, they see them out of the Combine area.
    A worker who never went through a Combine door is just left to it.

    (Half-Life 2's own "follow me" squads only work for rebels, not Civil
    Protection, so a unit follows the city's own way, as a Resistance fighter
    does: sv_livingcity_rebels.lua.)
]]

if CLIENT then return end

LC = LC or {}
LC.Escorts = LC.Escorts or {}       -- [worker] = escort
LC.Recaptures = LC.Recaptures or {} -- { cop, prisoner, untilT }

local FLAGS = bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED)
local cvOn       = CreateConVar("lc_escorts", "1", FLAGS, "Union workers on a job can ask for a Civil Protection escort through Combine doors")
local cvRange    = CreateConVar("lc_escort_range", "6000", FLAGS, "How far away a Civil Protection unit can be sent from to escort someone")
local cvHandover = CreateConVar("lc_escort_handover", "60", FLAGS, "Seconds an unattended worker is still covered while another Civil Protection unit comes")
local cvBan      = CreateConVar("lc_escort_ban_minutes", "10", FLAGS, "Minutes nobody will escort a worker who let someone through twice on one job")

local NEAR_DOOR = 450   -- how close the escort has to be for a door to open for them
local FOLLOW = 180      -- the unit keeps about this close
local LOST = 900        -- further than this from their escort, for LOST_SECS, and they're on their own
local LOST_SECS = 15
local ARRIVED = 230
local DOORWAY = 72      -- standing in the doorway itself
local WATCH = 260       -- how far round a door the unit keeps an eye
local WAIT_SECS = 180   -- a request nobody takes lapses

local function Units() local o = {} for _, p in ipairs(player.GetAll()) do if LC.PlayerIsCP(p) then o[#o + 1] = p end end return o end
local function Where(pos) return LC.DescribePlace and LC.DescribePlace(pos) or "" end
local function Radio(text)
    if LC.RadioNotice then LC.RadioNotice("cp", text) return end
    for _, u in ipairs(Units()) do u:ChatPrint("[CP net] " .. text) end
end
local function Say(ply, text) if IsValid(ply) then ply:ChatPrint(text) end end
local function Voice(npc, name) if IsValid(npc) and npc:IsNPC() then npc:EmitSound("npc/metropolice/vo/" .. name .. ".wav", 75) end end
local function NameOf(ply) return LC.CharacterName and LC.CharacterName(ply) or ply:Nick() end

-- What a unit is called on the radio.
function LC.UnitDesignation(u)
    if not IsValid(u) then return "A Civil Protection unit" end
    if u:IsPlayer() then
        local t = u:GetNW2String("lcf_title", "")
        return t ~= "" and t or u:Nick()
    end
    return "Unit " .. (10 + u:EntIndex() % 90)
end
local Desig = LC.UnitDesignation

-- In the Combine's part of the city (a Combine-only zone, or the prison).
local function Inside(pos)
    return (LC.CombineZoneAt and LC.CombineZoneAt(pos) ~= nil) or (LC.PrisonZoneAt and LC.PrisonZoneAt(pos) ~= nil)
end
local function HasZones()
    return #(LC.ZonesOfKindShared and LC.ZonesOfKindShared("combine") or {}) + #(LC.ZonesOfKindShared and LC.ZonesOfKindShared("prison") or {}) > 0
end

local function Flat(a, b, r)
    local dx, dy = a.x - b.x, a.y - b.y
    return dx * dx + dy * dy < r * r and math.abs(a.z - b.z) < 100
end

------------------------------------------------------------------------
-- Who can have one, and who can give one
------------------------------------------------------------------------

-- A Union worker, on a job.
function LC.MayHaveEscort(ply)
    if not cvOn:GetBool() then return false, "Escorts are off on this server." end
    if not IsValid(ply) or not ply:IsPlayer() or not ply:Alive() then return false end
    if LC.PlayerIsCP(ply) then return false, "You're a Civil Protection unit. You open those doors yourself." end
    if LC.PlayerIsZombie(ply) then return false end
    if LC.InCustody and LC.InCustody(ply) then return false, "Not from in here." end
    if not (LC.Job and LC.Job(ply)) then return false, "Only Union workers get an escort: take a Union job from your board (F4)." end
    if not (LC.QuestOf and LC.QuestOf[ply]) then return false, "You need to be on a job: accept a shift from your board (F4) first." end
    if LC.PlayerIsWanted(ply) then return false, "Civil Protection doesn't escort wanted people." end
    if (ply.lcEscortBanUntil or 0) > CurTime() then
        return false, "Dispatch won't send anyone with you. (" .. math.ceil((ply.lcEscortBanUntil - CurTime()) / 60) .. " min)"
    end
    return true
end

-- A unit with nothing more pressing on.
local FREE = { idle = true, moving = true, working = true }
local function FreeUnit(npc, st, now)
    return IsValid(npc) and st.role == "cop" and npc:Health() > 0 and FREE[st.state] and not st.workEscort
        and not st.raid and not st.questLock and not st.escortee and not st.subject and not st.skirmish
        and (st.stunnedUntil or 0) < now
end

local function NearestFreeUnit(pos, except)
    local now, r2 = CurTime(), cvRange:GetFloat() ^ 2
    local best, bd
    for npc, st in pairs(LC.NPCs or {}) do
        if FreeUnit(npc, st, now) and not (except and (except[npc] or 0) > now) then
            local d = npc:GetPos():DistToSqr(pos)
            if d < r2 and (not bd or d < bd) then best, bd = npc, d end
        end
    end
    return best
end
LC.NearestFreeEscort = NearestFreeUnit

------------------------------------------------------------------------
-- Moving the unit
------------------------------------------------------------------------

local function HeadFor(npc, st, pos, run)
    if not st.goingTo or st.goingTo:DistToSqr(pos) > 80 * 80
        or not (npc:IsCurrentSchedule(SCHED_FORCED_GO_RUN) or npc:IsCurrentSchedule(SCHED_FORCED_GO)) then
        st.goingTo = pos
        npc:SetLastPosition(pos)
        npc:SetSchedule(run and SCHED_FORCED_GO_RUN or SCHED_FORCED_GO)
    end
end

local function Stop(npc, st)
    if st.goingTo then
        st.goingTo = nil
        npc:SetSchedule(SCHED_IDLE_STAND)
    end
end

-- Walk to dest along the city's routes (the doors on the way open for a unit:
-- sv_livingcity_doors.lua looks at the next hop).
local function Steer(npc, st, dest, run, now)
    if not st.route or not st.routeTo or st.routeTo:DistToSqr(dest) > 250 * 250 or now > (st.routeAt or 0) + 8 then
        local route = LC.BuildRoute and LC.BuildRoute(npc:GetPos(), dest, "cop")
        st.route = (istable(route) and #route > 0) and route or { dest }
        st.hop, st.routeTo, st.routeAt = 1, dest, now
    end
    local pos = npc:GetPos()
    while st.hop < #st.route and pos:DistToSqr(st.route[st.hop]) < 96 * 96 do st.hop = st.hop + 1 end
    HeadFor(npc, st, st.hop >= #st.route and dest or st.route[st.hop], run)
end

------------------------------------------------------------------------
-- Escorts
------------------------------------------------------------------------

local function Publish(e)
    local w = e.worker
    if not IsValid(w) then return end
    w:SetNW2Entity("lc_escort", (e.unit and IsValid(e.unit)) and e.unit or NULL)
    w:SetNW2String("lc_escort_name", (e.unit and IsValid(e.unit)) and Desig(e.unit) or "")
    w:SetNW2String("lc_escort_phase", e.over and "" or e.phase)
    w:SetNW2Float("lc_escort_grace", e.phase == "unattended" and (e.graceUntil or 0) or 0)
end

local function Unassign(e)
    local u = e.unit
    e.unit = nil
    if not IsValid(u) then return u end
    if u:IsPlayer() then
        u:SetNW2Entity("lc_escorting", NULL)
        return u
    end
    local st = LC.NPCs and LC.NPCs[u]
    if st and st.workEscort == e then
        st.workEscort = nil
        st.route, st.routeTo, st.goingTo = nil, nil, nil
        LC.SetNPCStr(u, "lc_doing", "")
        if st.state == "workescort" then
            LC.SetState(u, st, "idle")
            st.untilT = CurTime() + 2
            u:SetSchedule(SCHED_IDLE_STAND)
        end
    end
    return u
end

local function Assign(e, u)
    e.unit = u
    e.arrived = false
    if u:IsPlayer() then
        u:SetNW2Entity("lc_escorting", e.worker)
    else
        local st = LC.NPCs[u]
        if LC.Release then LC.Release(u, st) end
        if LC.NPCWorkReset then LC.NPCWorkReset(u, st) end
        st.workEscort = e
        st.route, st.routeTo, st.goingTo = nil, nil, nil
        LC.SetState(u, st, "workescort")
        LC.SetNPCStr(u, "lc_doing", "escorting " .. NameOf(e.worker))
        Voice(u, math.random() < 0.5 and "copy" or "rodgerthat")
    end
    e.phase = (e.phase == "unattended" or e.phase == "waiting") and "coming" or e.phase
    if e.phase ~= "coming" then e.phase = "coming" end
    Publish(e)
end

-- Over: the unit goes back to its beat.
function LC.EndEscort(e, msg)
    if not e or e.over then return end
    e.over = true
    local u = Unassign(e)
    if LC.Escorts[e.worker] == e then LC.Escorts[e.worker] = nil end
    local w = e.worker
    if IsValid(w) then
        w:SetNW2Bool("lc_escort_wait", false)
        Publish(e)
        if msg then Say(w, msg) end
    end
    hook.Run("LivingCityEscortEnded", w, u, e.why)
end

local function End(e, why, msg) e.why = why return LC.EndEscort(e, msg) end

-- Find them a unit (anyone but the ones who just left).
local function Dispatch(e)
    local npc = NearestFreeUnit(e.worker:GetPos(), e.except)
    if not npc then return false end
    local handover = e.phase == "unattended"
    Assign(e, npc)
    e.worker:SetNW2Bool("lc_escort_wait", false)
    if handover then
        e.graceUntil = math.max(e.graceUntil or 0, CurTime() + 45) -- (still covered while they come)
        Say(e.worker, "[Union] " .. Desig(npc) .. " is coming to take over your escort. Stay where you are.")
        Radio(Desig(npc) .. ": copy, taking over the escort of " .. NameOf(e.worker) .. ".")
    else
        Say(e.worker, "[Union] " .. Desig(npc) .. " is on the way to escort you. Wait for them.")
    end
    return true
end

-- Ask for one.
function LC.RequestEscort(ply)
    local ok, why = LC.MayHaveEscort(ply)
    if not ok then return false, why end
    local cur = LC.Escorts[ply]
    if cur then return false, "You've already got " .. (IsValid(cur.unit) and Desig(cur.unit) or "an escort on the way") .. "." end
    local e = { worker = ply, quest = LC.QuestOf[ply], phase = "waiting", since = CurTime(), strikes = 0, doors = {}, except = {} }
    LC.Escorts[ply] = e
    local job = LC.Job(ply)
    Radio(string.format("Escort requested: %s, Union %s, %s.%s", NameOf(ply), job and job.name or "worker", Where(ply:GetPos()),
        " (Actions menu: Civil Protection > Escort requests.)"))
    if Dispatch(e) then return true end
    ply:SetNW2Bool("lc_escort_wait", true)
    Publish(e)
    return true, "[Union] No Civil Protection unit's free right now. Dispatch has your request; wait for one."
end

-- Dismiss it yourself.
function LC.DismissEscort(ply)
    local e = LC.Escorts[ply]
    if not e then return false, "You haven't got an escort." end
    local u = e.unit
    if IsValid(u) and u:IsPlayer() then Say(u, "[CP net] " .. NameOf(ply) .. " has dismissed you.") end
    End(e, "dismissed", "[Union] You send your escort away." .. (Inside(ply:GetPos()) and " You're in a restricted area: leave it." or ""))
    return true
end

-- A player unit takes it on (from an NPC unit, or a request nobody's answered).
function LC.TakeEscort(unit, worker)
    if not IsValid(unit) or not LC.PlayerIsCP(unit) then return false, "Civil Protection units only." end
    if not IsValid(worker) or not worker:IsPlayer() then return false, "Look at the worker, or pick them from Escort requests." end
    local e = LC.Escorts[worker]
    if e and e.unit == unit then return false, "You're already escorting them." end
    if not e then
        local ok, why = LC.MayHaveEscort(worker)
        if not ok then return false, why or "They aren't on a job." end
        e = { worker = worker, quest = LC.QuestOf[worker], phase = "waiting", since = CurTime(), strikes = 0, doors = {}, except = {} }
        LC.Escorts[worker] = e
    end
    for _, other in pairs(LC.Escorts) do
        if other ~= e and other.unit == unit then return false, "Finish the escort you're on first." end
    end
    local was = Unassign(e)
    if IsValid(was) and not was:IsPlayer() then Voice(was, "affirmative") end
    local resume = e.phase == "out" and "out" or nil
    Assign(e, unit)
    e.resume = resume or e.resume
    worker:SetNW2Bool("lc_escort_wait", false)
    Say(worker, "[Union] " .. Desig(unit) .. " is escorting you.")
    Say(unit, "[CP net] You're escorting " .. NameOf(worker) .. (e.phase == "out" and ": walk them out to the release point." or
        ". Keep them close and open the doors they need. Actions menu to hand it back."))
    return true
end

-- A player unit hands it back: the next free unit takes over.
function LC.DropEscort(unit)
    for _, e in pairs(LC.Escorts) do
        if e.unit == unit then
            LC.EscortUnattended(e, Desig(unit) .. ": handing off the escort of " .. NameOf(e.worker) .. ", " .. Where(e.worker:GetPos()) .. ".", "handed off")
            Say(unit, "[CP net] You hand the escort back to dispatch.")
            return true
        end
    end
    return false, "You aren't escorting anyone."
end

-- The unit's gone (called away, hurt, or handing off): another comes.
function LC.EscortUnattended(e, radioText, why)
    local u = Unassign(e)
    if IsValid(u) then e.except[u] = CurTime() + 90 end
    e.resume = (e.phase == "out" or e.resume == "out") and "out" or e.resume
    e.phase = "unattended"
    e.why = why
    e.graceUntil = CurTime() + cvHandover:GetFloat()
    e.nextDispatch = CurTime() + 1.5 -- (the radio call first)
    e.lostSince = nil
    e.doors = {} -- (the next unit watches the doors it opens itself)
    if radioText then Radio(radioText .. " Worker unattended: nearest free Civil Protection unit, take over.") end
    Say(e.worker, "[Union] Your escort's been called away. Stay where you are: another Civil Protection unit is coming.")
    Publish(e)
end

local function Unattended(e, text, why) return LC.EscortUnattended(e, text, why) end

-- Is someone covered by an escort right now? (Not trespassing, and Combine doors open for them.)
function LC.EscortCovers(ply)
    local e = LC.Escorts[ply]
    if not e or e.over then return false end
    if e.phase == "with" or e.phase == "out" then return true end
    return CurTime() < (e.graceUntil or 0)
end

function LC.EscortOf(ply)
    local e = LC.Escorts[ply]
    return e and not e.over and e or nil
end

------------------------------------------------------------------------
-- Doors, and who comes through them
------------------------------------------------------------------------

-- A door the escort opened: keep an eye on it while it's open.
function LC.EscortWatchDoor(e, door)
    if not e or e.over or not IsValid(door) then return end
    local entry = e.doors[door]
    local now = CurTime()
    if entry and entry.untilT > now then entry.untilT = now + 10 return end
    local pos = door:WorldSpaceCenter()
    local inside = {}
    for _, p in ipairs(player.GetAll()) do
        if p:GetPos():DistToSqr(pos) < (WATCH * 2) ^ 2 and Inside(p:GetPos()) then inside[p] = true end
    end
    e.doors[door] = { pos = pos, untilT = now + 10, inside = inside }
end

-- E on a Combine door with their escort close by: the unit buzzes them through.
hook.Add("LivingCityCanUseCPDoor", "LivingCityEscort", function(ply, door)
    local e = LC.Escorts[ply]
    if not e or e.over or not (e.phase == "with" or e.phase == "out") then return end
    local u = e.unit
    if not IsValid(u) or u:GetPos():DistToSqr(door:WorldSpaceCenter()) > NEAR_DOOR * NEAR_DOOR then return end
    LC.EscortWatchDoor(e, door)
    e.passed = true
    if not u:IsPlayer() then
        if LC.Face then LC.Face(u, door:WorldSpaceCenter()) end
        door:EmitSound("buttons/combine_button1.wav", 65)
        if (e.toldDoor or 0) < CurTime() then
            e.toldDoor = CurTime() + 30
            Say(ply, "[Union] " .. Desig(u) .. " buzzes you through.")
        end
    end
    return true
end)

-- Someone who may go through a Combine door, as far as a unit's concerned.
local function Authorized(p)
    return LC.PlayerIsCP(p) or (LC.FoolsSecurity and LC.FoolsSecurity(p)) or (LC.IsBuilder and LC.IsBuilder(p))
        or LC.PlayerIsZombie(p) or LC.EscortCovers(p)
end

-- Someone slipped in behind the worker.
local function Tailgated(e, intruder, entry)
    local u, w = e.unit, e.worker
    local st = LC.NPCs[u]
    e.strikes = e.strikes + 1
    Voice(u, math.random() < 0.5 and "holdit" or "freeze")
    LC.ReportCrime(intruder, "Unauthorized access", 180)
    local where = Where(entry.pos)
    Unattended(e, string.format("%s: intruder through a Combine door %s, in pursuit.", Desig(u), where), "intruder")
    if st and LC.MakeOneHostile then LC.MakeOneHostile(u, st, intruder) end
    if LC.AddStanding then LC.AddStanding(w, -10, "someone followed you through a Combine door") end
    if LC.AddViolation then LC.AddViolation(w, "Under escort, let someone through a Combine door") end
    Say(intruder, "[Civil Protection] \"Hold it!\" A Civil Protection unit saw you slip through behind the worker.")
    hook.Run("LivingCityEscortTricked", w, u, intruder, "intruder")
end

-- A prisoner got out of a door the unit opened.
local function PrisonerOut(e, prisoner, entry)
    local u, w = e.unit, e.worker
    local st = LC.NPCs[u]
    e.strikes = e.strikes + 1
    Voice(u, "dontmove")
    Unattended(e, string.format("%s: prisoner out of a cell %s, returning them.", Desig(u), Where(entry.pos)), "prisoner")
    if st then
        LC.Recaptures[#LC.Recaptures + 1] = { cop = u, prisoner = prisoner, untilT = CurTime() + 40, nextGo = 0 }
        if LC.GoTo then LC.GoTo(u, st, prisoner:GetPos(), true, nil) end
    end
    if LC.AddStanding then LC.AddStanding(w, -15, "a prisoner got out through a door your escort opened") end
    if LC.AddViolation then LC.AddViolation(w, "Under escort, had a cell door opened: a prisoner got out") end
    Say(prisoner, "[Civil Protection] \"Don't move!\" The Civil Protection unit's seen you.")
    hook.Run("LivingCityEscortTricked", w, u, prisoner, "prisoner")
end

-- Twice on one job, and that's the last escort they get for a while.
local function CheckStrikes(e)
    if e.strikes < 2 or e.over then return false end
    local w = e.worker
    w.lcEscortBanUntil = CurTime() + cvBan:GetFloat() * 60
    Radio("Dispatch: no further escorts for " .. NameOf(w) .. ". Twice now.")
    End(e, "banned", "[Union] Dispatch won't send anyone else with you. Get out of the restricted area.")
    return true
end

local function WatchDoors(e, now)
    local w = e.worker
    for door, entry in pairs(e.doors) do
        if entry.untilT < now or not IsValid(door) then
            e.doors[door] = nil
        else
            for _, p in ipairs(player.GetAll()) do
                if p ~= w and p:Alive() and p:GetPos():DistToSqr(entry.pos) < WATCH * WATCH then
                    if LC.Prisoners and LC.Prisoners[p] then
                        if Flat(p:GetPos(), entry.pos, DOORWAY * 1.8) then PrisonerOut(e, p, entry) return end
                    elseif not Authorized(p) and (Flat(p:GetPos(), entry.pos, DOORWAY) or (Inside(p:GetPos()) and not entry.inside[p])) then
                        Tailgated(e, p, entry)
                        return
                    end
                end
            end
        end
    end
end

------------------------------------------------------------------------
-- The job's over: out to the release point
------------------------------------------------------------------------

local function NearestRelease(pos)
    local best, bd
    for _, p in ipairs(LC.PointsOfKind and LC.PointsOfKind("release") or {}) do
        local d = p.pos:DistToSqr(pos)
        if not bd or d < bd then best, bd = p, d end
    end
    return best
end

local function BeginOut(e)
    local w = e.worker
    if not (Inside(w:GetPos()) or e.passed) then
        return End(e, "done", "[Union] Your job's done. Your escort heads back to their beat.")
    end
    local rel = NearestRelease(w:GetPos())
    if not rel and not HasZones() then
        return End(e, "done", "[Union] \"You're done. Out the way you came.\" Your escort heads back.")
    end
    e.phase, e.outTo, e.outSince = "out", rel and rel.pos or nil, CurTime()
    local u = e.unit
    if IsValid(u) and u:IsPlayer() then
        Say(u, "[CP net] " .. NameOf(w) .. "'s job is done: walk them out" .. (rel and " to the release point." or " of the Combine area."))
    elseif IsValid(u) then
        Voice(u, "keepmoving")
    end
    Say(w, "[Union] \"You're done here. This way.\" Your escort walks you out" .. (rel and " to the release point." or ".") .. " Stay with them.")
    Publish(e)
end

local function OutDone(e)
    local w = e.worker
    if e.outTo then return w:GetPos():DistToSqr(e.outTo) < 220 * 220 end
    return not Inside(w:GetPos())
end

local function FinishOut(e)
    local u = e.unit
    if IsValid(u) and not u:IsPlayer() then Voice(u, math.random() < 0.5 and "movealong" or "allrightyoucango") end
    if IsValid(u) and u:IsPlayer() and LC.AddXP then LC.AddXP(u, 5, "escort") end
    Radio((IsValid(u) and Desig(u) or "Dispatch") .. ": escort of " .. NameOf(e.worker) .. " complete.")
    End(e, "complete", "[Union] \"Move along.\" You're out, and your escort leaves you here.")
end

------------------------------------------------------------------------
-- Every half second
------------------------------------------------------------------------

local function DriveNPC(e, u, st, now)
    local w = e.worker
    local wp, up = w:GetPos(), u:GetPos()
    local d2 = wp:DistToSqr(up)
    if e.phase == "coming" then
        if d2 < ARRIVED * ARRIVED then
            e.phase = e.resume == "out" and "out" or "with"
            e.resume = nil
            e.lostSince = nil
            Stop(u, st)
            if LC.Face then LC.Face(u, wp) end
            Voice(u, e.phase == "out" and "keepmoving" or "allrightyoucango")
            Say(w, "[Union] " .. Desig(u) .. ": \"" .. (e.phase == "out" and "Out. This way." or "Stay close, and don't touch anything.") .. "\"")
            Publish(e)
        else
            Steer(u, st, wp, d2 > 600 * 600, now)
        end
        return
    end
    -- too far from their escort for too long: on their own
    if d2 > LOST * LOST then
        e.lostSince = e.lostSince or now
        if now - e.lostSince > LOST_SECS then
            if LC.AddStanding and Inside(wp) then LC.AddStanding(w, -5, "you slipped your escort") end
            Radio(Desig(u) .. ": " .. NameOf(w) .. " slipped their escort " .. Where(wp) .. ".")
            return End(e, "slipped", "[Union] You left your escort behind. You're on your own in there.")
        end
    else
        e.lostSince = nil
    end
    if e.phase == "with" then
        if d2 > FOLLOW * FOLLOW then
            local behind = wp - Angle(0, w:EyeAngles().y, 0):Forward() * 70
            Steer(u, st, behind, d2 > 450 * 450, now)
        else
            Stop(u, st)
            if now > (e.nextFace or 0) then e.nextFace = now + 3 if LC.Face then LC.Face(u, wp) end end
        end
    elseif e.phase == "out" then
        if OutDone(e) then return FinishOut(e) end
        if d2 > 380 * 380 then
            -- wait for them
            Stop(u, st)
            if LC.Face then LC.Face(u, wp) end
            if now > (e.nextNag or 0) then
                e.nextNag = now + 10
                Voice(u, "keepmoving")
                Say(w, "[Union] " .. Desig(u) .. ": \"Keep up.\"")
            end
        elseif e.outTo then
            Steer(u, st, e.outTo, false, now)
        else
            -- no release point: follow them out
            if d2 > FOLLOW * FOLLOW then Steer(u, st, wp, false, now) else Stop(u, st) end
        end
        if now - (e.outSince or now) > 240 then return End(e, "timeout", "[Union] Your escort leaves you to find your own way out.") end
    end
end

-- Forcefields: the unit swipes them through.
local function Forcefields(e, now)
    local w, u = e.worker, e.unit
    if not IsValid(u) then return end
    for _, f in ipairs(LC.EntsOf("lc_forcefield")) do
        if f.FieldUp and f:FieldUp() and f:GetPos():DistToSqr(w:GetPos()) < 150 * 150 and f:GetPos():DistToSqr(u:GetPos()) < 400 * 400
            and w:GetNW2Float("lc_ffpass_until", 0) < now + 1 then
            w:SetNW2Float("lc_ffpass_until", now + 3)
            if LC.FieldRulesChanged then LC.FieldRulesChanged(w) end
        end
    end
end

local function TickOne(e, now)
    local w = e.worker
    if not IsValid(w) then return End(e, "gone") end
    if not w:Alive() or (LC.InCustody and LC.InCustody(w)) or LC.PlayerIsCP(w) then return End(e, "gone") end
    -- the job: over, or a new one
    local q = LC.QuestOf and LC.QuestOf[w]
    if q ~= e.quest then
        e.quest = q
        if q then
            if e.phase == "out" then e.phase, e.outTo = "with", nil Publish(e) end
            if e.resume == "out" then e.resume = nil end
        elseif e.phase == "with" then
            BeginOut(e)
            if e.over then return end
        elseif e.phase == "waiting" then
            return End(e, "done", "[Union] Your job's over. Dispatch cancels the escort request.")
        else
            e.resume = "out" -- (a unit's on the way, or will be: they'll walk you out)
        end
    end
    local u = e.unit
    if u ~= nil then
        if u:IsPlayer() and IsValid(u) then
            if not u:Alive() or not LC.PlayerIsCP(u) then
                return Unattended(e, Desig(u) .. ": escort of " .. NameOf(w) .. " interrupted, " .. Where(w:GetPos()) .. ".", "Civil Protection unit down")
            end
            if e.phase == "coming" and w:GetPos():DistToSqr(u:GetPos()) < ARRIVED * ARRIVED then
                e.phase = e.resume == "out" and "out" or "with"
                e.resume = nil
                Publish(e)
            end
            if e.phase == "out" and OutDone(e) then return FinishOut(e) end
            Forcefields(e, now)
            return
        end
        local st = IsValid(u) and LC.NPCs and LC.NPCs[u]
        if not st or u:Health() <= 0 or st.workEscort ~= e or st.state ~= "workescort" then
            -- called away (a crime nearby, someone shooting), or down
            local down = not st or not IsValid(u) or u:Health() <= 0
            return Unattended(e, (down and "Dispatch: escort Civil Protection unit down" or (Desig(u) .. ": called away")) .. ", " .. Where(w:GetPos()) .. ".",
                down and "Civil Protection unit down" or "called away")
        end
        if e.phase ~= "coming" then
            WatchDoors(e, now)
            if e.over or e.unit ~= u then CheckStrikes(e) return end
        end
        DriveNPC(e, u, st, now)
        if not e.over and e.unit == u and e.phase ~= "coming" then Forcefields(e, now) end
        return
    end
    -- nobody with them
    if CheckStrikes(e) then return end
    if now >= (e.nextDispatch or 0) then
        e.nextDispatch = now + 5
        if Dispatch(e) then return end
    end
    if e.phase == "unattended" and now > (e.graceUntil or 0) then
        Radio("Dispatch: no Civil Protection unit free to take over the escort of " .. NameOf(w) .. ".")
        return End(e, "nobody came", "[Union] No Civil Protection unit came. You're on your own: leave the restricted area.")
    end
    if e.phase == "waiting" and now - (e.since or now) > WAIT_SECS then
        return End(e, "lapsed", "[Union] No Civil Protection unit was free. Your escort request lapses; ask again later.")
    end
end

-- Units who broke off to put a prisoner back.
local function Recaptures(now)
    for i = #LC.Recaptures, 1, -1 do
        local r = LC.Recaptures[i]
        local st = IsValid(r.cop) and LC.NPCs and LC.NPCs[r.cop]
        local pr = IsValid(r.prisoner) and LC.Prisoners and LC.Prisoners[r.prisoner]
        if not st or not pr or now > r.untilT or st.state == "hostile" or st.workEscort then
            table.remove(LC.Recaptures, i)
        elseif r.cop:GetPos():DistToSqr(r.prisoner:GetPos()) < 110 * 110 then
            table.remove(LC.Recaptures, i)
            Voice(r.cop, "movealong3")
            if LC.ReturnToCell then LC.ReturnToCell(r.prisoner, "The Civil Protection unit marches you back to your cell.") end
            LC.SetState(r.cop, st, "idle")
            st.untilT = now + 3
        elseif now > r.nextGo then
            r.nextGo = now + 2
            if LC.GoTo then LC.GoTo(r.cop, st, r.prisoner:GetPos(), true, nil) end
        end
    end
end

function LC.EscortTick()
    local now = CurTime()
    for w, e in pairs(LC.Escorts) do
        if e.over then LC.Escorts[w] = nil else TickOne(e, now) end
    end
    if #LC.Recaptures > 0 then Recaptures(now) end
end

timer.Create("LivingCityEscorts", 0.5, 0, function()
    local ok, err = LC.Try(LC.EscortTick)
    if not ok and LC.Error then LC.Error("escort", err) end
end)

hook.Add("PlayerDisconnected", "LivingCityEscort", function(ply)
    local e = LC.Escorts[ply]
    if e then End(e, "gone") end
    for _, o in pairs(LC.Escorts) do
        if o.unit == ply then Unattended(o, "Dispatch: escort Civil Protection unit off the net.", "Civil Protection unit gone") end
    end
end)

------------------------------------------------------------------------
-- Asking (the actions menu, or !escort)
------------------------------------------------------------------------

-- The players a unit could take on: everyone waiting, or left unattended.
function LC.EscortRequests()
    local out = {}
    for w, e in pairs(LC.Escorts) do
        if IsValid(w) and not e.over and (e.phase == "waiting" or e.phase == "unattended" or (IsValid(e.unit) and not e.unit:IsPlayer())) then
            out[#out + 1] = w
        end
    end
    return out
end

local function FindPlayer(name)
    name = string.lower(string.Trim(name or ""))
    if name == "" then return nil end
    for _, p in ipairs(player.GetAll()) do
        if string.find(string.lower(p:Nick()), name, 1, true) or string.find(string.lower(NameOf(p)), name, 1, true) then return p end
    end
    return nil
end

-- !escort: a worker asks (or sends it away); a unit takes one ("!escort name"), or hands it back ("!escort drop").
function LC.EscortCommand(ply, rest, target)
    rest = string.lower(string.Trim(rest or ""))
    local ok, why
    if LC.PlayerIsCP(ply) then
        if rest == "drop" or rest == "off" then
            ok, why = LC.DropEscort(ply)
        else
            local who = (IsValid(target) and target:IsPlayer() and target) or FindPlayer(rest)
            if not who then
                local reqs = LC.EscortRequests()
                who = #reqs == 1 and reqs[1] or nil
            end
            if not who then why = "Who? (!escort name, or Civil Protection > Escort requests in the actions menu.)"
            else ok, why = LC.TakeEscort(ply, who) end
        end
    elseif LC.Escorts[ply] then
        ok, why = LC.DismissEscort(ply)
    else
        ok, why = LC.RequestEscort(ply)
    end
    if why then ply:ChatPrint(why) end
    return ok
end

LC.SlashCommands = LC.SlashCommands or {}
LC.SlashCommands.escort = function(ply, rest) LC.EscortCommand(ply, rest) end

hook.Add("PlayerSay", "LivingCityEscort", function(ply, text)
    local raw = string.Trim(text or "")
    local lead = string.sub(raw, 1, 1)
    if lead ~= "!" and lead ~= "/" then return end
    if lead == "/" and LC.ICChatActive and LC.ICChatActive() then return end
    local cmd, rest = string.match(raw, "^[!/](%S+)%s*(.*)$")
    if not cmd or string.lower(cmd) ~= "escort" then return end
    LC.EscortCommand(ply, rest)
    return ""
end)
