--[[
    Living City: territory that spreads, and is pushed back

    The rebel zones and infestation zones you place in the editor are seeds.
    Left alone, each one slowly spreads: every so often a new patch of
    territory grows out from its edge along the path nodes you laid
    (sv_livingcity_territorypaths.lua: a block eight feet tall along the next
    link out); with no path nodes near it, a round patch in a random direction,
    over ground people can walk to. Rebels and zombies move in, and more of them turn up.

    Fighting back pushes it in. Every rebel or zombie killed in the territory
    (by a player or a unit) is a hit against it, and a run of hits takes the
    outermost patch away (along the path nodes: one growth's worth of the ground
    furthest out). Clear a patch out completely and it goes at once (the same).
    A territory that's been hit doesn't grow again for a while. The seed you
    placed is never taken away: it's where it all starts again.

      lc_territory_spread 0/1          spreading on or off (1)
      lc_rebel_spread_minutes <m>      average minutes between rebel growth (40)
      lc_infest_spread_minutes <m>     average minutes between infestation growth (10)
      lc_infest_max <n>                most patches an infestation can grow (30)
      lc_territory_city_max <n>        most patches of each kind across the whole city (45)
      lc_territory_max <n>             most patches a territory can grow (6); placed zones
                                       that touch or overlap count as one territory
      lc_territory_hits <n>            kills that push back one patch (3)
      lc_territory_calm <m>            minutes after a hit before it grows again (10)

      lc_territory                     what's grown where (admin)
      lc_territory_grow rebel|infest   grow one now (admin; superadmins also have it in
                                       C > Help > Admin testing tools > The city)
      lc_territory_reset               take back everything that grew (admin)

    Grown patches are kept across restarts in garrysmod/data/livingcity/<map>_territory.json,
    not in the layout file, so your own layout stays exactly as you drew it.
]]

if CLIENT then return end

LC = LC or {}

local FLAGS = bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED)
local cvOn      = CreateConVar("lc_territory_spread", "1", FLAGS, "Rebel and infestation zones slowly spread when left alone, and recede when fought")
local cvRebelM  = CreateConVar("lc_rebel_spread_minutes", "40", FLAGS, "Average minutes between rebel territory growing")
local cvInfestM = CreateConVar("lc_infest_spread_minutes", "10", FLAGS, "Average minutes between each infestation growing")
local cvMax     = CreateConVar("lc_territory_max", "6", FLAGS, "Most patches each territory can grow (placed zones that touch count as one)")
local cvHits    = CreateConVar("lc_territory_hits", "3", FLAGS, "Rebels or zombies killed to push back one patch of territory")
local cvCalm    = CreateConVar("lc_territory_calm", "10", FLAGS, "Minutes after territory is fought over before it grows again")
local cvInfMax  = CreateConVar("lc_infest_max", "30", FLAGS, "Most patches each infestation can grow (lc_territory_max is for the Resistance)")
local cvCityMax = CreateConVar("lc_territory_city_max", "45", FLAGS, "Most patches of each kind grown across the whole city, however many territories there are")

-- The most one territory of this kind can grow.
local function MaxFor(kind) return kind == "infest" and cvInfMax:GetInt() or cvMax:GetInt() end

local KINDS = { rebel = true, infest = true }
local UP = Vector(0, 0, 50)

-- what territory mustn't grow over
local KEEP_CLEAR = { block = 150, prison = 300, combine = 300, nogo = 50 }
local POINT_CLEAR = { checkpoint = 500, queue = 500, cell = 600, release = 500, spawn = 350, dispenser = 400, terminal = 400 }

local function Path() return "livingcity/" .. game.GetMap() .. "_territory.json" end
local function Pick(t) return t[math.random(#t)] end

LC.TerritoryState = LC.TerritoryState or {} -- [seed zone] = { nextGrow, hits, lastHit }

local function Interval(kind)
    local m = kind == "rebel" and cvRebelM:GetFloat() or cvInfestM:GetFloat()
    -- a hijacked city screen gets people talking: rebel ground spreads faster for a while
    if kind == "rebel" and (LC.RebelSurgeUntil or 0) > CurTime() then m = m * 0.4 end
    -- a city broadcast that ran its course settles people: it spreads slower for a while
    if kind == "rebel" and (LC.RebelCalmUntil or 0) > CurTime() then m = m * 2.5 end
    return math.max(1, m) * 60 * math.Rand(0.75, 1.25)
end

local function StateOf(seed)
    local s = LC.TerritoryState[seed]
    if not s then
        s = { nextGrow = CurTime() + Interval(seed.kind), hits = 0, lastHit = -1e9 }
        LC.TerritoryState[seed] = s
    end
    return s
end

local function IsSeed(z) return KINDS[z.kind] and not z.grown end

local function Seeds()
    local out = {}
    for _, z in ipairs(LC.Zones) do if IsSeed(z) then out[#out + 1] = z end end
    return out
end

-- A seed and everything that grew from it.
local function Family(seed)
    local out = { seed }
    for _, z in ipairs(LC.Zones) do if z.grown and z.seed == seed then out[#out + 1] = z end end
    return out
end
LC.TerritoryFamily = Family

local function Grown(seed)
    local out = {}
    for _, z in ipairs(LC.Zones) do if z.grown and z.seed == seed then out[#out + 1] = z end end
    return out
end

-- Placed zones of one kind that touch or overlap are one territory: an area drawn
-- with many small circles spreads, and is reported, like one place, not like forty.
local clusterCache, clusterKey, clusterAt, clusterOf = nil, nil, 0, nil
local function Clusters()
    -- worked out again when the zones change (a layout reload makes new ones), or every few seconds
    local key = #LC.Zones
    if clusterCache and clusterKey == key and clusterOf == LC.Zones and CurTime() - clusterAt < 5 then return clusterCache end
    clusterOf = LC.Zones
    local seeds = Seeds()
    local parent = {}
    local function Find(z) while parent[z] ~= z do z = parent[z] end return z end
    for _, z in ipairs(seeds) do parent[z] = z end
    for i = 1, #seeds do
        for j = i + 1, #seeds do
            local a, b = seeds[i], seeds[j]
            if a.kind == b.kind and a.pos:DistToSqr(b.pos) < (a.r + b.r + 300) ^ 2 then parent[Find(a)] = Find(b) end
        end
    end
    local groups, order = {}, {}
    for _, z in ipairs(seeds) do
        local root = Find(z)
        if not groups[root] then groups[root] = {} order[#order + 1] = root end
        table.insert(groups[root], z)
    end
    local out = {}
    for _, r in ipairs(order) do out[#out + 1] = groups[r] end
    clusterCache, clusterKey, clusterAt = out, key, CurTime()
    return out
end
LC.TerritoryClusters = Clusters

local function ClusterOf(seed)
    for _, c in ipairs(Clusters()) do
        for _, z in ipairs(c) do if z == seed then return c end end
    end
    return { seed }
end

LC.TerritoryClusterOf = ClusterOf

-- How much a grown zone counts for: a round patch is one; ground grown along the path
-- nodes counts each time it grew (one growth, one "patch", as lc_territory_max counts them).
local function Patches(z) return z.cells and math.max(1, z.steps or 1) or 1 end
LC.TerritoryPatches = Patches

local function ClusterGrown(cluster)
    local n = 0
    for _, seed in ipairs(cluster) do for _, z in ipairs(Grown(seed)) do n = n + Patches(z) end end
    return n
end

function LC.GrownCount(kind)
    local n = 0
    for _, z in ipairs(LC.Zones) do if z.grown and z.kind == kind then n = n + Patches(z) end end
    return n
end

-- the seed whose territory pos is in (or right at the edge of)
local function SeedAt(pos, kind, margin)
    local best, bd
    for _, z in ipairs(LC.Zones) do
        if z.kind == kind then
            local d = pos:DistToSqr(z.pos)
            if LCZ.Contains(z, pos, margin or 0) and (not bd or d < bd) then best, bd = z, d end
        end
    end
    if not best then return nil, nil end
    return best.grown and best.seed or best, best
end
LC.TerritorySeedAt = SeedAt

------------------------------------------------------------------------
-- Saving
------------------------------------------------------------------------

-- Territory that spreads is one floor deep (half above and below its floor),
-- so a patch on a roof isn't also the street under it.
local GROWN_H = 128

local function Prune()
    -- patches whose seed was removed in the editor go with it
    local seeds = {}
    for _, z in ipairs(LC.Zones) do if IsSeed(z) then seeds[z] = true end end
    for i = #LC.Zones, 1, -1 do
        local z = LC.Zones[i]
        if z.grown and not seeds[z.seed] then table.remove(LC.Zones, i) end
    end
end

function LC.SaveTerritory()
    Prune()
    local out = {}
    for _, z in ipairs(LC.Zones) do
        if z.grown and z.seed then
            out[#out + 1] = { kind = z.kind, x = z.pos.x, y = z.pos.y, z = z.pos.z, r = z.r, h = z.h,
                sx = z.seed.pos.x, sy = z.seed.pos.y, sz = z.seed.pos.z,
                -- (grown along the path nodes: its cells, as the few rectangles they merge into)
                ground = z.cells and LCZ.PackGround(z) or nil, steps = z.cells and z.steps or nil }
        end
    end
    file.CreateDir("livingcity")
    file.Write(Path(), util.TableToJSON(out, true))
end

-- Called at the end of every layout load: put the grown patches back.
function LC.RestoreTerritory()
    local raw = file.Read(Path(), "DATA")
    local list = raw and util.JSONToTable(raw) or nil
    if not istable(list) then return end
    for _, t in ipairs(list) do
        if KINDS[t.kind] and t.x and t.sx then
            local sp = Vector(t.sx, t.sy, t.sz)
            local seed
            for _, z in ipairs(LC.Zones) do
                if IsSeed(z) and z.kind == t.kind and z.pos:DistToSqr(sp) < 64 then seed = z break end
            end
            if seed and istable(t.ground) then
                -- grown along the path nodes: back cell for cell
                local z = LCZ.UnpackGround(t.ground, { kind = t.kind, grown = true, seed = seed, group = 0, h = 96,
                    steps = math.max(1, tonumber(t.steps) or 1), pos = Vector(t.x, t.y, t.z), born = CurTime() })
                z.r = math.max(200, math.sqrt((z.n or 0) * LCZ.CELL * LCZ.CELL / math.pi))
                if (z.n or 0) > 0 then LC.Zones[#LC.Zones + 1] = z end
                seed = nil
            end
            -- A patch an older version grew out over thin air, off a roof's edge, isn't
            -- put back; one that reaches past the edge comes back shrunk to the floor it's on.
            local pos = Vector(t.x, t.y, t.z)
            local r = tonumber(t.r) or 300
            local floating = seed and LC.FloorUnder and not LC.FloorUnder(pos + Vector(0, 0, 8))
            if seed and not floating and LC.TerritoryFitRadius then
                r = LC.TerritoryFitRadius(pos, r)
                floating = r == nil
            end
            if seed and not floating then
                LC.Zones[#LC.Zones + 1] = { pos = pos, r = r, h = tonumber(t.h) or GROWN_H, kind = t.kind,
                    group = 0, grown = true, seed = seed, born = CurTime() }
            end
        end
    end
end

-- Zones changed: the path network, wandering, and the editor overlay all need to know.
local function Changed()
    LC.SaveTerritory()
    LC.SaveData() -- writes the (unchanged) layout, and refreshes everything that depends on zones
end

------------------------------------------------------------------------
-- Growing
------------------------------------------------------------------------

local function ClearOfOthers(pos, r, kind)
    for _, z in ipairs(LC.Zones) do
        local gap = KEEP_CLEAR[z.kind]
        if gap and LCZ.Near(z, pos, r * 0.5 + gap) then return false end
        -- rebels and the infestation don't grow into each other (grown ground: its cells, LCZ.Near)
        if KINDS[z.kind] and z.kind ~= kind and LCZ.Near(z, pos, r + 100) then return false end
    end
    for _, p in ipairs(LC.Points) do
        local gap = POINT_CLEAR[p.kind]
        if gap and p.pos:DistToSqr(pos) < (gap + r * 0.5) ^ 2 then return false end
    end
    return true
end

-- The floor right under pos, if there's one close below (nil: thin air).
local function Floor(pos)
    if LC.FloorUnder then return LC.FloorUnder(pos) end
    local tr = util.TraceLine({ start = pos + Vector(0, 0, 40), endpos = pos - Vector(0, 0, 120), mask = MASK_NPCSOLID_BRUSHONLY })
    if tr and tr.Hit and not tr.StartSolid then return tr.HitPos end
end

-- Can you walk from a to b on the one floor: no drop, no gap, no climb on the way
-- (off a roof's edge and out over the street is not "the next patch over").
local function SameFloor(a, b)
    local steps = math.max(1, math.ceil(a:Distance(b) / 64))
    local last = a.z
    for i = 1, steps do
        local g = Floor(LerpVector(i / steps, a, b) + Vector(0, 0, 8))
        if not g or math.abs(g.z - last) > 48 then return false end
        last = g.z
    end
    return true
end
LC.TerritorySameFloor = SameFloor

-- How big a patch can be here and still be on the floor: shrunk until most
-- of its edge has ground under it (a rooftop's patch stays on the roof). nil if
-- not even a small one fits.
local function FitRadius(p, r)
    while r >= 200 do
        local ok = 0
        for i = 1, 8 do
            local a = i * math.pi / 4
            local q = p + Vector(math.cos(a), math.sin(a), 0) * (r * 0.7)
            local g = Floor(q + Vector(0, 0, 8))
            if g and math.abs(g.z - p.z) < 64 then ok = ok + 1 end
        end
        if ok >= 7 then return r end
        r = r * 0.75
    end
    return nil
end
LC.TerritoryFitRadius = FitRadius

-- Is this patch next to that one for someone on foot? On the one floor with
-- nothing in the way (no drop, no gap), or a short walk away on the map's
-- nodegraph: down a stairwell, a ramp or a ladder an NPC can use. Never just
-- across thin air.
local function Linked(from, p, newR)
    if SameFloor(from.pos, p) then return true end
    if not LC.NavWalkDistance then return false end
    local walk = LC.NavWalkDistance(from.pos, p)
    return type(walk) == "number" and walk <= math.max(900, (from.r + newR) * 1.6)
end
LC.TerritoryLinked = Linked

-- Same floor as zone z (a patch one floor down isn't "inside" the one above it).
local function SameLevel(z, p) return math.abs(p.z - z.pos.z) < (z.h or 100) end

-- Somewhere just past the edge of the territory, on ground people walk on
-- (on this floor, or up or down the stairs from it).
local function GrowthSpot(seed)
    local family = Family(seed)
    local newR = math.Clamp(seed.r * math.Rand(0.55, 0.8), 200, 700)
    for attempt = 1, 70 do
        local from = Pick(family)
        local p
        if attempt <= 40 then
            p = LC.RandomWanderPos("citizen", from.pos) -- a spot people actually walk to
        elseif attempt <= 52 then
            -- where NPCs can stand near the edge, on any floor: the top or the foot of the stairs
            local nodes = LC.NavNodesNear and LC.NavNodesNear(from.pos, from.r + newR) or {}
            if #nodes > 0 then p = Pick(nodes).pos end
        else
            -- straight out from the edge, on whatever floor is there
            local a = math.random() * math.pi * 2
            local probe = from.pos + Vector(math.cos(a), math.sin(a), 0) * (from.r + newR * 0.5)
            local tr = util.TraceLine({ start = from.pos + Vector(0, 0, 40), endpos = probe + Vector(0, 0, 40), mask = MASK_NPCSOLID_BRUSHONLY })
            if tr and not tr.Hit then p = probe end
        end
        p = p and Floor(p + Vector(0, 0, 8)) -- (nothing under it: not here)
        local fitR = p and FitRadius(p, newR)
        if p and fitR then
            local dz = math.abs(p.z - from.pos.z)
            local flat = Vector(p.x - from.pos.x, p.y - from.pos.y, 0):Length()
            -- past the edge on this floor; anywhere over or near it on the next one
            local edgeOk = flat < from.r + newR and (flat > from.r * 0.75 or dz > (from.h or 100))
            local inside = false
            for _, z in ipairs(family) do
                if z.cells then
                    if LCZ.Contains(z, p, 0) then inside = true break end
                elseif SameLevel(z, p) and Vector(p.x - z.pos.x, p.y - z.pos.y, 0):LengthSqr() < (z.r * 0.8) ^ 2 then inside = true break end
            end
            if edgeOk and not inside and dz < 700 and ClearOfOthers(p, fitR, seed.kind)
                and not (seed.kind == "infest" and LC.InfestQuietAt(p))
                and not (seed.kind == "infest" and LC.ContainmentBlocks and LC.ContainmentBlocks(from.pos, p, fitR)) -- (a checkpoint with power: sv_livingcity_checkpoints.lua)
                and (not LC.NavReachable or LC.NavReachable(from.pos, p))
                and Linked(from, p, fitR) then
                return p, fitR
            end
        end
    end
    return nil
end

local function Radio(band, text) if LC.RadioNotice then LC.RadioNotice(band, text) end end

-- Growth that happens close together is one notice on the radio, not one per patch.
local pendingNotice = {} -- [kind] = { places }
function LC.TerritoryNotice(kind, where)
    local p = pendingNotice[kind]
    if p then
        local seen = false
        for _, w in ipairs(p) do if w == where then seen = true end end
        if not seen then p[#p + 1] = where end
        return
    end
    pendingNotice[kind] = { where }
    timer.Simple(3, function()
        local places = pendingNotice[kind] or {}
        pendingNotice[kind] = nil
        local list = table.concat(places, ", ", 1, math.min(#places, 3)) .. (#places > 3 and ", and elsewhere" or "")
        if kind == "rebel" then
            Radio("resistance", "We've taken more ground " .. list .. ". Hold it.")
            Radio("cp", "Dispatch: anticitizen activity spreading " .. list .. ". Civil Protection units are advised to push it back.")
        else
            Radio("cp", "Dispatch: infestation spreading " .. list .. ". Containment teams required.")
        end
    end)
end

-- Ground just cleared of the infestation: nothing spawns or spreads there for
-- lc_infest_quiet_minutes (10).
local cvQuiet = CreateConVar("lc_infest_quiet_minutes", "10", bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED),
    "Minutes nothing infested spawns or spreads near ground a containment team just cleared")
LC.InfestQuiet = LC.InfestQuiet or {}
function LC.QuietInfestation(pos, r, secs)
    local q = { pos = pos, r = r, untilT = CurTime() + (secs or cvQuiet:GetFloat() * 60) }
    table.insert(LC.InfestQuiet, q)
    return q
end
function LC.InfestQuietAt(pos)
    local now = CurTime()
    for i = #LC.InfestQuiet, 1, -1 do
        local q = LC.InfestQuiet[i]
        if now > q.untilT then
            table.remove(LC.InfestQuiet, i)
        elseif pos:DistToSqr(q.pos) < q.r * q.r then
            return true
        end
    end
    return false
end

LC.TerritoryGrowthSpot = GrowthSpot
function LC.TerritoryCanGrow(seed)
    return ClusterGrown(ClusterOf(seed)) < MaxFor(seed.kind) and LC.GrownCount(seed.kind) < cvCityMax:GetInt()
end
function LC.TerritorySeeds(kind)
    local out = {}
    for _, z in ipairs(Seeds()) do if not kind or z.kind == kind then out[#out + 1] = z end end
    return out
end

function LC.GrowTerritory(seed, atPos, atR, why)
    if not LC.TerritoryCanGrow(seed) then
        return nil, "it's as big as it gets (lc_territory_max, lc_infest_max, lc_territory_city_max)"
    end
    local z, front, links
    -- along the path nodes: a few links out, and the gaps between (sv_livingcity_territorypaths.lua)
    if not atPos and LC.TerritoryGrowAlongNodes then
        local g, at, n = LC.TerritoryGrowAlongNodes(seed)
        if g then
            z, front, links = g, at, n
        elseif at ~= "nonodes" then
            return nil, at
        end
    end
    -- no path nodes in it or near it: a round patch out past its edge, the way it always grew
    if not z then
        local pos, r = atPos, atR
        if not pos then pos, r = GrowthSpot(seed) end
        if not pos then return nil, "nowhere to grow: no path nodes lead out of it, and no open floor round its edge is big enough for a round patch (lay path nodes out of it in the editor)" end
        r = r or math.Clamp(seed.r * 0.7, 200, 700)
        z = { pos = pos, r = r, h = GROWN_H, kind = seed.kind, group = 0, grown = true, seed = seed, born = CurTime(), why = why }
        LC.Zones[#LC.Zones + 1] = z
    end
    Changed()
    -- (where it grew to: the furthest it reached)
    z.where = LC.DescribePlace and LC.DescribePlace(front or z.pos) or "nearby"
    LC.TerritoryNotice(seed.kind, z.where)
    -- someone moves in
    if seed.kind == "rebel" and LC.ReinforceRebels then
        LC.ReinforceRebels(z, 1)
    elseif seed.kind == "infest" and LC.SpawnZombie and (not (LC.ZombieTarget and LC.QB and LC.QB.CountRole) or LC.QB.CountRole("zombie") < LC.ZombieTarget()) then
        local spot = LC.SpotInZone(z)
        if spot and not LC.IsSeen(spot + UP) then LC.SpawnZombie(spot + Vector(0, 0, 4), z) end
    end
    LC.Log("info", string.format("Territory: %s grew at %s (%s), %d patches now", seed.kind, tostring(front or z.pos),
        z.cells and string.format("along %d path node link%s: %d cells in %d rectangles", links or 0, links == 1 and "" or "s", z.n or 0, #(z.rects or {}))
        or ("r " .. math.floor(z.r)), ClusterGrown(ClusterOf(seed))))
    hook.Run("LivingCityTerritoryGrew", seed, z)
    return z
end

------------------------------------------------------------------------
-- Pushing it back
------------------------------------------------------------------------

local function Alive(e) return IsValid(e) and e:Health() > 0 end

local function LivingIn(z, role)
    local n = 0
    for npc, st in pairs(LC.NPCs or {}) do
        if Alive(npc) and st.role == role and LCZ.Contains(z, npc:GetPos(), 100) then n = n + 1 end
    end
    return n
end

-- What a unit is called on the street: their designation, else their name.
local function Callsign(p)
    local t = p:GetNW2String("lcf_title", "")
    return t ~= "" and t or (LC.CharacterName and LC.CharacterName(p) or p:Nick())
end
LC.Callsign = LC.Callsign or Callsign

-- by: the player whose work it was, if any. The whole city hears who did it.
-- Ground grown along the path nodes goes back one growth's worth at a time, the
-- cells furthest out first; a round patch goes all at once.
function LC.RecedeTerritory(z, why, by)
    if not z or not z.grown then return false end
    local idx
    for i, q in ipairs(LC.Zones) do if q == z then idx = i break end end
    if not idx then return false end
    local lost = z -- (what the hooks hear about: the patch, or where the ground was lost)
    if z.cells and LC.TerritoryShrinkGround then
        local at, gone = LC.TerritoryShrinkGround(z)
        if gone then table.remove(LC.Zones, idx) end
        lost = { kind = z.kind, pos = at, r = 300, grown = true, seed = z.seed, ground = z }
    else
        table.remove(LC.Zones, idx)
    end
    Changed()
    local where = LC.DescribePlace and LC.DescribePlace(lost.pos) or ""
    if where == "somewhere in the city" then where = "" end
    local who = IsValid(by) and by:IsPlayer() and Callsign(by) or nil
    local place = where ~= "" and (" " .. where) or ""
    if z.kind == "rebel" then
        Radio("cp", who and ("Dispatch: " .. who .. " has retaken anticitizen ground" .. place .. ".") or ("Dispatch: anticitizen ground" .. place .. " is retaken."))
        Radio("resistance", "We've lost the ground" .. place .. ".")
    else
        Radio("cp", who and ("Dispatch: " .. who .. " has contained the infestation" .. place .. ".") or ("Dispatch: infestation" .. place .. " is contained."))
    end
    if who then
        local line = z.kind == "rebel" and (who .. " has retaken ground from the Resistance" .. place .. ".")
            or (who .. " has contained the infestation" .. place .. ".")
        for _, p in ipairs(player.GetAll()) do p:ChatPrint("[City] " .. line) end
    end
    LC.Log("info", "Territory: " .. z.kind .. " ground at " .. tostring(lost.pos) .. " lost (" .. (why or "pushed back") .. ")")
    hook.Run("LivingCityTerritoryReceded", z.seed, lost, why)
    return true
end

-- What to give up first: ground grown along the path nodes (its outermost cells),
-- else the round patch farthest out from the seed.
local function Outermost(seed)
    local g = LC.TerritoryGround and LC.TerritoryGround(seed)
    if g then return g end
    local best, bd
    for _, z in ipairs(Grown(seed)) do
        local d = z.pos:DistToSqr(seed.pos)
        if not bd or d > bd then best, bd = z, d end
    end
    return best
end

hook.Add("OnNPCKilled", "LivingCityTerritory", function(npc, attacker)
    if not cvOn:GetBool() then return end
    local st = LC.NPCs and LC.NPCs[npc]
    if not st then return end
    local kind = (st.role == "rebel" and "rebel") or (st.role == "zombie" and "infest") or nil
    if not kind then return end
    -- the territory's own side doesn't count: a rebel shot by a rebel, a zombie by a zombie
    if IsValid(attacker) then
        if attacker:IsPlayer() then
            if kind == "rebel" and attacker:GetNW2String("lcf_faction", "") == "resistance" then return end
            if kind == "infest" and LC.PlayerIsZombie and LC.PlayerIsZombie(attacker) then return end
        else
            local ast = LC.NPCs[attacker]
            if ast and ((kind == "rebel" and ast.role == "rebel") or (kind == "infest" and ast.role == "zombie")) then return end
        end
    end
    local seed, z = SeedAt(npc:GetPos(), kind, 250)
    if not seed then return end
    local s = StateOf(seed)
    local now = CurTime()
    -- a checkpoint's turrets hold the line: it doesn't grow while they're shooting, but it isn't
    -- pushed back either (units have to go in for that), and nobody's told about every kill
    if IsValid(attacker) and LC.IsCheckpointTurret and LC.IsCheckpointTurret(attacker) then
        s.lastHit = now
        s.nextGrow = math.max(s.nextGrow, now + cvCalm:GetFloat() * 60)
        return
    end
    -- nobody new turns up mid-fight in a patch someone is clearing
    if z then z.contestedUntil = now + 90 end
    s.hits, s.lastHit = s.hits + 1, now
    s.nextGrow = math.max(s.nextGrow, now + cvCalm:GetFloat() * 60)
    -- a patch with nobody left in it falls straight away
    local role = kind == "rebel" and "rebel" or "zombie"
    local by = IsValid(attacker) and attacker:IsPlayer() and attacker or nil
    timer.Simple(0.5, function()
        if z and z.grown and LivingIn(z, role) == 0 then
            LC.RecedeTerritory(z, "cleared out", by)
            s.hits = 0
        elseif s.hits >= math.max(1, cvHits:GetInt()) then
            s.hits = 0
            LC.RecedeTerritory(Outermost(seed), "pushed back", by)
        end
    end)
end)

------------------------------------------------------------------------
-- Containment pay: units who put the infested down are paid for it, in
-- credits and in rounds for the weapon they did it with, once the shooting
-- stops (or the patch is contained). lc_containment_pay (3 credits a kill),
-- lc_containment_ammo 0/1.
------------------------------------------------------------------------

local cvPay  = CreateConVar("lc_containment_pay", "3", FLAGS, "Credits a Civil Protection unit is paid for each infested they put down")
local cvAmmo = CreateConVar("lc_containment_ammo", "1", FLAGS, "Civil Protection units are resupplied with rounds for the infested they put down")
local PER_KILL = { Pistol = 8, SMG1 = 15, Buckshot = 3, AR2 = 10, ["357"] = 2, XBowBolt = 1 }
LC.ContainmentTally = LC.ContainmentTally or {} -- [ply] = { kills, ammo = { [type] = kills }, last }

local function IsInfested(npc, st)
    if st and st.role == "zombie" then return true end
    local c = npc:GetClass()
    return string.find(c, "zombie", 1, true) ~= nil or string.find(c, "headcrab", 1, true) ~= nil
end

function LC.PayContainment(ply)
    local t = LC.ContainmentTally[ply]
    LC.ContainmentTally[ply] = nil
    if not t or not IsValid(ply) or t.kills <= 0 then return end
    local credits = math.min(60, t.kills * cvPay:GetInt())
    local parts = {}
    if credits > 0 and LC.AddCredits then LC.AddCredits(ply, credits) parts[#parts + 1] = "+" .. credits .. " credits" end
    if cvAmmo:GetBool() then
        for ammo, n in pairs(t.ammo) do
            local rounds = math.min(6, n) * (PER_KILL[ammo] or 8)
            if rounds > 0 then
                ply:GiveAmmo(rounds, ammo, true)
                parts[#parts + 1] = rounds .. " " .. string.lower(ammo == "SMG1" and "SMG" or ammo) .. " rounds"
            end
        end
    end
    if #parts > 0 then
        ply:ChatPrint(string.format("[Civil Protection] Containment pay: %d infested put down. %s.", t.kills, table.concat(parts, ", ")))
    end
end

hook.Add("OnNPCKilled", "LivingCityContainmentPay", function(npc, attacker)
    if not IsValid(attacker) or not attacker:IsPlayer() or not LC.PlayerIsCP(attacker) then return end
    if not IsInfested(npc, LC.NPCs and LC.NPCs[npc]) then return end
    local t = LC.ContainmentTally[attacker] or { kills = 0, ammo = {} }
    LC.ContainmentTally[attacker] = t
    t.kills, t.last = t.kills + 1, CurTime()
    local w = attacker:GetActiveWeapon()
    local ammo = IsValid(w) and w.GetPrimaryAmmoType and game.GetAmmoName and game.GetAmmoName(w:GetPrimaryAmmoType()) or nil
    if ammo then t.ammo[ammo] = (t.ammo[ammo] or 0) + 1 end
end)

-- containing a patch pays everyone who helped, straight away
hook.Add("LivingCityTerritoryReceded", "LivingCityContainmentPay", function(seed, z)
    if z and z.kind == "infest" then for p in pairs(LC.ContainmentTally) do LC.PayContainment(p) end end
end)

timer.Create("LivingCityContainmentPay", 5, 0, function()
    local now = CurTime()
    for p, t in pairs(LC.ContainmentTally) do
        if not IsValid(p) then LC.ContainmentTally[p] = nil
        elseif now - (t.last or now) > 60 then LC.PayContainment(p) end
    end
end)

------------------------------------------------------------------------
-- Ticking
------------------------------------------------------------------------

-- Due to grow but couldn't (nobody holding it, nowhere to go, fought over): tried again
-- this soon, not a whole lc_rebel_spread_minutes later, so it grows as soon as it can.
local RETRY = 60

-- One territory's turn to grow. Returns the patch, or nil and why not (also kept in its
-- state, for lc_territory and the admin tools).
local function TryGrow(cluster, now)
    local s = StateOf(cluster[1])
    local role = cluster[1].kind == "rebel" and "rebel" or "zombie"
    local lastHit, held = -1e9, {}
    for _, seed in ipairs(cluster) do
        lastHit = math.max(lastHit, StateOf(seed).lastHit)
        local n = 0
        for _, z in ipairs(Family(seed)) do n = n + LivingIn(z, role) end
        if n > 0 then held[#held + 1] = seed end
    end
    local grew, why
    -- only while unchallenged, and only from where someone actually holds it
    if now - lastHit < cvCalm:GetFloat() * 60 then
        why = "it was fought over in the last " .. cvCalm:GetInt() .. " minutes (lc_territory_calm)"
    elseif #held == 0 then
        why = role == "rebel" and "no Resistance fighters are in it to hold it" or "nothing infested is in it to spread it"
    elseif not LC.TerritoryCanGrow(cluster[1]) then
        why = "it's as big as it gets (lc_territory_max, lc_infest_max, lc_territory_city_max)"
    else
        for i = #held, 2, -1 do local j = math.random(i) held[i], held[j] = held[j], held[i] end
        for _, seed in ipairs(held) do
            local whyNot
            grew, whyNot = LC.GrowTerritory(seed)
            if grew then break end
            why = why or whyNot
        end
    end
    s.lastTry, s.lastWhy = now, (not grew) and why or nil
    return grew, why
end
LC.TerritoryTryGrow = TryGrow

timer.Create("LivingCityTerritory", 10, 0, function()
    local ok, err = pcall(function()
        if not LC.Running or not cvOn:GetBool() then return end
        local now = CurTime()
        -- one growth at a time per territory (a cluster of touching zones), not per zone
        for _, cluster in ipairs(Clusters()) do
            local s = StateOf(cluster[1])
            if now >= s.nextGrow then
                local grew = TryGrow(cluster, now)
                s.nextGrow = now + (grew and Interval(cluster[1].kind) or RETRY)
            end
        end
    end)
    if not ok then LC.Error("territory", err) end
end)

-- Grow one territory of this kind now, whatever the clock says (the admin tools and
-- lc_territory_grow). Returns the patch, or nil and why not.
function LC.TerritoryGrowNow(kind)
    local cands = {}
    for _, seed in ipairs(Seeds()) do if seed.kind == kind then cands[#cands + 1] = seed end end
    if #cands == 0 then return nil, "no " .. (kind == "rebel" and "rebel" or "infestation") .. " zones are placed" end
    for i = #cands, 2, -1 do local j = math.random(i) cands[i], cands[j] = cands[j], cands[i] end
    local why
    for _, seed in ipairs(cands) do
        local z, whyNot = LC.GrowTerritory(seed, nil, nil, "staff")
        if z then
            local s = StateOf(ClusterOf(seed)[1])
            s.nextGrow = CurTime() + Interval(kind)
            return z
        end
        why = why or whyNot
    end
    return nil, why
end

-- How each territory is doing, a line each (lc_territory, the admin tools).
function LC.TerritoryStatus(kind)
    local out = {}
    for _, cluster in ipairs(Clusters()) do
        local seed = cluster[1]
        if not kind or seed.kind == kind then
            local s = StateOf(seed)
            local n = ClusterGrown(cluster)
            local due = math.max(0, math.floor(s.nextGrow - CurTime()))
            out[#out + 1] = string.format("%s %s: %d patch%s grown (most %d), next growth %s, %d hit%s since the last push-back%s",
                seed.kind == "rebel" and "Rebel ground" or "Infestation", LC.DescribePlace and LC.DescribePlace(seed.pos) or tostring(seed.pos),
                n, n == 1 and "" or "es", MaxFor(seed.kind), due > 0 and ("in " .. (due >= 120 and (math.floor(due / 60) .. " min") or (due .. "s"))) or "due now",
                s.hits, s.hits == 1 and "" or "s", s.lastWhy and (". Last try didn't grow: " .. s.lastWhy) or "")
        end
    end
    return out
end

------------------------------------------------------------------------
-- Commands
------------------------------------------------------------------------

local function Say(ply, msg) if IsValid(ply) then ply:ChatPrint(msg) else print(msg) end end
local function Admin(ply) return not IsValid(ply) or ply:IsAdmin() end

concommand.Add("lc_territory", function(ply)
    if not Admin(ply) then return end
    local lines = LC.TerritoryStatus()
    if #lines == 0 then return Say(ply, "[Living City] No rebel or infestation zones placed.") end
    for _, l in ipairs(lines) do Say(ply, "[Living City] " .. l) end
end)

concommand.Add("lc_territory_grow", function(ply, _, args)
    if not Admin(ply) then return end
    local kind = string.lower(args[1] or "")
    if not KINDS[kind] then return Say(ply, "[Living City] Usage: lc_territory_grow rebel|infest") end
    local z, why = LC.TerritoryGrowNow(kind)
    Say(ply, z and ("[Living City] Grew " .. kind .. " territory " .. (z.where or "")
        .. (z.cells and " (along the path nodes)" or " (a round patch: no path nodes near it)"))
        or ("[Living City] Couldn't grow: " .. tostring(why)))
end)

concommand.Add("lc_territory_reset", function(ply)
    if not Admin(ply) then return end
    local n = 0
    for i = #LC.Zones, 1, -1 do
        if LC.Zones[i].grown then table.remove(LC.Zones, i) n = n + 1 end
    end
    LC.TerritoryState = {}
    Changed()
    Say(ply, "[Living City] Took back " .. n .. " grown patch" .. (n == 1 and "" or "es") .. ". Only the zones you placed are left.")
end)
