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
    "Units of leeway at the edge of every zone: added where being inside keeps you safe, taken off where it gets you in trouble")

function LCZ.Mercy()
    local cv = cvMercy or GetConVar("lc_zone_mercy")
    return cv and cv:GetFloat() or 96
end

-- Is pos in zone z, with margin m (negative shrinks it)?
function LCZ.Contains(z, pos, m)
    m = m or 0
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
