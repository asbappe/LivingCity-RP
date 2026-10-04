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
    for _, nd in ipairs(g.nodes) do
        local k = Key(nd.pos.x, nd.pos.y)
        grid[k] = grid[k] or {}
        table.insert(grid[k], nd)
    end
    LC.NavStats = { routes = 0, unreachable = 0, direct = 0 }
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

-- A* with a binary heap: a couple of thousand nodes is nothing.
local function Path(s, e)
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
                if not closed[nb] then
                    local t = g[cur] + edge[2]
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
    local path = Path(s, e)
    if not path then
        stats.unreachable = stats.unreachable + 1
        return false
    end
    -- short legs: a waypoint every LEG units, and at every change of level
    local out, last, run = {}, from, 0
    for i, nd in ipairs(path) do
        local prev = path[i - 1] and path[i - 1].pos or from
        run = run + prev:Distance(nd.pos)
        local nextNd = path[i + 1]
        local levelChange = nextNd and math.abs(nextNd.pos.z - nd.pos.z) > STEP_Z or math.abs(nd.pos.z - last.z) > STEP_Z
        if i == #path or run >= LEG or levelChange then
            if nd.pos:DistToSqr(from) > 120 * 120 then out[#out + 1] = nd.pos end
            last, run = nd.pos, 0
        end
    end
    out[#out + 1] = to
    stats.routes = stats.routes + 1
    return out
end

-- Can someone standing at `from` get to `to` on foot? (true when we can't tell.)
function LC.NavReachable(from, to)
    if not LC.NavGraph then return true end
    local s, e = Snap(from), Snap(to)
    if not s or not e then return true end
    return s.comp == e.comp
end
