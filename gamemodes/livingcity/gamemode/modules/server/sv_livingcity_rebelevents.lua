--[[
    Living City: the Resistance's raids and operations, made real and findable

    The owner, 7 November: "I see announcements for them and see sociostability
    changing, but I have never actually seen rebel NPCs doing anything." What
    was wrong is in docs/dev/rebel-activity-audit.md. What this file adds:

      Who goes         a raid or operation takes the fighters already in rebel
                       territory first, as many as it needs (never the
                       quartermaster, a posted lookout, one out scavenging or
                       anyone a player is with), and walks them out. Still short:
                       a spare NPC somewhere nobody can see (an idle fighter in
                       another zone, then a citizen) is taken out and a fighter
                       comes in at the raid's hidden spot instead, so the city's
                       NPC count doesn't go up (the owner: "just literally move
                       those NPCs to the raid"). The Combine side does the same:
                       an idle unit is sent, or swapped for one near the fight.
                       Room left under lc_npc_budget is used before any swap.
                       Only when nothing can be swapped, lc_event_npc_allowance
                       (0: off) more may come in above the cap, as a last resort.
                       Everyone a raid brought counts against lc_npc_budget
                       until they're home or gone.
      Getting there    raiders walk the city's own routes (the drawn paths, or
                       the map's nodegraph) to the target, not just the
                       engine's straight try; one stuck behind a wall gets past
                       it where nobody can see (never in front of anyone). The
                       raid's clock starts when they get there, so a long walk
                       doesn't use it up; one that hasn't got there in six
                       minutes is called off, and nobody claims a fight.
      Someone to fight a raid that reaches its target with fewer than two units
                       there gets units sent (the owner's city had none on the
                       street: its NPC cap was full of citizens).
      Findable         the Resistance's players see where their fighters are
                       ("Our fighters" on screen, following them) from the
                       moment they set out; Civil Protection and Overwatch
                       players see the fight ("10-20: ANTICITIZEN ATTACK")
                       once it starts.
      Honest           what says a fight happened (the ration dock "near a
                       Resistance attack", the PA's skirmish_raid line, the
                       rumours, the "rebel raid" tip) waits until the fighters
                       are really at the target.

    The Commissary's restrictions (sv_livingcity_market.lua) put another fighter
    in rebel territory for each one, as far as the zones have room. On top of
    that, raid and operation parties grow (the owner's words): one more fighter
    from 3 restrictions, two from 5, and one more for each past that, never
    more than lc_market_raid_max (6). The fighters the zones have no room for,
    or that the NPC cap keeps out, go into the parties instead.

      lc_event_npc_allowance <n>   last resort: NPCs a raid, operation or sweep may add above lc_npc_budget
                                   when nobody can be moved or swapped (0)
      lc_market_raid_max <n>       most extra raiders the Commissary's restrictions add to a party (6)
]]

if CLIENT then return end

LC = LC or {}

local FLAGS = bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED)
local cvAllow   = CreateConVar("lc_event_npc_allowance", "0", FLAGS, "Last resort: NPCs a Resistance raid, operation or sweep may add above lc_npc_budget when no idle NPC can be moved or swapped (taken away when it ends)")
local cvRaidMax = CreateConVar("lc_market_raid_max", "6", FLAGS, "Most extra fighters the Administrator's Commissary restrictions add to a Resistance raid or operation")

local UP = Vector(0, 0, 50)
local BASE_PARTY = 4    -- fighters in a raid before the Commissary's extras
local WALK_LIMIT = 360  -- seconds to reach the target before a raid is called off
local STUCK_SECS = 8    -- this long without getting anywhere: stuck
local SEND_RANGE = 6000 -- an idle unit this close is sent to a raid as he is; further, he's swapped
LC.RaidWalkSecs = WALK_LIMIT

------------------------------------------------------------------------
-- The Commissary's restrictions, in the raids
------------------------------------------------------------------------

-- Extra raiders for n restrictions: none for 1 or 2, one from 3, two from 5, then one more each.
function LC.MarketRaidScale(n)
    n = math.floor(tonumber(n) or 0)
    if n < 3 then return 0 end
    if n < 5 then return 1 end
    return 2 + (n - 5)
end

-- The restrictions' fighters rebel territory can't take in (no room in the zones, or the NPC cap
-- full before they turn up): they join the raids instead.
function LC.MarketRebelOverflow()
    local bonus = LC.MarketRebelBonus and LC.MarketRebelBonus() or 0
    if bonus <= 0 then return 0 end
    local zones = LC.ZonesOfKind and LC.ZonesOfKind("rebel") or {}
    if #zones == 0 then return 0 end
    local home = 0
    for _, z in ipairs(zones) do home = home + (LC.RebelsIn and LC.RebelsIn(z) or 0) end
    local cv = GetConVar("lc_rebels")
    local base = math.max(0, cv and cv:GetInt() or 0) + (LC.GrownCount and LC.GrownCount("rebel") or 0)
    local housed = math.Clamp(home - base, 0, bonus)
    return bonus - housed
end

function LC.MarketRaidExtra()
    local n = LC.MarketRestrictedCount and LC.MarketRestrictedCount() or 0
    if n <= 0 then return 0 end
    return math.min(math.max(0, cvRaidMax:GetInt()), LC.MarketRaidScale(n) + LC.MarketRebelOverflow())
end

-- How many fighters a raid or operation sets out with.
function LC.RaidPartySize()
    return BASE_PARTY + LC.MarketRaidExtra()
end

------------------------------------------------------------------------
-- Who goes: the city's own NPCs moved, or swapped, before anyone new
------------------------------------------------------------------------

LC.EventNPCs = LC.EventNPCs or {} -- [npc] = the skirmish they came for

local BUSY = { hostile = true, escort = true, event = true, escorted = true, jailed = true, detained = true, fighting = true, abed = true }

-- Idle, and nobody's counting on them (a player's squad, a post, a job, a fight...).
local function Spare(npc, st, role)
    if not IsValid(npc) or npc:Health() <= 0 or st.role ~= role or st.test or st.unmanaged or st.eventNPC then return false end
    if st.questLock or st.questSquad or BUSY[st.state] or st.foe or st.raid or st.skirmish then return false end
    if role == "rebel" then
        return not (st.follow or st.post or st.quartermaster or st.errand or st.wave or st.returning)
    end
    return not (st.backupFor or st.workEscort or st.marching or st.escortee or st.subject or st.guardZone or st.holdPos
        or st.withdrawing or st.cleanGuard or st.npcWork)
end
LC.EventSpare = Spare

-- Idle fighters at home in this zone, to walk out with the raid (the quartermaster, lookouts on
-- their posts, anyone out scavenging or with a player stay where they are).
function LC.RaidTakeFromZone(z, want)
    local out = {}
    for npc, st in pairs(LC.NPCs) do
        if #out >= want then break end
        if st.zone == z and Spare(npc, st, "rebel") then out[#out + 1] = npc end
    end
    return out
end

-- The city's NPCs as lc_npc_budget counts them, with everyone out on a raid or sweep.
function LC.CityNPCCount()
    local n = 0
    for npc, st in pairs(LC.NPCs) do
        if IsValid(npc) and npc:Health() > 0 and not st.test and st.state ~= "abed" and (not st.unmanaged or st.eventNPC) then n = n + 1 end
    end
    return n
end

local function Budget()
    local cv = GetConVar("lc_npc_budget")
    return cv and cv:GetInt() or 60
end

-- Opened when a raid or sweep starts: what it may add above the cap, as a last resort.
function LC.EventOpen(sk)
    sk.allowance = math.max(0, cvAllow:GetInt())
    sk.spawned = 0 -- (above the cap)
    sk.swapped = 0
end

-- What it may still add above the cap: none once it's over.
function LC.EventRoom(sk)
    if not sk or sk.done or not sk.allowance then return 0 end
    return math.max(0, sk.allowance - (sk.spawned or 0))
end

-- Raid and sweep NPCs out now.
function LC.EventNPCCount()
    local n = 0
    for npc, sk in pairs(LC.EventNPCs) do
        if IsValid(npc) and not sk.done then n = n + 1 end
    end
    return n
end

-- Room for one more on this raid or sweep: under the cap; else a spare NPC nobody can see (of these
-- roles, in order) is taken out to make it; else the last-resort allowance. True: spawn one.
function LC.EventSlot(sk, roles, avoidZone)
    if not sk or sk.done then return false end
    if LC.CityNPCCount() < Budget() then return true end
    for _, role in ipairs(roles or { "citizen" }) do
        for npc, st in pairs(LC.NPCs) do
            if Spare(npc, st, role) and not (avoidZone and st.zone == avoidZone) and not LC.IsSeen(npc:GetPos() + UP) then
                npc:Remove() -- (the city forgets them: sv_livingcity.lua, EntityRemoved)
                sk.swapped = (sk.swapped or 0) + 1
                return true
            end
        end
    end
    if LC.EventRoom(sk) > 0 then
        sk.spawned = (sk.spawned or 0) + 1
        return true
    end
    return false
end

-- One of the raid's or sweep's own: counted against the cap until home or gone.
function LC.EventNPCAdd(sk, npc, st)
    if not IsValid(npc) then return end
    LC.EventNPCs[npc] = sk
    if st then st.eventNPC = true end
end

hook.Add("LivingCitySkirmishEnded", "LivingCityRebelEvents", function(_, sk)
    -- the allowance goes; whoever came for it goes home (and stays counted until they're there or
    -- gone: sv_livingcity_rebels.lua), or withdraws out of sight
    for npc, s in pairs(LC.EventNPCs) do
        if s == sk or not IsValid(npc) then LC.EventNPCs[npc] = nil end
    end
end)
hook.Add("LivingCityStopped", "LivingCityRebelEvents", function() LC.EventNPCs = {} end)

------------------------------------------------------------------------
-- Getting to the target
------------------------------------------------------------------------

-- A spot near pos nobody can see, for one who has to get past something.
local function UnseenNear(pos, minD, maxD)
    for _ = 1, 12 do
        local a = math.Rand(0, math.pi * 2)
        local d = math.Rand(minD, maxD)
        local p = pos + Vector(math.cos(a) * d, math.sin(a) * d, 0)
        if not LC.IsSeen(p + UP) and (not LC.FarFromPlayers or LC.FarFromPlayers(p, 400))
            and (not LC.ClearSpot or LC.ClearSpot(p)) then return p end
    end
    return nil
end

-- One raider's walk to the target, hop by hop along the city's routes. True: handled.
function LC.RaidWalk(npc, st, r, now)
    if not IsValid(npc) or not r or not r.target or not LC.RebelHeadFor then return false end
    local pos = npc:GetPos()
    if not r.route then
        local route = LC.BuildRoute and LC.BuildRoute(pos, r.target, "rebel")
        r.route = type(route) == "table" and route or { r.target }
        r.hop = 1
        r.lastPos, r.lastMoved = pos, now
    end
    local last = #r.route
    if r.hop < last and pos:DistToSqr(r.route[r.hop]) < 120 * 120 then r.hop = r.hop + 1 end
    local goal = r.route[r.hop] or r.target
    if pos:DistToSqr(r.lastPos) > 60 * 60 then r.lastPos, r.lastMoved = pos, now end
    local there = pos:DistToSqr(r.target) < 220 * 220
    if there then
        r.lastMoved = now
    elseif now - r.lastMoved > STUCK_SECS and not LC.IsSeen(pos + UP) then
        -- stuck (a wall, a door, the engine finding no way): past it where nobody's looking,
        -- to the next stop on the route, or round to the target from another side
        local to
        if r.hop < last and not LC.IsSeen(r.route[r.hop] + UP) then
            to = r.route[r.hop]
            r.hop = r.hop + 1
        else
            to = UnseenNear(r.target, 250, 600)
        end
        if to then
            npc:SetPos(to + Vector(0, 0, 4))
            st.goingTo = nil
            r.skips = (r.skips or 0) + 1
        end
        r.lastPos, r.lastMoved = npc:GetPos(), now
    end
    LC.RebelHeadFor(npc, st, goal, true)
    return true
end

------------------------------------------------------------------------
-- When they get there
------------------------------------------------------------------------

local function LiveRebels(sk)
    local out = {}
    for _, n in ipairs(sk.rebels or {}) do if IsValid(n) and n:Health() > 0 then out[#out + 1] = n end end
    return out
end

-- Somewhere out of sight the units can come from, not too near and not too far.
local function ResponderSpot(target)
    for _ = 1, 30 do
        local p = LC.RandomWanderPos and LC.RandomWanderPos("cop", target)
        if p then
            local d = p:Distance(target)
            if d > 700 and d < 2400 and not LC.IsSeen(p + UP) and (not LC.ClearSpot or LC.ClearSpot(p)) then return p end
        end
    end
    return UnseenNear(target, 900, 1800)
end
LC.EventResponderSpot = ResponderSpot

local function OnRaid(sk, npc, st, raider, now)
    st.skirmish = sk
    if LC.ArmUnit then LC.ArmUnit(npc, st) end
    if LC.MakeOneHostile then LC.MakeOneHostile(npc, st, raider) end
    st.provokedBy, st.provokedUntil = raider, now + 150
    sk.units[#sk.units + 1] = npc
end

-- Units sent to answer a raid that has too few to fight it: an idle unit not too far is sent as
-- he is; else one is swapped in near the fight (an idle unit or a citizen nobody can see taken
-- out), never adding to the city's NPCs unless the last-resort allowance allows.
function LC.RaidResponders(sk, now)
    if not sk or sk.done or sk.respondersSent then return 0 end
    sk.respondersSent = true
    local live = 0
    for _, u in ipairs(sk.units or {}) do if IsValid(u) and u:Health() > 0 then live = live + 1 end end
    local raiders = LiveRebels(sk)
    if #raiders == 0 then return 0 end
    local want = math.max(0, math.min(3, math.max(2, math.ceil(#raiders / 2))) - live)
    local sent, moved = 0, 0
    -- idle units who can get there
    local near = {}
    for npc, st in pairs(LC.NPCs) do
        if LC.IsSecurity(st) and st.role ~= "scanner" and Spare(npc, st, st.role) and npc:GetPos():DistToSqr(sk.target) < SEND_RANGE * SEND_RANGE then
            near[#near + 1] = { npc = npc, st = st, d = npc:GetPos():DistToSqr(sk.target) }
        end
    end
    table.sort(near, function(a, b) return a.d < b.d end)
    for i = 1, math.min(want, #near) do
        OnRaid(sk, near[i].npc, near[i].st, raiders[(i - 1) % #raiders + 1], now)
        moved = moved + 1
    end
    -- then swapped in, out of sight near the fight
    for i = moved + 1, want do
        if not (LC.Spawners and LC.Spawners.cop) then break end
        local spot = ResponderSpot(sk.target)
        if LC.ManpowerCan and not LC.ManpowerCan("cp") then break end -- (none left in reserve: sv_livingcity_manpower.lua)
        if not spot or not LC.EventSlot(sk, { "cop", "soldier", "citizen" }) then break end
        local npc, st = LC.Spawners.cop(spot + Vector(math.random(-40, 40), math.random(-40, 40), 4))
        if IsValid(npc) and st then
            st.unmanaged, st.leaveAt, st.routeGroup = true, nil, nil
            OnRaid(sk, npc, st, raiders[(i - 1) % #raiders + 1], now)
            sk.stage = sk.stage or spot -- (where they withdraw to afterwards)
            LC.EventNPCAdd(sk, npc, st)
            sent = sent + 1
        end
    end
    if sent + moved > 0 then LC.Log("info", string.format("Skirmish: %d unit(s) sent to answer the raid, %d swapped in", moved, sent)) end
    return sent + moved
end

-- The fighters are at the target: the fight is real now. Its clock starts here.
function LC.RaidArrived(sk, now)
    if not sk or sk.arrivedAt then return end
    sk.arrivedAt = now
    sk.ends = math.max(sk.ends or 0, now + (sk.purpose and 240 or 150))
    for _, n in ipairs(sk.rebels or {}) do
        local st = IsValid(n) and LC.NPCs[n]
        if st and st.raid then st.raid.ends = sk.ends end
    end
    LC.RaidResponders(sk, now)
    LC.RaidMarkers(sk, now, true)
    hook.Run("LivingCityRaidArrived", sk)
end

------------------------------------------------------------------------
-- Findable: where it is, on the screens of those it's for
------------------------------------------------------------------------

local function IsResistance(p) return p:GetNW2String("lcf_faction", "") == "resistance" end
local function IsCombine(p)
    local f = p:GetNW2String("lcf_faction", "")
    return f == "cp" or f == "ota" or (LC.PlayerIsCP and LC.PlayerIsCP(p)) == true
end

local function Middle(list)
    local sum = Vector(0, 0, 0)
    for _, n in ipairs(list) do sum = sum + n:GetPos() end
    return sum / #list
end

-- Who gets which marker, now: { [ply] = { name, label, pos } }.
function LC.RaidMarkerPlan(sk)
    local out = {}
    if not sk or sk.done or sk.kind ~= "raid" then return out end
    local raiders = LiveRebels(sk)
    if #raiders == 0 then return out end
    local where = Middle(raiders)
    for _, p in ipairs(player.GetAll()) do
        if IsResistance(p) then
            out[p] = { name = "OUR FIGHTERS", label = "Our fighters", pos = where, rebel = true }
        elseif sk.arrivedAt and IsCombine(p) then
            out[p] = { name = "ANTICITIZEN ATTACK", pos = sk.target }
        end
    end
    return out
end

function LC.RaidMarkers(sk, now, fresh)
    if not LC.SendCompressed then return end
    for p, m in pairs(LC.RaidMarkerPlan(sk)) do
        local first = p.lcRaidMarked ~= sk or p.lcRaidMarkName ~= m.name
        p.lcRaidMarked, p.lcRaidMarkName = sk, m.name
        LC.SendCompressed("lc_cpmark", { name = m.name, label = m.label, rebel = m.rebel, quiet = not (first or fresh) or nil,
            x = m.pos.x, y = m.pos.y, z = m.pos.z, secs = 8 }, { p })
    end
end

------------------------------------------------------------------------
-- The clock
------------------------------------------------------------------------

timer.Create("LivingCityRebelEvents", 2, 0, function()
    local ok, err = pcall(function()
        if not LC.Running then return end
        local now = CurTime()
        local sk = LC.Skirmish
        if sk and sk.kind == "raid" and not sk.done then
            -- never got there: called off, rather than an attack announced that nobody fights
            if not sk.arrivedAt and now - (sk.started or now) > WALK_LIMIT and LC.EndSkirmish then
                return LC.EndSkirmish(sk, "never got there")
            end
            if now >= (sk.nextMark or 0) then
                sk.nextMark = now + 5
                LC.RaidMarkers(sk, now)
            end
        end
        for npc in pairs(LC.EventNPCs) do if not IsValid(npc) then LC.EventNPCs[npc] = nil end end
    end)
    if not ok and LC.Error then LC.Error("rebel events", err) end
end)
