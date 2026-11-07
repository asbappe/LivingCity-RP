--[[
    Zone shapes (shared): circles and boxes, and the mercy around their edges.

    A zone is either a circle (pos, r) or a box (box = { mins, maxs }, axis
    aligned, the shape of most rooms and streets). A box also keeps a centre
    (pos) and the radius of a circle round it (r), for the things that only need
    a rough idea of where and how big.

    "Inside" is checked with a margin: lc_zone_mercy (96 units, about eight
    feet) is added to every zone where being inside keeps you out of trouble
    (your housing block at curfew, the prison while you serve your time, rebel
    ground), and taken off where being inside gets you into it (Combine-only
    zones), so a step over a line drawn in the editor is never the difference.
]]


LCZ = LCZ or {}

local cvMercy = CreateConVar("lc_zone_mercy", "96", bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED),
    "Civil Protection units of leeway at the edge of every zone: added where being inside keeps you safe, taken off where it gets you in trouble")

function LCZ.Mercy()
    local cv = cvMercy or GetConVar("lc_zone_mercy")
    return cv and cv:GetFloat() or 96
end

-- Is pos in zone z, with margin m (negative shrinks it)?
function LCZ.Contains(z, pos, m)
    m = m or 0
    if z.cells then return LCZ.InGround(z, pos, m) end
    local b = z.box
    if b then
        return pos.x >= b.mins.x - m and pos.x <= b.maxs.x + m
            and pos.y >= b.mins.y - m and pos.y <= b.maxs.y + m
            and pos.z >= b.mins.z - math.max(m, 0) - 16 and pos.z <= b.maxs.z + math.max(m, 0)
    end
    -- a circle reaches up and down as far as it reaches out (the old sphere, without its rounded top),
    -- unless it has a height of its own (h: territory that spread is one floor deep, so a patch on a
    -- roof isn't the street below it too)
    local r = z.r + m
    if r <= 0 then return false end
    local dx, dy = pos.x - z.pos.x, pos.y - z.pos.y
    return dx * dx + dy * dy < r * r and math.abs(pos.z - z.pos.z) < (z.h and (z.h + math.max(m, 0)) or r)
end

-- A box from two corners clicked on the floor, standing `height` tall.
function LCZ.BoxFromCorners(a, b, height)
    local mins = Vector(math.min(a.x, b.x), math.min(a.y, b.y), math.min(a.z, b.z) - 16)
    local maxs = Vector(math.max(a.x, b.x), math.max(a.y, b.y), math.max(a.z, b.z) + math.max(64, height or 192))
    return { mins = mins, maxs = maxs }
end

-- The centre and the radius of the circle round a box (in the floor's plane).
function LCZ.BoxCircle(box)
    local c = (box.mins + box.maxs) * 0.5
    c.z = box.mins.z + 16
    local dx, dy = (box.maxs.x - box.mins.x) * 0.5, (box.maxs.y - box.mins.y) * 0.5
    return c, math.sqrt(dx * dx + dy * dy)
end

-- For saving and sending: a box as six numbers, and back again.
function LCZ.PackBox(box)
    if not box then return nil end
    return { box.mins.x, box.mins.y, box.mins.z, box.maxs.x, box.maxs.y, box.maxs.z }
end
function LCZ.UnpackBox(t)
    if type(t) ~= "table" or #t < 6 then return nil end
    local n = {}
    for i = 1, 6 do n[i] = tonumber(t[i]) if not n[i] then return nil end end
    return { mins = Vector(n[1], n[2], n[3]), maxs = Vector(n[4], n[5], n[6]) }
end

-- A random spot inside it (on the plane of its centre), for spawning and the like.
function LCZ.RandomInside(z, shrink)
    shrink = shrink or 0.85
    if z.cells and z.list and #z.list > 0 then
        -- a random cell of grown ground, somewhere in it, on its floor
        local c, C = z.list[math.random(#z.list)], LCZ.CELL
        local o = (1 - shrink) * 0.5
        return Vector((c.cx + o + math.random() * shrink) * C, (c.cy + o + math.random() * shrink) * C, c.lo + 16)
    end
    if z.box then
        local b = z.box
        local cx, cy = (b.mins.x + b.maxs.x) * 0.5, (b.mins.y + b.maxs.y) * 0.5
        local hx, hy = (b.maxs.x - b.mins.x) * 0.5 * shrink, (b.maxs.y - b.mins.y) * 0.5 * shrink
        return Vector(cx + (math.random() * 2 - 1) * hx, cy + (math.random() * 2 - 1) * hy, z.pos.z)
    end
    local ang = math.random() * math.pi * 2
    local dist = math.sqrt(math.random()) * z.r * shrink
    return z.pos + Vector(math.cos(ang) * dist, math.sin(ang) * dist, 0)
end

------------------------------------------------------------------------
-- Grown ground: territory that spread along the path nodes
-- (sv_livingcity_territorypaths.lua). One territory's grown ground is one
-- zone, whatever its size: square cells (LCZ.CELL, 128 units) on a grid, each
-- one floor deep (from just under its floor to eight feet over it), kept in a
-- table by cell, so "is this spot in it" is a lookup or two, not a loop over
-- every piece. Saved and sent as the few rectangles the cells merge into.
------------------------------------------------------------------------

LCZ.CELL = 128   -- a cell's side
LCZ.BAND = 96    -- floors this far apart are told apart (a cell's floor, to the nearest band)
local CELL, BAND, floor = LCZ.CELL, LCZ.BAND, math.floor

-- One number per cell (no strings made for every lookup).
function LCZ.CellKey(cx, cy, band) return ((band + 4096) * 8192 + (cx + 4096)) * 8192 + (cy + 4096) end
local Key = LCZ.CellKey

-- The cell holding pos at height (nil: none). Floors whose band could hold pos are tried.
local function CellAt(cells, cx, cy, pz, mm)
    for b = floor((pz - 120 - mm) / BAND), floor((pz + 16 + mm) / BAND) do
        local c = cells[Key(cx, cy, b)]
        if c and pz >= c.lo - mm and pz <= c.hi + mm then return c end
    end
    return nil
end
LCZ.CellAt = CellAt

-- 2D distance from (x, y) to the square of cell (cx, cy).
local function ToCell(x, y, x0, y0, x1, y1)
    local dx = x < x0 and (x0 - x) or (x > x1 and (x - x1) or 0)
    local dy = y < y0 and (y0 - y) or (y > y1 and (y - y1) or 0)
    return math.sqrt(dx * dx + dy * dy)
end

function LCZ.InGround(z, pos, m)
    local mn, mx = z.mins, z.maxs
    if not mn then return false end
    local mm = m > 0 and m or 0
    if pos.x < mn.x - mm or pos.x > mx.x + mm or pos.y < mn.y - mm or pos.y > mx.y + mm
        or pos.z < mn.z - mm or pos.z > mx.z + mm then return false end
    local cells = z.cells
    if m <= 0 then
        if not CellAt(cells, floor(pos.x / CELL), floor(pos.y / CELL), pos.z, 0) then return false end
        if m == 0 then return true end
        -- shrunk: as far as m in from its edge, every way
        for _, d in ipairs({ { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }) do
            if not CellAt(cells, floor((pos.x - m * d[1]) / CELL), floor((pos.y - m * d[2]) / CELL), pos.z, 0) then return false end
        end
        return true
    end
    if m <= CELL * 2 then
        -- the cells around it, as far as the margin reaches
        local cx, cy, r = floor(pos.x / CELL), floor(pos.y / CELL), math.ceil(m / CELL)
        for dx = -r, r do
            for dy = -r, r do
                local x0, y0 = (cx + dx) * CELL, (cy + dy) * CELL
                if ToCell(pos.x, pos.y, x0, y0, x0 + CELL, y0 + CELL) <= m and CellAt(cells, cx + dx, cy + dy, pos.z, mm) then return true end
            end
        end
        return false
    end
    -- a wide margin: the few rectangles are quicker than the cells
    for _, r in ipairs(z.rects or {}) do
        if pos.z >= r.lo - mm and pos.z <= r.hi + mm
            and ToCell(pos.x, pos.y, r.x0 * CELL, r.y0 * CELL, (r.x1 + 1) * CELL, (r.y1 + 1) * CELL) <= m then return true end
    end
    return false
end

-- The cells merged into as few rectangles as it takes (row by row, then down), one
-- floor at a time: cells whose floors are within 24 units of each other go together
-- (a ramp is a few rectangles, a level floor one). Also works out the bounds and
-- the list for picking a random cell.
function LCZ.MergeGround(z)
    local list = {}
    for _, c in pairs(z.cells) do list[#list + 1] = c end
    table.sort(list, function(a, b)
        if a.band ~= b.band then return a.band < b.band end
        if a.cy ~= b.cy then return a.cy < b.cy end
        return a.cx < b.cx
    end)
    local used, rects = {}, {}
    local cells = z.cells
    local function Free(cx, cy, band, lo)
        local c = cells[Key(cx, cy, band)]
        return c and not used[c] and math.abs(c.lo - lo) <= 24 and c or nil
    end
    local mn, mx
    for _, c in ipairs(list) do
        if not used[c] then
            local x1 = c.cx
            while Free(x1 + 1, c.cy, c.band, c.lo) do x1 = x1 + 1 end
            local y1 = c.cy
            while true do
                local okRow = true
                for x = c.cx, x1 do if not Free(x, y1 + 1, c.band, c.lo) then okRow = false break end end
                if not okRow then break end
                y1 = y1 + 1
            end
            local lo, hi = c.lo, c.hi
            for x = c.cx, x1 do
                for y = c.cy, y1 do
                    local q = cells[Key(x, y, c.band)]
                    used[q] = true
                    lo, hi = math.min(lo, q.lo), math.max(hi, q.hi)
                end
            end
            rects[#rects + 1] = { x0 = c.cx, y0 = c.cy, x1 = x1, y1 = y1, band = c.band, lo = lo, hi = hi }
            local a, b = Vector(c.cx * CELL, c.cy * CELL, lo), Vector((x1 + 1) * CELL, (y1 + 1) * CELL, hi)
            if not mn then mn, mx = a, b else
                mn = Vector(math.min(mn.x, a.x), math.min(mn.y, a.y), math.min(mn.z, a.z))
                mx = Vector(math.max(mx.x, b.x), math.max(mx.y, b.y), math.max(mx.z, b.z))
            end
        end
    end
    z.rects, z.list, z.mins, z.maxs, z.n = rects, list, mn, mx, #list
    return rects
end

-- For saving and sending: seven whole numbers a rectangle.
function LCZ.PackGround(z)
    if not (z and z.rects) then return nil end
    local out = {}
    for _, r in ipairs(z.rects) do
        out[#out + 1] = r.x0 out[#out + 1] = r.y0 out[#out + 1] = r.x1 out[#out + 1] = r.y1
        out[#out + 1] = r.band out[#out + 1] = math.floor(r.lo) out[#out + 1] = math.ceil(r.hi)
    end
    return out
end
-- And back: the cells again (each with its rectangle's floor and top), merged.
function LCZ.UnpackGround(t, z)
    if type(t) ~= "table" then return nil end
    z = z or {}
    z.cells = {}
    for i = 1, #t - 6, 7 do
        local x0, y0, x1, y1, band, lo, hi = tonumber(t[i]), tonumber(t[i + 1]), tonumber(t[i + 2]), tonumber(t[i + 3]),
            tonumber(t[i + 4]), tonumber(t[i + 5]), tonumber(t[i + 6])
        if x0 and y0 and x1 and y1 and band and lo and hi and (x1 - x0 + 1) * (y1 - y0 + 1) <= 100000 then
            for x = x0, x1 do
                for y = y0, y1 do z.cells[Key(x, y, band)] = { cx = x, cy = y, band = band, lo = lo, hi = hi } end
            end
        end
    end
    LCZ.MergeGround(z)
    return z
end
