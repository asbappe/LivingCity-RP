--[[
    Living City: weedkiller against the infestation, and against the Combine (the owner, 2026-11-01)

    Growths in the infestation
      Every infestation (the zones you place, and the patches that grow out of them) has growths in
      it: lumps of Xen growth, nests of glowing grubs, the dead it has taken. They glow a sickly green
      and give off spores, so you can see where the infestation is from the street. Spray one with
      weedkiller (look at it, E) and it shrivels away. Spray every growth in a patch that grew and the
      patch goes: the infestation shrinks. Spray out the zone you placed and nothing grows or spawns
      there for a while. Growths come back, one at a time, every lc_nest_regrow_minutes (6).
      They're Half-Life: Alyx's Xen gunk when the server has the owner's workshop pack (2043900984),
      else built-in Half-Life 2 and Episode 2 models. lc_infest_nest_models: your own (comma separated).
      With that pack, a Combine warning post (sign, lamp, barrel) stands at the edge of each
      infestation (lc_infest_hazard_posts), and the cleanup crew bags up what they spray.

    Infestation Cleanup (a Union job, the 15th)
      Into the infestation in a respirator (it keeps out gas, chlorine and weedkiller alike), with
      weedkiller, to spray the growths. While they're near an infestation on a shift, lc_cleanup_guards
      (2) Overwatch soldiers guard them (one with a shotgun, one with a pulse rifle; never metrocops:
      the owner, 7 November), and shoot the infested that come for them, only what they can see. The
      city's own cleanup crews do it too, with a guard of their own. Each shift a character does is
      longer: 3 growths the first time, then 5, 7, up to 11 (sv_livingcity_work.lua); while a crew is
      at work the infestation pushes out more growths where nobody's looking, so there's always
      something to clear. A cleanup shift counts as lc_cleanup_shift_counts (2) Intake Processor
      shifts towards joining Civil Protection. With the owner's Infestation Control pack (3185145650) on the server, players on
      the job and the city's own crews wear its hazmat suit ("worker"), a man the male one and a woman
      the female one, each their own skin (lc_cleanup_suit; lc_cleanup_model: another model instead);
      and Morticians, Sanitation Workers and the Reclamation Crew wear its "engineer" overalls.

    Barnacles
      A barnacle eats whatever it pulls up. Drop weedkiller (or anything tainted with it) under one:
      it chews, and dies.

    The firebomb (the Resistance lab: two weedkiller, an empty bottle and a rag)
      Armour doesn't keep out fire. Where it breaks it burns for lc_firebomb_secs (12): it sets alight
      anyone in it, units and soldiers included; it burns out power banks, forcefields and turrets
      for 90 seconds; and it burns growths away.

    Poison gas is the Combine's now (sold to units at the Civil Protection Commissary): a mask keeps
    it out. Sweeps into rebel ground open with a gas bomb now and then (lc_sweep_gas, 0.5).
    An Insider can foul the filter stock at the Commissary (sv_livingcity_insider.lua): for
    lc_fouled_minutes (20) every unit's mask lets gas through, theirs and the Resistance's alike.

      lc_infest_nests 0/1 (1), lc_infest_nests_per_patch (4), lc_nest_regrow_minutes (6),
      lc_infest_nest_models (""), lc_infest_hazard_posts (1), lc_cleanup_guards (2), lc_cleanup_shift_counts (2),
      lc_cleanup_model (""), lc_cleanup_suit (worker), lc_firebomb_secs (12), lc_sweep_gas (0.5), lc_fouled_minutes (20)
]]

if CLIENT then return end

LC = LC or {}

local FLAGS = bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED)
local cvNests   = CreateConVar("lc_infest_nests", "1", FLAGS, "Growths in the infestation, glowing, that weedkiller sprays away (and the infestation shrinks)")
local cvPer     = CreateConVar("lc_infest_nests_per_patch", "4", FLAGS, "Growths in each patch of infestation")
local cvRegrow  = CreateConVar("lc_nest_regrow_minutes", "6", FLAGS, "Minutes for a growth to come back in a patch that's lost one")
local cvModels  = CreateConVar("lc_infest_nest_models", "", FLAGS, "Your own models for the growths, comma separated (empty: the built-in ones)")
local cvGuards  = CreateConVar("lc_cleanup_guards", "2", FLAGS, "Overwatch soldiers (a shotgun and a pulse rifle) who guard a cleanup worker near an infestation")
local cvCounts  = CreateConVar("lc_cleanup_shift_counts", "2", FLAGS, "Intake Processor shifts each Infestation Cleanup shift counts as, towards joining Civil Protection")
local cvModel   = CreateConVar("lc_cleanup_model", "", FLAGS, "A player model for Infestation Cleanup workers (a hazmat suit, say; empty: their own)")
local cvFire    = CreateConVar("lc_firebomb_secs", "12", FLAGS, "Seconds a firebomb burns where it breaks")
local cvSweep   = CreateConVar("lc_sweep_gas", "0.5", FLAGS, "Chance a sweep into rebel ground opens with a poison gas bomb (0 to 1)")
local cvFouled  = CreateConVar("lc_fouled_minutes", "20", FLAGS, "Minutes units' mask filters let gas through after an Insider fouls them")

LC.CleanupShiftCounts = function() return math.max(1, cvCounts:GetInt()) end

------------------------------------------------------------------------
-- Fouled filters
------------------------------------------------------------------------

LC.FouledUntil = LC.FouledUntil or 0
function LC.FiltersFouled() return CurTime() < (LC.FouledUntil or 0) end
function LC.FoulFilters(secs)
    LC.FouledUntil = math.max(LC.FouledUntil or 0, CurTime() + (secs or math.max(1, cvFouled:GetFloat()) * 60))
    return LC.FouledUntil
end

------------------------------------------------------------------------
-- The respirator, and the suit
------------------------------------------------------------------------

local function OnCleanup(ply)
    local job = IsValid(ply) and LC.Job and LC.Job(ply)
    return job and job.id == "cleanup" or false
end
LC.OnCleanupJob = OnCleanup
function LC.CleanupRespirator(ply) return IsValid(ply) and ply:IsPlayer() and OnCleanup(ply) end

-- The Infestation Control crew from Half-Life: Alyx (the owner's workshop pack 3185145650), through Job
-- outfits (sv_livingcity_outfits.lua), so the city's own people in these jobs wear them too: a man the
-- male model, a woman the female one, each their own skin. The owner, 2026-11-01: the "worker" suits are
-- the hazmat suits (filter and air tank), for Infestation Cleanup; the "engineer" ones have neither, for
-- the dirty jobs (Mortician, Sanitation Worker, Reclamation Crew). Only while a job has no outfit of its
-- own: set one in the editor (Job outfits) and that's worn instead. Worn only for the work (the owner): a
-- player on a shift, one of the city's people doing the job; going home, their own clothes. lc_cleanup_suit: the cleanup job's
-- suit (worker); lc_cleanup_model: another player model for it instead.
local function Valid(m) return not util.IsValidModel or util.IsValidModel(m) end
local cvSuit = CreateConVar("lc_cleanup_suit", "worker", FLAGS, "Which Infestation Control suit cleanup workers wear, if the server has the pack: worker (the hazmat suit) or engineer")
local DIRTY = { mortuary = "engineer", sanitation = "engineer", scrap = "engineer" }

local function SuitOutfit(suit)
    local pm, npc = "models/player/" .. suit .. "_{sex}.mdl", "models/npc/" .. suit .. "_{sex}.mdl"
    if not Valid((string.gsub(pm, "{sex}", "male"))) then return nil end
    -- every skin it has, each person their own
    local n = 1
    pcall(function()
        local info = util.GetModelInfo and util.GetModelInfo((string.gsub(npc, "{sex}", "male")))
        n = math.max(1, tonumber(info and info.SkinCount) or 1)
    end)
    local skins = {}
    for i = 0, n - 1 do skins[#skins + 1] = i end
    return { pm = pm, npc = npc, skins = skins }
end
function LC.CleanupOutfit()
    local own = cvModel:GetString()
    if own ~= "" and Valid(own) then return { pm = own } end
    return SuitOutfit(cvSuit:GetString() == "engineer" and "engineer" or "worker")
end
local function EnsureOutfit()
    local all = LC.Outfits or (LC.LoadOutfits and LC.LoadOutfits())
    if not all then return end
    local want = { cleanup = LC.CleanupOutfit() }
    for job, suit in pairs(DIRTY) do want[job] = SuitOutfit(suit) end
    for job, e in pairs(want) do
        local cur = all[job]
        if not cur or cur.lcAuto then -- (never over the owner's own outfit for the job)
            all[job] = e and { list = { e }, lcAuto = true, onDuty = true } or nil -- (worn only for the work)
        end
    end
end
LC.EnsureCleanupOutfit = EnsureOutfit

-- Weedkiller for a job that sprays (Infestation Cleanup, the Groundskeeper): issued when they take
-- the job, again at each shift, and whenever they go to spray with none left.
local SPRAYERS = { cleanup = true, groundskeeper = true }
function LC.IssueWeedkiller(ply, quiet)
    local job = IsValid(ply) and LC.Job and LC.Job(ply)
    if not job or not SPRAYERS[job.id] or LC.HasItem(ply, "weedkiller") then return false end
    if not LC.GiveOrDrop then LC.GiveItem(ply, "weedkiller", 1) else LC.GiveOrDrop(ply, "weedkiller", 1) end
    if not quiet then ply:ChatPrint("[Union] A canister of weedkiller from your kit.") end
    return true
end

hook.Add("LivingCityJobChanged", "LivingCityCleanup", function(ply, id)
    if not IsValid(ply) then return end
    if id == "cleanup" then
        if not LC.HasItem(ply, "weedkiller") then
            if LC.GiveOrDrop then LC.GiveOrDrop(ply, "weedkiller", 1) else LC.GiveItem(ply, "weedkiller", 1) end
        end
        ply:ChatPrint("[Union] You're issued a respirator, weedkiller (the sprayer) and a hoover. Accept a shift (F4): it takes you into the infestation. Civil Protection will guard you.")
    end
    local ok, err = pcall(EnsureOutfit)
    if not ok and LC.Error then LC.Error("cleanup outfit", err) end
end)
timer.Simple(1, EnsureOutfit)
for _, n in ipairs({ "lc_cleanup_suit", "lc_cleanup_model" }) do
    cvars.AddChangeCallback(n, function() EnsureOutfit() end, "LivingCityCleanup")
end

------------------------------------------------------------------------
-- Growths
------------------------------------------------------------------------

-- { model, scale, colour }: the first of each that the server has
local BUILTIN = {
    { "models/props_wasteland/antlionhill.mdl", 0.22, Color(150, 175, 90) },  -- a lump of Xen growth
    { "models/antlion_grub.mdl", 1.6, Color(170, 230, 120) },               -- grubs (Episode 2)
    { "models/humans/charple01.mdl", 1, Color(120, 140, 90) },               -- what it took
    { "models/props_wasteland/antlionhill.mdl", 0.15, Color(130, 160, 80) },
}
local FALLBACK = { "models/props_junk/garbage_bag001a.mdl", 1.2, Color(120, 170, 80) }
-- Half-Life: Alyx's Xen gunk, from the owner's workshop pack (2043900984): used instead whenever the server has it
local GUNK = "models/hlvr/distillery_gunk/distillerygunk_gunk.mdl"
local GUNKS = { { GUNK, 0.7, Color(255, 255, 255) }, { GUNK, 1, Color(255, 255, 255) }, { GUNK, 1.3, Color(255, 255, 255) } }

local function PickLook()
    local own = {}
    for m in string.gmatch(cvModels:GetString(), "[^,%s]+") do if Valid(m) then own[#own + 1] = m end end
    if #own > 0 then return own[math.random(#own)], 1, Color(255, 255, 255) end
    local ok = {}
    for _, b in ipairs(Valid(GUNK) and GUNKS or BUILTIN) do if Valid(b[1]) then ok[#ok + 1] = b end end
    local b = #ok > 0 and ok[math.random(#ok)] or FALLBACK
    return b[1], b[2], b[3]
end
LC.NestLook = PickLook

local function Nests()
    local out = {}
    for _, e in ipairs(ents.FindByClass("lc_nest")) do if IsValid(e) then out[#out + 1] = e end end
    return out
end
LC.Nests = Nests

local function NestsIn(z)
    local n, list = 0, {}
    for _, e in ipairs(Nests()) do if e.lcZone == z then n = n + 1 list[n] = e end end
    return n, list
end
LC.NestsIn = NestsIn

-- the growths in a patch still alive (not sprayed dead and waiting for the hoover)
function LC.LiveNestsIn(z)
    local n = 0
    for _, e in ipairs(Nests()) do if e.lcZone == z and not e:GetNW2Bool("lc_dead", false) then n = n + 1 end end
    return n
end

function LC.SpawnNest(z, pos)
    pos = pos or (LC.SpotInZone and LC.SpotInZone(z))
    if not pos then return nil end
    local e = ents.Create("lc_nest")
    if not IsValid(e) then return nil end
    local m, scale, col = PickLook()
    e.lcModel = m
    e:SetPos(pos)
    e:SetAngles(Angle(0, math.random(0, 359), 0))
    e:Spawn()
    if e.SetModel then e:SetModel(m) end
    if e.SetModelScale then e:SetModelScale(scale or 1, 0) end
    if e.SetColor and col then e:SetColor(col) end
    e.lcZone = z
    z.lcNested = true
    return e
end

------------------------------------------------------------------------
-- The Combine's hazard props (the same workshop pack; nothing if the server hasn't got it): a
-- warning post at the edge of each infestation, and a sprayed growth bagged up for a while.
------------------------------------------------------------------------

local cvPosts = CreateConVar("lc_infest_hazard_posts", "1", FLAGS, "A Combine warning post (sign, lamp, and an infestation control barrel) at the edge of each infestation")
local HZ = "models/hlvr/combine_hazardprops/combinehazardprops_"
-- (model, sideways, back; the stand-in where the server hasn't the pack: Half-Life 2's traffic cones)
local POST = { { HZ .. "warningsign.mdl", 0, 0, "models/props_junk/TrafficCone001a.mdl" }, { HZ .. "lamp.mdl", 50, 30, "models/props_junk/TrafficCone001a.mdl" } }

-- The pack's workshop items: players who join download them (resource.AddWorkshop), so they see the
-- growths, posts and suits instead of ERRORs. The server needs them as well (its workshop collection).
local cvPacks = CreateConVar("lc_workshop_packs", "2043900984,3185145650", FLAGS, "Workshop items players download when they join (the Alyx hazard props and Infestation Control workers), comma separated")
if resource and resource.AddWorkshop then
    for id in string.gmatch(cvPacks:GetString(), "%d+") do resource.AddWorkshop(id) end
end

local function Prop(model, pos, ang)
    if not Valid(model) then return nil end
    local e = ents.Create("prop_physics")
    if not IsValid(e) then return nil end
    e:SetModel(model)
    e:SetPos(pos)
    e:SetAngles(ang or Angle(0, 0, 0))
    e:Spawn()
    local phys = e.GetPhysicsObject and e:GetPhysicsObject()
    if IsValid(phys) then phys:EnableMotion(false) end
    e.lcHazardProp = true
    return e
end

local function Reach(z)
    if z.box then return math.min(z.box.maxs.x - z.box.mins.x, z.box.maxs.y - z.box.mins.y) / 2 end
    return z.r or 300
end

-- Open ground for a post: on the floor, nothing solid in the way from the zone's middle, room to stand.
local function OpenSpot(centre, at)
    if not util.TraceLine then return true end
    local tr = util.TraceLine({ start = centre + Vector(0, 0, 50), endpos = at + Vector(0, 0, 50), mask = MASK_SOLID_BRUSHONLY })
    if tr and tr.Hit and tr.Fraction < 0.95 then return false end
    if util.TraceHull then
        local h = util.TraceHull({ start = at + Vector(0, 0, 40), endpos = at + Vector(0, 0, 41), mins = Vector(-40, -40, 0), maxs = Vector(40, 40, 40), mask = MASK_SOLID_BRUSHONLY })
        if h and h.Hit then return false end
    end
    return true
end

function LC.HazardBarrel(pos, ang)
    local e = ents.Create("lc_hazbarrel")
    if not IsValid(e) then return nil end
    e:SetPos(pos)
    e:SetAngles(ang or Angle(0, 0, 0))
    e:Spawn()
    return e
end

-- Room for a prop (mins/maxs its rough size): nothing solid where it would stand, the map's static
-- props and other props included (a brush-only trace misses static props: the lamp and barrel ended up
-- in walls, the owner, 7 November), and a floor under it.
local SIZE = { sign = { Vector(-14, -14, 2), Vector(14, 14, 70) }, lamp = { Vector(-12, -12, 2), Vector(12, 12, 90) }, barrel = { Vector(-18, -18, 2), Vector(18, 18, 50) } }
local function NotPeople(e) return not (IsValid(e) and (e:IsPlayer() or e:IsNPC())) end
local function Fits(at, size)
    if not util.TraceHull then return true end
    local h = util.TraceHull({ start = at + Vector(0, 0, 4), endpos = at + Vector(0, 0, 5), mins = size[1], maxs = size[2], mask = MASK_SOLID, filter = NotPeople })
    if h and (h.Hit or h.StartSolid) then return false end
    if util.TraceLine then
        local down = util.TraceLine({ start = at + Vector(0, 0, 20), endpos = at - Vector(0, 0, 100), mask = MASK_SOLID_BRUSHONLY })
        if not down or not down.Hit or math.abs(down.HitPos.z - at.z) > 24 then return false end
    end
    return true
end
LC.HazardPropFits = Fits

-- How far it is from a spot to the nearest wall that way (up to max).
local function Clearance(at, dir, max)
    if not util.TraceLine then return max end
    local tr = util.TraceLine({ start = at + Vector(0, 0, 36), endpos = at + Vector(0, 0, 36) + dir * max, mask = MASK_SOLID, filter = NotPeople })
    if tr and tr.StartSolid then return 0 end
    return (tr and tr.Hit) and max * tr.Fraction or max
end

-- The post beside the way in, never on it (the owner, 7 November: the signs stood right on the marked
-- path): the sign against whichever wall has room (or 100 units off the way, on open ground), the lamp
-- a step before it and the barrel a step past it, each only where it fits. `out` points out of the
-- infestation, the way the sign faces (at whoever's walking in).
local function PlacePost(z, at, out)
    local face = out:Angle()
    local right = face:Right()
    local sides = {}
    for _, s in ipairs({ right, -right }) do sides[#sides + 1] = { dir = s, room = Clearance(at, s, 260) } end
    table.sort(sides, function(x, y) return x.room > y.room end)
    for _, s in ipairs(sides) do
        if s.room < 64 then break end
        local off = s.room >= 240 and 100 or math.max(56, s.room - 30)
        local spot = at + s.dir * off
        spot = (LC.GroundAt and LC.GroundAt(spot + Vector(0, 0, 20))) or spot
        if Fits(spot, SIZE.sign) then
            local made = {}
            local sign = Prop(Valid(POST[1][1]) and POST[1][1] or POST[1][4], spot, face)
            if sign then sign.lcHazardZone = z made[#made + 1] = sign end
            for _, extra in ipairs({ { "lamp", SIZE.lamp, { 50, -50, 90 } }, { "barrel", SIZE.barrel, { -50, 50, -90 } } }) do
                for _, along in ipairs(extra[3]) do
                    local p = spot + out * along
                    p = (LC.GroundAt and LC.GroundAt(p + Vector(0, 0, 20))) or p
                    if Fits(p, extra[2]) then
                        local e
                        if extra[1] == "barrel" then e = LC.HazardBarrel(p, face)
                        else e = Prop(Valid(POST[2][1]) and POST[2][1] or POST[2][4], p, face) end
                        if e then e.lcHazardZone = z made[#made + 1] = e end
                        break
                    end
                end
            end
            return made
        end
    end
    return nil
end

function LC.HazardPost(z)
    local centre = z.box and (z.box.mins + z.box.maxs) / 2 or z.pos
    local function Out(at)
        local d = at - centre
        d.z = 0
        if d:LengthSqr() < 1 then d = Vector(1, 0, 0) end
        d:Normalize()
        return d
    end
    -- where people walk in: the path nodes just outside the infestation, on open ground, nearest first
    local nodes = {}
    for _, nd in ipairs(LC.NavNodesNear and LC.NavNodesNear(centre, Reach(z) + 600) or {}) do
        local p = nd.pos
        if math.abs(p.z - centre.z) < 120 and not (LC.InInfest and LC.InInfest(p)) and (not LC.ItemSpotOK or LC.ItemSpotOK(p, 72)) then
            nodes[#nodes + 1] = { pos = p, d = p:DistToSqr(centre) }
        end
    end
    table.sort(nodes, function(x, y) return x.d < y.d end)
    for i = 1, math.min(4, #nodes) do
        local at = (LC.GroundAt and LC.GroundAt(nodes[i].pos + Vector(0, 0, 20))) or nodes[i].pos
        local made = PlacePost(z, at, Out(at))
        if made then return made end
    end
    for try = 1, 16 do
        local yaw = math.random(0, 359)
        local dir = Angle(0, yaw, 0):Forward()
        local at = (LC.GroundAt or function(q) return q end)(centre + dir * (Reach(z) + 60) + Vector(0, 0, 30))
        if at and not (LC.InInfest and LC.InInfest(at)) and (try > 12 or OpenSpot(centre, at)) then
            local made = PlacePost(z, at, dir)
            if made then return made end
        end
    end
    return nil
end

local function PostTick(zones, alive)
    for _, cls in ipairs({ "prop_physics", "lc_hazbarrel" }) do
        for _, e in ipairs(ents.FindByClass(cls)) do
            if IsValid(e) and e.lcHazardZone and (not alive[e.lcHazardZone] or not cvPosts:GetBool()) then e:Remove() end
        end
    end
    if not cvPosts:GetBool() then return end
    for _, z in ipairs(zones) do
        if not z.lcPostTried then z.lcPostTried = true LC.HazardPost(z) end
    end
end

-- a sprayed growth, bagged by the cleanup crew, left for collection. Nobody trips over it: people
-- and NPCs walk through a bag (the owner, 7 November: they'd block the walkways).
local function Passable(e)
    if IsValid(e) and e.SetCollisionGroup then e:SetCollisionGroup(COLLISION_GROUP_DEBRIS or 1) end
    return e
end
LC.PassableProp = Passable
local function Bag(pos)
    local e = Prop(Valid(HZ .. "trashbag.mdl") and (HZ .. "trashbag.mdl") or "models/props_junk/garbage_bag001a.mdl", pos + Vector(0, 0, 4), Angle(0, math.random(0, 359), 0))
    if e then Passable(e) timer.Simple(90, function() if IsValid(e) then e:Remove() end end) end
    return e
end
LC.HazardBag = Bag

local function InfestZones()
    local out = {}
    for _, z in ipairs(LC.Zones or {}) do if z.kind == "infest" then out[#out + 1] = z end end
    return out
end

-- A growth gone (sprayed, burned): the patch it was in may go with it.
-- how: "vacuum" (a cleanup worker's hoover), "fire", "rot" (dead and left too long), "npc" (the city's crew)
function LC.ClearNest(e, by, how)
    if not IsValid(e) or e:GetClass() ~= "lc_nest" or e.lcCleared then return false end
    e.lcCleared = true
    local z = e.lcZone
    if how == "npc" then Bag(e:GetPos()) end -- (the city's crew bags it up)
    if how ~= "vacuum" and e.EmitSound then e:EmitSound("npc/barnacle/barnacle_die" .. math.random(1, 2) .. ".wav", 70) end
    -- (told before it's gone: a removed entity can't tell one growth from the next, and a job counting
    -- them saw every one after the first as the same growth)
    if IsValid(by) and by:IsPlayer() then
        LC.QuestEvent("nest_cleared", by, e)
        if how == "vacuum" then LC.QuestEvent("nest_vacuumed", by, e) end
    end
    e:Remove()
    hook.Run("LivingCityNestCleared", by, z)
    if not z then return true end
    z.lcNestNext = CurTime() + math.max(1, cvRegrow:GetFloat()) * 60
    if NestsIn(z) > 0 then return true end
    if z.grown then
        if LC.RecedeTerritory then LC.RecedeTerritory(z, "sprayed out", IsValid(by) and by:IsPlayer() and by or nil) end
    else
        -- the zone you placed is never taken away: it goes quiet for a while instead
        if LC.QuietInfestation then LC.QuietInfestation(z.pos, (z.r or 400) + 200) end
        local s = LC.TerritoryState and LC.TerritoryState[z]
        if s then s.nextGrow = math.max(s.nextGrow or 0, CurTime() + 600) end
        if IsValid(by) and by:IsPlayer() then by:ChatPrint("[Union] That's the last of the growth here. It'll be quiet for a while, but it always comes back.") end
    end
    return true
end

-- Killed (sprayed): it withers, stops glowing, and lies there dead until it's vacuumed up (or rots away).
local cvRot = CreateConVar("lc_nest_rot_minutes", "10", FLAGS, "Minutes a dead growth lies there before it rots away by itself (vacuumed up, it goes at once)")
function LC.NestDead(e) return IsValid(e) and e:GetNW2Bool("lc_dead", false) end
function LC.KillNest(e, by)
    if not IsValid(e) or e:GetClass() ~= "lc_nest" or LC.NestDead(e) then return false end
    e:SetNW2Bool("lc_dead", true)
    e.lcDeadAt = CurTime()
    if e.SetColor then e:SetColor(Color(70, 60, 40)) end
    if e.EmitSound then e:EmitSound("npc/barnacle/barnacle_die" .. math.random(1, 2) .. ".wav", 70) end
    if IsValid(by) and by:IsPlayer() then
        LC.QuestEvent("nest_killed", by, e)
        if LC.AddXP then LC.AddXP(by, 3, "Infestation growth killed") end
        if OnCleanup(by) then by:ChatPrint("[Union] It shrivels and dies. Now vacuum it up with your hoover (hold left click on it).") end
    end
    hook.Run("LivingCityNestKilled", by, e)
    return true
end

-- Spraying one: a few seconds, close up.
function LC.SprayNest(ply, e)
    if not IsValid(e) or e:GetClass() ~= "lc_nest" then return false end
    if LC.NestDead(e) then return false, OnCleanup(ply) and "It's dead already: vacuum it up with your hoover (hold left click on it)." or "It's dead already. The cleanup crew will take it away." end
    LC.IssueWeedkiller(ply)
    if not LC.HasItem(ply, "weedkiller") then return false, "You'd need weedkiller to spray it (the Union Commissary sells it)." end
    if (ply.lcSprayNext or 0) > CurTime() then return false end
    ply.lcSprayNext = CurTime() + 0.5
    local function Done(p) LC.KillNest(e, p) if LC.WearOut then LC.WearOut(p, "weedkiller", "That's the last of that canister of weedkiller.") end end
    if not LC.StartTask then Done(ply) return true end
    ply:EmitSound("ambient/water/water_spray1.wav", 55)
    return LC.StartTask(ply, 4, "Spraying the growth...", { maxMove = 60, cancelText = "You stop spraying.", done = Done })
end

local function NestTick(now)
    if not cvNests:GetBool() or not LC.Running then
        for _, e in ipairs(Nests()) do e:Remove() end
        return
    end
    local zones, alive = InfestZones(), {}
    for _, z in ipairs(zones) do alive[z] = true end
    for _, e in ipairs(Nests()) do if not alive[e.lcZone] then e:Remove() end end -- (its patch is gone)
    PostTick(zones, alive)
    local rot = math.max(1, cvRot:GetFloat()) * 60
    for _, e in ipairs(Nests()) do if LC.NestDead(e) and now - (e.lcDeadAt or now) > rot then LC.ClearNest(e, nil, "rot") end end
    local per = math.max(0, cvPer:GetInt())
    -- a crew at work (the owner, 7 November: longer shifts): the infestation pushes out another growth
    -- every tick where nobody's looking, while the worker still has growths to clear
    for _, z in ipairs(zones) do
        local need = LC.CleanupNeedNear and LC.CleanupNeedNear(z) or 0
        if need > 0 and LC.LiveNestsIn(z) < math.min(per, need) and not (LC.InfestQuietAt and LC.InfestQuietAt(z.pos)) then
            local p = LC.SpotInZone and LC.SpotInZone(z)
            if p and not (LC.IsSeen and LC.IsSeen(p + Vector(0, 0, 30))) then LC.SpawnNest(z, p) end
        end
    end
    for _, z in ipairs(zones) do
        local n = NestsIn(z)
        if n < per and not (LC.InfestQuietAt and LC.InfestQuietAt(z.pos)) then
            if not z.lcNestFirst then
                z.lcNestFirst = true
                for _ = n + 1, per do LC.SpawnNest(z) end -- (a new patch arrives with its growths)
            elseif now >= (z.lcNestNext or 0) then
                z.lcNestNext = now + math.max(1, cvRegrow:GetFloat()) * 60 * math.Rand(0.75, 1.25)
                local p = LC.SpotInZone and LC.SpotInZone(z)
                if p and not (LC.IsSeen and LC.IsSeen(p + Vector(0, 0, 30))) then LC.SpawnNest(z, p) end
            end
        end
    end
end
LC.NestTick = NestTick
timer.Create("LivingCityNests", 10, 0, function()
    local ok, err = pcall(NestTick, CurTime())
    if not ok and LC.Error then LC.Error("nests", err) end
end)

------------------------------------------------------------------------
-- Guards for the cleanup crew
------------------------------------------------------------------------

LC.CleanupGuards = LC.CleanupGuards or {} -- [worker] = { units = {}, nextLook }

-- The guards are Overwatch soldiers, never metrocops (the owner, 7 November: "2 soldiers, one with a
-- shotgun and one with a pulse rifle", no stunsticks in the infestation). A free soldier close by is
-- taken; the rest are sent in, spawned out of the worker's sight with the gun the pair still lacks, and
-- walk off again when the shift's done.
local Behind
local FREE = { idle = true, moving = true, working = true }
local function FreeUnit(npc, st, now)
    return IsValid(npc) and st.role == "soldier" and not st.elite and not st.prisonGuard and npc:Health() > 0 and FREE[st.state]
        and not st.workEscort and not st.raid and not st.questLock and not st.escortee and not st.subject
        and not st.skirmish and not st.cleanGuard and not st.holdPos and not st.guardZone and (st.stunnedUntil or 0) < now
end

-- A guard the Overwatch sent walks back where it came from, and is gone once nobody can see it.
local function WalkOff(npc, tries)
    if not IsValid(npc) then return end
    local st = LC.NPCs and LC.NPCs[npc]
    if not st or st.cleanGuard then return end -- (taken on again)
    if npc.lcGuardHome and npc.SetLastPosition and npc.SetSchedule and npc:GetPos():DistToSqr(npc.lcGuardHome) > 100 * 100 then
        npc:SetLastPosition(npc.lcGuardHome)
        npc:SetSchedule(SCHED_FORCED_GO)
    end
    local seen = LC.IsSeen and LC.IsSeen(npc:GetPos() + Vector(0, 0, 40))
    if not seen or (tries or 0) >= 18 then npc:Remove() return end
    timer.Simple(10, function() WalkOff(npc, (tries or 0) + 1) end)
end

local function Release(npc)
    local st = IsValid(npc) and LC.NPCs and LC.NPCs[npc]
    if not st then return end
    st.cleanGuard = nil
    if st.lcGuardLock then st.questLock, st.lcGuardLock = nil, nil end
    if npc.SetNW2String then LC.SetNPCStr(npc, "lc_doing", "") end
    if st.state == "cleanguard" then
        LC.SetState(npc, st, "idle")
        st.untilT = CurTime() + 2
    end
    if st.lcGuardSpawned then timer.Simple(8, function() WalkOff(npc, 0) end) end
end

local function Crowded(spot, avoid)
    for _, q in ipairs(avoid or {}) do if q:DistToSqr(spot) < 60 * 60 then return true end end
    return false
end

-- A spot on the ground behind the worker, dist away, with a clear line to it (so it's somewhere a
-- soldier can stand), and not on top of anyone in `avoid` (the owner, 7 November: both guards landed on
-- the same spot and stuck in each other).
Behind = function(worker, dist, avoid)
    local fwd = worker.GetForward and worker:GetForward() or Vector(1, 0, 0)
    fwd.z = 0
    if fwd:LengthSqr() < 0.01 then fwd = Vector(1, 0, 0) end
    local wpos = worker:GetPos()
    for _, side in ipairs({ 0, 60, -60, 120, -120, 180 }) do
        local dir = Angle(0, fwd:Angle().y + 180 + side, 0):Forward()
        local q = wpos + dir * dist + Vector(0, 0, 40)
        local tr = util.TraceLine and util.TraceLine({ start = wpos + Vector(0, 0, 40), endpos = q, mask = MASK_NPCSOLID_BRUSHONLY })
        if not tr or not tr.Hit then
            local spot = LC.GroundAt and LC.GroundAt(q) or q
            if spot and not Crowded(spot, avoid) then return spot end
        end
    end
    local n = avoid and #avoid or 0
    local right = fwd:Angle():Right()
    return wpos - fwd * 60 + right * ((n % 2 == 0) and 1 or -1) * 50 * math.ceil((n + 1) / 2)
end

local function Positions(list, field)
    local out = {}
    for _, u in ipairs(list) do
        local npc = field and u[field] or u
        if IsValid(npc) then out[#out + 1] = npc:GetPos() end
    end
    return out
end

local function HasShotgun(npc)
    local w = IsValid(npc) and npc.GetActiveWeapon and npc:GetActiveWeapon()
    return IsValid(w) and w.GetClass and w:GetClass() == "weapon_shotgun"
end

local function Assign(worker, g, now)
    local want = math.max(0, cvGuards:GetInt())
    local live = {}
    for _, u in ipairs(g.units) do
        local st = IsValid(u) and LC.NPCs[u]
        if st and u:Health() > 0 and st.cleanGuard == worker then
            -- (a fight pulls them off for a moment: back to guarding when it's over)
            if st.state ~= "cleanguard" and st.state ~= "hostile" then LC.SetState(u, st, "cleanguard") end
            live[#live + 1] = u
        end
    end
    g.units = live
    if #live >= want or now < (g.nextLook or 0) then return end
    g.nextLook = now + 3
    local wpos = worker:GetPos()
    -- free soldiers already close by
    local cands = {}
    for npc, st in pairs(LC.NPCs or {}) do
        if FreeUnit(npc, st, now) then
            local d = npc:GetPos():DistToSqr(wpos)
            if d < 1500 * 1500 then cands[#cands + 1] = { npc = npc, st = st, d = d } end
        end
    end
    table.sort(cands, function(x, y) return x.d < y.d end)
    -- not enough: the Overwatch sends the rest, out of sight behind the worker, apart from each other,
    -- the shotgun first if the pair hasn't one
    local missing = want - #live - #cands
    if missing > 0 and LC.SpawnSoldier and now >= (g.nextSpawn or 0) then
        g.nextSpawn = now + 10
        local placed = Positions(live)
        for _, c in ipairs(Positions(cands, "npc")) do placed[#placed + 1] = c end
        local shot = false
        for _, u in ipairs(live) do if HasShotgun(u) then shot = true end end
        for _, c in ipairs(cands) do if HasShotgun(c.npc) then shot = true end end
        for _ = 1, missing do
            local spot = Behind(worker, 450, placed)
            if not spot then break end
            local kind = shot and "ar2" or "shotgun"
            local npc, st = LC.SpawnSoldier(spot + Vector(0, 0, 4), kind)
            if IsValid(npc) and st then
                shot = shot or kind == "shotgun"
                st.lcGuardSpawned = true
                npc.lcGuardHome = npc:GetPos()
                placed[#placed + 1] = npc:GetPos()
                cands[#cands + 1] = { npc = npc, st = st, d = 0 }
            end
        end
    end
    for i = 1, math.min(#cands, want - #live) do
        local c = cands[i]
        if LC.Release then LC.Release(c.npc, c.st) end
        if LC.NPCWorkReset then LC.NPCWorkReset(c.npc, c.st) end
        c.st.cleanGuard = worker
        -- (held to it: nothing else sends them off, and they don't leave the city mid-job)
        if not c.st.questLock then c.st.questLock, c.st.lcGuardLock = true, true end
        c.st.route, c.st.routeTo, c.st.goingTo = nil, nil, nil
        LC.SetState(c.npc, c.st, "cleanguard")
        if c.npc.SetCurrentWeaponProficiency then c.npc:SetCurrentWeaponProficiency(WEAPON_PROFICIENCY_VERY_GOOD or 3) end
        if c.npc.SetNW2String then LC.SetNPCStr(c.npc, "lc_doing", "guarding the cleanup crew") end
        g.units[#g.units + 1] = c.npc
        if worker:IsPlayer() and not g.told then
            g.told = true
            worker:ChatPrint("[Union] The Overwatch is sending you two soldiers. Stay close to them in there.")
        end
    end
end

-- The infested nearest the worker, if any are close.
local function Threat(worker)
    local wpos, best, bd = worker:GetPos(), nil, nil
    for npc, st in pairs(LC.NPCs or {}) do
        if IsValid(npc) and st.role == "zombie" and npc:Health() > 0 then
            local d = npc:GetPos():DistToSqr(wpos)
            if d < 1100 * 1100 and (not bd or d < bd) then best, bd = npc, d end
        end
    end
    return best
end

-- Can this guard see that? (its own eyes; nothing is shot through a wall)
local function Sees(u, z)
    if u.Visible then return u:Visible(z) end
    if not util.TraceLine then return true end
    local tr = util.TraceLine({ start = u:EyePos(), endpos = z:WorldSpaceCenter(), mask = MASK_BLOCKLOS_AND_SOLID or MASK_SOLID, filter = { u, z } })
    return not tr or not tr.Hit or tr.Entity == z
end

local FOLLOWING = { SCHED_FORCED_GO, SCHED_FORCED_GO_RUN, SCHED_IDLE_STAND }
local function IsFollowing(u)
    if not u.IsCurrentSchedule then return true end
    for _, sched in ipairs(FOLLOWING) do if sched and u:IsCurrentSchedule(sched) then return true end end
    return false
end

-- A step out of the worker's way: to the open side of where they're heading, else behind them.
local function Aside(u, worker, others)
    local vel = worker.GetVelocity and worker:GetVelocity() or Vector(0, 0, 0)
    local heading = Vector(vel.x, vel.y, 0)
    if heading:LengthSqr() < 1 then heading = worker.GetForward and worker:GetForward() or Vector(1, 0, 0) heading.z = 0 end
    heading:Normalize()
    local right = heading:Angle():Right()
    local from = u:GetPos()
    for _, off in ipairs({ right * 70, -right * 70, heading * 90 }) do
        local to = from + off
        local tr = util.TraceLine and util.TraceLine({ start = from + Vector(0, 0, 36), endpos = to + Vector(0, 0, 36), mask = MASK_NPCSOLID_BRUSHONLY })
        if (not tr or not tr.Hit) and not Crowded(to, others) then return (LC.GroundAt and LC.GroundAt(to + Vector(0, 0, 20))) or to end
    end
    return Behind(worker, 100, others)
end

local function Drive(worker, g, now)
    local z = Threat(worker)
    local wpos = worker:GetPos()
    for i, u in ipairs(g.units) do
        if IsValid(u) then
            local others = {}
            for j, o in ipairs(g.units) do if j ~= i and IsValid(o) then others[#others + 1] = o:GetPos() end end
            if IsValid(z) then
                -- told where the infested is; it shoots only what it can see, and goes round a wall rather
                -- than through it. The fight itself is the soldier's own AI (the owner, 7 November: forced
                -- attack schedules every half second had them shooting walls, two shots at a time)
                if u.UpdateEnemyMemory then u:UpdateEnemyMemory(z, z:GetPos()) end
                if Sees(u, z) then
                    if u.SetEnemy and (not u.GetEnemy or u:GetEnemy() ~= z) then u:SetEnemy(z) end
                    if u.lcEngaged ~= z then
                        u.lcEngaged = z
                        if u.SetSchedule and IsFollowing(u) then u:SetSchedule(SCHED_RANGE_ATTACK1) end
                    end
                elseif now >= (u.lcChaseNext or 0) and (IsFollowing(u) or not (u.IsMoving and u:IsMoving())) then
                    u.lcChaseNext = now + 3
                    u.lcEngaged = z
                    if u.SetEnemy then u:SetEnemy(z) end
                    if u.SetSchedule then u:SetSchedule(SCHED_CHASE_ENEMY) end
                end
            else
                u.lcEngaged = nil
            end
            -- left behind (stuck, or lost on the way): back beside the worker
            local far = u:GetPos():DistToSqr(wpos) > 700 * 700
            if far then u.lcFarSince = u.lcFarSince or CurTime() else u.lcFarSince = nil end
            if far and CurTime() - u.lcFarSince > 4 then
                u.lcFarSince = nil
                local spot = Behind(worker, 90, others)
                if spot then u:SetPos(spot + Vector(0, 0, 4)) if u.SetSchedule then u:SetSchedule(SCHED_IDLE_STAND) end end
            end
            -- in the way (a doorway): a guard the worker walks into steps aside (the owner, 7 November: "I am
            -- stuck"); still in each other after a couple of seconds, it's put behind them
            local flat = u:GetPos() - wpos
            flat.z = 0
            if flat:LengthSqr() < 48 * 48 then
                u.lcBumpSince = u.lcBumpSince or now
                local vel = worker.GetVelocity and worker:GetVelocity() or Vector(0, 0, 0)
                local pushing = Vector(vel.x, vel.y, 0):LengthSqr() > 15 * 15 and (vel.x * flat.x + vel.y * flat.y) > 0
                if pushing and now >= (u.lcStepUntil or 0) then
                    u.lcStepUntil = now + 1.5
                    local to = Aside(u, worker, others)
                    if to and u.SetLastPosition and u.SetSchedule then u:SetLastPosition(to) u:SetSchedule(SCHED_FORCED_GO_RUN) end
                end
                if now - u.lcBumpSince > 2.5 then
                    u.lcBumpSince = nil
                    local spot = Behind(worker, 90, others)
                    if spot then u:SetPos(spot + Vector(0, 0, 4)) end
                end
            else
                u.lcBumpSince = nil
            end
            if not IsValid(z) and now >= (u.lcStepUntil or 0) then
                -- keep close, one on each side
                local d = u:GetPos():DistToSqr(wpos)
                if d > 170 * 170 and u.SetLastPosition and u.SetSchedule then
                    local side = (worker.GetRight and worker:GetRight() or Vector(1, 0, 0)) * (i % 2 == 0 and 70 or -70)
                    local back = (worker.GetForward and worker:GetForward() or Vector(0, 1, 0)) * -60
                    u:SetLastPosition(wpos + side + back)
                    if not (u.IsCurrentSchedule and (u:IsCurrentSchedule(SCHED_FORCED_GO) or u:IsCurrentSchedule(SCHED_FORCED_GO_RUN))) or d > 600 * 600 then
                        u:SetSchedule(d > 500 * 500 and SCHED_FORCED_GO_RUN or SCHED_FORCED_GO)
                    end
                end
            end
        end
    end
end

-- How many growths a player on a cleanup shift still has to clear (0 when they're not on one).
function LC.CleanupNeed(ply)
    if not IsValid(ply) or not ply:IsPlayer() or not OnCleanup(ply) then return 0 end
    local q = LC.QuestOf and LC.QuestOf[ply]
    if not q or q.done or q.chain ~= "shift" then return 0 end
    local st = q.stages and q.stages[q.stage]
    if not st or st.kind ~= "count" or st.event ~= "nest_vacuumed" then return 0 end
    return math.max(0, (st.need or 0) - (st.got or 0))
end

-- The most any cleanup worker near this infestation still needs (so it keeps growing for them).
function LC.CleanupNeedNear(z)
    local most = 0
    for _, p in ipairs(player.GetAll()) do
        if p:Alive() and LCZ.Near(z, p:GetPos(), 900) then most = math.max(most, LC.CleanupNeed(p)) end -- (grown ground: near any of its cells)
    end
    return most
end

-- Who needs guarding: a player on a cleanup shift near an infestation, or an NPC worker who asked.
local function NeedsGuard(w, now)
    if not IsValid(w) then return false end
    if w:IsPlayer() then
        if not w:Alive() or not OnCleanup(w) then return false end
        local q = LC.QuestOf and LC.QuestOf[w]
        if not q or q.chain ~= "shift" then return false end
        for _, z in ipairs(InfestZones()) do
            if LCZ.Near(z, w:GetPos(), 1500) then return true end
        end
        return false
    end
    return w:Health() > 0 and (w.lcGuardUntil or 0) > now
end

function LC.CleanupGuard(worker, secs)
    if not IsValid(worker) then return end
    if not worker:IsPlayer() then worker.lcGuardUntil = CurTime() + (secs or 90) end
    LC.CleanupGuards[worker] = LC.CleanupGuards[worker] or { units = {} }
end

local function GuardTick(now)
    -- players who've just walked up to an infestation on a shift
    for _, p in ipairs(player.GetAll()) do
        if not LC.CleanupGuards[p] and NeedsGuard(p, now) then LC.CleanupGuards[p] = { units = {} } end
    end
    for w, g in pairs(LC.CleanupGuards) do
        if not NeedsGuard(w, now) then
            for _, u in ipairs(g.units) do Release(u) end
            LC.CleanupGuards[w] = nil
        else
            Assign(w, g, now)
            Drive(w, g, now)
        end
    end
end
LC.CleanupGuardTick = GuardTick
timer.Create("LivingCityCleanupGuards", 0.5, 0, function()
    local ok, err = pcall(GuardTick, CurTime())
    if not ok and LC.Error then LC.Error("cleanup guards", err) end
end)

-- The city's own cleanup crews: spray the growths, with a guard.
if LC.AddNPCTask then
    LC.AddNPCTask("cleanup", { id = "nests", label = "clearing the infestation", weight = 3, find = function(npc, st, now)
        local best, bd
        for _, e in ipairs(Nests()) do
            local d = e:GetPos():DistToSqr(npc:GetPos())
            if d < 4000 * 4000 and (not bd or d < bd) then best, bd = e, d end
        end
        if not best then return nil end
        local e = best
        return { key = "nest" .. e:EntIndex(), steps = {
            { infest = true, pos = function(n) return LC.NPCWorkBeside and LC.NPCWorkBeside(e:GetPos(), n:GetPos(), 50) or e:GetPos() end,
              face = function() return e:GetPos() end, check = function() return IsValid(e) end, secs = 5, doing = "spraying the infestation",
              onGo = function(n) LC.CleanupGuard(n, 150) end,
              done = function(n) if IsValid(e) then e:EmitSound("ambient/water/water_spray1.wav", 60) LC.KillNest(e, n) end end },
            { infest = true, pos = function(n) return LC.NPCWorkBeside and LC.NPCWorkBeside(e:GetPos(), n:GetPos(), 50) or e:GetPos() end,
              face = function() return e:GetPos() end, check = function() return IsValid(e) end, secs = 5, doing = "vacuuming up the dead growth",
              done = function(n) if IsValid(e) then e:EmitSound("ambient/water/water_spray1.wav", 55, 60) LC.ClearNest(e, n, "npc") end n.lcGuardUntil = 0 end },
        } }
    end })
end

------------------------------------------------------------------------
-- The hoover (weapon_lc_hoover, the cleanup job's): dead growths in, emptied into an infestation
-- control barrel (the warning post's), or, where there are none, sealed in a bag
------------------------------------------------------------------------

local cvCap = CreateConVar("lc_hoover_capacity", "3", FLAGS, "Dead growths a cleanup worker's hoover holds before it has to be emptied")
local function Load(ply) return ply:GetNW2Int("lc_hoover_load", 0) end
LC.HooverLoad = Load

function LC.VacuumNest(ply, e)
    if not IsValid(e) or e:GetClass() ~= "lc_nest" then return false end
    if not LC.NestDead(e) then return false, "It's still alive: spray it with weedkiller first (look at it, E)." end
    local cap = math.max(1, cvCap:GetInt())
    if Load(ply) >= cap then return false, "Your hoover's full: empty it into an infestation control barrel (E on one)." end
    ply:SetNW2Int("lc_hoover_load", Load(ply) + 1)
    ply:EmitSound("physics/flesh/flesh_squishy_impact_hard" .. math.random(1, 4) .. ".wav", 60)
    LC.ClearNest(e, ply, "vacuum")
    if Load(ply) >= cap then
        ply:ChatPrint("[Union] Your hoover's full. Empty it into an infestation control barrel (E on one)" .. (LC.BarrelNear(ply) and "." or ", or seal it in a bag (right click)."))
    end
    return true
end

local function IsBarrel(e) return IsValid(e) and e:GetClass() == "lc_hazbarrel" end
LC.IsHazardBarrel = IsBarrel
-- an infestation control barrel within reach of a walk (none: a bag will do)
function LC.BarrelNear(ply)
    for _, e in ipairs(ents.FindInSphere(ply:GetPos(), 3000)) do if IsBarrel(e) then return e end end
    return nil
end

local function Emptied(ply, n, how)
    ply:SetNW2Int("lc_hoover_load", 0)
    for _ = 1, n do LC.QuestEvent("nest_dumped", ply) end
    if LC.AddXP then LC.AddXP(ply, n * 2, "Infestation waste disposed of") end
    ply:ChatPrint(string.format("[Union] %s: %d dead growth%s disposed of.", how, n, n == 1 and "" or "s"))
end

function LC.DumpHoover(ply, barrel)
    local n = Load(ply)
    if n < 1 then return false, "Your hoover's empty." end
    if not IsBarrel(barrel) then return false end
    barrel:EmitSound("physics/metal/metal_barrel_impact_soft" .. math.random(1, 4) .. ".wav", 70)
    Emptied(ply, n, "Into the barrel")
    return true
end

function LC.BagHoover(ply)
    local n = Load(ply)
    if n < 1 then return false, "Your hoover's empty." end
    if LC.BarrelNear(ply) then return false, "There's an infestation control barrel near here: empty it into that (E on it)." end
    local at = ply:GetPos() + ply:GetForward() * 30
    if not Bag(at) then
        local e = ents.Create("prop_physics")
        if IsValid(e) then
            e:SetModel("models/props_junk/garbage_bag001a.mdl") e:SetPos(at + Vector(0, 0, 8)) e:Spawn()
            Passable(e)
            timer.Simple(90, function() if IsValid(e) then e:Remove() end end)
        end
    end
    ply:EmitSound("physics/plastic/plastic_box_impact_soft" .. math.random(1, 4) .. ".wav", 60)
    Emptied(ply, n, "Sealed in a bag")
    return true
end

-- E on the barrel (entities/entities/lc_hazbarrel.lua)
function LC.UseHazardBarrel(ply, ent)
    if (ply.lcDumpNext or 0) > CurTime() then return end
    ply.lcDumpNext = CurTime() + 1
    if Load(ply) < 1 then
        ply:ChatPrint("An infestation control barrel. Empty a cleanup worker's hoover into it (E, with something in the hoover).")
        return
    end
    local ok, why = LC.DumpHoover(ply, ent)
    if not ok and why then ply:ChatPrint(why) end
end
hook.Add("LivingCityJobChanged", "LivingCityHooverEmpty", function(ply) if IsValid(ply) then ply:SetNW2Int("lc_hoover_load", 0) end end)

------------------------------------------------------------------------
-- Barnacles eat weedkiller
------------------------------------------------------------------------

local function Toxic(id) return id == "weedkiller" or string.sub(id, 1, 8) == "tainted_" end

local function BarnacleTick()
    -- (the barnacles kept as they come and go, not every entity in the map searched twice a second)
    for _, b in ipairs(LC.EntsOf and LC.EntsOf("npc_barnacle") or ents.FindByClass("npc_barnacle")) do
        if IsValid(b) and b:Health() > 0 and not b.lcPoisoned then
            for _, e in ipairs(ents.FindInSphere(b:GetPos(), 80)) do
                if IsValid(e) and e:GetClass() == "lc_item" and Toxic(e:GetNW2String("lc_item", "")) then
                    b.lcPoisoned = true
                    e:Remove()
                    if b.EmitSound then b:EmitSound("npc/barnacle/barnacle_crunch2.wav", 75) end
                    timer.Simple(1.5, function()
                        if not IsValid(b) or b:Health() <= 0 then return end
                        if b.EmitSound then b:EmitSound("npc/barnacle/barnacle_die2.wav", 80) end
                        b:TakeDamage(b:Health() + 100, game.GetWorld(), game.GetWorld())
                    end)
                    break
                end
            end
        end
    end
end
LC.BarnacleTick = BarnacleTick
timer.Create("LivingCityBarnacles", 0.5, 0, function()
    local ok, err = pcall(BarnacleTick)
    if not ok and LC.Error then LC.Error("barnacles", err) end
end)

------------------------------------------------------------------------
-- The firebomb
------------------------------------------------------------------------

local FIRE_R = 400 -- (the owner, 1 November: five times wider; it was too precise for a bottle that bounces first)
LC.Fires = LC.Fires or {}

function LC.Firebomb(pos, owner)
    local now, secs = CurTime(), math.max(1, cvFire:GetFloat())
    if sound and sound.Play then
        sound.Play("physics/glass/glass_bottle_break" .. math.random(1, 2) .. ".wav", pos, 80)
        sound.Play("ambient/fire/ignite.wav", pos, 85)
    end
    -- the flames: the engine's own fire
    pcall(function()
        local f = ents.Create("env_fire")
        if not IsValid(f) then return end
        f:SetPos(pos)
        f:SetKeyValue("health", tostring(secs))
        f:SetKeyValue("firesize", "220")
        f:SetKeyValue("fireattack", "1")
        f:SetKeyValue("damagescale", "0")
        f:SetKeyValue("spawnflags", tostring(4 + 128))
        f:Spawn()
        f:Fire("StartFire", "", 0)
        timer.Simple(secs + 1, function() if IsValid(f) then f:Remove() end end)
    end)
    LC.Fires[#LC.Fires + 1] = { pos = pos, untilT = now + secs, owner = owner }
    -- Combine machinery nearby burns out
    for _, e in ipairs(ents.FindInSphere(pos, FIRE_R + 80)) do
        if IsValid(e) and LC.VortZapTech then LC.VortZapTech(nil, e, 90) end
    end
    if IsValid(owner) and owner:IsPlayer() and LC.SeenBySecurity and LC.SeenBySecurity(owner, 900) then
        LC.ReportCrime(owner, "Firebombing", 300)
    end
    hook.Run("LivingCityFirebomb", pos, owner)
end

local function FireTick(now)
    for i = #LC.Fires, 1, -1 do
        local f = LC.Fires[i]
        if now > f.untilT then
            table.remove(LC.Fires, i)
        else
            local attacker = IsValid(f.owner) and f.owner or game.GetWorld()
            for _, e in ipairs(ents.FindInSphere(f.pos, FIRE_R)) do
                if IsValid(e) then
                    if e:GetClass() == "lc_nest" then
                        LC.ClearNest(e, IsValid(f.owner) and f.owner or nil, "fire")
                    elseif (e:IsPlayer() and e:Alive()) or (e.IsNPC and e:IsNPC() and e:Health() > 0) then
                        if e.Ignite then e:Ignite(3) end
                        e:TakeDamage(6, attacker, attacker)
                    end
                end
            end
        end
    end
end
LC.FireTick = FireTick
timer.Create("LivingCityFires", 0.5, 0, function()
    local ok, err = pcall(FireTick, CurTime())
    if not ok and LC.Error then LC.Error("fires", err) end
end)

------------------------------------------------------------------------
-- A sweep opens with gas
------------------------------------------------------------------------

hook.Add("LivingCitySweepArrived", "LivingCityCleanupGas", function(sk, u)
    if not sk or not sk.zone or math.random() >= cvSweep:GetFloat() or not LC.Detonate then return end
    -- into the thick of them: the nearest rebel to the unit, else the middle of their ground
    local spot
    if IsValid(u) then
        local bd
        for _, r in ipairs(sk.rebels or {}) do
            if IsValid(r) and r:Health() > 0 then
                local d = r:GetPos():DistToSqr(u:GetPos())
                if not bd or d < bd then spot, bd = r:GetPos(), d end
            end
        end
        if u.EmitSound then u:EmitSound("npc/metropolice/vo/movein.wav", 80) end
    end
    spot = spot or sk.zone.pos
    timer.Simple(1.5, function() LC.Detonate("poison", spot, IsValid(u) and u or nil) end)
end)

-- A cleanup guard's shots tell on the infested: four times the damage (the owner, 1 November: the soldiers
-- plinked away while the zombies mauled the worker).
local cvGuardDmg = CreateConVar("lc_cleanup_guard_damage", "4", FLAGS, "How many times harder a cleanup worker's guards hit the infested")
hook.Add("EntityTakeDamage", "LivingCityCleanupGuardDamage", function(victim, dmg)
    local att = dmg:GetAttacker()
    local ast = IsValid(att) and LC.NPCs and LC.NPCs[att]
    if not ast or not ast.cleanGuard then return end
    local vst = LC.NPCs[victim]
    if vst and vst.role == "zombie" then dmg:ScaleDamage(math.max(1, cvGuardDmg:GetFloat())) end
end)
