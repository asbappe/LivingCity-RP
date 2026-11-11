--[[
    Living City: the state of the city

      Territory you can see   rebel ground gets barrels, crates and a fire
                              going; the infestation gets rubbish, bones and
                              blood. It turns up as ground is taken (out of
                              sight) and goes when it's lost. Players get a
                              line on the HUD as they cross into either.

      Who holds the city      the share of the city's walkable ground that's
                              Combine, Resistance and infested (F4, or !city),
                              and what it does:
                                unrest  (the Resistance holds a lot)   more
                                        inspections and raids, ration cuts,
                                        a harsher PA, a cheaper black market
                                order   (nothing has spread)           the
                                        rebels go quiet, the black market is
                                        dearer
                                outbreak (an infestation at its limit) it
                                        spills into the streets and the
                                        sector locks down

      Units helping units     !backup sends the nearest NPC units running to
                              you; !10-20 marks where you are for every unit
                              player, and whoever gets there quickly earns XP.

      lc_unrest_share <0-1>    share of the city the Resistance needs for unrest (0.12)
      lc_outbreaks 0/1         an infestation at its limit breaks out (1)
      lc_dressing 0/1          props on taken ground (1)
      lc_city_effects 0/1      who holds the city changes things (1)
]]

if CLIENT then return end

util.AddNetworkString("lc_cpmark")

LC = LC or {}

local FLAGS = bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED)
local cvUnrest   = CreateConVar("lc_unrest_share", "0.12", FLAGS, "Share of the city the Resistance must hold for unrest")
local cvOutbreak = CreateConVar("lc_outbreaks", "1", FLAGS, "An infestation that's spread as far as it can breaks out into the streets")
local cvDressing = CreateConVar("lc_dressing", "1", FLAGS, "Barrels, crates, rubbish and bones on rebel and infested ground")
local cvEffects  = CreateConVar("lc_city_effects", "1", FLAGS, "Who holds the city changes events, rations, prices and the rebels' mood")

local UP = Vector(0, 0, 50)
local function Pick(t) return t[math.random(#t)] end
local function Say(ply, msg) if IsValid(ply) then ply:ChatPrint(msg) else print(msg) end end
local function Radio(band, text) if LC.RadioNotice then LC.RadioNotice(band, text) end end

------------------------------------------------------------------------
-- Dressing taken ground
------------------------------------------------------------------------

local DRESS = {
    rebel = {
        "models/props_c17/oildrum001.mdl", "models/props_junk/wood_crate001a.mdl", "models/props_junk/wood_crate002a.mdl",
        "models/props_junk/wood_pallet001a.mdl", "models/props_junk/cardboard_box001a.mdl", "models/props_junk/plasticcrate01a.mdl",
        "models/props_c17/furnituremattress001a.mdl", "models/props_c17/furnitureshelf001a.mdl", "models/props_c17/furnituredrawer001a.mdl",
        "models/props_c17/furniturecouch002a.mdl",
    },
    infest = {
        "models/props_junk/garbage_bag001a.mdl", "models/props_junk/garbage_newspaper001a.mdl", "models/props_c17/doll01.mdl",
        "models/props_junk/cardboard_box001a.mdl", "models/gibs/hgibs.mdl", "models/props_junk/trashbin01a.mdl",
        "models/props_junk/shoe001a.mdl",
    },
}
-- a table and the chairs round it: somewhere people actually sit
local TABLES = { "models/props_c17/furnituretable001a.mdl", "models/props_c17/furnituretable002a.mdl", "models/props_c17/furnituretable003a.mdl" }
local CHAIRS = { "models/props_c17/furniturechair001a.mdl", "models/props_c17/chair02a.mdl" }
-- small things that lie where they fall rather than stand to attention
local LOOSE = {
    ["models/props_c17/doll01.mdl"] = true, ["models/props_junk/shoe001a.mdl"] = true, ["models/gibs/hgibs.mdl"] = true,
    ["models/props_junk/garbage_newspaper001a.mdl"] = true, ["models/props_junk/garbage_bag001a.mdl"] = true,
}
local SPACING = 70 -- no two pieces closer than this
local PER_KIND_MAX = 60 -- across the whole city, so a map drawn with dozens of zones isn't buried

LC.Dressed = LC.Dressed or {} -- [zone] = { want = n, ents = { ... } }

local function ModelOK(m) return not util.IsValidModel or util.IsValidModel(m) end

-- Solid, level floor under the whole of something this big, not an edge it
-- would hang off (a roof's, a ledge's) or a gap it would sit over.
local DOWN_MASK = MASK_NPCSOLID_BRUSHONLY
local function Footing(pos, radius)
    local r = math.max(8, (radius or 20) * 0.8)
    for i = 0, 8 do
        local a = i * math.pi / 4
        local p = i == 0 and pos or pos + Vector(math.cos(a) * r, math.sin(a) * r, 0)
        local tr = util.TraceLine({ start = p + Vector(0, 0, 24), endpos = p - Vector(0, 0, 90), mask = DOWN_MASK })
        if not tr or not tr.Hit or tr.StartSolid or math.abs(tr.HitPos.z - pos.z) > 20 then return false end
    end
    return true
end
LC.Footing = Footing

-- The floor right under pos, if there is one close below (nil over a drop).
local function FloorUnder(pos)
    local tr = util.TraceLine({ start = pos + Vector(0, 0, 40), endpos = pos - Vector(0, 0, 120), mask = DOWN_MASK })
    if tr and tr.Hit and not tr.StartSolid then return tr.HitPos end
    return nil
end
LC.FloorUnder = FloorUnder

-- Spots on the zone's own ground: at its level (a zone on a roof is dressed on
-- the roof, not the street below it), with floor all round.
local cvWalk = CreateConVar("lc_walkway_clear", "100", bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED),
    "Units of room kept clear to walk past anything the city puts down in a passage (a corridor, a walkway beside a sewer channel): nothing goes where it would leave less")

-- How wide the way is here, wall to wall, at knee height: the narrowest of four
-- cross-measures (along the axes and the diagonals), up to 400.
local function WayWidth(pos)
    local o = pos + Vector(0, 0, 30)
    local function Out(d)
        local tr = util.TraceLine({ start = o, endpos = o + d * 200, mask = MASK_SOLID_BRUSHONLY or MASK_SOLID })
        return (tr and tr.Hit and tr.Fraction) and (tr.Fraction * 200) or 200
    end
    local s = 0.7071
    return math.min(Out(Vector(1, 0, 0)) + Out(Vector(-1, 0, 0)), Out(Vector(0, 1, 0)) + Out(Vector(0, -1, 0)),
        Out(Vector(s, s, 0)) + Out(Vector(-s, -s, 0)), Out(Vector(s, -s, 0)) + Out(Vector(-s, s, 0)))
end
LC.WayWidth = WayWidth
-- In a passage: something this big here would leave less than lc_walkway_clear to get by.
function LC.InWalkway(pos, radius)
    return WayWidth(pos) - 2 * (radius or 0) < cvWalk:GetFloat()
end
-- Standing in water (or sewage): the channel, not the walkway beside it.
function LC.InWater(pos)
    local c = util.PointContents and util.PointContents(pos + Vector(0, 0, 6)) or 0
    return bit.band(c or 0, bit.bor(CONTENTS_WATER or 32, CONTENTS_SLIME or 16)) ~= 0
end

local function DressSpots(z, n)
    local spots, wet = {}, {}
    -- (grown ground: on its cells, each at its own floor, not the circle round where it last grew to)
    local function Take(p)
        local g = p and FloorUnder(p)
        if not g then return end
        local fz = LCZ.FloorAt(z, g)
        if math.abs(g.z - fz) < 120 and LCZ.Within(z, g, 0.95) and Footing(g, 30) then
            -- (down in a channel or a ditch below the zone's floor: only if there's nowhere dry)
            if LC.InWater(g) or g.z < fz - 14 then wet[#wet + 1] = g else spots[#spots + 1] = g end
        end
    end
    if LC.QB and LC.QB.HideSpots then
        if z.cells then
            -- cover spots round a few of its cells
            for _ = 1, 2 do
                for _, p in ipairs(LC.QB.HideSpots(LCZ.RandomInside(z, 0.5), n, LCZ.CELL * 1.5, true)) do Take(p) end
            end
        else
            for _, p in ipairs(LC.QB.HideSpots(z.pos, n * 3, z.r * 0.85, true)) do Take(p) end
        end
    end
    -- not enough of those: anywhere on the zone's floor
    for _ = 1, 30 do
        if #spots >= n * 2 then break end
        Take(LCZ.RandomInside(z, 0.85) + Vector(0, 0, 8))
    end
    for _, g in ipairs(wet) do spots[#spots + 1] = g end
    return spots
end
LC.ZoneFloorSpots = DressSpots

-- Room here for something this big: no other dressing, prop or door in the way, and no wall.
local function Clear(pos, radius)
    local g = FloorUnder(pos)
    if not g or math.abs(g.z - pos.z) > 48 or not Footing(g, radius) then return false end -- (nothing to stand on, or off the edge)
    if LC.InWater(g) then return false end -- (not in the water)
    if LC.InWalkway(g, math.min(radius, 40)) then return false end -- (not where it'd block the way through; a table's chairs can be stepped round)
    for _, d in pairs(LC.Dressed) do
        for _, e in ipairs(d.ents) do
            if IsValid(e) and e:GetPos():DistToSqr(pos) < math.max(SPACING, radius * 1.5) ^ 2 then return false end
        end
    end
    for _, e in ipairs(ents.FindInSphere(pos, radius + 20)) do
        if IsValid(e) and (e:GetClass() == "prop_physics" or e:GetClass() == "prop_dynamic" or e.lcDressing or e.lcRebelProp or e.lcFixture) then return false end
    end
    if LC.NearDoor and LC.NearDoor(pos, 90) then return false end
    local up = pos + Vector(0, 0, radius * 0.5 + 6)
    local tr = util.TraceHull({ start = up, endpos = up + Vector(0, 0, 1), mins = Vector(-radius * 0.6, -radius * 0.6, -radius * 0.4),
        maxs = Vector(radius * 0.6, radius * 0.6, radius * 0.4), mask = MASK_SOLID_BRUSHONLY or MASK_SOLID })
    return not (tr.Hit or tr.StartSolid)
end
LC.DressingClear = Clear

local function Prop(model, pos, yaw)
    local e = ents.Create("prop_physics")
    if not IsValid(e) then return nil end
    e:SetModel(model)
    local ground = LC.GroundAt and LC.GroundAt(pos) or pos
    local loose = LOOSE[model]
    local lift = e.OBBMins and -e:OBBMins().z or 0
    if loose then
        -- dropped from a little above, on its side: physics lays it down, then it stays put
        e:SetPos(ground + Vector(0, 0, 10))
        e:SetAngles(Angle(math.random(70, 90), yaw or math.random(0, 359), math.random(-30, 30)))
    else
        e:SetPos(ground + Vector(0, 0, math.max(0, lift) + 1))
        e:SetAngles(Angle(0, yaw or math.random(0, 359), 0))
    end
    e:Spawn()
    local phys = e.GetPhysicsObject and e:GetPhysicsObject()
    if IsValid(phys) then
        if loose then
            phys:Wake()
            timer.Simple(4, function() if IsValid(e) and IsValid(phys) then phys:EnableMotion(false) end end)
        else
            phys:EnableMotion(false)
        end
    end
    e.lcDressing = true
    return e
end

local function Radius(model)
    if string.find(model, "couch", 1, true) or string.find(model, "mattress", 1, true) then return 60 end
    if string.find(model, "table", 1, true) or string.find(model, "shelf", 1, true) or string.find(model, "pallet", 1, true) then return 45 end
    if LOOSE[model] then return 14 end
    return 30
end

-- a table with a couple of chairs pulled up to it
local function TableSet(p, d)
    local tm = Pick(TABLES)
    if not ModelOK(tm) or not Clear(p, 80) then return false end
    local t = Prop(tm, p)
    if not IsValid(t) then return false end
    d.ents[#d.ents + 1] = t
    local yaw = math.random(0, 359)
    for k = 1, math.random(1, 3) do
        local a = math.rad(yaw + k * (360 / 3))
        local cp = p + Vector(math.cos(a) * 46, math.sin(a) * 46, 0)
        local cm = Pick(CHAIRS)
        local cg = FloorUnder(cp)
        if ModelOK(cm) and cg and math.abs(cg.z - p.z) < 24 and Footing(cg, 18) then
            -- facing the table
            local c = Prop(cm, cp, math.deg(math.atan2(p.y - cp.y, p.x - cp.x)) + 180)
            if IsValid(c) then d.ents[#d.ents + 1] = c end
        end
    end
    return true
end

local function KindCount(kind)
    local n = 0
    for z, d in pairs(LC.Dressed) do if z.kind == kind then n = n + #d.ents end end
    return n
end

local function Dress(z, d)
    local spots = DressSpots(z, d.want - #d.ents)
    -- (one fire and one table for a territory, in its biggest zone)
    if z.kind == "rebel" and LC.RebelIsLeader and not LC.RebelIsLeader(z) then d.fire, d.table = d.fire or true, true end
    for _, p in ipairs(spots) do
        if #d.ents >= d.want or KindCount(z.kind) >= PER_KIND_MAX then break end
        if not LC.IsSeen(p + Vector(0, 0, 30)) then -- nobody sees it appear
            local e
            if z.kind == "rebel" and not d.fire then
                if Clear(p, 40) then
                    e = ents.Create("lc_fire")
                    if IsValid(e) then
                        e:SetPos((LC.GroundAt and LC.GroundAt(p) or p) + Vector(0, 0, 2))
                        e:Spawn()
                        e.lcDressing = true
                        d.fire = e
                    end
                end
            elseif z.kind == "rebel" and not d.table and TableSet(p, d) then
                d.table = true
            else
                local m = Pick(DRESS[z.kind])
                if ModelOK(m) and Clear(p, Radius(m)) then e = Prop(m, p) end
            end
            if IsValid(e) then
                d.ents[#d.ents + 1] = e
                if z.kind == "infest" and util.Decal then
                    -- and the stains to go with it
                    local g = LC.GroundAt and LC.GroundAt(p) or p
                    pcall(util.Decal, "Blood", g + Vector(math.Rand(-30, 30), math.Rand(-30, 30), 10), g - Vector(0, 0, 20))
                end
            end
        end
    end
end

local function DressingTick()
    local live = {}
    if LC.Running and cvDressing:GetBool() then
        for _, z in ipairs(LC.Zones) do
            if z.kind == "rebel" or z.kind == "infest" then
                live[z] = true
                local d = LC.Dressed[z]
                if not d then
                    -- a zone mostly inside a bigger one of its kind (maps drawn with many
                    -- overlapping circles) adds a piece or two, not a whole set
                    -- (grown ground is never one of those circles, and is never inside one: it only takes ground nobody holds)
                    local inside = false
                    for _, o in ipairs(LC.Zones) do
                        if z.cells then break end
                        if o ~= z and not o.cells and o.kind == z.kind and o.r >= z.r and z.pos:DistToSqr(o.pos) < (o.r * 0.9) ^ 2 then inside = true break end
                    end
                    -- (and the other zones of one rebel territory are more of the same camp: a few
                    -- more beds, not a second camp: LC.RebelTerritories, sv_livingcity_paths.lua)
                    local part = z.kind == "rebel" and LC.RebelIsLeader and not LC.RebelIsLeader(z)
                    d = { want = inside and 1 or part and math.Clamp(1 + math.floor(z.r / 400), 1, 3) or math.Clamp(3 + math.floor(z.r / 250), 3, 8), ents = {} }
                    LC.Dressed[z] = d
                    -- a camp the players have arranged (sv_livingcity_campmove.lua): put back just as they left it
                    local keep = z.kind == "rebel" and LC.CampSaved and LC.CampSaved(z)
                    if keep then
                        local n = 0
                        for _, it in ipairs(keep) do
                            if not it.prop then
                                n = n + 1
                                local pos = Vector(it.x, it.y, it.z)
                                local e
                                if it.cls == "lc_fire" then
                                    e = ents.Create("lc_fire")
                                    if IsValid(e) then e:SetPos(pos) e:Spawn() e.lcDressing = true d.fire = e end
                                elseif it.model and ModelOK(it.model) then
                                    e = Prop(it.model, pos, it.yaw)
                                end
                                if IsValid(e) then d.ents[#d.ents + 1] = e end
                            end
                        end
                        d.want, d.table = n, true
                    end
                end
                for i = #d.ents, 1, -1 do if not IsValid(d.ents[i]) then table.remove(d.ents, i) end end
                if d.fire ~= true and not IsValid(d.fire) then d.fire = nil end
                if #d.ents < d.want and CurTime() > (d.nextTry or 0) then
                    d.nextTry = CurTime() + 20
                    Dress(z, d)
                end
            end
        end
    end
    -- ground that was lost: cleared away once nobody's looking (or after two minutes regardless)
    for z, d in pairs(LC.Dressed) do
        if not live[z] then
            d.lostAt = d.lostAt or CurTime()
            for i = #d.ents, 1, -1 do
                local e = d.ents[i]
                if not IsValid(e) then
                    table.remove(d.ents, i)
                elseif not LC.IsSeen(e:GetPos() + Vector(0, 0, 30)) or CurTime() - d.lostAt > 120 then
                    e:Remove()
                    table.remove(d.ents, i)
                end
            end
            if #d.ents == 0 then LC.Dressed[z] = nil end
        else
            d.lostAt = nil
        end
    end
end
LC.DressingTick = DressingTick

timer.Create("LivingCityDressing", 5, 0, function()
    local ok, err = pcall(DressingTick)
    if not ok then LC.Error("dressing", err) end
end)

hook.Add("PlayerUse", "LivingCityDressing", function(ply, ent)
    if ent.lcDressing and ent:GetClass() == "prop_physics" then return false end -- set dressing, not loot
end)

hook.Add("LivingCityStopped", "LivingCityDressing", function()
    for _, d in pairs(LC.Dressed) do
        for _, e in ipairs(d.ents) do if IsValid(e) then e:Remove() end end
    end
    LC.Dressed = {}
end)

------------------------------------------------------------------------
-- Who holds the city
------------------------------------------------------------------------

LC.Control = LC.Control or { rebel = 0, infest = 0, combine = 1 }
LC.CityStateName = LC.CityStateName or "normal"

local function InKind(pos, kind)
    for _, z in ipairs(LC.Zones) do
        if z.kind == kind and LCZ.Contains(z, pos) then return true end
    end
    return false
end

-- Shares of the city's walkable ground (the map's own navigation spots).
function LC.ComputeControl()
    local spots = LC.Fallback or {}
    local n = #spots
    local rebel, infest, counted = 0, 0, 0
    if n > 0 then
        local step = math.max(1, math.floor(n / 600))
        for i = 1, n, step do
            local p = spots[i]
            counted = counted + 1
            if InKind(p, "infest") then infest = infest + 1 elseif InKind(p, "rebel") then rebel = rebel + 1 end
        end
    end
    local c = LC.Control
    if counted == 0 then
        -- no navigation to sample: judge by how much has spread
        c.rebel = math.min(0.5, (LC.GrownCount and LC.GrownCount("rebel") or 0) * 0.04)
        c.infest = math.min(0.5, (LC.GrownCount and LC.GrownCount("infest") or 0) * 0.04)
    else
        c.rebel, c.infest = rebel / counted, infest / counted
    end
    c.combine = math.max(0, 1 - c.rebel - c.infest)
    SetGlobal2Float("lc_ctl_rebel", c.rebel)
    SetGlobal2Float("lc_ctl_infest", c.infest)
    return c
end

function LC.CityState() return LC.CityStateName end

local STATE_TEXT = {
    unrest = "The Resistance holds a real share of the city. Expect more inspections and raids, ration cuts and a harsher PA. The black market is cheaper while it lasts.",
    order = "The Combine holds the whole city. The rebels have gone quiet, and the black market has put its prices up.",
    normal = "Nobody holds the upper hand. The city goes about its business.",
}
local STATE_TITLE = { unrest = "Civil unrest", order = "Full compliance", normal = "Contested" }
LC.CityStateText, LC.CityStateTitle = STATE_TEXT, STATE_TITLE

local function SetState(name)
    if LC.CityStateName == name then return end
    LC.CityStateName = name
    SetGlobal2String("lc_city_state", name)
    for _, p in ipairs(player.GetAll()) do
        p:ChatPrint("[City] " .. STATE_TITLE[name] .. ". " .. STATE_TEXT[name])
    end
    LC.Log("info", "City state: " .. name)
    hook.Run("LivingCityStateChanged", name)
end

function LC.RefreshCityState()
    local c = LC.ComputeControl()
    if not cvEffects:GetBool() then return SetState("normal") end
    local grownRebel = LC.GrownCount and LC.GrownCount("rebel") or 0
    local grownInfest = LC.GrownCount and LC.GrownCount("infest") or 0
    if c.rebel >= cvUnrest:GetFloat() or grownRebel >= 4 then
        SetState("unrest")
    elseif grownRebel == 0 and grownInfest == 0 and #(LC.ZonesOfKind and (LC.ZonesOfKind("rebel")) or {}) + #(LC.ZonesOfKind and LC.ZonesOfKind("infest") or {}) > 0 then
        SetState("order")
    else
        SetState("normal")
    end
end

-- What the state does, for the other modules to ask.
function LC.EventWeightMul(name)
    local s = LC.CityStateName
    if s == "unrest" then return (name == "sweep" and 2.5) or (name == "raid" and 1.8) or (name == "lockdown" and 1.5) or 1 end
    return 1
end
function LC.RationIntervalMul() return LC.CityStateName == "unrest" and 1.5 or 1 end
function LC.BlackPriceMul()
    local s = LC.CityStateName
    return (s == "order" and 1.25) or (s == "unrest" and 0.85) or 1
end
function LC.SkirmishIntervalMul() return LC.CityStateName == "order" and 2 or 1 end

------------------------------------------------------------------------
-- Outbreaks
------------------------------------------------------------------------

local lastOutbreak = -1e9

function LC.Outbreak(seed)
    if not LC.Running or not LC.SpawnZombie then return false end
    lastOutbreak = CurTime()
    local family = LC.TerritoryFamily and LC.TerritoryFamily(seed) or { seed }
    local made = 0
    for _ = 1, 30 do
        if made >= 6 then break end
        local from = Pick(family)
        -- just outside the edge, on the street
        local p = LC.RandomWanderPos("citizen", from.pos)
        if not p or p:Distance(from.pos) > from.r + 700 then
            local a = math.random() * math.pi * 2
            local probe = from.pos + Vector(math.cos(a), math.sin(a), 0) * (from.r + math.random(100, 400))
            local tr = util.TraceLine({ start = from.pos + Vector(0, 0, 40), endpos = probe + Vector(0, 0, 40), mask = MASK_NPCSOLID_BRUSHONLY })
            p = (tr and not tr.Hit) and FloorUnder(probe + Vector(0, 0, 8)) or nil -- (and not in mid-air off a ledge)
        end
        if p and p:Distance(from.pos) < from.r + 700 and not LC.IsSeen(p + UP) then
            local npc, st = LC.SpawnZombie(p + Vector(0, 0, 4), nil)
            if st then
                st.unmanaged = true
                st.surgeExpires = CurTime() + 600
                made = made + 1
            end
        end
    end
    if LC.Announce then
        LC.Announce("response", "npc/overwatch/cityvoice/f_unrestprocedure1_spkr.wav",
            "The infestation " .. (LC.DescribePlace and LC.DescribePlace(seed.pos) or "") ..
            " has broken out into the streets. Infected are loose nearby. Get indoors, or get armed.")
    end
    Radio("cp", "Dispatch: quarantine breach. All Civil Protection units, contain the infected.")
    if LC.StartEvent and not LC.Event then LC.StartEvent("lockdown", 3) end
    LC.Log("info", "Outbreak from " .. tostring(seed.pos) .. ": " .. made .. " infected loose")
    hook.Run("LivingCityOutbreak", seed, made)
    return made > 0
end

local function OutbreakCheck()
    if not cvOutbreak:GetBool() or CurTime() - lastOutbreak < 1800 then return end
    for _, seed in ipairs(LC.TerritorySeeds and LC.TerritorySeeds("infest") or {}) do
        if LC.TerritoryCanGrow and not LC.TerritoryCanGrow(seed) then
            LC.Outbreak(seed)
            return
        end
    end
end

timer.Create("LivingCityCityState", 20, 0, function()
    local ok, err = pcall(function()
        if not LC.Running then return end
        LC.RefreshCityState()
        OutbreakCheck()
    end)
    if not ok then LC.Error("city state", err) end
end)

local function CityReport(ply)
    local c = LC.ComputeControl()
    Say(ply, string.format("[City] Combine %d%%, Resistance %d%%, infested %d%%. %s.", math.floor(c.combine * 100 + 0.5),
        math.floor(c.rebel * 100 + 0.5), math.floor(c.infest * 100 + 0.5), STATE_TITLE[LC.CityStateName] or "Contested"))
    Say(ply, "  > " .. (STATE_TEXT[LC.CityStateName] or ""))
end

------------------------------------------------------------------------
-- Backup and 10-20s
------------------------------------------------------------------------

LC.CPMarks = LC.CPMarks or {} -- [ply] = { pos, at, untilT, credited = {} }

local function IsUnitPlayer(p) return IsValid(p) and p:IsPlayer() and LC.PlayerIsCP(p) end
local function Callsign(p)
    local t = p:GetNW2String("lcf_title", "")
    return t ~= "" and t or p:Nick()
end

function LC.Mark1020(ply, quiet)
    if not IsUnitPlayer(ply) then return false, "Only Civil Protection units can call a 10-20." end
    if LC.Jammed and LC.Jammed(ply:GetPos()) then return false, "Static. Your radio can't get through: there's a jammer nearby." end
    local now = CurTime()
    local m = { pos = ply:GetPos(), at = now, untilT = now + 90, credited = {}, name = Callsign(ply) }
    LC.CPMarks[ply] = m
    local where = LC.DescribePlace and LC.DescribePlace(m.pos) or ""
    local units = {}
    for _, p in ipairs(player.GetAll()) do
        if IsUnitPlayer(p) then units[#units + 1] = p end
    end
    LC.SendCompressed("lc_cpmark", { name = m.name, x = m.pos.x, y = m.pos.y, z = m.pos.z, secs = 90 }, units)
    if not quiet then
        for _, p in ipairs(units) do
            if p ~= ply then p:ChatPrint("[CP net] 10-20: " .. m.name .. " is " .. where .. ". Respond for XP; the faster, the more.") end
        end
        ply:ChatPrint("[CP net] Your 10-20 is out to every Civil Protection unit for 90 seconds.")
    end
    return true
end

-- How long backup stays in the caller's squad (the owner, 7 November: "if I call for backup, the backup should join my squad").
local BACKUP_SECS = 300

-- The units in this player's squad right now (backup that answered their call).
function LC.BackupSquad(ply)
    local out = {}
    for npc, st in pairs(LC.NPCs or {}) do
        if IsValid(npc) and st.backupFor == ply and npc:Health() > 0 then out[#out + 1] = npc end
    end
    return out
end

-- The squad fights what its caller fights: a unit's target, or whoever hurts the unit.
local function SquadOnto(ply, target, now)
    if not IsValid(target) or target == ply then return end
    if target:IsPlayer() and (LC.PlayerIsCP(target) or not (LC.PlayerIsWanted and LC.PlayerIsWanted(target)) and not (LC.Violent and LC.Violent(target))) then return end
    if not target:IsPlayer() then
        local tst = LC.NPCs and LC.NPCs[target]
        if tst and (tst.role == "cop" or tst.role == "soldier" or tst.role == "citizen") then return end
    end
    for _, npc in ipairs(LC.BackupSquad(ply)) do
        local st = LC.NPCs[npc]
        if st.state ~= "hostile" and LC.MakeOneHostile then
            LC.MakeOneHostile(npc, st, target)
            st.provokedBy, st.provokedUntil = target, now + 60
        end
    end
end
hook.Add("EntityTakeDamage", "LivingCityBackupSquad", function(victim, dmg)
    local a = dmg:GetAttacker()
    if not IsValid(a) or not IsValid(victim) or dmg:GetDamage() <= 0 then return end
    local now = CurTime()
    if a:IsPlayer() and IsUnitPlayer(a) and (victim:IsPlayer() or victim:IsNPC()) then SquadOnto(a, victim, now) end
    if victim:IsPlayer() and IsUnitPlayer(victim) and a ~= victim and (a:IsPlayer() or a:IsNPC()) then SquadOnto(victim, a, now) end
end)

-- Backup comes from close by (the owner, 11 November: it "arrived 3 minutes later (WAY too late, make them
-- spawn NEARBY)"). A unit answering from further off than BACKUP_WALK that nobody is looking at starts
-- its walk from a spot out of sight between BACKUP_MIN and BACKUP_MAX of the caller, on about their level.
local BACKUP_WALK, BACKUP_MIN, BACKUP_MAX = 1400, 450, 1300
function LC.BackupSpot(ply)
    if not LC.RandomWanderPos then return nil end
    local at = ply:GetPos()
    for _ = 1, 40 do
        local p = LC.RandomWanderPos("cop", at) or LC.RandomWanderPos("cop")
        if p then
            local d = p:DistToSqr(at)
            if d > BACKUP_MIN * BACKUP_MIN and d < BACKUP_MAX * BACKUP_MAX and math.abs(p.z - at.z) < 220
                and not (LC.IsSeen and LC.IsSeen(p + Vector(0, 0, 50))) and (not LC.ClearSpot or LC.ClearSpot(p))
                and not (LC.InRebelZone and LC.InRebelZone(p))
                and (not LC.NavReachable or LC.NavReachable(p, at)) then return p end
        end
    end
    return nil
end
function LC.BackupBringNear(npc, ply)
    if npc:GetPos():DistToSqr(ply:GetPos()) < BACKUP_WALK * BACKUP_WALK then return false end
    if LC.IsSeen and LC.IsSeen(npc:GetPos() + Vector(0, 0, 50)) then return false end -- (watched: it walks)
    local p = LC.BackupSpot(ply)
    if not p then return false end
    npc:SetPos(p + Vector(0, 0, 4))
    return true
end

function LC.CallBackup(ply)
    if not IsUnitPlayer(ply) then return false, "Only Civil Protection units can call for backup." end
    if LC.Jammed and LC.Jammed(ply:GetPos()) then return false, "Static. Your radio can't get through: there's a jammer nearby." end
    local now = CurTime()
    if (ply.lcBackupNext or 0) > now then
        return false, string.format("Dispatch already has your last call. Again in %ds.", math.ceil(ply.lcBackupNext - now))
    end
    -- (the owner, 9 November: squads shrink as more players join the side, sv_livingcity_squads.lua)
    local room = LC.SquadRoom and LC.SquadRoom(ply) or 3
    if room <= 0 then return false, LC.SquadFullText and LC.SquadFullText(ply) or "Your squad is full." end
    local commander = ply:GetNW2String("lcf_special", "") == "ow_commander"
    ply.lcBackupNext = now + 45
    local near = {}
    for npc, st in pairs(LC.NPCs or {}) do
        if IsValid(npc) and LC.IsSecurity(st) and not st.questLock and not st.raid and not st.skirmish and not st.questSquad
            and st.state ~= "hostile" and st.state ~= "escort" and st.state ~= "event" and not st.workEscort
            and not IsValid(st.backupFor) and (not st.elite or commander) then -- (Elites answer only to the Overwatch Commander)
            local d = npc:GetPos():DistToSqr(ply:GetPos())
            if d < 5000 * 5000 then near[#near + 1] = { npc = npc, st = st, d = d } end
        end
    end
    table.sort(near, function(a, b) return a.d < b.d end)
    local sent = 0
    -- (the owner, 7 November: backup came WITH STUNSTICKS to a gunfight) gun out, shot at in the last
    -- 30 seconds, or on a violent job: they come with pistols and SMGs, and keep them out (sv_livingcity_fieldops.lua)
    local violent = LC.BackupViolent ~= nil and LC.BackupViolent(ply)
    for i = 1, math.min(room, #near) do
        local u = near[i]
        if LC.AbandonTask then LC.AbandonTask(u.npc, u.st, now) end
        if LC.ArmBackupUnit then LC.ArmBackupUnit(u.npc, u.st, violent, i) elseif LC.ArmUnit then LC.ArmUnit(u.npc, u.st) end
        -- (the owner, 7 November: backup joins your squad) with you for five minutes, one engine squad
        -- between them so Half-Life 2's own squad tactics work
        u.st.backupFor, u.st.backupUntil, u.st.backupJoined = ply, now + BACKUP_SECS, nil
        if u.npc.SetSquad then u.npc:SetSquad("lcbk" .. ply:EntIndex()) end
        LC.BackupBringNear(u.npc, ply)
        if LC.GoTo(u.npc, u.st, ply:GetPos(), true, nil) then sent = sent + 1 end
    end
    LC.Mark1020(ply, true)
    local where = LC.DescribePlace and LC.DescribePlace(ply:GetPos()) or ""
    for _, p in ipairs(player.GetAll()) do
        if IsUnitPlayer(p) and p ~= ply then p:ChatPrint("[CP net] " .. Callsign(ply) .. " requests backup " .. where .. ". Respond for XP.") end
    end
    ply:ChatPrint(sent > 0 and string.format("[Dispatch] %d unit%s en route to you. They join your squad when they reach you: with you, and on whatever you fight, for %d minutes.%s", sent, sent == 1 and "" or "s", math.floor(BACKUP_SECS / 60),
            violent and " Weapons free: they're coming with pistols and SMGs." or "")
        or "[Dispatch] No Civil Protection units free nearby. Your 10-20 is out to every unit.")
    if sent > 0 then ply:EmitSound("npc/metropolice/vo/copy.wav", 60) end
    return true, sent
end

local function Sees(npc, e, range)
    if npc:GetPos():DistToSqr(e:GetPos()) > range * range then return false end
    return LC.LineOfSight(npc:EyePos(), e:EyePos(), npc, e)
end

local function BackupTick(now)
    for npc, st in pairs(LC.NPCs or {}) do
        local caller = st.backupFor
        if IsValid(npc) and caller ~= nil then
            if not IsValid(caller) or not caller:Alive() or now > (st.backupUntil or 0) then
                st.backupFor, st.backupUntil = nil, nil
            elseif st.state ~= "hostile" then
                -- there: deal with whatever's going on
                local threat
                for _, p in ipairs(player.GetAll()) do
                    if p ~= caller and p:Alive() and LC.PlayerIsWanted and LC.PlayerIsWanted(p) and Sees(npc, p, 1000) then threat = p break end
                end
                if not threat then
                    for other, ost in pairs(LC.NPCs) do
                        if IsValid(other) and ost.role == "rebel" and other:Health() > 0 and Sees(npc, other, 1200) then threat = other break end
                    end
                end
                if threat then
                    LC.MakeOneHostile(npc, st, threat)
                    st.provokedBy, st.provokedUntil = threat, now + 60
                elseif npc:GetPos():DistToSqr(caller:GetPos()) > 350 * 350 and now > (st.backupMove or 0) then
                    st.backupMove = now + 3
                    LC.GoTo(npc, st, caller:GetPos() + Vector(math.random(-90, 90), math.random(-90, 90), 0), true, nil)
                elseif not st.backupJoined and npc:GetPos():DistToSqr(caller:GetPos()) < 350 * 350 then
                    -- there: in the squad, and the caller hears so
                    st.backupJoined = true
                    local who = LC.NPCStr(npc, "lc_pname", "")
                    caller:ChatPrint("[CP net] " .. (who ~= "" and ("Unit " .. who) or "A unit") .. " is with you: in your squad. They follow you and fight what you fight.")
                    npc:EmitSound(st.role == "soldier" and "npc/combine_soldier/vo/affirmative.wav" or "npc/metropolice/vo/affirmative.wav", 70)
                    if LC.Notice and (caller.lcBackupNoticeAt or 0) < now - 20 then
                        caller.lcBackupNoticeAt = now
                        LC.Notice(caller, "info", "Backup with you", "The units who answered are in your squad for a few minutes: they keep with you and turn on whatever you fight, or whoever hurts you.", 7)
                    end
                end
            end
        end
    end
    -- responders to a 10-20
    for owner, m in pairs(LC.CPMarks) do
        if not IsValid(owner) or now > m.untilT then
            LC.CPMarks[owner] = nil
        else
            for _, p in ipairs(player.GetAll()) do
                if p ~= owner and IsUnitPlayer(p) and p:Alive() and not m.credited[p] and p:GetPos():DistToSqr(m.pos) < 300 * 300 then
                    m.credited[p] = true
                    local secs = now - m.at
                    local xp = math.max(3, 20 - math.floor(secs / 5))
                    if LC.AddXP then LC.AddXP(p, xp, "responded to a 10-20") end
                    p:ChatPrint(string.format("[CP net] On scene in %ds. +%d XP.", math.floor(secs), xp))
                    if IsValid(owner) then owner:ChatPrint("[CP net] " .. Callsign(p) .. " is on scene.") end
                end
            end
        end
    end
end

timer.Create("LivingCityBackup", 1, 0, function()
    local ok, err = pcall(BackupTick, CurTime())
    if not ok then LC.Error("backup", err) end
end)

------------------------------------------------------------------------
-- Chat
------------------------------------------------------------------------

hook.Add("PlayerSay", "LivingCityWarChat", function(ply, text)
    local t = string.lower(string.Trim(text))
    if t == "!city" or t == "!control" then CityReport(ply) return "" end
    if t == "!backup" then
        local ok, why = LC.CallBackup(ply)
        if not ok and why then ply:ChatPrint("[Dispatch] " .. why) end
        return ""
    end
    if t == "!10-20" or t == "!1020" or t == "!mark" then
        local ok, why = LC.Mark1020(ply)
        if not ok and why then ply:ChatPrint("[CP net] " .. why) end
        return ""
    end
end)

concommand.Add("lc_backup_call", function(ply) if IsValid(ply) then local ok, why = LC.CallBackup(ply) if not ok and why then ply:ChatPrint("[Dispatch] " .. why) end end end)
concommand.Add("lc_1020", function(ply) if IsValid(ply) then local ok, why = LC.Mark1020(ply) if not ok and why then ply:ChatPrint("[CP net] " .. why) end end end)
concommand.Add("lc_city", function(ply) CityReport(ply) end)
concommand.Add("lc_outbreak", function(ply)
    if IsValid(ply) and not ply:IsAdmin() then return end
    local seed = LC.TerritorySeeds and LC.TerritorySeeds("infest")[1]
    if not seed then return Say(ply, "[Living City] No infestation zones placed.") end
    Say(ply, LC.Outbreak(seed) and "[Living City] Outbreak started." or "[Living City] Nowhere for them to break out to.")
end)

------------------------------------------------------------------------
-- Talk on the street
--
-- What's happened in the city lately, as people heard it. Press E on a
-- citizen and now and then they'll pass something on. Units mostly get
-- nervous silence.
------------------------------------------------------------------------

LC.Rumors = LC.Rumors or {}
local RUMOR_LIFE = 1800
local RUMOR_MAX = 14

local function Where(pos)
    local w = LC.DescribePlace and LC.DescribePlace(pos) or ""
    if string.find(w, " of you", 1, true) or w == "" then return "over that way" end
    return w
end

function LC.AddRumor(lines, pos, tag)
    if type(lines) == "string" then lines = { lines } end
    table.insert(LC.Rumors, 1, { lines = lines, at = CurTime(), pos = pos, tag = tag })
    while #LC.Rumors > RUMOR_MAX do table.remove(LC.Rumors) end
end

local function FreshRumor(ply)
    local now = CurTime()
    ply.lcHeard = ply.lcHeard or setmetatable({}, { __mode = "k" })
    local best
    for _, r in ipairs(LC.Rumors) do
        if now - r.at < RUMOR_LIFE and not ply.lcHeard[r] then best = r break end -- newest first
    end
    if not best then return nil end
    ply.lcHeard[best] = true
    return best
end

LC.TakeRumor = function(ply) local r = FreshRumor(ply) return r and Pick(r.lines) or nil end

local NERVOUS = {
    "'I didn't see anything, officer.'", "'Nothing to report. Nothing at all.'", "'I keep my head down. Like we're told.'",
}

hook.Add("LivingCityPlayerUsedNPC", "LivingCityRumors", function(ply, npc, st)
    if not st or st.role ~= "citizen" or st.test or st.questLock then return end
    if st.state ~= "idle" and st.state ~= "moving" and st.state ~= "inline" then return end
    local now = CurTime()
    if (ply.lcRumorNext or 0) > now then return end
    local name = LC.NPCStr(npc, "lc_pname", "")
    local who = name ~= "" and name or "A citizen"
    if LC.PlayerIsCP(ply) then
        if math.random() < 0.3 then
            ply.lcRumorNext = now + 20
            ply:ChatPrint("[" .. who .. "] " .. Pick(NERVOUS))
        end
        return
    end
    -- everyone else hears the city's rumours in the talk window (sv_livingcity_talk.lua)
end)

hook.Add("LivingCityTerritoryGrew", "LivingCityRumors", function(seed, z)
    local w = Where(z.pos)
    if z.kind == "rebel" then
        LC.AddRumor({ "They say the Resistance has taken the streets " .. w .. ". Civil Protection won't go in.",
            "Someone told me the rebels are holding ground " .. w .. " now. Just walked in and took it." }, z.pos, "rebel_grew")
    else
        LC.AddRumor({ "Stay away from " .. w .. ". The infected are spreading. I heard them last night.",
            "My neighbour went " .. w .. " for scrap. Didn't come back. They say it's crawling with them now." }, z.pos, "infest_grew")
    end
end)

hook.Add("LivingCityTerritoryReceded", "LivingCityRumors", function(seed, z, why)
    local w = Where(z.pos)
    if z.kind == "rebel" then
        LC.AddRumor({ "The Combine cleared the rebels out " .. w .. ". There was a lot of shooting.",
            "I heard Civil Protection took back the ground " .. w .. ". Nobody's saying what happened to the people there." }, z.pos)
    else
        LC.AddRumor({ "Civil Protection burned out the infected " .. w .. ". You can still smell it.",
            "They say it's safe " .. w .. " again. I wouldn't bet on it." }, z.pos)
    end
end)

-- (a raid is talked about once the shooting has started, not when the fighters set out)
hook.Add("LivingCityRaidArrived", "LivingCityRumors", function(sk)
    LC.AddRumor({ "Did you hear the shooting? Rebels hit the Combine " .. (sk.where or "across town") .. ".",
        "The Resistance went after the Combine " .. (sk.where or "") .. ". Brave, or stupid." }, sk.target)
end)
hook.Add("LivingCitySkirmish", "LivingCityRumors", function(kind, sk)
    if kind == "raid" then
        return
    else
        LC.AddRumor({ "The Combine sent a team into rebel ground " .. Where(sk.zone.pos) .. ". Armed.",
            "Civil Protection went into the rebel streets " .. Where(sk.zone.pos) .. " with guns drawn." }, sk.zone.pos)
    end
end)

hook.Add("LivingCityOutbreak", "LivingCityRumors", function(seed)
    LC.AddRumor({ "The infected broke out " .. Where(seed.pos) .. ". People didn't make it.",
        "They had to lock everything down. The things came out of " .. Where(seed.pos) .. "." }, seed.pos)
end)

hook.Add("LivingCityBlockRaided", "LivingCityRumors", function(block, found)
    local name = LC.BlockName and LC.BlockName(block) or "a block"
    LC.AddRumor({ "They tore " .. name .. " apart looking for contraband. Took people, too.",
        "Did you hear about " .. name .. "? Doors kicked in, the lot." })
end)

hook.Add("LivingCityDealerBusted", "LivingCityRumors", function(cop, dealer)
    if IsValid(dealer) then
        LC.AddRumor({ "The dealer " .. Where(dealer:GetPos()) .. " got raided. Don't go asking for him." }, dealer:GetPos())
    end
end)

hook.Add("LivingCityIncarcerated", "LivingCityRumors", function(target, secs, reason)
    if not IsValid(target) or not target:IsPlayer() then return end
    local name = target:GetNW2String("lc_char", "")
    if name == "" then name = target:Nick() end
    LC.AddRumor({ "They took " .. name .. " away. " .. (reason and reason ~= "" and (reason .. ", they said.") or "Nobody knows why."),
        "Have you seen " .. name .. "? Civil Protection came for them." })
end)

hook.Add("LivingCityPersonKilled", "LivingCityRumors", function(p, attacker)
    if not p or not p.name then return end
    local byUnit = IsValid(attacker) and (attacker:IsPlayer() and LC.PlayerIsCP(attacker) or (LC.NPCs[attacker] and LC.IsSecurity(LC.NPCs[attacker])))
    LC.AddRumor(byUnit and { "They killed " .. p.name .. ". Civil Protection. In the street, in front of everyone." }
        or { p.name .. " is dead. Nobody will say who did it." })
end)

hook.Add("LivingCityStateChanged", "LivingCityRumors", function(name)
    if name == "unrest" then
        LC.AddRumor({ "Everyone's on edge. The Combine are losing the streets, and they know it.",
            "Rations are short again. That's what happens when the rebels are winning." })
    elseif name == "order" then
        LC.AddRumor({ "It's quiet. Too quiet. The Combine have the whole city now.",
            "Haven't heard a shot in days. I don't know if that's good." })
    end
end)
