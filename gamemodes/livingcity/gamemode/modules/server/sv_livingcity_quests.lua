--[[
    Living City: quests

    Radiant-style jobs built on the fly from the live map: a real citizen to
    arrest, a real checkpoint to sabotage, your actual ration line and housing
    blocks. Each faction gets its own board:

      Civil Protection: Directives    Overwatch: Protocols    Administrator: Agenda
      Resistance: Operations          Citizen: Assignments    Infested: Urges

    Some steps are choices with d20 checks (d20 + skill against a difficulty).
    Skills come from rank and three traits your choices build over time:
    Loyalty, Sympathy, Corruption.

    Built for crowded servers as much as singleplayer:
      - no job ever targets a player; violence is only ever against NPCs
      - each faction's board holds a limited number of postings, scaled to how
        many people are in that faction
      - violent jobs are capped city-wide (one per lc_quest_violent_ratio players)
      - others in your faction can join your job as a squad (lc_quest_squad)

    F3, !jobs or lcq_board opens your board.
]]

if CLIENT then return end

for _, n in ipairs({ "lcq_board", "lcq_accept", "lcq_abandon", "lcq_state", "lcq_choice_open", "lcq_choice", "lcq_request" }) do
    util.AddNetworkString(n)
end

LC = LC or {}
LC.QuestOf = LC.QuestOf or {}       -- [ply] = the quest they're on (as owner or squad member)
LC.ActiveQuests = LC.ActiveQuests or {}
LC.Postings = LC.Postings or {}     -- [faction] = { posting, ... }
LC.QuestTemplates = {}

local FLAGS = bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED)
local cvOn       = CreateConVar("lc_quests", "1", FLAGS, "Offer quests")
local cvViolent  = CreateConVar("lc_quest_violent_ratio", "8", FLAGS, "One violent job city-wide per this many players (always at least one)")
local cvSquad    = CreateConVar("lc_quest_squad", "3", FLAGS, "Most people on one job")
local cvCooldown = CreateConVar("lc_quest_cooldown", "30", FLAGS, "Seconds between jobs for one player")
local cvPacing   = CreateConVar("lc_story_pacing", "45", FLAGS, "Seconds before the next part of a story appears")

local BOARDS = {
    cp = "Directives", ota = "Protocols", admin = "Agenda",
    resistance = "Operations", citizen = "Assignments", zombie = "Urges",
}

local nextId = 1
local function Pick(t) return t[math.random(#t)] end

------------------------------------------------------------------------
-- Who's asking, and what they're good at
------------------------------------------------------------------------

function LC.QuestFaction(ply)
    local f = ply:GetNW2String("lcf_faction", "")
    if f == "vort" or f == "stalker" then return "citizen" end -- shackled vortigaunts and stalkers work the Union's shifts
    if f == "cp" and LCF.IsOverwatch(ply) then return "ota" end -- (the Overwatch ranks have their own board: Protocols, and Civil Protection's)
    if f ~= "" then return f end
    if LC.PlayerIsZombie(ply) then return "zombie" end
    if LC.PlayerIsCP(ply) then return "cp" end
    return "citizen"
end

local function RankIndex(ply) return ply:GetNW2Int("lcf_rank", 1) end
local function Special(ply) return ply:GetNW2String("lcf_special", "") end

local TRAITS = { loyalty = true, sympathy = true, corruption = true }
function LC.Trait(ply, name) return tonumber(ply:GetPData("lcq_" .. name, 0)) or 0 end
function LC.AddTrait(ply, name, d)
    if not TRAITS[name] or not IsValid(ply) then return end
    ply:SetPData("lcq_" .. name, math.max(0, LC.Trait(ply, name) + d))
    ply:SetNW2Int("lcq_" .. name, LC.Trait(ply, name))
end
-- Shown on the HUD, top left (cl_livingcity_needs.lua): kept up to date as they change, and now and then
-- (a new life clears them elsewhere).
local function SendTraits(ply)
    if not IsValid(ply) then return end
    for name in pairs(TRAITS) do
        local v = LC.Trait(ply, name)
        if ply:GetNW2Int("lcq_" .. name, -1) ~= v then ply:SetNW2Int("lcq_" .. name, v) end
    end
end
hook.Add("PlayerSpawn", "LivingCityTraitsHUD", function(ply) timer.Simple(1, function() SendTraits(ply) end) end)
timer.Create("LivingCityTraitsHUD", 15, 0, function() for _, p in ipairs(player.GetAll()) do SendTraits(p) end end)

local SKILLS = {
    authority = function(ply)
        return math.floor(RankIndex(ply) / 2) + (LC.PlayerIsCP(ply) and 1 or 0) + math.floor(LC.Trait(ply, "loyalty") / 3)
    end,
    empathy = function(ply)
        return math.floor(LC.Trait(ply, "sympathy") / 2) + (Special(ply) == "chaplain" and 3 or 0)
    end,
    guile = function(ply)
        return math.floor(LC.Trait(ply, "corruption") / 2)
            + (LC.QuestFaction(ply) == "resistance" and math.floor(RankIndex(ply) / 2) or 0)
    end,
    nerve = function(ply) return math.floor((tonumber(ply:GetPData("lcq_done", 0)) or 0) / 5) end,
}

function LC.SkillMod(ply, skill)
    local fn = SKILLS[skill]
    return math.Clamp(fn and fn(ply) or 0, 0, 8)
end

------------------------------------------------------------------------
-- Story memory: what you've done, and where you are in each chain.
-- Saved by SteamID, so it follows you across maps and restarts.
------------------------------------------------------------------------

function LC.Story(ply)
    if ply.lcStory then return ply.lcStory end
    local raw = ply:GetPData("lcq_story", "")
    local t = raw ~= "" and util.JSONToTable(raw) or nil
    t = istable(t) and t or {}
    t.counters = istable(t.counters) and t.counters or {}
    t.chains = istable(t.chains) and t.chains or {}
    t.notified = istable(t.notified) and t.notified or {}
    t.flags = istable(t.flags) and t.flags or {}
    ply.lcStory = t
    return t
end

function LC.SaveStory(ply)
    if IsValid(ply) and ply.lcStory then ply:SetPData("lcq_story", util.TableToJSON(ply.lcStory)) end
end

function LC.Bump(ply, counter, n)
    if not IsValid(ply) or not ply:IsPlayer() then return end
    local st = LC.Story(ply)
    st.counters[counter] = (st.counters[counter] or 0) + (n or 1)
    LC.SaveStory(ply)
    hook.Run("LivingCityCounter", ply, counter, n or 1)
end

function LC.Counter(ply, counter) return LC.Story(ply).counters[counter] or 0 end

-- Story flags: get with LC.StoryFlag(ply, name), set with LC.StoryFlag(ply, name, value).
function LC.StoryFlag(ply, name, value)
    local st = LC.Story(ply)
    if value == nil then return st.flags[name] end
    st.flags[name] = value
    LC.SaveStory(ply)
    return value
end

------------------------------------------------------------------------
-- Reading the world
------------------------------------------------------------------------

local CRIMES = {
    "hoarding ration units", "unauthorized assembly", "possession of contraband", "failing a loyalty check",
    "breaking curfew", "speaking out against the Combine", "trading ration units", "moving home without registering",
    "tampering with a city terminal", "harboring an anticitizen",
}
-- Half-Life 2 has no proper elderly citizen model; these are its older faces.
LC.ELDERLY_MODELS = {
    "models/humans/group01/male_02.mdl", "models/humans/group01/male_07.mdl", "models/humans/group01/male_09.mdl",
}

local CONTRABAND = {
    { "an unregistered radio", "models/props_lab/citizenradio.mdl" },
    { "a stash of ration units", "models/props_junk/cardboard_box004a.mdl" },
    { "Resistance pamphlets", "models/props_c17/paper01.mdl" },
    { "a weapons cache", "models/items/ammocrate_smg1.mdl" },
}
local TRASH = {
    "models/props_junk/garbage_metalcan001a.mdl", "models/props_junk/garbage_milkcarton002a.mdl",
    "models/props_junk/garbage_newspaper001a.mdl", "models/props_junk/popcan01a.mdl",
}
local NOTES = {
    "The note says only: the canal gate opens at four.",
    "A child's drawing of a lambda (the Resistance symbol) and an address. You memorize the address and burn the note.",
    "Coordinates, and a single word: Ravenholm. You decide not to go.",
    "A list of Civil Protection unit numbers. Two are crossed out.",
}

local function CitizenID() return string.format("#%02d-%03d", math.random(10, 99), math.random(100, 999)) end

local DIRS = { "east", "north-east", "north", "north-west", "west", "south-west", "south", "south-east" }
local function Compass(from, to)
    local d = to - from
    local ang = math.deg(math.atan2(d.y, d.x)) % 360
    return DIRS[math.floor((ang + 22.5) / 45) % 8 + 1]
end

function LC.DescribePlace(pos, from)
    for _, z in ipairs(LC.ZonesOfKind("block")) do
        if (z.group or 0) > 0 and LCZ.Contains(z, pos, 400) then return "near " .. LC.BlockName(z.group) end
    end
    if LC.InRebelZone(pos) then return "in rebel territory" end
    for _, z in ipairs(LC.ZonesOfKind("prison")) do
        if LCZ.Contains(z, pos, 300) then return "by the prison" end
    end
    local function near(kind, r)
        for _, p in ipairs(LC.PointsOfKind(kind)) do if p.pos:DistToSqr(pos) < r * r then return true end end
        return false
    end
    if near("queue", 600) then return "by the ration line" end
    if near("checkpoint", 500) then return "at a checkpoint" end
    if near("spawn", 400) then return "outside an apartment doorway" end
    if from then return string.format("%d metres %s of you", math.floor(from:Distance(pos) * 0.019), Compass(from, pos)) end
    return "somewhere in the city"
end
local Place = LC.DescribePlace

-- Citizen jobs never send you onto Combine ground or into the infestation, and
-- NPCs placed there (patients, targets) wouldn't survive it.
local function GoodSpot(p, role)
    return (role and role ~= "citizen") or not LC.CitizenSpotOK or LC.CitizenSpotOK(p)
end

local function Spot(ply, minD, maxD, role)
    local origin = ply:GetPos()
    -- somewhere on your own level first: a job shouldn't start five floors down
    for _ = 1, 40 do
        local p = LC.RandomWanderPos(role or "citizen", origin)
        if not p then break end
        local d = p:Distance(origin)
        if d >= minD and d <= maxD and math.abs(p.z - origin.z) < 200 and GoodSpot(p, role) then return p end
    end
    for _ = 1, 40 do
        local p = LC.RandomWanderPos(role or "citizen")
        if not p then break end
        local d = p:Distance(origin)
        if d >= minD and d <= maxD and GoodSpot(p, role) then return p end
    end
    for _ = 1, 20 do
        local p = LC.RandomWanderPos(role or "citizen")
        if p and GoodSpot(p, role) then return p end
    end
    return LC.RandomWanderPos(role or "citizen")
end

-- Real bins already standing in the map: the ones the server can see as
-- entities, plus the map's own static props (read from the map file).
-- Returns { pos, ent (nil for a static prop), model }, up to n of them.
local BIN_CLASSES = { lc_citybin = true, prop_physics = true, prop_dynamic = true, prop_physics_multiplayer = true, prop_physics_override = true }

local function FindBins(ply, minD, maxD, n, dumpstersOnly)
    local origin = ply:GetPos()
    local out = {}
    local function consider(pos, ent, model)
        if dumpstersOnly and not string.find(model, "dumpster", 1, true) then return end
        local d = pos:Distance(origin)
        if d >= minD and d <= maxD and GoodSpot(pos) then out[#out + 1] = { pos = pos, ent = ent, model = model } end
    end
    for _, e in ipairs(ents.GetAll()) do
        if IsValid(e) and BIN_CLASSES[e:GetClass()] and not e.lcQuest then
            local m = string.lower(e:GetModel() or "")
            if LC.IsBinModel and LC.IsBinModel(m) then consider(e:GetPos(), e, m) end
        end
    end
    for _, b in ipairs(LC.StaticBins or {}) do consider(b.pos, nil, b.model or "") end
    -- shuffled, then the first n that aren't stacked on each other
    for i = #out, 2, -1 do local j = math.random(i); out[i], out[j] = out[j], out[i] end
    local picked = {}
    for _, b in ipairs(out) do
        if #picked >= n then break end
        local ok = true
        for _, o in ipairs(picked) do if o.pos:DistToSqr(b.pos) < 150 * 150 then ok = false end end
        if ok then picked[#picked + 1] = b end
    end
    return picked
end

-- A walk: each stop a short way on from the last, on the same level as the first,
-- not a tour of the whole city. Returns up to n points.
local function Route(ply, n, minStep, maxStep)
    local first = Spot(ply, 300, 1400)
    if not first then return {} end
    local out = { first }
    local prev = first
    for _ = 2, n do
        local nextP
        for _ = 1, 30 do
            local p = LC.RandomWanderPos("citizen", prev)
            if p then
                local d = p:Distance(prev)
                local far = true
                for _, q in ipairs(out) do if q:DistToSqr(p) < (minStep * 0.8) ^ 2 then far = false end end
                if d >= minStep and d <= maxStep and math.abs(p.z - first.z) < 160 and far and GoodSpot(p) then nextP = p break end
            end
        end
        if not nextP then break end
        out[#out + 1] = nextP
        prev = nextP
    end
    return out
end

local function SpotsNear(center, n, radius)
    local out = {}
    for _ = 1, 60 do
        if #out >= n then break end
        local p = LC.RandomWanderPos("citizen")
        if p and p:DistToSqr(center) < radius * radius then
            local far = true
            for _, q in ipairs(out) do if q:DistToSqr(p) < 120 * 120 then far = false end end
            if far then out[#out + 1] = p end
        end
    end
    while #out < n do
        local a = math.random() * math.pi * 2
        out[#out + 1] = center + Vector(math.cos(a), math.sin(a), 0) * math.random(80, radius * 0.6)
    end
    return out
end

-- Where someone would actually leave or hide something: on a table, counter
-- or shelf if there's one around, otherwise on the floor against a wall.
-- Never in a doorway or the middle of the street.
local SURFACE_CLASSES = { prop_physics = true, prop_dynamic = true, prop_physics_multiplayer = true, prop_physics_override = true }

local function NearDoor(pos, r) return LC.NearDoor and LC.NearDoor(pos, r) ~= nil end

local function FarFromAll(list, p, d)
    for _, q in ipairs(list) do if q:DistToSqr(p) < d * d then return false end end
    return true
end

-- The top of a table or counter standing at pos, if it has a flat top at a sensible height.
local function TopOf(pos, ent)
    local tr = util.TraceLine({ start = pos + Vector(0, 0, 110), endpos = pos - Vector(0, 0, 4), mask = MASK_SOLID })
    if not tr or not tr.Hit or tr.StartSolid then return nil end
    if ent and tr.Entity ~= ent and IsValid(tr.Entity) then return nil end -- something else sits on it
    if not tr.HitNormal or tr.HitNormal.z < 0.85 then return nil end
    local h = tr.HitPos.z - pos.z
    if h < 8 or h > 90 then return nil end
    return tr.HitPos
end

local function SurfaceSpots(center, radius, out, n)
    local cands = {}
    for _, sp in ipairs(LC.StaticSurfaces or {}) do
        if sp.pos:DistToSqr(center) < radius * radius and math.abs(sp.pos.z - center.z) < 200 then cands[#cands + 1] = { pos = sp.pos } end
    end
    for _, e in ipairs(ents.FindInSphere(center, radius)) do
        if IsValid(e) and SURFACE_CLASSES[e:GetClass()] and not e.lcQuest and LC.IsSurfaceModel and LC.IsSurfaceModel(e:GetModel())
            and math.abs(e:GetPos().z - center.z) < 200 then
            cands[#cands + 1] = { pos = e:GetPos(), ent = e }
        end
    end
    for i = #cands, 2, -1 do local j = math.random(i); cands[i], cands[j] = cands[j], cands[i] end
    for _, c in ipairs(cands) do
        if #out >= n then break end
        local top = TopOf(c.pos, c.ent)
        if top and not NearDoor(top, 120) and FarFromAll(out, top, 90) and (not LC.ItemSpotOK or LC.ItemSpotOK(top, 24)) then out[#out + 1] = top end
    end
end

local WALL_DIRS = 8
local function WallSpot(base)
    local off = math.random() * math.pi * 2
    for i = 0, WALL_DIRS - 1 do
        local a = off + i * (math.pi * 2 / WALL_DIRS)
        local dir = Vector(math.cos(a), math.sin(a), 0)
        local from = base + Vector(0, 0, 16)
        local tr = util.TraceLine({ start = from, endpos = from + dir * 320, mask = MASK_NPCSOLID_BRUSHONLY })
        if tr and tr.Hit and not tr.StartSolid and tr.HitNormal and math.abs(tr.HitNormal.z) < 0.3 then
            local n = Vector(tr.HitNormal.x, tr.HitNormal.y, 0)
            local spot = tr.HitPos + n * 14
            local ground = LC.GroundAt and LC.GroundAt(spot) or spot
            if math.abs(ground.z - base.z) < 40 and not NearDoor(ground, 130) then return ground end
        end
    end
    return nil
end

-- Somewhere a person can actually get to and pick it up (the owner, 1 November: a job's item went under
-- some stairs, into space walled off by the map): near a path node on the same floor, in plain sight of
-- it, with room to stand over it. (A map with no path nodes: only the room overhead is checked.)
local function ItemSpotOK(p, head)
    if not p or not util.TraceLine then return true end
    local up = util.TraceLine({ start = p + Vector(0, 0, 2), endpos = p + Vector(0, 0, head or 56), mask = MASK_SOLID_BRUSHONLY })
    if up and (up.Hit or up.StartSolid) then return false end
    local nodes = {}
    for _, nd in ipairs(LC.NavNodesNear and LC.NavNodesNear(p, 320) or {}) do nodes[#nodes + 1] = nd.pos end
    for _, nd in pairs(LC.Nodes or {}) do
        if nd.pos and nd.pos:DistToSqr(p) < 320 * 320 then nodes[#nodes + 1] = nd.pos end
    end
    if #nodes == 0 then return true end
    for _, np in ipairs(nodes) do
        if math.abs(np.z - p.z) < 64 then
            local tr = util.TraceLine({ start = np + Vector(0, 0, 36), endpos = p + Vector(0, 0, 12), mask = MASK_SOLID_BRUSHONLY })
            if tr and not tr.StartSolid and (not tr.Hit or tr.Fraction > 0.97) then return true end
        end
    end
    return false
end
LC.ItemSpotOK = ItemSpotOK

local function HideSpots(center, n, radius, floorOnly)
    local out = {}
    if not floorOnly then SurfaceSpots(center, radius, out, math.min(n, math.random(1, n))) end
    for _ = 1, 80 do
        if #out >= n then break end
        local base = LC.RandomWanderPos("citizen", center)
        if not base or base:DistToSqr(center) > radius * radius then
            local a = math.random() * math.pi * 2
            base = center + Vector(math.cos(a), math.sin(a), 0) * math.random(0, radius * 0.7)
            base = LC.GroundAt and LC.GroundAt(base) or base
        end
        local w = WallSpot(base)
        if w and w:DistToSqr(center) < (radius * 1.3) ^ 2 and FarFromAll(out, w, 110) and ItemSpotOK(w) then out[#out + 1] = w end
    end
    if not floorOnly and #out < n then SurfaceSpots(center, radius, out, n) end
    -- last resort: open ground, but still not in a doorway
    if #out < n then
        for _, p in ipairs(SpotsNear(center, (n - #out) * 3, radius)) do
            if #out >= n then break end
            if not NearDoor(p, 130) and FarFromAll(out, p, 100) and ItemSpotOK(p) then out[#out + 1] = p end
        end
    end
    -- still short: where people walk (a wander spot near it), never a guess in the open
    for _ = 1, 40 do
        if #out >= n then break end
        local p = LC.RandomWanderPos("citizen", center)
        if p and p:DistToSqr(center) < (radius * 1.5) ^ 2 and FarFromAll(out, p, 80) then out[#out + 1] = p end
    end
    if #out < n then
        for _, p in ipairs(SpotsNear(center, n - #out, radius)) do out[#out + 1] = p end
    end
    return out
end

local FREE_STATES = { idle = true, moving = true, inline = true, busy = true }

local function RandomCitizen(near, maxD)
    local list = {}
    for npc, st in pairs(LC.NPCs or {}) do
        if IsValid(npc) and st.role == "citizen" and not st.test and not st.questLock and not st.leaving
            and FREE_STATES[st.state] and (not near or npc:GetPos():DistToSqr(near) < maxD * maxD) then
            list[#list + 1] = npc
        end
    end
    return #list > 0 and Pick(list) or nil
end

local function CountRole(role)
    local n = 0
    for npc, st in pairs(LC.NPCs or {}) do if IsValid(npc) and st.role == role and not st.test then n = n + 1 end end
    return n
end

local function SecurityCount()
    local n = 0
    for npc, st in pairs(LC.NPCs or {}) do if IsValid(npc) and LC.IsSecurity(st) then n = n + 1 end end
    return n
end

-- A little stealth. How far a unit's eye reaches for you: half as far while you crouch,
-- less again when you're slow and quiet, and less in the dark (your own game says how lit
-- you are). lc_stealth 0: no stealth, as before.
local cvStealth = CreateConVar("lc_stealth", "1", bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED), "Crouching, moving slowly and keeping to the dark make you harder for units to see")
function LC.StealthRange(ply, dist)
    if not cvStealth:GetBool() or not IsValid(ply) or not ply:IsPlayer() then return dist end
    local f = 1
    if ply:Crouching() then
        f = f * 0.5
        if ply:GetVelocity():Length2D() < 60 then f = f * 0.85 end -- (creeping, or keeping still)
    end
    local light = LC.TrustedLight(ply)
    if light then
        if light < 0.06 then f = f * 0.55 elseif light < 0.15 then f = f * 0.75 end
    end
    return dist * f
end
-- In front of him (crouched, you can creep past behind a unit's back): within half degrees of where he faces.
function LC.InViewOf(npc, pos, half)
    local f = npc:GetForward()
    local d = pos - npc:GetPos()
    f.z, d.z = 0, 0
    if d:LengthSqr() < 1 then return true end
    f:Normalize() d:Normalize()
    return f:Dot(d) > math.cos(math.rad(half or 70))
end
-- Does this unit see you? (the reach above, a clear line, and crouched: only from the front)
function LC.UnitSees(npc, ply, dist)
    local r = LC.StealthRange(ply, dist)
    if npc:GetPos():DistToSqr(ply:GetPos()) > r * r then return false end
    if cvStealth:GetBool() and ply:IsPlayer() and ply:Crouching() and not LC.InViewOf(npc, ply:GetPos(), 70) then return false end
    return true
end

function LC.SeenBySecurity(ply, dist)
    local eye = ply:EyePos()
    for npc, st in pairs(LC.NPCs or {}) do
        if IsValid(npc) and LC.IsSecurity(st) and LC.UnitSees(npc, ply, dist) then
            local tr = util.TraceLine({ start = npc:EyePos(), endpos = eye, mask = MASK_OPAQUE, filter = npc })
            if tr.Fraction > 0.97 and not (LC.SmokeBlocks and LC.SmokeBlocks(npc:EyePos(), eye)) then return true end
        end
    end
    return false
end

util.AddNetworkString("lc_light")
net.Receive("lc_light", function(_, ply)
    if (ply.lcLightAt or 0) > CurTime() then return end
    ply.lcLightAt = CurTime() + 0.5
    ply.lcLight = math.Clamp(net.ReadFloat() or 1, 0, 1)
end)

-- The light level comes from the player's own game (the server can't see light), so it's
-- checked against what the server does know: a flashlight on, or open sky over them in the
-- daytime, and they're not in the dark, whatever their game says.
function LC.TrustedLight(ply)
    local light = ply.lcLight
    if not light or light >= 0.15 then return light end
    if ply.FlashlightIsOn and ply:FlashlightIsOn() then return 1 end
    if not (LC.IsNight and LC.IsNight()) then -- (open sky in daylight is never dark, power or no power)
        local up = util.TraceLine({ start = ply:EyePos(), endpos = ply:EyePos() + Vector(0, 0, 4000), mask = MASK_SOLID_BRUSHONLY })
        if up and up.HitSky then return 1 end
    end
    return light
end

local function NearestZone(kind, pos)
    local best, bd
    for _, z in ipairs(LC.ZonesOfKind(kind)) do
        local d = z.pos:DistToSqr(pos)
        if not bd or d < bd then best, bd = z, d end
    end
    return best
end

-- Somewhere safe for the Resistance: rebel territory if there is any, else far away.
local function SafeHouse(ply)
    local z = NearestZone("rebel", ply:GetPos())
    if z then return z.pos, math.max(150, z.r * 0.8), "rebel territory" end
    local p = Spot(ply, 1500, 5000) or Spot(ply, 300, 1500) -- (somewhere nearer, if nothing far off will do)
    if not p then return nil end -- (nowhere to meet right now: the job waits and tries again, rather than an error)
    return p, 150, Place(p, ply:GetPos())
end

local function IsZombieNPC(npc)
    local c = npc:GetClass()
    return string.find(c, "zombie", 1, true) ~= nil or string.find(c, "headcrab", 1, true) ~= nil
end

------------------------------------------------------------------------
-- Quest machinery
------------------------------------------------------------------------

local function Members(q)
    local out = {}
    for _, p in ipairs(q.members) do if IsValid(p) then out[#out + 1] = p end end
    return out
end

local function AnyMemberNear(q, pos, r, crouch)
    for _, p in ipairs(Members(q)) do
        if p:Alive() and p:GetPos():DistToSqr(pos) < r * r and (not crouch or p:Crouching()) then return p end
    end
    return nil
end

local function Stage(q) return q.stages[q.stage] end

local function Lock(q, npc)
    local st = LC.NPCs[npc]
    if st then st.questLock = q; q.marked[npc] = true end
end

local function Unlock(q)
    for npc in pairs(q.marked) do
        local st = IsValid(npc) and LC.NPCs[npc]
        if st and st.questLock == q then
            st.questLock = nil
            if st.state == "event" then st.eventUntil = 0 end
        end
    end
    q.marked = {}
end

local function Freeze(npc, secs)
    local st = LC.NPCs[npc]
    if not st then return end
    if LC.LeaveLine then LC.LeaveLine(npc, st) end
    npc:SetSchedule(SCHED_IDLE_STAND)
    LC.SetState(npc, st, "event")
    st.eventUntil = CurTime() + secs
end

-- The floor under a spot: wander spots and scattered search spots can sit a
-- little above the ground (or over a ledge), and things shouldn't hover.
local function GroundAt(pos)
    local tr = util.TraceLine({ start = pos + Vector(0, 0, 40), endpos = pos - Vector(0, 0, 600), mask = MASK_NPCSOLID_BRUSHONLY })
    if tr and tr.Hit and not tr.StartSolid then return tr.HitPos end
    return pos
end
LC.GroundAt = GroundAt

-- loose: a small thing lying about (evidence, trash, a flyer). It has physics
-- and settles where it lands. Everything else (bins, fixtures) stands still.
local function SpawnItem(q, model, pos, keep, loose)
    local e = ents.Create("prop_physics")
    if not IsValid(e) then return nil end
    e:SetModel(model)
    local ground = GroundAt(pos)
    -- somewhere nobody can get to (under stairs, walled-off space): the nearest spot where people walk instead
    if LC.ItemSpotOK and not LC.ItemSpotOK(ground, 24) then
        local best, bd
        for _, nd in ipairs(LC.NavNodesNear and LC.NavNodesNear(ground, 500) or {}) do
            local d = nd.pos:DistToSqr(ground)
            if (not bd or d < bd) and math.abs(nd.pos.z - ground.z) < 120 then best, bd = nd.pos, d end
        end
        if not best then
            local w = LC.RandomWanderPos and LC.RandomWanderPos("citizen", ground)
            if w and w:DistToSqr(ground) < 600 * 600 then best = w end
        end
        if best then ground = GroundAt(best + Vector(math.Rand(-20, 20), math.Rand(-20, 20), 0)) end
    end
    local lift = e.OBBMins and -e:OBBMins().z or 0
    e:SetPos(ground + Vector(0, 0, math.max(0, lift) + 2)) -- resting on the floor, not in it
    e:SetAngles(Angle(0, math.random(0, 359), 0))
    e:Spawn()
    local phys = e.GetPhysicsObject and e:GetPhysicsObject()
    if IsValid(phys) then
        if loose then
            phys:EnableMotion(true)
            phys:Wake()
        else
            phys:EnableMotion(false)
        end
    end
    if not keep then
        e.lcQuest = q
        q.ents[#q.ents + 1] = e
    end
    return e
end

local function Boom(pos)
    if sound and sound.Play then sound.Play("ambient/explosions/explode_4.wav", pos, 90) end
    if util.Effect and EffectData then
        local ed = EffectData()
        ed:SetOrigin(pos)
        util.Effect("Explosion", ed, true, true)
    end
end

local SendState, SendStateAll, EnterStage

-- She, not he: when the person a job is about is a woman, the job's words follow her (the owner
-- noticed "him" for women). Sentence by sentence: one that's about a unit, a guard, a father or
-- another fixed man is left alone. The person: the stage's own NPC, or the job's target or actor.
local SHE = { he = "she", him = "her", his = "her", himself = "herself", He = "She", Him = "Her", His = "Her", Himself = "Herself" }
local FIXED_MALE = { "unit", "units", "officer", "guard", "guards", "soldier", "soldiers", "quartermaster", "kleiner", "grigori", "father", "brother",
    "son", "man", "men", "foreman", "dispatch", "metrocop", "overwatch", "boy", "husband", "papa", "dad", "priest", "technician", "supervisor", "scientist", "elite", "stalker" }
local function FocusGender(q, st)
    local d = q and q.data or {}
    local e = (st and IsValid(st.npc) and st.npc) or (IsValid(d.target) and d.target) or (IsValid(d.actor) and d.actor) or nil
    local s = e and LC.NPCs[e]
    if s and s.gender then return s.gender end
    if IsValid(e) and e.GetModel and string.find(string.lower(e:GetModel() or ""), "female", 1, true) then return "female" end
    return nil
end
function LC.FitPronouns(q, text, st)
    if type(text) ~= "string" or text == "" or not q then return text end
    if FocusGender(q, st or (q.stages and q.stages[q.stage])) ~= "female" then return text end
    return (string.gsub(text, "[^%.!%?]+[%.!%?]*", function(sent)
        local low = string.lower(sent)
        for _, w in ipairs(FIXED_MALE) do
            if string.find(low, "%f[%a]" .. w .. "%f[%A]") then return sent end
        end
        return (string.gsub(sent, "%f[%a](%a+)%f[%A]", function(w) return SHE[w] or w end))
    end))
end

local function Narrate(q, text)
    text = LC.FitPronouns(q, text)
    q.narration = text
    for _, p in ipairs(Members(q)) do p:ChatPrint("[" .. q.board .. "] " .. text) end
end

local function InsertStages(q, list)
    for i, s in ipairs(list) do table.insert(q.stages, q.stage + i, s) end
end

local function Finish(q, success, why)
    if q.done then return end
    q.done = true
    LC.ActiveQuests[q] = nil
    if q.onFinish then
        local ok, err = pcall(q.onFinish, q, success)
        if not ok then LC.Error("quest finish " .. tostring(q.title), err) end
    end
    if q.posting then q.posting.q = nil; q.posting.dead = true end
    Unlock(q)
    for _, e in ipairs(q.ents) do
        if IsValid(e) then
            local est = LC.NPCs[e]
            if est and (est.state == "escorted" or est.state == "jailed" or est.jailUntil) then
                -- an arrested story character stays in the world and serves their sentence
                est.unmanaged = nil
                est.leaveAt = CurTime() + 600
            else
                e:Remove()
            end
        end
    end

    for _, p in ipairs(Members(q)) do
        LC.QuestOf[p] = nil
        p.lcqNext = CurTime() + cvCooldown:GetFloat()
        if success then
            local share = (p == q.owner) and 1 or 0.75
            local xp = math.floor((q.reward + (q.bonus or 0)) * share)
            if LC.FullStomachXP then xp = LC.FullStomachXP(p, xp) end -- (well fed: more done)
            if xp > 0 and LC.AddXP then LC.AddXP(p, xp, q.title) end
            p:SetPData("lcq_done", (tonumber(p:GetPData("lcq_done", 0)) or 0) + 1)
            p:ChatPrint(string.format("[%s] Complete: %s%s", q.board, q.title, xp > 0 and string.format(" (+%d XP)", xp) or ""))
            p:EmitSound("buttons/bell1.wav", 60)
        else
            p:ChatPrint(string.format("[%s] Failed: %s%s", q.board, q.title, why and (" (" .. why .. ")") or ""))
        end
        hook.Run(success and "LivingCityQuestComplete" or "LivingCityQuestFailed", p, q)
        SendState(p)
    end
    if q.chain and IsValid(q.owner) and LC.AdvanceChain then LC.AdvanceChain(q, success) end
    if success then
        for _, p in ipairs(Members(q)) do if LC.CheckUnlocks then LC.CheckUnlocks(p) end end
    end
    LC.Log("info", string.format("Quest %s: %s [%s]%s", success and "complete" or "failed", q.title, q.tmpl.id,
        why and (" (" .. why .. ")") or ""))
end
LC.FinishQuest = Finish

local function Advance(q)
    local st = Stage(q)
    if st and st.onDone then st.onDone(q, st) end
    if q.done then return end
    q.stage = q.stage + 1
    if q.stage > #q.stages then return Finish(q, true) end
    EnterStage(q)
end

local function OpenChoice(q, st)
    if not IsValid(q.owner) then return end
    local opts = {}
    for i, o in ipairs(st.options) do
        if not o.when or o.when(q) then
            opts[#opts + 1] = {
                i = i, text = LC.FitPronouns(q, o.text, st),
                skill = o.check and o.check[1], dc = o.check and o.check[2],
                mod = o.check and LC.SkillMod(q.owner, o.check[1]),
            }
        end
    end
    LC.SendCompressed("lcq_choice_open", { qid = q.id, title = q.title, prompt = LC.FitPronouns(q, st.prompt, st), options = opts }, { q.owner })
end

function EnterStage(q)
    local st = Stage(q)
    st.got, st.progress, st.seen = 0, 0, {}
    if st.onEnter and st.onEnter(q, st) == false then
        return Finish(q, false, st.failText or "the job's target couldn't be found")
    end
    -- heading for a housing block (or rebel territory, or the prison): walking
    -- into the zone counts, not just its exact center
    if st.pos and (st.kind == "goto" or st.kind == "deliver" or st.kind == "escort") then
        for _, z in ipairs(LC.Zones or {}) do
            if (z.kind == "block" or z.kind == "rebel" or z.kind == "prison") and z.pos:DistToSqr(st.pos) < 16 then
                st.r = math.max(st.r or 0, z.r * 0.9)
            end
        end
    end
    if st.kind == "collect" then
        st.items = {}
        for _, pos in ipairs(st.spots) do
            -- pick the model first, so the physics matches what you see
            local model = st.models and Pick(st.models) or st.model or Pick(TRASH)
            local e = SpawnItem(q, model, pos, nil, true)
            if e then st.items[e] = true end
        end
    elseif st.kind == "pickup" then
        st.item = SpawnItem(q, st.model, st.pos, nil, true)
    elseif st.kind == "choice" then
        OpenChoice(q, st)
    end
    if st.narrate then Narrate(q, st.narrate) end
    SendStateAll(q)
end

------------------------------------------------------------------------
-- State for the HUD tracker
------------------------------------------------------------------------

local function MarkerFor(q, st, viewer)
    if st.kind == "collect" and st.items then
        local best, bd
        for e in pairs(st.items) do
            if IsValid(e) then
                local d = e:GetPos():DistToSqr(viewer:GetPos())
                if not bd or d < bd then best, bd = e, d end
            end
        end
        return best, nil
    end
    local ent = st.npc or st.item
    if IsValid(ent) then return ent, nil end
    return nil, st.pos
end

function SendState(ply)
    local q = LC.QuestOf[ply]
    if not q or q.done then
        ply.lcQStateKey = nil
        LC.SendCompressed("lcq_state", { active = false }, { ply })
        return
    end
    local st = Stage(q)
    local forgetting = (ply.lcForgetUntil or 0) > CurTime()
    local t = {
        active = true, id = q.id, title = q.title, board = q.board, objective = LC.FitPronouns(q, st and st.text or "", st),
        left = math.max(0, math.floor(q.expires - CurTime())), members = #Members(q),
        narration = q.narration, step = q.stage, steps = #q.stages, owner = q.owner == ply,
    }
    if st then
        if st.need and not st.untallied then t.progress = string.format("%d/%d", st.got or 0, st.need) end
        if st.secs then t.progress = string.format("%ds / %ds", math.floor(st.progress or 0), st.secs) end
        local ent, pos = MarkerFor(q, st, ply)
        -- always send where it is too: far-away entities don't exist on the client
        if IsValid(ent) then
            t.ent = ent:EntIndex()
            pos = ent:GetPos()
        end
        if pos then t.pos = { math.floor(pos.x), math.floor(pos.y), math.floor(pos.z) } end
        t.choice = st.kind == "choice" and not st.resolved
        if st.kind == "tail" then t.suspicion, t.seen = math.floor(st.suspicion or 0), st.seen == true end
    end
    if forgetting then
        t.objective = "You can't remember what you were doing: Breen's water has clouded your memory. It comes back in about a minute."
        t.progress, t.pos, t.ent, t.forget = nil, nil, nil, true
    end
    -- the client counts the time down itself: if nothing else changed, don't send it
    -- again (but now and then anyway, in case one went astray)
    local left = t.left
    t.left = nil
    local key = util.TableToJSON(t)
    t.left = left
    local now = CurTime()
    if key == ply.lcQStateKey and now - (ply.lcQStateAt or 0) < 5 then return end
    ply.lcQStateKey, ply.lcQStateAt = key, now
    LC.SendCompressed("lcq_state", t, { ply })
end

function SendStateAll(q)
    for _, p in ipairs(Members(q)) do SendState(p) end
end
LC.SendQuestState = function(ply) SendState(ply) end

------------------------------------------------------------------------
-- Ticking quests
------------------------------------------------------------------------

local function PollEscort(q, st)
    local npc = st.npc
    local nst = IsValid(npc) and LC.NPCs[npc]
    if not nst then return Finish(q, false, "the person you were escorting is gone") end
    local leader, bd
    for _, p in ipairs(Members(q)) do
        if p:Alive() then
            local d = p:GetPos():DistToSqr(npc:GetPos())
            if not bd or d < bd then leader, bd = p, d end
        end
    end
    LC.SetState(npc, nst, "event")
    nst.eventUntil = CurTime() + 2
    if leader then
        -- follow like a person: aim for a spot just behind you on their side,
        -- only re-plan when you've actually moved on, and stop and wait when
        -- they're close. They run when you run, when they fall behind, and
        -- whenever there's shooting (yours, theirs, or at either of you).
        local now = CurTime()
        local npos, lpos = npc:GetPos(), leader:GetPos()
        local d = math.sqrt(bd)
        local moving = npc:IsCurrentSchedule(SCHED_FORCED_GO) or npc:IsCurrentSchedule(SCHED_FORCED_GO_RUN)
        local hp = npc:Health()
        if st.lastHp and hp < st.lastHp then st.hurtAt = now end
        st.lastHp = hp
        local danger = (st.hurtAt and now - st.hurtAt < 10) or (LC.InCombat and LC.InCombat(leader))
            or (LC.PlayerIsWanted and LC.PlayerIsWanted(leader) and LC.AlertLevel and LC.AlertLevel(leader) >= 2)
        local v = leader.GetVelocity and leader:GetVelocity() or Vector(0, 0, 0)
        local leaderRunning = v:Length2D() > (leader.GetWalkSpeed and leader:GetWalkSpeed() or 110) + 20
        -- a ladder between you (you went up or down it): to its foot, and up (or down) they go
        if math.abs(lpos.z - npos.z) > 64 and LC.LadderToward and now > (st.ladderAt or 0) then
            local climbing = leader.GetMoveType and leader:GetMoveType() == (MOVETYPE_LADDER or 9)
            local near, far = LC.LadderToward(npos, lpos, climbing)
            -- (only towards the end you're at: they used to hop up and down it over and over)
            if near and far and lpos:DistToSqr(far) > lpos:DistToSqr(near) then near = nil end
            if near then
                if climbing and Vector(npos.x - near.x, npos.y - near.y, 0):LengthSqr() < 90 * 90 and math.abs(npos.z - near.z) < 72 then
                    -- (they're still on it: wait at its end; up they go once they're off)
                    if moving then npc:SetSchedule(SCHED_IDLE_STAND) end
                    st.goal, st.running = nil, false
                    return
                end
                if Vector(npos.x - near.x, npos.y - near.y, 0):LengthSqr() < 90 * 90 and math.abs(npos.z - near.z) < 72 then
                    npc:SetPos(far + Vector(0, 0, 6))
                    st.ladderAt = now + 4 -- (and not straight back down it)
                    npc:SetSchedule(SCHED_IDLE_STAND)
                    npc:EmitSound("player/footsteps/ladder" .. math.random(1, 4) .. ".wav", 70)
                    st.goal, st.running = nil, false
                    return
                end
                if not moving or not st.goal or st.goal:DistToSqr(near) > 30 * 30 then
                    npc:SetLastPosition(near)
                    npc:SetSchedule(SCHED_FORCED_GO_RUN)
                    st.goal, st.running = near, true
                end
                return
            end
        end
        -- fallen far behind (a door, a jump they couldn't make), and nobody's looking: they catch up
        if d > 1200 and LC.FollowCatchUp and LC.FollowCatchUp(npc, leader) then
            st.goal, st.running = nil, false
            return
        end
        if d > 100 then
            local dir = npos - lpos
            dir.z = 0
            if dir:LengthSqr() < 1 then dir = Vector(1, 0, 0) end
            local goal = lpos + dir:GetNormalized() * 60
            local run = (danger or not st.walkOnly) and (danger or leaderRunning or d > 300 or (st.running and d > 160))
            if not moving or not st.goal or st.goal:DistToSqr(goal) > 90 * 90 or run ~= st.running then
                npc:SetLastPosition(goal)
                npc:SetSchedule(run and SCHED_FORCED_GO_RUN or SCHED_FORCED_GO)
                st.goal = goal
            end
            st.running = run
        elseif moving then
            npc:SetSchedule(SCHED_IDLE_STAND)
            st.goal, st.running = nil, false
            if LC.Face then LC.Face(npc, lpos) end
        end
    end
    if st.anyRebel and (st.nextHome or 0) < CurTime() then
        -- (home is any rebel territory: the marker points to the nearest)
        st.nextHome = CurTime() + 3
        local best, bd
        for _, z in ipairs(LC.ZonesOfKind("rebel")) do
            local d = z.pos:DistToSqr(npc:GetPos())
            if not bd or d < bd then best, bd = z, d end
        end
        if best then st.pos = best.pos end
    end
    if st.watch then st.watch(q, st) end
    if (st.anyRebel and LC.InRebelZone and LC.InRebelZone(npc:GetPos())) or npc:GetPos():DistToSqr(st.pos) < (st.r or 200) ^ 2 then
        if st.vanish then
            q.marked[npc] = nil
            npc:Remove()
        end
        Advance(q)
    end
end

-- How fast someone being tailed grows suspicious of p, per second (0: not at all).
-- Seeing you matters most: in front of them, in the open, and close. Right
-- behind them they hear you even without looking; bumping into them is worse.
local TAIL_COOL = 12 -- per second, out of sight
local function TailSuspicion(npc, p, st)
    local to = p:GetPos() - npc:GetPos()
    to.z = 0
    local d = to:Length()
    if d < 100 then return 30 end
    local sight = st.max or 1100
    if d > sight then return 0 end
    local tr = util.TraceLine({ start = npc:EyePos(), endpos = p:EyePos(), mask = MASK_OPAQUE, filter = npc })
    if tr.Fraction <= 0.97 then return 0 end
    local fwd = npc:GetForward()
    local facing = d < 1 or (fwd.x * to.x + fwd.y * to.y) / d > 0.5 -- inside a 120 degree view
    local rate
    if facing then
        local f = math.Clamp((sight - d) / (sight - (st.min or 200)), 0, 1)
        rate = 30 * f * f
    elseif d < (st.min or 200) then
        rate = 10 -- footsteps right behind them
    else
        return 0
    end
    if p:Crouching() then rate = rate * 0.5 end
    local v = p:GetVelocity()
    if v.x * v.x + v.y * v.y > 150 * 150 then rate = rate * 1.5 end
    return rate
end

local function Poll(q, now)
    if now > q.expires then
        -- out of time, but standing there doing it (a hold or a holdout already under way): the clock waits for
        -- them to finish (the owner, 1 November: 15 seconds into 45 at the spot, and the job was called off)
        local st = Stage(q)
        local still = st and (st.progress or 0) > 0 and ((st.kind == "hold" and AnyMemberNear(q, st.pos, st.r or 150, st.crouch))
            or (st.kind == "survive"))
        if not still then return Finish(q, false, "you ran out of time") end
        q.expires = now + 1
        if not q.overtimeTold and IsValid(q.owner) then
            q.overtimeTold = true
            q.owner:ChatPrint("[Job] Time's up, but you're at it: finish it and it still counts.")
        end
    end
    local mem = Members(q)
    if #mem == 0 then return Finish(q, false, "everyone left the job") end
    if not IsValid(q.owner) or not table.HasValue(mem, q.owner) then q.owner = mem[1] end
    if q.failOnArrest then
        for _, p in ipairs(mem) do
            if LC.Prisoners and LC.Prisoners[p] then return Finish(q, false, "you were arrested") end
        end
    end

    if q.tick then q.tick(q, now) end
    if q.done then return end
    local st = Stage(q)
    if not st then return end
    local k = st.kind
    if k == "tail" then
        -- follow someone: close enough to keep them in sight, far enough not to be noticed
        local npc = st.npc
        if not IsValid(npc) or not LC.NPCs[npc] then return Finish(q, false, "the person you were following is gone") end
        local best
        for _, p in ipairs(mem) do
            if p:Alive() then
                local d = p:GetPos():Distance(npc:GetPos())
                if not best or d < best then best = d end
            end
        end
        best = best or 1e9
        -- suspicion builds while they can see you (or hear you right behind
        -- them) and fades while you're out of sight; only a full meter blows it
        local gain = 0
        for _, p in ipairs(mem) do
            if p:Alive() then gain = math.max(gain, TailSuspicion(npc, p, st)) end
        end
        local before = st.suspicion or 0
        st.suspicion = math.Clamp(before + (gain > 0 and gain or -TAIL_COOL) * 0.5, 0, 100)
        st.seen = gain > 0
        if st.suspicion >= 50 and before < 50 then Narrate(q, "They keep glancing back: they're getting suspicious. Get out of their sight before they spot you.") end
        if st.suspicion >= 100 then
            st.suspicion = 0
            if st.onNoticed then return st.onNoticed(q, st) end
            return Finish(q, false, "they noticed you following them")
        end
        if best > st.lost then
            st.away = (st.away or 0) + 0.5
            if st.away >= 12 then return Finish(q, false, "you fell too far behind and lost them") end
        else
            st.away = 0
        end
        if best >= st.min and best <= st.max then
            st.progress = st.progress + 0.5
            if st.progress >= st.secs then Advance(q) end
        end
        return
    end
    if k == "goto" or k == "deliver" then
        if AnyMemberNear(q, st.pos, st.r or 120) then Advance(q) end
    elseif k == "hold" then
        if AnyMemberNear(q, st.pos, st.r or 150, st.crouch) then
            st.progress = st.progress + 0.5
            if st.progress >= st.secs then Advance(q) end
        end
    elseif k == "survive" then
        for _, p in ipairs(mem) do
            if p:Alive() and (not st.cond or st.cond(q, p)) then
                st.progress = st.progress + 0.5
                if st.progress >= st.secs then return Advance(q) end
                break
            end
        end
    elseif k == "target" then
        local npc = st.npc
        if not IsValid(npc) or not LC.NPCs[npc] then return Finish(q, false, st.lostText or "your target is gone") end
        if st.action == "reach" and AnyMemberNear(q, npc:GetPos(), st.r or 150) then
            Advance(q)
        elseif st.action == "arrest" then
            local s = LC.NPCs[npc].state
            if s == "jailed" and not st.armed then
                Narrate(q, "Another Civil Protection unit arrested them first. You get half the reward.")
                q.reward = math.floor(q.reward / 2)
                Advance(q)
            end
        end
    elseif k == "escort" then
        PollEscort(q, st)
    elseif k == "count" and st.poll then
        st.poll(q, st)
    end
end

-- A ration break: rations are out mid-shift, so the job waits (its clock stopped, nothing
-- failing for your being away) till you've had your ration, five minutes are up, or you
-- go back to it. F1 > Take a ration break (or !rationbreak; !back to carry on).
function LC.RationBreak(ply, on)
    if not IsValid(ply) then return false end
    if on then
        local q = LC.QuestOf[ply]
        if not q or q.done then return false, "You don't have a shift or job running, so there's nothing to take a break from." end
        if LC.Event ~= "rations" then return false, "Rations aren't being handed out right now, so you can't take a ration break." end
        ply.lcRationBreak = CurTime() + 300
        ply:SetNW2Bool("lc_ration_break", true)
        return true
    end
    if not ply.lcRationBreak then return false end
    ply.lcRationBreak = nil
    ply:SetNW2Bool("lc_ration_break", false)
    return true
end
local function OnBreak(q)
    local p = q.owner
    if not IsValid(p) or not p.lcRationBreak then return false end
    if CurTime() > p.lcRationBreak then
        LC.RationBreak(p, false)
        p:ChatPrint("[Work] Your ration break is over (five minutes at most). Your job's timer is running again.")
        return false
    end
    return true
end
hook.Add("LivingCityRationCollected", "LivingCityRationBreak", function(ply)
    if ply.lcRationBreak then
        LC.RationBreak(ply, false)
        ply:ChatPrint("[Work] You've got your ration, so your break is over. Your job carries on from where you left it.")
    end
end)
hook.Add("LivingCityEventStarted", "LivingCityRationBreak", function(name)
    if name ~= "rations" then return end
    for _, p in ipairs(player.GetAll()) do
        local q = LC.QuestOf[p]
        if q and not q.done and LC.Notice then
            LC.Notice(p, "info", "Rations are being handed out", "To get your ration without failing your job, press F1 and choose Take a ration break. It pauses your job's timer until you've collected your ration (five minutes at most).", 9)
        end
    end
end)
LC.SlashCommands = LC.SlashCommands or {}
LC.SlashCommands.rationbreak = function(ply)
    local ok, why = LC.RationBreak(ply, true)
    ply:ChatPrint(ok and "[Work] Ration break started. Your job's timer is paused until you collect your ration, for five minutes at most. Type /back to end the break early." or ("[Work] " .. (why or "You can't now.")))
end
LC.SlashCommands.back = function(ply)
    ply:ChatPrint(LC.RationBreak(ply, false) and "[Work] Break ended. Your job's timer is running again." or "[Work] You're not on a break.")
end

timer.Create("LivingCityQuests", 0.5, 0, function()
    local now = CurTime()
    local tick = math.floor(now * 2) % 2 == 0
    for q in pairs(LC.ActiveQuests) do
        local ok, err = true, nil
        if OnBreak(q) then q.expires = q.expires + 0.5 else ok, err = pcall(Poll, q, now) end
        if not ok then
            LC.Error("quest " .. tostring(q.tmpl and q.tmpl.id), err)
            Finish(q, false, "something went wrong")
        elseif not q.done then
            local st = Stage(q)
            if st and (st.kind == "tail" or tick and (st.kind == "hold" or st.kind == "survive" or st.kind == "collect"
                or st.kind == "escort" or st.kind == "target")) then
                SendStateAll(q)
            end
        end
    end
end)

------------------------------------------------------------------------
-- Things happening in the world
------------------------------------------------------------------------

function LC.QuestEvent(name, ply, a, b)
    local q = IsValid(ply) and LC.QuestOf[ply]
    if not q or q.done then return end
    local st = Stage(q)
    if not st then return end

    if st.kind == "count" and st.event == name then
        if st.filter and not st.filter(q, ply, a, b) then return end
        if st.distinct and a ~= nil then
            if st.seen[a] then return end
            st.seen[a] = true
        end
        st.got = st.got + 1
        if st.got >= st.need then Advance(q) else SendStateAll(q) end
    elseif st.kind == "target" and IsValid(st.npc) and a == st.npc then
        if st.action == "arrest" and name == "arrested" then
            Advance(q)
        elseif st.action == "free" and name == "used_npc" then
            local nst = LC.NPCs[st.npc]
            if nst and (nst.state == "jailed" or nst.state == "escorted" or nst.jailUntil) then
                LC.Release(st.npc, nst)
                nst.jailUntil = nil
                Freeze(st.npc, 5)
                Advance(q)
            end
        elseif st.action == "use" and name == "used_npc" then
            Advance(q)
        end
    elseif st.kind == "pickup" and name == "used_item" and a == st.item then
        if st.breakOpen then
            -- broken open where it stands: splinters, and what was in it goes in your pockets
            a.lcQuest = nil
            a:EmitSound("physics/wood/wood_crate_break" .. math.random(1, 5) .. ".wav", 75)
            a:Fire("Break")
            timer.Simple(0.3, function() if IsValid(a) then a:Remove() end end)
        else
            a:Remove()
        end
        q.data.carrying = true
        Advance(q)
    elseif st.kind == "collect" and name == "used_item" and st.items and st.items[a] then
        st.items[a] = nil
        a:Remove()
        st.got = st.got + 1
        if st.got >= st.need then Advance(q) else SendStateAll(q) end
    end
end

hook.Add("LivingCityPlayerUsedNPC", "LivingCityQuests", function(ply, npc, st) LC.QuestEvent("used_npc", ply, npc, st) end)
hook.Add("LivingCityIncarcerated", "LivingCityQuests", function(target, secs, reason, arrester)
    if IsValid(arrester) and arrester:IsPlayer() then LC.QuestEvent("arrested", arrester, target) end
end)
hook.Add("OnNPCKilled", "LivingCityQuests", function(npc, attacker)
    if IsValid(attacker) and attacker:IsPlayer() then LC.QuestEvent("killed", attacker, npc) end
end)
hook.Add("LivingCityHealed", "LivingCityQuests", function(healer, target, amount) LC.QuestEvent("healed", healer, target, amount) end)
hook.Add("LivingCityPreached", "LivingCityQuests", function(ply) LC.QuestEvent("preached", ply, nil) end)
hook.Add("LivingCityServed", "LivingCityQuests", function(npc)
    for q in pairs(LC.ActiveQuests) do
        local st = Stage(q)
        if st and st.kind == "count" and st.event == "served" and AnyMemberNear(q, st.pos, st.r or 300) then
            LC.QuestEvent("served", q.owner, npc)
        end
    end
end)
hook.Add("PlayerUse", "LivingCityQuestItems", function(ply, ent)
    if not ent.lcQuest then return end
    if LC.QuestOf[ply] == ent.lcQuest then LC.QuestEvent("used_item", ply, ent) end
    return false
end)

hook.Add("PlayerDisconnected", "LivingCityQuests", function(ply)
    local q = LC.QuestOf[ply]
    if not q then return end
    LC.QuestOf[ply] = nil
    for i, p in ipairs(q.members) do if p == ply then table.remove(q.members, i) break end end
    local left = 0
    for _, p in ipairs(q.members) do if IsValid(p) and p ~= ply then left = left + 1 end end
    if left == 0 then Finish(q, false) elseif q.owner == ply then q.owner = nil end
end)

------------------------------------------------------------------------
-- Building blocks for templates
------------------------------------------------------------------------

local function Goto(pos, text, r) return { kind = "goto", pos = pos, r = r or 120, text = text } end
local function Deliver(pos, text, r) return { kind = "deliver", pos = pos, r = r or 150, text = text } end
local function Hold(pos, secs, text, r, crouch) return { kind = "hold", pos = pos, secs = secs, r = r or 150, crouch = crouch, text = text } end
local function Count(event, need, text, filter, distinct)
    return { kind = "count", event = event, need = need, text = text, filter = filter, distinct = distinct ~= false }
end
local function Choice(prompt, options) return { kind = "choice", prompt = prompt, options = options, text = "Choose what to do" } end

-- Hands-on games (sv_livingcity_jobgames.lua, sv_livingcity_moregames.lua):
-- arriving starts one (GameGo), or the stage starts it (GameNow); the stage
-- after is the game itself, done when it's done.
local function GamesOn() return LC.JobGamesOn ~= nil and LC.JobGamesOn() end
local function GameStage(text) return Count("game_done", 1, text) end
local function GameGo(pos, text, kind, opts, r)
    local go = Goto(pos, text, r or 150)
    go.onDone = function(q) if IsValid(q.owner) and LC.JobGameStart then LC.JobGameStart(q.owner, kind, q, opts) end end
    return go
end
local function GameNow(kind, text, opts)
    local st = GameStage(text)
    st.onEnter = function(q) if IsValid(q.owner) and LC.JobGameStart then LC.JobGameStart(q.owner, kind, q, opts) end end
    return st
end

local function IsCitizenNPC(_, _, npc) local st = LC.NPCs[npc] return st ~= nil and st.role == "citizen" end
local function IsCopNPC(_, _, npc) local st = LC.NPCs[npc] return st ~= nil and st.role == "cop" end

local function T(def)
    def.factions = def.factions or {}
    LC.QuestTemplates[#LC.QuestTemplates + 1] = def
end

-- Pick a random NPC citizen when a stage begins, give them a made-up identity.
local function FindCitizenStage(text, r, onFound)
    return {
        kind = "target", action = "reach", r = r or 150, text = text,
        onEnter = function(q, st)
            local npc = q.data.target
            if not IsValid(npc) then npc = RandomCitizen() end
            if not npc then return false end
            Lock(q, npc)
            q.data.target = npc
            st.npc = npc
        end,
        onDone = function(q, st) if onFound then onFound(q, st) end end,
    }
end

local function ArrestStage(text)
    return {
        kind = "target", action = "arrest", text = text or "Detain them with the Arrest Baton (right click)",
        onEnter = function(q, st) st.npc = q.data.target; if not IsValid(st.npc) then return false end end,
    }
end

-- Running away: somewhere down the street on the same level, not the far
-- side of the city (and never popped there by the stuck-walker fix; see
-- Recover in sv_livingcity.lua, which leaves quest targets where they are).
local function Flee(q)
    local npc = q.data.target
    local st = IsValid(npc) and LC.NPCs[npc]
    if not st then return end
    st.eventUntil = 0
    local from = npc:GetPos()
    local dest
    for _ = 1, 12 do
        local p = LC.RandomWanderPos("citizen", from)
        if p and p:Distance(from) > 500 and p:Distance(from) < 1500 then dest = p break end
    end
    dest = dest or LC.RandomWanderPos("citizen", from) or LC.RandomWanderPos("citizen")
    LC.GoTo(npc, st, dest, true, nil)
end

-- Someone in the crowd in front of you: a citizen you can actually see (or
-- at least on your level, close by, and reachable), not one behind three walls.
local function SuspectNear(ply, center)
    local eye = ply:EyePos()
    local seen, near = {}, {}
    for npc, st in pairs(LC.NPCs or {}) do
        if IsValid(npc) and st.role == "citizen" and not st.test and not st.questLock and not st.leaving
            and FREE_STATES[st.state] then
            local pos = npc:GetPos()
            if math.abs(pos.z - ply:GetPos().z) < 120 and pos:DistToSqr(ply:GetPos()) < 1000 * 1000 then
                local tr = util.TraceLine({ start = eye, endpos = pos + Vector(0, 0, 50), mask = MASK_OPAQUE, filter = ply })
                if tr.Fraction > 0.97 or tr.Entity == npc then
                    seen[#seen + 1] = npc
                elseif pos:DistToSqr(center) < 600 * 600 and (not LC.NavReachable or LC.NavReachable(ply:GetPos(), pos)) then
                    near[#near + 1] = npc
                end
            end
        end
    end
    if #seen > 0 then return Pick(seen) end
    if #near > 0 then return Pick(near) end
    return nil
end

------------------------------------------------------------------------
-- Civil Protection: Directives
------------------------------------------------------------------------

T{
    id = "cp_patrol", factions = { cp = true, ota = true },
    build = function(ply)
        local stops = {}
        local beats = {}
        for _, p in ipairs(LC.PointsOfKind("patrol")) do if (p.group or 0) > 0 then beats[p.group] = true end end
        local groups = table.GetKeys(beats)
        if #groups > 0 then
            for _, p in ipairs(LC.PointsOfKind("patrol", Pick(groups))) do
                if #stops < 4 then stops[#stops + 1] = p.pos end
            end
        end
        if #stops == 0 then stops = Route(ply, math.random(3, 4), 400, 1100) end
        if #stops < 2 then return nil end
        local stages = {}
        for i, s in ipairs(stops) do stages[i] = Goto(s, string.format("Walk to patrol stop %d of %d, %s", i, #stops, Place(s, ply:GetPos())), 150) end
        return {
            title = "Patrol sweep " .. Place(stops[1], ply:GetPos()), reward = 15 + 5 * #stops, limit = 240 + 60 * #stops,
            desc = "Walk to each marked patrol stop in turn, so citizens see Civil Protection on the streets.", stages = stages,
            intro = Pick({ "Dispatch wants boots on the street. Yours will do.", "Overwatch reports elevated noncompliance. Show them the uniform." }),
        }
    end,
}

T{
    id = "cp_inspect", factions = { cp = true }, during = { "sweep" }, squad = 8,
    available = function() return LC.Running and CountRole("citizen") >= 3 end,
    build = function()
        local need = math.random(3, 5)
        return {
            title = "Civil status inspections", reward = 10 + 5 * need, limit = 360,
            desc = string.format("Stop %d citizens and %s. Nobody is above suspicion.", need, GamesOn() and "pat them down" or "check their papers"),
            stages = { GamesOn() and GameNow("patdown", string.format("Pat down %d citizens: walk up to one and press E, search them, then release them, confiscate what they carry, or detain them", need), { need = need })
                or Count("used_npc", need, "Inspect citizens: walk up to one and press E", IsCitizenNPC) },
        }
    end,
}

T{
    id = "cp_apprehend", factions = { cp = true }, violent = true, squad = 4,
    available = function() return LC.Running and CountRole("citizen") >= 1 and LC.PrisonAvailable() end,
    build = function(ply)
        local id, crime = CitizenID(), Pick(CRIMES)
        local stash = Pick(CONTRABAND)
        return {
            title = "Apprehend citizen " .. id, reward = 35, limit = 420,
            desc = string.format("Citizen %s is wanted for %s. An informant has given you their location: they're marked on your screen.", id, crime),
            stages = {
                FindCitizenStage("Find citizen " .. id .. " (marked on your screen)", 140, function(q) Freeze(q.data.target, 40) end),
                Choice(string.format("Citizen %s freezes. Their eyes go to your baton, then to the street behind you.", id), {
                    { text = "Detain them." },
                    { text = "Make them name their supplier.", check = { "authority", 12 },
                      success = function(q, p)
                          local spot = HideSpots(Spot(p, 300, 1500) or p:GetPos(), 1, 300)[1]
                          Narrate(q, "They crack and tell you: there's " .. stash[1] .. " hidden " .. Place(spot, p:GetPos()) .. ".")
                          LC.AddTrait(p, "loyalty", 1)
                          q.bonus = (q.bonus or 0) + 15
                          InsertStages(q, { { kind = "collect", spots = { spot }, model = stash[2], need = 1,
                              text = "Find " .. stash[1] .. " (marked) and press E on it to seize it" } })
                      end,
                      fail = function(q)
                          Narrate(q, "They shove past you and run! Catch them.")
                          Flee(q)
                      end },
                    { text = "Take their ration units as a bribe and let them go (ends the job, less XP).",
                      pick = function(q, p)
                          LC.AddTrait(p, "corruption", 1)
                          LC.Bump(p, "bribes")
                          q.reward = 10
                          Narrate(q, "The ration units are still warm from their pocket. Nobody will ever know. You will.")
                          return "complete"
                      end },
                    { text = "Let them go (ends the job, no XP).",
                      pick = function(q, p)
                          LC.AddTrait(p, "sympathy", 1)
                          LC.Bump(p, "mercies")
                          q.reward = 0
                          Narrate(q, "You look away. They're gone before you look back.")
                          return "complete"
                      end },
                }),
                ArrestStage(),
            },
        }
    end,
}

T{
    id = "cp_checkpoint", factions = { cp = true, ota = true },
    available = function() return #LC.PointsOfKind("checkpoint") > 0 end,
    build = function(ply)
        local p = Pick(LC.PointsOfKind("checkpoint"))
        local secs = math.random(9, 14) * 10
        return {
            title = "Checkpoint duty " .. Place(p.pos, ply:GetPos()), reward = 25, limit = secs + 240,
            desc = "Go to the checkpoint and stand guard there until the timer is full. Nobody passes without being looked at.",
            stages = { Goto(p.pos, "Go to the marked checkpoint", 250), Hold(p.pos, secs, "Stay at the checkpoint until the timer is full", 260) },
        }
    end,
}

T{
    id = "cp_contraband", factions = { cp = true },
    build = function(ply)
        local center = Spot(ply, 500, 2500)
        if not center then return nil end
        local kind = Pick(CONTRABAND)
        local sweep = { kind = "collect", spots = HideSpots(center, 3, 700), model = kind[2], need = 3,
            text = "Confiscate " .. kind[1] .. ": find each one (marked) and press E on it" }
        -- (the owner, 7 November: three boxes, and then it just ends; "can we track down who did this?")
        -- the last stash has something on it that points to whoever hid it: ask around, find them, bring them in
        sweep.onDone = function(q) if LC.ContrabandTrail then LC.ContrabandTrail(q, center, kind) end end
        return {
            title = "Contraband sweep " .. Place(center, ply:GetPos()), reward = 30, limit = 900,
            desc = "An informant reports " .. kind[1] .. " hidden around this area, in three places. Find and confiscate all three, then track down whoever hid them.",
            stages = { sweep },
        }
    end,
}

T{
    id = "cp_disturbance", factions = { cp = true }, violent = true, squad = 4,
    available = function() return LC.Running and LC.PrisonAvailable() end,
    build = function(ply)
        local center = Spot(ply, 800, 3000)
        if not center then return nil end
        return {
            title = "Disturbance " .. Place(center, ply:GetPos()), reward = 40, limit = 240,
            desc = "There's a disturbance nearby. Get there fast, then catch and arrest the suspect who runs.",
            stages = {
                Goto(center, "Hurry to the marked disturbance", 300),
                {
                    kind = "target", action = "arrest", text = "Chase the suspect and arrest them with the Arrest Baton (right click)",
                    onEnter = function(q, st)
                        local p = q.owner
                        local npc = IsValid(p) and SuspectNear(p, center)
                        if not npc then
                            -- nobody about: they come out of a doorway near you
                            local spot = IsValid(p) and LC.RandomWanderPos("citizen", p:GetPos()) or center
                            if spot and IsValid(p) and spot:Distance(p:GetPos()) > 900 then spot = center end
                            npc = LC.Spawners.citizen((spot or center) + Vector(0, 0, 4))
                        end
                        if not IsValid(npc) then return false end
                        Lock(q, npc)
                        q.data.target = npc
                        st.npc = npc
                        Flee(q)
                    end,
                    narrate = "Someone breaks from the crowd and runs! That's your suspect.",
                },
            },
        }
    end,
}

T{
    id = "cp_rationduty", factions = { cp = true }, during = { "rations" }, squad = 6,
    available = function() return LC.Running and next(LC.Lines) ~= nil end,
    build = function(ply)
        local g = Pick(table.GetKeys(LC.Lines))
        local front = LC.Lines[g].slots[1].pos
        return {
            title = "Ration line supervision", reward = 30, limit = 600,
            desc = "Keep order at ration line " .. g .. " while rations are handed out.",
            stages = {
                Goto(front, "Go to ration line " .. g .. " (marked)", 220),
                -- the line forms first (the owner, 7 November: "the line is restless" with nobody there)
                { kind = "count", event = "served", need = 1, pos = front, r = 320, distinct = false,
                  text = "Stand at the front of the line while it forms and the first citizen collects" },
                Choice("The line is restless. A woman at the front is shaking, and the man behind her keeps looking at your hands.", {
                    { text = "Keep order, by the book.", pick = function(q, p) LC.AddTrait(p, "loyalty", 1) end },
                    { text = "Calm the line with a few quiet words.", check = { "empathy", 11 },
                      success = function(q, p)
                          LC.AddTrait(p, "sympathy", 1)
                          q.bonus = (q.bonus or 0) + 10
                          Narrate(q, "The shaking stops. Somebody actually says thank you.")
                      end,
                      fail = function(q) Narrate(q, "Someone spits near your boots. The line goes quiet anyway.") end },
                    { text = "Pocket a few ration units while nobody's counting.",
                      pick = function(q, p) LC.AddTrait(p, "corruption", 1) LC.Bump(p, "bribes") end },
                }),
                { kind = "count", event = "served", need = 2, pos = front, r = 320, distinct = false,
                  text = "Stay near the front of the line while 2 more citizens collect their rations" },
            },
        }
    end,
}

T{
    id = "cp_infest", factions = { cp = true, ota = true }, violent = true, squad = 6,
    -- only while it's spreading (or has just broken out): posted the moment it grows
    available = function()
        for _, z in ipairs(LC.ZonesOfKind("infest")) do if z.grown then return true end end
        return LC.LastOutbreak ~= nil and CurTime() - LC.LastOutbreak < 600
    end,
    build = function(ply, focus)
        -- the front line: where it has spread to (the patch that just grew, if it's
        -- still there); else where it started
        local zones = LC.ZonesOfKind("infest")
        if #zones == 0 then return nil end
        local grown = {}
        for _, q in ipairs(zones) do if q.grown then grown[#grown + 1] = q end end
        local z = #grown > 0 and Pick(grown) or Pick(zones)
        if focus then for _, q in ipairs(zones) do if q == focus then z = focus end end end
        local need = 5
        local surge = 4
        local area = math.max(700, z.r * 1.6)
        local enter = Goto(z.pos, "Go to the infested area (marked)", math.max(200, z.r))
        -- they know you're coming: a few more crawl out for this, and don't
        -- come back once they're down
        enter.onEnter = function(q)
            -- from the moment the team goes in, nothing new crawls out here behind their
            -- backs: what's there is what they have to clear
            if LC.QuietInfestation then q.data.hold = LC.QuietInfestation(z.pos, area * 1.3, 3600) end
            if not LC.SpawnZombie then return end
            q.data.surge = {}
            for _ = 1, surge do
                local spot
                for _ = 1, 6 do
                    local p = LC.SpotInZone(z)
                    if p and not LC.IsSeen(p + Vector(0, 0, 50)) then spot = p break end
                end
                spot = spot or LC.SpotInZone(z)
                if spot then
                    local npc, st = LC.SpawnZombie(spot + Vector(0, 0, 4), z)
                    if st then
                        st.unmanaged = true -- extra, not part of the usual count: nothing replaces them
                        q.data.surge[#q.data.surge + 1] = npc
                    end
                end
            end
        end
        -- done when every infested thing in the area is down, not after a set number
        local function Left()
            local n = 0
            for npc, st in pairs(LC.NPCs) do
                if st.role == "zombie" and IsValid(npc) and npc:Health() > 0 and npc:GetPos():DistToSqr(z.pos) < area * area then n = n + 1 end
            end
            return n
        end
        local kill = Count("killed", 9999, "Kill every infested creature in this area", function(_, _, npc) return IsZombieNPC(npc) end)
        kill.poll = function(q, st)
            local left = Left()
            local text = left > 0 and string.format("Kill every infested creature in this area (%d left)", left) or "Area clear: every infested creature here is dead"
            if st.text ~= text then st.text = text SendStateAll(q) end
            if left == 0 and (st.got or 0) >= 1 then Advance(q) end
        end
        kill.onDone = function(q)
            -- a patch of it, gone, and quiet for a while
            if LC.QuietInfestation then LC.QuietInfestation(z.pos, area * 1.3) end
            if z.grown and LC.RecedeTerritory and LC.RecedeTerritory(z, "contained", q.owner) then
                Narrate(q, "The infestation is pushed back: this part of the infested zone is cleared, and nothing will crawl back for a while.")
            else
                Narrate(q, "Area clear. No infested creatures will appear here for a while.")
            end
        end
        return {
            title = "Containment " .. Place(z.pos, ply:GetPos()), reward = 45, limit = 1200,
            desc = z.grown and "The infestation has spread into new ground. Go there and kill every infested creature to push it back." or "The infestation is active at its source. Go there and kill every infested creature before it spreads.",
            stages = { enter, kill },
            onFinish = function(q)
                -- the hold on spawning lifts (a cleared area gets its own ten quiet minutes)
                if q.data.hold then q.data.hold.untilT = 0 end
                -- leftover extras wander off once nobody's looking
                for _, npc in ipairs(q.data.surge or {}) do
                    local st = IsValid(npc) and LC.NPCs[npc]
                    if st then st.surgeExpires = CurTime() + 120 end
                end
            end,
        }
    end,
}

local function IsRebelNPC(npc) local st = LC.NPCs[npc] return st ~= nil and st.role == "rebel" end

T{
    id = "cp_retake", factions = { cp = true, ota = true }, violent = true, squad = 6,
    available = function()
        for _, z in ipairs(LC.ZonesOfKind("rebel")) do if z.grown then return true end end
        return false
    end,
    build = function(ply, focus)
        local grown = {}
        for _, z in ipairs(LC.ZonesOfKind("rebel")) do if z.grown then grown[#grown + 1] = z end end
        if #grown == 0 then return nil end
        -- the ground that was just taken, or the nearest piece of it
        table.sort(grown, function(a, b) return a.pos:DistToSqr(ply:GetPos()) < b.pos:DistToSqr(ply:GetPos()) end)
        local z = grown[1]
        for _, g in ipairs(grown) do if g == focus then z = focus end end
        local where = Place(z.pos, ply:GetPos())
        -- (the owner, 7 November: 25 rebels dead and the job only counted 3, and more kept appearing
        -- behind him) the job is to clear the ground: every rebel on it, and nobody new turns up there
        -- while the team is at it; then, holding it, a wave of fighters comes to take it back
        local area = math.max(350, z.r + 150)
        local move = Goto(z.pos, "Go to the rebel-held ground " .. where .. " (marked)", math.max(200, z.r * 0.8))
        move.onEnter = function(q)
            if LC.QuietRebels then
                q.data.quiet = { LC.QuietRebels(z.pos, area + 900, 3600) }
                -- (and the camp it grew from, next door: fighters appearing there walked straight over)
                if z.seed and z.seed.pos then q.data.quiet[2] = LC.QuietRebels(z.seed.pos, (z.seed.r or 300) + 200, 3600) end
            end
            if LC.ReinforceRebels then LC.ReinforceRebels(z, 3) end
        end
        local clear = Count("killed", 9999, "Eliminate every rebel on the ground", function(_, _, npc) return IsRebelNPC(npc) end)
        clear.untallied = true -- (the count is of who's left, in the objective)
        clear.pos = z.pos
        clear.poll = function(q, st)
            local left = LC.RebelsOnGround and LC.RebelsOnGround(z.pos, area) or {}
            local near, nd
            for _, npc in ipairs(left) do
                local d = IsValid(q.owner) and npc:GetPos():DistToSqr(q.owner:GetPos()) or 0
                if not nd or d < nd then near, nd = npc, d end
            end
            st.npc = near -- (the marker: the nearest one still standing)
            local text = #left > 0 and string.format("Eliminate every rebel on the ground (%d left)", #left) or "The ground is clear: every rebel on it is down"
            if st.text ~= text then st.text = text SendStateAll(q) end
            if #left == 0 then Advance(q) end
        end
        local hold = Hold(z.pos, 30, "Hold the ground for 30 seconds. Expect a counterattack", math.max(260, z.r * 0.9))
        hold.onEnter = function(q) q.data.waveAt = CurTime() + math.Rand(4, 8) end
        hold.onDone = function(q)
            if LC.RecedeTerritory then LC.RecedeTerritory(z, "retaken", q.owner) end
            Narrate(q, "The ground is retaken: it's no longer rebel territory. Whatever they built here comes down by morning.")
        end
        return {
            title = "Retake the block " .. where, reward = 55, limit = 720,
            desc = "Anticitizens have taken over ground " .. where .. ". Go there and eliminate every rebel holding it (no more will come in while you clear it), then hold the ground for 30 seconds. Expect a counterattack.",
            stages = { move, clear, hold },
            tick = function(q, now)
                -- the counterattack: fighters from outside come to take it back while you hold it
                if q.data.waveAt and now >= q.data.waveAt and Stage(q) == hold then
                    q.data.waveAt = nil
                    local n = LC.RebelWave and LC.RebelWave(z.pos, Members(q), math.min(6, 2 + #Members(q))) or 0
                    if n > 0 then Narrate(q, "Rebel fighters are coming to take the ground back! Hold it.") end
                end
            end,
            onFinish = function(q)
                for _, h in ipairs(q.data.quiet or {}) do h.untilT = CurTime() + 120 end -- (two quiet minutes after, then life goes on)
            end,
        }
    end,
}

T{
    id = "res_takeground", factions = { resistance = true }, violent = true, squad = 6,
    available = function()
        for _, seed in ipairs(LC.TerritorySeeds and LC.TerritorySeeds("rebel") or {}) do
            if LC.TerritoryCanGrow(seed) then return true end
        end
        return false
    end,
    build = function(ply)
        local seeds = {}
        for _, seed in ipairs(LC.TerritorySeeds("rebel")) do if LC.TerritoryCanGrow(seed) then seeds[#seeds + 1] = seed end end
        if #seeds == 0 then return nil end
        table.sort(seeds, function(a, b) return a.pos:DistToSqr(ply:GetPos()) < b.pos:DistToSqr(ply:GetPos()) end)
        local seed = seeds[1]
        local spot, r = LC.TerritoryGrowthSpot(seed)
        if not spot then return nil end
        local where = Place(spot, ply:GetPos())
        local hold = Hold(spot, 60, "Stay on the spot for 60 seconds. Civil Protection units will come to stop you.", 260)
        hold.onEnter = function(q)
            -- dispatch hears about it, and sends whoever is nearest to look
            if LC.RadioNotice then LC.RadioNotice("cp", "Dispatch: anticitizens gathering " .. where .. ". Nearby Civil Protection units, investigate.") end
            local near = {}
            for npc, st in pairs(LC.NPCs) do
                if IsValid(npc) and st.role == "cop" and not st.questLock and st.state ~= "hostile" and not st.workEscort then
                    near[#near + 1] = { npc = npc, st = st, d = npc:GetPos():DistToSqr(spot) }
                end
            end
            table.sort(near, function(a, b) return a.d < b.d end)
            for i = 1, math.min(2, #near) do
                if near[i].d < 4000 * 4000 then
                    if LC.ArmUnit then LC.ArmUnit(near[i].npc, near[i].st) end
                    LC.GoTo(near[i].npc, near[i].st, spot, true, nil)
                end
            end
        end
        hold.onDone = function(q)
            local z = LC.GrowTerritory(seed, spot, r, "taken")
            if z and LC.ReinforceRebels then LC.ReinforceRebels(z, 2) end
            Narrate(q, z and "The ground is ours: it's rebel territory now. People are already moving in behind you." or "You held it, but it can't be kept: the ground doesn't become rebel territory.")
        end
        return {
            title = "Take ground " .. where, reward = 50, limit = 540,
            desc = "We want the ground " .. where .. ". Get there and stay on it for a minute, and it becomes rebel territory. Civil Protection units will be sent to stop you.",
            stages = { Goto(spot, "Go to the marked ground " .. where, 200), hold },
        }
    end,
}

T{
    id = "res_supplyrun", factions = { resistance = true }, squad = 4,
    available = function()
        for _, r in pairs(LC.RebelProps or {}) do if IsValid(r.cache) then return true end end
        return false
    end,
    build = function(ply)
        local cache
        for _, r in pairs(LC.RebelProps or {}) do if IsValid(r.cache) then cache = r.cache break end end
        if not cache then return nil end
        -- the Union's own stores: by the ration dispenser, a checkpoint, the ration line
        local sources = {}
        for _, kind in ipairs({ "dispenser", "checkpoint", "queue" }) do
            for _, p in ipairs(LC.PointsOfKind(kind)) do sources[#sources + 1] = p.pos end
        end
        local src = #sources > 0 and Pick(sources) or Spot(ply, 800, 3000)
        if not src then return nil end
        local spot = HideSpots(src, 1, 400, true)[1] or src
        local where = Place(spot, ply:GetPos())
        local take = { kind = "pickup", pos = spot, model = "models/items/item_item_crate.mdl",
            text = "Steal the crate of Union supplies " .. where .. ": press E on it" }
        take.onDone = function(q)
            local p = q.owner
            if IsValid(p) and LC.SeenBySecurity and LC.SeenBySecurity(p, 900) then
                LC.ReportCrime(p, "Theft of Union supplies", 120)
                Narrate(q, "A Civil Protection unit saw you take it. You're wanted now: run.")
            else
                Narrate(q, "Nobody saw you take it. Walk, don't run.")
            end
            -- word gets out: units can follow the smuggler on their screens (sv_livingcity_resistanceops.lua)
            if LC.TrackSmuggler then LC.TrackSmuggler(q) end
        end
        local bring = Deliver(cache:GetPos(), "Take it to the Resistance supply crate in rebel territory (marked)", 180)
        bring.onDone = function(q)
            local added = LC.AddToCache and LC.AddToCache(cache, 6) or 0
            Narrate(q, string.format("You add six meals to the Resistance supply crate. It now holds %d.", IsValid(cache) and (cache.lcStock or 0) or added))
            -- and ammunition, packed under the food
            for _, m in ipairs(Members(q)) do
                if IsValid(m) and LC.GiveOrDrop then LC.GiveOrDrop(m, math.random() < 0.5 and "ammo_pistol" or "ammo_smg", 1) end
            end
            Narrate(q, "There was ammunition packed under the food. Everyone on the job gets a box.")
        end
        return {
            title = "Supply run " .. where, reward = 35, limit = 600, failOnArrest = true,
            desc = "The Resistance's food stores are low. The Union keeps supplies " .. where .. ". Steal a crate and bring it to the Resistance supply crate in rebel territory.",
            stages = { take, bring },
        }
    end,
}

local function Quartermaster()
    for npc, st in pairs(LC.NPCs or {}) do
        if IsValid(npc) and st.quartermaster and npc:Health() > 0 then return npc end
    end
    return nil
end

-- Smuggling for the black market: guns out to the Resistance, or parts in.
T{
    id = "cit_gunrun", factions = { citizen = true, resistance = true },
    build = function(ply)
        local qm = Quartermaster()
        local home, homeName
        if LC.PlayerBlock and LC.PlayerBlock(ply) then
            for _, z in ipairs(LC.ZonesOfKind("block")) do
                if z.group == LC.PlayerBlock(ply) then home, homeName = z.pos, LC.BlockName(z.group) break end
            end
        end
        local partsRun = not qm or (home and math.random() < 0.45)
        if partsRun and not home then return nil end
        local contact = Spot(ply, 1200, 4000)
        if not contact then return nil end
        local where = Place(contact, ply:GetPos())
        local take = { kind = "pickup", pos = HideSpots(contact, 1, 300, true)[1] or contact, model = "models/items/item_item_crate.mdl",
            breakOpen = true, text = "Find the crate a contact left " .. where .. " and press E to break it open" }
        take.onDone = function(q)
            local p = q.owner
            if not IsValid(p) then return end
            if LC.GiveItem(p, "smuggled_supplies", 1) then
                Narrate(q, "You break the crate open and put the supplies in your pockets. A search will find them, so don't get stopped.")
            else
                LC.SpawnWorldItem("smuggled_supplies", p:GetPos() + p:GetForward() * 30 + Vector(0, 0, 10))
                Narrate(q, "The crate breaks open, but your pockets are full. Make room in your pockets (F2), then pick the supplies up off the ground.")
            end
        end
        local destPos = partsRun and home or qm:GetPos()
        local bring = Deliver(destPos, partsRun and ("Take the supplies home to " .. homeName) or "Take the supplies to the Resistance quartermaster (marked)", 200)
        bring.onDone = function(q)
            local p = q.owner
            -- (the supplies; or a whole crate, from before crates were broken open)
            local carried = IsValid(p) and ((LC.HasItem(p, "smuggled_supplies") and "smuggled_supplies") or (LC.HasItem(p, "arms_crate") and "arms_crate"))
            if not carried then
                q.reward = 0
                Narrate(q, "You arrived without the supplies, so there's no reward. Somebody's going to want to know where they went.")
                return
            end
            LC.TakeItem(p, carried)
            if partsRun then
                LC.GiveItem(p, "gun_parts", 3)
                LC.GiveItem(p, "chemicals", 1)
                Narrate(q, "Inside: 3 gun parts and some chemicals, now in your pockets. Craft them into something worth selling.")
            else
                if LC.AddCredits then LC.AddCredits(p, 60, "gun run") end
                if LC.AddTrait then LC.AddTrait(p, "sympathy", 1) end
                Narrate(q, "The quartermaster counts the guns, then counts out sixty credits. 'Same again, soon.'")
            end
        end
        return {
            title = partsRun and ("Parts pickup " .. where) or ("Gun run " .. where), reward = 30, limit = 720, failOnArrest = true,
            desc = partsRun and ("A smuggler has left gun parts for you " .. where .. ". Pick them up and take them home without getting searched.")
                or ("A crate of guns is waiting " .. where .. ". Get it to the Resistance quartermaster and you're paid sixty credits."),
            stages = { take, bring },
        }
    end,
}

T{
    id = "cp_transfer", factions = { cp = true },
    available = function() return LC.Running and CountRole("citizen") >= 1 and LC.PrisonAvailable() end,
    build = function(ply)
        local id = CitizenID()
        -- a unit is holding them somewhere sensible: a checkpoint if there's one
        -- within reach, else out on the street nearby
        local where
        local cps = {}
        for _, p in ipairs(LC.PointsOfKind("checkpoint")) do
            if p.pos:Distance(ply:GetPos()) < 3500 then cps[#cps + 1] = p.pos end
        end
        where = #cps > 0 and Pick(cps) or Spot(ply, 400, 2000)
        if not where then return nil end
        local place = Place(where, ply:GetPos())
        local pickup = {
            kind = "target", action = "reach", r = 140,
            text = "Take over detainee " .. id .. " from the Civil Protection unit holding them " .. place .. ": walk up to them (marked)",
            onEnter = function(q, st)
                -- the detainee stands still, hands up; the unit beside them waits for you
                local npc = LC.QB.SpawnActor(q, "citizen", where, 900)
                if not npc then return false end
                q.data.target = npc
                st.npc = npc
                local nst = LC.NPCs[npc]
                if nst then nst.questDetainee = true end
                if LC.PlayGesture and LC.FRISKED_ANIMS then LC.PlayGesture(npc, LC.FRISKED_ANIMS, 6) end
                local guard, gst = LC.QB.SpawnActor(q, "cop", npc:GetPos() + Vector(50, 30, 0), 900, true)
                if guard then
                    gst.unmanaged = nil -- one of the city's own units once this is over
                    q.data.guard = guard
                    LC.Face(guard, npc:GetPos())
                end
            end,
            onDone = function(q)
                local guard = q.data.guard
                local gst = IsValid(guard) and LC.NPCs[guard]
                if gst then
                    -- the handover; then he's back on his beat
                    guard:EmitSound("npc/metropolice/vo/affirmative.wav", 75)
                    gst.eventUntil = CurTime() + 2
                    gst.questLock, gst.unmanaged = nil, nil
                    Narrate(q, "The Civil Protection unit nods at the detainee. 'All yours.' He heads back to his beat.")
                end
                if IsValid(q.data.target) then Freeze(q.data.target, 600) end
            end,
        }
        return {
            title = "Detainee transfer: " .. id, reward = 25, limit = 420,
            desc = "A Civil Protection unit is holding citizen " .. id .. " " .. place .. " and has been called away. Take over the detainee, choose how to handle them, then arrest them with the Arrest Baton (right click) to send them to the cells.",
            stages = {
                pickup,
                Choice("The detainee was flagged by an informant. They swear they've done nothing, and their voice is steady.", {
                    { text = "Process them." },
                    { text = "Hear them out.", check = { "empathy", 14 },
                      success = function(q, p)
                          LC.AddTrait(p, "sympathy", 1)
                          q.bonus = (q.bonus or 0) + 10
                          Narrate(q, "Their story holds. The informant owed them money. You note it in the file. It won't matter.")
                      end,
                      fail = function(q) Narrate(q, "Halfway through, they contradict themselves. You stop listening.") end },
                    { text = "Lean on them for names.", check = { "authority", 10 },
                      success = function(q, p)
                          LC.AddTrait(p, "loyalty", 1)
                          q.bonus = (q.bonus or 0) + 10
                          Narrate(q, "Two names. You'll see them on a directive soon.")
                      end,
                      fail = function(q) Narrate(q, "They go silent. Smarter than they look.") end },
                }),
                ArrestStage("Detain them with the Arrest Baton (right click) to send them to the cells"),
            },
        }
    end,
}

------------------------------------------------------------------------
-- Overwatch: Protocols    Administrator: Agenda
------------------------------------------------------------------------

T{
    id = "ota_raid", factions = { ota = true }, violent = true, squad = 6,
    available = function() return #LC.ZonesOfKind("rebel") > 0 end,
    build = function(ply)
        local z = Pick(LC.ZonesOfKind("rebel"))
        return {
            title = "Incursion " .. Place(z.pos, ply:GetPos()), reward = 50, limit = 420,
            desc = "Go into rebel territory and stay alive inside it for sixty seconds. Expect rebels to fight back.",
            stages = {
                (function()
                    local g = Goto(z.pos, "Go into the marked rebel territory", math.max(150, z.r * 0.8))
                    g.onEnter = function() if LC.ReinforceRebels then LC.ReinforceRebels(z, 3) end end
                    return g
                end)(),
                { kind = "survive", secs = 60, text = "Stay alive inside rebel territory for 60 seconds",
                  cond = function(_, p) return LC.InRebelZone(p:GetPos()) end },
            },
        }
    end,
}

T{
    id = "admin_address", factions = { admin = true },
    build = function(ply)
        local spots = LC.PointsOfKind("idle")
        local pos = #spots > 0 and Pick(spots).pos or Spot(ply, 300, 2000)
        if not pos then return nil end
        return {
            title = "Address the citizens", reward = 20, limit = 360,
            desc = "The people need to hear their Administrator. Go to the plaza, speak to the crowd, then choose how to end your speech.",
            stages = {
                Goto(pos, "Go to the plaza (marked)", 150),
                Hold(pos, 40, "Stay there for 40 seconds while you give your speech", 220),
                Choice("The crowd watches you in silence. How do you end it?", {
                    { text = "Announce additional rations (starts a ration handout).", pick = function(q, p)
                        LC.AddTrait(p, "sympathy", 1)
                        if LC.Running then LC.StartEvent("rations") end
                        return "complete" end },
                    { text = "Remind them of their duty to the city (starts an inspection sweep).", pick = function(q, p)
                        LC.AddTrait(p, "loyalty", 1)
                        if LC.Running then LC.StartEvent("sweep") end
                        return "complete" end },
                    { text = "Declare a curfew, effective immediately (starts a curfew).", pick = function(q, p)
                        LC.AddTrait(p, "loyalty", 2)
                        if LC.Running then LC.StartEvent("curfew") end
                        return "complete" end },
                }),
            },
        }
    end,
}

T{
    id = "admin_review", factions = { admin = true },
    available = function() return LC.Running and CountRole("cop") >= 1 end,
    build = function()
        local need = math.min(3, math.max(1, CountRole("cop")))
        return {
            title = "Review the Civil Protection units", reward = 15, limit = 360,
            desc = "Check on Civil Protection in person: find units on the street and talk to them.",
            stages = { Count("used_npc", need, "Talk to Civil Protection units: walk up to one and press E", IsCopNPC) },
        }
    end,
}

------------------------------------------------------------------------
-- Resistance: Operations
------------------------------------------------------------------------

T{
    id = "res_supply", factions = { resistance = true },
    build = function(ply)
        local a = Spot(ply, 600, 2500)
        if not a then return nil end
        local dest, r, where = SafeHouse(ply)
        return {
            title = "Supply run", reward = 35, limit = 480, failOnArrest = true,
            desc = "A contact has a crate of medical supplies for you " .. Place(a, ply:GetPos()) .. ". Bring it to the Resistance's safe spot: " .. where .. ".",
            stages = {
                LC.QB.Contact("Find your contact (marked) and press E on them to take the crate", a, "citizen", "'Don't thank me. Don't look back, either.'", { rebel = true }),
                Choice("The crate is heavier than it should be. There's a Civil Protection unit posted at the end of the street.", {
                    { text = "Walk it out in plain sight." },
                    { text = "Bury it under a coat and some laundry.", check = { "guile", 11 },
                      success = function(q) Narrate(q, "Nobody looks twice at a tired citizen with laundry.") end,
                      fail = function(q, p)
                          Narrate(q, "A Civil Protection unit shouts after you. You're wanted now: run!")
                          LC.ReportCrime(p, "Carrying contraband", 120)
                      end },
                }),
                LC.QB.Contact("Find the quartermaster at the safe spot (" .. where .. ") and press E on him to hand over the crate", dest, "citizen", "He's already prying the lid up. 'Good. We needed this yesterday.'", { rebel = true }),
            },
        }
    end,
}

T{
    id = "res_propaganda", factions = { resistance = true },
    build = function(ply)
        local spots = { Spot(ply, 400, 2500), Spot(ply, 400, 2500), Spot(ply, 400, 2500) }
        if not spots[3] then return nil end
        local stages = {}
        for i, s in ipairs(spots) do
            stages[i] = Hold(s, 3, string.format("Post flyer %d of 3 %s: crouch at the marked spot for 3 seconds", i, Place(s, ply:GetPos())), 90, true)
            stages[i].onDone = function(q)
                local flyer = SpawnItem(q, "models/props_c17/paper01.mdl", s, true, true)
                if IsValid(flyer) then SafeRemoveEntityDelayed(flyer, 600) end
                local p = q.owner
                if IsValid(p) and LC.SeenBySecurity(p, 700) then
                    Narrate(q, "A Civil Protection unit saw you put that up. You're wanted now.")
                    LC.ReportCrime(p, "Distributing propaganda", 150)
                end
            end
        end
        return {
            title = "Paper the walls", reward = 30, limit = 480, failOnArrest = true,
            desc = "Put up three Resistance flyers in three marked places. If a Civil Protection unit sees you putting one up, you become wanted.",
            stages = stages,
        }
    end,
}

T{
    id = "res_sabotage", factions = { resistance = true }, violent = true,
    available = function() return #LC.PointsOfKind("checkpoint") > 0 end,
    build = function(ply)
        local cp = Pick(LC.PointsOfKind("checkpoint"))
        local dest, r, where = SafeHouse(ply)
        local plant = Hold(cp.pos, 5, "Go to the marked checkpoint and crouch there for 5 seconds to plant the charge", 100, true)
        plant.onDone = function(q)
            Boom(cp.pos + Vector(0, 0, 20))
            cp.disabledUntil = CurTime() + 300
            local p = q.owner
            if IsValid(p) then
                LC.ReportCrime(p, "Sabotage", 240)
                if LC.Running then LC.MakeCopsHostile(p, cp.pos, 1500) end
            end
            Narrate(q, "The checkpoint goes up in a shower of sparks. You're wanted now, and every Civil Protection unit in the sector heard that.")
        end
        return {
            title = "Sabotage " .. Place(cp.pos, ply:GetPos()), reward = 45, limit = 480, failOnArrest = true,
            desc = "Blow up the checkpoint to put it out of action for five minutes, then escape to safety.",
            stages = { plant, Deliver(dest, "Escape: get to the safe spot (" .. where .. ")", r) },
        }
    end,
}

T{
    id = "res_jailbreak", factions = { resistance = true },
    available = function()
        if #LC.PointsOfKind("cell") == 0 then return false end
        for npc, st in pairs(LC.NPCs or {}) do if IsValid(npc) and st.state == "jailed" then return true end end
        return LC.Running and CountRole("citizen") >= 1
    end,
    build = function(ply)
        local id = CitizenID()
        local dest, r, where = SafeHouse(ply)
        return {
            title = "Jailbreak: " .. id, reward = 50, limit = 600, failOnArrest = true,
            desc = "Citizen " .. id .. " was arrested last night, and they know too much to stay in a cell. Break them out of prison and lead them to safety.",
            stages = {
                {
                    kind = "target", action = "free", text = "Go to their cell in the prison (marked) and press E on them to break them out",
                    onEnter = function(q, st)
                        local npc
                        for n, s in pairs(LC.NPCs) do if IsValid(n) and s.state == "jailed" and not s.questLock then npc = n break end end
                        if not npc then
                            npc = RandomCitizen()
                            if not npc or not LC.ArrestNPC(npc, nil) then return false end
                        end
                        Lock(q, npc)
                        q.data.target = npc
                        st.npc = npc
                    end,
                    onDone = function(q)
                        if IsValid(q.owner) then LC.ReportCrime(q.owner, "Aiding an escape", 240) end
                        Narrate(q, "The lock gives. You're wanted for this now, and the alarms won't stay quiet for long. Move.")
                    end,
                },
                { kind = "escort", pos = dest, r = r, vanish = true, text = "Lead them to the safe spot (" .. where .. "): they follow you",
                  onEnter = function(q, st) st.npc = q.data.target; if not IsValid(st.npc) then return false end end },
            },
        }
    end,
}

T{
    id = "res_recruit", factions = { resistance = true },
    available = function() return LC.Running and CountRole("citizen") >= 3 end,
    build = function()
        local last = 0
        return {
            title = "Sound out the neighbors", reward = 25, limit = 480,
            desc = "Find three citizens who might be ready to join the Resistance, and talk to them where no Civil Protection unit can see you.",
            stages = { Count("used_npc", 3, "Talk to 3 citizens (walk up and press E) where no Civil Protection unit can see you", function(q, p, npc)
                if not IsCitizenNPC(q, p, npc) then return false end
                if LC.SeenBySecurity(p, 700) then
                    if CurTime() > last then p:ChatPrint("[Operations] A Civil Protection unit can see you, so that didn't count. Move somewhere out of sight."); last = CurTime() + 5 end
                    return false
                end
                return true
            end) },
        }
    end,
}

T{
    id = "res_deaddrop", factions = { resistance = true },
    build = function(ply)
        local a, b = Spot(ply, 500, 2500), Spot(ply, 500, 2500)
        if not a or not b then return nil end
        return {
            title = "Dead drop", reward = 25, limit = 420,
            desc = "Meet a contact at the meeting point, then hide a message at the drop for the Resistance to find.",
            stages = {
                Goto(a, "Go to the marked meeting point " .. Place(a, ply:GetPos()), 120),
                Hold(a, 20, "Wait at the meeting point for 20 seconds for your contact", 160),
                Choice("Your contact doesn't come. Instead, a child walks past and presses a folded note into your hand.", {
                    { text = "Read it.", pick = function(q) Narrate(q, Pick(NOTES)) end },
                    { text = "Burn it unread.", pick = function(q) Narrate(q, "Some things are safer not known.") end },
                }),
                GamesOn() and GameGo(b, "Take the message to the marked drop " .. Place(b, ply:GetPos()), "drop", { pos = b }, 140)
                    or Goto(b, "Go to the marked drop " .. Place(b, ply:GetPos()) .. " to leave the message", 120),
                GamesOn() and GameStage("Hide the message: press E on one of the three marked hiding places, then crouch and keep still. If anyone sees you doing it, that hiding place is ruined.") or nil,
            },
        }
    end,
}

-- The Smuggler's trade (a Resistance role, F4): the cell's cargo from the quartermaster, out
-- to three drops in the city past the units, knowing exactly what's in it.
T{
    id = "res_smuggle", factions = { resistance = true },
    available = function(ply) return IsValid(ply) and ply:GetNW2String("lcf_special", "") == "smuggler" and GamesOn() end,
    build = function(ply)
        local qm = Quartermaster()
        local from = IsValid(qm) and qm:GetPos() or Spot(ply, 300, 1500)
        if not from then return nil end
        local stops = {}
        for _ = 1, 3 do
            local sp = Spot(ply, 800, 3500)
            if not sp then return nil end
            stops[#stops + 1] = { pos = sp, name = "the drop " .. Place(sp, from) }
        end
        return {
            title = "Smuggling run", reward = 20, limit = 900,
            desc = "Take the Resistance cell's cargo (guns and ammunition) to three drops around the city. If a Civil Protection unit searches you, they'll find it.",
            stages = {
                GameGo(from, IsValid(qm) and "Go to the quartermaster (marked) to collect the cargo" or "Go to the marked spot to collect the cargo", "parcel", { stops = stops, smuggle = true }, 140),
                GameStage("Deliver the cargo to the three marked drops before time runs out. Crouch to sneak past Civil Protection units, or stand still for their search and hope for the best"),
            },
        }
    end,
}

T{
    id = "res_terminal", factions = { resistance = true },
    available = function() return GamesOn() end,
    build = function(ply)
        local terms = {}
        for _, c in ipairs({ "lc_terminal", "lc_console" }) do
            for _, e in ipairs(LC.EntsOf and LC.EntsOf(c) or {}) do terms[#terms + 1] = e end
        end
        local pos, what
        if #terms > 0 then
            local e = Pick(terms)
            pos = e:GetPos()
            what = e:GetClass() == "lc_terminal" and "the civil records terminal" or "the Combine console"
        else
            pos, what = Spot(ply, 500, 2500), "a records terminal"
        end
        if not pos then return nil end
        local function Wipe(p)
            -- one of ours with a record (or whoever did it, if nobody else has one)
            local who
            for _, o in ipairs(player.GetAll()) do
                if o ~= p and o:GetNW2String("lcf_faction", "") == "resistance" and LC.PlayerIsWanted(o) then who = o break end
            end
            if not who and IsValid(p) and LC.PlayerIsWanted(p) then who = p end
            if who then
                LC.ClearWanted(who)
                who:ChatPrint("[Operations] A Resistance member wiped your record from the Combine's terminals: you're no longer wanted.")
                if IsValid(p) and p ~= who then p:ChatPrint("[Operations] You wiped " .. who:Nick() .. "'s record: they're no longer wanted.") end
            elseif IsValid(p) then
                p:ChatPrint("[Operations] Nobody of ours was wanted, so you wiped three names from the registers instead. The scanner never noticed.")
            end
        end
        return {
            title = "Doctor the records", reward = 30, limit = 480, failOnArrest = true,
            desc = "Some of ours are wanted by the Combine. Hack into " .. what .. " " .. Place(pos, ply:GetPos()) .. " and wipe a wanted Resistance member's record.",
            stages = {
                GameGo(pos, "Go to " .. what .. " " .. Place(pos, ply:GetPos()) .. " (marked)", "hack", { pos = pos, what = what, onDone = Wipe }, 140),
                GameStage("Hack the terminal: stop the moving needle inside the band (click or space) four times. When the scanner passes over, stop touching the panel"),
            },
        }
    end,
}

T{
    id = "res_ambush", factions = { resistance = true }, violent = true,
    available = function(ply) return LC.Running and SecurityCount() >= 2 and (LC.PlayerIsHunted(ply) or RankIndex(ply) >= 3) end,
    build = function()
        return {
            title = "Ambush a patrol", reward = 40, limit = 480,
            desc = "For fighters only. Kill two Civil Protection units, then get away.",
            stages = { Count("killed", 2, "Kill 2 Civil Protection units", function(_, _, npc)
                local st = LC.NPCs[npc]
                return st ~= nil and LC.IsSecurity(st)
            end) },
        }
    end,
}

T{
    id = "res_rescue", factions = { resistance = true },
    available = function() return #LC.ZonesOfKind("rebel") > 0 end,
    build = function(ply)
        local where = Spot(ply, 600, 2500)
        if not where then return nil end
        local dest, r, safe = SafeHouse(ply)
        return {
            title = "Extraction", reward = 40, limit = 600,
            desc = "Someone on a Civil Protection wanted list is hiding " .. Place(where, ply:GetPos()) .. ". Find them and lead them to safety.",
            stages = {
                {
                    kind = "target", action = "reach", r = 140, text = "Find the fugitive (marked on your screen)",
                    onEnter = function(q, st)
                        local npc = LC.Spawners.citizen(where + Vector(0, 0, 4))
                        if not IsValid(npc) then return false end
                        Lock(q, npc)
                        Freeze(npc, 600)
                        q.data.target = npc
                        st.npc = npc
                    end,
                },
                { kind = "escort", pos = dest, r = r, vanish = true, text = "Lead them to the safe spot (" .. safe .. "): they follow you",
                  onEnter = function(q, st) st.npc = q.data.target; if not IsValid(st.npc) then return false end end },
            },
        }
    end,
}

T{
    id = "res_ministry", factions = { resistance = true },
    available = function(ply) return Special(ply) == "chaplain" end,
    build = function()
        return {
            title = "The ministry", reward = 30, limit = 600,
            desc = "Tend to your flock: comfort a grieving woman, heal three wounded people with The Blessing, and preach once. The Combine call it unlawful worship. You call it Sunday.",
            stages = {
                Choice("A woman catches your sleeve. Her husband was taken last night. She asks you to pray with her, here, in the open.", {
                    { text = "Pray with her where she stands (if a Civil Protection unit sees, you become wanted).", pick = function(q, p)
                        LC.AddTrait(p, "sympathy", 1)
                        q.bonus = (q.bonus or 0) + 10
                        if LC.SeenBySecurity(p, 800) then
                            Narrate(q, "You finish the prayer. Then you hear the boots: a Civil Protection unit saw you, and you're wanted now.")
                            LC.ReportCrime(p, "Unlawful worship", 180)
                        else
                            Narrate(q, "She holds your hand through all of it. Nobody comes.")
                        end
                    end },
                    { text = "Promise to pray for him tonight, somewhere safe.", check = { "empathy", 10 },
                      success = function(q, p) LC.AddTrait(p, "sympathy", 1) Narrate(q, "She nods. It's enough. For now it's enough.") end,
                      fail = function(q) Narrate(q, "She lets go of your sleeve and doesn't look back.") end },
                }),
                Count("healed", 3, "Heal 3 different wounded people with The Blessing (left click)", nil, true),
                Count("preached", 1, "Preach the Word: hold The Blessing and press reload where people can hear", nil, false),
            },
        }
    end,
}

------------------------------------------------------------------------
-- Citizens: Assignments
------------------------------------------------------------------------

T{
    id = "cit_rations", factions = { citizen = true },
    available = function() return next(LC.Lines) ~= nil end,
    build = function()
        local g = Pick(table.GetKeys(LC.Lines))
        local front = LC.Lines[g].slots[1].pos
        return {
            title = "Collect your ration", reward = LC.Event == "rations" and 20 or 10, limit = 300,
            desc = "Your ration is ready. Go to ration line " .. g .. " and wait at the front to collect it.",
            stages = { Goto(front, "Go to ration line " .. g .. " (marked)", 200), Hold(front, 10, "Stand at the front of the line for 10 seconds", 110) },
        }
    end,
}

T{
    id = "cit_cleanup", factions = { citizen = true },
    build = function(ply)
        local center = Spot(ply, 300, 2000)
        if not center then return nil end
        return {
            title = "Union work order: sanitation", reward = 20, limit = 420,
            desc = "Pick up four pieces of litter " .. Place(center, ply:GetPos()) .. ". A clean city is a compliant city.",
            stages = { { kind = "collect", spots = HideSpots(center, 4, 600, true), models = TRASH, need = 4,
                text = "Pick up the litter: press E on each marked piece" } },
        }
    end,
}

T{
    id = "cit_errand", factions = { citizen = true },
    build = function(ply)
        -- Mrs. Kleiner lives in a housing block: the parcel is picked up inside one
        -- (yours if you have one), only falling back to the streets on maps without blocks
        local a
        local blocks = LC.ZonesOfKind and LC.ZonesOfKind("block") or {}
        if #blocks > 0 then
            local mine = LC.PlayerBlock and LC.PlayerBlock(ply)
            local own = {}
            for _, z in ipairs(blocks) do if mine and z.group == mine then own[#own + 1] = z end end
            local pool = #own > 0 and own or blocks
            for _ = 1, 6 do
                a = LC.SpotInZone(pool[math.random(#pool)])
                if a then break end
            end
        end
        local inBlock = a ~= nil
        a = a or Spot(ply, 400, 2000)
        local b = Spot(ply, 600, 3000)
        if not a or not b then return nil end
        local deliver = LC.QB.Contact("Find her cousin " .. Place(b, ply:GetPos()) .. " (marked) and press E on them to hand over the parcel", b, "citizen",
            "'From Kleiner? Tell her I'm fine.' It's not true, and you both know it.")
        return {
            title = "A neighbor's errand", reward = 20, limit = 420,
            desc = inBlock and "Mrs. Kleiner from the third floor needs a parcel carried across the district. Collect it from her inside the housing block, then deliver it to her cousin."
                or "Mrs. Kleiner from the third floor needs a parcel carried across the district. Collect it from her, then deliver it to her cousin.",
            stages = {
                LC.QB.Contact(inBlock and "Find Mrs. Kleiner inside the housing block (marked) and press E on her" or "Find Mrs. Kleiner (marked) and press E on her", a, "citizen",
                    "'It's only a little parcel. It's gone to the third floor and back already.' She presses it into your hands."),
                Choice("The parcel is taped shut. It's light, and something inside slides when you tilt it.", {
                    { text = "Deliver it unopened." },
                    { text = "Peel back the tape and look.", check = { "guile", 12 },
                      success = function(q)
                          InsertStages(q, { Choice("Resistance pamphlets. Your hands are suddenly cold.", {
                              { text = "Deliver it anyway.", pick = function(q2, p) LC.AddTrait(p, "sympathy", 1) LC.Bump(p, "pamphlets") end },
                              { text = "Hand it to Civil Protection instead.", pick = function(q2, p)
                                  LC.AddTrait(p, "loyalty", 2)
                                  LC.Bump(p, "reports")
                                  q2.stages[q2.stage + 1] = Count("used_npc", 1, "Hand the parcel to a Civil Protection unit: walk up to one and press E", IsCopNPC)
                              end },
                          }) })
                      end,
                      fail = function(q) Narrate(q, "The tape tears loudly. Better just deliver it, and fast.") end },
                }),
                deliver,
            },
        }
    end,
}

-- Handing something over and taking it, on citizen models (first one the model has wins).
local HANDOFF_GIVE = { "Heal", "takepackage", "g_palm_out_high_l", "g_point", "ACT_ARM" }
local HANDOFF_TAKE = { "takepackage", "Heal", "g_palm_out_l", "ACT_DISARM" }
local HANDOFF_LOOK = { "LookOutIdle", "photo_react_startle", "Fear_Reaction" }

T{
    id = "cit_report", factions = { citizen = true },
    build = function(ply)
        -- behind a dumpster: a real one in the map if there's one in reach (a
        -- dumpster first, any bin after that); otherwise one is put down on
        -- the street. Two people are actually there, and you walk up and see them.
        local bin = FindBins(ply, 300, 2500, 1, true)[1] or FindBins(ply, 300, 2500, 1)[1]
            or FindBins(ply, 150, 5000, 1, true)[1] or FindBins(ply, 150, 5000, 1)[1]
        local s = bin and bin.pos or Spot(ply, 400, 2500)
        if not s then return nil end
        if not bin then
            local tr = util.TraceLine({ start = s + Vector(0, 0, 40), endpos = s - Vector(0, 0, 300), mask = MASK_SOLID_BRUSHONLY })
            if tr.Hit then s = tr.HitPos end -- on the ground, not floating
        end
        local noun = (not bin or string.find(bin.model or "", "dumpster", 1, true)) and "the dumpster" or "the bins"
        local prompt = "Two people swap a bundle behind " .. noun .. ". One has a lambda scratched into his sleeve."
        local look = Goto(s, "Walk over to " .. noun .. " (marked), casually", 170)
        local from = ply:GetPos()
        look.onEnter = function(q)
            if not bin then
                local d = q.data.dumpster
                if not IsValid(d) then
                    d = SpawnItem(q, "models/props_junk/trashdumpster01a.mdl", s)
                    q.data.dumpster = d
                end
                if IsValid(d) then
                    d:SetPos(s + Vector(0, 0, d.OBBMins and -d:OBBMins().z or 30)) -- standing on the ground
                    local ang = (s - from):Angle()
                    d:SetAngles(Angle(0, ang.y + 90, 0)) -- side on to you, so there's a behind
                end
            end
            -- the two of them behind it (from where you're coming), facing each other
            local away = s - from
            away.z = 0
            away = away:LengthSqr() > 1 and away:GetNormalized() or Vector(1, 0, 0)
            local side = Vector(-away.y, away.x, 0)
            q.data.watched = {}
            for _, sign in ipairs({ 1, -1 }) do
                local npc = LC.QB.SpawnActor(q, "citizen", s + away * 75 + side * (35 * sign), 900)
                if npc then q.data.watched[#q.data.watched + 1] = npc end
            end
            local a, b = q.data.watched[1], q.data.watched[2]
            if IsValid(a) and IsValid(b) then
                LC.Face(a, b:GetPos()) LC.Face(b, a:GetPos())
                -- the hand-off, over and over: one holds something out, the other takes it,
                -- then they glance around. Whichever animations the models have.
                local name, turn = "LivingCityHandoff" .. tostring(q.id), 0
                local function swap()
                    if q.done or not IsValid(a) or not IsValid(b) then return timer.Remove(name) end
                    turn = turn + 1
                    local giver, taker = a, b
                    if turn % 2 == 0 then giver, taker = b, a end
                    LC.Face(giver, taker:GetPos()) LC.Face(taker, giver:GetPos())
                    if turn % 3 == 0 then
                        LC.PlayGesture(giver, HANDOFF_LOOK, 4)
                        LC.PlayGesture(taker, HANDOFF_LOOK, 4)
                    else
                        LC.PlayGesture(giver, HANDOFF_GIVE, 4)
                        timer.Simple(0.6, function() if IsValid(taker) then LC.PlayGesture(taker, HANDOFF_TAKE, 4) end end)
                    end
                end
                timer.Create(name, 4.5, 0, swap)
                timer.Simple(0.5, swap)
            end
        end
        return {
            title = "Something you saw", reward = 20, limit = 420,
            desc = "Neighbors whisper about something going on behind " .. (noun == "the bins" and "some bins " or "a dumpster ") .. Place(s, ply:GetPos()) .. ". Go and see what it is.",
            stages = {
                look,
                Hold(s, 6, "Stay nearby and watch quietly for 6 seconds", 220),
                Choice(prompt, {
                    { text = "Report it to a Civil Protection unit.", pick = function(q, p)
                        LC.AddTrait(p, "loyalty", 1)
                        LC.Bump(p, "reports")
                        InsertStages(q, { Count("used_npc", 1, "Tell a Civil Protection unit: walk up to one and press E", IsCopNPC) })
                    end },
                    { text = "Keep it to yourself (ends the job, little XP).", pick = function(q, p)
                        LC.AddTrait(p, "sympathy", 1)
                        LC.Bump(p, "silences")
                        q.reward = 5
                        Narrate(q, "You saw nothing. You'll keep seeing nothing.")
                        return "complete"
                    end },
                }),
            },
        }
    end,
}

T{
    id = "cit_lost", factions = { citizen = true },
    available = function() return #LC.ZonesOfKind("block") > 0 or #LC.PointsOfKind("spawn") > 0 end,
    build = function(ply)
        local where = Spot(ply, 400, 2000)
        if not where then return nil end
        local blocks = LC.ZonesOfKind("block")
        local home, homeName
        if #blocks > 0 then
            local z = Pick(blocks)
            home, homeName = z.pos, LC.BlockName(z.group)
        else
            home = Pick(LC.PointsOfKind("spawn")).pos
            homeName = "his doorway"
        end
        return {
            title = "The confused old man", reward = 25, limit = 600,
            desc = "An old man is wandering " .. Place(where, ply:GetPos()) .. ", asking everyone for directions. Find him and walk him home.",
            stages = {
                {
                    kind = "target", action = "reach", r = 140, text = "Find the old man (marked on your screen)",
                    onEnter = function(q, st)
                        local npc = LC.Spawners.citizen(where + Vector(0, 0, 4))
                        if not IsValid(npc) then return false end
                        npc:SetModel(Pick(LC.ELDERLY_MODELS)) -- Half-Life 2's older faces
                        if LC.NPCs[npc] then LC.NPCs[npc].gender = "male" end
                        Lock(q, npc)
                        Freeze(npc, 600)
                        q.data.target = npc
                        st.npc = npc
                    end,
                },
                Choice("He doesn't remember his block number. He keeps asking for his daughter.", {
                    { text = "Calm him down first.", check = { "empathy", 10 },
                      success = function(q) q.bonus = (q.bonus or 0) + 5 Narrate(q, "He takes your arm. His hand is light as paper.") end,
                      fail = function(q) Narrate(q, "He shuffles after you anyway, still asking.") end },
                    { text = "Just lead the way." },
                }),
                { kind = "escort", pos = home, r = 200, vanish = true, walkOnly = true, text = "Walk him home to " .. homeName .. ". He follows you, slowly.",
                  onEnter = function(q, st) st.npc = q.data.target; if not IsValid(st.npc) then return false end end },
            },
        }
    end,
}

T{
    id = "cit_loyalty", factions = { citizen = true },
    available = function() return LC.Running and #LC.PointsOfKind("checkpoint") > 0 and CountRole("cop") > 0 end,
    build = function(ply)
        local cp = Pick(LC.PointsOfKind("checkpoint"))
        return {
            title = "Loyalty check", reward = 15, limit = 360,
            desc = "You've been summoned for a routine loyalty check. Go to the checkpoint and present yourself to a Civil Protection officer.",
            stages = {
                Goto(cp.pos, "Go to the marked checkpoint", 260),
                Count("used_npc", 1, "Present yourself to a Civil Protection officer: walk up to one and press E", IsCopNPC),
                Choice("The officer's mask tilts. Where were you last night, citizen?", {
                    { text = "Tell the truth.", pick = function(q, p) LC.AddTrait(p, "loyalty", 1) end },
                    { text = "Give a smooth, boring alibi.", check = { "guile", 12 },
                      success = function(q) q.bonus = (q.bonus or 0) + 5 Narrate(q, "He waves you through. Boring is safe.") end,
                      fail = function(q, p)
                          Narrate(q, "He doesn't buy it. You're wanted now for failing a loyalty check.")
                          LC.ReportCrime(p, "Failing a loyalty check", 90)
                      end },
                }),
            },
        }
    end,
}

------------------------------------------------------------------------
-- The Infested: Urges
------------------------------------------------------------------------

T{
    id = "z_hunt", factions = { zombie = true }, violent = true,
    available = function() return LC.Running and CountRole("citizen") >= 2 end,
    build = function()
        return {
            title = "Hunger", reward = 30, limit = 480,
            desc = "Feed.",
            stages = { Count("killed", 2, "Kill 2 citizens", function(_, _, npc)
                local st = LC.NPCs[npc]
                return st ~= nil and st.role == "citizen"
            end) },
        }
    end,
}

T{
    id = "z_terrorize", factions = { zombie = true },
    available = function() return LC.Running and CountRole("citizen") >= 4 end,
    build = function()
        local st = Count("near_citizen", 4, "Get close to 4 different citizens (they'll run from you)", nil, true)
        st.poll = function(q, s)
            for _, p in ipairs(Members(q)) do
                if p:Alive() then
                    for npc, ns in pairs(LC.NPCs) do
                        if IsValid(npc) and ns.role == "citizen" and npc:GetPos():DistToSqr(p:GetPos()) < 150 * 150 then
                            LC.QuestEvent("near_citizen", p, npc)
                            if q.done or Stage(q) ~= s then return end
                        end
                    end
                end
            end
        end
        return { title = "Terror", reward = 20, limit = 420, desc = "Scare the living: get close to four different citizens.", stages = { st } }
    end,
}

T{
    id = "z_roam", factions = { zombie = true },
    available = function() return #LC.ZonesOfKind("infest") > 0 end,
    build = function()
        return {
            title = "Wander", reward = 25, limit = 400,
            desc = "Leave the infested zones and survive outside them for two minutes.",
            stages = { { kind = "survive", secs = 120, text = "Stay alive outside the infested zones for 2 minutes",
                cond = function(_, p) return LC.InfestZoneAt(p:GetPos()) == nil end } },
        }
    end,
}

------------------------------------------------------------------------
-- Stories: chains of parts, unlocked by what you've done
------------------------------------------------------------------------

LC.Chains = {}
LC.ChainList = {}

function LC.Chain(def)
    def.factions = def.factions or {}
    LC.Chains[def.id] = def
    LC.ChainList[#LC.ChainList + 1] = def
end

local function ChainFits(chain, ply)
    if chain.special then return Special(ply) == chain.special end
    return chain.factions[LC.QuestFaction(ply)] == true
end

function LC.ChainState(ply, id)
    local s = LC.Story(ply)
    s.chains[id] = s.chains[id] or { data = {} }
    s.chains[id].data = s.chains[id].data or {}
    return s.chains[id]
end

local function NextPart(ply, chain)
    local s = LC.Story(ply)
    if chain.gate then
        local ok, open = pcall(chain.gate, ply, s)
        if not ok or not open then return nil end
    end
    local cs = s.chains[chain.id]
    if cs and cs.done then return nil end
    if cs and (cs.readyAt or 0) > os.time() then return nil end
    if cs and cs.part then return cs.part end
    local ok, yes = pcall(chain.unlock, ply, s)
    if ok and yes then return chain.start end
    return nil
end

-- A story of your own waits until you've done a few ordinary jobs (the owner, 7 November: "at least
-- 2 to 4 standard jobs before one even appears"). The number is drawn once per character and kept in
-- the story memory; the count is the quests completed since then (lcq_done). A chain already under
-- way is never held back.
function LC.StoryGate(ply)
    local st = LC.Story(ply)
    local g = st.flags.story_gate
    if not istable(g) then
        g = { need = math.random(2, 4), base = tonumber(ply:GetPData("lcq_done", 0)) or 0 }
        st.flags.story_gate = g
        LC.SaveStory(ply)
    end
    return g
end

-- Not stories but somebody's work, never held back: the flat chains (a Union shift, rehabilitation,
-- an insider's ops), a stalker's lot and a shackled vortigaunt's collar.
local WORK_CHAINS = { stalker = true, collar = true }

-- Open?, and how many more jobs it takes.
function LC.StoryGateOpen(ply)
    if not IsValid(ply) or not ply:IsPlayer() then return false, 0 end
    local g = LC.StoryGate(ply)
    local done = (tonumber(ply:GetPData("lcq_done", 0)) or 0) - (g.base or 0)
    return done >= (g.need or 0), math.max(0, (g.need or 0) - done)
end

hook.Add("LivingCityNewCharacter", "LivingCityStoryGate", function(ply)
    if not IsValid(ply) or not ply:IsPlayer() then return end
    LC.Story(ply).flags.story_gate = nil
    LC.StoryGate(ply)
    ply.lcStoryPostings = nil
end)

function LC.StoryPostings(ply)
    ply.lcStoryPostings = ply.lcStoryPostings or {}
    local out = {}
    local open = LC.StoryGateOpen(ply)
    for _, chain in ipairs(LC.ChainList) do
        local cs = LC.Story(ply).chains[chain.id]
        local underWay = cs and (cs.part or cs.done) and true or false
        if ChainFits(chain, ply) and (open or underWay or chain.flat or WORK_CHAINS[chain.id]) then
            local part = NextPart(ply, chain)
            local cached = ply.lcStoryPostings[chain.id]
            if cached and cached.q and not cached.dead then
                out[#out + 1] = cached
            elseif not part then
                ply.lcStoryPostings[chain.id] = nil
            elseif cached and cached.part == part and not cached.dead then
                out[#out + 1] = cached
            else
                local def = chain.parts[part]
                local cs = LC.ChainState(ply, chain.id)
                local ok, spec = pcall(def.build, ply, cs.data)
                if not ok then
                    LC.Error("story " .. chain.id .. "/" .. part, spec)
                elseif spec then
                    spec.id = nextId
                    nextId = nextId + 1
                    spec.tmpl = { id = chain.id .. "/" .. part }
                    spec.story, spec.chain, spec.part, spec.chainName = true, chain.id, part, chain.name
                    spec.partNum = def.num or 1
                    if chain.flat then
                        spec.title = string.format("%s: %s", chain.name, spec.title)
                    else
                        spec.title = string.format("%s, part %d: %s", chain.name, spec.partNum, spec.title)
                    end
                    spec.faction = LC.QuestFaction(ply)
                    spec.data = spec.data or {}
                    spec.expiresPost = CurTime() + 1e9
                    spec.owner = ply
                    ply.lcStoryPostings[chain.id] = spec
                    out[#out + 1] = spec
                end
            end
        end
    end
    return out
end

function LC.AdvanceChain(q, success)
    local ply = q.owner
    local chain = LC.Chains[q.chain]
    if not chain then return end
    local cs = LC.ChainState(ply, chain.id)
    local def = chain.parts[q.chainPart]
    if ply.lcStoryPostings then ply.lcStoryPostings[chain.id] = nil end
    local pace = math.min(chain.pace or math.huge, cvPacing:GetFloat()) -- (a chain can ask to come round sooner)

    if success and q.chainDecline then
        cs.part = nil
        cs.readyAt = os.time() + 1800
        ply:ChatPrint("[Story] You turned down " .. chain.name .. ". It comes back to your board (F3) in about 30 minutes.")
    elseif success and q.chainEnd then
        cs.done, cs.part = q.chainEnd, nil
        local ending = chain.endings and chain.endings[q.chainEnd] or q.chainEnd
        ply:ChatPrint("[Story] " .. chain.name .. " has ended. " .. ending)
        LC.Log("info", string.format("Story %s ended for %s: %s", chain.id, ply:Nick(), q.chainEnd))
        hook.Run("LivingCityStoryEnded", ply, chain.id, q.chainEnd)
    elseif success then
        local nextPart = q.chainNext or (def and def.next)
        if nextPart and chain.parts[nextPart] then
            cs.part = nextPart
            cs.readyAt = os.time() + pace
            ply:ChatPrint("[Story] " .. chain.name .. " continues." .. (pace > 0 and " Check your board (F3) in a little while." or " Check your board (F3)."))
        else
            cs.done, cs.part = "complete", nil
            ply:ChatPrint("[Story] " .. chain.name .. " has ended.")
        end
    else
        cs.part = q.chainPart
        cs.readyAt = os.time() + pace
        ply:ChatPrint("[Story] " .. chain.name .. ": that part failed. You can try it again: it comes back to your board (F3).")
    end
    LC.SaveStory(ply)
end

function LC.CheckUnlocks(ply)
    if not IsValid(ply) then return end
    local s = LC.Story(ply)
    local changed = false
    for _, chain in ipairs(LC.ChainList) do
        if ChainFits(chain, ply) and not s.chains[chain.id] and not s.notified[chain.id] then
            local ok, yes = pcall(chain.unlock, ply, s)
            if ok and yes then
                s.notified[chain.id] = true
                changed = true
                ply:ChatPrint("[Story] A new story is available. Check your job board (F3).")
            end
        end
    end
    if changed then LC.SaveStory(ply) end
end

-- Story NPCs: real people placed in the world for one quest.
local function SpawnActor(q, role, pos, holdSecs, keep, want)
    local spawner = LC.Spawners and LC.Spawners[role]
    if not spawner or not pos then return nil end
    local npc, st = spawner(pos + Vector(math.random(-40, 40), math.random(-40, 40), 4), role == "citizen" and want or nil)
    if not IsValid(npc) then return nil end
    st.unmanaged = true
    st.leaveAt = nil
    st.routeGroup = nil
    Lock(q, npc)
    if holdSecs then
        npc:SetSchedule(SCHED_IDLE_STAND)
        LC.SetState(npc, st, "event")
        st.eventUntil = CurTime() + holdSecs
    end
    if not keep then q.ents[#q.ents + 1] = npc end
    return npc, st
end

-- True while this player's current job is to speak with a Civil Protection unit,
-- so units don't treat walking up to one as crowding him.
function LC.QuestWantsCop(ply)
    local q = LC.QuestOf and LC.QuestOf[ply]
    local st = q and not q.done and Stage(q)
    return st ~= nil and st.kind == "count" and st.event == "used_npc" and st.filter == IsCopNPC
end

-- True while pressing E on this NPC is part of this player's current job
-- (so it doesn't open the talk window as well).
function LC.QuestWantsNPC(ply, npc)
    local q = LC.QuestOf and LC.QuestOf[ply]
    local st = q and not q.done and Stage(q)
    if not st then return false end
    if st.kind == "count" and st.event == "used_npc" then
        return not st.filter or st.filter(q, ply, npc, LC.NPCs[npc]) == true
    end
    if st.kind == "target" and st.npc == npc then return true end
    if st.kind == "contact" or st.kind == "escort" then return st.npc == npc end
    return false
end

-- Somewhere to stand a person: inside the housing block if pos is a block's center,
-- else the spot itself.
local function PersonSpot(pos)
    for _, z in ipairs(LC.ZonesOfKind and LC.ZonesOfKind("block") or {}) do
        if z.pos:DistToSqr(pos) < 16 then return LC.SpotInZone(z) or pos end
    end
    return pos
end

-- A person to meet: someone is waiting at pos (marked on your HUD) and you press E
-- on them. role is "citizen" (default) or "cop". If nobody can be placed, it falls
-- back to simply walking there. line is what the quest says when you've met.
local function Contact(text, pos, role, line, want)
    local where = PersonSpot(pos)
    return {
        kind = "target", action = "use", pos = where, r = 140, text = text,
        onEnter = function(q, st)
            local npc = SpawnActor(q, role or "citizen", where, 900, nil, want)
            if not npc then
                st.kind, st.r, st.npc = "deliver", 150, nil
                return
            end
            st.npc = npc
        end,
        onDone = line and function(q) Narrate(q, line) end or nil,
    }
end

-- Everything the story file needs to build parts out of the same pieces.
-- Where someone's job is taking them right now (the marker on their screen), or nil.
function LC.QuestObjectivePos(ply)
    local q = IsValid(ply) and LC.QuestOf[ply]
    local st = q and not q.done and Stage(q)
    if not st then return nil end
    local ent, pos = MarkerFor(q, st, ply)
    if IsValid(ent) then return ent:GetPos() end
    return pos
end

LC.QB = {
    Contact = Contact, PersonSpot = PersonSpot,
    Goto = Goto, Deliver = Deliver, Hold = Hold, Count = Count, Choice = Choice,
    FindCitizenStage = FindCitizenStage, ArrestStage = ArrestStage, Flee = Flee,
    Spot = Spot, Route = Route, SpotsNear = SpotsNear, HideSpots = HideSpots, FindBins = FindBins, Place = Place, SafeHouse = SafeHouse, NearestZone = NearestZone,
    Freeze = Freeze, Lock = Lock, SpawnActor = SpawnActor, SpawnItem = SpawnItem,
    CitizenID = CitizenID, Pick = Pick, Narrate = Narrate, InsertStages = InsertStages,
    IsCitizenNPC = IsCitizenNPC, IsCopNPC = IsCopNPC, RandomCitizen = RandomCitizen, CountRole = CountRole,
    Members = Members, Stage = Stage, Advance = Advance, Finish = Finish, SendStateAll = function(q) SendStateAll(q) end,
    RankIndex = RankIndex, Special = Special, IsZombieNPC = IsZombieNPC,
    CONTRABAND = CONTRABAND, CRIMES = CRIMES, TRASH = TRASH,
}


------------------------------------------------------------------------
-- Directives that go with the city's events. They're posted a couple of
-- minutes before an event begins (when the city knows it's coming) and as it
-- starts, only show while it's on, and are withdrawn when it ends. Many hands:
-- a whole shift of units can take the same one.
------------------------------------------------------------------------

local function RaidBlock()
    local r = LC.Raid
    if not r or not r.block then return nil end
    local z = r.zones and r.zones[1]
    if not z then
        for _, b in ipairs(LC.ZonesOfKind("block")) do if (b.group or 0) == r.block then z = b break end end
    end
    return r.block, z
end

-- a block: the one being raided, or one picked for an upcoming raid
-- Somewhere in block n (any of its wings), give or take pad.
local function InBlock(n, pos, pad)
    for _, b in ipairs(LC.ZonesOfKind("block")) do
        if (b.group or 0) == n and LCZ.Contains(b, pos, pad or 0) then return true end
    end
    return false
end

local function SomeBlock()
    local n, z = RaidBlock()
    if z then return n, z end
    local blocks = {}
    for _, b in ipairs(LC.ZonesOfKind("block")) do if (b.group or 0) > 0 then blocks[#blocks + 1] = b end end
    if #blocks == 0 then return nil end
    local b = Pick(blocks)
    return b.group, b
end

T{
    id = "cp_blockraid", factions = { cp = true }, during = { "raid" }, squad = 8,
    available = function() return LC.Running and #LC.ZonesOfKind("block") > 0 end,
    build = function(ply)
        local n, z = SomeBlock()
        if not z then return nil end
        local name = LC.BlockName and LC.BlockName(n) or ("Block " .. n)
        return {
            title = "Housing block inspection: " .. name, reward = 45, limit = 600,
            desc = "The raid team is searching " .. name .. ". Back them up: inspect the residents, then guard the block until the search is done.",
            stages = GamesOn() and {
                GameGo(z.pos, "Go to " .. name .. " (marked)", "breach", { pos = z.pos }, math.max(250, z.r * 0.8)),
                GameStage("Breach and search: press E on the locked door to set the charge and stand back, press E on each resident to put them on the floor, then press E on the furniture to search it"),
            } or {
                Goto(z.pos, "Go to " .. name .. " (marked)", math.max(250, z.r * 0.8)),
                { kind = "count", event = "used_npc", need = 3, distinct = true,
                  text = "Inspect 3 residents of " .. name .. ": walk up to each one and press E",
                  filter = function(_, _, npc)
                      local st = LC.NPCs[npc]
                      return st ~= nil and st.role == "citizen" and LCZ.Contains(z, npc:GetPos(), 300)
                  end },
                Hold(z.pos, 45, "Stay at the block for 45 seconds while the team finishes the search", math.max(300, z.r)),
            },
            intro = "Dispatch: all units, " .. name .. " is under inspection. Nobody leaves without papers.",
        }
    end,
}

T{
    id = "cp_curfew", factions = { cp = true, ota = true }, during = { "curfew" }, squad = 8,
    available = function() return LC.Running end,
    build = function(ply)
        local stops = Route(ply, 3, 400, 1100)
        if #stops == 0 then return nil end
        local stages = {}
        for i, sp in ipairs(stops) do stages[#stages + 1] = Goto(sp, string.format("Clear the streets: go to stop %d of %d, %s", i, #stops, Place(sp, ply:GetPos())), 180) end
        stages[#stages + 1] = Hold(stops[#stops], 60, "Stay on this street for 60 seconds. Anyone still outside gets three warnings before they become wanted", 300)
        return {
            title = "Curfew enforcement", reward = 35, limit = 540,
            desc = "Curfew is in effect. Walk to each marked stop, moving people along as you go, then stay at the last stop for 60 seconds.",
            stages = stages,
        }
    end,
}

T{
    id = "cp_lockdown", factions = { cp = true, ota = true }, during = { "lockdown" }, squad = 8,
    available = function() return LC.Running end,
    build = function(ply)
        local p = #LC.PointsOfKind("checkpoint") > 0 and Pick(LC.PointsOfKind("checkpoint")).pos or Spot(ply, 300, 2000)
        if not p then return nil end
        return {
            title = "Lockdown: hold the perimeter " .. Place(p, ply:GetPos()), reward = 45, limit = 480,
            desc = "Lockdown is in effect. Go to your post and guard it for 90 seconds, or until the lockdown lifts. Nobody moves through your sector.",
            stages = { Goto(p, "Go to your marked post", 220), Hold(p, 90, "Stay at your post for 90 seconds", 300) },
        }
    end,
}

T{
    id = "res_warnblock", factions = { resistance = true }, during = { "raid" }, squad = 6,
    available = function() return LC.Running and #LC.ZonesOfKind("block") > 0 end,
    build = function(ply)
        local n, z = SomeBlock()
        if not z then return nil end
        local name = LC.BlockName and LC.BlockName(n) or ("Block " .. n)
        return {
            title = "Warn " .. name, reward = 30, limit = 420,
            desc = "Civil Protection units are about to search " .. name .. ". Get there first and warn three residents to move what they're hiding.",
            stages = {
                Goto(z.pos, "Get to " .. name .. " (marked) before the Civil Protection units do", math.max(250, z.r * 0.8)),
                { kind = "count", event = "used_npc", need = 3, distinct = true,
                  text = "Warn 3 residents: walk up to each one and press E",
                  -- (anyone in any wing of the block)
                  filter = function(_, _, npc)
                      local st = LC.NPCs[npc]
                      return st ~= nil and st.role == "citizen" and InBlock(n, npc:GetPos(), 300)
                  end,
                  -- a block with nobody home: residents come out of their rooms to be warned
                  onEnter = function(q)
                      local home = 0
                      for npc, st in pairs(LC.NPCs) do
                          if IsValid(npc) and st.role == "citizen" and InBlock(n, npc:GetPos(), 0) then home = home + 1 end
                      end
                      local wings = {}
                      for _, b in ipairs(LC.ZonesOfKind("block")) do if (b.group or 0) == n then wings[#wings + 1] = b end end
                      for _ = home + 1, 4 do
                          local spot = #wings > 0 and LC.SpotInZone(Pick(wings))
                          if spot then SpawnActor(q, "citizen", spot, 120) end
                      end
                  end },
            },
        }
    end,
}

T{
    id = "res_curfewrun", factions = { resistance = true }, during = { "curfew", "lockdown" }, squad = 4,
    available = function() return LC.Running end,
    build = function(ply)
        local from = Spot(ply, 600, 2500)
        if not from then return nil end
        local to, r, toName = SafeHouse(ply)
        if not to then return nil end
        return {
            title = "Run supplies under curfew", reward = 40, limit = 480,
            desc = "The streets are empty and the Civil Protection units are busy. A contact left a crate " .. Place(from, ply:GetPos()) .. ". Pick it up and bring it to the safe spot: " .. toName .. ".",
            stages = {
                { kind = "collect", spots = HideSpots(from, 1, 300, true), model = "models/items/item_item_crate.mdl", need = 1,
                  text = "Find the crate (marked) and press E to pick it up" },
                Deliver(to, "Bring it to the safe spot (" .. toName .. ")", r),
            },
        }
    end,
}

------------------------------------------------------------------------
-- Boards
------------------------------------------------------------------------

local function FactionPlayers(f)
    local n = 0
    for _, p in ipairs(player.GetAll()) do if LC.QuestFaction(p) == f then n = n + 1 end end
    return n
end

local function ViolentInUse()
    local n = 0
    for q in pairs(LC.ActiveQuests) do if q.violent then n = n + 1 end end
    for _, list in pairs(LC.Postings) do
        for _, p in ipairs(list) do if p.violent and not p.q and not p.dead then n = n + 1 end end
    end
    return n
end

function LC.ViolentCap()
    return math.max(1, math.floor(#player.GetAll() / math.max(1, cvViolent:GetFloat())))
end

-- Which of a directive's events is on (or about to be), if any.
local function EventOn(during)
    if not during then return nil end
    for _, e in ipairs(during) do
        if LC.Event == e or LC.PendingEvent == e then return e end
    end
    return nil
end
LC.DirectiveEventOn = EventOn

local function Shuffle(t)
    for i = #t, 2, -1 do
        local j = math.random(i)
        t[i], t[j] = t[j], t[i]
    end
    return t
end
LC.QB.Shuffle = Shuffle

function LC.RefreshBoard(ply)
    local f = LC.QuestFaction(ply)
    local now = CurTime()
    local list = {}
    for _, p in ipairs(LC.Postings[f] or {}) do
        -- an event's directives only while it's on (or about to be)
        local stale = p.during and not p.q and not EventOn(p.during)
        if not p.dead and not stale and (p.q or now < p.expiresPost) then list[#list + 1] = p end
    end
    LC.Postings[f] = list

    local want = math.Clamp(2 + math.ceil(FactionPlayers(f) * 0.6), 3, 10)
    local open = 0
    local used = {}
    for _, p in ipairs(list) do
        if not p.q then open = open + 1 end
        used[p.tmpl] = true
    end

    local cands = {}
    for _, t in ipairs(LC.QuestTemplates) do
        if t.factions[f] and not used[t] and (not t.during or EventOn(t.during)) then
            local ok, avail = pcall(function() return not t.available or t.available(ply) end)
            if ok and avail then cands[#cands + 1] = t end
        end
    end
    for _, t in ipairs(Shuffle(cands)) do
        if open >= want then break end
        if not t.violent or ViolentInUse() < LC.ViolentCap() then
            local ok, spec = pcall(t.build, ply)
            if not ok then
                LC.Error("quest " .. t.id, spec)
            elseif spec then
                spec.id = nextId
                nextId = nextId + 1
                spec.tmpl = t
                spec.violent = t.violent
                spec.faction = f
                spec.squad = spec.squad or t.squad
                spec.during = t.during
                spec.expiresPost = now + 240
                spec.data = spec.data or {}
                list[#list + 1] = spec
                open = open + 1
            end
        end
    end
    return list, f
end

-- Post a directive right now, on every board it belongs on that has someone to
-- take it, whatever else is there; tell them. focus: what it's about (a zone).
-- Returns the postings made.
function LC.PostDirective(tid, focus)
    if not cvOn:GetBool() then return {} end
    local t
    for _, x in ipairs(LC.QuestTemplates) do if x.id == tid then t = x end end
    if not t then return {} end
    local now = CurTime()
    local made = {}
    for f in pairs(t.factions) do
        local people = {}
        for _, p in ipairs(player.GetAll()) do if LC.QuestFaction(p) == f then people[#people + 1] = p end end
        if #people > 0 then
            LC.Postings[f] = LC.Postings[f] or {}
            -- one of each up at a time (an open one already there will do)
            local have = false
            for _, p in ipairs(LC.Postings[f]) do
                if p.tmpl == t and not p.dead and not p.q and now < p.expiresPost then have = true end
            end
            local ok, avail = pcall(function() return not t.available or t.available(people[1]) end)
            if not have and ok and avail then
                local okB, spec = pcall(t.build, people[1], focus)
                if not okB then
                    LC.Error("quest " .. t.id, spec)
                elseif spec then
                    spec.id = nextId
                    nextId = nextId + 1
                    spec.tmpl, spec.violent, spec.faction = t, t.violent, f
                    spec.squad = spec.squad or t.squad
                    spec.during = t.during
                    spec.urgent = true
                    spec.expiresPost = now + (t.during and math.max(300, ((LC.EventEnds or now) - now) + 180) or 600)
                    spec.data = spec.data or {}
                    table.insert(LC.Postings[f], 1, spec)
                    made[#made + 1] = spec
                    local board = BOARDS[f] or "Jobs"
                    local room = math.max(cvSquad:GetInt(), spec.squad or 0)
                    for _, p in ipairs(people) do
                        p:ChatPrint(string.format("[%s] New job: %s. Take it from your job board (F3). Up to %d people can work on it together.", board, spec.title, room))
                    end
                end
            end
        end
    end
    return made
end

-- The city's events bring their own directives, and take them away again.
local function PostFor(name)
    for _, t in ipairs(LC.QuestTemplates) do
        if t.during then
            for _, e in ipairs(t.during) do if e == name then LC.PostDirective(t.id) break end end
        end
    end
end
hook.Add("LivingCityEventSoon", "LivingCityDirectives", function(name) PostFor(name) end)
hook.Add("LivingCityEventStarted", "LivingCityDirectives", function(name) PostFor(name) end)
hook.Add("LivingCityEventEnded", "LivingCityDirectives", function(was)
    local function bound(p) if not p.during then return false end for _, e in ipairs(p.during) do if e == was then return true end end return false end
    for _, list in pairs(LC.Postings) do
        for _, p in ipairs(list) do
            if bound(p) and not EventOn(p.during) then
                if p.q and not p.q.done then
                    -- whoever got stuck in gets paid; whoever hadn't started hasn't failed;
                    -- a count left short (residents warned, people stopped) wasn't done
                    local st = Stage(p.q)
                    local short = st and st.kind == "count" and (st.got or 0) < (st.need or 1)
                    if short and (p.q.stage or 1) > 1 then
                        Finish(p.q, false, string.format("the event ended with only %d of %d done", st.got or 0, st.need or 1))
                    elseif (p.q.stage or 1) > 1 then
                        Narrate(p.q, "The event is over. Good work: the job counts as done.")
                        Finish(p.q, true)
                    else
                        Finish(p.q, false, "the event ended before you got started, so it doesn't count against you")
                    end
                end
                p.dead = true
            end
        end
    end
end)
-- Ground lost: the directive to take it back goes up at once.
hook.Add("LivingCityTerritoryGrew", "LivingCityDirectives", function(seed, z)
    if not seed then return end
    LC.PostDirective(seed.kind == "infest" and "cp_infest" or "cp_retake", z)
end)
hook.Add("LivingCityOutbreak", "LivingCityDirectives", function()
    LC.LastOutbreak = CurTime()
    LC.PostDirective("cp_infest")
end)

function LC.SendBoard(ply)
    if not cvOn:GetBool() then return ply:ChatPrint("[Living City] Quests are turned off on this server.") end
    local list, f = LC.RefreshBoard(ply)
    local out = {}
    local mine = LC.QuestOf[ply]
    -- a stalker's board has its work on it (The Stalker's Lot), and nothing else
    local stalker = LC.PlayerIsStalker and LC.PlayerIsStalker(ply)
    if stalker then list = {} end
    for _, p in ipairs(LC.StoryPostings and LC.StoryPostings(ply) or {}) do
        if not stalker or p.chain == "stalker" then
            out[#out + 1] = {
                id = p.id, title = p.title, desc = p.desc, reward = p.reward, violent = false, limit = p.limit,
                taken = p.q and 1 or 0, max = 1, mine = mine ~= nil and mine.posting == p,
                story = true, chain = p.chainName, part = p.partNum,
            }
        end
    end
    for _, p in ipairs(list) do
        out[#out + 1] = {
            id = p.id, title = p.title, desc = p.desc, reward = p.reward, violent = p.violent == true,
            limit = p.limit, taken = p.q and #Members(p.q) or 0, max = math.max(cvSquad:GetInt(), p.squad or 0), mine = mine ~= nil and mine.posting == p,
        }
    end
    local jobs
    if not stalker and LC.CanWork and LC.CanWork(ply) and LCJ then
        jobs = { current = ply:GetNW2String("lcj_job", ""), list = {} }
        for _, o in ipairs(LCJ.Occupations) do
            -- (a post you have to earn isn't even listed until you have: the Block Warden)
            local earned = not o.minStanding or (LC.Standing and LC.Standing(ply) >= o.minStanding)
            if not LCJ.Closed(o) and earned then jobs.list[#jobs.list + 1] = { id = o.id, name = o.name, desc = o.desc, path = o.path or "" } end
        end
    end
    LC.SendCompressed("lcq_board", {
        jobs = jobs, credits = LC.Credits and LC.Credits(ply) or nil, standing = LC.Standing and LC.Standing(ply) or nil,
        board = BOARDS[f] or "Jobs", faction = f, postings = out, active = mine ~= nil,
        traits = { loyalty = LC.Trait(ply, "loyalty"), sympathy = LC.Trait(ply, "sympathy"), corruption = LC.Trait(ply, "corruption") },
        wait = math.max(0, math.ceil((ply.lcqNext or 0) - CurTime())),
    }, { ply })
end

function LC.AcceptPosting(ply, pid)
    if not cvOn:GetBool() then return false end
    if LC.QuestOf[ply] then ply:ChatPrint("[Living City] Finish or abandon your current job first.") return false end
    if (ply.lcqNext or 0) > CurTime() then
        ply:ChatPrint("[Living City] You have to wait before taking another job. Next job in " .. math.ceil(ply.lcqNext - CurTime()) .. "s.")
        return false
    end
    local f = LC.QuestFaction(ply)
    local posting
    for _, p in ipairs(LC.Postings[f] or {}) do if p.id == pid then posting = p end end
    if not posting and ply.lcStoryPostings then
        for _, p in pairs(ply.lcStoryPostings) do if p.id == pid then posting = p end end
    end
    if not posting or posting.dead then ply:ChatPrint("[Living City] That job is no longer available.") return false end
    if posting.story and posting.owner ~= ply then return false end
    if LC.PlayerIsStalker and LC.PlayerIsStalker(ply) and posting.chain ~= "stalker" then
        ply:ChatPrint("[Living City] Stalkers can only do stalker work. You can't take this job.")
        return false
    end

    if posting.q then
        if posting.story then return false end
        local q = posting.q
        if #Members(q) >= math.max(cvSquad:GetInt(), posting.squad or 0) then ply:ChatPrint("[Living City] That job has enough people.") return false end
        table.insert(q.members, ply)
        LC.QuestOf[ply] = q
        Narrate(q, ply:Nick() .. " has joined the job.")
        SendStateAll(q)
        return true
    end

    local q = {
        id = posting.id, posting = posting, tmpl = posting.tmpl, title = posting.title, desc = posting.desc,
        reward = posting.reward, violent = posting.violent, board = BOARDS[f] or "Jobs",
        owner = ply, members = { ply }, stages = posting.stages, stage = 1,
        expires = CurTime() + (posting.limit or 300), ents = {}, marked = {}, data = posting.data or {},
        failOnArrest = posting.failOnArrest, tick = posting.tick, onFinish = posting.onFinish,
    }
    if posting.story then
        q.chain, q.chainPart, q.board = posting.chain, posting.part, posting.chainName
        local cs = LC.ChainState(ply, posting.chain)
        cs.part = posting.part
        q.chainData = cs.data
        LC.SaveStory(ply)
    end
    posting.q = q
    LC.QuestOf[ply] = q
    LC.ActiveQuests[q] = true
    ply:ChatPrint("[" .. q.board .. "] " .. q.title .. ". " .. (q.desc or ""))
    if posting.intro then Narrate(q, posting.intro) end
    LC.Log("info", string.format("Quest accepted: %s [%s] by %s", q.title, q.tmpl.id, ply:Nick()))
    hook.Run("LivingCityQuestAccepted", ply, q)
    EnterStage(q)
    return true
end

function LC.AbandonQuest(ply)
    local q = LC.QuestOf[ply]
    if not q then return end
    if q.owner == ply and #Members(q) <= 1 then return Finish(q, false, "abandoned") end
    for i, p in ipairs(q.members) do if p == ply then table.remove(q.members, i) break end end
    LC.QuestOf[ply] = nil
    ply.lcqNext = CurTime() + cvCooldown:GetFloat()
    if q.owner == ply then q.owner = Members(q)[1] end
    Narrate(q, ply:Nick() .. " left the job.")
    SendState(ply)
    SendStateAll(q)
end

function LC.ResolveChoice(ply, qid, idx)
    local q = LC.QuestOf[ply]
    if not q or q.id ~= qid or q.owner ~= ply then return end
    local st = Stage(q)
    if not st or st.kind ~= "choice" or st.resolved then return end
    local o = st.options[idx]
    if not o or (o.when and not o.when(q)) then return end
    st.resolved = true

    local success = true
    if o.check then
        local roll, mod = math.random(20), LC.SkillMod(ply, o.check[1])
        success = (roll ~= 1) and (roll == 20 or roll + mod >= o.check[2])
        Narrate(q, string.format("%s check: rolled %d + %d skill = %d, needed %d. %s", string.upper(o.check[1]), roll, mod,
            roll + mod, o.check[2], success and "Success." or "Failure."))
    end
    local fn = o.pick
    if not fn then
        if success then fn = o.success else fn = o.fail end
    end
    local result = fn and fn(q, ply) or "next"
    if q.done then return end
    if result == "complete" then return Finish(q, true) end
    if result == "fail" then return Finish(q, false, o.failText) end
    Advance(q)
end

net.Receive("lcq_accept", function(_, ply) LC.AcceptPosting(ply, net.ReadUInt(32)); LC.SendBoard(ply) end)
net.Receive("lcq_abandon", function(_, ply) LC.AbandonQuest(ply) end)
net.Receive("lcq_choice", function(_, ply)
    local qid, idx = net.ReadUInt(32), net.ReadUInt(8)
    LC.ResolveChoice(ply, qid, idx)
end)
net.Receive("lcq_request", function(_, ply)
    SendState(ply)
    local q = LC.QuestOf[ply]
    local st = q and Stage(q)
    if st and st.kind == "choice" and not st.resolved and q.owner == ply then OpenChoice(q, st) end
end)

hook.Add("ShowSpare1", "LivingCityQuests", function(ply) LC.SendBoard(ply) end)
concommand.Add("lcq_board", function(ply) if IsValid(ply) then LC.SendBoard(ply) end end)
hook.Add("PlayerSay", "LivingCityQuestsChat", function(ply, text)
    local t = string.lower(string.Trim(text))
    if t == "!jobs" or t == "!quests" or t == "!board" or t == "!directives" then LC.SendBoard(ply) return "" end
    if t == "!abandon" then LC.AbandonQuest(ply) return "" end
end)

------------------------------------------------------------------------
-- Story admin (handy for trying chains in singleplayer)
------------------------------------------------------------------------

local function StoryTarget(ply, name)
    if name and name ~= "" then return LC.FindPlayer(name) end
    return IsValid(ply) and ply or nil
end

concommand.Add("lcq_startchain", function(ply, _, args)
    if IsValid(ply) and not (ply:IsAdmin() or LC.CanEdit(ply)) then return end
    local chain = LC.Chains[args[1] or ""]
    local target = StoryTarget(ply, args[2])
    local function out(m) if IsValid(ply) then ply:ChatPrint(m) else print(m) end end
    if not chain then
        local ids = {}
        for _, c in ipairs(LC.ChainList) do ids[#ids + 1] = c.id end
        return out("[Story] Chains: " .. table.concat(ids, ", ") .. ". Usage: lcq_startchain <chain> [player]")
    end
    if not target then return out("[Story] Player not found.") end
    local s = LC.Story(target)
    s.chains[chain.id] = { part = chain.start, data = {}, readyAt = 0 }
    LC.SaveStory(target)
    if target.lcStoryPostings then target.lcStoryPostings[chain.id] = nil end
    out("[Story] " .. chain.name .. " is ready on " .. target:Nick() .. "'s board (F3).")
end)

concommand.Add("lcq_story", function(ply, _, args)
    if IsValid(ply) and not (ply:IsAdmin() or LC.CanEdit(ply)) then return end
    local target = StoryTarget(ply, args[1])
    local function out(m) if IsValid(ply) then ply:ChatPrint(m) else print(m) end end
    if not target then return out("[Story] Player not found.") end
    local s = LC.Story(target)
    out(string.format("[Story] %s: loyalty %d, sympathy %d, corruption %d", target:Nick(),
        LC.Trait(target, "loyalty"), LC.Trait(target, "sympathy"), LC.Trait(target, "corruption")))
    local c = {}
    for k, v in SortedPairs(s.counters) do c[#c + 1] = k .. " " .. v end
    out("  counters: " .. (#c > 0 and table.concat(c, ", ") or "none"))
    for id, cs in SortedPairs(s.chains) do
        out(string.format("  %s: %s", id, cs.done and ("ended (" .. cs.done .. ")") or ("at " .. tostring(cs.part))))
    end
end)

concommand.Add("lcq_resetstory", function(ply, _, args)
    if IsValid(ply) and not (ply:IsAdmin() or LC.CanEdit(ply)) then return end
    local target = StoryTarget(ply, args[1])
    if not target then return end
    target.lcStory = nil
    target.lcStoryPostings = nil
    target:RemovePData("lcq_story")
    for _, t in ipairs({ "loyalty", "sympathy", "corruption" }) do target:RemovePData("lcq_" .. t) end
    target:ChatPrint("[Story] Your story has been reset.")
end)
