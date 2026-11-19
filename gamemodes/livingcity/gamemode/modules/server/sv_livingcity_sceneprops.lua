--[[
    Living City: two pieces of set dressing the owner picked (19 November)

      The ration plant's counter (the owner: "please add soupprep.mdl as
      automatically placing on a nearby raised table/surface for ration
      prep"): models/props_lab/soupprep.mdl, a busy kitchen counter, is set
      on a table or counter top near the Ration Production workplace (the
      editor's work points of that job), facing where the worker stands. One
      for each ration plant, however many work points it has. No table or
      counter within reach: nothing is put there.

      The Resistance headquarters ("securitybank.mdl should be utilized in
      resistance headquarter(s) ... a good setting for the Resistance
      Leader"): models/props_lab/securitybank.mdl, security monitors on
      shelves, stands in every rebel camp by its notice board (else the
      fund's TV, else the middle of the camp), on the floor with its back to
      a wall when one is near, facing into the camp, out of the way through.
      It is one of the camp's own things (LC.RebelProps,
      sv_livingcity_scavenge.lua), so a held E carries it like the rest and
      it's put back where it was left (sv_livingcity_campmove.lua).

    Both stay put: frozen, not used, not carried off, not saved as a
    persistent prop. Both models ship with Half-Life 2; a server without one
    goes without, and nothing is said about it.
]]

if CLIENT then return end

LC = LC or {}

LC.SceneModels = {
    soupprep = "models/props_lab/soupprep.mdl",
    securitybank = "models/props_lab/securitybank.mdl",
}
-- Which way each model faces: 0 when its front is its +X (Valve's way), 180 when its back is.
-- If one is ever seen facing the wall, this is the number to change.
local FRONT_YAW = { soupprep = 0, securitybank = 0 }

-- The model's path if this server has it, else nil (looked up once).
local found = {}
function LC.SceneModel(name)
    local f = found[name]
    if f == nil then
        local m = LC.SceneModels[name]
        local have = false
        if m then
            if util.IsValidModel then have = util.IsValidModel(m) == true
            elseif file and file.Exists then have = file.Exists(m, "GAME") == true end
        end
        f = have and m or false
        found[name] = f
    end
    return f or nil
end
function LC.SceneModelForget() found = {} end

-- How big a model is (its bounds, from a copy that's never spawned), once per model.
local bounds = {}
local function BoundsOf(model)
    local b = bounds[model]
    if b then return b[1], b[2] end
    local e = ents.Create("prop_physics")
    if not IsValid(e) then return nil end
    e:SetModel(model)
    local mins, maxs = e:OBBMins(), e:OBBMaxs()
    e:Remove()
    if not (mins and maxs) then return nil end
    bounds[model] = { mins, maxs }
    return mins, maxs
end
function LC.SceneBoundsForget() bounds = {} end

local function Dir(yaw) local r = math.rad(yaw) return Vector(math.cos(r), math.sin(r), 0) end
local function YawOf(v) return math.deg(math.atan2(v.y, v.x)) end
-- How far its front and back are from its origin, and half its width, the way it faces.
local function Extents(name, mins, maxs)
    local hw = math.max(math.abs(mins.y), math.abs(maxs.y))
    if (FRONT_YAW[name] or 0) == 180 then return -mins.x, maxs.x, hw end
    return maxs.x, -mins.x, hw
end
-- Where the middle of its body is, stood at o turned to yaw.
local function Middle(o, yaw, mins, maxs)
    return o + Dir(yaw) * ((mins.x + maxs.x) / 2) + Dir(yaw + 90) * ((mins.y + maxs.y) / 2)
end

-- Something of anybody's standing here (a person, a prop, one of the city's things), at or above `below`.
local function Occupied(pos, r, below)
    for _, e in ipairs(ents.FindInSphere(pos, r)) do
        if IsValid(e) and e:GetPos().z > below then
            local cls = e:GetClass() or ""
            if (e.IsPlayer and e:IsPlayer()) or (e.IsNPC and e:IsNPC()) or string.sub(cls, 1, 5) == "prop_" or string.sub(cls, 1, 3) == "lc_" then
                return true
            end
        end
    end
    return false
end

-- A piece of set dressing that stays put.
local function Place(model, pos, yaw, scene, rebelKind)
    local e = ents.Create("prop_physics")
    if not IsValid(e) then return nil end
    e:SetModel(model)
    e:SetPos(pos)
    e:SetAngles(Angle(0, yaw or 0, 0))
    e:Spawn()
    local phys = e.GetPhysicsObject and e:GetPhysicsObject()
    if IsValid(phys) then phys:EnableMotion(false) end
    e.lcDressing = true -- (scenery: not loot, not pocketed, not a persistent prop)
    e.lcSceneProp = scene
    e.lcRebelProp = rebelKind -- (the camp's monitors: one of its things, carried with a held E)
    return e
end
LC.ScenePlace = Place

------------------------------------------------------------------------
-- The ration plant's counter
------------------------------------------------------------------------

local LOW, HIGH = 24, 54 -- a table or counter top: this high above the floor the worker stands on
local REACH = 240        -- how far from the workplace it may be
local STEP = 16          -- how finely the tops round it are looked over
local ONE_PER = 700      -- one counter for a ration plant, however many work points it has

local function Down(x, y, z1, z2)
    return util.TraceLine({ start = Vector(x, y, z1), endpos = Vector(x, y, z2), mask = MASK_SOLID })
end
-- What it may stand on: the world, or a prop that's fixed in place (a table nobody can shove away).
local function IsMap(e) return not IsValid(e) or (e.IsWorld and e:IsWorld()) end
local function Bearer(e)
    if IsMap(e) then return true end
    if (e.IsPlayer and e:IsPlayer()) or (e.IsNPC and e:IsNPC()) or e.lcQuest or e.lcRebelProp or e.lcSceneProp then return false end
    local cls = e:GetClass() or ""
    if cls == "prop_dynamic" then return true end
    if cls ~= "prop_physics" then return false end
    local phys = e.GetPhysicsObject and e:GetPhysicsObject()
    return IsValid(phys) and not phys:IsMotionEnabled()
end
-- The level top of a table or counter at x, y (its height), or nil.
local function TopAt(x, y, floorZ)
    local tr = Down(x, y, floorZ + HIGH + 16, floorZ + LOW - 8)
    if not (tr and tr.Hit) or tr.StartSolid then return nil end
    if tr.HitNormal and tr.HitNormal.z < 0.95 then return nil end
    local h = tr.HitPos.z - floorZ
    if h < LOW or h > HIGH or not Bearer(tr.Entity) then return nil end
    return tr.HitPos.z, not IsMap(tr.Entity) and tr.Entity or nil
end

-- It fits on that top, standing at x, y and facing `face`: level under it (a little may hang over the
-- edge), open floor in front of it (a counter you stand at, not a raised floor), room above it and
-- nothing already there.
local function Fits(x, y, topZ, floorZ, face, mins, maxs, front)
    local yaw = face + (FRONT_YAW.soupprep or 0)
    local fw, sd = Dir(yaw), Dir(yaw + 90)
    local o = Vector(x, y, 0)
    for _, cx in ipairs({ mins.x * 0.8, maxs.x * 0.8 }) do
        for _, cy in ipairs({ mins.y * 0.8, maxs.y * 0.8 }) do
            local p = o + fw * cx + sd * cy
            local t = TopAt(p.x, p.y, floorZ)
            if not t or math.abs(t - topZ) > 3 then return false end
        end
    end
    local ahead = o + Dir(face) * (front + 18)
    local tr = Down(ahead.x, ahead.y, topZ + 8, floorZ - 24)
    if not (tr and tr.Hit) or tr.StartSolid or math.abs(tr.HitPos.z - floorZ) > 12 then return false end
    local c = Middle(o, yaw, mins, maxs)
    local s = math.min(maxs.x - mins.x, maxs.y - mins.y) * 0.4
    local h = math.max(4, maxs.z - mins.z - 2)
    local th = util.TraceHull({ start = Vector(c.x, c.y, topZ + 2), endpos = Vector(c.x, c.y, topZ + 3),
        mins = Vector(-s, -s, 0), maxs = Vector(s, s, h), mask = MASK_SOLID })
    if th and (th.Hit or th.StartSolid) then return false end
    local reach = math.sqrt((maxs.x - mins.x) ^ 2 + (maxs.y - mins.y) ^ 2) / 2 + 4
    return not Occupied(Vector(c.x, c.y, topZ + 4), reach, topZ - 4)
end

-- Where on a table or counter near pos (where a worker stands) the counter scene goes, facing the
-- worker: its origin, its yaw and what it stands on (nil for the map itself); nil if there's no top
-- within reach.
function LC.CounterSpot(pos, model)
    model = model or LC.SceneModel("soupprep")
    if not (pos and model) then return nil end
    local mins, maxs = BoundsOf(model)
    if not mins then return nil end
    local floorZ = (LC.GroundAt and LC.GroundAt(pos) or pos).z
    local front = Extents("soupprep", mins, maxs)
    local lift = math.max(0, -mins.z) + 0.5
    local spots = {}
    local n = math.floor(REACH / STEP)
    for i = -n, n do
        for j = -n, n do
            local d2 = (i * i + j * j) * STEP * STEP
            if d2 > 0 and d2 <= REACH * REACH then spots[#spots + 1] = { pos.x + i * STEP, pos.y + j * STEP, d2 } end
        end
    end
    table.sort(spots, function(a, b) return a[3] < b[3] end)
    for _, s in ipairs(spots) do
        local x, y = s[1], s[2]
        local topZ, under = TopAt(x, y, floorZ)
        if topZ then
            -- facing the worker, square to the room (maps are built square); else along the counter
            local face = math.floor((YawOf(Vector(pos.x - x, pos.y - y, 0)) + 45) / 90) * 90
            for _, f in ipairs({ face, face + 90, face - 90 }) do
                if Fits(x, y, topZ, floorZ, f, mins, maxs, front) then
                    return Vector(x, y, topZ + lift), f + (FRONT_YAW.soupprep or 0), under
                end
            end
        end
    end
    return nil
end

LC.KitchenProps = LC.KitchenProps or {} -- [the work point's key] = the counter scene
local tries = {}                         -- [key] = when to look again

local function Key(p) return string.format("%d_%d_%d", math.floor(p.pos.x), math.floor(p.pos.y), math.floor(p.pos.z)) end
local function KitchenPoints()
    local job = LCJ and LCJ.ById and LCJ.ById.kitchen
    if not job or not LC.PointsOfKind then return {} end
    return LC.PointsOfKind("work", job.num)
end

function LC.EnsureKitchenProps()
    local m = LC.Running and LC.SceneModel("soupprep")
    local live, now = {}, CurTime()
    if m then
        for _, p in ipairs(KitchenPoints()) do
            local key = Key(p)
            local e = LC.KitchenProps[key]
            -- (the table it stood on taken away or shoved: it goes, and finds a top again)
            if IsValid(e) and e.lcOnTop ~= nil and (not IsValid(e.lcOnTop) or e.lcOnTop:GetPos():DistToSqr(e.lcOnTopAt) > 8 * 8) then
                e:Remove()
                e = nil
            end
            if IsValid(e) then
                live[key] = true
            else
                local near = false
                for k, o in pairs(LC.KitchenProps) do
                    if k ~= key and IsValid(o) and o:GetPos():DistToSqr(p.pos) < ONE_PER * ONE_PER then near = true break end
                end
                if not near and now >= (tries[key] or 0) then
                    tries[key] = now + 60
                    local pos, yaw, under = LC.CounterSpot(p.pos, m)
                    if pos and LC.IsSeen and LC.IsSeen(pos + Vector(0, 0, 10)) then
                        tries[key] = now + 10 -- (somebody's looking: in a moment)
                    elseif pos then
                        e = Place(m, pos, yaw, "soupprep")
                        if IsValid(e) then
                            if under then e.lcOnTop, e.lcOnTopAt = under, under:GetPos() end
                            LC.KitchenProps[key] = e
                            live[key] = true
                        end
                    end
                end
            end
        end
    end
    for key, e in pairs(LC.KitchenProps) do
        if not live[key] then
            if IsValid(e) then e:Remove() end
            LC.KitchenProps[key] = nil
        end
    end
end

timer.Create("LivingCitySceneProps", 10, 0, function()
    local ok, err = LC.Try(LC.EnsureKitchenProps)
    if not ok then LC.Error("scene props", err) end
end)

hook.Add("LivingCityStopped", "LivingCitySceneProps", function()
    for _, e in pairs(LC.KitchenProps) do if IsValid(e) then e:Remove() end end
    LC.KitchenProps, tries = {}, {}
end)
hook.Add("PostCleanupMap", "LivingCitySceneProps", function() tries = {} end) -- (put back at the next look)

------------------------------------------------------------------------
-- The Resistance headquarters' security monitors
------------------------------------------------------------------------

local WALL_NEAR = 70 -- how far off a wall may be from where it would stand, for its back to go against it

local function Inside(parts, p)
    for _, part in ipairs(parts) do if LCZ.Contains(part, p, 0) then return true end end
    return false
end
-- By the camp's notice board, else the fund's TV, else the middle of the camp.
local ANCHORS = { "rebelboard", "fundtv" }
local function Anchor(z, parts)
    for _, kind in ipairs(ANCHORS) do
        for _, e in pairs(LC.Fixtures or {}) do
            if IsValid(e) and e.lcFixtureKind == kind and Inside(parts, e:GetPos()) then return e:GetPos() end
        end
    end
    return z.pos
end

-- The wall near g it could stand with its back to: where its origin goes and which way it faces
-- (out from the wall, into the room); nil if no flat wall is near (a corner of a pillar or a
-- doorway is not a wall).
local function AgainstWall(g, back, hw)
    local eye = g + Vector(0, 0, 40)
    local best, bd
    for k = 0, 7 do
        local tr = util.TraceLine({ start = eye, endpos = eye + Dir(k * 45) * (back + WALL_NEAR), mask = MASK_SOLID_BRUSHONLY })
        if tr and tr.Hit and not tr.StartSolid and tr.HitNormal and math.abs(tr.HitNormal.z) < 0.3 then
            local d = (tr.HitPos - eye):Length2D()
            if not bd or d < bd then best, bd = tr, d end
        end
    end
    if not best then return nil end
    local n = Vector(best.HitNormal.x, best.HitNormal.y, 0)
    if n:Length() < 0.1 then return nil end
    n:Normalize()
    local side = Vector(-n.y, n.x, 0)
    local wall = Vector(best.HitPos.x, best.HitPos.y, eye.z)
    for _, s in ipairs({ -0.8, 0.8 }) do
        local from = wall + n * 16 + side * (hw * s)
        local tr = util.TraceLine({ start = from, endpos = from - n * 24, mask = MASK_SOLID_BRUSHONLY })
        if not (tr and tr.Hit) or tr.StartSolid or math.abs((tr.HitPos - from):Length2D() - 16) > 4 then return nil end
    end
    return Vector(wall.x, wall.y, g.z) + n * (back + 2), YawOf(n)
end

-- Room for it here, turned to yaw: in the camp, on solid dry floor, not by a door, not narrowing a
-- passage, nothing else there and nothing in its body's way.
local function Room(parts, o, yaw, mins, maxs, front, back, hw)
    if not Inside(parts, o) then return false end
    local depth = front + back
    if LC.Footing and not LC.Footing(o, math.min(hw, depth / 2)) then return false end
    if LC.InWater and LC.InWater(o) then return false end
    if LC.NearDoor and LC.NearDoor(o, 90 + hw) then return false end
    if LC.InWalkway and LC.InWalkway(o, depth / 2) then return false end
    local c = Middle(o, yaw, mins, maxs)
    if Occupied(c + Vector(0, 0, 8), hw + 24, o.z - 64) then return false end
    local s = math.min(depth, hw * 2) * 0.4
    local h = math.max(8, maxs.z - mins.z - 8)
    local th = util.TraceHull({ start = c + Vector(0, 0, 6), endpos = c + Vector(0, 0, 7),
        mins = Vector(-s, -s, 0), maxs = Vector(s, s, h), mask = MASK_SOLID_BRUSHONLY or MASK_SOLID })
    return not (th and (th.Hit or th.StartSolid))
end

-- Where in camp z the monitors stand: their origin, their yaw, and whether their back is to a wall;
-- nil if the camp has no room for them.
function LC.SecurityBankSpot(z, model)
    model = model or LC.SceneModel("securitybank")
    if not (z and model) then return nil end
    local mins, maxs = BoundsOf(model)
    if not mins then return nil end
    local parts = LC.RebelPartsOf and LC.RebelPartsOf(z) or { z }
    local anchor = Anchor(z, parts)
    local base = LC.GroundAt and LC.GroundAt(anchor) or anchor
    local front, back, hw = Extents("securitybank", mins, maxs)
    local turn = FRONT_YAW.securitybank or 0
    local lift = Vector(0, 0, math.max(0, -mins.z) + 0.5)
    local spots = {}
    for ring = 0, 9 do
        local rad = 40 + ring * 28
        for k = 0, 15 do
            local a = k * math.pi / 8
            local p = Vector(base.x + math.cos(a) * rad, base.y + math.sin(a) * rad, base.z)
            local g = LC.FloorUnder and LC.FloorUnder(p) or p
            if g and math.abs(g.z - base.z) < 40 and Inside(parts, g) then spots[#spots + 1] = g end
        end
    end
    -- with its back to a wall, near the board first
    for _, g in ipairs(spots) do
        local o, face = AgainstWall(g, back, hw)
        local f = o and (LC.FloorUnder and LC.FloorUnder(o) or o)
        if f and math.abs(f.z - g.z) < 16 and Room(parts, f, face + turn, mins, maxs, front, back, hw) then
            return f + lift, face + turn, true
        end
    end
    -- no wall for it: on the open floor, facing the middle of the camp
    for _, g in ipairs(spots) do
        local to = Vector(z.pos.x - g.x, z.pos.y - g.y, 0)
        if to:Length() < 30 then to = Vector(anchor.x - g.x, anchor.y - g.y, 0) end
        local yaw = YawOf(to) + turn
        if (not LC.DressingClear or LC.DressingClear(g, math.max(hw, (front + back) / 2))) and Room(parts, g, yaw, mins, maxs, front, back, hw) then
            return g + lift, yaw, false
        end
    end
    return nil
end

-- Camp z's monitors: put back where the players last left them, else wherever there's room. nil if
-- this server lacks the model, there's no room, or somebody would see them appear (asked again later).
function LC.SecurityBankFor(z, saved)
    local m = LC.SceneModel("securitybank")
    if not (z and m) then return nil end
    for _, it in ipairs(saved or {}) do
        if it.prop == "bank" then return Place(m, Vector(it.x, it.y, it.z), it.yaw or 0, "securitybank", "bank") end
    end
    local o, yaw = LC.SecurityBankSpot(z, m)
    if not o or (LC.IsSeen and LC.IsSeen(o + Vector(0, 0, 40))) then return nil end
    return Place(m, o, yaw, "securitybank", "bank")
end

------------------------------------------------------------------------
-- Neither is used or carried off
------------------------------------------------------------------------

hook.Add("PlayerUse", "LivingCitySceneProps", function(_, ent) if ent.lcSceneProp then return false end end)
hook.Add("AllowPlayerPickup", "LivingCitySceneProps", function(_, ent) if ent.lcSceneProp then return false end end)
hook.Add("GravGunPickupAllowed", "LivingCitySceneProps", function(_, ent) if ent.lcSceneProp then return false end end)
