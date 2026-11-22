--[[
    Living City: the Resistance's supply lines (docs/features/supply-lines.md)

    The owner, 22 November: "Now and then an NPC courier walks the road, or a boat comes up the canal, with
    food and rounds for the HQ crate. The Resistance get an escort job, Civil Protection get Stop the courier.
    This needs the route marked on the map, as editor points or names in the map pieces."

      When        only while the Resistance's headquarters is live (sv_livingcity_base.lua), now and then:
                  every 15 to 25 minutes (SL.MINUTES, give or take a quarter), one at a time.
                  A map with no route has none.
      Routes      the map's own: info_targets named lc_supply_road_1, _2, ... (a courier on foot) and
                  lc_supply_canal_1, _2, ... (a boat), in that order. Or the editor's: "Point: supply line,
                  road" and "Point: supply line, canal" (the # is the route; its points in the order they
                  were placed). Every route ends at the headquarters' supply crate: the last leg goes from
                  the route's last point to the crate (the city's paths where it has them).
      The road    a Resistance courier in plain clothes, unarmed, a box in both hands, walks the route from
                  its first point to the crate. Shot at, or a unit close, he runs.
      The canal   a canal boat with a rebel in it comes up the route on the water (the server moves it
                  smoothly point to point; a point under the water is lifted to its surface). At the last
                  point it ties up, and the boatman takes a box ashore and walks it to the crate. Shooting
                  the boat sinks it (BOAT_HP); shooting the boatman stops it.
      In          LOAD_FOOD meals into the crate (LC.AddToCache), and the rounds as boxes of ammunition set
                  on the crate (the Resistance have no stock of rounds: the fund buys them as fighters are
                  issued). Killed, caught, sunk: nothing comes in.
      The jobs    posted as the run starts (LC.PostDirective). The Resistance: "Escort the courier" or
                  "Meet the boat" (get to him, see him in: a member near him as he gets to the crate);
                  the courier waits at his first point for whoever takes it, as a supply drop waits for
                  its guards (LC.ProtectWait). Civil Protection and Overwatch: "Stop the courier" (kill
                  him, arrest him, sink the boat): the usual pay. Their marker shows him only once a unit
                  (a player or the Combine's own) has seen him, or once he is half way.

      Settings    none: a route on the map turns them on (no route, none); SL.MINUTES is fixed (20)
      For others  LC.SupplyLineStart(kind) (kind "road", "canal" or nil), LC.SupplyLineRoutes(kind),
                  LC.SupplyLines.run (the run under way: kind, state "waiting", "boat", "walk", courier,
                  boat, spotted), hooks LivingCitySupplyLine(run), LivingCitySupplyArrived(run, food,
                  rounds), LivingCitySupplyStopped(run, how, by) with how "killed", "caught", "sunk",
                  "shot" or "off".
]]

if CLIENT then return end

LC = LC or {}
LC.SupplyLines = LC.SupplyLines or {}
local SL = LC.SupplyLines

SL.MINUTES = 20                                                      -- between runs, give or take a quarter (15 to 25)

SL.LOAD_FOOD = 6                                                     -- meals into the crate
SL.LOAD_ROUNDS = { ammo_pistol = 2, ammo_smg = 1, ammo_buckshot = 1 } -- boxes set on the crate
SL.MAX_SECS = 900        -- a run not in by then is called off (stuck somewhere)
SL.BOAT = "models/props_canal/boat001a.mdl"
SL.BOAT_SPEED = 90       -- units a second
SL.BOAT_HP = 300         -- what sinks it
SL.RIDER_HP = 60         -- what stops the boatman
SL.RIDER = "models/Humans/Group01/male_07.mdl"
SL.BOX = "models/props_junk/cardboard_box001a.mdl"
SL.REACH = 70            -- how near a point counts as there
SL.SEEN_UNIT = 1500      -- how far a unit's player sees him (a clear line)
SL.SEEN_NPC = 900        -- and the Combine's own
SL.NEAR = 1500           -- how near him one of the escort must be as he gets in
local CUSTODY = { detained = true, escorted = true, jailed = true }

local function Unit(p) return LC.PlayerIsCP and LC.PlayerIsCP(p) end

------------------------------------------------------------------------
-- Routes
------------------------------------------------------------------------

-- The map's own: lc_supply_<kind>_1, _2, ... in order.
local function MapRoute(kind)
    local pts = {}
    for _, e in ipairs(ents.FindByName("lc_supply_" .. kind .. "_*")) do
        local n = IsValid(e) and tonumber(string.match(e:GetName() or "", "^lc_supply_" .. kind .. "_(%d+)$"))
        if n then pts[#pts + 1] = { n = n, pos = e:GetPos() } end
    end
    table.sort(pts, function(a, b) return a.n < b.n end)
    local out = {}
    for i, p in ipairs(pts) do out[i] = p.pos end
    return out
end

-- Every route there is: { kind = "road" or "canal", pts = { Vector, ... }, label }. A road needs one point
-- (the crate is the rest of the way), a canal two (where the boat sets out, where it ties up).
function LC.SupplyLineRoutes(want)
    local out = {}
    for _, kind in ipairs({ "road", "canal" }) do
        if not want or want == kind then
            local least = kind == "canal" and 2 or 1
            local pts = MapRoute(kind)
            if #pts >= least then out[#out + 1] = { kind = kind, pts = pts, label = kind .. " (the map's)" } end
            local by, order = {}, {}
            for _, p in ipairs(LC.Points or {}) do
                if p.kind == "supply" .. kind then
                    if not by[p.group] then by[p.group] = {} order[#order + 1] = p.group end
                    table.insert(by[p.group], p.pos)
                end
            end
            for _, g in ipairs(order) do
                if #by[g] >= least then out[#out + 1] = { kind = kind, pts = by[g], label = kind .. " " .. g } end
            end
        end
    end
    return out
end

-- The headquarters' crate: the territory's own, else the nearest one to it. -> crate (or nil), where to go.
function SL.Crate(zone)
    if not zone then return nil, nil end
    local function look()
        local r = LC.RebelProps and LC.RebelProps[zone]
        if r and IsValid(r.cache) then return r.cache end
        return LC.CacheNear and LC.CacheNear(zone.pos, math.max(800, (zone.r or 400) + 400)) or nil
    end
    local c = look()
    if not c and LC.EnsureRebelProps then LC.Try(LC.EnsureRebelProps) c = look() end
    if IsValid(c) then return c, c:GetPos() end
    return nil, (LC.Base and LC.Base.S and LC.Base.S.pos) or zone.pos
end

-- The water's surface at a canal point (a point placed with the editor lands on the canal's bed).
local function OnWater(p)
    if MASK_WATER then
        local tr = util.TraceLine({ start = p + Vector(0, 0, 400), endpos = p - Vector(0, 0, 64), mask = MASK_WATER })
        if tr and tr.Hit and not tr.StartSolid then return tr.HitPos end
    end
    return p
end

local function Dry(p)
    if not util.PointContents then return true end
    return bit.band(util.PointContents(p), CONTENTS_WATER or 32) == 0
end

-- Dry floor beside where the boat ties up, nearest first.
local function Ashore(at)
    for r = 60, 300, 60 do
        for a = 0, 330, 30 do
            local p = at + Vector(math.cos(math.rad(a)) * r, math.sin(math.rad(a)) * r, 0)
            local tr = util.TraceLine({ start = p + Vector(0, 0, 64), endpos = p - Vector(0, 0, 200), mask = MASK_NPCSOLID_BRUSHONLY })
            if tr and tr.Hit and not tr.StartSolid and Dry(tr.HitPos + Vector(0, 0, 8)) then return tr.HitPos end
        end
    end
    return at
end

-- The last leg: from the route's end to the crate, along the city's paths where it has them.
local function LastLeg(from, crate, dest)
    local to = dest
    if IsValid(crate) then
        local away = from - dest
        away.z = 0
        if away:LengthSqr() > 1 then to = dest + away:GetNormalized() * 40 end
    end
    local hops
    if LC.BuildRoute then
        local ok, r = LC.Try(LC.BuildRoute, from, to, "rebel")
        if ok and istable(r) then hops = r end
    end
    hops = hops or {}
    if #hops == 0 or hops[#hops]:DistToSqr(to) > 1 then hops[#hops + 1] = to end
    return hops
end

local function PathLength(from, pts)
    local n, at = 0, from
    for _, p in ipairs(pts) do n = n + at:Distance(p) at = p end
    return n
end

------------------------------------------------------------------------
-- The run
------------------------------------------------------------------------

-- What is on its way right now: the boat, or the man on foot (nil while he waits to set out).
function SL.Thing(run)
    run = run or SL.run
    if not run or run.over then return nil end
    if run.state == "boat" and IsValid(run.boat) then return run.boat end
    if run.state == "walk" and IsValid(run.courier) then return run.courier end
    return nil
end

local function Wait() return SL.MINUTES * 60 * math.Rand(0.75, 1.25) end

local leftovers = {}
local function Leave(e) if IsValid(e) then leftovers[#leftovers + 1] = { ent = e, at = CurTime() } end end

-- Let him go: the city has him again (or the cells do).
local function Release(run, home)
    local npc = run.courier
    local st = IsValid(npc) and LC.NPCs and LC.NPCs[npc]
    if not st then return end
    if IsValid(st.carry) and LC.NPCDropCarry then LC.NPCDropCarry(npc, st) end
    st.unmanaged, st.supplyCourier = nil, nil
    if st.state == "event" then st.eventUntil = 0 end
    if home then
        st.zone = run.zone
        if LC.SquadCasual then LC.SquadCasual(npc, st, false) end
    end
    if not CUSTODY[st.state] and not st.jailUntil then st.leaveAt = CurTime() + (home and 120 or 30) end
end

local function End(run, how)
    if run.over then return end
    run.over, run.how, run.endT = true, how, CurTime()
    if SL.run == run then SL.run = nil end
    SL.last = run
    SL.nextAt = CurTime() + Wait()
    -- (its jobs still on a board come off: the two posted as it set out, and any a board offered while it was on)
    for _, p in ipairs(run.postings or {}) do if not p.q then p.dead = true end end
    for _, list in pairs(LC.Postings or {}) do
        for _, p in ipairs(list) do if not p.q and istable(p.data) and p.data.run == run then p.dead = true end end
    end
    if run.how ~= "sunk" then Leave(run.boat) end
    if IsValid(run.rider) then Leave(run.rider) end
end

-- Stopped on the way: nothing comes in.
local function Stop(run, how, by)
    if run.over then return end
    run.state, run.by = "stopped", by
    if how == "sunk" and IsValid(run.boat) then
        local b = run.boat
        if IsValid(run.rider) then run.rider:Remove() end
        SL.sinking = SL.sinking or {}
        SL.sinking[#SL.sinking + 1] = { ent = b, t0 = CurTime(), z0 = b:GetPos().z }
        b:EmitSound("physics/wood/wood_crate_break" .. math.random(1, 5) .. ".wav", 80)
    end
    if how ~= "killed" then Release(run, false) end
    End(run, how)
    if LC.Log then LC.Log("info", "Supply run (" .. tostring(run.route and run.route.label) .. ") stopped: " .. how) end
    hook.Run("LivingCitySupplyStopped", run, how, by)
end

-- In at the crate: the food in it, the rounds on it.
local function Arrive(run)
    if run.over then return end
    run.state = "arrived"
    run.near = {}
    local at = IsValid(run.courier) and run.courier:GetPos() or run.dest
    for _, p in ipairs(player.GetAll()) do
        if p:Alive() and p:GetPos():DistToSqr(at) < SL.NEAR * SL.NEAR then run.near[p] = true end
    end
    local food = 0
    if IsValid(run.crate) and LC.AddToCache then food = LC.AddToCache(run.crate, SL.LOAD_FOOD) end
    local rounds = {}
    local top = IsValid(run.crate) and (run.crate:GetPos() + Vector(0, 0, 30)) or (run.dest + Vector(0, 0, 10))
    local ids, k = {}, 0
    for id in pairs(SL.LOAD_ROUNDS) do ids[#ids + 1] = id end
    table.sort(ids)
    for _, id in ipairs(ids) do
        local n = SL.LOAD_ROUNDS[id]
        if LCS and LCS.Items and LCS.Items[id] and LC.SpawnWorldItem then
            for _ = 1, n do
                k = k + 1
                local e = LC.SpawnWorldItem(id, top + Vector((k % 3) * 9 - 9, math.floor(k / 3) * 9 - 4, k * 2))
                if IsValid(e) then rounds[#rounds + 1] = id end
            end
        end
    end
    if IsValid(run.courier) then
        local st = LC.NPCs and LC.NPCs[run.courier]
        if st and LC.PlayGesture then LC.Try(LC.PlayGesture, run.courier, { "ACT_PICKUP_GROUND", "ACT_PICKUP_RACK" }, 1.5) end
        if IsValid(run.crate) then run.crate:EmitSound("physics/cardboard/cardboard_box_impact_soft" .. math.random(1, 3) .. ".wav", 60) end
    end
    Release(run, true)
    End(run, "arrived")
    if LC.Log then LC.Log("info", string.format("Supply run (%s) in: %d meals, %d boxes of rounds", tostring(run.route.label), food, #rounds)) end
    hook.Run("LivingCitySupplyArrived", run, food, rounds)
end

-- The man on foot, from where he is.
local function Courier(run, pos, path)
    local spawner = LC.SpawnRebel
    if not spawner then return nil end
    local ok, npc, st = LC.Try(LC.ManpowerFree or function(f, ...) return f(...) end, spawner, pos + Vector(0, 0, 4), nil, "")
    if not ok or not IsValid(npc) or not st then return nil end
    st.unmanaged, st.supplyCourier = true, run
    st.leaveAt, st.routeGroup, st.zone = nil, nil, nil
    if LC.SquadCasual then LC.SquadCasual(npc, st, true) end -- (plain clothes)
    if LC.NPCCarry then LC.NPCCarry(npc, st, SL.BOX) end
    if LC.SetState then LC.SetState(npc, st, "event") end
    st.eventUntil = CurTime() + 60
    run.courier, run.path, run.i = npc, path, 1
    run.walkStart = npc:GetPos()
    run.state = "walk"
    return npc
end

-- The boat, at the canal's first point, facing up the canal, with the boatman in it.
local function Boat(run)
    local pts = {}
    for i, p in ipairs(run.route.pts) do pts[i] = OnWater(p) + Vector(0, 0, 6) end
    run.water = pts
    run.boatLen = PathLength(pts[1], pts)
    run.boatAt, run.boatT = 0, CurTime()
    local b = ents.Create("prop_physics")
    if not IsValid(b) then return nil end
    b:SetModel(SL.BOAT)
    b:SetPos(pts[1])
    local d = pts[2] - pts[1]
    b:SetAngles(Angle(0, math.deg(math.atan2(d.y, d.x)), 0))
    b:Spawn()
    local ph = b.GetPhysicsObject and b:GetPhysicsObject()
    if IsValid(ph) then ph:EnableMotion(false) end
    b.lcSupplyBoat = true
    run.boat = b
    local r = ents.Create("prop_dynamic")
    if IsValid(r) then
        r:SetModel(SL.RIDER)
        r:SetKeyValue("solid", "2")
        r:SetPos(b:LocalToWorld(Vector(-40, 0, -12)))
        r:SetAngles(b:GetAngles())
        r:Spawn()
        if r.LookupSequence and r.ResetSequence then
            for _, name in ipairs({ "sitchair1", "Sit_Chair", "sitcouch1" }) do
                local seq = r:LookupSequence(name)
                if seq and seq >= 0 then r:ResetSequence(seq) break end
            end
        end
        r:SetParent(b)
        r.lcSupplyRider = true
        run.rider = r
    end
    run.riderHurt, run.boatHurt = 0, 0
    run.state = "boat"
    return b
end

-- On its way (when the escort has had its minute, or nobody took the job): the courier steps out where the
-- road starts (out of sight, if a few seconds' wait gives that), or the boat sets out.
function SL.SetOff(run, tries)
    if SL.run ~= run or run.over or run.state ~= "waiting" then return false end
    tries = tries or 0
    local start = run.route.pts[1]
    if tries < 8 and LC.IsSeen and LC.IsSeen(start + Vector(0, 0, 50)) then
        timer.Simple(2, function() SL.SetOff(run, tries + 1) end)
        return false
    end
    run.setOffT = CurTime()
    if run.kind == "canal" then
        if not Boat(run) then Stop(run, "off") return false end
        run.length = run.boatLen + run.route.pts[#run.route.pts]:Distance(run.dest)
    else
        local path = {}
        for i = 2, #run.route.pts do path[#path + 1] = run.route.pts[i] end
        for _, h in ipairs(LastLeg(run.route.pts[#run.route.pts], run.crate, run.dest)) do path[#path + 1] = h end
        local ground = LC.GroundAt and LC.GroundAt(start) or start
        if not Courier(run, ground, path) then Stop(run, "off") return false end
        run.length = PathLength(ground, path)
    end
    run.travel = 0
    return true
end

-- A run, now: the jobs go up, and the courier or the boat sets out once the escort has had its chance.
function LC.SupplyLineStart(want)
    if SL.run then return false, "A supply run is already under way." end
    if not LC.Running then return false, "The city isn't running." end
    local zone = LC.BaseLive and LC.BaseLive()
    if not zone then return false, "The Resistance has no live headquarters (a flag at the top of its pole)." end
    local routes = LC.SupplyLineRoutes(want)
    if #routes == 0 then
        return false, "This map has no supply route: lay one with the editor (Point: supply line, road or canal) or name info_targets lc_supply_road_1, 2... or lc_supply_canal_1, 2..."
    end
    SL.Register()
    local route = routes[math.random(#routes)]
    local crate, dest = SL.Crate(zone)
    local run = { route = route, kind = route.kind, zone = zone, crate = crate, dest = dest, startT = CurTime(), state = "waiting", postings = {} }
    SL.run = run
    local res = LC.PostDirective and LC.PostDirective("res_supplyescort", run) or {}
    local cp = LC.PostDirective and LC.PostDirective("cp_supplystop", run) or {}
    for _, p in ipairs(res) do run.postings[#run.postings + 1] = p end
    for _, p in ipairs(cp) do run.postings[#run.postings + 1] = p end
    if #res > 0 and LC.ProtectWait then
        LC.ProtectWait({ "res_supplyescort" }, res, function() SL.SetOff(run) end, run.kind == "canal" and "The boat" or "The courier")
    else
        SL.SetOff(run)
    end
    if LC.Log then LC.Log("info", "Supply run set out by " .. route.label) end
    hook.Run("LivingCitySupplyLine", run)
    return true, run
end

-- Called off now (the robot players putting the city back): nothing comes in, the courier goes away.
function SL.CallOff()
    local run = SL.run
    if run then Stop(run, "off") end
end

------------------------------------------------------------------------
-- Every tick
------------------------------------------------------------------------

local function UnitNear(pos, r)
    for _, p in ipairs(player.GetAll()) do
        if Unit(p) and p:Alive() and p:GetPos():DistToSqr(pos) < r * r then return p end
    end
    return nil
end

-- Has the Combine seen him? A unit's player with a clear line, or one of its own NPCs; or he's half way.
local function Spotted(run)
    local thing = SL.Thing(run)
    if not IsValid(thing) then return false end
    if (run.length or 0) > 0 and (run.travel or 0) >= run.length * 0.5 then return true end
    local at = thing:GetPos() + Vector(0, 0, 40)
    local function clear(from, who)
        local tr = util.TraceLine({ start = from, endpos = at, mask = MASK_OPAQUE, filter = { who, thing, run.rider } })
        return tr.Fraction > 0.97 or tr.Entity == thing
    end
    for _, p in ipairs(player.GetAll()) do
        if Unit(p) and p:Alive() and p:GetPos():DistToSqr(at) < SL.SEEN_UNIT * SL.SEEN_UNIT and clear(p:EyePos(), p) then return true end
    end
    for npc, st in pairs(LC.NPCs or {}) do
        if IsValid(npc) and LC.IsSecurity and LC.IsSecurity(st) and npc:Health() > 0
            and npc:GetPos():DistToSqr(at) < SL.SEEN_NPC * SL.SEEN_NPC and clear(npc:EyePos(), npc) then return true end
    end
    return false
end

local function MoveBoat(run, now)
    local b = run.boat
    if not IsValid(b) then return Stop(run, "sunk") end
    run.boatAt = math.min(run.boatLen, run.boatAt + SL.BOAT_SPEED * math.max(0, now - (run.boatT or now)))
    run.boatT = now
    run.travel = run.boatAt
    local left, pts = run.boatAt, run.water
    for i = 2, #pts do
        local a, c = pts[i - 1], pts[i]
        local len = a:Distance(c)
        if left <= len or i == #pts then
            local f = len > 0 and math.min(1, left / len) or 1
            b:SetPos(a + (c - a) * f)
            local d = c - a
            if d:LengthSqr() > 1 then b:SetAngles(Angle(0, math.deg(math.atan2(d.y, d.x)), 0)) end
            break
        end
        left = left - len
    end
    if run.boatAt >= run.boatLen then
        -- tied up: the boatman takes the box ashore, and walks it in
        local landing = pts[#pts]
        if IsValid(run.rider) then run.rider:Remove() end
        run.rider = nil
        local ground = Ashore(landing)
        run.walkFrom = run.boatLen
        if not Courier(run, ground, LastLeg(ground, run.crate, run.dest)) then return Stop(run, "off") end
        b:EmitSound("physics/wood/wood_box_impact_soft" .. math.random(1, 3) .. ".wav", 70)
    end
end

local function Walk(run, now)
    local npc = run.courier
    local st = IsValid(npc) and LC.NPCs and LC.NPCs[npc]
    if not st or npc:Health() <= 0 then return Stop(run, "killed", run.killer) end
    if (LC.NPCCustody and LC.NPCCustody[npc]) or st.jailUntil or CUSTODY[st.state] then return Stop(run, "caught", run.catcher) end
    local pos = npc:GetPos()
    local goal = run.path[run.i]
    while goal and Vector(pos.x - goal.x, pos.y - goal.y, 0):LengthSqr() < SL.REACH * SL.REACH and math.abs(pos.z - goal.z) < 90 do
        run.i = run.i + 1
        goal = run.path[run.i]
    end
    if not goal then return Arrive(run) end
    -- how far along (for the Combine's marker at half way)
    local done, at = run.walkFrom or 0, run.walkStart or pos
    for k = 1, run.i - 1 do done = done + at:Distance(run.path[k]) at = run.path[k] end
    run.travel = done + math.max(0, at:Distance(goal) - pos:Distance(goal))
    -- breaking free of an arrest: the running away is his own, for now
    if (st.fleeingUntil or 0) > now then return end
    if st.state ~= "event" and LC.SetState then LC.SetState(npc, st, "event") end
    st.eventUntil = now + 60
    local hp = npc:Health()
    if run.lastHp and hp < run.lastHp then run.hurtAt = now end
    run.lastHp = hp
    local hurry = (run.hurtAt and now - run.hurtAt < 12) or UnitNear(pos, 500) ~= nil
    local moving = npc:IsCurrentSchedule(SCHED_FORCED_GO) or npc:IsCurrentSchedule(SCHED_FORCED_GO_RUN)
    if not moving or run.goal ~= goal or run.hurry ~= hurry then
        npc:SetLastPosition(goal)
        npc:SetSchedule(hurry and SCHED_FORCED_GO_RUN or SCHED_FORCED_GO)
        run.goal, run.hurry = goal, hurry
    end
    -- no headway for eight seconds, and nobody looking: on to the point he was making for
    if run.lastPos and pos:DistToSqr(run.lastPos) < 20 * 20 then run.still = (run.still or 0) + 0.5 else run.still = 0 end
    run.lastPos = pos
    if run.still >= 8 and not (LC.IsSeen and LC.IsSeen(pos + Vector(0, 0, 40))) then
        npc:SetPos(goal + Vector(0, 0, 4))
        run.still = 0
    end
end

function SL.Tick(now)
    now = now or CurTime()
    -- the sinking boats go down, and are gone
    for i = #(SL.sinking or {}), 1, -1 do
        local s = SL.sinking[i]
        local f = (now - s.t0) / 4
        if not IsValid(s.ent) or f >= 1 then
            if IsValid(s.ent) then s.ent:Remove() end
            table.remove(SL.sinking, i)
        else
            local p = s.ent:GetPos()
            s.ent:SetPos(Vector(p.x, p.y, s.z0 - 80 * f))
            s.ent:SetAngles(Angle(0, s.ent:GetAngles().y, 25 * f))
        end
    end
    local run = SL.run
    if not run then
        -- the next one, while the headquarters is live
        if not (LC.Running and LC.BaseLive and LC.BaseLive()) then return end
        if not SL.nextAt then SL.nextAt = now + Wait() return end
        if now < SL.nextAt then return end
        SL.nextAt = now + Wait()
        local ok, why = LC.SupplyLineStart()
        if not ok and why ~= SL.lastWhy and LC.Log then LC.Log("info", "No supply run: " .. tostring(why)) end
        SL.lastWhy = not ok and why or nil
        return
    end
    -- no headquarters to bring it to (packed, overrun, torn down), the city stopped, or too long on the way
    if not LC.Running or not (LC.BaseLive and LC.BaseLive() == run.zone) or now - run.startT > SL.MAX_SECS then
        return Stop(run, "off")
    end
    if run.state == "boat" then MoveBoat(run, now) end
    if run.over then return end
    if now < (run.thinkAt or 0) then return end
    run.thinkAt = now + 0.5
    if run.state == "walk" then Walk(run, now) end
    if run.over then return end
    if not run.spotted and now >= (run.spotAt or 0) then
        run.spotAt = now + 1
        if Spotted(run) then run.spotted = true end
    end
end

timer.Create("LivingCitySupplyLines", 0.1, 0, function()
    local ok, err = LC.Try(SL.Tick, CurTime())
    if not ok and LC.Error then LC.Error("supply lines", err) end
    local now = CurTime()
    for i = #leftovers, 1, -1 do
        local l = leftovers[i]
        if not IsValid(l.ent) then
            table.remove(leftovers, i)
        elseif now - l.at > 180 or (now - l.at > 30 and not (LC.IsSeen and LC.IsSeen(l.ent:GetPos() + Vector(0, 0, 30)))) then
            l.ent:Remove()
            table.remove(leftovers, i)
        end
    end
end)

-- Shot: the boat's own count (the prop itself takes no harm: it would break apart), the boatman's too.
hook.Add("EntityTakeDamage", "LivingCitySupplyLines", function(ent, dmg)
    local run = SL.run
    if not run or run.over or not IsValid(ent) then return end
    if ent ~= run.boat and ent ~= run.rider then return end
    local n = dmg.GetDamage and dmg:GetDamage() or 0
    local by = dmg.GetAttacker and dmg:GetAttacker() or nil
    if ent == run.rider then
        run.riderHurt = (run.riderHurt or 0) + n
        if run.riderHurt >= SL.RIDER_HP then Stop(run, "shot", by) end
    else
        run.boatHurt = (run.boatHurt or 0) + n
        if run.boatHurt >= SL.BOAT_HP then Stop(run, "sunk", by) end
    end
    return true
end)

hook.Add("OnNPCKilled", "LivingCitySupplyLines", function(npc, attacker)
    local run = SL.run
    if run and npc == run.courier then run.killer = attacker end
end)
hook.Add("LivingCityIncarcerated", "LivingCitySupplyLines", function(target, secs, reason, arrester)
    local run = SL.run
    if run and target == run.courier then run.catcher = arrester end
end)
hook.Add("LivingCityBaseLive", "LivingCitySupplyLines", function() SL.nextAt = CurTime() + Wait() end)
hook.Add("LivingCityBaseGone", "LivingCitySupplyLines", function(zone)
    SL.nextAt = nil
    local run = SL.run
    if run and run.zone == zone then Stop(run, "off") end
end)
hook.Add("PostCleanupMap", "LivingCitySupplyLines", function() SL.run, SL.sinking, SL.nextAt = nil, nil, nil end)

------------------------------------------------------------------------
-- The jobs
------------------------------------------------------------------------

-- A job about a run that is over: how it went for this side.
local function Over(q, run, side)
    local Q = LC.QB
    if side == "cp" then
        if run.state == "stopped" and run.how ~= "off" then return Q.Finish(q, true) end
        if run.how == "arrived" then return Q.Finish(q, false, "the supplies got through") end
        return Q.Finish(q, false, "the run was called off")
    end
    if run.how == "arrived" then
        for _, p in ipairs(Q.Members(q)) do if run.near and run.near[p] then return Q.Finish(q, true) end end
        return Q.Finish(q, false, "he got there without you")
    end
    local why = ({ killed = "the courier was killed", caught = "the courier was caught", sunk = "the boat was sunk", shot = "the boatman was shot" })[run.how]
    return Q.Finish(q, false, why or "the run was called off")
end

-- The marker follows him (or the boat); with nothing out yet, it shows where he sets out.
local function Mark(q, st, thing, pos)
    if st.item ~= thing or (not thing and st.pos ~= pos) then
        st.item, st.pos = thing, pos
        LC.QB.SendStateAll(q)
    end
end

local function EscortTemplate()
    local Q = LC.QB
    return {
        id = "res_supplyescort", brings = false, factions = { resistance = true }, violent = true, squad = 4,
        available = function() return SL.run ~= nil and not SL.run.over end,
        build = function(ply, run)
            run = (istable(run) and run.route) and run or SL.run
            if not run or run.over then return nil end
            local canal = run.kind == "canal"
            local get = Q.Count("supply_escort", 1, canal and "Get to the boat (marked)" or "Get to the courier (marked)")
            get.untallied, get.pos = true, run.route.pts[1]
            get.poll = function(q, st)
                if run.over then return Over(q, run, "resistance") end
                local thing = SL.Thing(run)
                Mark(q, st, thing, run.route.pts[1])
                if not IsValid(thing) then return end
                local r = thing == run.boat and 700 or 450
                for _, p in ipairs(Q.Members(q)) do
                    if p:Alive() and p:GetPos():DistToSqr(thing:GetPos()) < r * r then return Q.Advance(q) end
                end
            end
            local see = Q.Count("supply_escort", 1, canal and "See the boatman to the headquarters" or "See the courier to the headquarters")
            see.untallied = true
            see.poll = function(q, st)
                if run.over then return Over(q, run, "resistance") end
                Mark(q, st, SL.Thing(run), run.dest)
            end
            return {
                title = canal and "Meet the boat" or "Escort the courier", reward = 45, limit = SL.MAX_SECS + 120, failOnArrest = true,
                desc = canal and "A boat is coming up the canal with food and rounds for the headquarters. Meet it and see the boatman in."
                    or "A courier is on the road with food and rounds for the headquarters. Meet him and see him in.",
                stages = { get, see }, data = { run = run },
            }
        end,
    }
end

local function StopTemplate()
    local Q = LC.QB
    return {
        id = "cp_supplystop", factions = { cp = true, ota = true }, violent = true, squad = 6,
        available = function() return SL.run ~= nil and not SL.run.over end,
        -- (killing him pays what an anticitizen neutralized always does: what the job board shows, LC.PostingPay)
        extraCredits = function() return { 0, LCF and LCF.XP and LCF.XP.rebel_kill_credits or 0 } end,
        build = function(ply, run)
            run = (istable(run) and run.route) and run or SL.run
            if not run or run.over then return nil end
            local canal = run.kind == "canal"
            local hunt = canal and "Find the boat on the canal and stop it: sink it, or shoot the boatman" or "Find the courier and stop him: kill or arrest him"
            local seen = canal and "Stop the boat (marked): sink it, or shoot the boatman" or "Stop the courier (marked): kill or arrest him"
            local stop = Q.Count("supply_stop", 1, hunt)
            stop.untallied = true
            stop.poll = function(q, st)
                if run.over then return Over(q, run, "cp") end
                local thing = run.spotted and SL.Thing(run) or nil
                local text = (thing and thing == run.courier and canal) and "Stop the boatman (marked): kill or arrest him" or (thing and seen or hunt)
                if st.item ~= thing or st.text ~= text then
                    st.item, st.text = thing, text
                    Q.SendStateAll(q)
                end
            end
            return {
                title = "Stop the courier", reward = 45, limit = SL.MAX_SECS + 120,
                desc = canal and "A Resistance boat is coming up the canal with food and rounds for their headquarters. Stop it before it gets there."
                    or "A Resistance courier is carrying food and rounds to their headquarters. Stop him before he gets there.",
                stages = { stop }, data = { run = run },
            }
        end,
    }
end

-- The jobs go on the boards' list once the quests are loaded (this file comes before them).
function SL.Register()
    if not (LC.QB and LC.QuestTemplates) then return false end
    for _, t in ipairs(LC.QuestTemplates) do if t.id == "res_supplyescort" then return true end end
    LC.QuestTemplates[#LC.QuestTemplates + 1] = EscortTemplate()
    LC.QuestTemplates[#LC.QuestTemplates + 1] = StopTemplate()
    return true
end
hook.Add("Initialize", "LivingCitySupplyLines", function() LC.Try(SL.Register) end)
hook.Add("InitPostEntity", "LivingCitySupplyLines", function() LC.Try(SL.Register) end)
