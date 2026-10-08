--[[
    Living City: path network

    Your own walkable lanes, drawn with the editor tool. When a map's built-in
    navigation is missing or broken (no AI nodes, nodes that skip doorways,
    NPCs that won't climb stairs), lay path nodes along the routes people
    should take and link them. NPCs then walk node to node, which only needs
    short, direct hops the engine can always manage.

    Zones (also drawn with the tool):
      nogo     NPCs never pick a destination inside, and routes avoid it
      infest   zombies live here; everyone else treats it as no-go
      prison   the prison area; leaving it while jailed counts as escaping
      rebel    Civil Protection and soldiers never patrol, path, or spawn here
      block    a housing block (see sv_livingcity_housing.lua)
      combine  Combine only: nexus, offices, armory, prison. Citizens (NPC and player) stay out

    Data lives in LC.Nodes and LC.Zones (owned and saved by sv_livingcity_data.lua).
]]

if CLIENT then return end

LC = LC or {}
LC.Nodes = LC.Nodes or {} -- [id] = { id, pos, links = { [otherId] = true } }
LC.Zones = LC.Zones or {} -- { pos, r, kind }

local DOOR_CLASSES = { prop_door_rotating = true, func_door = true, func_door_rotating = true, func_movelinear = true }

local usable = {}       -- [node] = true for nodes outside avoided zones
local usableList = {}   -- array of the same
local usablePos = {}    -- array of positions, for random wandering
local rebelNode = {}    -- [node] = true for usable nodes inside rebel zones
local combineNode = {}  -- [node] = true for usable nodes inside Combine-only zones (security only)
local securityPos = {}  -- usablePos minus rebel zones

------------------------------------------------------------------------
-- Zones
------------------------------------------------------------------------

local function InZoneOfKinds(pos, kinds, margin)
    for _, z in ipairs(LC.Zones) do
        if kinds[z.kind] and LCZ.Contains(z, pos, margin) then return z end
    end
    return nil
end

-- Zones by kind, rebuilt only when the list of zones changes (one added, one
-- removed, a layout loaded).
local zc = {}
local EMPTY = {}
local function ZoneIndex()
    local zs = LC.Zones
    local n = #zs
    if zc.tbl ~= zs or zc.n ~= n or zc.first ~= zs[1] or zc.last ~= zs[n] then
        local by = {}
        for _, z in ipairs(zs) do
            local l = by[z.kind]
            if not l then l = {} by[z.kind] = l end
            l[#l + 1] = z
        end
        zc.tbl, zc.n, zc.first, zc.last, zc.by = zs, n, zs[1], zs[n], by
    end
    return zc.by
end
-- The zones of a kind, shared: read it, don't change it (LC.ZonesOfKind gives you your own copy).
function LC.ZonesOfKindShared(kind) return ZoneIndex()[kind] or EMPTY end

local REBEL, COMBINE, INFEST, PRISON = { rebel = true }, { combine = true }, { infest = true }, { prison = true }

local AVOID = { nogo = true, infest = true, combine = true }
local AVOID_SECURITY = { nogo = true, infest = true, rebel = true }

local function IsSecurityRole(role) return role == "cop" or role == "soldier" end

-- Places NPCs of this role should not go (security also stays out of rebel zones).
function LC.InNoGo(pos, role)
    return InZoneOfKinds(pos, IsSecurityRole(role) and AVOID_SECURITY or AVOID) ~= nil
end
-- rebel ground has no mercy at its edge: rebel rooms are often small, and eight
-- feet either side of a small room is more than the room. Instead, anyone within
-- lc_zone_mercy of it is warned they're about to walk in (sv_livingcity_rebels.lua).
function LC.InRebelZone(pos)
    for _, z in ipairs(LC.ZonesOfKindShared("rebel")) do if LCZ.Contains(z, pos, 0) then return true end end
    return false
end
function LC.NearRebelZone(pos)
    local m = LCZ.Mercy()
    for _, z in ipairs(LC.ZonesOfKindShared("rebel")) do if LCZ.Contains(z, pos, m) then return true end end
    return false
end
-- Citizens never stand on Combine floors: nexus metal, Combine glass, citadel plating.
local COMBINE_TEXTURES = { "combine", "citadel", "nexus", "comb_" }

local function CombineTexture(tex)
    if not tex then return false end
    tex = string.lower(tex)
    for _, pat in ipairs(COMBINE_TEXTURES) do
        if string.find(tex, pat, 1, true) then return true end
    end
    return false
end

function LC.OnCombineSurface(pos)
    local offsets = { Vector(0, 0, 0), Vector(24, 0, 0), Vector(-24, 0, 0), Vector(0, 24, 0), Vector(0, -24, 0) }
    for _, o in ipairs(offsets) do
        local from = pos + o + Vector(0, 0, 16)
        local tr = util.TraceLine({ start = from, endpos = from - Vector(0, 0, 72), mask = MASK_NPCSOLID_BRUSHONLY })
        if tr.Hit and CombineTexture(tr.HitTexture) then return true end
    end
    return false
end

-- Where a citizen may spawn or appear: not Combine ground, not a Combine-only
-- or infested zone, and not right beside an infestation spawn.
function LC.CitizenSpotOK(pos)
    if LC.InNoGo(pos) then return false end
    if LC.OnCombineSurface(pos) then return false end
    if InZoneOfKinds(pos, PRISON) then return false end
    for _, p in ipairs(LC.Points) do
        -- cells and the release steps are Combine business, and so are checkpoints' immediate surroundings
        if (p.kind == "cell" or p.kind == "release") and p.pos:DistToSqr(pos) < 500 * 500 then return false end
    end
    for _, p in ipairs(LC.Points) do
        if p.kind == "zspawn" and p.pos:DistToSqr(pos) < 900 * 900 then return false end
    end
    for _, z in ipairs(LC.Zones) do
        if z.kind == "infest" and LCZ.Contains(z, pos, 500) then return false end
    end
    return true
end

-- without mercy: you're only trespassing well inside a Combine-only zone, not at its edge
function LC.CombineZoneAt(pos) return InZoneOfKinds(pos, COMBINE, -LCZ.Mercy()) end
function LC.InfestZoneAt(pos) return InZoneOfKinds(pos, INFEST) end
function LC.PrisonZoneAt(pos) return InZoneOfKinds(pos, PRISON) end

-- The rebel zone pos is in (the nearest, where they overlap), with an optional margin.
function LC.RebelZoneAt(pos, margin)
    local best, bd
    for _, z in ipairs(LC.ZonesOfKindShared("rebel")) do
        if LCZ.Contains(z, pos, margin or 0) then
            local d = pos:DistToSqr(z.pos)
            if not bd or d < bd then best, bd = z, d end
        end
    end
    return best
end

-- Your own list of the zones of a kind (change it as you like).
function LC.ZonesOfKind(kind)
    local out = {}
    for i, z in ipairs(LC.ZonesOfKindShared(kind)) do out[i] = z end
    return out
end

------------------------------------------------------------------------
-- Graph upkeep
------------------------------------------------------------------------

function LC.RebuildGraph()
    usable, usableList, usablePos, rebelNode, securityPos, combineNode = {}, {}, {}, {}, {}, {}
    for _, n in pairs(LC.Nodes) do
        if not InZoneOfKinds(n.pos, { nogo = true, infest = true }) then
            usable[n] = true
            usableList[#usableList + 1] = n
            -- Combine-only ground is for security: citizens neither wander there nor route through it
            if LC.CombineZoneAt(n.pos) then
                combineNode[n] = true
            else
                usablePos[#usablePos + 1] = n.pos
            end
            if LC.InRebelZone(n.pos) then rebelNode[n] = true else securityPos[#securityPos + 1] = n.pos end
        end
    end
end

function LC.NodePositions(role) return IsSecurityRole(role) and securityPos or usablePos end
function LC.NodeCount() return #usableList end

function LC.LinkCount()
    local c = 0
    for _, n in pairs(LC.Nodes) do c = c + table.Count(n.links) end
    return c / 2
end

------------------------------------------------------------------------
-- Walkability: a person-sized box slid from a to b, ignoring doors,
-- NPCs and players (doors get opened, people move).
------------------------------------------------------------------------

local function HitFilter(ent)
    if not IsValid(ent) then return true end
    if DOOR_CLASSES[ent:GetClass()] or ent:IsNPC() or ent:IsPlayer() then return false end
    return true
end

function LC.Walkable(a, b)
    local tr = util.TraceHull({
        start = a + Vector(0, 0, 20),
        endpos = b + Vector(0, 0, 20),
        mins = Vector(-10, -10, 0),
        maxs = Vector(10, 10, 44),
        mask = MASK_NPCSOLID,
        filter = HitFilter,
    })
    return not tr.Hit, tr.HitPos
end

------------------------------------------------------------------------
-- Routing
------------------------------------------------------------------------

-- Nearest usable node we can walk straight to; falls back to plain nearest.
local function EntryNode(pos, avoidRebel, avoidCombine)
    local cands = {}
    for _, n in ipairs(usableList) do
        local d = n.pos:DistToSqr(pos)
        if d < 1600 * 1600 and not (avoidRebel and rebelNode[n]) and not (avoidCombine and combineNode[n]) then
            cands[#cands + 1] = { n = n, d = d }
        end
    end
    if #cands == 0 then return nil end
    table.sort(cands, function(x, y) return x.d < y.d end)
    for i = 1, math.min(6, #cands) do
        if LC.Walkable(pos, cands[i].n.pos) then return cands[i].n end
    end
    return cands[1].n
end

local function AStar(start, goal, avoidRebel, avoidCombine)
    local open = { [start] = true }
    local came = {}
    local g = { [start] = 0 }
    local f = { [start] = start.pos:Distance(goal.pos) }
    local guard = 0

    while next(open) do
        guard = guard + 1
        if guard > 20000 then return nil end

        local cur, best
        for n in pairs(open) do
            if not best or f[n] < best then cur, best = n, f[n] end
        end

        if cur == goal then
            local path = { cur }
            while came[cur] do
                cur = came[cur]
                table.insert(path, 1, cur)
            end
            return path
        end

        open[cur] = nil
        for id in pairs(cur.links) do
            local nb = LC.Nodes[id]
            if nb and usable[nb] and not (avoidRebel and rebelNode[nb]) and not (avoidCombine and combineNode[nb]) then
                local t = g[cur] + cur.pos:Distance(nb.pos)
                if not g[nb] or t < g[nb] then
                    came[nb] = cur
                    g[nb] = t
                    f[nb] = t + nb.pos:Distance(goal.pos)
                    open[nb] = true
                end
            end
        end
    end
    return nil
end
LC._AStar = AStar -- exposed for testing

local EditorRoute

-- Returns a list of positions to walk through (ending at `to`), nil to walk
-- there directly with the engine's own pathfinding, or false when the map's
-- nodegraph says it can't be reached from here.
function LC.BuildRoute(from, to, role)
    -- the drawn path network first; where it has nothing to offer, the map's own nodegraph
    local route = EditorRoute(from, to, role)
    if route then return route end
    if LC.NavRoute then return LC.NavRoute(from, to, role) end
    return nil
end

function EditorRoute(from, to, role)
    if #usableList < 2 then return nil end
    if from:DistToSqr(to) < 450 * 450 and LC.Walkable(from, to) then return nil end

    local avoidRebel = IsSecurityRole(role)
    local avoidCombine = not avoidRebel
    local s, e = EntryNode(from, avoidRebel, avoidCombine), EntryNode(to, avoidRebel, avoidCombine)
    if not s or not e or s == e then return nil end

    local path = AStar(s, e, avoidRebel, avoidCombine)
    if not path then return nil end

    local out = {}
    for _, n in ipairs(path) do out[#out + 1] = n.pos end
    out[#out + 1] = to
    return out
end

-- Links every pair of nodes within radius that a person could walk between.
function LC.AutoLink(radius)
    radius = radius or 450
    local r2 = radius * radius
    local list = {}
    for _, n in pairs(LC.Nodes) do list[#list + 1] = n end
    local made = 0
    for i = 1, #list do
        for j = i + 1, #list do
            local a, b = list[i], list[j]
            if not a.links[b.id] and a.pos:DistToSqr(b.pos) < r2 and LC.Walkable(a.pos, b.pos) then
                a.links[b.id] = true
                b.links[a.id] = true
                made = made + 1
            end
        end
    end
    return made
end

-- Nodes with no links at all are almost always a mistake worth pointing out.
function LC.OrphanNodes()
    local out = {}
    for _, n in pairs(LC.Nodes) do
        if next(n.links) == nil then out[#out + 1] = n end
    end
    return out
end
