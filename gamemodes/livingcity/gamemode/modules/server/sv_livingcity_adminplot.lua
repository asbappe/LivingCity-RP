--[[
    Living City: the plot against the Administrator, a coordinated attack and not a lone wolf

    The owner, 17 November: "if the attempted assassin is a resistance member that was
    ordered by a resistance leader, or given a job by the resistance leader, to
    assassinate her, I would love for a few resistance/rebel fighters to appear all over
    the place, maybe like 7 or 8, so it looks like a coordinated rebel attack and not a
    lone wolf. However if it is just a lone wolf, then none of that happens."

    The job     "Kill the Administrator" is on the Resistance's board (Operations), and
                nobody else's, from the moment the city is called to her address until
                someone tries. Its one step is making the attempt at her address. Taken
                by one, joined by others as any job is: Fighters and up, and nobody below
                that rank sees it on the board (the owner, 17 November: "fighters and up
                only"). It pays when the attempt is made (the owner: "xp should be 250 for
                trying, 250 more if successful, plus a 100 credit stipend, but ONLY if it
                is a job from the resistance job board": 250 experience, 100 credits in
                all, 250 more experience if she dies of it, then or after the roll in her
                office) and ends there. Nobody is told it has gone up, and the planned
                order never leaks to Civil Protection (the owner: "it should just go on
                the board. Keep as minimal a chance of CP/overwatch/administrator finding
                out about it"). It also ends when her address is over, and as any job does:
                dropped, arrested, a new character, gone from the server.
    The order   A Resistance leader's planning board (F2 > Resistance > Operations: plan
                or join, sv_livingcity_opplan.lua) lists "Kill the Administrator at her
                address" while her address is on. No raid goes for that one: whoever
                joined is under orders from the moment they join. At its hour those who
                joined are pointed to the stand, as for any operation, and the order
                stands until her address is over. When one of them makes the attempt,
                those who joined and are there are paid as for any planned operation.
    Ordered     An attempt on her life at her address (LC.AdminAttempt,
                sv_livingcity_adminsecurity.lua) by someone who holds the job or the
                order. Anyone else's (a lone wolf, a rogue unit, a citizen) brings
                nobody: that is as it was.
    The attack  Seven or eight Resistance fighters (fewer when the Resistance's reserve
                is short, none when it is empty: sv_livingcity_manpower.lua) come out
                round the stand at once, each from one of the city's own walking spots or
                doorways that no player can see at that moment, one from each direction
                first and never two close together (where there are too few such spots, two
                or three from one, a step apart). They are the city's own fighters
                (LC.SpawnRebel: the same people, guns and health) and fire on her guards,
                the units there and the Combine's players; never on citizens or the
                Resistance, whom their fire cannot hurt. Her guards may hurt them
                (LC.AdminTargets). They are on top of the city's own numbers, as her
                guards are.
    Leaving     When she is gone (and they have fought at least forty seconds), or after
                ninety seconds, the living break off, run back the way they came and are
                taken out of the city once nobody can see them: back in the reserve. The
                dead are lost to it, as in any skirmish.
    Told        nobody, in words. The fighters arriving are the news.

    Hooks heard: LivingCityAdminExfil (her guards are getting her out: who set it off),
    LivingCityAdminAttempt (a grenade by her), her own hurt and death at her address, and
    LivingCitySpeechCalled and LivingCitySpeechEnded (the job goes on the board, and comes
    off it). Nothing is answered to any of them. No settings: the numbers are the constants
    below.
]]

if CLIENT then return end

LC = LC or {}

local JOB = "res_regicide"
local KIND = "regicide"        -- the planned operation's kind (sv_livingcity_opplan.lua)
local TITLE = "Kill the Administrator"
local LINE = "At her address. Our fighters open fire when you do."
local LABEL = "Kill the Administrator at her address"
local REWARD = 250             -- experience, when the attempt is made (the owner, 17 November)
local KILL_BONUS = 250         -- more, if she dies of it
local STIPEND = 100            -- credits with the job, in all (the board's usual pay for a job is part of it)
local MIN_RANK = 3             -- Fighters and up (Sympathizer, Member, Fighter, Lieutenant, Commander)
local FIGHTERS = { 7, 8 }      -- how many come (fewer when the reserve is short)
local RING_MIN, RING_MAX = 400, 1500 -- how far from the stand they come out
local LEVEL = 300              -- and how far above or below it
local APART = 260              -- never two of them closer together than this
local BESIDE = 90              -- (few such spots there: a second and a third man this far from one already chosen)
local SECTORS = 8              -- one from each of these directions first
local CHECKS = 300             -- spots looked at, at most
local NEAR_PLAYER = 250        -- never this near a player, seen or not
local FIGHT_MIN, FIGHT_MAX = 40, 90 -- seconds they fight: at least, and at most
local LEAVE_MAX = 180          -- a fighter still watched this long after breaking off goes anyway
local REACH = 2500             -- the Combine this near the stand are theirs to fight
local HOLD = 3600              -- (the city leaves a fighter of the attack alone this long at most: the "event" state)
local UP = Vector(0, 0, 50)
local TAKEN = { detained = true, escorted = true, jailed = true }

local P       -- the attack under way, or nil
local order   -- the leader's order, standing since its hour came (the plan), or nil
local TEMPLATE

function LC.AdminPlot() return P end

local function Faction(p) return p:GetNW2String("lcf_faction", "") end
local function RankIndex(p) return p:GetNW2Int("lcf_rank", 1) end
local function Administrator(p) return LC.IsAdministrator ~= nil and LC.IsAdministrator(p) == true end
local function Exit() return LC.AdminExfil and LC.AdminExfil() or nil end
local function Living(e)
    if not IsValid(e) then return false end
    if e:IsPlayer() then return e:Alive() end
    return e:Health() > 0
end

-- Her, while her address is on (from the call until it ends): a player Administrator, or the city's own at the
-- stand. And the address.
local function AtAddress()
    local S = LC.SpeechSession and LC.SpeechSession()
    if not S then return nil end
    local her = (IsValid(S.by) and S.by) or (IsValid(S.her) and S.her) or nil
    if not her or (her:IsPlayer() and not her:Alive()) then return nil end
    return her, S
end

-- Her address is on, and nobody has tried yet: the job is on the board, the target on the planning board.
function LC.AdminPlotOpen()
    local her, S = AtAddress()
    return her ~= nil and not S.plotted and Exit() == nil
end

------------------------------------------------------------------------
-- Who is under orders
------------------------------------------------------------------------

local function JobOf(ply)
    local q = LC.QuestOf and LC.QuestOf[ply]
    if q and not q.done and q.tmpl == TEMPLATE then return q end
    return nil
end
local function OrderOf(ply)
    if Faction(ply) ~= "resistance" then return nil end
    local plan = LC.OpPlan
    if plan and plan.kind == KIND and plan.joined[ply] then return plan end
    if order and order.joined[ply] then return order end
    return nil
end
-- "job", "order" or nil: what makes an attempt of theirs an ordered one.
function LC.AdminPlotHolds(ply)
    if not (IsValid(ply) and ply:IsPlayer()) then return nil end
    if JobOf(ply) then return "job" end
    if OrderOf(ply) then return "order" end
    return nil
end

-- The leader's order is done with: made (those who joined and are there are paid), or over.
local function EndOrder(plan, made)
    if LC.OpPlan == plan then LC.OpPlan = nil end
    if order == plan then order = nil end
    if made and LC.OpPay then LC.Try(LC.OpPay, plan) end
    if LC.OpSyncMenu then
        for _, p in ipairs(player.GetAll()) do LC.Try(LC.OpSyncMenu, p) end
    end
end

-- The planning board's target, while her address is on (LC.OpTargets).
function LC.AdminPlotTarget()
    if not LC.AdminPlotOpen() then return nil end
    local _, S = AtAddress()
    return { label = LABEL, kind = KIND, pos = S.stand.pos, data = {} }
end
-- Its hour has come (sv_livingcity_opplan.lua, Fire): with her address still on, the order stands until it is
-- over, and those who joined are pointed to the stand. False: there is nothing left to go to.
function LC.AdminPlotGo(plan)
    if not LC.AdminPlotOpen() then return false end
    order = plan
    return true
end

-- No longer theirs: a new character, or in a cell (backing out is the planning board's own: LC.JoinOp).
local function Released(ply)
    if not IsValid(ply) then return end
    local plan = LC.OpPlan
    if plan and plan.kind == KIND then plan.joined[ply] = nil end
    if order then order.joined[ply] = nil end
end
hook.Add("LivingCityNewCharacter", "LivingCityAdminPlot", function(ply) Released(ply) end)
hook.Add("LivingCityIncarcerated", "LivingCityAdminPlot", function(ply) Released(ply) end)

------------------------------------------------------------------------
-- The job, on the Resistance's board
------------------------------------------------------------------------

TEMPLATE = {
    id = JOB, factions = { resistance = true }, first = true, recheck = true,
    available = function(ply) return LC.AdminPlotOpen() and (not IsValid(ply) or RankIndex(ply) >= MIN_RANK) end,
    sees = function(ply) return IsValid(ply) and RankIndex(ply) >= MIN_RANK end, -- (not on the board of anyone below a Fighter)
    -- (her address over, and nobody getting her out: there is nothing left to try. No reason in words: it shows.)
    over = function()
        if not AtAddress() and not Exit() then return false end
    end,
    build = function()
        local her, S = AtAddress()
        if not her then return nil end
        return {
            title = TITLE, reward = REWARD, limit = 600, failOnArrest = true, desc = LINE,
            -- (one step, and not a place to stand: the attempt itself. The marker is the stand.)
            stages = { { kind = "count", event = "admin_attempt", need = 1, untallied = true, text = LINE, pos = S.stand.pos } },
        }
    end,
}
if LC.QuestTemplates then
    for i = #LC.QuestTemplates, 1, -1 do if LC.QuestTemplates[i].id == JOB then table.remove(LC.QuestTemplates, i) end end
    LC.QuestTemplates[#LC.QuestTemplates + 1] = TEMPLATE
end
-- On the board from the moment the city is called, whatever else is on it. Nobody is told in words: the call
-- to her address is heard by everyone.
hook.Add("LivingCitySpeechCalled", "LivingCityAdminPlot", function()
    if LC.PostDirective then LC.Try(LC.PostDirective, JOB, nil, true) end
end)
-- Her address is over (or her guards have begun): a job nobody took comes off the board.
hook.Add("LivingCitySpeechEnded", "LivingCityAdminPlot", function()
    for _, p in ipairs(LC.Postings and LC.Postings.resistance or {}) do
        if p.tmpl == TEMPLATE and not p.q then p.dead = true end
    end
end)

------------------------------------------------------------------------
-- Where they come out
------------------------------------------------------------------------

local function Shuffle(t)
    for i = #t, 2, -1 do
        local j = math.random(i)
        t[i], t[j] = t[j], t[i]
    end
    return t
end

-- Nobody can see it at this moment, nobody is standing by it, and a person fits there and can walk to the stand.
local function Hidden(p, centre)
    if LC.FarFromPlayers and not LC.FarFromPlayers(p, NEAR_PLAYER) then return false end
    if LC.IsSeen and (LC.IsSeen(p + UP) or LC.IsSeen(p + Vector(0, 0, 12))) then return false end
    if LC.InNoGo and LC.InNoGo(p, "rebel") then return false end
    if LC.DestIsBad and LC.DestIsBad(p) then return false end
    if LC.ClearSpot and not LC.ClearSpot(p) then return false end
    if LC.NavReachable and not LC.NavReachable(p, centre) then return false end
    return true
end

-- Up to `want` spots round `centre`: the city's doorways (where its people come out) and its own walking
-- spots, between RING_MIN and RING_MAX of it and about on its level. One from each of eight directions first,
-- then round again, and never two within APART of each other: all round, not in one clump. Where the place has
-- too few of those (one doorway, a path with few points), a second and then a third man comes out beside one
-- already chosen, a step away and as unseen as he is: never more than three at one spot. Fewer than asked when
-- there is no more room nobody can see.
function LC.AdminPlotSpots(centre, want)
    local bySector, taken, n = {}, {}, 0
    local function add(p)
        if not p then return end
        local dx, dy = p.x - centre.x, p.y - centre.y
        local d2 = dx * dx + dy * dy
        if d2 < RING_MIN * RING_MIN or d2 > RING_MAX * RING_MAX or math.abs(p.z - centre.z) > LEVEL then return end
        local key = math.floor(p.x / 48) .. ":" .. math.floor(p.y / 48) .. ":" .. math.floor(p.z / 48)
        if taken[key] then return end
        taken[key] = true
        local s = math.floor((math.atan2(dy, dx) + math.pi) / (2 * math.pi) * SECTORS) % SECTORS
        bySector[s] = bySector[s] or {}
        bySector[s][#bySector[s] + 1] = p
        n = n + 1
    end
    for _, pt in ipairs(LC.PointsOfKind and LC.PointsOfKind("spawn") or {}) do add(pt.pos) end
    for _, p in ipairs(LC.NodePositions and LC.NodePositions("rebel") or {}) do add(p) end
    for _, p in ipairs(LC.Fallback or {}) do add(p) end
    local sectors = {}
    for s, list in pairs(bySector) do
        Shuffle(list)
        sectors[#sectors + 1] = s
    end
    table.sort(sectors)
    Shuffle(sectors)
    local out, checks, more = {}, 0, n > 0
    while #out < want and more and checks < CHECKS do
        more = false
        for _, s in ipairs(sectors) do
            if #out >= want or checks >= CHECKS then break end
            local list = bySector[s]
            while #list > 0 and checks < CHECKS do
                local p = table.remove(list)
                local apart = true
                for _, o in ipairs(out) do if o:DistToSqr(p) < APART * APART then apart = false break end end
                if apart then
                    checks = checks + 1
                    if Hidden(p, centre) then
                        out[#out + 1] = p
                        more = true
                        break
                    end
                end
            end
        end
    end
    -- still short: beside the ones chosen, once round and then once more
    local first = #out
    for ring = 1, 2 do
        for i = 1, first do
            if #out >= want or checks >= CHECKS then break end
            local a = math.random() * math.pi * 2
            for k = 0, 3 do
                local q = out[i] + Vector(math.cos(a + k * math.pi / 2), math.sin(a + k * math.pi / 2), 0) * (BESIDE * ring)
                local free = true
                for _, o in ipairs(out) do if o:DistToSqr(q) < (BESIDE * 0.9) ^ 2 then free = false break end end
                if free and checks < CHECKS then
                    checks = checks + 1
                    if Hidden(q, centre) then
                        out[#out + 1] = q
                        break
                    end
                end
            end
        end
    end
    return out
end

------------------------------------------------------------------------
-- The fighters
------------------------------------------------------------------------

-- Whom a fighter of the attack never hurts: citizens, the Resistance, anyone who is not the Combine's.
local function Spared(ent)
    if ent:IsPlayer() then
        return not ((LC.PlayerIsCP and LC.PlayerIsCP(ent)) or Administrator(ent) or (LC.PlayerIsZombie and LC.PlayerIsZombie(ent)))
    end
    local st = LC.NPCs and LC.NPCs[ent]
    return st ~= nil and (st.role == "citizen" or st.role == "rebel")
end
LC.AdminPlotSpares = Spared

-- The Combine within reach of the stand: her guards, the city's units, the Combine's players. Never her.
local function Foes(at, her)
    local out = {}
    for npc, st in pairs(LC.NPCs or {}) do
        if IsValid(npc) and npc ~= her and npc:Health() > 0 and not st.test and LC.IsSecurity(st)
            and npc:GetPos():DistToSqr(at) < REACH * REACH then
            out[#out + 1] = npc
        end
    end
    for _, ply in ipairs(player.GetAll()) do
        if ply ~= her and ply:Alive() and not Administrator(ply) and LC.RebelLooksCombine and LC.RebelLooksCombine(ply)
            and ply:GetPos():DistToSqr(at) < REACH * REACH then
            out[#out + 1] = ply
        end
    end
    return out
end

local function Sees(npc, e)
    if LC.RebelCanSee then return LC.RebelCanSee(npc, e, REACH) end
    return npc:GetPos():DistToSqr(e:GetPos()) < REACH * REACH
end

-- The nearest of them (sighted: the nearest he can see).
local function Nearest(npc, foes, sighted)
    local pos, best, bd = npc:GetPos(), nil, nil
    for _, e in ipairs(foes) do
        if Living(e) then
            local d = e:GetPos():DistToSqr(pos)
            if (not bd or d < bd) and (not sighted or Sees(npc, e)) then best, bd = e, d end
        end
    end
    return best
end

-- Whom he is fighting. A fighter of the attack is never without a foe as the rest of the city's code sees it:
-- one of the city's own fighters with none, hit by a unit, turns on it and has it sent after him
-- (sv_livingcity_rebels.lua), and her guards are hers to move. With nobody to fight his foe is himself:
-- nobody's enemy.
local function FoeOf(npc, st)
    local e = st.foe
    if e == npc then return nil end
    return e
end

-- Back to neutral with whoever he was fighting.
local function Drop(npc, st)
    local e = FoeOf(npc, st)
    st.foe = npc
    if IsValid(e) then
        if e:IsPlayer() then
            if LC.SetRel and LC.RebelDisposition then
                LC.SetRel(npc, st, e, LC.RebelDisposition(npc, st, e, LC.PlayerIsZombie and LC.PlayerIsZombie(e)))
            end
        else
            npc:AddEntityRelationship(e, D_NU, 99)
        end
    end
    npc:SetEnemy(NULL)
    if npc.ClearEnemyMemory then npc:ClearEnemyMemory() end
end

-- One of the Combine is his to fight: the fighter hates him, and a unit hates him back, as with any fighter
-- who shoots at one (LC.UnitHatesRebel, sv_livingcity_rebels.lua). Nobody is made to walk anywhere by it:
-- her guards are hers to move.
local function Engage(npc, st, e, now)
    if FoeOf(npc, st) then Drop(npc, st) end
    st.foe, st.foeSince, st.goingTo = e, now, nil
    if e:IsPlayer() then
        if LC.SetRel then LC.SetRel(npc, st, e, D_HT) end
    else
        npc:AddEntityRelationship(e, D_HT, 99)
        local est = LC.NPCs and LC.NPCs[e]
        if est and LC.UnitHatesRebel then LC.UnitHatesRebel(e, est, npc, now) end
    end
end

-- He keeps at him: in sight he shoots; out of sight he runs to where he is.
local function Press(npc, st, e, now)
    if npc:GetEnemy() ~= e then npc:SetEnemy(e) end
    if npc.UpdateEnemyMemory then npc:UpdateEnemyMemory(e, e:GetPos()) end
    if not Sees(npc, e) then
        if now - (st.lastChase or 0) > 3 then
            st.lastChase = now
            npc:SetLastPosition(e:GetPos())
            npc:SetSchedule(SCHED_FORCED_GO_RUN)
        end
    elseif npc:IsCurrentSchedule(SCHED_FORCED_GO) or npc:IsCurrentSchedule(SCHED_FORCED_GO_RUN) then
        npc:SetSchedule(SCHED_CHASE_ENEMY) -- (a walking schedule ignores enemies)
    end
end

local function Run(npc, st, to)
    if LC.RebelHeadFor then return LC.RebelHeadFor(npc, st, to, true) end
    npc:SetLastPosition(to)
    npc:SetSchedule(SCHED_FORCED_GO_RUN)
end

local function Fight(alive, now)
    local foes = Foes(P.at, P.her)
    for _, npc in ipairs(alive) do
        local st = LC.NPCs[npc]
        local e = FoeOf(npc, st)
        if e and not (Living(e) and e:GetPos():DistToSqr(P.at) < REACH * REACH) then
            Drop(npc, st)
            e = nil
        end
        -- (nobody yet, or the one he has is out of sight: someone he can see, now and then)
        if now >= (st.plotLook or 0) and (not e or not Sees(npc, e)) then
            st.plotLook = now + 2
            local seen = Nearest(npc, foes, true)
            if seen and seen ~= e then
                Engage(npc, st, seen, now)
                e = seen
            end
        end
        if e then
            Press(npc, st, e, now)
        else
            -- nobody in sight: toward the nearest of them, or where she stood
            local near = Nearest(npc, foes, false)
            local to = near and near:GetPos() or P.at
            if npc:GetPos():DistToSqr(to) > 300 * 300 then Run(npc, st, to) end
        end
    end
end

local function BreakOff(alive, now)
    P.phase, P.leftAt = "leave", now
    for _, npc in ipairs(alive) do
        local st = LC.NPCs[npc]
        Drop(npc, st)
        st.goingTo, st.plotOut = nil, nil
    end
    if LC.Log then LC.Log("info", string.format("The attack at the Administrator's address breaks off: %d of %d fighters left", #alive, P.came)) end
end

local function Leave(alive, now)
    for _, npc in ipairs(alive) do
        local st = LC.NPCs[npc]
        local pos = npc:GetPos()
        local since = now - P.leftAt
        if since >= 2 and (since > LEAVE_MAX or not (LC.IsSeen and LC.IsSeen(pos + UP))) then
            LC.AdminTargets[npc] = nil
            npc:Remove() -- (alive: back in the Resistance's reserve, sv_livingcity_manpower.lua)
        else
            -- back the way he came; watched there too, on to somewhere nobody is looking
            local to = st.plotOut
            if not to then
                to = st.plotFrom
            elseif pos:DistToSqr(to) < 120 * 120 and now >= (st.plotOutAt or 0) then
                to = (LC.AlarmSquadSpot and LC.AlarmSquadSpot(pos)) or st.plotFrom
            end
            if to ~= st.plotOut then st.plotOut, st.plotOutAt, st.goingTo = to, now + 3, nil end
            if to then Run(npc, st, to) end
        end
    end
end

-- She is no longer at her address, and nobody is getting her out.
local function Gone()
    if Exit() then return false end
    local her = AtAddress()
    return her == nil or her ~= P.her
end

-- The fighters come. How many (0: nobody to send, or nowhere to come from unseen).
function LC.AdminPlotStart(her, who)
    if P or LC.Running == false or not LC.SpawnRebel or not IsValid(her) then return 0 end
    local now = CurTime()
    local want = math.random(FIGHTERS[1], FIGHTERS[2])
    if LC.ManpowerOn and LC.ManpowerOn() and LC.ManpowerPool then
        want = math.min(want, math.floor(LC.ManpowerPool("rebel").reserve))
    end
    if want <= 0 then return 0 end -- (the reserve is spent: the assassin is on their own)
    local centre = her:GetPos()
    local spots = LC.AdminPlotSpots(centre, want)
    local plot = { her = her, by = who, at = centre, t0 = now, fighters = {}, phase = "fight", came = 0 }
    for _, pos in ipairs(spots) do
        local okS, npc, st = LC.Try(LC.SpawnRebel, pos + Vector(0, 0, 4))
        if okS and IsValid(npc) and st then
            -- (on top of the city's own numbers, and nobody else's to move, lead or send home meanwhile)
            st.unmanaged, st.questLock, st.zone, st.leaveAt = true, true, nil, nil
            st.plotFrom = pos
            st.foe = npc -- (nobody yet: FoeOf)
            st.eventUntil = now + HOLD
            LC.SetState(npc, st, "event")
            npc.lcAdminPlot = true
            LC.AdminTargets[npc] = true -- (her guards may hurt him)
            npc:SetAngles(Angle(0, math.deg(math.atan2(centre.y - pos.y, centre.x - pos.x)), 0))
            plot.fighters[#plot.fighters + 1] = npc
        end
    end
    plot.came = #plot.fighters
    if plot.came == 0 then return 0 end
    P = plot
    if LC.Log then
        LC.Log("info", string.format("An ordered attempt on the Administrator by %s: %d Resistance fighters come out round the stand",
            IsValid(who) and who:IsPlayer() and who:Nick() or "?", plot.came))
    end
    return plot.came
end

-- It is over at once: whoever is left is taken out of the city where they stand (the city stopped; tests).
function LC.AdminPlotEnd()
    local plot = P
    P = nil
    if not plot then return end
    for _, npc in ipairs(plot.fighters) do
        if IsValid(npc) then
            LC.AdminTargets[npc] = nil
            npc:Remove()
        end
    end
end

------------------------------------------------------------------------
-- The attempt
------------------------------------------------------------------------

-- Someone tried to kill her at her address. Under orders: the fighters come, and the job and the order are
-- done and paid. Anyone else: nothing. True when it was an ordered one.
function LC.AdminPlotAttempt(her, who, killed)
    if not (IsValid(who) and who:IsPlayer()) or not IsValid(her) then return false end
    local q, plan = JobOf(who), OrderOf(who)
    if not q and not plan then return false end
    -- once for an address, and once for an exit
    local _, S = AtAddress()
    local A = Exit()
    local again = (S and S.plotted) or (A and A.plotted)
    if S then S.plotted = true end
    if A then A.plotted = true end
    if not again then
        local okS, err = LC.Try(LC.AdminPlotStart, her, who)
        if not okS and LC.Error then LC.Error("the attack at the Administrator's address", err) end
    end
    if q then
        if killed then q.bonus = (q.bonus or 0) + KILL_BONUS else LC.AdminPlotPaid[who] = CurTime() end
        LC.Try(LC.QuestEvent, "admin_attempt", who)
    end
    if plan then EndOrder(plan, true) end
    return true
end

-- The stipend: 100 credits in all for the job from the board (never for the order, nor for a lone wolf). The board's
-- usual pay for a finished job (lc_directive_pay, sv_livingcity_economy.lua) is part of it, so this adds the rest.
hook.Add("LivingCityQuestComplete", "LivingCityAdminPlot", function(ply, q)
    if not (IsValid(ply) and q and q.tmpl == TEMPLATE and LC.AddCredits) then return end
    local eco, usual = GetConVar("lc_economy"), GetConVar("lc_directive_pay")
    local had = (not eco or eco:GetBool()) and usual and usual:GetInt() or 0
    if STIPEND - had > 0 then LC.AddCredits(ply, STIPEND - had, "paid quietly") end
end)
function LC.AdminPlotMinRank() return MIN_RANK end

-- She died of it after all, later: hit with no close calls left she is taken out alive, and the roll in her office
-- went against her (the owner, 17 November; sv_livingcity_adminsecurity.lua says so here). Whoever was paid for the
-- job at that address in the last ten minutes gets what they would have had if she had died at the stand. Nothing
-- is said. How many were paid.
LC.AdminPlotPaid = LC.AdminPlotPaid or setmetatable({}, { __mode = "k" }) -- [holder] = when the job paid them
function LC.AdminPlotDied()
    local n, now = 0, CurTime()
    for who, at in pairs(LC.AdminPlotPaid) do
        LC.AdminPlotPaid[who] = nil
        if IsValid(who) and who:IsPlayer() and now - at <= 600 and LC.AddXP then
            LC.AddXP(who, KILL_BONUS, "Kill the Administrator")
            n = n + 1
        end
    end
    return n
end

-- At her address: her address is on and it is her, or her guards are getting her out.
local function Hers(her)
    if not IsValid(her) then return false end
    local A = Exit()
    if A and A.her == her then return true end
    local S = LC.SpeechSession and LC.SpeechSession()
    return S ~= nil and (S.by == her or S.her == her)
end

-- Her guards are getting her out: whoever set it off. (Most attempts come this way: a hit, a near miss.)
hook.Add("LivingCityAdminExfil", "LivingCityAdminPlot", function(her, who)
    LC.Try(LC.AdminPlotAttempt, her, who)
end)
-- A grenade by her (it may be heard before her guards have begun, or with them switched off).
hook.Add("LivingCityAdminAttempt", "LivingCityAdminPlot", function(her, who)
    if Hers(her) then LC.Try(LC.AdminPlotAttempt, her, who) end
end)
-- A hit she took at her address with her guards' exit switched off, or one she died of.
hook.Add("PostEntityTakeDamage", "LivingCityAdminPlot", function(ent, dmg, took)
    if not took or not IsValid(ent) or not Hers(ent) then return end
    local att = dmg:GetAttacker()
    if IsValid(att) and att:IsPlayer() and att ~= ent and LC.AdminPlotHolds(att) then
        LC.Try(LC.AdminPlotAttempt, ent, att, ent:IsPlayer() and not ent:Alive())
    end
end)
hook.Add("PlayerDeath", "LivingCityAdminPlot", function(victim, _, attacker)
    if not IsValid(victim) or not Hers(victim) then return end
    if IsValid(attacker) and attacker:IsPlayer() and attacker ~= victim and LC.AdminPlotHolds(attacker) then
        LC.Try(LC.AdminPlotAttempt, victim, attacker, true)
    end
end)

-- A fighter of the attack never hurts a citizen or one of the Resistance, whatever his bullets find.
hook.Add("EntityTakeDamage", "LivingCityAdminPlot", function(ent, dmg)
    local att = dmg:GetAttacker()
    if IsValid(att) and att.lcAdminPlot and IsValid(ent) and Spared(ent) then return true end
end)

------------------------------------------------------------------------
-- Twice a second
------------------------------------------------------------------------

function LC.AdminPlotThink(now)
    now = now or CurTime()
    -- someone under orders who joined in once her guards had begun (marked by them as an attacker)
    local A = Exit()
    if A and P then A.plotted = true end -- (once for an exit, however it was set off)
    if A and not A.plotted then
        for who in pairs(A.attackers or {}) do
            if IsValid(who) and who:IsPlayer() and LC.AdminPlotHolds(who) then
                LC.AdminPlotAttempt(A.her, who)
                break
            end
        end
    end
    -- the leader's order, past its hour: it stood until her address was over
    if order and not AtAddress() and not A then EndOrder(order, false) end
    if not P then return end
    local alive = {}
    for i = #P.fighters, 1, -1 do
        local npc = P.fighters[i]
        local st = IsValid(npc) and npc:Health() > 0 and LC.NPCs[npc] or nil
        if not st then
            table.remove(P.fighters, i)
        elseif TAKEN[st.state] or st.jailUntil then
            -- cuffed or in a cell: the Combine's prisoner now, as any fighter taken alive
            table.remove(P.fighters, i)
            LC.AdminTargets[npc] = nil
            st.unmanaged, st.questLock, st.eventUntil = nil, nil, nil
            if st.foe == npc then st.foe = nil end
        else
            -- (still the attack's own, whatever else has tried to send him somewhere)
            st.eventUntil = now + HOLD
            if st.state ~= "event" then LC.SetState(npc, st, "event") end
            table.insert(alive, 1, npc)
        end
    end
    if #alive == 0 then
        P = nil
        return
    end
    if P.phase == "fight" then
        local t = now - P.t0
        if t >= FIGHT_MAX or (t >= FIGHT_MIN and Gone()) then BreakOff(alive, now) else Fight(alive, now) end
    end
    if P.phase == "leave" then Leave(alive, now) end
end

timer.Create("LivingCityAdminPlot", 0.5, 0, function()
    if not P and not order and not Exit() then return end
    local okT, err = LC.Try(LC.AdminPlotThink, CurTime())
    if not okT and LC.Error then LC.Error("admin plot", err) end
end)

hook.Add("LivingCityStopped", "LivingCityAdminPlot", function()
    LC.AdminPlotEnd()
    order = nil
end)
