--[[
    Living City: squad sizes and backup by radio (sv_livingcity_squads.lua)

    The owner, 9 November: "can we have scaling squad sizes for resistance and
    metrocops/overwatch/combine? So if there's only 1-2 human players in a
    faction, then they can recruit 5 NPCs to follow them in a squad. If there's
    3-4 human players in a faction, then it drops to 3 ish ... eventually you can
    only ask 1 NPC to follow because we should expect players to talk with other
    players and form human squads, but this limitation needs to be somehow
    inferred/shown to the player when those limits are reached and in effect."

    How many NPCs one player may lead (LC.SquadLimit), from the human players on
    their side (the Resistance; or the Combine: Civil Protection and Overwatch):
      1-2 players: 5;  3-4: 3;  5-6: 2;  7 and more: 1   (LC.SquadSteps)
    A Resistance Commander and an Overwatch Elite Soldier (or the Overwatch
    Commander) always lead at least LC.SquadLeaderMin (4). Nobody is sent away
    when the limit drops: they just can't take on more until they're under it,
    and they're told.

    Resistance squads are the fighters following them (sv_livingcity_rebels.lua);
    the Combine's are the units in their squad (st.backupFor: sv_livingcity_war.lua),
    by "Call for backup" or by pressing E on a unit (LC.UnitRecruit: metrocops for
    any Metrocop and up, soldiers for Overwatch, Elites only for the Overwatch
    Commander). The player's NW2 ints lc_squad_n / lc_squad_max / lc_squad_players
    feed F2 ("Call for backup (squad 2 of 3)").

    Backup by radio: the radio transmitter's left click calls for backup on the
    band it's on (Freq 7: LC.RebelCallBackup; the CP net: LC.CallBackup). A
    Resistance call needs a Freq 7 radio, from F2 too. Fighters too far away come
    out of rebel territory: one nobody can see is moved to a spot out of sight
    between the territory and the caller, with a way through to them
    (LC.RebelBackupSpot), and runs in to join the squad.
]]

LC = LC or {}

LC.SquadSteps = { { 2, 5 }, { 4, 3 }, { 6, 2 } } -- (up to this many players on the side: this many each; more: 1)
LC.SquadLeaderMin = 4

local function Faction(p) return p:GetNW2String("lcf_faction", "") end
local function Rank(p) return p:GetNW2Int("lcf_rank", 1) end

-- "rebels", "combine" or nil.
function LC.SquadSide(p)
    if not IsValid(p) or not p:IsPlayer() then return nil end
    local f = Faction(p)
    if f == "resistance" then return "rebels" end
    if f == "cp" or f == "ota" then return "combine" end
    return nil
end

function LC.SquadSidePlayers(side)
    local n = 0
    for _, p in ipairs(player.GetAll()) do if LC.SquadSide(p) == side then n = n + 1 end end
    return n
end

-- The side's leaders: the Resistance's Commander, Overwatch's Elite Soldiers and its Commander.
function LC.SquadLeader(p)
    local side = LC.SquadSide(p)
    if side == "rebels" then return Rank(p) >= 5 end
    if side == "combine" then return Rank(p) >= 6 or p:GetNW2String("lcf_special", "") == "ow_commander" end
    return false
end

function LC.SquadLimitFor(players)
    for _, s in ipairs(LC.SquadSteps) do if players <= s[1] then return s[2] end end
    return 1
end

-- How many NPCs p may lead now, how many players are on their side, and whether a leader's minimum lifted it.
function LC.SquadLimit(p)
    local side = LC.SquadSide(p)
    if not side then return 0, 0, false end
    local players = math.max(1, LC.SquadSidePlayers(side))
    local n = LC.SquadLimitFor(players)
    if LC.SquadLeader(p) and n < LC.SquadLeaderMin then return LC.SquadLeaderMin, players, true end
    return n, players, false
end

function LC.SquadMembers(p)
    local side = LC.SquadSide(p)
    if side == "rebels" then return LC.FollowersOf and LC.FollowersOf(p) or {} end
    if side == "combine" then return LC.BackupSquad and LC.BackupSquad(p) or {} end
    return {}
end

function LC.SquadRoom(p)
    return math.max(0, (LC.SquadLimit(p)) - #LC.SquadMembers(p))
end

-- Why the squad's full, in a line: the limit, and why it's that.
function LC.SquadFullText(p)
    local limit, players, lifted = LC.SquadLimit(p)
    local side = LC.SquadSide(p) == "rebels" and "the Resistance" or "the Combine"
    local why
    if lifted then
        why = string.format("as %s you always lead at least %d", LC.SquadSide(p) == "rebels" and "a Commander" or "an Elite", LC.SquadLeaderMin)
    elseif players <= 2 then
        why = string.format("%d player%s in %s", players, players == 1 and "" or "s", side)
    else
        why = string.format("%d players in %s: the more of you, the smaller each squad, so team up with them", players, side)
    end
    return string.format("Your squad is full: %d of %d (%s).", #LC.SquadMembers(p), limit, why)
end

local function Tell(p, kind, title, text, secs)
    if LC.Notice then LC.Notice(p, kind, title, text, secs or 9) elseif p.ChatPrint then p:ChatPrint(title .. ": " .. text) end
end

-- Every few seconds: each player's squad numbers for F2, and a word when their limit changes while they lead anyone.
function LC.SquadTick()
    for _, p in ipairs(player.GetAll()) do
        local limit, players = LC.SquadLimit(p)
        local n = #LC.SquadMembers(p)
        local was = p:GetNW2Int("lc_squad_max", -1)
        p:SetNW2Int("lc_squad_n", n)
        p:SetNW2Int("lc_squad_max", limit)
        p:SetNW2Int("lc_squad_players", players)
        if was > 0 and limit ~= was and n > 0 then
            if limit < n then
                Tell(p, "warn", "Squad limit", string.format("More players joined your side (%d now): squads are %d each. Yours keep with you, but nobody new can join until you're under %d.", players, limit, limit))
            elseif limit > was then
                Tell(p, "info", "Squad limit", string.format("Fewer players on your side (%d now): you can lead %d.", players, limit))
            end
        end
        -- a Combine squad member whose leader isn't the Combine's any more goes back to work
        if LC.SquadSide(p) ~= "combine" and LC.BackupSquad then
            for _, npc in ipairs(LC.BackupSquad(p)) do
                local st = LC.NPCs[npc]
                if st then st.backupFor, st.backupUntil, st.backupRecruited = nil, nil, nil end
            end
        end
    end
end
timer.Create("LivingCitySquads", 3, 0, function() LC.Try(LC.SquadTick) end)

------------------------------------------------------------------------
-- A Combine unit pressing E on one of the city's units: "Follow me"
------------------------------------------------------------------------

LC.UnitRecruitSecs = 3600 -- (with you until you send them back, or for an hour)

-- Why p can't lead this unit (nil: they can).
function LC.UnitRecruitWhyNot(p, npc, st)
    if LC.SquadSide(p) ~= "combine" then return "Only Civil Protection and Overwatch lead units." end
    if Rank(p) < 2 then return "Recruits don't give orders: Metrocops and up can lead units." end
    if st.elite then
        if p:GetNW2String("lcf_special", "") ~= "ow_commander" then return "Elites answer only to the Overwatch Commander." end
    elseif st.role == "soldier" and Rank(p) < 4 then
        return "Overwatch soldiers answer only to Overwatch."
    end
    if st.garrison or st.supplyGuard or st.prisonGuard or st.questLock or st.questSquad or st.raid or st.skirmish or st.workEscort
        or st.state == "hostile" or st.state == "escort" or st.state == "event" or st.desperationTest then
        return "That unit has orders of its own."
    end
    if IsValid(st.backupFor) and st.backupFor ~= p then return "That unit's already in someone's squad." end
    return nil
end

-- E on a unit: into p's squad, or (already in it) back to work. True when it was handled.
function LC.UnitRecruit(p, npc, st)
    if not IsValid(npc) or not st or not LC.IsSecurity(st) or LC.SquadSide(p) ~= "combine" then return false end
    local soldier = st.role == "soldier"
    if st.backupFor == p then
        st.backupFor, st.backupUntil, st.backupRecruited, st.backupJoined = nil, nil, nil, nil
        npc:EmitSound(soldier and "npc/combine_soldier/vo/affirmative.wav" or "npc/metropolice/vo/affirmative.wav", 75)
        p:ChatPrint("[CP net] " .. (LC.NPCStr and LC.NPCStr(npc, "lc_pname", "The unit") or "The unit") .. " goes back to their duties.")
        return true
    end
    local why = LC.UnitRecruitWhyNot(p, npc, st)
    if not why and LC.SquadRoom(p) <= 0 then why = LC.SquadFullText(p) end
    if why then
        Tell(p, "warn", "Squad", why, 8)
        return true
    end
    local now = CurTime()
    if LC.AbandonTask then LC.AbandonTask(npc, st, now) end
    if LC.ArmBackupUnit then LC.ArmBackupUnit(npc, st, false, 1) end
    st.backupFor, st.backupUntil, st.backupJoined, st.backupRecruited = p, now + LC.UnitRecruitSecs, true, true
    if npc.SetSquad then npc:SetSquad("lcbk" .. p:EntIndex()) end
    npc:EmitSound(soldier and "npc/combine_soldier/vo/copythat.wav" or "npc/metropolice/vo/copy.wav", 75)
    local limit = LC.SquadLimit(p)
    p:ChatPrint(string.format("[CP net] %s is with you (%d of %d in your squad): they keep with you and fight what you fight. E on them again sends them back to their duties.",
        LC.NPCStr and LC.NPCStr(npc, "lc_pname", "A unit") or "A unit", #LC.SquadMembers(p), limit))
    return true
end

------------------------------------------------------------------------
-- Backup out of rebel territory
------------------------------------------------------------------------

-- A spot out of sight between rebel territory (at from) and the caller, with a way through to them.
function LC.RebelBackupSpot(ply, from)
    local to = ply:GetPos()
    local best, bestScore
    for _ = 1, 40 do
        local p = LC.RandomWanderPos and (LC.RandomWanderPos("citizen", to) or LC.RandomWanderPos("soldier", to))
        if not p then break end
        local d = p:Distance(to)
        if d > 700 and d < 2600 and not (LC.IsSeen and LC.IsSeen(p + Vector(0, 0, 50)))
            and (not LC.NavReachable or LC.NavReachable(p, to)) and (not LC.ClearSpot or LC.ClearSpot(p)) then
            local score = from and p:Distance(from) or d -- (on the territory's side of them)
            if not bestScore or score < bestScore then best, bestScore = p, score end
        end
    end
    return best
end

-- Idle fighters in rebel territory, far from the caller and seen by nobody, nearest the caller first.
function LC.RebelTerritoryBackup(ply, n)
    if n <= 0 then return {} end
    local out = {}
    for npc, st in pairs(LC.NPCs or {}) do
        if IsValid(npc) and st.role == "rebel" and npc:Health() > 0 and not st.follow and not st.raid and not st.skirmish
            and not st.quartermaster and not st.post and not st.errand and not st.foe and not st.questLock and not st.test
            and LC.InRebelZone and LC.InRebelZone(npc:GetPos()) and not (LC.IsSeen and LC.IsSeen(npc:GetPos() + Vector(0, 0, 50))) then
            out[#out + 1] = { npc = npc, st = st, d = npc:GetPos():DistToSqr(ply:GetPos()) }
        end
    end
    table.sort(out, function(a, b) return a.d < b.d end)
    local sent = {}
    for _, c in ipairs(out) do
        if #sent >= n then break end
        local spot = LC.RebelBackupSpot(ply, c.npc:GetPos())
        if not spot then break end
        c.npc:SetPos(spot + Vector(0, 0, 4))
        if c.npc.SetSchedule and SCHED_IDLE_STAND then c.npc:SetSchedule(SCHED_IDLE_STAND) end
        sent[#sent + 1] = c
    end
    return sent
end

------------------------------------------------------------------------
-- Squad mates who fall behind catch up (the owner, 12 November, "this is like the 4th time I've reported
-- this": "they get stuck and get lost, I had one get lost for 10 minutes then suddenly run up. They need to
-- TELEPORT to me if they get too far away"). Every 2 seconds, each unit in a player's squad (backup or
-- recruited: st.backupFor) further than LC.SquadCatchFar from them, or more than LC.SquadCatchNear away
-- without getting any closer for LC.SquadCatchStuck seconds, is put just behind them: on the floor they
-- stand on, in the same room (a clear line from them), with room to stand (no wall or prop), where the nav
-- graph can get to them. Out of everyone's sight if any such spot is, else out of the leader's own view,
-- else anywhere that fits. Never into the dream zone unless the leader is in it. Whatever the unit was
-- doing; not while it walks a prisoner in, and the "no closer" rule waits while it fights.
------------------------------------------------------------------------

LC.SquadCatchFar, LC.SquadCatchNear, LC.SquadCatchStuck, LC.SquadCatchEvery = 900, 300, 10, 2
local CATCH_EYE = Vector(0, 0, 50)

local function InDreamZone(pos)
    local dz = LC.DreamZone and LC.DreamZone()
    return dz ~= nil and LCZ ~= nil and LCZ.Contains ~= nil and LCZ.Contains(dz, pos) == true
end
LC.SquadInDreamZone = InDreamZone

local function InLeaderView(leader, pos)
    local d = pos + CATCH_EYE - leader:EyePos()
    if d:LengthSqr() < 1 then return true end
    d:Normalize()
    return d:Dot(leader:GetAimVector()) > 0.3
end

-- Where a squad mate is put to catch up with its leader (nil: nowhere fits).
function LC.SquadCatchSpot(leader, npc)
    if not IsValid(leader) then return nil end
    local lpos = leader:GetPos()
    if leader.IsOnGround and not leader:IsOnGround() and LC.GroundAt then lpos = LC.GroundAt(lpos) end -- (mid-jump: the floor under them)
    local back = leader:GetAimVector() * -1
    back.z = 0
    if back:LengthSqr() < 0.01 then back = leader:GetForward() * -1 back.z = 0 end
    if back:LengthSqr() < 0.01 then back = Vector(-1, 0, 0) end
    back:Normalize()
    local right = Vector(-back.y, back.x, 0)
    local cands = {}
    for _, dist in ipairs({ 90, 140, 200, 280 }) do
        for _, side in ipairs({ 0, 50, -50, 100, -100 }) do cands[#cands + 1] = lpos + back * dist + right * side end
    end
    for i = 0, 7 do -- (then all round them: a corridor behind them that ends in a wall)
        local a = math.rad(i * 45)
        local dir = Vector(math.cos(a), math.sin(a), 0)
        for _, dist in ipairs({ 80, 140 }) do cands[#cands + 1] = lpos + dir * dist end
    end
    local dreamOK = InDreamZone(lpos)
    local chest = lpos + Vector(0, 0, 40)
    local fits = {}
    for _, p in ipairs(cands) do
        local g = LC.GroundAt and LC.GroundAt(p + Vector(0, 0, 30)) or p
        if math.abs(g.z - lpos.z) < 40 and (not LC.ClearSpot or LC.ClearSpot(g)) and (dreamOK or not InDreamZone(g)) then
            local tr = util.TraceLine({ start = chest, endpos = g + Vector(0, 0, 40), mask = MASK_NPCSOLID_BRUSHONLY, filter = { leader, npc } })
            if (tr.Fraction or 1) > 0.97 and not tr.StartSolid and (not LC.NavReachable or LC.NavReachable(g, lpos)) then
                fits[#fits + 1] = g
            end
        end
    end
    for _, g in ipairs(fits) do if not (LC.IsSeen and LC.IsSeen(g + CATCH_EYE)) then return g end end
    for _, g in ipairs(fits) do if not InLeaderView(leader, g) then return g end end
    return fits[1]
end

-- One squad mate: caught up now? (true when it was moved)
function LC.SquadCatchUpOne(npc, st, leader, now)
    if not (IsValid(npc) and st and IsValid(leader)) then return false end
    if st.state == "jailed" or st.state == "escort" or st.marching then return false end
    if (st.catchNext or 0) > now then return false end
    if leader.InVehicle and leader:InVehicle() then return false end
    if leader.GetMoveType and MOVETYPE_NOCLIP and leader:GetMoveType() == MOVETYPE_NOCLIP then return false end
    local pos = npc:GetPos()
    local d = pos:Distance(leader:GetPos())
    if d <= LC.SquadCatchNear then
        st.catchBest, st.catchSince, st.catchFrom = nil, nil, nil
        return false
    end
    -- getting any closer? (a step better than its best so far, or it moved at all)
    local fighting = st.state == "hostile" and IsValid(st.enemy)
    if not st.catchBest or d < st.catchBest - 32 or fighting then
        st.catchBest, st.catchSince = d, now
    end
    local stuck = now - (st.catchSince or now) >= LC.SquadCatchStuck
    if d <= LC.SquadCatchFar and not stuck then return false end
    local spot = LC.SquadCatchSpot(leader, npc)
    if not spot then st.catchNext = now + LC.SquadCatchEvery return false end
    npc:SetPos(spot + Vector(0, 0, 4))
    if npc.SetLocalVelocity then npc:SetLocalVelocity(Vector(0, 0, 0)) end
    if npc.StopMoving then npc:StopMoving() end
    if npc.SetSchedule and SCHED_IDLE_STAND then npc:SetSchedule(SCHED_IDLE_STAND) end
    -- (a walk it was on is over: it's there. Idle, so the next think picks up from here; a fight goes on.)
    st.goingTo, st.backupMove = nil, 0
    if st.state == "moving" and LC.SetState then LC.SetState(npc, st, "idle") st.untilT = now end
    st.catchBest, st.catchSince, st.catchNext = nil, nil, now + 4
    if LC.Face then LC.Face(npc, leader:GetPos() + leader:GetForward() * 300) end
    hook.Run("LivingCitySquadCaughtUp", npc, leader, d)
    return true
end

function LC.SquadCatchUpTick(now)
    now = now or CurTime()
    local n = 0
    for npc, st in pairs(LC.NPCs or {}) do
        local leader = st.backupFor
        if IsValid(npc) and npc:Health() > 0 and IsValid(leader) and leader:IsPlayer() and leader:Alive() and LC.SquadSide(leader) == "combine" then
            if LC.SquadCatchUpOne(npc, st, leader, now) then n = n + 1 end
        elseif st.catchBest then
            st.catchBest, st.catchSince = nil, nil
        end
    end
    return n
end
timer.Create("LivingCitySquadCatchUp", LC.SquadCatchEvery, 0, function()
    local ok, err = LC.Try(LC.SquadCatchUpTick, CurTime())
    if not ok and LC.Error then LC.Error("squad catch up", err) end
end)
