--[[
    Living City: territory grows along the path nodes

    Rebel ground and the infestation spread along the path nodes you lay in the
    editor, the way people walk, so you can see where it will go next and steer it.
    Each growth takes a few of the links out of the territory at random
    (lc_territory_links, 3: two or three of them), from a node already inside it
    (or just outside the edge of a zone you placed) to the next node out, and the
    ground along each link becomes territory: lc_territory_width (160) units wide,
    eight feet (96 units) tall, on the floor between the two nodes.

    In the open it spreads wide, not just down one line: gaps the new ground closes
    in (a courtyard ringed by it, a square between links) are filled in, and so is
    the ground between a node and its neighbours once they're all taken.

    However much it grows, one territory's grown ground is one zone: square cells
    (128 units) on a grid, one floor deep, looked up by cell, so asking "is this
    spot rebel ground" costs the same at 10 cells as at 1000. It's saved and sent as
    the few rectangles the cells merge into. lc_territory_cells (600) is the most
    one territory can hold.

    It never goes through a floor or a ceiling: a link whose ends are further apart
    in height than a stair or a ramp would be (more than 160 units, or steeper than
    about 37 degrees) is never taken. Nor is one that runs into a housing block,
    the prison, a Combine area, a no-go zone, a checkpoint, a ration line, a cell, a
    spawn doorway, a dispenser or a terminal, or into the other side's territory.

    Pushed back, it goes back the way it came: the cells furthest from the zone you
    placed (walking through the territory) go first, about one growth's worth at a
    time. A territory with no path nodes in it or near it grows the old way
    (sv_livingcity_territory.lua: a round patch out from its edge, on open floor).

      lc_territory_width <units>   how wide the ground along a link is (160)
      lc_territory_links <n>       most links one growth takes (3; it takes this many or one fewer)
      lc_territory_cells <n>       most cells (128 x 128 units) one territory's grown ground holds (600)
]]

if CLIENT then return end

LC = LC or {}

local FLAGS = bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED)
local cvWidth = CreateConVar("lc_territory_width", "160", FLAGS,
    "How wide (units) the ground along a path node link is where territory grows (it is always eight feet, 96 units, tall)")
local cvLinks = CreateConVar("lc_territory_links", "3", FLAGS,
    "Most path node links one growth of territory takes (it takes this many or one fewer, at random)")
local cvCells = CreateConVar("lc_territory_cells", "600", FLAGS,
    "Most cells (128 x 128 units each) one territory's grown ground can hold")

local HEIGHT = 96        -- eight feet
local MAX_RISE = 160     -- most height between a link's two ends (a flight of stairs)
local MAX_SLOPE = 0.75   -- rise over run: about 37 degrees, as steep as stairs get
local ANCHOR = 160       -- a node this close outside a placed zone's edge is where growth starts
local LEVEL = 96         -- and on the zone's own floor, within this much of it
local HOLE_MAX = 16      -- a gap of up to this many cells closed in on every side is filled (not a whole city block)
local CELL, BAND = LCZ.CELL, LCZ.BAND
local Key, floor = LCZ.CellKey, math.floor
LC.TERRITORY_GROUND_H = HEIGHT

-- what territory mustn't grow into (the same as the round patches keep clear of)
local KEEP_CLEAR = { block = 150, prison = 300, combine = 300, nogo = 50 }
local KEEP_NAME = { block = "a housing block", prison = "the prison", combine = "a Combine area", nogo = "a no-go zone" }
local POINT_CLEAR = { checkpoint = 500, queue = 500, cell = 600, release = 500, spawn = 350, dispenser = 400, terminal = 400 }

function LC.TerritoryWidth() return math.Clamp(cvWidth:GetFloat(), 48, 600) end
local function Cap() return math.max(10, cvCells:GetInt()) end

local function Flat(a, b) local dx, dy = b.x - a.x, b.y - a.y return math.sqrt(dx * dx + dy * dy) end

-- Could you walk this link on one floor, or up a stair or a ramp? (Not a link
-- drawn straight up a stairwell to the floor above: that would go through the ceiling.)
function LC.TerritoryLinkFits(a, b)
    local run, rise = Flat(a, b), math.abs(b.z - a.z)
    return run >= 16 and rise <= MAX_RISE and rise <= math.max(24, run * MAX_SLOPE)
end

-- Is pos (on a floor) inside zone z or within m of it, on z's own level?
local function Near(z, pos, m)
    if z.cells then return LCZ.Contains(z, pos, m) end
    -- across: as far as the margin; up and down: only the zone's own height
    return LCZ.Contains(z, Vector(pos.x, pos.y, z.pos.z), m) and LCZ.Contains(z, Vector(z.pos.x, z.pos.y, pos.z), 0)
end

-- The floor of a zone you placed (a box stands 16 units below its floor).
local function FloorOf(z) return z.box and (z.box.mins.z + 16) or z.pos.z end

-- Nothing at p (within half of it) that territory has to keep away from.
local function ClearAt(p, kind, half)
    for _, z in ipairs(LC.Zones) do
        local gap = KEEP_CLEAR[z.kind]
        if gap and Near(z, p, gap * 0.5 + half) then return false, "it would run into " .. KEEP_NAME[z.kind] end
        if (z.kind == "rebel" or z.kind == "infest") and z.kind ~= kind and Near(z, p, half + 100) then
            return false, "the other side holds the ground there"
        end
    end
    for _, pt in ipairs(LC.Points) do
        local gap = POINT_CLEAR[pt.kind]
        if gap and math.abs(pt.pos.z - p.z) < 128 and Flat(pt.pos, p) < gap * 0.5 + half then
            return false, "it would run into a " .. pt.kind .. " point"
        end
    end
    return true
end

-- Nothing along the link (or near it) that territory has to keep away from.
local function Clear(a, b, kind, w)
    local half = w * 0.5
    local steps = math.max(1, math.ceil(Flat(a, b) / 48))
    for i = 0, steps do
        local ok, why = ClearAt(LerpVector(i / steps, a, b) + Vector(0, 0, 8), kind, half)
        if not ok then return false, why end
    end
    if kind == "infest" then
        if LC.InfestQuietAt and LC.InfestQuietAt(b) then return false, "a containment team cleared the ground there" end
        if LC.ContainmentBlocks and LC.ContainmentBlocks(a, b, half) then return false, "a powered checkpoint holds the way" end
    end
    return true
end
LC.TerritoryLinkClear = Clear

-- Is there floor at (x, y) at about this height (not a wall, not a drop)?
local function FloorOK(x, y, fz)
    if not LC.FloorUnder then return true end
    local g = LC.FloorUnder(Vector(x, y, fz + 8))
    return g ~= nil and math.abs(g.z - fz) <= 48
end

------------------------------------------------------------------------
-- The grown ground: one zone a territory
------------------------------------------------------------------------

function LC.TerritoryGround(seed)
    for _, z in ipairs(LC.Zones) do if z.cells and z.seed == seed then return z end end
    return nil
end

local function NewGround(seed)
    return { kind = seed.kind, grown = true, seed = seed, group = 0, h = HEIGHT, cells = {}, rects = {}, list = {},
        n = 0, steps = 0, pos = Vector(seed.pos.x, seed.pos.y, seed.pos.z), r = 200, born = CurTime() }
end

-- Mark one cell (its floor at fz). True if it's new.
local function Mark(G, cx, cy, fz)
    if G.n >= Cap() then return false end
    local band = floor(fz / BAND)
    if G.cells[Key(cx, cy, band)] then return false end
    -- (a ramp crossing from one band to the next: the cell is already there, a band over)
    for _, b in ipairs({ band - 1, band + 1 }) do
        local c = G.cells[Key(cx, cy, b)]
        if c and math.abs(c.lo + 16 - fz) < 48 then return false end
    end
    G.cells[Key(cx, cy, band)] = { cx = cx, cy = cy, band = band, lo = floor(fz - 16), hi = math.ceil(fz + HEIGHT) }
    G.n = G.n + 1
    return true
end

local function Has(G, cx, cy, band) return G.cells[Key(cx, cy, band)] ~= nil end

-- The ground along a link: every cell whose middle is within half the width of it, and
-- (where there's floor there, not a wall) the next cells out, so a cell edge never cuts a
-- corridor in half.
local function ClaimLink(G, a, b, w, kind)
    local half = w * 0.5
    local reach = half + CELL * 0.5
    local dx, dy = b.x - a.x, b.y - a.y
    local len2 = math.max(1, dx * dx + dy * dy)
    local added = 0
    for cx = floor((math.min(a.x, b.x) - reach) / CELL), floor((math.max(a.x, b.x) + reach) / CELL) do
        for cy = floor((math.min(a.y, b.y) - reach) / CELL), floor((math.max(a.y, b.y) + reach) / CELL) do
            local x, y = (cx + 0.5) * CELL, (cy + 0.5) * CELL
            local t = math.Clamp(((x - a.x) * dx + (y - a.y) * dy) / len2, 0, 1)
            local px, py = a.x + dx * t, a.y + dy * t
            local d = math.sqrt((x - px) ^ 2 + (y - py) ^ 2)
            local fz = a.z + (b.z - a.z) * t
            if d <= half or (d <= reach and FloorOK(x, y, fz) and ClearAt(Vector(x, y, fz + 8), kind, CELL * 0.5)) then
                if Mark(G, cx, cy, fz) then added = added + 1 end
            end
        end
    end
    return added
end

-- Gaps closed in on every side, on one floor (a courtyard, the middle of a square): filled,
-- if there's floor there and it's not something territory keeps away from. Big ones (more
-- than HOLE_MAX cells: a whole block of buildings ringed by streets) are left.
local function FillHoles(G, kind)
    local added = 0
    local bands = {}
    for _, c in pairs(G.cells) do
        local b = bands[c.band]
        if not b then b = { x0 = c.cx, x1 = c.cx, y0 = c.cy, y1 = c.cy } bands[c.band] = b end
        b.x0, b.x1 = math.min(b.x0, c.cx), math.max(b.x1, c.cx)
        b.y0, b.y1 = math.min(b.y0, c.cy), math.max(b.y1, c.cy)
    end
    for band, bb in pairs(bands) do
        if (bb.x1 - bb.x0 + 3) * (bb.y1 - bb.y0 + 3) <= 40000 then
            -- flood the outside in from the edge of the box round it
            local x0, x1, y0, y1 = bb.x0 - 1, bb.x1 + 1, bb.y0 - 1, bb.y1 + 1
            local outside, stack = {}, {}
            local function Push(x, y)
                local k = Key(x, y, band)
                if x >= x0 and x <= x1 and y >= y0 and y <= y1 and not outside[k] and not Has(G, x, y, band) then
                    outside[k] = true
                    stack[#stack + 1] = { x, y }
                end
            end
            for x = x0, x1 do Push(x, y0) Push(x, y1) end
            for y = y0, y1 do Push(x0, y) Push(x1, y) end
            while #stack > 0 do
                local p = table.remove(stack)
                Push(p[1] + 1, p[2]) Push(p[1] - 1, p[2]) Push(p[1], p[2] + 1) Push(p[1], p[2] - 1)
            end
            -- what's left, neither ground nor outside, is a hole: each one on its own
            local seen = {}
            for x = bb.x0, bb.x1 do
                for y = bb.y0, bb.y1 do
                    local k = Key(x, y, band)
                    if not outside[k] and not seen[k] and not Has(G, x, y, band) then
                        local hole, q, sum, nb = {}, { { x, y } }, 0, 0
                        seen[k] = true
                        while #q > 0 do -- (all of it, even past HOLE_MAX: so none of it is taken for a small hole later)
                            local p = table.remove(q)
                            hole[#hole + 1] = p
                            for _, d in ipairs({ { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }) do
                                local nx, ny = p[1] + d[1], p[2] + d[2]
                                local nk = Key(nx, ny, band)
                                local c = G.cells[nk]
                                if c then sum, nb = sum + c.lo + 16, nb + 1
                                elseif not seen[nk] and not outside[nk] then seen[nk] = true q[#q + 1] = { nx, ny } end
                            end
                        end
                        if #hole <= HOLE_MAX and nb > 0 then
                            local fz = sum / nb
                            for _, p in ipairs(hole) do
                                local px, py = (p[1] + 0.5) * CELL, (p[2] + 0.5) * CELL
                                if FloorOK(px, py, fz) and ClearAt(Vector(px, py, fz + 8), kind, CELL * 0.5) and Mark(G, p[1], p[2], fz) then
                                    added = added + 1
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    return added
end

-- Is p (x, y) in the triangle a b c? And the floor's height there, from theirs.
local function InTriangle(x, y, a, b, c)
    local d = (b.y - c.y) * (a.x - c.x) + (c.x - b.x) * (a.y - c.y)
    if math.abs(d) < 1 then return nil end
    local l1 = ((b.y - c.y) * (x - c.x) + (c.x - b.x) * (y - c.y)) / d
    local l2 = ((c.y - a.y) * (x - c.x) + (a.x - c.x) * (y - c.y)) / d
    local l3 = 1 - l1 - l2
    if l1 < -0.02 or l2 < -0.02 or l3 < -0.02 then return nil end
    return l1 * a.z + l2 * b.z + l3 * c.z
end

-- A node whose neighbours are all taken: the ground between them is filled in too
-- (the wedges between one link and the next round it, when they're less than half a turn apart).
local function FillBetween(G, inside, kind)
    local added = 0
    for id in pairs(inside) do
        local n = LC.Nodes[id]
        local nbs, all = {}, true
        for oid in pairs(n and n.links or {}) do
            local o = LC.Nodes[oid]
            if o and LC.TerritoryLinkFits(n.pos, o.pos) then
                if not inside[oid] then all = false break end
                nbs[#nbs + 1] = { pos = o.pos, ang = math.atan2(o.pos.y - n.pos.y, o.pos.x - n.pos.x) }
            end
        end
        if all and #nbs >= 2 then
            table.sort(nbs, function(p, q) return p.ang < q.ang end)
            for i = 1, #nbs do
                local p, q = nbs[i], nbs[i % #nbs + 1]
                local gap = (q.ang - p.ang) % (math.pi * 2)
                if (#nbs > 2 or i == 1) and gap > 0.01 and gap < math.pi - 0.01 then
                    local a, b, c = n.pos, p.pos, q.pos
                    for cx = floor(math.min(a.x, b.x, c.x) / CELL), floor(math.max(a.x, b.x, c.x) / CELL) do
                        for cy = floor(math.min(a.y, b.y, c.y) / CELL), floor(math.max(a.y, b.y, c.y) / CELL) do
                            local x, y = (cx + 0.5) * CELL, (cy + 0.5) * CELL
                            local fz = InTriangle(x, y, a, b, c)
                            if fz and FloorOK(x, y, fz) and ClearAt(Vector(x, y, fz + 8), kind, CELL * 0.5) and Mark(G, cx, cy, fz) then
                                added = added + 1
                            end
                        end
                    end
                end
            end
        end
    end
    return added
end

-- The nodes inside a territory (a seed and what grew from it): in it, or just outside
-- the edge of the zone you placed, on its floor.
local function InsideNodes(family)
    local inside, any = {}, false
    for id, n in pairs(LC.Nodes or {}) do
        for _, z in ipairs(family) do
            local inZ
            if z.cells then
                inZ = LCZ.Contains(z, n.pos + Vector(0, 0, 8), 0)
            elseif not z.grown then
                local fl = FloorOf(z)
                inZ = math.abs(n.pos.z - fl) <= LEVEL and LCZ.Contains(z, Vector(n.pos.x, n.pos.y, fl + 8), ANCHOR)
            else
                inZ = LCZ.Contains(z, n.pos + Vector(0, 0, 8), 0) -- (a round patch an older version grew)
            end
            if inZ then inside[id] = true any = true break end
        end
    end
    return inside, any
end
LC.TerritoryInsideNodes = InsideNodes

-- Already territory of this kind (any of it, anywhere)?
local function Taken(pos, kind)
    for _, z in ipairs(LC.Zones) do
        if z.kind == kind and Near(z, pos + Vector(0, 0, 8), 0) then return true end
    end
    return false
end

-- Where it is and how big, for everything that only needs a rough idea: pos at
-- the front (where it last grew to, or the furthest it still reaches), r the radius
-- of a circle as big as all of it.
local function Settle(G, front)
    LCZ.MergeGround(G)
    if front then G.pos = Vector(front.x, front.y, front.z) end
    G.r = math.max(200, math.sqrt(G.n * CELL * CELL / math.pi))
end

-- Grow one step along the path nodes. Returns the ground and where it grew to; nil
-- and why when it can't; why is "nonodes" when there are no path nodes in it or near
-- it (it grows the old way then).
function LC.TerritoryGrowAlongNodes(seed)
    local family = LC.TerritoryFamily and LC.TerritoryFamily(seed) or { seed }
    local inside, any = InsideNodes(family)
    if not any then return nil, "nonodes" end
    local G = LC.TerritoryGround(seed)
    if G and G.n >= Cap() then return nil, "it's as big as it gets (lc_territory_cells)" end
    local cands, steep = {}, 0
    for id in pairs(inside) do
        local n = LC.Nodes[id]
        for oid in pairs(n.links or {}) do
            local o = LC.Nodes[oid]
            if o and not inside[oid] then
                if not LC.TerritoryLinkFits(n.pos, o.pos) then
                    steep = steep + 1
                elseif not Taken(o.pos, seed.kind) then
                    cands[#cands + 1] = { a = n.pos, b = o.pos, to = oid }
                end
            end
        end
    end
    if #cands == 0 then
        return nil, steep > 0 and "the only path node links out of it climb more than a stair or a ramp would"
            or "no path node links lead out of it (link the nodes in it to the ones outside, in the editor)"
    end
    for i = #cands, 2, -1 do local j = math.random(i) cands[i], cands[j] = cands[j], cands[i] end
    local most = math.max(1, cvLinks:GetInt())
    local want = math.random(math.max(1, most - 1), most)
    local w, picked, to, why = LC.TerritoryWidth(), {}, {}, nil
    for _, c in ipairs(cands) do
        if #picked >= want then break end
        if not to[c.to] then
            local ok, whyNot = Clear(c.a, c.b, seed.kind, w)
            if ok then picked[#picked + 1] = c to[c.to] = true else why = why or whyNot end
        end
    end
    if #picked == 0 then return nil, why or "nowhere to grow" end
    local new = G == nil
    G = G or NewGround(seed)
    local added = 0
    for _, c in ipairs(picked) do added = added + ClaimLink(G, c.a, c.b, w, seed.kind) end
    if added == 0 then return nil, "the ground along the links out of it is already taken" end
    if new then LC.Zones[#LC.Zones + 1] = G end
    LCZ.MergeGround(G) -- (so the nodes now inside it can be found)
    for id in pairs(InsideNodes({ G })) do inside[id] = true end
    added = added + FillBetween(G, inside, seed.kind) + FillHoles(G, seed.kind)
    -- where it grew to: the link that reached furthest from where it started
    local front, fd = picked[1].b, -1
    for _, c in ipairs(picked) do
        local d = c.b:DistToSqr(seed.pos)
        if d > fd then front, fd = c.b, d end
    end
    G.steps = (G.steps or 0) + 1
    Settle(G, front)
    return G, front, #picked
end

-- How far each cell is from the zone you placed, walking through the territory
-- (cell to cell, on one floor or up a ramp). Cells cut off from it are furthest of all.
local function Distances(G, seed)
    local dist, q = {}, {}
    for k, c in pairs(G.cells) do
        local p = Vector((c.cx + 0.5) * CELL, (c.cy + 0.5) * CELL, c.lo + 24)
        if Near(seed, p, CELL) then dist[k] = 0 q[#q + 1] = c end
    end
    if #q == 0 then
        local best, bd
        for k, c in pairs(G.cells) do
            local d = Vector((c.cx + 0.5) * CELL, (c.cy + 0.5) * CELL, c.lo + 16):DistToSqr(seed.pos)
            if not bd or d < bd then best, bd = k, d end
        end
        if best then dist[best] = 0 q[1] = G.cells[best] end
    end
    -- (a small Dijkstra: steps are 1 across, 1.4 corner to corner)
    local head = 1
    while head <= #q do
        local c = q[head]
        head = head + 1
        local dc = dist[Key(c.cx, c.cy, c.band)]
        for dx = -1, 1 do
            for dy = -1, 1 do
                if dx ~= 0 or dy ~= 0 then
                    for b = c.band - 1, c.band + 1 do
                        local nk = Key(c.cx + dx, c.cy + dy, b)
                        local o = G.cells[nk]
                        if o and math.abs(o.lo - c.lo) <= 64 then
                            local nd = dc + ((dx ~= 0 and dy ~= 0) and 1.4 or 1)
                            if not dist[nk] or nd < dist[nk] - 0.001 then dist[nk] = nd q[#q + 1] = o end
                        end
                    end
                end
            end
        end
    end
    return dist
end
LC.TerritoryCellDistances = Distances

-- Push it back one growth's worth: the cells furthest out go. Returns where they were
-- (their middle), and true if nothing's left of it.
function LC.TerritoryShrinkGround(G)
    local seed = G.seed
    local dist = Distances(G, seed)
    local order = {}
    for k, c in pairs(G.cells) do order[#order + 1] = { k = k, c = c, d = dist[k] or 1e9 } end
    table.sort(order, function(a, b) return a.d > b.d end)
    local steps = math.max(1, G.steps or 1)
    local take = math.ceil(#order / steps)
    local sx, sy, sz = 0, 0, 0
    for i = 1, math.min(take, #order) do
        local c = order[i].c
        G.cells[order[i].k] = nil
        sx, sy, sz = sx + (c.cx + 0.5) * CELL, sy + (c.cy + 0.5) * CELL, sz + c.lo + 16
    end
    local n = math.min(take, #order)
    G.n = #order - n
    G.steps = steps - 1
    local where = n > 0 and Vector(sx / n, sy / n, sz / n) or G.pos
    if G.n <= 0 or G.steps <= 0 then G.cells, G.n = {}, 0 return where, true end
    -- the front is now the furthest that's left
    local front = order[n + 1].c
    Settle(G, Vector((front.cx + 0.5) * CELL, (front.cy + 0.5) * CELL, front.lo + 16))
    return where, false
end
