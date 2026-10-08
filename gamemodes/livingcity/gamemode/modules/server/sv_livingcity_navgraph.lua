--[[
    Living City: routes over the map's own nodegraph

    The engine walks NPCs well over a short distance and badly over a long
    one, especially across floors on multi-level maps: it gives up, or walks
    into a wall and stays there. So when the map's nodegraph has links (read
    in sv_livingcity.lua into LC.NavGraph), a route is planned here, node to
    node, and handed out as a list of short legs, a few hundred units each.

    It also knows what's connected. A destination whose nearest node is in a
    different connected area from the walker (a sealed room, a rooftop, the
    far side of a locked gate) can't be reached, so the trip isn't started.

    Editor path nodes (sv_livingcity_paths.lua) still come first: they're
    what an admin drew because the map's own navigation wasn't good enough.
]]

if CLIENT then return end

LC = LC or {}

local CELL = 512
local LEG = 400       -- roughly how far apart the legs of a route are
local STEP_Z = 48     -- a change of level worth its own leg (stairs, ramps)
local SNAP = 320      -- a destination farther than this from every node: we can't judge it

local grid = {}       -- [key] = { node, ... }

local function Key(x, y) return math.floor(x / CELL) .. ":" .. math.floor(y / CELL) end

function LC.NavGraphReady()
    grid = {}
    local g = LC.NavGraph
    if not g then return end
    for i, nd in ipairs(g.nodes) do
        nd.idx = i
        local k = Key(nd.pos.x, nd.pos.y)
        grid[k] = grid[k] or {}
        table.insert(grid[k], nd)
    end
    LC.NavStats = { routes = 0, unreachable = 0, direct = 0, refined = 0, avoided = 0, replanned = 0 }
    LC.BadLinks = {}
end

------------------------------------------------------------------------
-- Links that don't work in practice
--
-- The nodegraph says two nodes are linked, but the engine still can't walk
-- it: a locked door, a gate, a prop dropped in a corridor, a crowd. When a
-- walker fails on a link it's remembered for a while: once, it costs a long
-- detour's worth; twice, nobody is routed along it until it's forgotten.
------------------------------------------------------------------------

local BAD_TIME = 900
local BAD_COST = 2500
LC.BadLinks = LC.BadLinks or {}

local function BadRec(a, b)
    local t = LC.BadLinks[a]
    return t and t[b]
end

-- 0 for a fine link; otherwise extra cost, or false when it's off limits.
local function Penalty(a, b)
    local r = BadRec(a, b)
    if not r or r.untilT < CurTime() then return 0 end
    if r.n >= 2 then return false end
    return BAD_COST * r.n
end

local function MarkBad(a, b)
    if not a or not b or a == b then return end
    local now = CurTime()
    for _, pair in ipairs({ { a, b }, { b, a } }) do
        local t = LC.BadLinks[pair[1]] or {}
        LC.BadLinks[pair[1]] = t
        local r = t[pair[2]]
        if not r or r.untilT < now then r = { n = 0 } end
        r.n, r.untilT = r.n + 1, now + BAD_TIME
        t[pair[2]] = r
    end
end

function LC.BadLinkCount()
    local n, now = 0, CurTime()
    for _, t in pairs(LC.BadLinks or {}) do
        for _, r in pairs(t) do if r.untilT > now then n = n + 1 end end
    end
    return math.floor(n / 2)
end

-- The nearest node someone at pos could walk straight to (nil if none close).
local function Snap(pos)
    local cx, cy = math.floor(pos.x / CELL), math.floor(pos.y / CELL)
    local cands = {}
    for dx = -1, 1 do
        for dy = -1, 1 do
            for _, nd in ipairs(grid[(cx + dx) .. ":" .. (cy + dy)] or {}) do
                local d = nd.pos:DistToSqr(pos)
                -- on another floor is not "near", however close it is in a straight line
                if d < SNAP * SNAP and math.abs(nd.pos.z - pos.z) < 100 then cands[#cands + 1] = { nd, d } end
            end
        end
    end
    if #cands == 0 then return nil end
    table.sort(cands, function(a, b) return a[2] < b[2] end)
    for i = 1, math.min(5, #cands) do
        if not LC.Walkable or LC.Walkable(pos, cands[i][1].pos) then return cands[i][1] end
    end
    return cands[1][2] < 120 * 120 and cands[1][1] or nil
end
LC.NavSnap = Snap

------------------------------------------------------------------------
-- Traffic
--
-- Left to plain shortest paths, a busy city sends everyone down the same
-- strip of pavement and they jam it while the next street over is empty.
-- So a route costs more where other people are already headed (every node
-- still ahead on someone's route) and where people are standing about, and
-- each walker weighs the streets a little differently from the next.
------------------------------------------------------------------------

local TRAFFIC_COST = 70    -- per other walker planning to pass a node
local STANDING_COST = 160  -- per person standing at a node
local VARIETY = 0.35       -- each route sees each link up to this much longer
local SIDESTEP = 44        -- waypoints sit up to this far either side of the node

LC.NavTraffic, LC.NavStanding = LC.NavTraffic or {}, LC.NavStanding or {}

local function NearestNodeQuick(pos, r)
    local best, bd
    for _, nd in ipairs(grid[Key(pos.x, pos.y)] or {}) do
        local d = nd.pos:DistToSqr(pos)
        if d < r * r and math.abs(nd.pos.z - pos.z) < 80 and (not bd or d < bd) then best, bd = nd, d end
    end
    return best
end

function LC.RefreshNavTraffic()
    local traffic, standing = {}, {}
    if LC.NavGraph then
        for npc, st in pairs(LC.NPCs or {}) do
            if IsValid(npc) then
                local legs = st.route and st.route.legs
                if st.state == "moving" and legs then
                    for i = st.hop or 1, #st.route do
                        for _, nd in ipairs(legs[i] or {}) do traffic[nd] = (traffic[nd] or 0) + 1 end
                    end
                elseif st.state ~= "moving" then
                    local nd = NearestNodeQuick(npc:GetPos(), 70)
                    if nd then standing[nd] = (standing[nd] or 0) + 1 end
                end
            end
        end
    end
    LC.NavTraffic, LC.NavStanding = traffic, standing
end
timer.Create("LivingCityNavTraffic", 2, 0, function()
    local ok, err = pcall(LC.RefreshNavTraffic)
    if not ok then LC.Error("nav traffic", err) end
end)

-- The same link always looks the same length to one route (so the search
-- stays sane), but different routes see it a little differently.
local function Variety(a, b, seed)
    if not seed then return 1 end
    local ia, ib = a.idx or 0, b.idx or 0
    if ia > ib then ia, ib = ib, ia end
    local h = (ia * 73856093 + ib * 19349663 + seed * 83492791) % 1000
    return 1 + VARIETY * h / 1000
end

-- A* with a binary heap: a couple of thousand nodes is nothing.
-- secure: a unit (cop or soldier), who may go through Civil Protection doors
local function Path(s, e, seed, secure)
    local heap, n = {}, 0
    local function push(nd, f)
        n = n + 1
        heap[n] = { nd, f }
        local i = n
        while i > 1 do
            local p = math.floor(i / 2)
            if heap[p][2] <= heap[i][2] then break end
            heap[p], heap[i] = heap[i], heap[p]
            i = p
        end
    end
    local function pop()
        local top = heap[1]
        heap[1] = heap[n]
        heap[n] = nil
        n = n - 1
        local i = 1
        while true do
            local l, r, m = i * 2, i * 2 + 1, i
            if l <= n and heap[l][2] < heap[m][2] then m = l end
            if r <= n and heap[r][2] < heap[m][2] then m = r end
            if m == i then break end
            heap[m], heap[i] = heap[i], heap[m]
            i = m
        end
        return top[1]
    end
    local g, came, closed = { [s] = 0 }, {}, {}
    push(s, s.pos:Distance(e.pos))
    while n > 0 do
        local cur = pop()
        if cur == e then
            local out = { cur }
            while came[cur] do cur = came[cur]; table.insert(out, 1, cur) end
            return out
        end
        if not closed[cur] then
            closed[cur] = true
            for _, edge in ipairs(cur.adj) do
                local nb = edge[1]
                local extra = Penalty(cur, nb)
                if edge.units and not secure then extra = false end -- (a Civil Protection door: units only)
                if not closed[nb] and extra then
                    if seed then
                        extra = extra + TRAFFIC_COST * (LC.NavTraffic[nb] or 0) + STANDING_COST * (LC.NavStanding[nb] or 0)
                    end
                    local t = g[cur] + edge[2] * Variety(cur, nb, seed) + extra
                    if not g[nb] or t < g[nb] then
                        g[nb], came[nb] = t, cur
                        push(nb, t + nb.pos:Distance(e.pos))
                    end
                end
            end
        end
    end
    return nil
end
LC._NavPath = Path -- for testing

-- false: can't be reached from here. nil: no opinion (no graph, or too far
-- from any node to tell). Otherwise a list of positions ending at `to`.
function LC.NavRoute(from, to, role)
    if not LC.NavGraph then return nil end
    local stats = LC.NavStats
    local s, e = Snap(from), Snap(to)
    if not s or not e then return nil end
    if s.comp ~= e.comp then
        stats.unreachable = stats.unreachable + 1
        return false
    end
    if s == e or from:DistToSqr(to) < 300 * 300 then
        stats.direct = stats.direct + 1
        return nil
    end
    local path = Path(s, e, math.random(1, 100000), role == "cop" or role == "soldier")
    if not path then
        stats.unreachable = stats.unreachable + 1
        return false
    end
    -- short legs: a waypoint every LEG units, and at every change of level.
    -- Each leg remembers the nodes it passes, so a leg the engine can't walk
    -- in one go can be broken into single steps, and a bad link found.
    local out, last, run = {}, from, 0
    local legs, legStart = {}, 1
    for i, nd in ipairs(path) do
        local prev = path[i - 1] and path[i - 1].pos or from
        run = run + prev:Distance(nd.pos)
        local nextNd = path[i + 1]
        local levelChange = nextNd and math.abs(nextNd.pos.z - nd.pos.z) > STEP_Z or math.abs(nd.pos.z - last.z) > STEP_Z
        if i == #path or run >= LEG or levelChange then
            if nd.pos:DistToSqr(from) > 120 * 120 then
                -- not everyone aims for the exact same spot: a little to one side,
                -- if there's room there
                local wp = nd.pos
                if i < #path and not nd.ladder then
                    local dir = (path[i + 1].pos - prev)
                    dir.z = 0
                    if dir:LengthSqr() > 1 then
                        dir = dir:GetNormalized()
                        local side = Vector(-dir.y, dir.x, 0) * (math.Rand(-1, 1) * SIDESTEP)
                        local cand = nd.pos + side
                        if not LC.Walkable or LC.Walkable(nd.pos, cand) then wp = cand end
                    end
                end
                out[#out + 1] = wp
                local seg = {}
                for j = legStart, i do seg[#seg + 1] = path[j] end
                legs[#out] = seg
                legStart = i
            end
            last, run = nd.pos, 0
        end
    end
    out[#out + 1] = to
    legs[#out] = { path[#path] }
    out.legs = legs
    stats.routes = stats.routes + 1
    return out
end

-- How far it is to walk from `from` to `to` over the nodegraph: stairs,
-- ramps and ladders included. nil when we can't tell (no graph, or no node
-- near one end), false when it can't be walked at all.
function LC.NavWalkDistance(from, to)
    if not LC.NavGraph then return nil end
    local s, e = Snap(from), Snap(to)
    if not s or not e then return nil end
    if s.comp ~= e.comp then return false end
    local path = Path(s, e, nil)
    if not path then return false end
    local d, last = from:Distance(path[1].pos), path[1].pos
    for i = 2, #path do d = d + last:Distance(path[i].pos) last = path[i].pos end
    return d + last:Distance(to)
end

-- The nodes within r of pos, on any floor (where an NPC can stand).
function LC.NavNodesNear(pos, r)
    local out = {}
    local cr = math.ceil(r / CELL)
    local cx, cy = math.floor(pos.x / CELL), math.floor(pos.y / CELL)
    for dx = -cr, cr do
        for dy = -cr, cr do
            for _, nd in ipairs(grid[(cx + dx) .. ":" .. (cy + dy)] or {}) do
                if nd.pos:DistToSqr(pos) < r * r then out[#out + 1] = nd end
            end
        end
    end
    return out
end

-- Can someone standing at `from` get to `to` on foot? (true when we can't tell.)
function LC.NavReachable(from, to)
    if not LC.NavGraph then return true end
    local s, e = Snap(from), Snap(to)
    if not s or not e then return true end
    return s.comp == e.comp
end

------------------------------------------------------------------------
-- When the engine can't walk a leg
------------------------------------------------------------------------

-- Break the current leg into node-to-node steps. True if there was anything
-- to break up.
function LC.NavRefineLeg(st)
    local route = st.route
    local legs = route and route.legs
    local seg = legs and legs[st.hop]
    if not seg or #seg < 3 then return false end
    local steps = {}
    for j = 2, #seg do steps[#steps + 1] = { pos = seg[j].pos, nodes = { seg[j - 1], seg[j] } } end
    -- shift what comes after, then put the steps in place of the leg
    local newRoute, newLegs = {}, {}
    for i = 1, st.hop - 1 do newRoute[i], newLegs[i] = route[i], legs[i] end
    for _, s in ipairs(steps) do
        newRoute[#newRoute + 1] = s.pos
        newLegs[#newRoute] = s.nodes
    end
    for i = st.hop + 1, #route do
        newRoute[#newRoute + 1] = route[i]
        newLegs[#newRoute] = legs[i]
    end
    newRoute.legs = newLegs
    st.route = newRoute
    if LC.NavStats then LC.NavStats.refined = LC.NavStats.refined + 1 end
    return true
end

-- Remember the link that just failed (the last step of the current leg).
-- True if there was a link to blame.
function LC.NavBlameLeg(st)
    local legs = st.route and st.route.legs
    local seg = legs and legs[st.hop]
    if not seg or #seg < 2 then return false end
    MarkBad(seg[#seg - 1], seg[#seg])
    if LC.NavStats then LC.NavStats.avoided = LC.NavStats.avoided + 1 end
    return true
end

------------------------------------------------------------------------
-- Ladders
--
-- NPCs can't climb. A ladder (the editor's "Path: ladder end" points, two
-- with the same number for its bottom and top; or a usable ladder the map
-- already has) joins the two ends in the route graph, and anyone who reaches
-- one end on their way to the other is simply put there: a step up and
-- they're at the top. It looks no worse than an NPC gliding up a ladder and
-- getting stuck halfway.
------------------------------------------------------------------------

LC.Ladders = LC.Ladders or {} -- { { a = pos, b = pos }, ... }

local function MapLadders()
    local out = {}
    for _, e in ipairs(ents.FindByClass("func_useableladder")) do
        local ok, top, bottom = pcall(function()
            return e:GetInternalVariable("m_vecPlayerMountPositionTop"), e:GetInternalVariable("m_vecPlayerMountPositionBottom")
        end)
        if ok and isvector and isvector(top) and isvector(bottom) and top:DistToSqr(bottom) > 64 * 64 then
            out[#out + 1] = { a = bottom, b = top, map = true }
        end
    end
    return out
end

local function EditorLadders()
    local byGroup, out = {}, {}
    for _, p in ipairs(LC.Points or {}) do
        if p.kind == "ladder" then
            local g = p.group or 0
            byGroup[g] = byGroup[g] or {}
            table.insert(byGroup[g], p.pos)
        end
    end
    for _, ends in pairs(byGroup) do
        if #ends >= 2 then
            table.sort(ends, function(x, y) return x.z < y.z end)
            out[#out + 1] = { a = ends[1], b = ends[#ends] }
        end
    end
    return out
end

local function Recompute()
    local g = LC.NavGraph
    if not g then return end
    for _, nd in ipairs(g.nodes) do nd.comp = nil end
    local comps, sizes = 0, {}
    for _, nd in ipairs(g.nodes) do
        if not nd.comp then
            comps = comps + 1
            nd.comp = comps
            local stack, size = { nd }, 0
            while #stack > 0 do
                local cur = table.remove(stack)
                size = size + 1
                for _, e in ipairs(cur.adj) do
                    if not e[1].comp then e[1].comp = comps; stack[#stack + 1] = e[1] end
                end
            end
            sizes[comps] = size
        end
    end
    local best, bestN = nil, 0
    for c, size in pairs(sizes) do if size > bestN then best, bestN = c, size end end
    g.main = best or g.main
end

-- Put the ladders into the route graph (and take out the ones that are gone).
function LC.ApplyLadders()
    local list = {}
    for _, l in ipairs(EditorLadders()) do list[#list + 1] = l end
    for _, l in ipairs(MapLadders()) do list[#list + 1] = l end
    LC.Ladders = list
    local g = LC.NavGraph
    if not g then return #list end
    -- drop the old ladder nodes, and the old links through doors
    local keep = {}
    for _, nd in ipairs(g.nodes) do
        if not nd.ladder then
            local adj = {}
            for _, e in ipairs(nd.adj) do if not e[1].ladder and not e.bridge then adj[#adj + 1] = e end end
            nd.adj = adj
            keep[#keep + 1] = nd
        end
    end
    g.nodes = keep
    for k, cell in pairs(grid) do
        local c = {}
        for _, nd in ipairs(cell) do if not nd.ladder then c[#c + 1] = nd end end
        grid[k] = c
    end
    local function AddEnd(pos)
        local nd = { pos = pos, adj = {}, ladder = true, idx = #g.nodes + 1 }
        local near = Snap(pos)
        g.nodes[#g.nodes + 1] = nd
        if near then
            local d = near.pos:Distance(pos)
            nd.adj[#nd.adj + 1] = { near, d }
            near.adj[#near.adj + 1] = { nd, d }
        end
        local k = Key(pos.x, pos.y)
        grid[k] = grid[k] or {}
        table.insert(grid[k], nd)
        return nd
    end
    for _, l in ipairs(list) do
        local na, nb = AddEnd(l.a), AddEnd(l.b)
        local cost = 120 -- a climb costs about as much as a short walk
        na.adj[#na.adj + 1] = { nb, cost }
        nb.adj[#nb.adj + 1] = { na, cost }
        l.na, l.nb = na, nb
    end
    LC.DoorBridges = LC.BridgeDoors and LC.BridgeDoors(g) or 0
    Recompute()
    return #list
end

------------------------------------------------------------------------
-- Through doors
--
-- The map's nodegraph was built with its doors shut, so a Combine door often
-- splits the city in two: the nexus and the rooms behind it in an area of
-- their own that nobody can be routed into. A door you've tagged (or one
-- that's Combine-only or a prison door by where it is) joins the nodes on
-- either side of it. A Civil Protection or prison door is for units only:
-- only cops and soldiers are routed through it (they open it as they get
-- there: sv_livingcity_doors.lua).
------------------------------------------------------------------------

local BRIDGE_TAGS = { cp = "units", prison = "units", open = "all", force = "all", rent = "all" }

function LC.BridgeDoors(g)
    if not g or not LC.EffectiveDoorTag then return 0 end
    local n = 0
    for _, cls in ipairs({ "func_door", "func_door_rotating", "prop_door_rotating", "func_movelinear" }) do
        for _, door in ipairs(ents.FindByClass(cls)) do
            local who = BRIDGE_TAGS[LC.EffectiveDoorTag(door) or ""]
            if who then
                local mins, maxs = door:OBBMins(), door:OBBMaxs()
                local size = maxs - mins
                -- the way through: across the door's thin side
                local local_n = size.x <= size.y and Vector(1, 0, 0) or Vector(0, 1, 0)
                local across = door:LocalToWorld(local_n) - door:LocalToWorld(Vector(0, 0, 0))
                across.z = 0
                if across:LengthSqr() > 0.01 then
                    across = across:GetNormalized()
                    local c = door:WorldSpaceCenter()
                    local foot = Vector(c.x, c.y, c.z - size.z * 0.5)
                    local reach = math.max(220, math.max(size.x, size.y) * 0.75 + 120)
                    local best = {}
                    for _, nd in ipairs(LC.NavNodesNear(foot, reach)) do
                        if not nd.ladder and math.abs(nd.pos.z - foot.z) < 80 then
                            local side = (nd.pos - c):Dot(across) > 0 and 1 or 2
                            local d = nd.pos:DistToSqr(foot)
                            if not best[side] or d < best[side][2] then best[side] = { nd, d } end
                        end
                    end
                    local a, b = best[1] and best[1][1], best[2] and best[2][1]
                    if a and b and a ~= b and (not LC.Walkable or LC.Walkable(a.pos, b.pos)) then
                        local linked = false
                        for _, e in ipairs(a.adj) do if e[1] == b then linked = true break end end
                        if not linked then
                            local d = a.pos:Distance(b.pos)
                            local units = who == "units" or nil
                            a.adj[#a.adj + 1] = { b, d, bridge = true, units = units, door = door }
                            b.adj[#b.adj + 1] = { a, d, bridge = true, units = units, door = door }
                            n = n + 1
                        end
                    end
                end
            end
        end
    end
    return n
end

-- The ladder that takes someone at pos toward goal (on another level): the
-- end to walk to, and the end they come out at. nil if there's none near.
-- climbing: goal is someone who's on a ladder right now, partway up it. The
-- far end isn't any nearer to them than the foot is (they're in the middle),
-- so what counts is that it goes their way and they're by it.
function LC.LadderToward(pos, goal, climbing)
    local best, bestNear, bestFar
    for _, l in ipairs(LC.Ladders) do
        for _, pair in ipairs({ { l.a, l.b }, { l.b, l.a } }) do
            local here, there = pair[1], pair[2]
            if math.abs(pos.z - here.z) < 72 then
                local goesTheirWay
                if climbing then
                    local dz, span = goal.z - here.z, there.z - here.z
                    goesTheirWay = dz * span > 0 and math.abs(dz) > 48
                        and Vector(goal.x - here.x, goal.y - here.y, 0):Length() < 240
                else
                    goesTheirWay = math.abs(goal.z - there.z) + 48 < math.abs(goal.z - here.z)
                end
                if goesTheirWay then
                    local d1, d2 = pos:Distance(here), there:Distance(goal)
                    if d1 < 1200 and d2 < 1500 and (not best or d1 + d2 < best) then
                        best, bestNear, bestFar = d1 + d2, here, there
                    end
                end
            end
        end
    end
    return bestNear, bestFar
end

------------------------------------------------------------------------
-- Ladders learned from the people who climb them
--
-- Most maps' ladders aren't entities at all (just a ladder texture on a
-- wall), so there's nothing to read. But when a player climbs one, the game
-- has just shown where its foot and its top are: where they stood before
-- they got on, and where they stood when they got off. That pair is saved
-- as a ladder (the editor's ladder points, so you can see and remove it),
-- and NPCs use it from then on: walk to one end, and they're at the other.
--   lc_learn_ladders 0/1
------------------------------------------------------------------------

local cvLearn = CreateConVar("lc_learn_ladders", "1", bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED),
    "Ladders players climb are remembered (as editor ladder points) so NPCs can use them too")

function LC.LearnLadder(a, b)
    if not a or not b then return false end
    local bottom, top = a, b
    if bottom.z > top.z then bottom, top = top, bottom end
    if top.z - bottom.z < 64 or Vector(top.x - bottom.x, top.y - bottom.y, 0):Length() > 300 then return false end
    for _, l in ipairs(LC.Ladders or {}) do
        local lb, lt = l.a, l.b
        if lb.z > lt.z then lb, lt = lt, lb end
        if lb:DistToSqr(bottom) < 96 * 96 and lt:DistToSqr(top) < 96 * 96 then return false end -- (known already)
    end
    local g = 0
    for _, p in ipairs(LC.Points or {}) do if p.kind == "ladder" then g = math.max(g, p.group or 0) end end
    g = g + 1
    LC.AddPoint(bottom, 0, "ladder", g)
    LC.AddPoint(top, 0, "ladder", g)
    if LC.Log then LC.Log("info", string.format("Learned a ladder (#%d) from a climb: %s up to %s", g, tostring(bottom), tostring(top))) end
    if LC.ApplyLadders then LC.ApplyLadders() end
    return true
end

local climbs = {} -- [ply] = { ground = last spot on the ground, mount = where they got on, offAt }
function LC.LadderLearnTick(now)
    if not cvLearn:GetBool() then return end
    local LADDER = MOVETYPE_LADDER or 9
    for _, p in ipairs(player.GetAll()) do
        local c = climbs[p]
        if not c then c = {} climbs[p] = c end
        local mt = p:GetMoveType()
        if mt == LADDER then
            c.mount = c.mount or c.ground
            c.offAt = nil
        else
            if c.mount then
                if mt == MOVETYPE_NOCLIP or not p:Alive() then
                    c.mount = nil
                elseif p:IsOnGround() then
                    LC.LearnLadder(c.mount, p:GetPos())
                    c.mount = nil
                else
                    c.offAt = c.offAt or now
                    if now - c.offAt > 1.5 then c.mount = nil end -- (fell or jumped off)
                end
            end
            if mt == MOVETYPE_WALK and p:IsOnGround() then c.ground = p:GetPos() end
        end
    end
end
timer.Create("LivingCityLadderLearn", 0.1, 0, function()
    local ok, err = pcall(LC.LadderLearnTick, CurTime())
    if not ok and LC.Error then LC.Error("ladder learning", err) end
end)
hook.Add("PlayerDisconnected", "LivingCityLadderLearn", function(p) climbs[p] = nil end)

-- Standing at one end of a ladder on the way to the other: up (or down) you go.
function LC.LadderHop(npc, goal)
    if not IsValid(npc) or not goal or #LC.Ladders == 0 then return false end
    local pos = npc:GetPos()
    for _, l in ipairs(LC.Ladders) do
        for _, pair in ipairs({ { l.a, l.b }, { l.b, l.a } }) do
            local here, there = pair[1], pair[2]
            local dx, dy = pos.x - here.x, pos.y - here.y
            if dx * dx + dy * dy < 90 * 90 and math.abs(pos.z - here.z) < 72
                and math.abs(goal.z - there.z) + 48 < math.abs(goal.z - here.z) then
                npc:SetPos(there + Vector(0, 0, 6))
                if npc.SetSchedule then npc:SetSchedule(SCHED_IDLE_STAND) end
                npc:EmitSound("player/footsteps/ladder" .. math.random(1, 4) .. ".wav", 70)
                if LC.NavStats then LC.NavStats.ladders = (LC.NavStats.ladders or 0) + 1 end
                return true
            end
        end
    end
    return false
end

-- NPCs that walk without a planned route (rebels heading somewhere, anyone
-- chasing) get the same help.
timer.Create("LivingCityLadders", 0.5, 0, function()
    if #LC.Ladders == 0 then return end
    for npc, st in pairs(LC.NPCs or {}) do
        if IsValid(npc) and st.state ~= "moving" then
            local goal = st.goingTo
            if not goal and npc.GetEnemy and IsValid(npc:GetEnemy()) then goal = npc:GetEnemy():GetPos() end
            if goal then LC.LadderHop(npc, goal) end
        end
    end
end)

hook.Add("LivingCityLayoutChanged", "LivingCityLadders", function()
    timer.Simple(0, function() local ok, err = pcall(LC.ApplyLadders) if not ok and LC.Error then LC.Error("ladders", err) end end)
end)
hook.Add("InitPostEntity", "LivingCityLadders", function()
    timer.Simple(5, function() pcall(LC.ApplyLadders) end)
end)
