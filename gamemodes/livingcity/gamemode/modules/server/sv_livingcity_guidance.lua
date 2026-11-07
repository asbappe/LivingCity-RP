--[[
    Living City: guidance

    The quest trail. While you have a quest, a trail of chevrons on the
    ground leads you to where it wants you (cl_livingcity_trail.lua draws it).
    The way is worked out here, over the same paths the city's people walk:
      1. the paths drawn in the editor (LC.EditorRoute, sv_livingcity_paths.lua)
      2. the map's own nodegraph (LC.NavPathPoints, sv_livingcity_navgraph.lua)
      3. the map's navmesh, if it has one
      4. failing all that, straight there
    It's sent again when the objective moves, when you wander off it (more
    than STRAY units from the line), and every REFRESH seconds while you're
    on the move. No more than BUDGET ways are worked out a second, whoever
    is waiting, so it stays cheap with a full server.

      lc_trail          1: players can have the trail (each can hide theirs in
                        C > Settings, lc_trail_show on their side); 0: off for everyone

    Where you are (lc_here on each player: rebel, infest, home, combine,
    prison, nogo, block, or nothing), for the panel of what you can do
    (cl_livingcity_context.lua).
]]

if CLIENT then return end

LC = LC or {}

util.AddNetworkString("lc_trail")

local cvOn = CreateConVar("lc_trail", "1", FCVAR_ARCHIVE,
    "The quest trail on the ground, leading to the quest's objective: 1 players can have it (each can hide theirs in C > Settings), 0 off for everyone", 0, 1)

local REFRESH = 10    -- seconds before the way is worked out again, if you've moved
local STRAY = 300     -- this far off the line, and it's worked out again at once
local MOVED = 160     -- the objective (or you) moved this far
local ARRIVE = 120    -- this close to the objective, there's no trail
local BUDGET = 4      -- ways worked out each second, at most
local MAX_POINTS = 96 -- the client only draws a stretch ahead; the rest comes as you go
local MERGE = 40      -- points closer together than this are one

LC.TrailConfig = { REFRESH = REFRESH, STRAY = STRAY, MOVED = MOVED, ARRIVE = ARRIVE, BUDGET = BUDGET, MAX_POINTS = MAX_POINTS }

------------------------------------------------------------------------
-- The way
------------------------------------------------------------------------

-- A* over the navmesh's areas, from centre to centre: a small binary heap,
-- and a cap on how far it looks.
local function NavMeshPath(from, to)
    if not (navmesh and navmesh.IsLoaded and navmesh.IsLoaded() and navmesh.GetNearestNavArea) then return nil end
    local a = navmesh.GetNearestNavArea(from, false, 400, false, true)
    local b = navmesh.GetNearestNavArea(to, false, 400, false, true)
    if not a or not b then return nil end
    if a == b then return { to } end
    local heap, n = {}, 0
    local function push(area, f)
        n = n + 1
        heap[n] = { area, f }
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
    local goal = b:GetCenter()
    local g, came, closed = { [a] = 0 }, {}, {}
    push(a, a:GetCenter():Distance(goal))
    local looked = 0
    while n > 0 and looked < 3000 do
        local cur = pop()
        looked = looked + 1
        if cur == b then
            local out = { to }
            cur = came[cur]
            while cur and cur ~= a do table.insert(out, 1, cur:GetCenter()) cur = came[cur] end
            return out
        end
        if not closed[cur] then
            closed[cur] = true
            local c = cur:GetCenter()
            for _, nb in ipairs(cur:GetAdjacentAreas() or {}) do
                if not closed[nb] then
                    local t = g[cur] + c:Distance(nb:GetCenter())
                    if not g[nb] or t < g[nb] then
                        g[nb], came[nb] = t, cur
                        push(nb, t + nb:GetCenter():Distance(goal))
                    end
                end
            end
        end
    end
    return nil
end
LC._TrailNavMeshPath = NavMeshPath -- (for the tests)

-- Points too close together are one; a long way is cut short (the rest comes as you walk it).
local function Tidy(pts, from)
    local out, last = {}, from
    for i, p in ipairs(pts) do
        if i == #pts or not last or p:DistToSqr(last) > MERGE * MERGE then
            out[#out + 1] = p
            last = p
        end
        if #out >= MAX_POINTS then break end
    end
    return out
end

-- The way from `from` to `to`, as a list of points ending at `to` (never empty).
function LC.TrailRoute(from, to, role)
    local pts
    if LC.EditorRoute then
        local r = LC.EditorRoute(from, to, role)
        if type(r) == "table" and #r > 0 then pts = r end
    end
    if not pts and LC.NavPathPoints then
        local r = LC.NavPathPoints(from, to, role)
        if type(r) == "table" and #r > 0 then pts = r end
    end
    if not pts then
        local ok, r = pcall(NavMeshPath, from, to)
        if ok and type(r) == "table" and #r > 0 then pts = r end
    end
    return Tidy(pts or { to }, from)
end

local function RoleOf(ply)
    if LC.PlayerIsZombie and LC.PlayerIsZombie(ply) then return "zombie" end
    if LC.PlayerIsCP and LC.PlayerIsCP(ply) then return "cop" end
    return "citizen"
end

-- How far pos is from the trail: the line from where it was worked out, through its points.
local function SegDist2(p, a, b)
    local ab = b - a
    local len2 = ab:LengthSqr()
    local t = len2 > 0 and math.Clamp((p - a):Dot(ab) / len2, 0, 1) or 0
    return p:DistToSqr(a + ab * t)
end
function LC.TrailDistance(trail, pos)
    if not trail or not trail.pts or #trail.pts == 0 then return math.huge end
    local best, prev = math.huge, trail.from or trail.pts[1]
    for _, p in ipairs(trail.pts) do
        best = math.min(best, SegDist2(pos, prev, p))
        prev = p
    end
    return math.sqrt(best)
end

-- Does this player's trail need working out again?
function LC.TrailNeedsRefresh(trail, pos, goal, now)
    if not trail then return true end
    if trail.goal:DistToSqr(goal) > MOVED * MOVED then return true end
    if LC.TrailDistance(trail, pos) > STRAY then return true end
    if now - (trail.at or 0) > REFRESH and pos:DistToSqr(trail.from or pos) > MOVED * MOVED then return true end
    return false
end

function LC.SendTrail(ply, trail)
    if not trail then
        LC.SendCompressed("lc_trail", {}, { ply })
        return
    end
    local flat = {}
    for _, p in ipairs(trail.pts) do
        flat[#flat + 1] = math.floor(p.x)
        flat[#flat + 1] = math.floor(p.y)
        flat[#flat + 1] = math.floor(p.z)
    end
    local g = trail.goal
    LC.SendCompressed("lc_trail", { g = { math.floor(g.x), math.floor(g.y), math.floor(g.z) }, p = flat }, { ply })
end

function LC.TrailRefresh(ply, goal, now)
    local from = ply:GetPos()
    local trail = { goal = goal, from = from, at = now or CurTime(), pts = LC.TrailRoute(from, goal, RoleOf(ply)) }
    ply.lcTrail = trail
    LC.SendTrail(ply, trail)
    return trail
end

-- Wants one: the server allows it, they haven't hidden theirs, and they're alive.
function LC.TrailWanted(ply)
    if not cvOn:GetBool() or not IsValid(ply) or not ply:Alive() then return false end
    if ply.GetInfoNum and ply:GetInfoNum("lc_trail_show", 1) == 0 then return false end
    -- (Breen's water has clouded their memory: no trail either, as the quest tracker shows nothing)
    if (ply.lcForgetUntil or 0) > CurTime() then return false end
    return true
end

function LC.TrailTick(now)
    now = now or CurTime()
    local budget = BUDGET
    for _, ply in ipairs(player.GetAll()) do
        local goal = LC.TrailWanted(ply) and LC.QuestObjectivePos and LC.QuestObjectivePos(ply) or nil
        local trail = ply.lcTrail
        if not goal or ply:GetPos():DistToSqr(goal) < ARRIVE * ARRIVE then
            if trail then
                ply.lcTrail = nil
                LC.SendTrail(ply, nil)
            end
        elseif budget > 0 and LC.TrailNeedsRefresh(trail, ply:GetPos(), goal, now) then
            budget = budget - 1
            LC.TrailRefresh(ply, goal, now)
        end
    end
end

timer.Create("LivingCityTrail", 1, 0, function()
    local ok, err = pcall(LC.TrailTick, CurTime())
    if not ok and LC.Error then LC.Error("quest trail", err) end
end)

------------------------------------------------------------------------
-- Where you are (for the panel of what you can do)
------------------------------------------------------------------------

function LC.WhereKind(ply)
    if LC.PlayerInOwnBlock and LC.PlayerInOwnBlock(ply) == true then return "home" end
    local z = LC.ZoneAt and LC.ZoneAt(ply:GetPos())
    return z and z.kind or ""
end

timer.Create("LivingCityWhereAmI", 1, 0, function()
    for _, ply in ipairs(player.GetAll()) do
        local ok, kind = pcall(LC.WhereKind, ply)
        kind = (ok and kind) or ""
        if ply:GetNW2String("lc_here", "") ~= kind then ply:SetNW2String("lc_here", kind) end
    end
end)
