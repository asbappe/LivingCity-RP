--[[
    Living City: how infested each district is, and its leaking to the next
    (the owner, 18 November: the long-term plan, item 1, "go with 1 for now":
    a district is a housing block)

    Every district (a housing block; ground outside every block counts for the
    nearest one, the same as who holds it) has an infestation score from 0 to
    100, worked out from what is really there: each patch the infestation grew
    near it counts PATCH points, each infestation placed in the editor near it
    POINTS_PLACED (none while a containment team's clearing keeps it quiet).
    Clearing the infestation (weedkiller, fire, the cleanup jobs, Containment)
    brings the score down by itself, since the patches go.

    A district at LEAK or more leaks: every LEAK_MINUTES or so (one at a time
    per district), spores carry the infestation to one of its NEIGHBOURS (the
    nearest blocks by their middles), the less infested first. It grows there
    as a patch of the infestation it came from, so everything that fights the
    infestation fights it. Never past a checkpoint with power (lc_containment),
    never onto ground just cleared, and only while the infestation can grow at
    all (lc_territory_spread, lc_infest_max, lc_territory_city_max). The radio
    tells Civil Protection where it spread, as for any growth; the next City
    Bulletin says where it came from.

    Read in the world and on F2 > Me (More) > The state of the city (a word
    after the district: infested, badly infested, overrun); no meter on screen
    (house rule 10). lc_territory (admin) lists the scores.
]]

if CLIENT then return end

LC = LC or {}

local PATCH = 12          -- points for each grown patch
local POINTS_PLACED = 25  -- points for an infestation placed in the editor
local LEAK = 50           -- a district this infested leaks to a neighbour
local LEAK_MINUTES = 20   -- about this often (one at a time per district)
local NEIGHBOURS = 2      -- the nearest this many blocks are next door
local RETRY = 120         -- couldn't leak: tried again this soon

LC.DistrictInfestConst = { PATCH = PATCH, POINTS_PLACED = POINTS_PLACED, LEAK = LEAK, LEAK_MINUTES = LEAK_MINUTES, NEIGHBOURS = NEIGHBOURS }

local function BlockAt(pos) return LC.LedgerBlockAt and LC.LedgerBlockAt(pos) end
local function BName(n) return LC.BlockName and LC.BlockName(n) or ("Block " .. tostring(n)) end
local function Quiet(pos) return LC.InfestQuietAt and LC.InfestQuietAt(pos) end

-- The middle of a cell of ground grown along the path nodes.
local function CellPos(c)
    local size = LCZ and LCZ.CELL or 64
    return Vector((c.cx + 0.5) * size, (c.cy + 0.5) * size, (c.lo or 0) + 16)
end

-- { [block] = points } for what is there now (not capped; worked out again every few seconds).
local cache, cacheAt, cacheOf = nil, -1e9, nil
local function Points()
    if cache and CurTime() - cacheAt < 5 and cacheOf == LC.Zones then return cache end
    local out = {}
    local function Add(pos, d)
        local n = BlockAt(pos)
        if n then out[n] = (out[n] or 0) + d end
    end
    for _, z in ipairs(LC.Zones or {}) do
        if z.kind == "infest" and z.grown then
            if z.cells and next(z.cells) then
                -- ground grown along the path nodes: its cells, each where it lies
                local n, list = 0, {}
                for _, c in pairs(z.cells) do n = n + 1 list[n] = c end
                local each = PATCH * math.max(1, z.steps or 1) / n
                for _, c in ipairs(list) do Add(CellPos(c), each) end
            elseif not z.cells then
                Add(z.pos, PATCH)
            end
        end
    end
    -- placed infestations: touching zones are one (LC.TerritoryClusters)
    for _, cluster in ipairs(LC.TerritoryClusters and LC.TerritoryClusters() or {}) do
        local seed = cluster[1]
        if seed.kind == "infest" and not Quiet(seed.pos) then Add(seed.pos, POINTS_PLACED) end
    end
    cache, cacheAt, cacheOf = out, CurTime(), LC.Zones
    return out
end
LC.DistrictInfestForget = function() cache = nil end

-- How infested district n is, 0 to 100.
function LC.DistrictInfest(n)
    return math.Clamp(math.floor((Points()[n] or 0) + 0.5), 0, 100)
end

-- Words for a score (nil: nothing worth saying).
function LC.DistrictInfestWord(v)
    v = v or 0
    if v >= 75 then return "overrun" elseif v >= LEAK then return "badly infested" elseif v >= 25 then return "infested" end
    return nil
end

-- The districts next door: the nearest blocks by their middles.
function LC.DistrictNeighbours(n)
    local c = LC.BlockCenter and LC.BlockCenter(n)
    if not c then return {} end
    local list = {}
    for _, m in ipairs(LC.BlockNumbers and LC.BlockNumbers() or {}) do
        local mc = m ~= n and LC.BlockCenter(m)
        if mc then list[#list + 1] = { n = m, d = mc:DistToSqr(c) } end
    end
    table.sort(list, function(a, b) return a.d < b.d end)
    local out = {}
    for i = 1, math.min(NEIGHBOURS, #list) do out[i] = list[i].n end
    return out
end

-- The infestation in district n with the most there (its seed), to leak from.
local function SourceSeed(n)
    local best, bp = nil, 0
    for _, cluster in ipairs(LC.TerritoryClusters and LC.TerritoryClusters() or {}) do
        local seed = cluster[1]
        if seed.kind == "infest" then
            local p = 0
            for _, s in ipairs(cluster) do
                for _, z in ipairs(LC.TerritoryFamily and LC.TerritoryFamily(s) or { s }) do
                    if BlockAt(z.pos) == n then p = p + (z.grown and PATCH or POINTS_PLACED) end
                end
            end
            if p > bp then best, bp = seed, p end
        end
    end
    return best
end

-- Leak district n's infestation to a neighbour now. Returns the patch and where it
-- went, or nil and why not.
function LC.DistrictLeak(n)
    if not (LC.GrowTerritory and LC.TerritoryLeakSpot) then return nil, "no territory" end
    local seed = SourceSeed(n)
    if not seed then return nil, "no infestation of its own" end
    if LC.TerritoryCanGrow and not LC.TerritoryCanGrow(seed) then return nil, "it's as big as it gets (lc_infest_max, lc_territory_city_max)" end
    local next_ = LC.DistrictNeighbours(n)
    table.sort(next_, function(a, b) return LC.DistrictInfest(a) < LC.DistrictInfest(b) end)
    for _, m in ipairs(next_) do
        if LC.DistrictInfest(m) < LC.DistrictInfest(n) then
            local pos, r = LC.TerritoryLeakSpot(seed, LC.BlockCenter(m), function(p) return BlockAt(p) == m end)
            if pos then
                local z = LC.GrowTerritory(seed, pos, r, "leak")
                if z then
                    cache = nil
                    if LC.LedgerNews then LC.LedgerNews(string.format("The infestation has spread from %s to %s.", BName(n), BName(m))) end
                    hook.Run("LivingCityDistrictLeaked", n, m, z)
                    return z, m
                end
            end
        end
    end
    return nil, "nowhere next door it could take (a checkpoint with power, ground just cleared, or no open ground)"
end

LC.DistrictLeakAt = LC.DistrictLeakAt or {} -- [block] = when it may leak next

timer.Create("LivingCityDistrictInfest", 30, 0, function()
    local ok, err = LC.Try(function()
        if not LC.Running or not GetConVar("lc_territory_spread"):GetBool() then return end
        local now = CurTime()
        for _, n in ipairs(LC.BlockNumbers and LC.BlockNumbers() or {}) do
            if LC.DistrictInfest(n) >= LEAK then
                local due = LC.DistrictLeakAt[n]
                if not due then
                    LC.DistrictLeakAt[n] = now + LEAK_MINUTES * 60 * math.Rand(0.75, 1.25)
                elseif now >= due then
                    local z = LC.DistrictLeak(n)
                    LC.DistrictLeakAt[n] = now + (z and LEAK_MINUTES * 60 * math.Rand(0.75, 1.25) or RETRY)
                end
            else
                LC.DistrictLeakAt[n] = nil
            end
        end
    end)
    if not ok then LC.Error("districtinfest", err) end
end)

-- For lc_territory: a line per district with any infestation.
function LC.DistrictInfestStatus()
    local out = {}
    for _, n in ipairs(LC.BlockNumbers and LC.BlockNumbers() or {}) do
        local v = LC.DistrictInfest(n)
        if v > 0 then
            local due = LC.DistrictLeakAt[n]
            out[#out + 1] = string.format("%s: infestation %d%s", BName(n), v,
                v >= LEAK and (due and string.format(", leaks next door in about %d min", math.max(0, math.ceil((due - CurTime()) / 60))) or ", leaks next door soon") or "")
        end
    end
    return out
end
