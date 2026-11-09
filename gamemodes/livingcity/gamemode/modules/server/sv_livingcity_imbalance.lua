--[[
    Living City: help for the outnumbered side

      The owner, 9 November: "If ... one side/faction had 2x the number of human players, I think we'd want
      to double (against the excess number of human players on the over stacked faction) the number of
      opposing faction NPCs. So if 15 resistance players and 5 cp/overwatch, then the cp/overwatch side gets
      an addition/excess temporary NPC budget of 20 (10 player difference x2) ... Please make sure all the
      excess NPCs don't end up standing only in combine HQ and not making a difference; even if we need to
      have a sort of 'reserve' combine soldier group that is ready to deploy near (NEAR, as in like a 15 ish
      second response time, not instant psychic appearance at the first gunshot) of a resistance raid".

      When one side's players (the Resistance; or Civil Protection and Overwatch together) are at least
      double the other's, and at least LC.ImbalanceFloor (4), the outnumbered side's NPCs get a bonus of
      LC.ImbalancePer (2) for every player of difference, at most LC.ImbalanceMax (40), on top of lc_npc_budget.

      The Combine outnumbered (the usual case):
        - Half the bonus walks the streets: extra Civil Protection patrols, spawned out of sight the city's own
          way and managed like the rest (they patrol, answer trouble, make arrests). Never parked in a base.
        - The other half is a quick reaction force that isn't on the map at all until it's needed: when a
          Resistance player gets violent (a unit killed, or Alert 2 and up) or a rebel raid arrives, a squad
          of Overwatch soldiers (4; or, the owner: "if sociostability is red and there is lots of rebel
          fighting ... 5 soldiers and an elite leading them", 5 and an Elite, when it's red, when 3 or more
          units have died in the last five minutes, or for an attack on a checkpoint or the Nexus) comes into being out of everyone's sight about LC.QRFRun (2800) units
          away, about fifteen seconds' run, and runs to the trouble. One squad to a place every 45 seconds;
          they stay LC.QRFStay (5 minutes) and then slip away when nobody's looking. Each comes out of the
          Combine's reserves (sv_livingcity_manpower.lua): an empty reserve sends nobody.
      The Resistance outnumbered: the bonus is more fighters in rebel territory (where there's room).

      By dropship (the owner, 9 November: "yes please" to a visible dropship and to answering attacks on
      checkpoints and the Nexus): with open sky near the trouble, the squad comes in by Combine dropship
      (sv_livingcity_dropship.lua), landing LC.QRFLandNear (500 to 1400 units) from it, and runs the rest
      of the way; only without sky anywhere near does it come on foot from out of sight as above.
      Attacks on checkpoints and the Nexus: a unit killed at a checkpoint (within 600 units of one) or
      in a Combine-only zone, by a Resistance player or a rebel NPC, a checkpoint's power bank shorted
      by a Resistance player, or a forcefield broken, bring a heavy squad (5 soldiers and an Elite).

      Seen: the Combine manpower readout's line, and the debug report.
]]

if CLIENT then return end

LC = LC or {}

LC.ImbalancePer, LC.ImbalanceFloor, LC.ImbalanceMax = 2, 4, 40
LC.QRFNormal, LC.QRFHeavy, LC.QRFMin = 4, 5, 6 -- (soldiers in a squad; in a heavy one, with an Elite leading; the reaction force is never smaller than a heavy squad)
LC.QRFHeavyLosses = 3 -- (units lost in five minutes that make it heavy)
LC.QRFRun, LC.QRFStay, LC.QRFAreaGap, LC.QRFGap = 2800, 300, 45, 15
LC.QRF = LC.QRF or {} -- [npc] = { untilT }

local function Log(level, msg) if LC.Log then LC.Log(level, msg) end end
local SIDE_OF = { resistance = "rebels", cp = "combine", ota = "combine" }

-- Players on each side now.
function LC.ImbalanceCounts()
    local n = { rebels = 0, combine = 0 }
    for _, p in ipairs(player.GetAll()) do
        local s = SIDE_OF[p:GetNW2String("lcf_faction", "")]
        if s then n[s] = n[s] + 1 end
    end
    return n
end
-- The outnumbered side ("combine" or "rebels") and its bonus, or nil, 0.
function LC.ImbalanceBonus(n)
    n = n or LC.ImbalanceCounts()
    local big, small, side
    if n.rebels >= n.combine then big, small, side = n.rebels, n.combine, "combine" else big, small, side = n.combine, n.rebels, "rebels" end
    if big < LC.ImbalanceFloor or big < 2 * small or big == small then return nil, 0 end
    return side, math.min(LC.ImbalanceMax, LC.ImbalancePer * (big - small))
end

-- The patrols' share and the reaction force's share, kept current for the population code (sv_livingcity.lua).
local function Refresh()
    local side, bonus = LC.ImbalanceBonus()
    LC.ImbalanceSide, LC.ImbalanceTotal = side, bonus
    LC.ImbalanceCops = side == "combine" and math.floor(bonus / 2) or 0
    LC.ImbalanceBudget = side == "combine" and LC.ImbalanceCops or bonus -- (the cap rises for the patrols; the reaction force is on top, like any response squad)
    LC.ImbalanceQRFSize = side == "combine" and math.max(LC.QRFMin, bonus - math.floor(bonus / 2)) or 0
    LC.ImbalanceRebels = side == "rebels" and bonus or 0
end
LC.ImbalanceRefresh = Refresh
timer.Create("LivingCityImbalance", 5, 0, function() pcall(Refresh) end)
hook.Add("PlayerInitialSpawn", "LivingCityImbalance", function() timer.Simple(1, function() pcall(Refresh) end) end)
hook.Add("PlayerDisconnected", "LivingCityImbalance", function() timer.Simple(1, function() pcall(Refresh) end) end)

------------------------------------------------------------------------
-- The quick reaction force
------------------------------------------------------------------------

function LC.QRFOut()
    local n = 0
    for npc in pairs(LC.QRF) do if IsValid(npc) then n = n + 1 else LC.QRF[npc] = nil end end
    return n
end

-- Somewhere out of everyone's sight, about fifteen seconds' run from pos.
function LC.QRFSpot(pos)
    local best, bestErr
    for _ = 1, 50 do
        local p = LC.RandomWanderPos and LC.RandomWanderPos("soldier", pos)
        if not p then break end
        local d = p:Distance(pos)
        if d > 1200 and d < 4500 and not (LC.IsSeen and LC.IsSeen(p + Vector(0, 0, 50))) and (not LC.NavReachable or LC.NavReachable(p, pos)) then
            local err = math.abs(d - LC.QRFRun)
            if not bestErr or err < bestErr then best, bestErr = p, err end
            if err < 500 then break end
        end
    end
    return best
end

LC.QRFLandNear, LC.QRFPlaceExtra = { 500, 1400 }, 1 -- (extra > 0: a heavy squad)
LC.QRFPending = LC.QRFPending or 0 -- (on their way by dropship, not yet out)
-- Somewhere near pos with open sky for a dropship to set down, or nil.
function LC.QRFLandSpot(pos)
    if not (LC.FlyDropship and LC.DropshipHeadroom) then return nil end
    for _ = 1, 40 do
        local p = LC.RandomWanderPos and LC.RandomWanderPos("soldier", pos)
        if not p then break end
        local d = p:Distance(pos)
        if d >= LC.QRFLandNear[1] and d <= LC.QRFLandNear[2] then
            local room, sky = LC.DropshipHeadroom(p)
            if sky and room > 900 and (not LC.NavReachable or LC.NavReachable(p, pos)) then return p end
        end
    end
    return nil
end
-- Units lost lately (any killed by someone not of the Combine), for a heavy squad.
local losses = {}
hook.Add("OnNPCKilled", "LivingCityQRFLosses", function(npc, attacker)
    if IsValid(npc) and npc.GetClass and (npc:GetClass() == "npc_metropolice" or npc:GetClass() == "npc_combine_s") then losses[#losses + 1] = CurTime() end
end)
function LC.QRFRecentLosses()
    local now, keep = CurTime(), {}
    for _, t in ipairs(losses) do if now - t < 300 then keep[#keep + 1] = t end end
    losses = keep
    return #keep
end
-- Heavy now? (red, or a lot of fighting lately)
function LC.QRFHeavyNow() return LC.Socio == "red" or LC.QRFRecentLosses() >= LC.QRFHeavyLosses end
-- The squad: a list of soldier kinds ("elite" first when heavy, then plain soldiers), at most room.
function LC.QRFSquad(heavy, room)
    local out = {}
    if heavy then out[1] = "elite" end
    for _ = 1, heavy and LC.QRFHeavy or LC.QRFNormal do out[#out + 1] = "soldier" end
    while #out > math.max(1, room or #out) do table.remove(out) end
    return out
end
-- One of the squad, out at at, sent after target (a player) or to pos. kind: "elite" or "soldier".
local function Deploy(at, i, pos, target, kind)
    local spawn = LC.Spawners.soldier or LC.SpawnSoldier
    local npc, st = nil, nil
    if spawn then npc, st = spawn(at + Vector(math.cos(i) * 60, math.sin(i) * 60, 4), kind == "elite" and "elite" or nil) end
    if not (IsValid(npc) and st) then return nil end
    st.unmanaged, st.armed, st.qrf = true, true, true
    LC.QRF[npc] = { untilT = CurTime() + LC.QRFStay }
    if IsValid(target) and target.IsPlayer and target:IsPlayer() and LC.MakeOneHostile then LC.MakeOneHostile(npc, st, target)
    elseif npc.SetLastPosition and SCHED_FORCED_GO_RUN then npc:SetLastPosition(pos) npc:SetSchedule(SCHED_FORCED_GO_RUN) end
    return npc
end
LC.QRFDeploy = Deploy

local lastAt, areas = 0, {}
-- Send a squad to pos (after target, a player, if there is one); extra: more for an attack on a checkpoint or the Nexus.
-- The number sent (or on the way), and why not (0 and a reason).
function LC.QRFDispatch(pos, target, why, extra)
    if LC.ImbalanceSide ~= "combine" or (LC.ImbalanceQRFSize or 0) <= 0 then return 0, "the sides aren't uneven" end
    if not LC.Running or not LC.Spawners then return 0, "the city isn't running" end
    local now = CurTime()
    if now - lastAt < LC.QRFGap then return 0, "a squad went out a moment ago" end
    for i = #areas, 1, -1 do
        local a = areas[i]
        if now - a.t > LC.QRFAreaGap then table.remove(areas, i) elseif a.pos:Distance(pos) < 1500 then return 0, "a squad is already on its way here" end
    end
    local room = LC.ImbalanceQRFSize - LC.QRFOut() - LC.QRFPending
    if room <= 0 then return 0, "the whole reaction force is out" end
    local squad = LC.QRFSquad((extra or 0) > 0 or LC.QRFHeavyNow(), room)
    local want = #squad
    -- by dropship, if there's open sky near the trouble
    local land = LC.QRFLandSpot(pos)
    if land then
        LC.QRFPending = LC.QRFPending + want
        local landed = false
        local ship = LC.FlyDropship({ pos = land, hold = 6 + want * 1.4, troops = true,
            onLanded = function(_, ground, _, door)
                landed = true
                local at = (door and door.pos) or ground or land
                for i = 1, want do -- (the Elite first out of the door, leading them)
                    timer.Simple(0.8 + (i - 1) * 1.2, function()
                        LC.QRFPending = math.max(0, LC.QRFPending - 1)
                        Deploy(at, i, pos, target, squad[i])
                    end)
                end
            end,
            onGone = function() if not landed then LC.QRFPending = math.max(0, LC.QRFPending - want) end end })
        if ship then
            lastAt = now
            areas[#areas + 1] = { pos = pos, t = now }
            if LC.RadioNotice then LC.RadioNotice("cp", string.format("Dispatch: %s inbound by dropship to %s. Hold on.", squad[1] == "elite" and ("an Elite and " .. (want - 1) .. " soldiers") or (want .. " soldiers"), why or "the disturbance")) end
            Log("info", string.format("Reaction squad of %d by dropship (%s)", want, tostring(why)))
            return want, "by dropship"
        end
        LC.QRFPending = math.max(0, LC.QRFPending - want)
    end
    -- else on foot, from out of sight about fifteen seconds away
    local spot = LC.QRFSpot(pos)
    if not spot then return 0, "nowhere out of sight to come from" end
    local made = 0
    for i = 1, want do if Deploy(spot, i, pos, target, squad[i]) then made = made + 1 end end
    if made > 0 then
        lastAt = now
        areas[#areas + 1] = { pos = pos, t = now }
        if LC.RadioNotice then LC.RadioNotice("cp", string.format("Dispatch: reaction squad of %d inbound to %s. Hold on.", made, why or "the disturbance")) end
        Log("info", string.format("Reaction squad of %d dispatched (%s), %d of the reaction force out", made, tostring(why), LC.QRFOut()))
    end
    return made, "on foot"
end

-- When they're called: a Resistance player turning violent, or a rebel raid arriving.
local function Resistance(p) return IsValid(p) and p.IsPlayer and p:IsPlayer() and p:GetNW2String("lcf_faction", "") == "resistance" end
hook.Add("LivingCityAlert", "LivingCityImbalance", function(ply, level)
    if level >= 2 and Resistance(ply) then LC.QRFDispatch(ply:GetPos(), ply, "an armed rebel") end
end)
-- A checkpoint or the Nexus (a Combine-only zone) at pos, by name, or nil.
function LC.QRFPlace(pos)
    if LC.CombineZoneAt and LC.CombineZoneAt(pos) then return "the Nexus" end
    for _, pt in ipairs(LC.PointsOfKind and LC.PointsOfKind("checkpoint") or {}) do
        if pt.pos and pt.pos:Distance(pos) < 600 then return "a checkpoint" end
    end
    return nil
end
local function RebelNPC(a) return IsValid(a) and a.GetClass ~= nil and (a:GetClass() == "npc_citizen" or a:GetClass() == "npc_vortigaunt") end
hook.Add("OnNPCKilled", "LivingCityImbalance", function(npc, attacker)
    if not (IsValid(npc) and npc.GetClass and (npc:GetClass() == "npc_metropolice" or npc:GetClass() == "npc_combine_s")) then return end
    local place = LC.QRFPlace(npc:GetPos())
    if place and (Resistance(attacker) or RebelNPC(attacker)) then -- (an attack on a checkpoint or the Nexus: by a player or the rebels' own)
        LC.QRFDispatch(npc:GetPos(), Resistance(attacker) and attacker or nil, "the attack on " .. place, LC.QRFPlaceExtra)
    elseif Resistance(attacker) then
        LC.QRFDispatch(npc:GetPos(), attacker, "a unit down")
    end
end)
hook.Add("LivingCityPowerBankShorted", "LivingCityImbalance", function(bank, ply)
    if IsValid(bank) and Resistance(ply) then LC.QRFDispatch(bank:GetPos(), ply, "sabotage at a checkpoint", LC.QRFPlaceExtra) end
end)
hook.Add("LivingCityForcefieldBroken", "LivingCityImbalance", function(f)
    if IsValid(f) then LC.QRFDispatch(f:GetPos(), nil, "a broken forcefield at " .. (LC.QRFPlace(f:GetPos()) or "a checkpoint"), LC.QRFPlaceExtra) end
end)
hook.Add("LivingCityRaidArrived", "LivingCityImbalance", function(sk)
    local at
    for _, r in ipairs(sk and sk.rebels or {}) do
        local st = IsValid(r) and LC.NPCs and LC.NPCs[r]
        if st and st.raid and st.raid.target then at = st.raid.target break end
        if IsValid(r) then at = r:GetPos() break end
    end
    if at then LC.QRFDispatch(at, nil, "the rebel raid") end
end)

-- Their time up: away, once nobody's looking (and gone regardless a minute later).
timer.Create("LivingCityQRF", 3, 0, function()
    local now = CurTime()
    for npc, q in pairs(LC.QRF) do
        if not IsValid(npc) then LC.QRF[npc] = nil
        elseif now > q.untilT and (now > q.untilT + 60 or not (LC.IsSeen and LC.IsSeen(npc:GetPos() + Vector(0, 0, 50)))) then
            LC.QRF[npc] = nil
            npc:Remove() -- (alive, so back in the reserve: sv_livingcity_manpower.lua)
        end
    end
end)

-- A line for the readouts.
function LC.ImbalanceLine()
    local side, bonus = LC.ImbalanceSide, LC.ImbalanceTotal or 0
    if not side or bonus <= 0 then return nil end
    if side == "combine" then
        return string.format("Outnumbered by the Resistance: %d more units on the streets, and a reaction force of %d (%d out now).", LC.ImbalanceCops or 0, LC.ImbalanceQRFSize or 0, LC.QRFOut())
    end
    return string.format("Outnumbered by the Combine: %d more Resistance fighters in rebel territory.", LC.ImbalanceRebels or 0)
end
