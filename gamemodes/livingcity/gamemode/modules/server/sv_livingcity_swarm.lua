--[[
    Living City: the Swarm, the second way into the chapter "the city falls to the Resistance" (the owner, 27 November:
    "we'll want the highest ranking player on the server to get the pheropods ... they function just like in HL2: you can
    control antlions and the mission becomes 'disable the thumpers' and then once the player with the pheropods is inside
    the city, antlions function just like in Nova Prospekt ... throwing a pheropod on an NPC or player spawns extra
    antlions that then swarm the target and any other enemies nearby ... the antlion nest needs to have the EP2 antlion
    guardian spawn and come straight out of the gate when it is opened and another when the extract ... is reached and
    harvested"). The rocket's way stays as it is. docs/features/the-swarm.md.

      The nest      the forest cave's emergency door (the map's relay lc_nest_opened) brings an Episode Two antlion
                    guardian out of the dark behind it, charging through the doorway at whoever opened it (one at a
                    time; not again for 10 minutes after one dies). The larval extract (lc_nest_extract) is harvested
                    by holding E on it for 5 seconds while the nest wakes: its glow and a rising sound show how far.
                    A second guardian bursts up in the chamber: while it lives, the hive hunts the essence wherever
                    it goes (antlions burrow up near it every 15 to 20 seconds, 4 out at most).
      Fragile       dropped (death, disconnect) it lies glowing where they fell: anyone not Combine picks it up (E).
                    In a Combine player's pockets (E on it, a search, a pat-down, cuffs) it is gone, and so it is when
                    the Combine (players or NPCs) hurt it on the ground; Combine NPCs who see it go for it. Gone, or
                    left 10 minutes, the essence is back in the nest.
      The keeper    the carrier hands it to a freed vortigaunt (E), who holds it as Episode Two's does and stays put.
      The ritual    a Resistance player's E on that vortigaunt, once the five things the owner asked for are true
                    (the flag live at the mine, 3 freed vortigaunts, strength 70, 2 districts, the mine's flag flown 2
                    hours) and the city can fall: the freed vortigaunts gather, turn blue-purple and chant for 15
                    seconds, and the pheropods (weapon_bugbait) go to the highest-ranking Resistance player online.
                    Missing anything: one short line of what. One per map.
      The swarm     the mission is the city's thumpers. All stopped (or none on the map) and the holder in the city:
                    antlions come up near the holder as at Nova Prospekt, the Resistance's allies and the Combine's
                    enemies. A thrown pheropod brings more onto what it hits; squeezed, they come to the holder.
      The fall      the holder in the Nexus with the swarm: antlions burst up on the Combine, and the chapter begins
                    (LC.ChapterBegin("swarm")). The pheropods are destroyed for good, the antlions turn wild, and the
                    thumpers left stopped are broken until mended: the Resistance's job "Restart the thumpers".

    lc_swarm 0: nobody can harvest, no ritual, the city does not fall to the swarm by itself; staff's lines still work,
    and the guardians and the map's own wiring still run. Staff: F4 > Factions > Admin: testing tools > The city.
    The mine's flag clock is kept in data/livingcity/<map>_swarm.json; the rest starts afresh with the map.
]]

if CLIENT then return end

LC = LC or {}
LC.Swarm = LC.Swarm or {}
local W = LC.Swarm

local FLAGS = bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED)
local cvOn = CreateConVar("lc_swarm", "1", FLAGS, "The Swarm: the antlion nest's larval extract, made into pheropods by the freed vortigaunts, brings the antlions down on the Combine and the city to the Resistance (0: no harvest, ritual or fall by itself; staff's lines still work)")

util.AddNetworkString("lc_swarm_fall")

W.HARVEST_SECS = 5        -- holding E on the essence
W.REACH = 300             -- how far from the essence a harvest (or a pickup by look) reaches
W.CONE = 0.94             -- how straight at it you must look
W.HUNT_MAX = 4            -- antlions out after the essence at once
W.HUNT_GAP = { 15, 20 }   -- seconds between them
W.DROP_SECS = 600         -- left untouched this long: back in the nest
W.RITUAL_SECS = 15
W.RITUAL_R = 1500         -- freed vortigaunts this near the keeper join in
W.RING = 90
W.SWARM_MAX = 6           -- the swarm round the holder
W.SWARM_EVERY = 20
W.SWARM_CAP = 10          -- with what a thrown pheropod brings
W.EXTRA = 3
W.THUMP_R = 1000          -- a running thumper's reach (the map's EffectRadius)
W.CITY_REACH = 2500       -- round the city's zones, the city
W.FALL_DELAY = 2.5        -- the burst, then the city falls
W.FALL_MAX = 16
W.GUARD_AGAIN = 600       -- the door's next guardian, after one dies
W.GUARD_CHARGE = 4        -- the shutter high enough for it
W.SEE_R = 1500            -- Combine NPCs who see a dropped extract go for it
W.STOMP_R = 28
-- what the ritual waits for (the owner, 27 November)
W.NEED_VORTS = 3
W.NEED_STRENGTH = 70
W.NEED_DISTRICTS = 2
W.NEED_FLOWN = 7200       -- seconds of server time the mine's flag has flown
W.MINE = "lc_hq_setup_cave"

local VORTIGESE = {}
for i = 2, 12 do VORTIGESE[#VORTIGESE + 1] = string.format("vo/npc/vortigaunt/vortigese%02d.wav", i) end
local HULL = { antlion = { Vector(-18, -18, 0), Vector(18, 18, 64) }, guard = { Vector(-40, -40, 0), Vector(40, 40, 100) } }
local COMBINE_FACTION = { cp = true, admin = true, ota = true }
local COMBINE_CLASSES = { "npc_metropolice", "npc_combine_s", "npc_cscanner", "npc_clawscanner", "npc_manhack", "npc_rollermine",
    "npc_hunter", "npc_strider", "npc_turret_floor", "npc_stalker" }
local CITY_KINDS = { block = true, combine = true, prison = true, infest = true, nogo = true }
local ESSENCE_MODEL = "models/props_hive/larval_essence.mdl"

local function Fresh() return { stage = "nest", out = {}, wild = {}, broken = {}, pressers = {}, grenades = {} } end
W.S = W.S or Fresh()

------------------------------------------------------------------------
-- Who is who
------------------------------------------------------------------------

local function Faction(p) return (IsValid(p) and p:IsPlayer()) and p:GetNW2String("lcf_faction", "") or "" end
local function CombinePlayer(p) return COMBINE_FACTION[Faction(p)] == true end
local function Rebel(p) return Faction(p) == "resistance" end
local function Living(e) return IsValid(e) and (e:IsPlayer() and e:Alive() or (not e:IsPlayer() and e:Health() > 0)) end
local function Combine(e)
    if not IsValid(e) then return false end
    if e:IsPlayer() then return CombinePlayer(e) end
    return LC.IsCombineNPC ~= nil and LC.IsCombineNPC(e) == true
end
-- a Combine NPC that can walk up to the extract: units and soldiers (the gamemode's own roles)
local function Walker(npc)
    local st = LC.NPCs and LC.NPCs[npc]
    if st then return st.role == "cop" or st.role == "soldier" end
    local c = npc:GetClass()
    return c == "npc_metropolice" or c == "npc_combine_s"
end
local function Friendly(e)
    if not IsValid(e) then return false end
    if e:IsPlayer() then return Rebel(e) end
    local st = LC.NPCs and LC.NPCs[e]
    return (st and (st.role == "rebel" or st.role == "vortigaunt")) or (LC.RebelVorts and LC.RebelVorts[e]) or false
end
local function Nick(p) return IsValid(p) and p:Nick() or "Nobody" end

-- The one place this puts words on a screen (house rule 10: few of them).
local function Tell(p, text) if IsValid(p) and LC.Notice then LC.Notice(p, "event", "The swarm", text, 8) end end
local function TellRebels(text, but) for _, p in ipairs(player.GetAll()) do if p ~= but and Rebel(p) then Tell(p, text) end end end

------------------------------------------------------------------------
-- The map's pieces, found by name
------------------------------------------------------------------------

local function Named(name)
    for _, e in ipairs(ents.FindByName and ents.FindByName(name) or {}) do if IsValid(e) then return e end end
    return nil
end
function W.Essence()
    if not IsValid(W.essence) then W.essence = Named("lc_nest_extract") end
    return W.essence
end
function W.ShowEssence(on)
    local e = W.Essence()
    if IsValid(e) and e.SetNoDraw then e:SetNoDraw(not on) end
end

-- The city's thumpers (every copy of the module: sv_livingcity_antlions.lua).
function W.Thumpers() return LC.Antlions and LC.Antlions.Heads and LC.Antlions.Heads() or {} end
function W.Stopped(th) return LC.Antlions ~= nil and LC.Antlions.stopped[th] ~= nil end
function W.StoppedThumpers()
    local out = {}
    for _, th in ipairs(W.Thumpers()) do if W.Stopped(th) then out[#out + 1] = th end end
    return out
end
function W.AllStopped()
    for _, th in ipairs(W.Thumpers()) do if not W.Stopped(th) then return false end end
    return true
end
local function NearRunningThumper(pos)
    for _, th in ipairs(W.Thumpers()) do
        if not W.Stopped(th) and th:GetPos():DistToSqr(pos) < W.THUMP_R * W.THUMP_R then return true end
    end
    return false
end
-- A broken thumper (left stopped when the city fell to the swarm): its button does nothing until it is mended.
function W.Broken(th) return IsValid(th) and W.S.broken[th] == true end

-- Inside the city: in or near a housing block, a Combine-only zone, the prison or the infestation (not the forests).
-- A map with none of them: everywhere.
function W.InCity(pos)
    local any = false
    for _, z in ipairs(LC.Zones or {}) do
        if CITY_KINDS[z.kind] then
            any = true
            if LCZ.Contains(z, pos, W.CITY_REACH) then return true end
        end
    end
    return not any
end
function W.InNexus(pos)
    for _, z in ipairs(LC.ChapterNexus and LC.ChapterNexus() or {}) do if LCZ.Contains(z, pos) then return true end end
    return false
end

------------------------------------------------------------------------
-- Places on the floor
------------------------------------------------------------------------

local function FloorUnder(pos, rise, drop)
    if not util.TraceLine then return nil end
    local tr = util.TraceLine({ start = pos + Vector(0, 0, rise or 64), endpos = pos - Vector(0, 0, drop or 192), mask = MASK_SOLID_BRUSHONLY })
    if tr and tr.Hit then return tr.HitPos end
    return nil
end
local function Clear(pos, hull)
    if not util.TraceHull then return true end
    local tr = util.TraceHull({ start = pos + Vector(0, 0, 6), endpos = pos + Vector(0, 0, 6), mins = hull[1], maxs = hull[2], mask = MASK_NPCSOLID })
    return not (tr and (tr.Hit or tr.StartSolid))
end
local function Seen(a, b)
    if not util.TraceLine then return true end
    local tr = util.TraceLine({ start = a, endpos = b, mask = MASK_SOLID_BRUSHONLY })
    return not (tr and tr.Hit)
end

-- A spot on the floor round centre, rmin to rmax away, that a creature of this hull fits and that centre sees.
-- dir: the way to try first (behind someone). avoid(pos): a spot not to use.
function W.SpotNear(centre, rmin, rmax, hull, dir, avoid)
    local base = dir and math.atan2(dir.y, dir.x) or math.Rand(0, math.pi * 2)
    for i = 0, 11 do
        local a = base + ((i % 2 == 0) and 1 or -1) * math.floor((i + 1) / 2) * (math.pi / 6)
        local r = math.Rand(rmin, rmax)
        local floor = FloorUnder(centre + Vector(math.cos(a) * r, math.sin(a) * r, 0), 64, 192)
        if floor and math.abs(floor.z - centre.z) < 96 and Clear(floor, hull or HULL.antlion) and not (avoid and avoid(floor))
            and Seen(centre + Vector(0, 0, 40), floor + Vector(0, 0, 40)) then
            return floor
        end
    end
    return nil
end

------------------------------------------------------------------------
-- Antlions, guardians, and whose side they are on
------------------------------------------------------------------------

local function Rel(a, b, d) if IsValid(a) and IsValid(b) and a.AddEntityRelationship then a:AddEntityRelationship(b, d, 99) end end
local function ClassRel(a, text) if IsValid(a) and a.AddRelationship then a:AddRelationship(text) end end
local function Go(npc, pos, run)
    if IsValid(npc) and npc.SetLastPosition then npc:SetLastPosition(pos) npc:SetSchedule(run and SCHED_FORCED_GO_RUN or SCHED_FORCED_GO) end
end
local function Hunt(npc, target)
    if not (IsValid(npc) and IsValid(target)) then return end
    Rel(npc, target, D_HT)
    if npc.SetEnemy then npc:SetEnemy(target) end
    if npc.UpdateEnemyMemory then npc:UpdateEnemyMemory(target, target:GetPos()) end
end
local function Count(kind)
    local n = 0
    for e, k in pairs(W.S.out) do
        if not (IsValid(e) and e:Health() > 0) then W.S.out[e] = nil elseif k == kind then n = n + 1 end
    end
    return n
end
local function OfKind(kind)
    local out = {}
    for e, k in pairs(W.S.out) do if k == kind and IsValid(e) and e:Health() > 0 then out[#out + 1] = e end end
    return out
end

-- An antlion digging up out of the ground (Valve's own unburrow).
function W.Antlion(pos, kind)
    local e = ents.Create("npc_antlion")
    if not IsValid(e) then return nil end
    e:SetPos(pos + Vector(0, 0, 4))
    e:SetAngles(Angle(0, math.random(0, 359), 0))
    e:SetKeyValue("startburrowed", "1")
    e:SetKeyValue("spawnflags", tostring(SF_NPC_FADE_CORPSE or 512))
    e:Spawn()
    if e.Activate then e:Activate() end
    if e.Fire then e:Fire("Unburrow", "", 0.1) end
    W.S.out[e] = kind
    return e
end

-- Episode Two's cavern guardian (cavernbreed, as Garry's Mod's own "Antlion Guardian"). incavern: poison and no charge.
function W.Guard(pos, yaw, incavern, burrowed)
    local g = ents.Create("npc_antlionguard")
    if not IsValid(g) then return nil end
    g:SetPos(pos + Vector(0, 0, 4))
    g:SetAngles(Angle(0, yaw or 0, 0))
    g:SetKeyValue("cavernbreed", "1")
    g:SetKeyValue("incavern", incavern and "1" or "0")
    if burrowed then g:SetKeyValue("startburrowed", "1") end
    g:Spawn()
    if g.Activate then g:Activate() end
    if burrowed and g.Fire then g:Fire("Unburrow", "", 0.2) end
    W.S.out[g] = "guard"
    return g
end

-- One of the swarm's: the Resistance's friend (players, fighters, vortigaunts), the Combine's enemy; citizens left alone.
-- (Per creature, never Half-Life 2's antlion_allied: that makes every antlion love every player, units too.)
function W.Befriend(ant)
    if not IsValid(ant) or ant.lcSwarmWild then return end
    if not ant.lcSwarmFriend then
        ant.lcSwarmFriend, ant.lcSwarmSeen = true, {}
        ClassRel(ant, "player D_NU 99") ClassRel(ant, "npc_citizen D_NU 99") ClassRel(ant, "npc_vortigaunt D_LI 99")
        for _, c in ipairs(COMBINE_CLASSES) do ClassRel(ant, c .. " D_HT 99") end
    end
    for _, p in ipairs(player.GetAll()) do Rel(ant, p, Rebel(p) and D_LI or (CombinePlayer(p) and D_HT or D_NU)) end
    for npc, st in pairs(LC.NPCs or {}) do
        if IsValid(npc) and not ant.lcSwarmSeen[npc] then
            ant.lcSwarmSeen[npc] = true
            if st.role == "rebel" or st.role == "vortigaunt" then Rel(ant, npc, D_LI) Rel(npc, ant, D_LI)
            elseif st.role == "cop" or st.role == "soldier" or st.role == "scanner" then Rel(ant, npc, D_HT)
            else Rel(ant, npc, D_NU) end
        end
    end
    for v in pairs(LC.RebelVorts or {}) do
        if IsValid(v) and not ant.lcSwarmSeen[v] then ant.lcSwarmSeen[v] = true Rel(ant, v, D_LI) Rel(v, ant, D_LI) end
    end
end

-- Nobody's again: every player and person its enemy (after the fall).
function W.Wild(ant)
    if not IsValid(ant) or ant.lcSwarmWild then return end
    ant.lcSwarmWild, ant.lcSwarmFriend = true, nil
    ClassRel(ant, "player D_HT 99") ClassRel(ant, "npc_citizen D_HT 99") ClassRel(ant, "npc_vortigaunt D_HT 99")
    for _, p in ipairs(player.GetAll()) do Rel(ant, p, D_HT) end
    for npc in pairs(ant.lcSwarmSeen or {}) do if IsValid(npc) then Rel(ant, npc, D_HT) Rel(npc, ant, D_HT) end end
    W.S.wild[ant] = true
end

local function BurrowAway(kind)
    for e, k in pairs(W.S.out) do
        if k == kind then
            if IsValid(e) and e:Health() > 0 then
                if e.Fire then e:Fire("BurrowAway", "", math.Rand(0, 2)) else e:Remove() end
            end
            W.S.out[e] = nil
        end
    end
end

-- The nearest Combine NPC or unit to pos, within r.
function W.FoeNear(pos, r)
    local best, bd
    for _, e in ipairs(ents.FindInSphere and ents.FindInSphere(pos, r) or {}) do
        if Living(e) and Combine(e) and not (e:IsPlayer() and e:GetNW2Bool("lc_build", false)) then
            local d = e:GetPos():DistToSqr(pos)
            if not bd or d < bd then best, bd = e, d end
        end
    end
    return best
end
local function NearestPlayer(pos, r)
    local best, bd
    for _, p in ipairs(player.GetAll()) do
        local d = p:GetPos():DistToSqr(pos)
        if p:Alive() and d < r * r and (not bd or d < bd) then best, bd = p, d end
    end
    return best
end

------------------------------------------------------------------------
-- The emergency door's guardian (it comes whatever lc_swarm says)
------------------------------------------------------------------------

-- Where it waits: on the planks just behind the shutter (the tunnels' side: away from the holdout's rally point), at
-- the door's own floor, never down in the cleft. The shutter's opening (192 wide, 152 clear when up) takes the
-- guardian's hull (80 wide, 100 tall). Returns the spot (nil: none found), the way out, the doorway's middle.
function W.DoorGuardSpot()
    local door = Named("lc_nest_door")
    if not IsValid(door) then return nil end
    local mins, maxs = door:OBBMins(), door:OBBMaxs()
    local centre = door:LocalToWorld((mins + maxs) * 0.5)
    local size = maxs - mins
    local n = size.x < size.y and Vector(1, 0, 0) or Vector(0, 1, 0) -- (the shutter is thin across its wall)
    local front, back = Named("lc_nest_rally"), Named("lc_nest_extract") or Named("lc_nest_maker")
    if IsValid(front) then
        if (front:GetPos() - centre):Dot(n) > 0 then n = -n end
    elseif IsValid(back) and (back:GetPos() - centre):Dot(n) < 0 then
        n = -n
    end
    local foot = door:LocalToWorld(mins).z
    local half = math.min(size.x, size.y) / 2
    for _, d in ipairs({ 72, 110, 150, 200 }) do
        local at = Vector(centre.x, centre.y, foot) + n * (half + d)
        local floor = FloorUnder(at, 64, 64)
        if floor and math.abs(floor.z - foot) < 40 and Clear(floor, HULL.guard) then return floor, n, centre end
    end
    return nil, n, centre
end

-- Who opened it: whoever pressed one of its buttons last (within half a minute), else the nearest player to it.
function W.Opener(at)
    local best, bt
    for p, t in pairs(W.S.pressers) do
        if Living(p) and CurTime() - t < 30 and p:GetPos():DistToSqr(at) < 3000 * 3000 and (not bt or t > bt) then best, bt = p, t end
    end
    return best or NearestPlayer(at, 3000)
end

function W.DoorOpened(by)
    local S = W.S
    if Living(S.doorGuard) then return nil end
    if S.doorGuardDied and CurTime() - S.doorGuardDied < W.GUARD_AGAIN then return nil end
    local spot, n, centre = W.DoorGuardSpot()
    if not centre then return nil end
    spot = spot or Vector(centre.x, centre.y, centre.z) + n * 90 -- (no floor found to check: right behind the shutter)
    local g = W.Guard(spot, math.deg(math.atan2(-n.y, -n.x)), false, false)
    if not g then return nil end
    S.doorGuard, S.doorGuardDied = g, nil
    S.doorChargeAt, S.doorAt = CurTime() + W.GUARD_CHARGE, centre
    if IsValid(by) then S.pressers[by] = S.pressers[by] or CurTime() end
    return g
end

-- The shutter is up: out through the doorway at whoever opened it.
local function DoorCharge()
    local S = W.S
    S.doorChargeAt = nil
    local g = S.doorGuard
    if not Living(g) then return end
    local t = W.Opener(S.doorAt or g:GetPos())
    if not t then return end
    Hunt(g, t)
    if g.Fire then g:Fire("SetChargeTarget", "!activator !activator", 0, t, t) end
    if g.SetSchedule then g:SetSchedule(SCHED_CHASE_ENEMY) end
    return t
end

------------------------------------------------------------------------
-- The harvest
------------------------------------------------------------------------

-- Looking at a point within reach (the essence has no collision of its own, so E on it is a look, not a trace).
local function LookingAt(p, pos, reach)
    local eye = p:EyePos()
    local to = pos - eye
    local d = to:Length()
    if d > reach then return false end
    if d < 1 then return true end
    if p:GetAimVector():Dot(to / d) < W.CONE then return false end
    if not util.TraceLine then return true end
    local tr = util.TraceLine({ start = eye, endpos = pos, mask = MASK_SOLID_BRUSHONLY })
    return not (tr and tr.Hit) or tr.HitPos:Distance(pos) < 220 -- (the honeycomb round the essence is fine)
end

function W.TryHarvest(p)
    local S = W.S
    if S.stage ~= "nest" or S.harvest or not cvOn:GetBool() then return false end
    if not Living(p) or not p:IsPlayer() or CombinePlayer(p) then return false end
    local ess = W.Essence()
    if not IsValid(ess) or not LookingAt(p, ess:GetPos(), W.REACH) then return false end
    S.harvest = { ply = p, t0 = CurTime(), step = 0 }
    SetGlobal2Entity("lc_swarm_essence", ess)
    ess:SetNW2Float("lc_swarm_glow", 0.02)
    ess:EmitSound("npc/vort/health_charge.wav", 70, 70)
    -- the nest wakes: the grubs squeal, the ground stirs
    for _, grub in ipairs(ents.FindByClass and ents.FindByClass("npc_antlion_grub") or {}) do
        if IsValid(grub) and grub:GetPos():DistToSqr(ess:GetPos()) < 1500 * 1500 then grub:EmitSound("NPC_Antlion_Grub.Alert") end
    end
    if util.ScreenShake then util.ScreenShake(ess:GetPos(), 2, 5, W.HARVEST_SECS, 900) end
    return true
end

function W.HarvestStop()
    local h = W.S.harvest
    W.S.harvest = nil
    local ess = W.Essence()
    if IsValid(ess) then ess:SetNW2Float("lc_swarm_glow", 0) end
    if h then SetGlobal2Entity("lc_swarm_essence", NULL) end
end

-- The second guardian bursts up in the chamber, near the harvester: while it lives the hive hunts the essence.
local function ChamberGuard(p)
    local at = p:GetPos()
    local aim = p:GetAimVector()
    local spot = W.SpotNear(at, 260, 420, HULL.guard, Vector(aim.x, aim.y, 0))
    if not spot then
        local back = Vector(-aim.x, -aim.y, 0)
        spot = at + (back:LengthSqr() > 0.01 and back:GetNormalized() or Vector(1, 0, 0)) * 200
    end
    local g = W.Guard(spot, math.deg(math.atan2(at.y - spot.y, at.x - spot.x)), true, true)
    if g then Hunt(g, p) end
    W.S.claim, W.S.claimGoneAt = g, nil
    return g
end

function W.Harvested(p)
    local ess = W.Essence()
    W.HarvestStop()
    W.ShowEssence(false)
    if IsValid(ess) then ess:EmitSound("ambient/energy/whiteflash.wav", 75, 140) end
    ChamberGuard(p)
    W.S.huntNext = CurTime() + math.Rand(W.HUNT_GAP[1], W.HUNT_GAP[2])
    W.Carry(p)
    if LC.Log then LC.Log("info", "swarm: " .. Nick(p) .. " harvested the larval extract") end
end

function W.HarvestTick(now)
    local h = W.S.harvest
    if not h then return end
    local p, ess = h.ply, W.Essence()
    if not (W.S.stage == "nest" and Living(p) and IsValid(ess) and p:KeyDown(IN_USE) and LookingAt(p, ess:GetPos(), W.REACH)) then
        return W.HarvestStop()
    end
    local f = math.Clamp((now - h.t0) / W.HARVEST_SECS, 0, 1)
    ess:SetNW2Float("lc_swarm_glow", math.max(0.02, f))
    local step = math.floor(f * 4)
    if step > h.step then
        h.step = step
        ess:EmitSound("npc/vort/health_charge.wav", 70, 70 + 15 * step) -- (a sound that rises as it is drawn out)
        if step == 1 or step == 3 then -- (and the chamber's antlions dig up round the harvester)
            local spot = W.SpotNear(p:GetPos(), 200, 420, HULL.antlion)
            local e = spot and W.Antlion(spot, "hunt")
            if e then Hunt(e, p) end
        end
    end
    if f >= 1 then W.Harvested(p) end
end

------------------------------------------------------------------------
-- Carried, dropped, kept by a vortigaunt, and gone
------------------------------------------------------------------------

local function Uncarry()
    local p = W.S.carrier
    if IsValid(p) then p:SetNW2Bool("lc_swarm_carry", false) end
    W.S.carrier = nil
end

local function ClearDrop()
    local S = W.S
    if IsValid(S.bull) then S.bull:Remove() end
    if IsValid(S.drop) then S.drop:Remove() end
    S.drop, S.bull, S.dropAt = nil, nil, nil
end

local function Release(v)
    if IsValid(v) then v.lcVortNext = 0 end
    if IsValid(W.S.holdScript) then W.S.holdScript:Fire("CancelSequence") W.S.holdScript:Remove() end
    if IsValid(W.S.inHand) then W.S.inHand:Remove() end
    W.S.holdScript, W.S.inHand = nil, nil
    SetGlobal2Entity("lc_swarm_inhand", NULL)
end

function W.Carry(p)
    local S = W.S
    ClearDrop()
    if IsValid(S.carrier) and S.carrier ~= p then S.carrier:SetNW2Bool("lc_swarm_carry", false) end
    S.stage, S.carrier, S.bringer = "carried", p, p
    if IsValid(p) then p:SetNW2Bool("lc_swarm_carry", true) end
end

-- It lies glowing where it fell, for anyone to pick up; an invisible mark on it that only the Combine are told to
-- hate (npc_bullseye, not solid, taking no damage: their shots go into the extract).
function W.Drop(pos)
    local S = W.S
    Uncarry()
    Release(S.keeper)
    S.keeper = nil
    ClearDrop()
    local floor = FloorUnder(pos, 32, 192) or pos
    local e = ents.Create("lc_swarm_extract")
    if not IsValid(e) then return W.Home() end
    e:SetPos(floor + Vector(0, 0, 2))
    e:Spawn()
    if e.Activate then e:Activate() end
    e:SetNW2Bool("lc_swarm_drop", true)
    S.stage, S.drop, S.dropAt = "dropped", e, CurTime()
    local b = ents.Create("npc_bullseye")
    if IsValid(b) then
        b:SetPos(floor + Vector(0, 0, 8))
        b:SetKeyValue("spawnflags", tostring(65536 + 131072))
        b:Spawn()
        if b.Activate then b:Activate() end
        if b.SetParent then b:SetParent(e) end
        S.bull = b
    end
    return e
end

-- Back in the nest: the essence shows again over the honeycomb.
function W.Home()
    local S = W.S
    Uncarry()
    Release(S.keeper)
    ClearDrop()
    S.stage, S.keeper, S.bringer = "nest", nil, nil
    W.ShowEssence(true)
end

-- Gone: a wet burst of it, no words, and the essence back in the nest.
function W.Destroy(how)
    local S = W.S
    local at
    if S.stage == "dropped" and IsValid(S.drop) then at = S.drop:GetPos() + Vector(0, 0, 6)
    elseif S.stage == "carried" and IsValid(S.carrier) then at = S.carrier:GetPos() + Vector(0, 0, 40) end
    if at then
        if sound and sound.Play then sound.Play("physics/flesh/flesh_squishy_impact_hard" .. math.random(1, 4) .. ".wav", at, 75, 100) end
        if util.Effect and EffectData then
            local ed = EffectData()
            ed:SetOrigin(at)
            ed:SetColor(BLOOD_COLOR_ANTLION or 4)
            ed:SetScale(2)
            util.Effect("BloodImpact", ed)
        end
    end
    if LC.Log then LC.Log("info", "swarm: the larval extract is gone (" .. tostring(how) .. ")") end
    W.Home()
    return true
end

-- E on it on the ground: anyone not Combine carries it; a Combine player pockets it, and it is gone.
function W.UseExtract(p, e)
    local S = W.S
    if S.stage ~= "dropped" or (e and e ~= S.drop) or not Living(p) or not p:IsPlayer() then return false end
    if CombinePlayer(p) then return W.Destroy("pocketed") end
    W.Carry(p)
    return true
end

-- Hurt on the ground: by the Combine (players or NPCs) it bursts; by anyone else, nothing (a rebel's stray shot).
function W.HurtExtract(e, dmg)
    if W.S.stage ~= "dropped" or e ~= W.S.drop then return false end
    if Combine(dmg:GetAttacker()) or Combine(dmg:GetInflictor()) then return W.Destroy("hurt") end
    return false
end

-- A unit searches, pats down or cuffs the carrier: it goes in their pockets, and it is gone.
local function Confiscated(target, by)
    if W.S.stage == "carried" and target == W.S.carrier and Combine(by) then return W.Destroy("confiscated") end
end

-- Combine NPCs who see it on the ground drop what they are doing and go for it: shooting it where they have a clear
-- shot, running to it where not (whoever gets there first ends it).
function W.CombineSeek(now)
    local S = W.S
    local e, b = S.drop, S.bull
    if not IsValid(e) then return end
    local at = e:GetPos() + Vector(0, 0, 8)
    for _, npc in ipairs(ents.FindInSphere and ents.FindInSphere(at, W.SEE_R) or {}) do
        if IsValid(npc) and npc:IsNPC() and npc:Health() > 0 and Combine(npc) and Walker(npc) then
            local saw = npc.lcSwarmSaw == e or Seen(npc:EyePos(), at)
            if saw then
                npc.lcSwarmSaw = e
                if IsValid(b) then
                    Rel(npc, b, D_HT)
                    if npc.SetEnemy then npc:SetEnemy(b) end
                    if npc.UpdateEnemyMemory then npc:UpdateEnemyMemory(b, at) end
                    if now >= (npc.lcSwarmGoAt or 0) then npc.lcSwarmGoAt = now + 3 if npc.SetSchedule then npc:SetSchedule(SCHED_CHASE_ENEMY) end end
                else
                    Go(npc, at, true)
                end
            end
        end
    end
end

-- Stepped on by the Combine, or reached by one of their NPCs: it bursts.
function W.StompTick()
    local e = W.S.drop
    if W.S.stage ~= "dropped" or not IsValid(e) then return end
    for _, o in ipairs(ents.FindInSphere and ents.FindInSphere(e:GetPos(), W.STOMP_R) or {}) do
        if IsValid(o) and (o:IsPlayer() or o:IsNPC()) and Living(o) and Combine(o) then return W.Destroy("stamped") end
    end
end

------------------------------------------------------------------------
-- The hunt: while the guardian that came at the harvest lives, the hive comes for the essence wherever it is
------------------------------------------------------------------------

-- Where the essence is now, and who has it.
function W.Where()
    local S = W.S
    if S.stage == "carried" and Living(S.carrier) then return S.carrier:GetPos(), S.carrier end
    if (S.stage == "held" or S.stage == "ritual") and Living(S.keeper) then return S.keeper:GetPos(), S.keeper end
    if S.stage == "dropped" and IsValid(S.drop) then return S.drop:GetPos(), NearestPlayer(S.drop:GetPos(), 1500) end
    return nil
end

function W.HuntTick(now)
    local S = W.S
    if S.claim ~= nil and not Living(S.claim) then -- (the guardian is dead: the hive's claim on the essence is broken)
        S.claim, S.claimGoneAt = nil, now
    end
    if S.claimGoneAt and now - S.claimGoneAt >= 30 then S.claimGoneAt = nil BurrowAway("hunt") end
    if not S.claim then return end
    local at, target = W.Where()
    if not at then return end
    for _, e in ipairs(OfKind("hunt")) do
        local en = e.GetEnemy and e:GetEnemy()
        if IsValid(target) and not Living(en) then Hunt(e, target) end
    end
    if now < (S.huntNext or 0) then return end
    S.huntNext = now + math.Rand(W.HUNT_GAP[1], W.HUNT_GAP[2])
    local back
    if IsValid(target) and target:IsPlayer() then
        local f = target:GetAimVector()
        f = Vector(f.x, f.y, 0)
        if f:LengthSqr() > 0.01 then back = -f:GetNormalized() end
    end
    for _ = 1, 2 do
        if Count("hunt") >= W.HUNT_MAX then break end
        local spot = W.SpotNear(at, 260, 480, HULL.antlion, back)
        local e = spot and W.Antlion(spot, "hunt")
        if e and IsValid(target) then Hunt(e, target) end
    end
end

------------------------------------------------------------------------
-- The keeper and the ritual
------------------------------------------------------------------------

local function HasSeq(npc, name) return IsValid(npc) and npc.LookupSequence ~= nil and (npc:LookupSequence(name) or -1) >= 0 end

-- A scripted sequence on an NPC (as Valve's maps play the vortigaunts' own animations). Only the sequences its model
-- has; nil when it has none of them.
local function Script(npc, play, idle, flags, at, yaw, move)
    if play and not HasSeq(npc, play) then play = nil end
    if idle and not HasSeq(npc, idle) then idle = nil end
    if not (play or idle) then return nil end
    local name = npc:GetName()
    if name == "" then name = "lc_swarm_npc" .. npc:EntIndex() npc:SetName(name) end
    local ss = ents.Create("scripted_sequence")
    if not IsValid(ss) then return nil end
    ss:SetPos(at or npc:GetPos())
    ss:SetAngles(Angle(0, yaw or npc:GetAngles().y, 0))
    ss:SetKeyValue("m_iszEntity", name)
    if play then ss:SetKeyValue("m_iszPlay", play) end
    if idle then ss:SetKeyValue("m_iszPostIdle", idle) end
    ss:SetKeyValue("m_fMoveTo", tostring(move or 0))
    ss:SetKeyValue("spawnflags", tostring(flags))
    ss:Spawn()
    if ss.Activate then ss:Activate() end
    ss:Fire("BeginSequence", "", 0.05)
    return ss
end

-- The carrier hands it to a freed vortigaunt, who holds it as Episode Two's does (ep2_outland_02: "nectar_recieve",
-- then "idle_nectar", the essence on its "nectar" attachment) and stays put until the ritual.
function W.Hand(v, from)
    local S = W.S
    Uncarry()
    S.stage, S.keeper, S.bringer = "held", v, from or S.bringer
    v.lcVortNext = CurTime() + 1e6 -- (its camp life waits)
    if v.SetSchedule then v:SetSchedule(SCHED_IDLE_STAND) end
    S.holdScript = Script(v, "nectar_recieve", "idle_nectar", 32 + 64 + 128 + 256 + 512)
    local prop = ents.Create("prop_dynamic")
    if IsValid(prop) then
        prop:SetModel(ESSENCE_MODEL)
        prop:SetPos(v:GetPos() + Vector(0, 0, 40))
        prop:SetKeyValue("solid", "0")
        prop:Spawn()
        if prop.SetParent then prop:SetParent(v) end
        prop:Fire("SetParentAttachment", "nectar", 0.05)
        if ParticleEffectAttach then LC.Try(ParticleEffectAttach, "larval_extract_drip", PATTACH_ABSORIGIN_FOLLOW or 1, prop, 0) end
        S.inHand = prop
        SetGlobal2Entity("lc_swarm_inhand", prop)
    end
    v:EmitSound("outland_04.vort_remove_extract_fx")
    v:EmitSound(VORTIGESE[math.random(#VORTIGESE)], 70, 100)
    return true
end

-- How many freed vortigaunts the Resistance has, alive (the city's freed ones and the Free Vortigaunt players).
function W.FreedVorts()
    local n = 0
    for v in pairs(LC.RebelVorts or {}) do if IsValid(v) and v:Health() > 0 then n = n + 1 end end
    for _, p in ipairs(player.GetAll()) do if p:Alive() and Rebel(p) and p:GetNW2String("lcf_special", "") == "vortigaunt" then n = n + 1 end end
    return n
end
function W.DistrictsHeld()
    local n = 0
    for _, b in ipairs(LC.BlockNumbers and LC.BlockNumbers() or {}) do
        if LC.DistrictOwner and LC.DistrictOwner(b) == "resistance" then n = n + 1 end
    end
    return n
end
-- The headquarters live at the mine (the territory of the map's lc_hq_setup_cave, Ravenholm's big room).
function W.AtMine()
    if not (LC.BaseState and LC.BaseState() == "live") then return false end
    local m = Named(W.MINE)
    local s = LC.Base and LC.Base.S or {}
    if not IsValid(m) then return false end
    if LC.Base.SiteAt and s.zone and LC.Base.SiteAt(m:GetPos()) == s.zone then return true end
    return s.pos ~= nil and s.pos:DistToSqr(m:GetPos()) < 1000 * 1000
end

-- May the city fall now? (Not locked, not cooling down, not the Resistance's already, no rocket on its way.)
function W.MayFall()
    local C = LC.Chapter
    if not (C and C.S) then return false, "nochapter" end
    if C.S.state == "reversed" then return false, "already" end
    if C.S.lock then return false, "locked" end
    if (C.S.cooldown or 0) > 0 then return false, "cooldown" end
    if C.pendingAt then return false, "rocket" end
    return true
end

-- What the ritual still waits for, in as few words as will do (nil: nothing).
function W.Missing()
    local miss = {}
    if not W.AtMine() then miss[#miss + 1] = "the flag flying at the mine" end
    if W.FreedVorts() < W.NEED_VORTS then miss[#miss + 1] = W.NEED_VORTS .. " freed vortigaunts" end
    local led = LC.Ledger and LC.Ledger()
    if not (led and (led.resistance or 0) >= W.NEED_STRENGTH) then miss[#miss + 1] = "Resistance strength " .. W.NEED_STRENGTH end
    if W.DistrictsHeld() < W.NEED_DISTRICTS then miss[#miss + 1] = W.NEED_DISTRICTS .. " districts held" end
    local left = W.NEED_FLOWN - (W.clock.flown or 0)
    if left > 0 then miss[#miss + 1] = string.format("the mine's flag up %d more minutes", math.ceil(left / 60)) end
    if not W.MayFall() then miss[#miss + 1] = "a city that can fall" end
    return #miss > 0 and miss or nil
end

local function EndChant(r)
    for _, o in ipairs(r.chanters or {}) do
        if IsValid(o) then
            if o.Fire then o:Fire("TurnBlue", "0") end
            o:SetNW2Bool("lc_swarm_chant", false)
            o.lcVortNext = 0
        end
    end
    for _, ss in ipairs(r.scripts or {}) do if IsValid(ss) then ss:Fire("CancelSequence") ss:Remove() end end
    for _, p in ipairs(r.players or {}) do if IsValid(p) then p:SetNW2Bool("lc_swarm_chant", false) end end
end

-- The freed vortigaunts near the keeper gather round it, turn blue-purple (their own TurnBlue, and Valve's
-- "turn_blue" animations from ep2_outland_02 where the model has them) and chant; the Free Vortigaunt players near
-- glow with them. Without a keeper (staff): straight to the pheropods.
function W.Ritual(v, by)
    local S = W.S
    Uncarry()
    ClearDrop()
    local prefer = by or S.bringer
    if not Living(v) then
        Release(S.keeper)
        S.keeper = nil
        return W.GivePheropods(prefer)
    end
    if S.keeper ~= v then Release(S.keeper) end
    local now = CurTime()
    local r = { vort = v, by = prefer, endAt = now + W.RITUAL_SECS, chanters = { v }, next = {}, scripts = {}, players = {} }
    for o in pairs(LC.RebelVorts or {}) do
        if Living(o) and o ~= v and #r.chanters < 6 and o:GetPos():DistToSqr(v:GetPos()) < W.RITUAL_R * W.RITUAL_R then r.chanters[#r.chanters + 1] = o end
    end
    local c = v:GetPos()
    if IsValid(S.holdScript) then S.holdScript:Fire("CancelSequence") S.holdScript:Remove() S.holdScript = nil end
    for i, o in ipairs(r.chanters) do
        o.lcVortNext = now + 1e6
        if o.Fire then o:Fire("TurnBlue", "1") end
        o:SetNW2Bool("lc_swarm_chant", true)
        r.next[o] = now + (i - 1) * 0.7
        local ss
        if i == 1 then
            ss = Script(o, "turn_blue", "surgery_sustain_idle", 32 + 64 + 256 + 512)
        else
            local a = (i - 2) / math.max(1, #r.chanters - 1) * math.pi * 2
            local spot = FloorUnder(c + Vector(math.cos(a) * W.RING, math.sin(a) * W.RING, 0), 64, 192) or o:GetPos()
            local yaw = math.deg(math.atan2(c.y - spot.y, c.x - spot.x))
            ss = Script(o, "turn_blue_vort" .. ((i - 2) % 3 + 1), "surgery_sustain_idle", 32 + 64 + 256 + 512, spot, yaw, 1)
            if not ss then Go(o, spot, false) end
        end
        if ss then r.scripts[#r.scripts + 1] = ss end
    end
    for _, p in ipairs(player.GetAll()) do
        if p:GetNW2String("lcf_special", "") == "vortigaunt" and p:GetPos():DistToSqr(c) < W.RITUAL_R * W.RITUAL_R then
            p:SetNW2Bool("lc_swarm_chant", true)
            r.players[#r.players + 1] = p
        end
    end
    S.stage, S.keeper, S.ritual = "ritual", v, r
    if LC.Log then LC.Log("info", "swarm: the vortigaunts' ritual begins") end
    return true
end

function W.RitualTick(now)
    local S = W.S
    local r = S.ritual
    if S.stage ~= "ritual" or not r then return end
    if not Living(r.vort) then -- (the keeper is dead: the extract falls where it stood)
        EndChant(r)
        S.ritual = nil
        local at = IsValid(r.vort) and r.vort:GetPos() or r.lastPos
        if at then W.Drop(at) else W.Home() end
        return
    end
    r.lastPos = r.vort:GetPos()
    for _, o in ipairs(r.chanters) do
        if Living(o) and now >= (r.next[o] or 0) then
            r.next[o] = now + math.Rand(2.2, 3.2)
            o:EmitSound(VORTIGESE[math.random(#VORTIGESE)], 75, math.random(92, 104))
        end
    end
    if now >= r.endAt then
        EndChant(r)
        S.ritual = nil
        Release(r.vort)
        S.keeper = nil
        W.GivePheropods(r.by)
    end
end

-- E on a freed vortigaunt (also asked by its vest charge's own E, sv_livingcity_resistanceops.lua, so the order the
-- game's hooks answer in does not matter): the carrier hands the extract over; a Resistance player at its keeper
-- starts the ritual, or is told in one line what it still waits for. false: not ours (the vest charge goes on).
function W.UseVort(p, v)
    local S = W.S
    if not (IsValid(v) and LC.RebelVorts and LC.RebelVorts[v] and Living(p) and p:IsPlayer()) then return false end
    local mine = (S.stage == "carried" and p == S.carrier) or ((S.stage == "held" or S.stage == "ritual") and v == S.keeper and Rebel(p))
    if not mine then return false end
    if (p.lcSwarmUseAt or 0) > CurTime() then return true end -- (one press, however long E is held)
    p.lcSwarmUseAt = CurTime() + 1
    if S.stage == "carried" then return W.Hand(v, p) end
    if S.stage == "held" then
        if not cvOn:GetBool() then return true end
        local miss = W.Missing()
        if miss then
            Tell(p, "Still needed: " .. table.concat(miss, ", ") .. ".")
            return true
        end
        return W.Ritual(v, S.bringer or p)
    end
    return true -- (the ritual under way)
end

------------------------------------------------------------------------
-- The pheropods
------------------------------------------------------------------------

-- The highest-ranking Resistance player online; ties to prefer (who brought the extract), then the longest online.
function W.PickHolder(prefer)
    local best, br, bt
    for _, p in ipairs(player.GetAll()) do
        if Rebel(p) then
            local r = p:GetNW2Int("lcf_rank", 1)
            local t = p.TimeConnected and p:TimeConnected() or 0
            local better = not best or r > br
            if not better and r == br then better = p == prefer or (best ~= prefer and t > bt) end
            if better then best, br, bt = p, r, t end
        end
    end
    return best
end

local function GiveBait(p)
    if Living(p) and not (LC.IsTied and LC.IsTied(p)) and not p:HasWeapon("weapon_bugbait") then p:Give("weapon_bugbait") end
end
local function TakeBait(p)
    if not IsValid(p) then return end
    p:SetNW2Bool("lc_swarm_holder", false)
    if p.StripWeapon then p:StripWeapon("weapon_bugbait") end
end

function W.SetHolder(p, first)
    local S = W.S
    if IsValid(S.holder) and S.holder ~= p then TakeBait(S.holder) end
    S.holder = p
    if not IsValid(p) then return end
    p:SetNW2Bool("lc_swarm_holder", true)
    GiveBait(p)
    local down = W.AllStopped()
    if down then S.toldDown = true end
    Tell(p, down and "The pheropods are yours. Take the swarm to the Nexus." or "The pheropods are yours. Stop the city's thumpers.")
    if first then TellRebels(p:Nick() .. (down and " has the pheropods." or " has the pheropods. Stop the city's thumpers."), p) end
end

function W.GivePheropods(prefer)
    local S = W.S
    S.made, S.stage, S.toldDown = true, "pheropods", nil
    S.swarmNext = CurTime()
    W.SetHolder(W.PickHolder(prefer), true)
    if LC.Log then LC.Log("info", "swarm: the pheropods go to " .. Nick(S.holder)) end
    return S.holder
end

-- Squeezed (right click): the swarm comes to the holder.
function W.Squeeze(p)
    local S = W.S
    if S.stage ~= "pheropods" or p ~= S.holder then return false end
    local w = p:GetActiveWeapon()
    if not (IsValid(w) and w:GetClass() == "weapon_bugbait") or CurTime() < (p.lcSqueezeNext or 0) then return false end
    p.lcSqueezeNext = CurTime() + 1
    local at = p:GetPos()
    for _, e in ipairs(OfKind("swarm")) do Go(e, at + Vector(math.random(-90, 90), math.random(-90, 90), 0), true) end
    for e in pairs(LC.Antlions and LC.Antlions.out or {}) do if Living(e) and e.lcSwarmFriend then Go(e, at, true) end end
    return true
end

-- Thrown: where it bursts more of them dig up and go for what it hit (unless it is one of the Resistance's own), then
-- for any other enemy near; thrown at nothing, the swarm goes there and fights what it finds.
function W.BaitBurst(pos, by)
    local S = W.S
    if S.stage ~= "pheropods" or not IsValid(S.holder) then return nil end
    if IsValid(by) and by ~= S.holder then return nil end
    local target, td
    for _, e in ipairs(ents.FindInSphere and ents.FindInSphere(pos, 72) or {}) do
        if IsValid(e) and (e:IsPlayer() or e:IsNPC()) and e ~= S.holder and Living(e) and e:GetClass() ~= "npc_antlion" and e:GetClass() ~= "npc_bullseye" then
            local d = e:GetPos():DistToSqr(pos)
            if not td or d < td then target, td = e, d end
        end
    end
    local swarm = OfKind("swarm")
    local near = {}
    for _, e in ipairs(swarm) do if e:GetPos():DistToSqr(pos) < 1500 * 1500 then near[#near + 1] = e end end
    local made = 0
    for _ = 1, W.EXTRA do
        if #swarm >= W.SWARM_CAP then break end
        local spot = W.SpotNear(pos, 40, 200, HULL.antlion, nil, NearRunningThumper)
        local e = spot and W.Antlion(spot, "swarm")
        if e then W.Befriend(e) swarm[#swarm + 1] = e near[#near + 1] = e made = made + 1 end
    end
    local mark = IsValid(target) and not Friendly(target)
    for _, e in ipairs(mark and near or swarm) do
        if mark then Hunt(e, target) else Go(e, pos, true) end
    end
    return target, made
end

function W.SwarmNear(pos, r)
    for _, e in ipairs(OfKind("swarm")) do if e:GetPos():DistToSqr(pos) < r * r then return true end end
    return false
end

-- As at Nova Prospekt: with every thumper down and the holder in the city, they dig up near the holder a few at a
-- time, follow, and go for the Combine on their own. Never within a running thumper's reach.
function W.SwarmTick(now, h)
    local S = W.S
    for e in pairs(LC.Antlions and LC.Antlions.out or {}) do if Living(e) and not e.lcSwarmFriend and not e.lcSwarmWild then W.Befriend(e) end end
    local list = OfKind("swarm")
    if now >= (S.befriendAt or 0) then
        S.befriendAt = now + 5
        for _, e in ipairs(list) do W.Befriend(e) end
    end
    if not Living(h) then return end
    local hp = h:GetPos()
    if W.AllStopped() and W.InCity(hp) and not NearRunningThumper(hp) and now >= (S.swarmNext or 0) then
        S.swarmNext = now + W.SWARM_EVERY
        for _ = 1, 3 do
            if #list >= W.SWARM_MAX then break end
            local spot = W.SpotNear(hp, 220, 520, HULL.antlion, nil, NearRunningThumper)
            local e = spot and W.Antlion(spot, "swarm")
            if e then W.Befriend(e) list[#list + 1] = e end
        end
    end
    if now >= (S.followAt or 0) then
        S.followAt = now + 3
        for _, e in ipairs(list) do
            local en = e.GetEnemy and e:GetEnemy()
            if not Living(en) then
                local foe = W.FoeNear(e:GetPos(), 1200)
                if foe then Hunt(e, foe)
                elseif e:GetPos():DistToSqr(hp) > 500 * 500 then Go(e, hp + Vector(math.random(-120, 120), math.random(-120, 120), 0), true) end
            end
        end
    end
end

------------------------------------------------------------------------
-- The fall, and after it
------------------------------------------------------------------------

-- The event instead of the rocket's flash: antlions burst up on the Combine across the city, the ground shakes. No words.
function W.FallBurst()
    local targets = {}
    for _, npc in ipairs(LC.ChapterCombineNPCs and LC.ChapterCombineNPCs() or {}) do if Living(npc) then targets[#targets + 1] = npc end end
    for _, p in ipairs(player.GetAll()) do if p:Alive() and LC.ChapterIsUnit and LC.ChapterIsUnit(p) then targets[#targets + 1] = p end end
    local n = 0
    for _, t in ipairs(targets) do
        if n >= W.FALL_MAX then break end
        local spot = W.SpotNear(t:GetPos(), 40, 140, HULL.antlion)
        local e = spot and W.Antlion(spot, "fall")
        if e then
            n = n + 1
            W.Befriend(e)
            Hunt(e, t)
            if util.Effect and EffectData then
                local ed = EffectData()
                ed:SetOrigin(spot)
                ed:SetScale(48)
                util.Effect("ThumperDust", ed)
            end
        end
    end
    return n
end

-- The holder in the Nexus with the swarm (or staff, whatever the lock and the cooldown say): the burst, and a moment
-- later the chapter's own begin, with why "swarm" (whatever lc_chapter says: that is the rocket's switch).
function W.Fall(by, staff)
    local S = W.S
    if LC.ChapterReversed and LC.ChapterReversed() then return false, "already" end
    if S.falling then return false, "falling" end
    if not staff then
        local ok, why = W.MayFall()
        if not ok then return false, why end
    end
    S.falling = { by = by, at = CurTime() + W.FALL_DELAY }
    W.FallBurst()
    net.Start("lc_swarm_fall")
    net.Broadcast()
    return true
end

-- The city has fallen (to the swarm; or by the rocket while the pheropods were out): the pheropods are destroyed for
-- good (none again this map), their antlions are nobody's now, and the thumpers the saboteurs left stopped are broken.
function W.Destroyed(why)
    local S = W.S
    if why ~= "swarm" and S.stage ~= "pheropods" then return false end
    TakeBait(S.holder)
    S.holder, S.stage, S.made, S.fallen = nil, "gone", true, true
    Uncarry()
    Release(S.keeper)
    S.keeper = nil
    ClearDrop()
    for e, k in pairs(S.out) do
        if k == "swarm" or k == "fall" then
            if IsValid(e) then W.Wild(e) end
            S.out[e] = nil
        end
    end
    for e in pairs(LC.Antlions and LC.Antlions.out or {}) do if IsValid(e) and e.lcSwarmFriend then W.Wild(e) end end
    S.broken = {}
    for _, th in ipairs(W.StoppedThumpers()) do S.broken[th] = true end
    if next(S.broken) ~= nil and LC.PostDirective then LC.PostDirective("res_thumpers", nil, true) end
    if LC.Log then LC.Log("info", "swarm: the pheropods are destroyed; the antlions are wild") end
    return true
end
hook.Add("LivingCityChapterBegan", "LivingCitySwarm", function(why) LC.Try(W.Destroyed, why) end)
-- (the Combine have the city back: they see to their own thumpers)
hook.Add("LivingCityChapterEnded", "LivingCitySwarm", function() W.S.fallen, W.S.broken = false, {} end)

------------------------------------------------------------------------
-- The mine's flag clock (kept over restarts)
------------------------------------------------------------------------

local function ClockFile() return "livingcity/" .. game.GetMap() .. "_swarm.json" end
function W.ClockLoad()
    local t = LC.SafeReadJSON and LC.SafeReadJSON(ClockFile())
    W.clock = { flown = math.max(0, tonumber(istable(t) and t.flown) or 0) }
    return W.clock
end
function W.ClockSave()
    if not (file and file.Write and LC.SafeWrite) then return end
    if file.CreateDir then file.CreateDir("livingcity") end
    LC.SafeWrite(ClockFile(), util.TableToJSON({ flown = math.floor(W.clock.flown or 0) }, true))
end
W.clock = W.clock or W.ClockLoad()
local function ClockReset()
    if (W.clock.flown or 0) > 0 then W.clock.flown = 0 W.ClockSave() end
end
-- It runs while the flag flies at the mine (overrun, at half mast, it stands); a ransack, a strike or a move starts it again.
function W.ClockTick(now, dt)
    if not W.AtMine() then return end
    W.clock.flown = (W.clock.flown or 0) + dt
    if now >= (W.clockSaveAt or 0) then W.clockSaveAt = now + 60 W.ClockSave() end
end
hook.Add("LivingCityBaseGone", "LivingCitySwarm", function(_, how) if how == "ransacked" or how == "packed" then LC.Try(ClockReset) end end)
hook.Add("LivingCityBaseLive", "LivingCitySwarm", function() if not W.AtMine() then LC.Try(ClockReset) end end)

------------------------------------------------------------------------
-- Restart the thumpers (the Resistance's job while the city is theirs after the swarm)
------------------------------------------------------------------------

-- The city is the Resistance's (the chapter).
function W.CityOurs() return LC.ChapterReversed ~= nil and LC.ChapterReversed() end

-- Where to mend a thumper: at its own button (its console), else at the thumper.
function W.ThumperConsole(th)
    local b = LC.Antlions and LC.Antlions.PartOf and LC.Antlions.PartOf(th, "button")
    if IsValid(b) then return b:WorldSpaceCenter() end
    return th:GetPos()
end

local Q = LC.QB
if Q and LC.QuestTemplates then
    LC.QuestTemplates[#LC.QuestTemplates + 1] = {
        id = "res_thumpers", brings = false, factions = { resistance = true }, squad = 4,
        available = function() return W.S.fallen == true and W.CityOurs() and #W.StoppedThumpers() > 0 end,
        over = function()
            if not (W.S.fallen and W.CityOurs()) then return false, "the city is not ours now" end
            if #W.StoppedThumpers() == 0 then return true end -- (every thumper runs: it pays, whoever started the last)
        end,
        build = function(ply)
            local left, list = W.StoppedThumpers(), {}
            local from = IsValid(ply) and ply:GetPos() or Vector(0, 0, 0)
            while #left > 0 do -- (each next the nearest to the last)
                local bi, bd
                for i, th in ipairs(left) do
                    local d = th:GetPos():DistToSqr(from)
                    if not bd or d < bd then bi, bd = i, d end
                end
                local th = table.remove(left, bi)
                list[#list + 1] = th
                from = th:GetPos()
            end
            if #list == 0 then return nil end
            local stages = {}
            for _, th in ipairs(list) do
                local at = W.ThumperConsole(th)
                stages[#stages + 1] = Q.GameGo(at, "Get to the stopped thumper (marked)", "wiring", { what = "the thumper", pos = at }, 140)
                local mend = Q.GameStage("Mend its wiring")
                mend.onDone = function() W.S.broken[th] = nil end
                stages[#stages + 1] = mend
                local start = Q.Count("thumper_started", 1, "Start it with its button")
                start.pos, start.untallied, start.thumper = at, true, th
                start.relay = LC.Antlions and LC.Antlions.PartOf and LC.Antlions.PartOf(th, "start")
                start.poll = function(q, st) if not W.Stopped(st.thumper) then Q.Advance(q) end end
                stages[#stages + 1] = start
            end
            return {
                title = "Restart the thumpers", reward = 40 + 20 * #list, limit = 600 + 300 * #list,
                desc = "The antlions are coming into the city. Mend each stopped thumper and start it again.",
                stages = stages,
            }
        end,
    }
end

-- A broken thumper's start (its button triggers the copy's start relay): nothing but a fizzle, until it is mended.
local function Fizzle(ent)
    local th = LC.Antlions and LC.Antlions.PartOf and LC.Antlions.PartOf(ent, "head")
    if not W.Broken(th) then return false end
    ent:EmitSound("ambient/energy/spark" .. math.random(1, 6) .. ".wav", 70, 100)
    return true
end

------------------------------------------------------------------------
-- Every second, and every tenth
------------------------------------------------------------------------

function W.Tick(now)
    local S = W.S
    local dt = math.Clamp(now - (W.lastTick or now), 0, 5)
    W.lastTick = now
    W.ClockTick(now, dt)
    -- the door's guardian
    if S.doorGuard ~= nil and not Living(S.doorGuard) then S.doorGuard, S.doorGuardDied, S.doorChargeAt = nil, now, nil end
    if S.doorChargeAt and now >= S.doorChargeAt then DoorCharge() end
    -- the carrier
    if S.stage == "carried" then
        local p = S.carrier
        if not IsValid(p) then W.Drop(S.carrierAt or Vector(0, 0, 0))
        elseif CombinePlayer(p) then W.Destroy("pocketed")
        else S.carrierAt = p:GetPos() end
    elseif S.stage == "held" then
        local v = S.keeper
        if Living(v) then S.keeperAt = v:GetPos() v.lcVortNext = now + 1e6
        else W.Drop(IsValid(v) and v:GetPos() or S.keeperAt or Vector(0, 0, 0)) end
    elseif S.stage == "dropped" then
        if not IsValid(S.drop) or now - (S.dropAt or now) >= W.DROP_SECS then W.Home() else W.CombineSeek(now) end
    end
    W.HuntTick(now)
    W.RitualTick(now)
    if S.stage == "pheropods" then
        local h = S.holder
        if not (IsValid(h) and Rebel(h)) then W.SetHolder(W.PickHolder(nil), false) h = S.holder end
        if IsValid(h) then GiveBait(h) end
        if not S.toldDown and #W.Thumpers() > 0 and W.AllStopped() then
            S.toldDown = true
            TellRebels("The thumpers are down. Take the swarm to the Nexus.")
        end
        W.SwarmTick(now, h)
        if Living(h) and cvOn:GetBool() and not S.falling and W.AllStopped() and W.InNexus(h:GetPos()) and W.SwarmNear(h:GetPos(), 3000) and W.MayFall() then
            W.Fall(h)
        end
        for _, w in ipairs(ents.FindByClass and ents.FindByClass("weapon_bugbait") or {}) do -- (never left lying about)
            if IsValid(w) and not IsValid(w:GetOwner()) then w:Remove() end
        end
    end
    if S.falling and now >= S.falling.at then
        local by = S.falling.by
        S.falling = nil
        if LC.ChapterBegin then LC.ChapterBegin("swarm", by) end
    end
end

timer.Create("LivingCitySwarm", 1, 0, function()
    if LC.Running == false then return end
    local ok, err = LC.Try(W.Tick, CurTime())
    if not ok and LC.Error then LC.Error("swarm", err) end
end)
timer.Create("LivingCitySwarmHold", 0.1, 0, function()
    if not (W.S.harvest or W.S.stage == "dropped") then return end
    LC.Try(W.HarvestTick, CurTime())
    LC.Try(W.StompTick)
end)

------------------------------------------------------------------------
-- What the game tells us
------------------------------------------------------------------------

hook.Add("AcceptInput", "LivingCitySwarm", function(ent, input, activator)
    if not IsValid(ent) then return end
    local what = string.lower(input or "")
    if what ~= "trigger" and what ~= "add" then return end
    local name = string.lower(tostring(ent.GetName and ent:GetName() or ""))
    if name == "lc_nest_count" and what == "add" then -- (a press of one of the emergency door's two buttons)
        if IsValid(activator) and activator:IsPlayer() then W.S.pressers[activator] = CurTime() end
    elseif name == "lc_nest_opened" and what == "trigger" then
        LC.Try(W.DoorOpened, IsValid(activator) and activator:IsPlayer() and activator or nil)
    elseif what == "trigger" and LC.Antlions and LC.Antlions.Parse then
        local _, part = LC.Antlions.Parse(name)
        if part == "start" then
            local ok, broken = LC.Try(Fizzle, ent)
            if ok and broken then return true end -- (the relay does nothing)
        end
    end
end)

hook.Add("KeyPress", "LivingCitySwarm", function(p, key)
    if key == IN_USE then
        if W.S.stage == "nest" then LC.Try(W.TryHarvest, p)
        elseif W.S.stage == "dropped" and IsValid(W.S.drop) and LookingAt(p, W.S.drop:GetPos() + Vector(0, 0, 6), 96) then LC.Try(W.UseExtract, p, W.S.drop) end
    elseif key == (IN_ATTACK2 or 2048) then
        LC.Try(W.Squeeze, p)
    end
end)

hook.Add("PlayerUse", "LivingCitySwarm", function(p, ent)
    if not IsValid(ent) then return end
    if ent == W.S.drop then LC.Try(W.UseExtract, p, ent) return false end
    if LC.RebelVorts and LC.RebelVorts[ent] then
        local ok, mine = LC.Try(W.UseVort, p, ent)
        if ok and mine then return false end
    end
end)

hook.Add("EntityTakeDamage", "LivingCitySwarm", function(ent, dmg)
    if IsValid(ent) and ent == W.S.drop then LC.Try(W.HurtExtract, ent, dmg) end
end)

hook.Add("PlayerDeath", "LivingCitySwarm", function(p)
    if W.S.stage == "carried" and p == W.S.carrier then LC.Try(W.Drop, p:GetPos()) end
end)
hook.Add("PlayerDisconnected", "LivingCitySwarm", function(p)
    W.S.pressers[p] = nil
    if W.S.stage == "carried" and p == W.S.carrier then LC.Try(W.Drop, p:GetPos()) end
    if p == W.S.holder then W.S.holder = nil end -- (the next highest gets them on the next tick)
end)

hook.Add("PlayerCanPickupWeapon", "LivingCitySwarm", function(p, w)
    if W.S.stage == "pheropods" and IsValid(w) and w:GetClass() == "weapon_bugbait" and p ~= W.S.holder then return false end
end)

hook.Add("LivingCitySearched", "LivingCitySwarm", function(searcher, target) LC.Try(Confiscated, target, searcher) end)
hook.Add("LivingCityPattedDown", "LivingCitySwarm", function(target, by) LC.Try(Confiscated, target, by) end)
hook.Add("LivingCityTied", "LivingCitySwarm", function(target, by) LC.Try(Confiscated, target, by) end)

-- A thrown pheropod: where it bursts (Valve's npc_grenade_bugbait takes itself away on touching something).
hook.Add("OnEntityCreated", "LivingCitySwarm", function(e)
    if IsValid(e) and e:GetClass() == "npc_grenade_bugbait" then W.S.grenades[e] = true end
end)
hook.Add("EntityRemoved", "LivingCitySwarm", function(e)
    if W.S.grenades[e] then
        W.S.grenades[e] = nil
        LC.Try(W.BaitBurst, e:GetPos(), e.GetOwner and e:GetOwner() or nil)
    end
end)

-- Over: the pheropods back, the antlions dig down, the extract back in the nest (staff; the city stopped). The door's
-- guardian is the map's and stays.
function W.End()
    local S = W.S
    W.HarvestStop()
    if S.ritual then EndChant(S.ritual) end
    TakeBait(S.holder)
    Uncarry()
    Release(S.keeper)
    ClearDrop()
    for e, k in pairs(S.out) do
        if IsValid(e) and k ~= "guard" then
            if e.Fire then e:Fire("BurrowAway", "", math.Rand(0, 1)) else e:Remove() end
        end
    end
    for e in pairs(S.wild) do if IsValid(e) and e:Health() > 0 and e.Fire then e:Fire("BurrowAway", "", math.Rand(0, 1)) end end
    local guards = {}
    for e, k in pairs(S.out) do if k == "guard" and IsValid(e) then guards[e] = k end end
    local dg, died = S.doorGuard, S.doorGuardDied
    W.S = Fresh()
    W.S.out, W.S.doorGuard, W.S.doorGuardDied = guards, dg, died
    W.ShowEssence(true)
    return true
end

local function Forget()
    for e in pairs(W.S.out) do if IsValid(e) then e:Remove() end end
    for e in pairs(W.S.wild) do if IsValid(e) then e:Remove() end end
    ClearDrop()
    Release(W.S.keeper)
    TakeBait(W.S.holder)
    Uncarry()
    W.S, W.essence = Fresh(), nil
end
hook.Add("LivingCityStopped", "LivingCitySwarm", Forget)
hook.Add("PostCleanupMap", "LivingCitySwarm", function() W.S, W.essence = Fresh(), nil end)
hook.Add("ShutDown", "LivingCitySwarm", function() if (W.clock.flown or 0) > 0 then W.ClockSave() end end)

------------------------------------------------------------------------
-- Staff: F4 > Factions > Admin: testing tools > The city (sv_livingcity_admintools.lua)
------------------------------------------------------------------------

-- What staff see under the lines.
function W.Status()
    local S = W.S
    local line
    if S.stage == "nest" then
        line = IsValid(W.Essence()) and "The extract is in the nest." or "This map has no antlion nest."
    elseif S.stage == "carried" then
        line = Nick(S.carrier) .. " carries the extract."
    elseif S.stage == "dropped" then
        line = string.format("The extract lies where it fell (back in the nest in %d min).", math.max(0, math.ceil((W.DROP_SECS - (CurTime() - (S.dropAt or CurTime()))) / 60)))
    elseif S.stage == "held" then
        local miss = W.Missing()
        line = "A freed vortigaunt holds the extract." .. (miss and (" Still needed: " .. table.concat(miss, ", ") .. ".") or " Everything is ready.")
    elseif S.stage == "ritual" then
        line = string.format("The vortigaunts' ritual: %d s left.", math.max(0, math.ceil((S.ritual and S.ritual.endAt or CurTime()) - CurTime())))
    elseif S.stage == "pheropods" then
        line = string.format("%s holds the pheropods. Thumpers stopped: %d of %d. The swarm: %d.", Nick(S.holder), #W.StoppedThumpers(), #W.Thumpers(), Count("swarm"))
    else
        local n = 0
        for th in pairs(S.broken) do if IsValid(th) then n = n + 1 end end
        line = string.format("The city fell to the swarm: the pheropods are gone, %d thumpers broken.", n)
    end
    if S.claim then line = line .. " The hive hunts it while the chamber's guardian lives." end
    if Living(S.doorGuard) then line = line .. " The door's guardian is out."
    elseif S.doorGuardDied and CurTime() - S.doorGuardDied < W.GUARD_AGAIN then
        line = line .. string.format(" The door's next guardian in %d min.", math.ceil((W.GUARD_AGAIN - (CurTime() - S.doorGuardDied)) / 60))
    end
    line = line .. string.format(" The mine's flag: %d of %d min.", math.floor((W.clock.flown or 0) / 60), W.NEED_FLOWN / 60)
    if not cvOn:GetBool() then line = line .. " (lc_swarm is 0: nothing starts by itself.)" end
    return { stage = S.stage, line = line }
end

-- Staff's own: the extract, the ritual, the fall, the end (whatever lc_swarm and the conditions say).
function W.StaffExtract(admin)
    W.End()
    W.ShowEssence(false)
    W.Carry(admin)
    return true
end
function W.StaffRitual(admin)
    local S = W.S
    local prefer = S.bringer or S.carrier
    if S.stage == "pheropods" or S.stage == "gone" or S.stage == "ritual" then W.End() end
    W.ShowEssence(false)
    local v = S.keeper
    if not Living(v) then
        local best, bd
        for o in pairs(LC.RebelVorts or {}) do
            if Living(o) then
                local d = IsValid(admin) and o:GetPos():DistToSqr(admin:GetPos()) or 0
                if not bd or d < bd then best, bd = o, d end
            end
        end
        v = best
    end
    return W.Ritual(v, prefer)
end

if LC.ADMIN_ACTIONS then
    LC.ADMIN_ACTIONS.swarm = function(_, v, admin)
        if IsValid(admin) and not admin:IsSuperAdmin() then return false, "Superadmins only." end
        if v == "extract" then
            if not IsValid(admin) then return false, "Nobody to give it to." end
            W.StaffExtract(admin)
            return true, "You carry the larval extract."
        elseif v == "ritual" then
            W.StaffRitual(admin)
            if W.S.stage == "ritual" then return true, "The vortigaunts' ritual: the pheropods go to the highest rank in 15 s." end
            return true, IsValid(W.S.holder) and ("The pheropods go to " .. W.S.holder:Nick() .. ".") or "No Resistance player is online: the pheropods wait for one."
        elseif v == "fall" then
            local ok, why = W.Fall(admin, true)
            if not ok then return false, why == "already" and "The city is the Resistance's already." or "It is falling already." end
            return true, "The swarm: the city falls to the Resistance."
        elseif v == "end" then
            W.End()
            return true, "The swarm is over: the pheropods taken back, the antlions gone, the extract in the nest."
        end
        return false, "Swarm: extract, ritual, fall or end?"
    end
end
