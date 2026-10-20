--[[
    Living City (core)

    Populates a map with ambient citizens, Civil Protection, Overwatch soldiers,
    scanners and (in infestation zones) zombies, and runs their routines:

      citizens   wander, loiter, sit, lean, chat, join ration lines, arrive from
                 and leave through spawn points, get stopped and sometimes arrested
      cops       walk patrol beats or random patrols, man checkpoints, inspect
                 citizens, tell players to move along, escort prisoners
      soldiers   patrol and hold checkpoints
      scanners   drift around following citizens
      zombies    live inside infestation zones and stay there

    Movement goes through the path network (sv_livingcity_paths.lua) when one
    exists, and recovers from getting stuck when nobody is looking.

    Other modules: data (saving), paths, doors, law (who's CP, who's wanted),
    events (announcements, rations, curfew), prison, factions.
]]

if CLIENT then return end

LC = LC or {}
LC.VERSION = "2.5"
LC.NPCs = LC.NPCs or {}         -- [entity] = state table
LC.Points = LC.Points or {}
LC.Fallback = LC.Fallback or {} -- wander spots from the map's nodegraph or navmesh
LC.Source = LC.Source or "none"
LC.Running = LC.Running or false
LC.Lines = LC.Lines or {}       -- [group] = { slots = {points}, q = {npcs}, nextAdvance }
LC.Occupied = LC.Occupied or {} -- [point] = entity using it

local FLAGS = bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED)
local cvCitizens  = CreateConVar("lc_citizens", "14", FLAGS, "Target number of ambient citizens")
local cvCops      = CreateConVar("lc_cops", "4", FLAGS, "Target number of ambient Civil Protection")
local cvSoldiers  = CreateConVar("lc_soldiers", "0", FLAGS, "Target number of Overwatch soldiers")
local cvScanners  = CreateConVar("lc_scanners", "1", FLAGS, "Target number of city scanners")
local cvZombies   = CreateConVar("lc_zombies", "6", FLAGS, "Zombies kept alive across infestation zones")
local cvZomMax    = CreateConVar("lc_zombies_max", "50", FLAGS, "Most zombies alive at once, however far the infestation has spread")

-- How many of the infested the city keeps: the usual number, plus one for each
-- patch it's spread to, never more than lc_zombies_max.
function LC.ZombieTarget()
    local grown = LC.GrownCount and LC.GrownCount("infest") or 0
    return math.min(cvZombies:GetInt() + grown, math.max(cvZombies:GetInt(), cvZomMax:GetInt()))
end
local cvAutostart = CreateConVar("lc_autostart", "0", FLAGS, "Start Living City automatically on map load")
local cvSpawnDist = CreateConVar("lc_spawn_mindist", "900", FLAGS, "Random spawns happen at least this far from players")
local cvLifetime  = CreateConVar("lc_citizen_lifetime", "600", FLAGS, "Average seconds a citizen stays before going home (0 = forever)")
local cvArrestChance = CreateConVar("lc_npc_arrest_chance", "8", FLAGS, "Percent chance an inspection ends with the citizen being taken to a cell")
local cvBudget    = CreateConVar("lc_npc_budget", "60", FLAGS, "Hard cap on Living City NPCs, whatever the individual targets say")
local cvLodDist   = CreateConVar("lc_lod_distance", "3500", FLAGS, "NPCs farther than this from every player think less often")
local cvRebelPursuit = CreateConVar("lc_rebel_pursuit", "0", FLAGS, "Security NPCs chase people into rebel zones")

local SF_NPC_GAG                 = 2     -- no idle chatter (no "Hey, Doctor Freeman!")
local SF_NPC_FADE_CORPSE         = 512
local SF_NPC_NO_WEAPON_DROP      = 8192
local SF_CITIZEN_NOT_COMMANDABLE = 1048576
local SF_SCRIPT_LOOP_IN_POST_IDLE = 256
local SF_SCRIPT_NO_COMPLAINTS     = 2048
local SF_SCRIPT_ALLOW_DEATH       = 4096

local UP = Vector(0, 0, 50)

------------------------------------------------------------------------
-- Log (read by lc_debugreport; see sv_livingcity_debug.lua)
------------------------------------------------------------------------

LC.LogBuffer = LC.LogBuffer or {}
LC.Perf = LC.Perf or { samples = 0, total = 0, max = 0 }

-- The whole server frame (the engine's NPC AI, physics and networking, not
-- just Living City's Lua): how long between ticks, against how long a tick
-- should take. Behind is what players feel as rubber-banding.
LC.Frame = LC.Frame or { n = 0, total = 0, worst = 0, slow = 0 }
local lastTick
hook.Add("Tick", "LivingCityFrameTime", function()
    local now = SysTime()
    if lastTick then
        local f, dt = LC.Frame, (now - lastTick) * 1000
        f.n, f.total = f.n + 1, f.total + dt
        if dt > f.worst then f.worst = dt end
        if dt > engine.TickInterval() * 1000 * 1.5 then f.slow = f.slow + 1 end
    end
    lastTick = now
end)

function LC.Log(level, msg)
    local buf = LC.LogBuffer
    buf[#buf + 1] = string.format("[%s %7.1f] %-5s %s", os.date("%H:%M:%S"), CurTime(), level, tostring(msg))
    if #buf > 300 then table.remove(buf, 1) end
    local dbg = GetConVar("lc_debug")
    if level == "error" or (dbg and dbg:GetBool()) then print("[Living City] " .. level .. ": " .. tostring(msg)) end
end

function LC.Error(where, err)
    LC.Log("error", where .. ": " .. tostring(err))
    ErrorNoHalt("[Living City] " .. where .. ": " .. tostring(err) .. "\n")
end

-- Is this sound file on the server's disk (and so, very likely, the
-- players')? A sound that isn't makes every player near it search their whole
-- install for it each time it plays, which can freeze a frame on a game with
-- a lot of addons, and prints "Failed to load sound" in their console. Script
-- sounds (no file extension) are always taken as there. Cached.
local soundKnown = {}
function LC.SoundExists(path)
    if type(path) ~= "string" or path == "" then return false end
    local clean = string.lower(string.gsub(string.gsub(path, "^[%*#@<>%^%)}%$!%?]+", ""), "\\", "/"))
    local ext = string.match(clean, "%.(%w+)$")
    if ext ~= "wav" and ext ~= "mp3" and ext ~= "ogg" then return true end
    if LC.TestMode or not (file and file.Exists) then return true end
    local known = soundKnown[clean]
    if known == nil then
        known = file.Exists("sound/" .. clean, "GAME") == true
        soundKnown[clean] = known
        if not known then LC.Log("warn", "sound missing from this install, not played: " .. clean) end
    end
    return known
end

-- The first of these sounds that's there (or nil).
function LC.FirstSound(list)
    for _, s in ipairs(type(list) == "table" and list or { list }) do
        if LC.SoundExists(s) then return s end
    end
end

-- Every sound the server plays goes through it, ours or not.
do
    local EM = FindMetaTable and FindMetaTable("Entity")
    if EM and EM.EmitSound and not EM.lcSoundChecked then
        local emit = EM.EmitSound
        EM.lcSoundChecked = true
        EM.EmitSound = function(self, snd, ...)
            if not LC.SoundExists(snd) then return end
            return emit(self, snd, ...)
        end
    end
    if sound and sound.Play and not LC.lcSoundPlayChecked then
        local play = sound.Play
        LC.lcSoundPlayChecked = true
        sound.Play = function(snd, ...)
            if not LC.SoundExists(snd) then return end
            return play(snd, ...)
        end
    end
end

------------------------------------------------------------------------
-- Sounds
------------------------------------------------------------------------

local function Vo(gender, name) return "vo/npc/" .. gender .. "01/" .. name .. ".wav" end

local COP_APPROACH = { "npc/metropolice/vo/citizen.wav", "npc/metropolice/vo/apply.wav" }
local COP_RELEASE  = { "npc/metropolice/vo/movealong.wav", "npc/metropolice/vo/movealong3.wav", "npc/metropolice/vo/keepmoving.wav" }
local COP_WARN     = { "npc/metropolice/vo/movealong3.wav", "npc/metropolice/vo/firstwarningmove.wav", "npc/metropolice/vo/keepmoving.wav" }
local COP_ARREST   = { "npc/metropolice/vo/holdit.wav", "npc/metropolice/vo/dontmove.wav" }
local CIT_GREET    = { "hi01", "hi02", "excuseme01", "excuseme02" }
local CIT_NERVOUS  = { "sorry01", "sorry02", "sorry03" }
local CIT_BARK     = { "excuseme01", "excuseme02", "pardonme01", "pardonme02" }
local CIT_PROTEST  = { "no01", "no02" }
local SERVE_SOUND  = "items/ammo_pickup.wav"

LC.Sounds = {
    COP_WARN = COP_WARN, COP_ARREST = COP_ARREST,
    Vo = Vo,
}

------------------------------------------------------------------------
-- Helpers
------------------------------------------------------------------------

local function Pick(t) return t[math.random(#t)] end
LC.Pick = Pick

function LC.Face(npc, pos)
    if npc.SetIdealYawAndUpdate then npc:SetIdealYawAndUpdate((pos - npc:GetPos()):Angle().y) end
end

function LC.FaceYaw(npc, yaw)
    if yaw and npc.SetIdealYawAndUpdate then npc:SetIdealYawAndUpdate(yaw) end
end

local Face, FaceYaw = LC.Face, LC.FaceYaw

local function Say(ply, msg)
    if IsValid(ply) then ply:ChatPrint("[Living City] " .. msg) else print("[Living City] " .. msg) end
end
LC.Say = Say

local function Allowed(ply) return LC.CanEdit(ply) end

local function FarFromPlayers(pos, dist)
    local d2 = dist * dist
    for _, ply in ipairs(player.GetAll()) do
        if ply:GetPos():DistToSqr(pos) < d2 then return false end
    end
    return true
end
LC.FarFromPlayers = FarFromPlayers

-- Could any living player see this spot right now?
function LC.IsSeen(pos)
    for _, ply in ipairs(player.GetAll()) do
        if ply:Alive() then
            local eye = ply:EyePos()
            local dir = pos - eye
            local d2 = dir:LengthSqr()
            if d2 < 80 * 80 then return true end
            if d2 < 6000 * 6000 then
                dir:Normalize()
                if dir:Dot(ply:GetAimVector()) > 0.4 then
                    local tr = util.TraceLine({ start = eye, endpos = pos, mask = MASK_OPAQUE, filter = ply })
                    if tr.Fraction > 0.97 then return true end
                end
            end
        end
    end
    return false
end

local function ClearSpot(pos)
    local tr = util.TraceHull({
        start = pos + Vector(0, 0, 10), endpos = pos + Vector(0, 0, 10),
        mins = Vector(-16, -16, 0), maxs = Vector(16, 16, 72),
        mask = MASK_NPCSOLID,
    })
    return not tr.Hit and not tr.StartSolid
end
LC.ClearSpot = ClearSpot

local function SetState(npc, st, state)
    if st.state ~= state then
        st.state = state
        if IsValid(npc) then npc:SetNW2String("lc_state", state) end
    end
end
LC.SetState = SetState

local function IsSecurity(st) return st.role == "cop" or st.role == "soldier" end
LC.IsSecurity = IsSecurity

-- Relationship toward a player, only touching the engine when it changes.
-- With 100+ players this saves thousands of engine calls every few seconds.
local function SetRel(npc, st, ply, disp)
    st.rel = st.rel or setmetatable({}, { __mode = "k" })
    if st.rel[ply] ~= disp then
        st.rel[ply] = disp
        npc:AddEntityRelationship(ply, disp, 99)
    end
end
LC.SetRel = SetRel

------------------------------------------------------------------------
-- Points and claims
------------------------------------------------------------------------

-- Points by kind, rebuilt only when the list of points changes (an edit, a layout loaded).
local pc = {}
local NONE = {}
local function PointIndex()
    local ps = LC.Points
    local n = #ps
    if pc.tbl ~= ps or pc.n ~= n or pc.first ~= ps[1] or pc.last ~= ps[n] then
        local by = {}
        for _, p in ipairs(ps) do
            local l = by[p.kind]
            if not l then l = {} by[p.kind] = l end
            l[#l + 1] = p
        end
        pc.tbl, pc.n, pc.first, pc.last, pc.by = ps, n, ps[1], ps[n], by
    end
    return pc.by
end

-- Your own list of the points of a kind (and group), in the order they were placed.
local function PointsOfKind(kind, group)
    local out = {}
    for _, p in ipairs(PointIndex()[kind] or NONE) do
        if group == nil or (p.group or 0) == group then out[#out + 1] = p end
    end
    return out
end
LC.PointsOfKind = PointsOfKind
-- How many there are, without making a list.
function LC.CountPointsOfKind(kind) return #(PointIndex()[kind] or NONE) end

function LC.ClaimHolderValid(p)
    local occ = LC.Occupied[p]
    if not IsValid(occ) then return false end
    local st = LC.NPCs[occ]
    if st and st.claim == p then return true end
    local pr = LC.Prisoners and LC.Prisoners[occ]
    return pr ~= nil and pr.cell == p
end

local function IsFree(p, who)
    local occ = LC.Occupied[p]
    return occ == nil or occ == who or not LC.ClaimHolderValid(p)
end
LC.IsPointFree = IsFree

local function FreePoints(kinds, who, looseOnly)
    local out, now, by = {}, CurTime(), PointIndex()
    for kind in pairs(kinds) do
        for _, p in ipairs(by[kind] or NONE) do
            if IsFree(p, who) and (not looseOnly or (p.group or 0) == 0) and (p.disabledUntil or 0) < now then out[#out + 1] = p end
        end
    end
    return out
end
LC.FreePoints = FreePoints

local function Release(npc, st)
    if st.claim then
        if LC.Occupied[st.claim] == npc then LC.Occupied[st.claim] = nil end
        st.claim = nil
    end
end

local function Claim(npc, st, p)
    Release(npc, st)
    st.claim = p
    LC.Occupied[p] = npc
end
LC.Claim = Claim
LC.Release = Release

-- Patrol points of one beat, in the order they were placed.
function LC.RoutePoints(group) return PointsOfKind("patrol", group) end

local function PatrolGroups()
    local seen, out = {}, {}
    for _, p in ipairs(LC.Points) do
        local g = p.group or 0
        if p.kind == "patrol" and g > 0 and not seen[g] then seen[g] = true; out[#out + 1] = g end
    end
    return out
end

------------------------------------------------------------------------
-- Wandering spots: the map's nodegraph or navmesh, plus our path nodes
------------------------------------------------------------------------

-- Reads ground nodes from the map's AI nodegraph (.ain), if the mapper placed nodes.
-- Big maps have plenty of nodes NPCs can never walk to (rooftops, sealed
-- interiors, lone nodes), so only the largest connected area is used.
-- Otherwise people constantly set off for places they can't reach.
--
-- The file also lists the links between nodes, and which body sizes can walk
-- each one. Those for a person on foot become LC.NavGraph, which
-- sv_livingcity_navgraph.lua plans routes over: the engine is then only asked
-- to walk short legs, which it manages, instead of crossing the map in one go,
-- which on multi-level maps it often can't. Without links (older files), the
-- engine's own zones decide what's connected.
local AI_NODE_FIRST_ZONE = 4
local NUM_HULLS, HULL_HUMAN, CAP_MOVE_GROUND = 10, 0, 1

local function ReadNodegraph()
    LC.NavGraph = nil
    local f = file.Open("maps/graphs/" .. game.GetMap() .. ".ain", "rb", "GAME")
    if not f then return {}, nil end
    local nodes, byIndex = {}, {}
    local links
    local ok = pcall(function()
        if f:ReadLong() ~= 37 then error("unsupported nodegraph version") end
        f:ReadLong() -- map revision
        local n = f:ReadLong()
        if n <= 0 or n > 20000 then error("bad node count") end
        for i = 0, n - 1 do
            local x, y, z = f:ReadFloat(), f:ReadFloat(), f:ReadFloat()
            f:ReadFloat()                         -- yaw
            for _ = 1, NUM_HULLS do f:ReadFloat() end -- hull offsets
            local nodeType = f:ReadByte()
            f:ReadUShort()                        -- info
            local zone = f:ReadShort()
            if nodeType == 2 then -- ground node
                local nd = { pos = Vector(x, y, z), zone = zone, adj = {} }
                nodes[#nodes + 1] = nd
                byIndex[i] = nd
            end
        end
        -- the links: whoever can walk between which nodes
        local okL = pcall(function()
            local count = f:ReadLong()
            if not count or count < 0 or count > 200000 then error("no links") end
            local list = {}
            for _ = 1, count do
                local a, b = f:ReadShort(), f:ReadShort()
                local moves = 0
                for h = 0, NUM_HULLS - 1 do
                    local m = f:ReadByte()
                    if h == HULL_HUMAN then moves = m end
                end
                list[#list + 1] = { a, b, moves }
            end
            links = list
        end)
        if not okL then links = nil end
    end)
    f:Close()
    if not ok then return {}, nil end

    local main
    if links then
        local walkable = 0
        for _, l in ipairs(links) do
            local a, b = byIndex[l[1]], byIndex[l[2]]
            if a and b and bit.band(l[3], CAP_MOVE_GROUND) ~= 0 then
                local d = a.pos:Distance(b.pos)
                a.adj[#a.adj + 1] = { b, d }
                b.adj[#b.adj + 1] = { a, d }
                walkable = walkable + 1
            end
        end
        -- connected areas for a person on foot
        local comps, sizes = 0, {}
        for _, nd in ipairs(nodes) do
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
        if walkable > 0 and best and bestN >= 20 then
            main = best
            LC.NavGraph = { nodes = nodes, main = main, links = walkable }
        end
    end

    local pts = {}
    if main then
        for _, nd in ipairs(nodes) do if nd.comp == main then pts[#pts + 1] = nd.pos end end
    else
        local counts = {}
        for _, nd in ipairs(nodes) do
            if nd.zone >= AI_NODE_FIRST_ZONE then counts[nd.zone] = (counts[nd.zone] or 0) + 1 end
        end
        local best, bestN = nil, 0
        for zone, c in pairs(counts) do if c > bestN then best, bestN = zone, c end end
        -- only trust the zones if the main area is a real share of the map
        if best and bestN >= math.max(20, #nodes * 0.25) then
            for _, nd in ipairs(nodes) do if nd.zone == best then pts[#pts + 1] = nd.pos end end
        else
            for _, nd in ipairs(nodes) do pts[#pts + 1] = nd.pos end
        end
    end
    if LC.NavGraphReady then LC.NavGraphReady() end
    return pts, string.format("%d of %d ground nodes, in the main connected area%s", #pts, #nodes,
        LC.NavGraph and string.format(" (%d walkable links, routes planned over them)", LC.NavGraph.links) or "")
end

local function ReadNavmesh()
    local pts = {}
    if not navmesh or not navmesh.IsLoaded() or navmesh.GetNavAreaCount() == 0 then return pts end
    for _, a in ipairs(navmesh.GetAllNavAreas()) do
        if a:GetSizeX() >= 40 and a:GetSizeY() >= 40 and not a:IsUnderwater() then
            pts[#pts + 1] = a:GetCenter()
        end
    end
    return pts
end

local function BuildFallback()
    LC.Fallback, LC.SourceDetail = ReadNodegraph()
    LC.Source = "nodegraph"
    if #LC.Fallback == 0 then
        LC.SourceDetail = nil
        LC.Fallback = ReadNavmesh()
        LC.Source = "navmesh"
    end
    if #LC.Fallback == 0 then LC.Source = "none" end
end

-- near: somewhere to stay close to. Wandering NPCs mill around where they are
-- (same level, within a few streets) instead of setting off across the map,
-- which on multi-level maps meant routes the engine couldn't walk.
function LC.RandomWanderPos(role, near)
    if near then
        for _ = 1, 25 do
            local p = LC.RandomWanderPos(role)
            if p then
                local dx, dy = p.x - near.x, p.y - near.y
                if dx * dx + dy * dy < 1600 * 1600 and math.abs(p.z - near.z) < 150
                    and not (LC.DestIsBad and LC.DestIsBad(p)) and (not LC.NavReachable or LC.NavReachable(near, p)) then
                    return p
                end
            end
        end
    end
    local pools = {}
    if #LC.Fallback > 0 then pools[#pools + 1] = LC.Fallback end
    local nodes = LC.NodePositions and LC.NodePositions(role) or {}
    if #nodes > 0 then pools[#pools + 1] = nodes end
    if #pools == 0 then
        if #LC.Points > 0 then return LC.Points[math.random(#LC.Points)].pos end
        return nil
    end
    for _ = 1, 12 do
        local pool = pools[math.random(#pools)]
        local pos = pool[math.random(#pool)]
        if (not LC.InNoGo or not LC.InNoGo(pos, role)) and not (LC.DestIsBad and LC.DestIsBad(pos)) then return pos end
    end
    return nil
end

------------------------------------------------------------------------
-- Ration lines (queue points with a line number, front placed first)
------------------------------------------------------------------------

function LC.RebuildLines()
    local old = LC.Lines or {}
    LC.Lines = {}
    for _, p in ipairs(LC.Points) do
        local g = p.group or 0
        if p.kind == "queue" and g > 0 then
            if not LC.Lines[g] then
                LC.Lines[g] = { slots = {}, q = old[g] and old[g].q or {}, nextAdvance = 0 }
            end
            table.insert(LC.Lines[g].slots, p)
        end
    end
    for g, line in pairs(old) do
        if not LC.Lines[g] then
            for _, n in ipairs(line.q) do
                local s = LC.NPCs[n]
                if s and IsValid(n) then s.line = nil; s.untilT = 0; SetState(n, s, "idle") end
            end
        end
    end
end

------------------------------------------------------------------------
-- Movement
------------------------------------------------------------------------

local Arrive, Recover -- defined below

local function IssueHop(npc, st)
    npc:SetLastPosition(st.route[st.hop])
    npc:SetSchedule(st.run and SCHED_FORCED_GO_RUN or SCHED_FORCED_GO)
end

-- Places that walkers keep failing to reach: skipped for a while when choosing
-- where to go. Keyed by a 64-unit grid square.
LC.BadDest = LC.BadDest or {}
local function DestKey(pos) return math.floor(pos.x / 64) .. ":" .. math.floor(pos.y / 64) .. ":" .. math.floor(pos.z / 64) end
function LC.DestIsBad(pos)
    local b = LC.BadDest[DestKey(pos)]
    return b ~= nil and b.n >= 2 and b.untilT > CurTime()
end
local function MarkBadDest(pos)
    local k = DestKey(pos)
    local b = LC.BadDest[k] or { n = 0 }
    b.n, b.untilT = b.n + 1, CurTime() + 600
    LC.BadDest[k] = b
end

function LC.GoTo(npc, st, pos, run, poi)
    if not pos or not IsValid(npc) then return false end
    local now = CurTime()
    local route = LC.BuildRoute and LC.BuildRoute(npc:GetPos(), pos, st.role)
    if route == false then
        -- nowhere they can walk to from here: don't set off at all
        LC.UnreachableSkips = (LC.UnreachableSkips or 0) + 1
        return false
    end
    st.dest, st.poi, st.run = pos, poi, run
    st.replans = 0
    st.route = route or { pos }
    st.hop = 1
    st.hopTries = 0
    st.giveUp = now + 30 + 12 * #st.route
    st.lastPos, st.lastMoved = npc:GetPos(), now
    SetState(npc, st, "moving")
    npc:SetNW2Vector("lc_dest", pos)
    IssueHop(npc, st)
    return true
end
local GoTo = LC.GoTo

local function NextHop(npc, st)
    st.hop = st.hop + 1
    st.hopTries = 0
    IssueHop(npc, st)
end

local function HandleMoving(npc, st, now)
    local target = st.route[st.hop]
    -- at the foot (or the top) of a ladder the route goes up: climb it (sv_livingcity_navgraph.lua)
    if LC.LadderHop and target and LC.LadderHop(npc, target) then
        if st.hop >= #st.route then return Arrive(npc, st, now) end
        return NextHop(npc, st)
    end
    local pos = npc:GetPos()
    local last = st.hop >= #st.route
    local d = pos:Distance(target)

    if d < (last and 56 or 96) then
        if last then return Arrive(npc, st, now) end
        return NextHop(npc, st)
    end

    if pos:DistToSqr(st.lastPos) > 400 then st.lastPos = pos; st.lastMoved = now end

    local going = npc:IsCurrentSchedule(SCHED_FORCED_GO) or npc:IsCurrentSchedule(SCHED_FORCED_GO_RUN)
    if not going then
        if d < 160 then
            if last then return Arrive(npc, st, now) end
            return NextHop(npc, st)
        end
        st.hopTries = st.hopTries + 1
        -- once more (someone was in the way), then the leg in single steps,
        -- then around the link that won't walk, and only then give up
        if st.hopTries <= 1 then return IssueHop(npc, st) end
        if LC.NavRefineLeg and LC.NavRefineLeg(st) then
            st.hopTries = 0
            return IssueHop(npc, st)
        end
        if (st.replans or 0) < 2 and LC.NavBlameLeg and LC.NavBlameLeg(st) and st.dest and not st.test then
            local replans = (st.replans or 0) + 1
            if GoTo(npc, st, st.dest, st.run, st.poi) then
                st.replans = replans
                if LC.NavStats then LC.NavStats.replanned = LC.NavStats.replanned + 1 end
                return
            end
            return LC.AbandonTask(npc, st, now)
        end
        return Recover(npc, st, now, "engine found no path")
    end

    if now - st.lastMoved > 7 then return Recover(npc, st, now, "no progress") end
    if now > st.giveUp then return Recover(npc, st, now, "took too long") end
end

------------------------------------------------------------------------
-- Activities: sitting, sitting on benches, leaning on walls
------------------------------------------------------------------------

local BUSY = {
    sit      = { "ACT_BUSY_SIT_GROUND_ENTRY", "ACT_BUSY_SIT_GROUND", "ACT_BUSY_SIT_GROUND_EXIT" },
    sitchair = { "ACT_BUSY_SIT_CHAIR_ENTRY", "ACT_BUSY_SIT_CHAIR", "ACT_BUSY_SIT_CHAIR_EXIT" },
    lean     = { "ACT_BUSY_LEAN_BACK_ENTRY", "ACT_BUSY_LEAN_BACK", "ACT_BUSY_LEAN_BACK_EXIT" },
}

local function SeqName(npc, actName)
    local act = _G[actName]
    if not act then return nil end
    local seq = npc:SelectWeightedSequence(act)
    if not seq or seq < 0 then return nil end
    local name = npc:GetSequenceName(seq)
    if not name or name == "" or name == "Unknown" then return nil end
    return name
end

local function MakeSequence(npc, pos, yaw, play, idle, flags, moveTo, delay)
    local ss = ents.Create("scripted_sequence")
    if not IsValid(ss) then return nil end
    ss:SetPos(pos)
    ss:SetAngles(Angle(0, yaw, 0))
    ss:SetKeyValue("m_iszEntity", npc:GetName())
    if play then ss:SetKeyValue("m_iszPlay", play) end
    if idle then ss:SetKeyValue("m_iszPostIdle", idle) end
    ss:SetKeyValue("m_fMoveTo", tostring(moveTo or 0))
    ss:SetKeyValue("spawnflags", tostring(flags or 0))
    ss:Spawn()
    ss:Activate()
    ss:Fire("BeginSequence", "", delay or 0)
    return ss
end

-- Play a one-off animation where the NPC stands. Candidates are sequence
-- names or ACT_ activity names; the first one this model actually has wins.
-- Returns true if something played.
function LC.PlayGesture(npc, candidates, holdSecs)
    if not IsValid(npc) then return false end
    for _, c in ipairs(candidates) do
        local name
        if string.StartWith(c, "ACT_") then
            name = SeqName(npc, c)
        elseif npc.LookupSequence then
            local seq = npc:LookupSequence(c)
            if seq and seq >= 0 then name = c end
        end
        if name then
            local ok, ss = pcall(MakeSequence, npc, npc:GetPos(), npc:GetAngles().y, name, nil,
                SF_SCRIPT_NO_COMPLAINTS + SF_SCRIPT_ALLOW_DEATH, 0, 0)
            if ok and IsValid(ss) then
                npc.lcGesture = ss -- cancelled if they're attacked mid-animation
                SafeRemoveEntityDelayed(ss, holdSecs or 6)
                return true
            end
        end
    end
    return false
end

-- A unit sizing someone up: the trainstation harassment and threat animations.
LC.FRISK_ANIMS = { "harassfront1", "harassfront2", "plazathreat1", "plazathreat2", "luggagewarn" }
-- The person being looked over: a flinch, or hands up and scared.
LC.FRISKED_ANIMS = { "photo_react_startle", "Fear_Reaction", "ACT_COWER" }

LC.MakeSequence, LC.BusySeqName, LC.BUSY_ACTS = MakeSequence, SeqName, BUSY

local function StartBusy(npc, st, p)
    local names = BUSY[p.kind]
    if not names then return false end
    local loop = SeqName(npc, names[2])
    if not loop then return false end
    local entry = SeqName(npc, names[1])
    local ok, ss = pcall(MakeSequence, npc, p.pos, p.yaw or 0, entry or loop, loop,
        SF_SCRIPT_LOOP_IN_POST_IDLE + SF_SCRIPT_NO_COMPLAINTS + SF_SCRIPT_ALLOW_DEATH, 1, 0)
    if not ok or not IsValid(ss) then return false end
    st.ss = ss
    st.busyKind = p.kind
    SetState(npc, st, "busy")
    st.untilT = CurTime() + math.Rand(30, 90)
    return true
end

local function EndBusy(npc, st, withExit)
    if IsValid(st.ss) then
        st.ss:Fire("CancelSequence")
        SafeRemoveEntityDelayed(st.ss, 0.5)
    end
    st.ss = nil
    if withExit and IsValid(npc) and st.busyKind then
        local exit = SeqName(npc, BUSY[st.busyKind][3])
        if exit then
            local ok, ss2 = pcall(MakeSequence, npc, npc:GetPos(), npc:GetAngles().y, exit, nil,
                SF_SCRIPT_NO_COMPLAINTS + SF_SCRIPT_ALLOW_DEATH, 0, 0.2)
            if ok and IsValid(ss2) then SafeRemoveEntityDelayed(ss2, 6) end
        end
    end
    st.busyKind = nil
end

------------------------------------------------------------------------
-- Lines
------------------------------------------------------------------------

local function SlotPoi(g, i, slot) return { kind = "lineslot", line = g, index = i, yaw = slot.yaw, pos = slot.pos } end

local function ShuffleLine(g)
    local line = LC.Lines[g]
    if not line then return end
    for i, n in ipairs(line.q) do
        local s = LC.NPCs[n]
        local slot = line.slots[i]
        if s and IsValid(n) and slot and s.slotIndex ~= i then
            s.slotIndex = i
            GoTo(n, s, slot.pos, false, SlotPoi(g, i, slot))
        end
    end
end

local function LeaveLine(npc, st)
    local g = st.line
    st.line, st.slotIndex, st.lineHeading = nil, nil, nil
    if not g or not LC.Lines[g] then return end
    local q = LC.Lines[g].q
    for i, n in ipairs(q) do
        if n == npc then
            table.remove(q, i)
            ShuffleLine(g)
            return
        end
    end
end
LC.LeaveLine = LeaveLine

-- People only queue at a line they can reasonably walk to, and take their place
-- in the order they actually arrive (not the order they decided to come).
local LINE_REACH, LINE_REACH_RATIONS = 3000, 5000

local function LineFront(line) return line.slots[1] and line.slots[1].pos end

-- Who's on their way to line g: walking there, set off in the last two
-- minutes. (Anyone who stopped, gave up or never set off isn't coming: left
-- counted, they filled the line with nobody and nobody else could join.)
local function Coming(g)
    local n, now = 0, CurTime()
    for npc, s in pairs(LC.NPCs) do
        if s.lineHeading == g then
            if IsValid(npc) and s.state == "moving" and s.poi and s.poi.kind == "lineapproach" and now - (s.lineSince or 0) < 120 then
                n = n + 1
            else
                s.lineHeading = nil
            end
        end
    end
    return n
end

-- The ration dispenser at the head of a line, if one was placed there.
function LC.LineDispenser(g)
    local line = LC.Lines[g]
    local front = line and LineFront(line)
    if not front then return nil end
    local best, bd
    for _, e in ipairs(LC.EntsOf("lc_dispenser")) do
        local d = e:GetPos():DistToSqr(front)
        if d < 260 * 260 and (not bd or d < bd) then best, bd = e, d end
    end
    return best
end

local function JoinLine(npc, st, anywhere)
    local reach = LC.Event == "rations" and LINE_REACH_RATIONS or LINE_REACH
    local pos = npc:GetPos()
    local options = {}
    for g, line in pairs(LC.Lines) do
        local front = LineFront(line)
        local disp = front and LC.LineDispenser(g)
        if front and #line.q + Coming(g) < #line.slots and (anywhere or pos:DistToSqr(front) < reach * reach)
            and not (IsValid(disp) and disp:GetNW2Bool("lc_nopower", false)) then -- (a dead dispenser: no point queueing)
            options[#options + 1] = g
        end
    end
    if #options == 0 then return false end
    local g = Pick(options)
    local line = LC.Lines[g]
    local back = line.slots[math.min(#line.q + 1, #line.slots)]
    st.lineHeading = g
    st.lineSince = CurTime()
    local ok = GoTo(npc, st, back.pos, false, { kind = "lineapproach", line = g, pos = back.pos, yaw = back.yaw })
    if not ok then st.lineHeading = nil end -- no way there: not coming
    return ok
end

-- Arrived at the back of the line: take the next free slot.
local function EnterQueue(npc, st, g, now)
    st.lineHeading = nil
    local line = LC.Lines[g]
    if not line or #line.q >= #line.slots or LC.Event == "curfew" or LC.Event == "lockdown" then
        st.untilT = now + math.Rand(2, 6)
        return
    end
    table.insert(line.q, npc)
    st.line = g
    st.lineSince = now
    local i = #line.q
    st.slotIndex = i
    GoTo(npc, st, line.slots[i].pos, false, SlotPoi(g, i, line.slots[i]))
end

LC.JoinLine = JoinLine

-- Test helper: straight into the queue.
LC._JoinLine = function(npc, st)
    local g = next(LC.Lines)
    if not g then return false end
    EnterQueue(npc, st, g, CurTime())
    return true
end

-- The front of a line is the end at the dispenser, whichever end of it was placed first
-- (placed from the back, the line stood the wrong way round: served at the far end).
local function OrientLine(line)
    local n = #line.slots
    if n < 2 then return end
    local a, b = line.slots[1].pos, line.slots[n].pos
    local da, db
    for _, e in ipairs(LC.EntsOf("lc_dispenser")) do
        local p = e:GetPos()
        da = math.min(da or math.huge, p:DistToSqr(a))
        db = math.min(db or math.huge, p:DistToSqr(b))
    end
    if da and db < da and db < 600 * 600 then
        local r = {}
        for i = n, 1, -1 do r[#r + 1] = line.slots[i] end
        line.slots = r
        line.reversed = not line.reversed
        return true
    end
end
LC.OrientLine = OrientLine

local function LineThink(now)
    for g, line in pairs(LC.Lines) do
        if now > (line.nextOrient or 0) then
            line.nextOrient = now + 10
            if OrientLine(line) then ShuffleLine(g) end
        end
        local changed = false
        local i = 1
        while i <= #line.q do
            local n = line.q[i]
            local s = LC.NPCs[n]
            if not IsValid(n) or not s or s.line ~= g then
                table.remove(line.q, i); changed = true
            elseif i > #line.slots then
                s.line, s.slotIndex = nil, nil
                SetState(n, s, "idle"); s.untilT = 0
                table.remove(line.q, i); changed = true
            else
                i = i + 1
            end
        end
        if changed then ShuffleLine(g) end

        -- close enough to their spot counts as there (people bunch up in lines)
        for idx, n in ipairs(line.q) do
            local s = LC.NPCs[n]
            local slot = line.slots[idx]
            if s.state == "moving" and slot and n:GetPos():DistToSqr(slot.pos) < 90 * 90 then
                n:SetSchedule(SCHED_IDLE_STAND)
                Arrive(n, s, now)
            end
        end

        local front = line.q[1]
        if front ~= line.front then line.front, line.frontSince = front, now end
        local atCounter = LC.ServePlayersAtLine and LC.ServePlayersAtLine(g, line, now)
        if atCounter then
            line.nextAdvance = math.max(line.nextAdvance, now + 2) -- someone's being served; wait your turn
        elseif front and now > line.nextAdvance then
            local fs = LC.NPCs[front]
            if fs.state == "inline" then
                local disp = LC.LineDispenser(g)
                if IsValid(disp) then
                    Face(front, disp:GetPos())
                    if LC.DispenserAnimate then LC.DispenserAnimate(disp) end
                else
                    front:EmitSound(SERVE_SOUND, 65)
                end
                hook.Run("LivingCityServed", front, g)
                fs.line, fs.slotIndex = nil, nil
                table.remove(line.q, 1)
                SetState(front, fs, "idle")
                fs.untilT = now + 1.5
                fs.servedUntil = now + 300 -- one ration each; don't rejoin straight away
                if LC.Event == "rations" then
                    fs.leaveAt = math.min(fs.leaveAt or math.huge, now + math.Rand(20, 60))
                    fs.leaveWhy = "had their ration and went home"
                end
                ShuffleLine(g)
                line.nextAdvance = now + (LC.Event == "rations" and math.Rand(6, 10) or math.Rand(20, 40))
            elseif now - (line.frontSince or now) > 25 then
                LeaveLine(front, fs) -- never made it to the counter; the next person steps up
                SetState(front, fs, "idle"); fs.untilT = 0
            else
                line.nextAdvance = now + 2
            end
        end
    end
end

------------------------------------------------------------------------
-- Abandoning, recovering, cleaning up
------------------------------------------------------------------------

local function CancelBusy(npc, st) EndBusy(npc, st, false) end

local function AbandonTask(npc, st, now)
    if IsValid(npc) then npc:SetSchedule(SCHED_IDLE_STAND) end
    LeaveLine(npc, st)
    Release(npc, st)
    st.poi = nil
    SetState(npc, st, "idle")
    st.untilT = now + math.Rand(2, 5)
end
LC.AbandonTask = AbandonTask

local function CleanupNPC(npc, st)
    if not st or st.cleaned then return end
    st.cleaned = true
    if IsValid(st.ss) then st.ss:Remove() end
    LeaveLine(npc, st)
    Release(npc, st)
    if LC.OnNPCRemoved then LC.OnNPCRemoved(npc, st) end
end

-- Stuck NPCs are logged a few at a time, then summarized, so they don't
-- push everything else out of the debug report.
local stuckLogged, stuckQuiet = 0, {}
timer.Create("LivingCityStuckSummary", 60, 0, function()
    local n, parts = 0, {}
    for role, c in pairs(stuckQuiet) do n = n + c parts[#parts + 1] = role .. " " .. c end
    if n > 0 then LC.Log("warn", string.format("...and %d more stuck NPCs moved in the last minute (%s)", n, table.concat(parts, ", "))) end
    stuckLogged, stuckQuiet = 0, {}
end)

-- Someone who isn't getting anywhere. If nobody's watching and the place they
-- were heading for is close (a prop in the way, a doorframe), they're quietly
-- put there. A far one isn't: popping people across the map is worse than the
-- trip being given up, so they give it up, and that place is remembered as
-- hard to reach so it isn't picked again straight away.
local TELEPORT_MAX = 700

function Recover(npc, st, now, why)
    if st.test then return LC.TestStuck(npc, st, now) end
    st.recoveries = (st.recoveries or 0) + 1
    LC.StuckReasons = LC.StuckReasons or {}
    LC.StuckReasons[why or "no progress"] = (LC.StuckReasons[why or "no progress"] or 0) + 1
    local target = st.route[st.hop]
    local unseen = not LC.IsSeen(npc:GetPos() + UP)
    local close = npc:GetPos():DistToSqr(target) < TELEPORT_MAX * TELEPORT_MAX

    -- nobody's looking and it's just a step away: put them there. Not someone
    -- a quest has you chasing or following, though: they'd seem to go through walls.
    if close and unseen and not st.questLock and not LC.IsSeen(target + UP) and ClearSpot(target) then
        if stuckLogged < 5 then
            stuckLogged = stuckLogged + 1
            LC.Log("warn", string.format("%s stuck near %s (%s), moved on to hop %d/%d (%s)", st.role,
                tostring(npc:GetPos()), why or "no progress", st.hop, #st.route, tostring(target)))
        else
            stuckQuiet[st.role] = (stuckQuiet[st.role] or 0) + 1
        end
        LC.StuckCount = (LC.StuckCount or 0) + 1
        npc:SetPos(target + Vector(0, 0, 4))
        st.lastMoved = now
        if st.hop >= #st.route then return Arrive(npc, st, now) end
        return NextHop(npc, st)
    end

    if st.recoveries > 8 and unseen and not st.questLock then
        LC.Log("warn", string.format("%s removed after %d recoveries near %s", st.role, st.recoveries, tostring(npc:GetPos())))
        npc:Remove() -- hopelessly stuck; population tops itself back up
        return
    end

    if not close and st.dest then
        MarkBadDest(st.dest)
        LC.GaveUp = (LC.GaveUp or 0) + 1
    end
    AbandonTask(npc, st, now)
end

------------------------------------------------------------------------
-- Leaving the city (lifetime over, curfew) through spawn points
------------------------------------------------------------------------

local function GoHome(npc, st, run)
    local blocks = LC.ZonesOfKind and LC.ZonesOfKind("block") or {}
    if #blocks == 0 then return false end
    -- one of the nearest two blocks, so a street doesn't all pile into the same doorway
    local from = npc:GetPos()
    table.sort(blocks, function(a, b) return a.pos:DistToSqr(from) < b.pos:DistToSqr(from) end)
    -- their own block if they have one; otherwise one of the nearest two
    local z = LC.HomeZoneFor and LC.HomeZoneFor(st) or blocks[math.min(#blocks, math.random(1, 2))]
    local spot = LC.SpotInZone(z)
    if not spot then return false end
    st.homeBlock = z
    return GoTo(npc, st, spot, run, { kind = "spawn", pos = spot, yaw = math.random(0, 359) })
end

-- Why people left (for the debug report): [reason] = how many since the map started
LC.LeaveCounts = LC.LeaveCounts or {}

local function StartLeaving(npc, st, run, why)
    if not st.leaving then
        why = why or st.leaveWhy or "other"
        LC.LeaveCounts[why] = (LC.LeaveCounts[why] or 0) + 1
    end
    st.leaving = true
    LeaveLine(npc, st)
    CancelBusy(npc, st)
    Release(npc, st)
    -- curfew: people walk home to a housing block and go inside, rather than
    -- trooping off to the edge of the map
    local ev = LC.Event
    if (ev == "curfew" or ev == "lockdown") and GoHome(npc, st, run) then return true end
    -- a train's in: leaving the city means boarding it, suitcase and all (sv_livingcity_trains.lua)
    local board = LC.TrainBoardingPos and LC.TrainBoardingPos()
    if board and GoTo(npc, st, board, run, { kind = "spawn", pos = board, yaw = math.random(0, 359) }) then
        if LC.NPCCarry then LC.NPCCarry(npc, st, "models/props_c17/suitcase001a.mdl") end
        npc:SetNW2String("lc_doing", "leaving the city by train")
        return true
    end
    local spawns = PointsOfKind("spawn")
    if #spawns > 0 then
        local best, bd
        for _, p in ipairs(spawns) do
            local d = p.pos:DistToSqr(npc:GetPos())
            if not bd or d < bd then best, bd = p, d end
        end
        return GoTo(npc, st, best.pos, run, best)
    end
    -- no spawn points: head into the nearest housing block and vanish there
    if GoHome(npc, st, run) then return true end
    if not GoTo(npc, st, LC.RandomWanderPos(), run, nil) then st.untilT = CurTime() + 5 end
end
LC.StartLeaving = StartLeaving

------------------------------------------------------------------------
-- Arrival
------------------------------------------------------------------------

function Arrive(npc, st, now)
    local poi = st.poi
    SetState(npc, st, "idle")
    st.recoveries = 0
    if st.dest then LC.BadDest[DestKey(st.dest)] = nil end
    if st.test then return LC.TestArrived(npc, st, now) end
    if not poi then st.untilT = now + math.Rand(3, 10) return end
    FaceYaw(npc, poi.yaw)

    local k = poi.kind
    if k == "lineslot" then
        SetState(npc, st, "inline")
    elseif k == "lineapproach" then
        EnterQueue(npc, st, poi.line, now)
    elseif k == "spawn" and st.leaving then
        SetState(npc, st, "exiting")
        st.untilT = now + (st.homeBlock and 6 or 15) -- going indoors takes a moment, not a quarter of a minute
    elseif k == "cell" then
        if LC.OnNPCReachedCell then LC.OnNPCReachedCell(npc, st, now) else st.untilT = now + 30 end
    elseif k == "release" then
        st.untilT = now + math.Rand(2, 5)
    elseif k == "raidpoint" then
        st.untilT = now + 0.2
    elseif BUSY[k] then
        if not StartBusy(npc, st, poi) then st.untilT = now + math.Rand(15, 40) end
    elseif k == "checkpoint" then
        st.untilT = now + math.Rand(40, 120)
    elseif k == "exercise" then
        if LC.ExerciseArrive then LC.ExerciseArrive(npc, st, now) else st.untilT = now + 5 end
    elseif k == "npcwork" then
        if LC.NPCWorkArrive then LC.NPCWorkArrive(npc, st, now) else st.untilT = now + 5 end
    elseif k == "work" then
        st.untilT = now + math.Rand(60, 150)
    elseif k == "patrol" then
        st.untilT = now + (st.routeGroup and math.Rand(3, 8) or math.Rand(4, 12))
    elseif k == "queue" then
        st.untilT = now + math.Rand(30, 90)
    else
        st.untilT = now + math.Rand(20, 60)
    end
end

------------------------------------------------------------------------
-- Spawning
------------------------------------------------------------------------

local function Register(npc, role)
    local now = CurTime()
    local life = cvLifetime:GetFloat()
    local st = {
        role = role, state = "idle", untilT = now + math.Rand(1, 4),
        lastPos = npc:GetPos(), lastMoved = now,
        nextChat = now + math.Rand(10, 30), nextInspect = now + math.Rand(20, 50),
        nextWarn = 0, nextUse = 0, nextBark = 0, nextFollow = 0, recoveries = 0, errors = 0,
        born = now,
        leaveAt = (role == "citizen" and life > 0) and now + life * math.Rand(0.6, 1.4) or nil,
        leaveWhy = "their time out was up (lc_citizen_lifetime: a citizen stays about that long, then others come)",
    }
    npc:SetName("lc_npc_" .. npc:EntIndex())
    npc:SetNW2String("lc_role", role)
    -- they leave a searchable body instead of the game's own ragdoll (sv_livingcity_bodies.lua)
    local bodies = GetConVar("lc_bodies")
    if bodies and bodies:GetBool() and (role == "citizen" or role == "cop" or role == "soldier" or role == "rebel") then
        npc:SetNW2Bool("lc_noragdoll", true)
    end
    npc:SetNW2String("lc_state", "idle")
    LC.NPCs[npc] = st
    return st
end
LC.RegisterNPC = Register

local function BaseFlags() return SF_NPC_FADE_CORPSE + SF_NPC_NO_WEAPON_DROP end

-- One speech filter for every Living City citizen: no idle chatter, never say
-- hello. Our own barks are played directly and aren't affected.
local speechFilter
function LC.FilterSpeech(npc)
    if not IsValid(speechFilter) then
        speechFilter = ents.Create("ai_speechfilter")
        if not IsValid(speechFilter) then return end
        speechFilter:SetKeyValue("targetname", "lc_speechfilter")
        speechFilter:SetKeyValue("subject", "lc_npc_*")
        speechFilter:SetKeyValue("IdleModifier", "0")
        speechFilter:SetKeyValue("NeverSayHello", "1")
        speechFilter:Spawn()
        speechFilter:Activate()
    end
    timer.Simple(0, function() if IsValid(speechFilter) then speechFilter:Fire("Enable") end end)
end

local function SpawnCitizen(pos, want)
    local npc = ents.Create("npc_citizen")
    if not IsValid(npc) then return end
    npc:SetPos(pos)
    npc:SetAngles(Angle(0, math.random(0, 359), 0))
    npc:SetKeyValue("citizentype", "1") -- downtrodden, random group01 model
    -- gagged: the engine's own citizen chatter treats the player as Gordon Freeman
    npc:SetKeyValue("spawnflags", tostring(SF_CITIZEN_NOT_COMMANDABLE + SF_NPC_GAG + BaseFlags()))
    npc:Spawn()
    npc:Activate()
    if LC.FilterSpeech then LC.FilterSpeech(npc) end
    for _, cls in ipairs({ "npc_metropolice", "npc_combine_s", "npc_cscanner" }) do
        npc:AddRelationship(cls .. " D_NU 99")
    end
    local st = Register(npc, "citizen")
    st.gender = string.find(string.lower(npc:GetModel() or ""), "female", 1, true) and "female" or "male"
    -- everyone on the street is somebody: same name, face, job and home every time
    local person = LC.ClaimProfile and LC.ClaimProfile("citizen", want)
    if person then LC.AttachProfile(npc, st, person) end
    return npc, st
end
LC.SpawnCitizen = SpawnCitizen

local function AssignBeat(st)
    local groups = PatrolGroups()
    if #groups == 0 or math.random() > 0.75 then st.routeGroup = nil return end
    local counts = {}
    for _, s in pairs(LC.NPCs) do
        if s.routeGroup then counts[s.routeGroup] = (counts[s.routeGroup] or 0) + 1 end
    end
    table.sort(groups, function(a, b) return (counts[a] or 0) < (counts[b] or 0) end)
    st.routeGroup = groups[1]
    st.routeIdx = 0
end

local function SetupSecurity(npc, st)
    npc:AddRelationship("npc_citizen D_NU 99")
    for _, ply in ipairs(player.GetAll()) do SetRel(npc, st, ply, D_NU) end
    AssignBeat(st)
end

-- The Combine loom: units a little bigger than the people they police, and
-- Overwatch soldiers (who hunch as they walk) a little more. Only how they
-- look: their size for doors and corridors is the same.
local cvCopScale = CreateConVar("lc_cp_scale", "1.05", FLAGS, "How big Civil Protection NPCs are drawn (1 = HL2's own size)")
local cvSoldierScale = CreateConVar("lc_soldier_scale", "1.10", FLAGS, "How big Overwatch soldier NPCs are drawn (1 = HL2's own size)")
local function Loom(npc, cv)
    local k = math.Clamp(cv:GetFloat(), 0.8, 1.3)
    if npc.SetModelScale and (k ~= 1 or (npc.GetModelScale and npc:GetModelScale() ~= 1)) then npc:SetModelScale(k, 0) end
end
-- changed in the editor: the ones already out there change too
for _, c in ipairs({ { "lc_cp_scale", cvCopScale, "cop" }, { "lc_soldier_scale", cvSoldierScale, "soldier" } }) do
    cvars.AddChangeCallback(c[1], function()
        for npc, st in pairs(LC.NPCs or {}) do
            if IsValid(npc) and st.role == c[3] then Loom(npc, c[2]) end
        end
    end, "LivingCityLoom")
end

local function SpawnCop(pos)
    local npc = ents.Create("npc_metropolice")
    if not IsValid(npc) then return end
    npc:SetPos(pos)
    npc:SetAngles(Angle(0, math.random(0, 359), 0))
    npc:SetKeyValue("additionalequipment", "weapon_stunstick")
    npc:SetKeyValue("spawnflags", tostring(BaseFlags()))
    npc:Spawn()
    npc:Activate()
    Loom(npc, cvCopScale)
    local st = Register(npc, "cop")
    SetupSecurity(npc, st)
    st.nextChatter = CurTime() + math.Rand(20, 60)
    local person = LC.ClaimProfile and LC.ClaimProfile("cop")
    if person then LC.AttachProfile(npc, st, person) end
    return npc, st
end

-- Nova Prospekt's own: any soldier posted in a Combine-only zone near the
-- prison wears the prison guard's uniform (lc_prisonguard_range, 3000 units
-- from a prison zone or cell; 0 turns it off).
local cvGuardRange = CreateConVar("lc_prisonguard_range", "3000", bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED), "Soldiers in a Combine-only zone this close to the prison are Nova Prospekt guards (0: never)")
local GUARD_MODEL, ELITE_MODEL = "models/combine_soldier_prisonguard.mdl", "models/combine_super_soldier.mdl"
function LC.NearPrisonCombine(pos)
    local r = cvGuardRange:GetFloat()
    if r <= 0 or not LCZ or not LC.ZonesOfKind then return false end
    local inside = false
    for _, z in ipairs(LC.ZonesOfKind("combine")) do if LCZ.Contains(z, pos, 0) then inside = true break end end
    if not inside then return false end
    for _, z in ipairs(LC.ZonesOfKind("prison")) do if z.pos:DistToSqr(pos) < r * r then return true end end
    for _, p in ipairs(LC.PointsOfKind and LC.PointsOfKind("cell") or {}) do if p.pos:DistToSqr(pos) < r * r then return true end end
    return false
end

-- kind: nil (as the place says), "elite" (an Overwatch Elite) or "guard" (Nova Prospekt)
local function SpawnSoldier(pos, kind)
    local npc = ents.Create("npc_combine_s")
    if not IsValid(npc) then return end
    if not kind and LC.NearPrisonCombine(pos) then kind = "guard" end
    local gun = kind == "elite" and "weapon_ar2" or (kind == "guard" and math.random() < 0.4 and "weapon_shotgun")
        or (not kind and math.random() < 0.2 and "weapon_shotgun") or (math.random() < 0.7 and "weapon_smg1" or "weapon_ar2")
    -- an installed Combine pack's model if there is one (sv_livingcity_combinemodels.lua), else Half-Life 2's
    local shot = gun == "weapon_shotgun"
    local hla = LC.CombineModel and LC.CombineModel(kind == "elite" and "elite" or (kind == "guard" and (shot and "guard_shotgun" or "guard")) or (shot and "shotgunner" or "soldier"), false)
    local model = hla or (kind == "elite" and ELITE_MODEL) or (kind == "guard" and GUARD_MODEL) or nil
    if model and (not util.IsValidModel or util.IsValidModel(model)) then npc:SetModel(model) end
    npc:SetPos(pos)
    npc:SetAngles(Angle(0, math.random(0, 359), 0))
    npc:SetKeyValue("additionalequipment", gun)
    npc:SetKeyValue("NumGrenades", kind == "elite" and "2" or "0")
    npc:SetKeyValue("spawnflags", tostring(BaseFlags()))
    npc:Spawn()
    npc:Activate()
    if kind == "elite" then npc:SetMaxHealth(120) npc:SetHealth(120) end
    Loom(npc, cvSoldierScale)
    local st = Register(npc, "soldier")
    st.elite = kind == "elite" or nil
    st.prisonGuard = kind == "guard" or nil
    SetupSecurity(npc, st)
    return npc, st
end

LC.SpawnCop, LC.SpawnSoldier = SpawnCop, SpawnSoldier

local function SpawnScanner(pos)
    local npc = ents.Create("npc_cscanner")
    if not IsValid(npc) then return end
    npc:SetPos(pos + Vector(0, 0, 110))
    npc:SetKeyValue("spawnflags", tostring(SF_NPC_FADE_CORPSE))
    npc:Spawn()
    npc:Activate()
    npc:AddRelationship("npc_citizen D_NU 99")
    local st = Register(npc, "scanner")
    if LC.ScannerSparesUnits then LC.ScannerSparesUnits(npc, st) end
    return npc, st
end

local ZOMBIE_TYPES = {
    { "npc_zombie", 50 }, { "npc_headcrab", 15 }, { "npc_zombie_torso", 10 },
    { "npc_fastzombie", 15 }, { "npc_poisonzombie", 1 }, { "npc_headcrab_fast", 5 }, -- poison: about 1 in 100
}

local function PickZombieClass()
    local total = 0
    for _, z in ipairs(ZOMBIE_TYPES) do total = total + z[2] end
    local r = math.random() * total
    for _, z in ipairs(ZOMBIE_TYPES) do
        r = r - z[2]
        if r <= 0 then return z[1] end
    end
    return "npc_zombie"
end

local function SpawnZombie(pos, zone, class)
    local npc = ents.Create(class or PickZombieClass())
    if not IsValid(npc) then return end
    npc:SetPos(pos)
    npc:SetAngles(Angle(0, math.random(0, 359), 0))
    npc:SetKeyValue("spawnflags", tostring(SF_NPC_FADE_CORPSE))
    npc:Spawn()
    npc:Activate()
    local st = Register(npc, "zombie")
    st.zone = zone
    return npc, st
end
LC.SpawnZombie = SpawnZombie

-- A random standing spot inside a zone.
function LC.SpotInZone(z)
    local wet
    for _ = 1, 14 do
        local top = LCZ.RandomInside(z, 0.85) + Vector(0, 0, 64)
        -- (a patch of territory one floor deep: on its floor, not the street under a roof)
        local tr = util.TraceLine({ start = top, endpos = top - Vector(0, 0, z.h and (z.h + 64) or 400), mask = MASK_NPCSOLID_BRUSHONLY })
        if tr.Hit and tr.HitNormal.z > 0.7 and (not z.h or LCZ.Contains(z, tr.HitPos)) and ClearSpot(tr.HitPos) then
            -- dry ground first: down in the water, or a channel below the zone's floor, only if there's nothing else
            if (LC.InWater and LC.InWater(tr.HitPos)) or tr.HitPos.z < z.pos.z - 14 then wet = wet or tr.HitPos else return tr.HitPos end
        end
    end
    return wet
end

local function FindSpawnPos(role)
    if role == "zombie" then
        -- infestation spawn points first, spread out; then spots inside infestation zones
        local zs = PointsOfKind("zspawn")
        for _ = 1, 6 do
            if #zs == 0 then break end
            local p = Pick(zs)
            if FarFromPlayers(p.pos, 400) and not LC.IsSeen(p.pos + UP) and not (LC.InfestQuietAt and LC.InfestQuietAt(p.pos)) then
                return p.pos + Vector(0, 0, 4), LC.InfestZoneAt and LC.InfestZoneAt(p.pos) or nil
            end
        end
        local zones = {}
        for _, q in ipairs(LC.ZonesOfKind and LC.ZonesOfKind("infest") or {}) do
            -- not where someone is fighting them, nor where a containment team just cleared them out
            if (q.contestedUntil or 0) < CurTime() and not (LC.InfestQuietAt and LC.InfestQuietAt(q.pos)) then zones[#zones + 1] = q end
        end
        if #zones == 0 then return nil end
        local z = Pick(zones)
        local pos = LC.SpotInZone(z)
        if pos and not LC.IsSeen(pos + UP) and FarFromPlayers(pos, 400) then return pos + Vector(0, 0, 4), z end
        return nil
    end

    if role == "rebel" then return LC.RebelSpawnPos and LC.RebelSpawnPos() end

    local citizen = role == "citizen"
    local spawns = PointsOfKind("spawn")
    if role ~= "scanner" and #spawns > 0 then
        for _ = 1, 8 do
            local p = Pick(spawns)
            if FarFromPlayers(p.pos, 250) and not LC.IsSeen(p.pos + UP) and ClearSpot(p.pos)
                and not (LC.InNoGo and LC.InNoGo(p.pos, role))
                and (not citizen or LC.CitizenSpotOK(p.pos)) then
                return p.pos + Vector(0, 0, 4)
            end
        end
        if citizen then return nil end -- spawn points exist; never improvise a citizen onto Combine ground
    end

    for _ = 1, 25 do
        local pos = LC.RandomWanderPos(role)
        if not pos then return nil end
        local far = FarFromPlayers(pos, cvSpawnDist:GetFloat())
        if (far or (FarFromPlayers(pos, 500) and not LC.IsSeen(pos + UP))) and ClearSpot(pos)
            and (not citizen or LC.CitizenSpotOK(pos)) then
            return pos + Vector(0, 0, 4)
        end
    end
    return nil
end

-- Somewhere a citizen player may stand when (re)spawning: a citizen spawn
-- point if the map has any, else a clean wander spot.
function LC.SafeCitizenSpot()
    local spawns = PointsOfKind("spawn")
    for _ = 1, 12 do
        if #spawns == 0 then break end
        local p = Pick(spawns)
        if LC.CitizenSpotOK(p.pos) then return p.pos + Vector(0, 0, 4) end
    end
    for _ = 1, 25 do
        local pos = LC.RandomWanderPos("citizen")
        if not pos then break end
        if LC.CitizenSpotOK(pos) then return pos + Vector(0, 0, 4) end
    end
    return nil
end

local SPAWNERS = {
    citizen = SpawnCitizen, cop = SpawnCop, soldier = SpawnSoldier, scanner = SpawnScanner,
    zombie = function(pos, zone) return SpawnZombie(pos, zone) end,
}
local ROLE_ORDER = { "citizen", "cop", "soldier", "scanner", "zombie", "rebel" }
LC.Spawners = SPAWNERS

-- How many NPCs the city's settings want in all (lc_citizens, lc_cops and the rest).
function LC.NPCTargetsTotal()
    return (LC.CitizenTarget and LC.CitizenTarget() or 0) + cvCops:GetInt() + (LC.ExtraCops or 0) + cvSoldiers:GetInt() + cvScanners:GetInt()
        + (LC.ZombieTarget and LC.ZombieTarget() or 0) + (LC.RebelTarget and LC.RebelTarget() or 0)
end

function LC.CitizenTarget()
    if LC.Event == "curfew" or LC.Event == "lockdown" then
        local cv = GetConVar("lc_curfew_citizens")
        return cv and cv:GetInt() or 0
    end
    local n = cvCitizens:GetInt()
    -- fewer out early, late and at night (sv_livingcity_rhythm.lua)
    if LC.RhythmPopulation and n > 0 then n = math.max(2, math.floor(n * LC.RhythmPopulation() + 0.5)) end
    return n
end

local function MaintainPopulation()
    local counts = {}
    for npc, st in pairs(LC.NPCs) do
        if not IsValid(npc) or npc:Health() <= 0 then
            CleanupNPC(npc, st)
            LC.NPCs[npc] = nil
        elseif not st.test and not st.unmanaged then
            counts[st.role] = (counts[st.role] or 0) + 1
        end
    end
    LC.RoleCounts = counts
    local total = 0
    for _, c in pairs(counts) do total = total + c end
    if total >= cvBudget:GetInt() then
        -- (the cap's lower than what the city's asking for: say so, now and then, or it just
        -- looks like Civil Protection and the citizens have stopped turning up)
        local want = LC.NPCTargetsTotal()
        if want > cvBudget:GetInt() and CurTime() >= (LC.BudgetWarnAt or 0) and LC.Notice then
            LC.BudgetWarnAt = CurTime() + 600
            for _, p in ipairs(player.GetAll()) do
                if p:IsSuperAdmin() then
                    LC.Notice(p, "warn", "NPC cap", string.format("lc_npc_budget is %d, but the city's settings want %d NPCs: no more will spawn (units and citizens included). "
                        .. "60 is the default: lc_npc_budget 60.", cvBudget:GetInt(), want), 14)
                end
            end
            LC.Log("warn", string.format("lc_npc_budget (%d) is below what the city's settings want (%d): nothing more spawns", cvBudget:GetInt(), want))
        end
        return
    end

    local targets = {
        citizen = LC.CitizenTarget(),
        cop = cvCops:GetInt() + (LC.ExtraCops or 0),
        soldier = cvSoldiers:GetInt(),
        scanner = cvScanners:GetInt(),
        -- grown infestation brings more of them (sv_livingcity_territory.lua)
        zombie = LC.ZombieTarget(),
        rebel = LC.RebelTarget and LC.RebelTarget() or 0, -- sv_livingcity_rebels.lua
    }
    for _, role in ipairs(ROLE_ORDER) do
        if SPAWNERS[role] and (counts[role] or 0) < targets[role] then
            local pos, extra = FindSpawnPos(role)
            if pos and SPAWNERS[role](pos, extra) then return end
        end
    end
end

------------------------------------------------------------------------
-- Citizens
------------------------------------------------------------------------

local function TryChat(npc, st, now)
    st.nextChat = now + math.Rand(25, 60)
    for other, ost in pairs(LC.NPCs) do
        if other ~= npc and IsValid(other) and ost.role == "citizen" and (ost.state == "idle" or ost.state == "inline")
            and other:GetPos():DistToSqr(npc:GetPos()) < 160 * 160 then
            if st.state ~= "inline" then Face(npc, other:GetPos()) end
            if ost.state ~= "inline" then Face(other, npc:GetPos()) end
            npc:EmitSound(Vo(st.gender, string.format("question%02d", math.random(1, 20))), 70)
            ost.nextChat = now + 30
            timer.Simple(math.Rand(2.5, 4), function()
                if IsValid(other) then
                    other:EmitSound(Vo(ost.gender or "male", string.format("answer%02d", math.random(1, 20))), 70)
                end
            end)
            return
        end
    end
end

local SITTABLE = { sit = true, sitchair = true, lean = true }
local LOITER = { idle = true, queue = true }
local WORK = { work = true }

local function ChooseCitizenTask(npc, st, now)
    Release(npc, st)
    if LC.NPCWorkReset then LC.NPCWorkReset(npc, st) end
    local ev = LC.Event
    if not st.questLock and (ev == "curfew" or ev == "lockdown" or st.leaving or (st.leaveAt and now > st.leaveAt)) then
        return StartLeaving(npc, st, ev == "lockdown", (ev == "curfew" or ev == "lockdown") and "curfew or lockdown: gone home" or nil)
    end

    -- more people out than the hour calls for: home (sv_livingcity_rhythm.lua)
    if not st.questLock and LC.RhythmGoHome and LC.RhythmGoHome(npc, st, now) then
        return StartLeaving(npc, st, false, "the time of day: fewer people out at this hour")
    end

    -- rations being handed out: the queue comes before work (work used to win, and the line stood empty)
    local lineChance = (ev == "rations") and 0.85 or (LC.RhythmLineChance and LC.RhythmLineChance(0.18) or 0.18)
    local served = st.servedUntil and now < st.servedUntil
    if ev == "rations" and next(LC.Lines) and not served and math.random() < lineChance and JoinLine(npc, st) then return end

    -- their Union job: fix what's broken, haul, carry, deliver, heal (sv_livingcity_npcwork.lua)
    if LC.NPCWorkChoose and LC.NPCWorkChoose(npc, st, now) then return end

    if ev ~= "rations" and next(LC.Lines) and not served and math.random() < lineChance and JoinLine(npc, st) then return end

    if math.random() < (LC.RhythmSitChance and LC.RhythmSitChance(0.3) or 0.3) then
        local spots = FreePoints(SITTABLE, npc)
        if #spots > 0 then
            local p = Pick(spots)
            Claim(npc, st, p)
            return GoTo(npc, st, p.pos, false, p)
        end
    end

    -- people with a job spend a good part of the day at its workplace
    if st.profile and st.profile.job and math.random() < 0.4 and LC.WorkplaceFor then
        local p = LC.WorkplaceFor(st)
        if p and IsFree(p, npc) then
            Claim(npc, st, p)
            return GoTo(npc, st, p.pos, false, p)
        end
    end

    if math.random() < 0.25 then
        -- the city has jobs, and people go to them
        local spots = FreePoints(WORK, npc)
        if #spots > 0 then
            local p = Pick(spots)
            Claim(npc, st, p)
            return GoTo(npc, st, p.pos, false, p)
        end
    end

    if math.random() < 0.45 then
        local spots = FreePoints(LOITER, npc, true)
        if #spots > 0 then
            local p = Pick(spots)
            Claim(npc, st, p)
            return GoTo(npc, st, p.pos, false, p)
        end
    end

    if not GoTo(npc, st, LC.RandomWanderPos(nil, npc:GetPos()), false, nil) then st.untilT = now + 5 end
end

local function ThinkCitizen(npc, st, now)
    local s = st.state
    if s == "event" or s == "escorted" then
        if now > (st.eventUntil or 0) and s == "event" then SetState(npc, st, "idle"); st.untilT = now + 1 end
        if s == "escorted" then return HandleMoving(npc, st, now) end
        return
    end
    if s == "detained" then
        if now > st.untilT then SetState(npc, st, "idle"); st.untilT = now + 1 end
        return
    end
    if s == "jailed" then
        if now > st.untilT and LC.ReleaseNPCPrisoner then LC.ReleaseNPCPrisoner(npc, st, now) end
        return
    end
    if s == "exiting" then
        if not LC.IsSeen(npc:GetPos() + UP) or now > st.untilT then npc:Remove() end
        return
    end
    if s == "moving" then return HandleMoving(npc, st, now) end
    if s == "working" and LC.NPCWorkThink then return LC.NPCWorkThink(npc, st, now) end
    if s == "lookout" then -- keeping watch for the Resistance (sv_livingcity_lookouts.lua): they stay put
        if now > (st.lookoutUntil or 0) then SetState(npc, st, "idle") st.untilT = now + 2 end
        return
    end
    if s == "busy" then
        if not IsValid(st.ss) then
            st.busyKind = nil
            SetState(npc, st, "idle"); st.untilT = now + 1
        elseif now > st.untilT or LC.Event == "curfew" or LC.Event == "lockdown" then
            EndBusy(npc, st, true)
            Release(npc, st)
            SetState(npc, st, "idle"); st.untilT = now + 3
        end
        return
    end
    if s == "inline" then
        if now > st.nextChat and math.random() < 0.3 then TryChat(npc, st, now) else st.nextChat = math.max(st.nextChat, now + 10) end
        if LC.Event == "curfew" or LC.Event == "lockdown" then LeaveLine(npc, st); SetState(npc, st, "idle"); st.untilT = 0 end
        return
    end

    -- idle
    if st.leaving and LC.CountPointsOfKind("spawn") == 0 and not LC.IsSeen(npc:GetPos() + UP) and FarFromPlayers(npc:GetPos(), 700) then
        npc:Remove()
        return
    end
    if now > st.nextChat then TryChat(npc, st, now) end
    if now > st.untilT then ChooseCitizenTask(npc, st, now) end
end

------------------------------------------------------------------------
-- Civil Protection and soldiers
------------------------------------------------------------------------

local function ReleaseInspection(cop, cst, now)
    local cit = cst.subject
    if IsValid(cit) and LC.NPCs[cit] and LC.NPCs[cit].state == "detained" then
        local ist = LC.NPCs[cit]
        SetState(cit, ist, "idle"); ist.untilT = now + math.Rand(0.5, 2)
    end
    cst.subject = nil
    SetState(cop, cst, "idle")
    cst.untilT = now + math.Rand(2, 5)
end

local function TryStartInspection(cop, cst, now)
    local sweep = LC.Event == "sweep"
    cst.nextInspect = now + (sweep and math.Rand(10, 20) or math.Rand(40, 90))
    if not sweep and math.random() > 0.6 then return end
    for cit, ist in pairs(LC.NPCs) do
        if IsValid(cit) and ist.role == "citizen" and not ist.test and (ist.state == "idle" or ist.state == "moving")
            and cit:GetPos():DistToSqr(cop:GetPos()) < 500 * 500 then
            LeaveLine(cit, ist)
            SetState(cit, ist, "detained"); ist.untilT = now + 40
            cit:SetSchedule(SCHED_IDLE_STAND)
            SetState(cop, cst, "inspect_approach"); cst.subject = cit; cst.giveUp = now + 20
            cop:SetLastPosition(LC.SpotInFrontOf(cit, cop, 40))
            cop:SetSchedule(SCHED_FORCED_GO)
            return
        end
    end
end

-- Take a detained citizen in. Cells are behind locked doors, so like an
-- arrested player they're put straight in one (see LC.ArrestNPC).
local function TryArrestCitizen(cop, cst, cit, ist, now)
    if math.random(100) > cvArrestChance:GetInt() then return false end
    if not LC.ArrestNPC then return false end
    cop:EmitSound(Pick(COP_ARREST), 75)
    cit:EmitSound(Vo(ist.gender, Pick(CIT_PROTEST)), 70)
    if not LC.ArrestNPC(cit, nil) then return false end
    cst.subject = nil
    SetState(cop, cst, "idle")
    cst.untilT = now + math.Rand(2, 5)
    return true
end

-- Where to stand to talk to someone face to face: `dist` units in front of
-- them, on the side `from` is coming from.
function LC.SpotInFrontOf(target, from, dist)
    local d = from:GetPos() - target:GetPos()
    d.z = 0
    if d:LengthSqr() < 1 then d = Vector(1, 0, 0) end
    return target:GetPos() + d:GetNormalized() * (dist or 40)
end

local function ThinkInspection(cop, cst, now)
    local cit = cst.subject
    if not IsValid(cit) or now > cst.giveUp then return ReleaseInspection(cop, cst, now) end
    local ist = LC.NPCs[cit]

    if cst.state == "inspect_approach" then
        if cop:GetPos():DistToSqr(cit:GetPos()) < 58 * 58 then
            -- right up close, then the once-over
            cop:SetSchedule(SCHED_IDLE_STAND)
            Face(cop, cit:GetPos())
            Face(cit, cop:GetPos())
            cop:EmitSound(Pick(COP_APPROACH), 75)
            timer.Simple(0.4, function()
                if IsValid(cop) then LC.PlayGesture(cop, LC.FRISK_ANIMS, 6) end
                if IsValid(cit) then LC.PlayGesture(cit, LC.FRISKED_ANIMS, 5) end
            end)
            if ist then
                timer.Simple(2, function()
                    if IsValid(cit) then cit:EmitSound(Vo(ist.gender, Pick(CIT_NERVOUS)), 70) end
                end)
            end
            SetState(cop, cst, "inspect_talk"); cst.untilT = now + math.Rand(5, 8)
        elseif not cop:IsCurrentSchedule(SCHED_FORCED_GO) then
            cop:SetLastPosition(LC.SpotInFrontOf(cit, cop, 40))
            cop:SetSchedule(SCHED_FORCED_GO)
        end
    elseif cst.state == "inspect_talk" and now > cst.untilT then
        if ist and TryArrestCitizen(cop, cst, cit, ist, now) then return end
        cop:EmitSound(Pick(COP_RELEASE), 75)
        ReleaseInspection(cop, cst, now)
    end
end

local function ThinkEscort(cop, cst, now)
    local cit = cst.escortee
    local ist = IsValid(cit) and LC.NPCs[cit]
    if not ist or ist.state ~= "escorted" or now > cst.escortUntil then
        cst.escortee = nil
        SetState(cop, cst, "idle"); cst.untilT = now + 2
        return
    end
    if cop:GetPos():DistToSqr(cit:GetPos()) > 110 * 110 and not cop:IsCurrentSchedule(SCHED_FORCED_GO) then
        cop:SetLastPosition(cit:GetPos() - cit:GetForward() * 60)
        cop:SetSchedule(SCHED_FORCED_GO)
    end
end

local function ChooseSecurityTask(npc, st, now)
    Release(npc, st)
    if LC.NPCWorkReset then LC.NPCWorkReset(npc, st) end
    local run = LC.Event == "lockdown"

    -- a post to hold (an Overwatch landing party round its landing zone): back to it, and stand there
    if st.holdPos then
        if npc:GetPos():DistToSqr(st.holdPos) > 120 * 120 then
            if GoTo(npc, st, st.holdPos, false, nil) then return end
        end
        st.untilT = now + math.Rand(10, 20)
        return
    end

    -- the nexus garrison (sv_livingcity_garrison.lua) stays inside its zone:
    -- a walk to somewhere else in it, or a while standing post
    if st.guardZone then
        if table.HasValue(LC.Zones or {}, st.guardZone) then
            if math.random() < 0.4 then st.untilT = now + math.Rand(8, 25) return end
            local p = LC.SpotInZone(st.guardZone)
            if p and GoTo(npc, st, p, run, nil) then return end
            st.untilT = now + 5
            return
        end
        st.guardZone = nil
    end

    if st.routeGroup then
        local pts = LC.RoutePoints(st.routeGroup)
        if #pts > 0 then
            st.routeIdx = (st.routeIdx or 0) % #pts + 1
            local p = pts[st.routeIdx]
            return GoTo(npc, st, p.pos, run, p)
        end
        st.routeGroup = nil
    end

    local checkpoints = FreePoints({ checkpoint = true }, npc)
    if #checkpoints > 0 and math.random() < 0.35 then
        local p = Pick(checkpoints)
        Claim(npc, st, p)
        return GoTo(npc, st, p.pos, run, p)
    end
    local patrols = PointsOfKind("patrol", 0)
    if #patrols > 0 and math.random() < 0.7 then
        local p = Pick(patrols)
        return GoTo(npc, st, p.pos, run, p)
    end
    if not GoTo(npc, st, LC.RandomWanderPos(st.role, npc:GetPos()), run, nil) then st.untilT = now + 5 end
end

local function CalmOne(npc, st, now)
    if LC.LeaveSquad then LC.LeaveSquad(npc, st) end
    if IsValid(st.enemy) and st.enemy:IsPlayer() then SetRel(npc, st, st.enemy, D_NU) end
    npc:SetEnemy(NULL)
    npc:ClearEnemyMemory()
    npc:SetSchedule(SCHED_IDLE_STAND)
    st.enemy, st.provokedBy, st.arrestOnly = nil, nil, nil
    if st.armed then
        -- back to the stick (unless there's a judgment waiver on: then the pistol stays out)
        st.armed = nil
        if npc.SelectWeapon and not (LC.WaiverIn and LC.WaiverIn()) then npc:SelectWeapon("weapon_stunstick") end
    end
    SetState(npc, st, "idle"); st.untilT = now + 2
end
LC.CalmOne = CalmOne

-- Hostile units actually go after their target. The engine's combat AI only
-- engages what it can see, and a walking schedule ignores enemies entirely,
-- so dispatch keeps them told where the suspect is and they run there until
-- they have eyes on them.
local STOP_LINES = { cop = { "npc/metropolice/vo/holdit.wav", "npc/metropolice/vo/stopthere.wav", "npc/metropolice/vo/dontmove.wav" },
    soldier = { "npc/combine_soldier/vo/contact.wav", "npc/combine_soldier/vo/stayalert.wav" } }
local function Pursue(npc, st, e, now)
    if now < (st.nextPursue or 0) then return end
    -- lost them: nobody has seen them for a while, so nobody tells this unit where they are
    if LC.WantedLost and LC.WantedLost(e) then
        npc:SetEnemy(NULL)
        SetRel(npc, st, e, D_NU)
        CalmOne(npc, st, now)
        return
    end
    st.nextPursue = now + (st.arrestOnly and 0.3 or 1)
    -- after someone who's harmed nobody: run them down and lay hands on them (no shots).
    -- If they turn violent (hurt anyone, a gun in hand, the alert climbs), weapons free.
    if st.arrestOnly then
        if not e:IsPlayer() or LC.Violent(e) then
            st.arrestOnly = nil
            if e:IsPlayer() then SetRel(npc, st, e, D_HT) end
            npc:SetEnemy(e)
            if LC.ArmForAlert then LC.ArmForAlert(npc, st, e) end
        else
            local epos = e:GetPos()
            -- (laid hands on only once they're subdued: beaten, down, or standing still for it)
            if npc:GetPos():DistToSqr(epos) < 90 * 90 and LC.NPCSubdue and LC.NPCSubdue(npc, st, e, now) then return end
            if (st.nextShout or 0) < now then
                st.nextShout = now + 7
                local lines = STOP_LINES[st.role] or STOP_LINES.cop
                npc:EmitSound(lines[math.random(#lines)], 80)
            end
            st.chasePos = epos
            npc:SetLastPosition(epos)
            if not npc:IsCurrentSchedule(SCHED_FORCED_GO_RUN) or (st.lastArrestGoal or Vector(0, 0, 0)):DistToSqr(epos) > 60 * 60 then
                st.lastArrestGoal = epos
                npc:SetSchedule(SCHED_FORCED_GO_RUN)
            end
            return
        end
    end
    local epos = e:GetPos()
    if npc.UpdateEnemyMemory then npc:UpdateEnemyMemory(e, epos) end
    if npc:GetEnemy() ~= e then npc:SetEnemy(e) end
    local d2 = npc:GetPos():DistToSqr(epos)
    local sees = false
    if d2 < 900 * 900 then
        local tr = util.TraceLine({ start = npc:EyePos(), endpos = e:EyePos(), mask = MASK_OPAQUE, filter = npc })
        sees = tr.Fraction > 0.97 and not (LC.SmokeBlocks and LC.SmokeBlocks(npc:EyePos(), e:EyePos()))
    end
    local running = npc:IsCurrentSchedule(SCHED_FORCED_GO_RUN) or npc:IsCurrentSchedule(SCHED_FORCED_GO)
    -- as a squad (sv_livingcity_squadai.lua): just hurt, the combat AI has them; a
    -- follower keeps with the leader rather than running at the target alone
    if LC.SquadHurt and LC.SquadHurt(st, now) then return end
    if LC.SquadFollow and LC.SquadFollow(npc, st, e, now, sees) then return end
    if sees and d2 < 600 * 600 then
        -- in sight and close: let the combat AI close in and swing
        if running then npc:SetSchedule(SCHED_CHASE_ENEMY) end
        st.chasePos = nil
    elseif not running or not st.chasePos or st.chasePos:DistToSqr(epos) > 200 * 200 then
        st.chasePos = epos
        npc:SetLastPosition(epos)
        npc:SetSchedule(SCHED_FORCED_GO_RUN)
    end
end

-- Crowding a unit: two warnings, a shove, a harder shove with the stick, and
-- then you're obstructing Civil Protection.
local BUMP_LINES = {
    "npc/metropolice/vo/movealong3.wav", "npc/metropolice/vo/firstwarningmove.wav",
    "npc/metropolice/vo/secondwarning.wav", "npc/metropolice/vo/finalwarning.wav",
}
function LC.CopProvoked(npc, st, ply, now)
    if not IsValid(ply) or not ply:Alive() or LC.PlayerIsCP(ply) or (LC.DisguisedAsCP and LC.DisguisedAsCP(ply)) then return end
    if LC.PlayerIsZombie and LC.PlayerIsZombie(ply) then return end
    if LC.InCustody and LC.InCustody(ply) then return end -- (a prisoner they're walking in, or one they've cuffed, isn't crowding them)
    if LC.IsTied and LC.IsTied(ply) then return end
    local b = ply.lcBump
    if not b or now - b.last > 45 then
        b = { n = 0, last = 0 }
        ply.lcBump = b
    end
    if now - b.last < 2.5 then return end
    b.n = b.n + 1
    b.last = now
    Face(npc, ply:GetPos())
    if b.n <= #BUMP_LINES then npc:EmitSound(BUMP_LINES[b.n], 78) end
    if b.n == 3 or b.n == 4 then
        local away = ply:GetPos() - npc:GetPos()
        away.z = 0
        away = away:GetNormalized()
        ply:SetVelocity(away * (b.n == 3 and 300 or 450) + Vector(0, 0, 110))
        ply:ViewPunch(Angle(-10, math.Rand(-6, 6), 0))
        npc:EmitSound(b.n == 3 and "physics/body/body_medium_impact_soft3.wav" or "Weapon_StunStick.Melee_Hit", 70)
        if b.n == 4 then ply:TakeDamage(5, npc, npc) end
        ply:ChatPrint(b.n == 3 and "[Civil Protection] The Civil Protection unit shoves you back. Move along."
            or "[Civil Protection] A crack across the ribs with the stick. Last warning.")
    elseif b.n > #BUMP_LINES then
        ply.lcBump = nil
        npc:EmitSound("npc/metropolice/vo/holdit.wav", 80)
        ply:ChatPrint("[Civil Protection] You were warned. Obstructing Civil Protection.")
        LC.ReportCrime(ply, "Obstructing Civil Protection", 90)
        LC.MakeCopsHostile(ply, npc:GetPos(), 1500)
    end
end

local function ThinkSecurity(npc, st, now)
    if (st.stunnedUntil or 0) > now then return end -- flashbanged
    local s = st.state
    if s == "event" then
        if now > (st.eventUntil or 0) then SetState(npc, st, "idle"); st.untilT = now + 1 end
        return
    end
    if s == "hostile" then
        local e = st.enemy
        -- a unit that's been shot at, or a suspect at a high alert level, gets
        -- chased right across the city and into rebel territory
        local provoked = IsValid(e) and st.provokedBy == e and now < (st.provokedUntil or 0)
        local alert = (IsValid(e) and e:IsPlayer() and LC.AlertLevel) and LC.AlertLevel(e) or 0
        local leash = (provoked or alert >= 2) and 9000 or 3000
        if not IsValid(e) or (e:IsPlayer() and not e:Alive()) or (not e:IsPlayer() and e:Health() <= 0)
            or e:GetPos():DistToSqr(npc:GetPos()) > leash * leash
            or (LC.InCustody and LC.InCustody(e)) or (LC.Prisoners and LC.Prisoners[e]) then
            CalmOne(npc, st, now)
        elseif e:IsPlayer() and not cvRebelPursuit:GetBool() and not provoked and alert < 3 and LC.InRebelZone and LC.InRebelZone(e:GetPos())
            and not LC.InRebelZone(npc:GetPos()) then
            -- they made it to rebel territory; Civil Protection doesn't follow
            st.lostSince = st.lostSince or now
            if now - st.lostSince > 6 then st.lostSince = nil; CalmOne(npc, st, now) end
        else
            st.lostSince = nil
            Pursue(npc, st, e, now)
        end
        return
    end
    if s == "inspect_approach" or s == "inspect_talk" then return ThinkInspection(npc, st, now) end
    if s == "escort" then return ThinkEscort(npc, st, now) end
    if s == "workescort" then return end -- escorting a worker (sv_livingcity_escort.lua drives them)

    if st.role == "cop" then
        -- tell people crowding them to move along, and escalate if they don't
        if now > st.nextWarn and LC.Event ~= "curfew" and LC.Event ~= "lockdown" then
            local npos = npc:GetPos()
            for _, ply in ipairs(player.GetAll()) do
                -- right up against him first (cheap), then who they are
                if ply:GetPos():DistToSqr(npos) < 90 * 90 and ply:Alive() and not LC.PlayerIsCP(ply)
                    and not (LC.DisguisedAsCP and LC.DisguisedAsCP(ply))
                    and not (LC.Stops and LC.Stops[ply]) and (ply.lcCopTalkUntil or 0) < now
                    and not (LC.QuestWantsCop and LC.QuestWantsCop(ply))
                    and not (LC.EscortCovers and LC.EscortCovers(ply)) then -- (a worker with an escort has business here)
                    LC.CopProvoked(npc, st, ply, now)
                    st.nextWarn = now + 4
                    break
                end
            end
        end
        if now > st.nextInspect and (s == "idle" or s == "moving") and not st.raid and not st.npcWork then
            TryStartInspection(npc, st, now)
            if st.state ~= "idle" and st.state ~= "moving" then return end
        end
    end

    if st.raid and st.state == "idle" and now > st.untilT and LC.RaidThink and LC.RaidThink(npc, st, now) then return end
    if st.state == "moving" then return HandleMoving(npc, st, now) end
    if st.state == "working" and LC.NPCWorkThink then return LC.NPCWorkThink(npc, st, now) end
    if st.state == "idle" and now > st.untilT then ChooseSecurityTask(npc, st, now) end
end

------------------------------------------------------------------------
-- Scanners and zombies
------------------------------------------------------------------------

-- Scanners drift from citizen to citizen. Left alone they snag on walkways,
-- signs and overhangs, so they also change altitude now and then, and a
-- scanner that hasn't moved while its target walks away gets itself free:
-- up or down to clear air, or (with nobody watching) back over the street.
local SCANNER_HULL_MIN, SCANNER_HULL_MAX = Vector(-20, -20, -20), Vector(20, 20, 20)

local function Glide(npc, to)
    local from = npc:GetPos()
    for i = 1, 10 do
        timer.Simple(i * 0.06, function()
            if IsValid(npc) then npc:SetPos(from + (to - from) * (i / 10)) end
        end)
    end
end

local function ClearPath(npc, from, to)
    local tr = util.TraceHull({ start = from, endpos = to, mins = SCANNER_HULL_MIN, maxs = SCANNER_HULL_MAX,
        mask = MASK_NPCSOLID, filter = npc })
    return not tr.Hit and not tr.StartSolid
end

-- Try a new height. Returns true if the scanner moved.
local function ScannerAltitude(npc, steps)
    local pos = npc:GetPos()
    local order = {}
    for _, dz in ipairs(steps) do order[#order + 1] = dz end
    for i = #order, 2, -1 do local j = math.random(i) order[i], order[j] = order[j], order[i] end
    for _, dz in ipairs(order) do
        local to = pos + Vector(0, 0, dz)
        if ClearPath(npc, pos, to) then
            Glide(npc, to)
            return true
        end
    end
    return false
end

local function ScannerUnstick(npc, st, now)
    LC.StuckCount = (LC.StuckCount or 0) + 1
    if ScannerAltitude(npc, { 90, -90, 150, -150, 220 }) then return end
    -- boxed in: with nobody looking, move it back over an open street
    if not LC.IsSeen(npc:GetPos()) then
        local spot = LC.RandomWanderPos("citizen")
        if spot then npc:SetPos(spot + Vector(0, 0, math.Rand(130, 220))) end
    end
end

-- Someone a scanner should take for one of its own: a unit, or anyone in a
-- convincing Civil Protection uniform.
local function LooksCombine(ply)
    return LC.PlayerIsCP(ply) or (LC.DisguisedAsCP and LC.DisguisedAsCP(ply))
        or (LC.PlayerIsStalker and LC.PlayerIsStalker(ply)) or false -- a stalker is Combine property (sv_livingcity_custody.lua)
end
LC.LooksCombine = LooksCombine

-- Scanners photograph players on their own (the engine's inspection). Units
-- aren't suspects, so while one is nearby the scanner leaves players alone
-- and keeps to the citizens it's following.
local SCANNER_UNIT_RANGE = 1600
local function ScannerSparesUnits(npc, st)
    local pos, near = npc:GetPos(), false
    for _, ply in ipairs(player.GetAll()) do
        if ply:Alive() and ply:GetPos():DistToSqr(pos) < SCANNER_UNIT_RANGE * SCANNER_UNIT_RANGE and LooksCombine(ply) then
            near = true
            break
        end
    end
    if st.sparing ~= near then
        st.sparing = near
        npc:SetKeyValue("NeverInspectPlayers", near and "1" or "0")
    end
end
LC.ScannerSparesUnits = ScannerSparesUnits

-- A city scanner that has a fugitive in sight (wanted, or a hunted rebel who
-- isn't passing as a citizen) tells the units where they are: a flash, a report
-- to every unit on duty, and the nearby units come after them.
local TIP_RANGE, TIP_EVERY = 900, 25
function LC.ScannerTipOff(npc, st, now)
    for _, ply in ipairs(player.GetAll()) do
        if ply:Alive() and not LooksCombine(ply) and not (LC.Prisoners and LC.Prisoners[ply]) and (ply.lcTipAt or 0) < now
            and ply:GetPos():DistToSqr(npc:GetPos()) < TIP_RANGE * TIP_RANGE then
            local passes = LC.PassesAsCitizen and LC.PassesAsCitizen(ply)
            local why = (LC.PlayerIsWanted and LC.PlayerIsWanted(ply) and "a wanted citizen")
                or (LC.PlayerIsHunted and LC.PlayerIsHunted(ply) and not passes and "a rebel") or nil
            if why and LC.LineOfSight(npc:GetPos(), ply:EyePos(), npc) then
                ply.lcTipAt = now + TIP_EVERY
                npc:EmitSound("npc/scanner/scanner_photo1.wav", 75)
                ply:ChatPrint("A scanner's flash. You've been photographed, and Civil Protection has the picture.")
                local where = LC.DescribePlace and LC.DescribePlace(ply:GetPos()) or ""
                for _, p in ipairs(player.GetAll()) do
                    if LC.PlayerIsCP(p) then
                        p:ChatPrint(string.format("[CP net] Scanner report: %s%s.", why, where ~= "" and (", " .. where) or ""))
                    end
                end
                ply:SetNW2Float("lc_spotted_until", now + 30)
                ply:SetNW2String("lc_spotted_why", why)
                LC.MakeCopsHostile(ply, ply:GetPos(), 2500)
                return ply
            end
        end
    end
    return nil
end

local function ThinkScanner(npc, st, now)
    ScannerSparesUnits(npc, st)
    if now > (st.nextTipCheck or 0) then
        st.nextTipCheck = now + 1
        LC.ScannerTipOff(npc, st, now)
    end
    -- stuck: hasn't moved in 6 seconds while its citizen is getting away
    if now > (st.scanCheck or 0) then
        local pos = npc:GetPos()
        local target = st.followEnt
        if st.scanPos and pos:DistToSqr(st.scanPos) < 40 * 40 and IsValid(target)
            and target:GetPos():DistToSqr(pos) > 400 * 400 then
            ScannerUnstick(npc, st, now)
        end
        st.scanPos, st.scanCheck = pos, now + 6
    end
    -- and a new altitude every so often anyway
    if now > (st.nextAltitude or 0) then
        st.nextAltitude = now + math.Rand(20, 45)
        ScannerAltitude(npc, { 60, -60, 110, -110 })
    end
    if now < st.nextFollow then return end
    st.nextFollow = now + math.Rand(30, 60)
    local cits = {}
    for n, s in pairs(LC.NPCs) do
        if IsValid(n) and s.role == "citizen" and not s.test then cits[#cits + 1] = n end
    end
    if #cits > 0 then
        st.followEnt = Pick(cits)
        npc:Fire("SetFollowTarget", st.followEnt:GetName())
    else
        st.followEnt = nil
        npc:Fire("ClearFollowTarget")
    end
end

local function ThinkZombie(npc, st, now)
    local z = st.zone
    if z and not table.HasValue(LC.Zones, z) then
        -- the patch they lived in was cleared: back to what's left of the infestation
        local best, bd
        for _, q in ipairs(LC.ZonesOfKind and LC.ZonesOfKind("infest") or {}) do
            local d = q.pos:DistToSqr(npc:GetPos())
            if not bd or d < bd then best, bd = q, d end
        end
        if not best and not LC.IsSeen(npc:GetPos() + UP) then npc:Remove() return end
        st.zone, z = best, best
    end
    if st.surgeExpires and now > st.surgeExpires and not LC.IsSeen(npc:GetPos() + UP) then npc:Remove() return end
    if not z then return end
    local pos = npc:GetPos()
    local limit = z.r * 1.3
    if pos:DistToSqr(z.pos) < limit * limit then return end
    local enemy = npc:GetEnemy()
    if IsValid(enemy) and enemy:GetPos():DistToSqr(z.pos) < (z.r * 1.6) ^ 2 then return end
    -- wandered out: snap back if unseen, otherwise call it home
    if not LC.IsSeen(pos + UP) then
        local spot = LC.SpotInZone(z)
        if spot then npc:SetPos(spot + Vector(0, 0, 4)) end
    elseif not npc:IsCurrentSchedule(SCHED_FORCED_GO) then
        npc:SetEnemy(NULL)
        npc:SetLastPosition(z.pos)
        npc:SetSchedule(SCHED_FORCED_GO)
    end
end

------------------------------------------------------------------------
-- Ambient barks when players brush past citizens
------------------------------------------------------------------------

local function BarkPass(now)
    for _, ply in ipairs(player.GetAll()) do
        if ply:Alive() and ply:GetVelocity():LengthSqr() > 100 * 100 then
            -- only who's right there (the engine finds them; not every NPC in the city)
            for _, npc in ipairs(ents.FindInSphere(ply:GetPos(), 60)) do
                local st = LC.NPCs[npc]
                if st and st.role == "citizen" and now > st.nextBark and IsValid(npc)
                    and (st.state == "moving" or st.state == "idle" or st.state == "inline") then
                    st.nextBark = now + 20
                    if math.random() < 0.5 then
                        local snd = LC.PlayerIsZombie and LC.PlayerIsZombie(ply) and Vo(st.gender, "runforyourlife01")
                            or Vo(st.gender, Pick(CIT_BARK))
                        npc:EmitSound(snd, 70)
                    end
                end
            end
        end
    end
end

------------------------------------------------------------------------
-- Relationships with players (zombie players, CP players)
------------------------------------------------------------------------

function LC.RefreshRelations()
    -- each player is looked at once, not once per NPC
    local players, zombie, combine, wanted = player.GetAll(), {}, {}, {}
    for i, ply in ipairs(players) do
        zombie[i] = LC.PlayerIsZombie and LC.PlayerIsZombie(ply) or false
        combine[i] = not zombie[i] and LooksCombine(ply) or false
        wanted[i] = not zombie[i] and LC.PlayerIsWanted and LC.PlayerIsWanted(ply) or false
    end
    for npc, st in pairs(LC.NPCs) do
        if IsValid(npc) then
            local role = st.role
            local security = IsSecurity(st) or role == "scanner"
            for i, ply in ipairs(players) do
                local z = zombie[i]
                if role == "zombie" then
                    SetRel(npc, st, ply, z and D_LI or D_HT)
                elseif role == "citizen" then
                    SetRel(npc, st, ply, z and D_FR or D_LI)
                elseif role == "rebel" then
                    if LC.RebelDisposition then SetRel(npc, st, ply, LC.RebelDisposition(npc, st, ply, z)) end
                elseif security then
                    if z then
                        SetRel(npc, st, ply, D_HT)
                    elseif role == "scanner" and combine[i] then
                        SetRel(npc, st, ply, D_LI) -- one of ours
                    elseif st.enemy ~= ply and not wanted[i] then
                        SetRel(npc, st, ply, D_NU)
                    end
                end
            end
        end
    end
end

------------------------------------------------------------------------
-- Main loop
------------------------------------------------------------------------

local THINKERS = {
    citizen = ThinkCitizen, cop = ThinkSecurity, soldier = ThinkSecurity,
    scanner = ThinkScanner, zombie = ThinkZombie,
}

-- The loop runs ten times a second, and each run only does as much as fits in
-- a few milliseconds: on a listen server the game waits for this, so doing every
-- NPC in one go every half second was a hitch twice a second. NPCs whose turn
-- didn't come this run go first next run.
local cvBudget = CreateConVar("lc_think_budget_ms", "2.5", bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED),
    "Milliseconds the NPC loop may spend per tick (it runs ten times a second); lower is smoother, higher keeps NPCs sharper")
local nextPop, nextRel, nextLines = 0, 0, 0
local queue, qi = {}, 1
local function Think()
    if LC.TimeStopped then return end -- (the G-Man has stopped time: sv_livingcity_endings.lua)
    local now = CurTime()
    local t0 = SysTime()
    if LC.Running then
        if now > nextPop then MaintainPopulation(); nextPop = now + 1.2
        elseif now > nextRel then LC.RefreshRelations(); nextRel = now + 3
        elseif now > nextLines then LineThink(now); BarkPass(now); nextLines = now + 0.5 end
    end
    -- whose turn it is: rebuilt once the last list is worked through
    if qi > #queue then
        queue, qi = {}, 1
        for npc, st in pairs(LC.NPCs) do
            if now >= (st.nextThink or 0) then queue[#queue + 1] = npc end
        end
    end
    local players = player.GetAll()
    local lod2 = cvLodDist:GetFloat() ^ 2
    local budget = math.max(0.5, cvBudget:GetFloat()) / 1000
    while qi <= #queue do
        if SysTime() - t0 > budget and not LC.TestMode then break end
        local npc = queue[qi]
        qi = qi + 1
        local st = LC.NPCs[npc]
        if st and IsValid(npc) and npc:Health() > 0 and now >= (st.nextThink or 0) then
            -- far from everyone: think every 2 seconds instead of every half second
            local near = st.test or st.state == "hostile"
            if not near then
                local pos = npc:GetPos()
                for _, ply in ipairs(players) do
                    if ply:GetPos():DistToSqr(pos) < lod2 then near = true break end
                end
            end
            st.nextThink = near and (now + 0.45) or (now + 2)
            if LC.NPCSleepTick then LC.NPCSleepTick(npc, st, now, near) end -- (sv_livingcity_sleep.lua)
            local fn = THINKERS[st.role] or (LC.Thinkers and LC.Thinkers[st.role])
            if fn then
                local ok, err = pcall(fn, npc, st, now)
                if not ok then
                    st.errors = (st.errors or 0) + 1
                    LC.Error(st.role .. " in state " .. tostring(st.state), err)
                    if st.errors > 5 then npc:Remove() else SetState(npc, st, "idle"); st.untilT = now + 5 end
                end
            end
        end
    end
end
timer.Create("LivingCityThink", 0.1, 0, function()
    local t0 = SysTime()
    local ok, err = pcall(Think)
    if not ok then LC.Error("main loop", err) end
    local dt = (SysTime() - t0) * 1000
    local perf = LC.Perf
    perf.samples, perf.total = perf.samples + 1, perf.total + dt
    if dt > perf.max then perf.max = dt end
    perf.last = dt
end)

function LC.OnLayoutChanged()
    LC.RebuildLines()
    hook.Run("LivingCityLayoutChanged")
    local groups = {}
    for _, g in ipairs(PatrolGroups()) do groups[g] = true end
    for _, st in pairs(LC.NPCs) do
        if st.routeGroup and not groups[st.routeGroup] then st.routeGroup = nil end
    end
end

function LC.Start(ply)
    LC.LoadData(false)
    BuildFallback()
    local nodes = LC.NodeCount and LC.NodeCount() or 0
    if #LC.Fallback == 0 and #LC.Points == 0 and nodes == 0 then
        Say(ply, "This map has no AI nodes or navmesh and nothing placed yet. Lay some path nodes or points with the Living City Editor, then start again.")
        return false
    end
    LC.RebuildLines()
    LC.Running = true
    LC.StartedAt = CurTime()
    LC.Log("info", "City started on " .. game.GetMap())
    Say(ply, string.format("Started. Map nav: %d spots (%s). Your layout: %d points, %d path nodes.",
        #LC.Fallback, LC.Source, #LC.Points, nodes))
    return true
end

function LC.Stop(ply)
    LC.Running = false
    LC.Log("info", "City stopped")
    if LC.EndEvent then LC.EndEvent(true) end
    for npc, st in pairs(LC.NPCs) do
        CleanupNPC(npc, st)
        if IsValid(npc) then npc:Remove() end
    end
    LC.NPCs = {}
    LC.Occupied = {}
    hook.Run("LivingCityStopped")
    for _, line in pairs(LC.Lines) do line.q = {} end
    Say(ply, "Stopped and removed all Living City NPCs.")
end

------------------------------------------------------------------------
-- Test walker (editor tool): walks to a spot and reports how it went
------------------------------------------------------------------------

function LC.SendRoute(ply, positions, stuckAt)
    if not IsValid(ply) then return end
    local pts = {}
    for _, p in ipairs(positions) do pts[#pts + 1] = { p.x, p.y, p.z } end
    local t = { pts = pts }
    if stuckAt then t.stuck = { stuckAt.x, stuckAt.y, stuckAt.z } end
    LC.SendCompressed("lc_route", t, { ply })
end

function LC.SpawnTestWalker(ply, dest)
    local start = ply:GetPos() + ply:GetRight() * 48
    if not ClearSpot(start) then start = ply:GetPos() - ply:GetForward() * 48 end
    local npc, st = SpawnCitizen(start + Vector(0, 0, 4))
    if not npc then return false end
    st.test = true
    st.owner = ply
    st.testStart = CurTime()
    st.leaveAt = nil
    GoTo(npc, st, dest, false, nil)
    local route = { start }
    for _, p in ipairs(st.route) do route[#route + 1] = p end
    LC.SendRoute(ply, route, nil)
    local how = #st.route > 1 and string.format("your path network (%d hops)", #st.route - 1) or "the map's own navigation"
    Say(ply, "Test walker heading out using " .. how .. ".")
    return true
end

function LC.TestArrived(npc, st, now)
    Say(st.owner, string.format("Test walker arrived in %.1f seconds. This route works.", now - st.testStart))
    SetState(npc, st, "event"); st.eventUntil = math.huge
    SafeRemoveEntityDelayed(npc, 3)
end

function LC.TestStuck(npc, st, now)
    local pos = npc:GetPos()
    LC.Log("warn", string.format("Test walker stuck at %s on hop %d/%d", tostring(pos), st.hop, #st.route))
    local msg = string.format("Test walker got stuck after %.1f seconds, on hop %d of %d (marked red).",
        now - st.testStart, st.hop, #st.route)
    if st.hop < #st.route or #st.route == 1 then
        msg = msg .. " Add a path node here and link it toward the destination, or check for a door it can't open."
    end
    Say(st.owner, msg)
    local route = { pos }
    for i = st.hop, #st.route do route[#route + 1] = st.route[i] end
    LC.SendRoute(st.owner, route, pos)
    SetState(npc, st, "event"); st.eventUntil = math.huge
    npc:SetSchedule(SCHED_IDLE_STAND)
    SafeRemoveEntityDelayed(npc, 5)
end

------------------------------------------------------------------------
-- Interactivity and consequences
------------------------------------------------------------------------

-- Security NPCs within radius of origin (or all, if radius is nil) go after target.
-- One security NPC goes after target: drops whatever it was doing (including
-- an animation), is told where the target is, and draws a gun if the alert
-- level calls for it.
function LC.MakeOneHostile(npc, st, target)
    local now = CurTime()
    -- walking a prisoner in (sv_livingcity_march.lua): he only lets go of him to
    -- fight whoever attacks him, not to chase someone else
    if st.marching and not (IsValid(target) and st.provokedBy == target and (st.provokedUntil or 0) > now) then return end
    if st.subject then ReleaseInspection(npc, st, now) end
    if st.escortee then st.escortee = nil end
    if IsValid(npc.lcGesture) then npc.lcGesture:Fire("CancelSequence") npc.lcGesture:Remove() end
    Release(npc, st)
    SetState(npc, st, "hostile")
    st.enemy = target
    st.nextPursue, st.chasePos, st.lostSince = 0, nil, nil
    -- someone wanted who's done nobody any harm: run them down and cuff them, no shooting
    st.arrestOnly = target:IsPlayer() and LC.Violent and not LC.Violent(target) or nil
    if st.arrestOnly then
        SetRel(npc, st, target, D_NU)
        if st.role == "cop" and npc.SelectWeapon then npc:SelectWeapon("weapon_stunstick") end
        return
    end
    if target:IsPlayer() then SetRel(npc, st, target, D_HT) else npc:AddEntityRelationship(target, D_HT, 99) end
    npc:SetEnemy(target)
    if npc.UpdateEnemyMemory then npc:UpdateEnemyMemory(target, target:GetPos()) end
    npc:SetSchedule(SCHED_CHASE_ENEMY) -- drop any walking schedule; walking ignores enemies
    if LC.ArmForAlert then LC.ArmForAlert(npc, st, target) end
end

function LC.MakeCopsHostile(target, origin, radius)
    local r2 = radius and radius * radius
    for npc, st in pairs(LC.NPCs) do
        if IsValid(npc) and IsSecurity(st) and st.enemy ~= target and (not r2 or npc:GetPos():DistToSqr(origin) < r2) then
            LC.MakeOneHostile(npc, st, target)
        end
    end
end

-- Security NPCs stop hunting ply (or everyone, if ply is nil) and go back to work.
function LC.CalmCops(ply)
    local now = CurTime()
    for npc, st in pairs(LC.NPCs) do
        if IsValid(npc) and IsSecurity(st) then
            local targets = IsValid(ply) and { ply } or player.GetAll()
            for _, p in ipairs(targets) do
                if not (LC.PlayerIsZombie and LC.PlayerIsZombie(p)) then SetRel(npc, st, p, D_NU) end
            end
            if st.state == "hostile" and (not IsValid(ply) or st.enemy == ply or not IsValid(st.enemy)) then
                CalmOne(npc, st, now)
            end
        end
    end
end

-- Citizens near pos run, dropping whatever they were doing.
function LC.Scatter(pos, radius)
    local now = CurTime()
    for npc, st in pairs(LC.NPCs) do
        -- (not someone a quest has following you, or anyone else spoken for)
        if IsValid(npc) and st.role == "citizen" and not st.test and not st.questLock
            and st.state ~= "detained" and st.state ~= "jailed" and st.state ~= "escorted" and st.state ~= "event"
            and npc:GetPos():DistToSqr(pos) < radius * radius then
            CancelBusy(npc, st)
            LeaveLine(npc, st)
            Release(npc, st)
            GoTo(npc, st, LC.RandomWanderPos(), true, nil)
            st.untilT = now + 5
        end
    end
end

-- A citizen attacked by a headcrab or a zombie: they scream for help and run
-- (away from it, not just anywhere), everyone near them scatters, and the
-- nearest units come and deal with it.
local CIT_PANIC = { "help01", "headcrabs01", "headcrabs02", "runforyourlife01", "runforyourlife02", "runforyourlife03",
    "gethellout", "watchout", "zombies01", "zombies02", "uhoh" }
local MONSTERS = { npc_headcrab = true, npc_headcrab_fast = true, npc_headcrab_black = true, npc_headcrab_poison = true,
    npc_zombie = true, npc_zombie_torso = true, npc_fastzombie = true, npc_fastzombie_torso = true, npc_poisonzombie = true, npc_zombine = true }

local function IsMonster(e)
    if not IsValid(e) then return false end
    if MONSTERS[e:GetClass()] then return true end
    local st = LC.NPCs[e]
    if st and st.role == "zombie" then return true end
    return e:IsPlayer() and LC.PlayerIsZombie and LC.PlayerIsZombie(e) or false
end
LC.IsMonster = IsMonster

function LC.CitizenPanic(npc, st, threat)
    local now = CurTime()
    if (st.nextPanic or 0) > now then return false end
    st.nextPanic = now + 3.5
    npc:EmitSound(Vo(st.gender, Pick(CIT_PANIC)), 85, math.random(98, 108))
    local npos = npc:GetPos()
    if st.state ~= "detained" and st.state ~= "jailed" and st.state ~= "escorted" and st.state ~= "event" then
        CancelBusy(npc, st)
        LeaveLine(npc, st)
        Release(npc, st)
        -- away from it
        local away = IsValid(threat) and (npos - threat:GetPos()) or VectorRand()
        away.z = 0
        if away:LengthSqr() < 1 then away = Vector(1, 0, 0) end
        away = away:GetNormalized()
        local dest
        for _ = 1, 8 do
            local p = LC.RandomWanderPos("citizen", npos + away * 700)
            if p and (p - npos):GetNormalized():Dot(away) > 0.2 then dest = p break end
        end
        GoTo(npc, st, dest or LC.RandomWanderPos("citizen", npos), true, nil)
        st.untilT = now + 6
    end
    -- the others round them run too
    LC.Scatter(npos, 450)
    -- and the nearest units come for it
    if IsValid(threat) and not threat:IsPlayer() then
        local near = {}
        for cop, cst in pairs(LC.NPCs) do
            if IsValid(cop) and IsSecurity(cst) and cst.state ~= "hostile" and not cst.test
                and cop:GetPos():DistToSqr(npos) < 1500 * 1500 then
                near[#near + 1] = { cop, cst, cop:GetPos():DistToSqr(npos) }
            end
        end
        table.sort(near, function(x, y) return x[3] < y[3] end)
        for i = 1, math.min(2, #near) do LC.MakeOneHostile(near[i][1], near[i][2], threat) end
    end
    hook.Run("LivingCityCitizenPanic", npc, threat)
    return true
end

hook.Add("EntityTakeDamage", "LivingCityCitizenPanic", function(victim, dmg)
    local st = LC.NPCs[victim]
    if not st or st.test or st.role ~= "citizen" then return end
    local att = dmg:GetAttacker()
    if not IsMonster(att) then return end
    local ok, err = pcall(LC.CitizenPanic, victim, st, att)
    if not ok then LC.Error("citizen panic", err) end
end)

-- Units deal with headcrabs and zombies: one that's bitten fights back at
-- once (a walking order otherwise has him ignore it while it eats him), and
-- one that sees one close by goes for it.
hook.Add("EntityTakeDamage", "LivingCityUnitsFightBack", function(victim, dmg)
    local st = LC.NPCs[victim]
    if not st or st.test or not IsSecurity(st) or st.state == "hostile" then return end
    local att = dmg:GetAttacker()
    if not IsValid(att) or att:IsPlayer() or not IsMonster(att) then return end
    st.provokedBy, st.provokedUntil = att, CurTime() + 10 -- (bitten: he fights back, even walking a prisoner in)
    LC.MakeOneHostile(victim, st, att)
end)

local function Monsters()
    local out = {}
    for e, kind in pairs(LC.Wildlife or {}) do
        if kind == "vermin" and IsValid(e) and e:Health() > 0 then out[#out + 1] = e end
    end
    for e, st in pairs(LC.NPCs) do
        if st.role == "zombie" and IsValid(e) and e:Health() > 0 then out[#out + 1] = e end
    end
    return out
end

local cvSpot = CreateConVar("lc_units_spot_monsters", "1", FLAGS, "Civil Protection units who see a headcrab or a zombie close by go for it")

function LC.UnitsSpotMonsters()
    if not cvSpot:GetBool() then return 0 end
    local list = Monsters()
    if #list == 0 then return 0 end
    local n = 0
    for npc, st in pairs(LC.NPCs) do
        if IsValid(npc) and IsSecurity(st) and not st.test and st.state ~= "hostile" and st.state ~= "workescort" and st.state ~= "event" then
            local pos, best, bd = npc:GetPos(), nil, 400 * 400
            for _, m in ipairs(list) do
                local d = m:GetPos():DistToSqr(pos)
                if d < bd and math.abs(m:GetPos().z - pos.z) < 120 then best, bd = m, d end
            end
            if best then
                local tr = util.TraceLine({ start = npc:EyePos(), endpos = best:WorldSpaceCenter(), mask = MASK_OPAQUE, filter = npc })
                if not tr.Hit or tr.Entity == best or tr.Fraction > 0.95 then
                    LC.MakeOneHostile(npc, st, best)
                    n = n + 1
                end
            end
        end
    end
    return n
end
timer.Create("LivingCityUnitsSpotMonsters", 1, 0, function()
    if not LC.Running then return end
    local ok, err = pcall(LC.UnitsSpotMonsters)
    if not ok then LC.Error("Civil Protection units and monsters", err) end
end)

hook.Add("PlayerUse", "LivingCityUse", function(ply, ent)
    local st = LC.NPCs[ent]
    if not st or st.test then return end
    if LC.StalkerCantSpeak and LC.StalkerCantSpeak(ply, ent) then return false end -- (a stalker: sv_livingcity_custody.lua)
    -- the engine's own "use" makes citizens talk to you as Gordon Freeman; we handle it instead
    if CurTime() < st.nextUse then return st.role == "citizen" and false or nil end
    st.nextUse = CurTime() + 3
    hook.Run("LivingCityPlayerUsedNPC", ply, ent, st)
    -- guarding a supply drop (sv_livingcity_convoy.lua): he answers, without leaving his post
    if st.supplyGuard and IsSecurity(st) and st.state ~= "hostile" then
        if LC.PlayerIsWanted(ply) and not LC.PlayerIsCP(ply) and LC.Surrender then return LC.Surrender(ply, ent) end
        Face(ent, ply:GetPos())
        local soldier = st.role == "soldier"
        if LC.PlayerIsCP(ply) or (LC.DisguisedAsCP and LC.DisguisedAsCP(ply)) then
            ent:EmitSound(soldier and "npc/combine_soldier/vo/affirmative.wav" or "npc/metropolice/vo/affirmative.wav", 75)
            ply:ChatPrint("[Civil Protection] \"Supply point secure. Hold the perimeter until the load moves on.\"")
        else
            ent:EmitSound(soldier and Pick({ "npc/combine_soldier/vo/contained.wav", "npc/combine_soldier/vo/affirmative2.wav" })
                or Pick({ "npc/metropolice/vo/movealong.wav", "npc/metropolice/vo/movealong3.wav", "npc/metropolice/vo/keepmoving.wav" }), 75)
            ply:ChatPrint("[Civil Protection] \"" .. Pick({ "Restricted supply point. Move along.", "Step away from the supplies, citizen.",
                "Nothing here for you. Keep moving." }) .. "\"")
        end
        return
    end
    if st.state == "event" then return st.role == "citizen" and false or nil end -- busy with something scripted
    if st.role == "citizen" then
        if st.state == "detained" or st.state == "jailed" or st.state == "escorted" or st.state == "busy" then return false end
        Face(ent, ply:GetPos())
        LeaveLine(ent, st)
        if st.state == "moving" then ent:SetSchedule(SCHED_IDLE_STAND) end
        if LC.PlayerIsCP(ply) then
            -- a Civil Protection player stops a citizen: they freeze and apologise
            ent:EmitSound(Vo(st.gender, Pick(CIT_NERVOUS)), 70)
            SetState(ent, st, "detained"); st.untilT = CurTime() + 10
            if (ply.lcStopHintAt or 0) < CurTime() then
                ply.lcStopHintAt = CurTime() + 300
                ply:ChatPrint("[Civil Protection] Stopped. With the Arrest Baton out: R to search them, right click to detain.")
            end
        else
            ent:EmitSound(Vo(st.gender, Pick(CIT_GREET)), 70)
            SetState(ent, st, "idle"); st.untilT = CurTime() + 4
        end
        return false
    elseif IsSecurity(st) and LC.PlayerIsWanted(ply) and not LC.PlayerIsCP(ply) and LC.Surrender then
        LC.Surrender(ply, ent) -- walking up to a unit and pressing E: hands up
    elseif IsSecurity(st) and st.state ~= "hostile" then
        Face(ent, ply:GetPos())
        if LC.PlayerIsCP(ply) or (LC.DisguisedAsCP and LC.DisguisedAsCP(ply)) then
            ent:EmitSound(st.role == "cop" and "npc/metropolice/vo/affirmative.wav" or "npc/combine_soldier/vo/affirmative.wav", 75)
        elseif st.role == "cop" then
            -- walking up to a unit and pressing E is talking to him, not crowding him
            ply.lcCopTalkUntil = CurTime() + 12
            if LC.QuestOf and LC.QuestOf[ply] then
                ent:EmitSound(Pick({ "npc/metropolice/vo/copy.wav", "npc/metropolice/vo/affirmative.wav", "npc/metropolice/vo/rodgerthat.wav" }), 75) -- probably reporting something: he acknowledges
            else
                LC.CopProvoked(ent, st, ply, CurTime()) -- pestering a unit is as bad as crowding one
            end
        end
    end
end)

hook.Add("EntityTakeDamage", "LivingCityDamage", function(victim, dmg)
    local st = LC.NPCs[victim]
    local attacker = dmg:GetAttacker()
    if not st or st.test or not IsValid(attacker) or not attacker:IsPlayer() then return end
    if st.role == "zombie" then return end -- shooting zombies is public service
    if st.role == "rebel" then return end -- and so, as far as the Combine is concerned, is shooting rebels

    -- Civil Protection players can rough up citizens without the NPC cops caring
    if LC.PlayerIsCP(attacker) and st.role == "citizen" then return end

    -- a unit that gets hurt remembers who did it, however far away they were
    if IsSecurity(st) or st.role == "scanner" then
        st.provokedBy, st.provokedUntil = attacker, CurTime() + 45
        attacker.lcAttackedSecurityAt = CurTime()
    end

    LC.Scatter(victim:GetPos(), 1500)

    -- a crime, and every cop comes for you
    -- (a scanner is city property, not a person)
    -- (one report per few seconds for a scanner: every bullet of a burst isn't a new offence)
    local isScanner = st.role == "scanner" or string.find(victim:GetClass(), "scanner", 1, true) ~= nil
    if isScanner and not IsSecurity(st) then
        if CurTime() >= (attacker.lcNextScanCrime or 0) then
            attacker.lcNextScanCrime = CurTime() + 5
            LC.ReportCrime(attacker, "Damaging city property")
        end
    else
        LC.ReportCrime(attacker, IsSecurity(st) and "Assaulting Civil Protection" or "Assaulting a citizen")
    end
    LC.MakeCopsHostile(attacker, victim:GetPos(), nil)
end)

hook.Add("EntityRemoved", "LivingCityRemoved", function(ent)
    local st = LC.NPCs[ent]
    if st then
        CleanupNPC(ent, st)
        LC.NPCs[ent] = nil
    end
end)

hook.Add("PlayerInitialSpawn", "LivingCityRelations", function()
    timer.Simple(1, function() if LC.Running then LC.RefreshRelations() end end)
end)

-- once you're dead, it's over
hook.Add("PlayerDeath", "LivingCityPlayerDeath", function(ply)
    timer.Simple(0, function() if IsValid(ply) and LC.Running then LC.CalmCops(ply) end end)
end)

hook.Add("InitPostEntity", "LivingCityAutostart", function()
    timer.Simple(5, function() if cvAutostart:GetBool() then LC.Start(nil) end end)
end)

------------------------------------------------------------------------
-- Console commands
------------------------------------------------------------------------

concommand.Add("lc_start", function(ply) if Allowed(ply) then LC.Start(ply) end end)
concommand.Add("lc_stop", function(ply) if Allowed(ply) then LC.Stop(ply) end end)

concommand.Add("lc_calm", function(ply)
    if not Allowed(ply) then return end
    LC.CalmCops(nil)
    Say(ply, "Civil Protection has stood down.")
end)

concommand.Add("lc_addpoint", function(ply, _, args)
    if not Allowed(ply) or not IsValid(ply) then return end
    local kind = string.lower(args[1] or "idle")
    if not LC.AddPoint(ply:GetPos(), ply:EyeAngles().y, kind, tonumber(args[2]) or 0) then
        Say(ply, "Kinds: idle, sit, sitchair, lean, queue, patrol, checkpoint, spawn, cell, release")
        return
    end
    Say(ply, string.format("Added %s point (%d total on this map).", kind, #LC.Points))
end)

concommand.Add("lc_removepoint", function(ply)
    if not Allowed(ply) or not IsValid(ply) then return end
    local kind = LC.RemoveNearestPoint(ply:GetPos(), 150)
    Say(ply, kind and ("Removed nearest " .. kind .. " point.") or "No point within 150 Civil Protection units.")
end)

concommand.Add("lc_status", function(ply)
    if not Allowed(ply) then return end
    local counts = {}
    for npc, st in pairs(LC.NPCs) do
        if IsValid(npc) then counts[st.role] = (counts[st.role] or 0) + 1 end
    end
    local lines, beats = table.Count(LC.Lines), #PatrolGroups()
    Say(ply, string.format("%s | event %s", LC.Running and "running" or "stopped", LC.Event or "none"))
    Say(ply, string.format("citizens %d/%d, cops %d/%d, soldiers %d/%d, scanners %d/%d, zombies %d/%d, rebels %d/%d",
        counts.citizen or 0, LC.CitizenTarget(), counts.cop or 0, cvCops:GetInt() + (LC.ExtraCops or 0),
        counts.soldier or 0, cvSoldiers:GetInt(), counts.scanner or 0, cvScanners:GetInt(),
        counts.zombie or 0, cvZombies:GetInt(), counts.rebel or 0, LC.RebelTarget and LC.RebelTarget() or 0))
    Say(ply, string.format("map nav %d (%s) | points %d | path nodes %d, links %d, unlinked %d | zones %d | lines %d | patrol beats %d",
        #LC.Fallback, LC.Source, #LC.Points, LC.NodeCount and LC.NodeCount() or 0,
        LC.LinkCount and LC.LinkCount() or 0, LC.OrphanNodes and #LC.OrphanNodes() or 0,
        #(LC.Zones or {}), lines, beats))
end)
