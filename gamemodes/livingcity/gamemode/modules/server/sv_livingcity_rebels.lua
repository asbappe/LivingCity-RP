--[[
    Living City: the Resistance on the street

    Rebel territory isn't empty any more. A few armed Resistance fighters live
    in each rebel zone: they mill about, keep watch, and defend it.

      Defending   anyone who looks like Combine (a unit, Overwatch, the
                  Administrator, or someone in a convincing CP uniform) who walks
                  into rebel territory gets a shout first ("Combine!"), then
                  gets shot at. Resistance players are always friends; ordinary
                  citizens are left alone unless they start shooting.
      Raids       now and then a few fighters slip out and hit the nearest
                  checkpoint or patrol beat. Units nearby draw pistols and fight.
      Sweeps      now and then Civil Protection sends an armed team into rebel
                  territory. The rebels there fight back.

    Skirmishes are SOMETIMES, not constantly: one every lc_skirmish_interval
    minutes on average, never two at once, and never with nobody on the server.

    Guerrillas, not an army. They don't open up on the Combine the moment it's
    in sight: a unit has to come onto their ground and within about 1100
    units to be shouted at (then shot at within 1500, or 900 unseen), and the
    city's own units within 1000 (one that has only wandered in, 650). Out of
    their territory they keep their heads down: the city's units notice an
    armed rebel within lc_units_spot_rebels units (600) and open fire, so
    they keep their distance (sv_livingcity_rebellife.lua).

    Fighters who follow you (E on one, Members and up) stay with you before
    anything else: they never stop to chase or take cover. They hold their
    fire until it's on: anything Combine shooting at you or at them, anything
    you shoot at, units hunting the Resistance, and the usual on rebel
    ground. Then they shoot as they go, and stand and fire whenever they're
    already at your side. They climb ladders after you, and one who falls
    far behind catches up out of sight.

      lc_rebels <n>              fighters kept across the rebel zones (4)
      lc_skirmishes 0/1          raids and sweeps (1)
      lc_skirmish_interval <m>   average minutes between skirmishes (50: one every 40 to 60)
      lc_rebel_damage <x>        damage multiplier for rebel NPCs shooting players (0.5)
      lc_rebel_warning <s>       seconds of shouting before they open fire on a unit (2)
      lc_skirmish raid|sweep     start one now (admin)
      lc_units_spot_rebels <u>   how close a unit notices an armed rebel off rebel ground (600; 0 never)

    Lookout posts: the editor's "Point: rebel lookout post" keeps an armed
    fighter standing guard there, facing the way the point faces (whoever
    placed it). Combine coming his way (a unit, Overwatch, a convincing
    uniform, the city's own units) gets a shout and a warning on Freq 7 from
    lc_lookout_post_warn units out (1400); come within lc_lookout_post_fire
    (650), or into rebel ground, and he opens fire. He holds his post, and
    goes back to it after a fight. Killed, he's replaced after
    lc_lookout_post_respawn seconds (120), out of sight.
]]

if CLIENT then return end

LC = LC or {}
LC.Thinkers = LC.Thinkers or {}

local FLAGS = bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED)
local cvRebels   = CreateConVar("lc_rebels", "4", FLAGS, "Resistance fighters kept in rebel territory, spread across the rebel zones")
local cvSkirm    = CreateConVar("lc_skirmishes", "1", FLAGS, "Rebels sometimes raid the Combine, and the Combine sometimes sweeps rebel territory")
local cvSweepLead = CreateConVar("lc_sweep_warning", "90", FLAGS, "Seconds Civil Protection and Overwatch players hear (and get a job to join it) before a sweep team moves into rebel territory (0: no warning)")
local cvRaidLead = CreateConVar("lc_raid_warning", "90", FLAGS, "Seconds the Resistance's own hear (and get a job to back it up) before their fighters hit the Combine (0: no warning)")
local cvSkirmInt = CreateConVar("lc_skirmish_interval", "50", FLAGS, "Average minutes between skirmishes (each one comes 20% either side of it)")
-- the old default (9) was far too busy: a server still on it moves to the new one
timer.Simple(5, function() if cvSkirmInt:GetFloat() == 9 then RunConsoleCommand("lc_skirmish_interval", "50") end end)
local cvDamage   = CreateConVar("lc_rebel_damage", "0.5", FLAGS, "Damage multiplier for Resistance NPCs shooting players")
local cvHomeHurt = CreateConVar("lc_rebel_home_hurt", "1", FLAGS, "Damage multiplier for rebels who aren't following a player (1: as tough as a player's squad; 2: half as tough)")
-- (the owner, 9 November: weaker than the Combine, no armour and no training, but not too weak; and slightly more of them)
local cvHealth   = CreateConVar("lc_rebel_health", "50", FLAGS, "Health of Resistance fighter NPCs (Half-Life 2's own: 40)")
local cvPerUnit  = CreateConVar("lc_rebel_per_combine", "1.25", FLAGS, "At least this many Resistance fighters for every Combine NPC on the streets (0: just lc_rebels and the rest)")
local cvWarn     = CreateConVar("lc_rebel_warning", "2", FLAGS, "Seconds the Resistance shouts before opening fire on a Civil Protection unit in their territory")
local cvPostWarn = CreateConVar("lc_lookout_post_warn", "1400", FLAGS, "How far a rebel lookout post sees the Combine coming (and warns Freq 7)")
local cvPostFire = CreateConVar("lc_lookout_post_fire", "650", FLAGS, "How close the Combine can come to a rebel lookout post before he opens fire")
local cvPostRe   = CreateConVar("lc_lookout_post_respawn", "120", FLAGS, "Seconds before a killed rebel lookout is replaced")
local cvSpotReb  = CreateConVar("lc_units_spot_rebels", "600", FLAGS, "How close a Civil Protection unit has to be to notice an armed rebel outside rebel ground, and open fire (0: never)")

-- Guerrillas, not an army: how close the Combine has to come before they act.
local SPOT_RANGE   = 1100 -- a unit on our ground seen this close: the shout goes up
local FIRE_RANGE   = 1500 -- after the shout: anyone in sight this close...
local CLOSE_RANGE  = 900  -- ...or anyone this close on our ground, seen or not
local NPC_RANGE    = 1000 -- the city's own units on our ground (come for a fight, or sweeping it)
local NPC_RAID     = 1300 -- on a raid
local NPC_STRAY    = 650  -- a unit that's only wandered in
local SQUAD_RANGE  = 1600 -- fighters out with someone, once it's on
local FOLLOW_CLOSE = 140  -- this close to the one they follow: stop walking, fight from here
local FOLLOW_RUN   = 260  -- further than this: run
local FOLLOW_STRAND = 12  -- seconds on another level from the one they follow (and no way up): they catch up, unseen
local LADDER_MT    = MOVETYPE_LADDER or 9

local SF_NPC_GAG                 = 2
local SF_NPC_FADE_CORPSE         = 512
local SF_NPC_NO_WEAPON_DROP      = 8192
local SF_CITIZEN_NOT_COMMANDABLE = 1048576

local UP = Vector(0, 0, 50)
local SECURITY_CLASSES = { "npc_metropolice", "npc_combine_s", "npc_cscanner" }

local function Pick(t) return t[math.random(#t)] end
local function Vo(st, name) return "vo/npc/" .. (st.gender or "male") .. "01/" .. name .. ".wav" end

-- (the owner: rebels never carry pulse rifles; SMGs, now and then a shotgun, and (9 November) a few crossbow marksmen)
local WEAPONS = { { "weapon_smg1", 70 }, { "weapon_shotgun", 20 }, { "weapon_crossbow", 10 } }
local function PickWeapon()
    local total = 0
    for _, w in ipairs(WEAPONS) do total = total + w[2] end
    local r = math.random() * total
    for _, w in ipairs(WEAPONS) do
        r = r - w[2]
        if r <= 0 then return w[1] end
    end
    return "weapon_smg1"
end

local SPOTTED = { "combine01", "combine02" } -- "Combine!"
local NAMES_M = { "Arne", "Bogdan", "Dmitri", "Emil", "Feliks", "Gregor", "Ivo", "Jakub", "Karel", "Lev", "Milan", "Oskar", "Pavel", "Stefan", "Tomas", "Viktor" }
local NAMES_F = { "Alena", "Daria", "Eva", "Hana", "Irina", "Jana", "Katya", "Lena", "Marta", "Nadia", "Olga", "Petra", "Sonja", "Vera", "Zora" }

------------------------------------------------------------------------
-- Who's who
------------------------------------------------------------------------

local function RebelZones() return LC.ZonesOfKindShared and LC.ZonesOfKindShared("rebel") or {} end
local function ZoneAt(pos, margin) return LC.RebelZoneAt(pos, margin) end -- (sv_livingcity_paths.lua)

local function IsResistance(ply)
    return ply:GetNW2String("lcf_faction", "") == "resistance" or (LC.DisguisedAsRebel and LC.DisguisedAsRebel(ply)) or false
end

-- Looks like the enemy to a rebel. A Resistance member in a stolen uniform is
-- still one of ours: they know their own.
local function LooksCombine(ply)
    if not IsValid(ply) or not ply:IsPlayer() or not ply:Alive() or IsResistance(ply) then return false end
    if ply:GetNW2Bool("lc_build", false) then return false end -- an admin building the map
    if LC.InCustody and LC.InCustody(ply) then return false end
    if LC.Prisoners and LC.Prisoners[ply] then return false end
    return LC.LooksCombine and LC.LooksCombine(ply) or LC.PlayerIsCP(ply)
end

local function Alive(e)
    if not IsValid(e) then return false end
    if e:IsPlayer() then return e:Alive() end
    return e:Health() > 0
end

local function CanSee(npc, e, range)
    local d2 = npc:GetPos():DistToSqr(e:GetPos())
    if d2 > range * range then return false end
    local tr = util.TraceLine({ start = npc:EyePos(), endpos = e:EyePos(), mask = MASK_OPAQUE, filter = npc })
    if LC.SmokeBlocks and LC.SmokeBlocks(npc:EyePos(), e:EyePos()) then return false end -- nobody sees through smoke
    return tr.Fraction > 0.97 or tr.Entity == e
end

-- How many fighters a zone has room for: one for every lc_rebel_room square (its floor area,
-- a box's or a circle's), at least one. A small camp isn't packed wall to wall.
local cvRoom = CreateConVar("lc_rebel_room", "350", FLAGS, "Room each Resistance fighter needs in rebel territory (units: one for every this-by-this square of a zone); a small zone gets fewer")

-- Open floor, not a doorway or a narrow hallway (the owner, 7 November: fighters crammed into doorways,
-- hallways and walkways): a hull the size of a person goes r units clear in at least three of the four
-- directions. A corridor or a doorway lets it through two, opposite each other, and fails.
local ROOM_MINS, ROOM_MAXS = Vector(-13, -13, 0), Vector(13, 13, 56)
local ROOM_DIRS = { Vector(1, 0, 0), Vector(-1, 0, 0), Vector(0, 1, 0), Vector(0, -1, 0) }
function LC.RoomAround(pos, r)
    r = r or 44
    local base = pos + Vector(0, 0, 10)
    local free = 0
    for _, d in ipairs(ROOM_DIRS) do
        local tr = util.TraceHull({ start = base, endpos = base + d * r, mins = ROOM_MINS, maxs = ROOM_MAXS, mask = MASK_NPCSOLID_BRUSHONLY })
        if tr and not tr.Hit and not tr.StartSolid then free = free + 1 end
    end
    return free >= 3
end

-- A spot in a zone with room round it, if a few tries find one (the last spot tried otherwise).
function LC.RoomySpot(z, tries)
    local last
    for _ = 1, tries or 5 do
        local p = LC.SpotInZone(z)
        if p then
            if LC.RoomAround(p) then return p, true end
            last = p
        end
    end
    return last, false
end

-- How much of a zone's floor is open (sampled, kept five minutes): a camp that is mostly walls and
-- hallways has room for fewer than its area says. Never below a quarter.
local function OpenFraction(z)
    local now = CurTime()
    local c = z.lcOpen
    if c and now < c.till then return c.f end
    local found, roomy = 0, 0
    for _ = 1, 16 do
        local p = LC.SpotInZone(z)
        if p then
            found = found + 1
            if LC.RoomAround(p) then roomy = roomy + 1 end
        end
    end
    local f = found >= 6 and math.max(0.25, roomy / found) or 1
    z.lcOpen = { f = f, till = now + 300 }
    return f
end

function LC.RebelRoomIn(z)
    local area
    if z.box then
        area = math.abs(z.box.maxs.x - z.box.mins.x) * math.abs(z.box.maxs.y - z.box.mins.y)
    elseif z.cells then
        area = (z.n or 0) * LCZ.CELL * LCZ.CELL -- (grown ground: its cells)
    else
        area = math.pi * (z.r or 300) ^ 2
    end
    return math.max(1, math.floor(area * OpenFraction(z) / math.max(50, cvRoom:GetFloat()) ^ 2))
end

-- The Combine's NPCs out on the streets (not those posted inside their own buildings, nor test units).
function LC.CombineStreetCount()
    local n = 0
    for npc, st in pairs(LC.NPCs or {}) do
        if (st.role == "cop" or st.role == "soldier") and not st.garrison and not st.test and not st.desperationTest
            and IsValid(npc) and npc:Health() > 0 then n = n + 1 end
    end
    return n
end

function LC.RebelTarget()
    if #RebelZones() == 0 then return 0 end
    -- more ground, more fighters (sv_livingcity_territory.lua), but never more than the zones have room for
    local want = math.max(0, cvRebels:GetInt()) + (LC.GrownCount and LC.GrownCount("rebel") or 0)
        + (LC.MarketRebelBonus and LC.MarketRebelBonus() or 0) -- (each Commissary restriction, another joins them: sv_livingcity_market.lua)
        + (LC.ImbalanceRebels or 0) -- (the Combine's players far outnumbering the Resistance's: sv_livingcity_imbalance.lua)
    -- (the owner, 9 November: "slightly more resistance NPCs than combine"): never fewer than lc_rebel_per_combine for each
    -- Combine NPC on the streets (still within the zones' room, the Resistance's reserve and the NPC cap)
    local per = math.max(0, cvPerUnit:GetFloat())
    if per > 0 then want = math.max(want, math.ceil(per * LC.CombineStreetCount() - 1e-6)) end
    local room = 0
    for _, z in ipairs(RebelZones()) do room = room + LC.RebelRoomIn(z) end
    return math.min(want, room)
end

------------------------------------------------------------------------
-- Spawning
------------------------------------------------------------------------

local function CountIn(zone)
    local n = 0
    for npc, st in pairs(LC.NPCs) do
        if IsValid(npc) and st.role == "rebel" and st.zone == zone and not st.raid then n = n + 1 end
    end
    return n
end
LC.RebelsIn = CountIn

-- A spot inside a zone nobody can see right now (or, if anyone, then any spot).
local function HiddenSpot(z, allowSeen)
    local cramped
    for _ = 1, 10 do
        local p = LC.SpotInZone(z)
        if p and LC.FarFromPlayers(p, 300) and not LC.IsSeen(p + UP) then
            if LC.RoomAround(p) then return p end -- (open floor first: not a doorway)
            cramped = cramped or p
        end
    end
    if cramped then return cramped end
    if allowSeen then return (LC.RoomySpot(z)) end
    return nil
end

-- Called by the population code: the emptiest rebel zone, out of sight.
function LC.RebelSpawnPos()
    local zones = LC.ZonesOfKind("rebel") -- (our own copy: sorted below)
    if #zones == 0 then return nil end
    table.sort(zones, function(a, b) return CountIn(a) < CountIn(b) end)
    local now = CurTime()
    for _, z in ipairs(zones) do
        -- (no goto here: "continue" is a keyword in Garry's Mod's Lua)
        -- (nor on ground a team is clearing: LC.QuietRebels, sv_livingcity_fieldops.lua)
        if (z.contestedUntil or 0) <= now and CountIn(z) < LC.RebelRoomIn(z) and not (LC.RebelQuietZone and LC.RebelQuietZone(z)) then
            local p = HiddenSpot(z)
            if p then return p + Vector(0, 0, 4), z end
        end
    end
    return nil
end

local function SpawnRebel(pos, zone, weapon)
    -- (from the Resistance's reserve: none left, nobody comes: sv_livingcity_manpower.lua)
    if LC.ManpowerCan and not LC.ManpowerCan("rebel") then return end
    local npc = ents.Create("npc_citizen")
    if not IsValid(npc) then return end
    npc:SetPos(pos)
    npc:SetAngles(Angle(0, math.random(0, 359), 0))
    npc:SetKeyValue("citizentype", "3") -- the Resistance's own clothes
    npc:SetKeyValue("additionalequipment", weapon or PickWeapon())
    npc:SetKeyValue("spawnflags", tostring(SF_CITIZEN_NOT_COMMANDABLE + SF_NPC_GAG + SF_NPC_FADE_CORPSE + SF_NPC_NO_WEAPON_DROP))
    npc:Spawn()
    npc:Activate()
    local hp = math.max(1, math.floor(cvHealth:GetFloat()))
    if npc.SetMaxHealth then npc:SetMaxHealth(hp) end
    npc:SetHealth(hp)
    if LC.FilterSpeech then LC.FilterSpeech(npc) end
    -- peace with the Combine by default: fights are picked deliberately, below
    for _, cls in ipairs(SECURITY_CLASSES) do npc:AddRelationship(cls .. " D_NU 99") end
    local st = LC.RegisterNPC(npc, "rebel")
    if LC.ManpowerTake then LC.ManpowerTake(npc, st, "rebel") end
    st.zone = zone or ZoneAt(pos, 200)
    st.gender = string.find(string.lower(npc:GetModel() or ""), "female", 1, true) and "female" or "male"
    st.leaveAt = nil
    st.nextLook = 0
    LC.SetNPCStr(npc, "lc_pname", Pick(st.gender == "female" and NAMES_F or NAMES_M))
    LC.SetNPCStr(npc, "lc_pjob", "Resistance")
    npc:SetNW2Bool("lc_prebel", true)
    for _, ply in ipairs(player.GetAll()) do
        LC.SetRel(npc, st, ply, LC.RebelDisposition(npc, st, ply, LC.PlayerIsZombie and LC.PlayerIsZombie(ply)))
    end
    return npc, st
end
LC.SpawnRebel = SpawnRebel
LC.Spawners = LC.Spawners or {}
LC.Spawners.rebel = function(pos, zone) return SpawnRebel(pos, zone) end

-- Make sure at least n fighters are in a zone (the Missing Unit's retaliation,
-- an Overwatch incursion). Extras drift away again later, unseen.
function LC.ReinforceRebels(z, n)
    if not z or not LC.Running then return 0 end
    local made = 0
    for _ = 1, math.max(0, n - CountIn(z)) do
        local p = HiddenSpot(z, true)
        if not p then break end
        local npc, st = SpawnRebel(p + Vector(0, 0, 4), z)
        if IsValid(npc) then
            st.unmanaged = true
            st.expires = CurTime() + 900
            made = made + 1
        end
    end
    return made
end

-- Too many for the space (the owner, 7 November: about twenty in a small camp, "crammed like
-- sardines"): a zone with more fighters at home than it has room for (lc_rebel_room) loses the
-- extras, unseen, the ones who came for something first. Fighters out with a player, on a raid,
-- at a post, the quartermaster and anyone in a fight are left alone.
function LC.RebelTrimCrowds(now)
    now = now or CurTime()
    local removed = 0
    for _, z in ipairs(RebelZones()) do
        local home = {}
        for npc, st in pairs(LC.NPCs) do
            if IsValid(npc) and st.role == "rebel" and st.zone == z and npc:Health() > 0 and not st.test and not st.questLock
                and not st.raid and not st.skirmish and not st.follow and not st.post and not st.quartermaster
                and not st.errand and not st.foe and not st.returning then
                home[#home + 1] = { npc, st }
            end
        end
        local over = #home - LC.RebelRoomIn(z)
        -- (not on ground a team is retaking: the fighters holding it are the ones they've come to clear)
        if over > 0 and not (LC.RebelQuietZone and LC.RebelQuietZone(z)) then
            -- the extras first (reinforcements, raiders back home), then anyone out of sight
            table.sort(home, function(a, b)
                local ua, ub = a[2].unmanaged and 1 or 0, b[2].unmanaged and 1 or 0
                if ua ~= ub then return ua > ub end
                return (a[2].expires or 0) < (b[2].expires or 0)
            end)
            for _, h in ipairs(home) do
                if over <= 0 then break end
                local npc, st = h[1], h[2]
                if not LC.IsSeen(npc:GetPos() + UP) then
                    if st.life and LC.RebelLifeEnd then LC.RebelLifeEnd(npc, st) end
                    LC.NPCs[npc] = nil
                    npc:Remove()
                    over = over - 1
                    removed = removed + 1
                end
            end
        end
    end
    return removed
end
timer.Create("LivingCityRebelCrowd", 30, 0, function()
    if not LC.Running then return end
    local ok, err = pcall(LC.RebelTrimCrowds, CurTime())
    if not ok and LC.Error then LC.Error("rebel crowds", err) end
end)

------------------------------------------------------------------------
-- Relationships
------------------------------------------------------------------------

function LC.RebelDisposition(npc, st, ply, zombie)
    if zombie then return D_HT end
    if st.foe == ply then return D_HT end
    if IsValid(ply) and ply:GetNW2Float("lc_traitor_until", 0) > CurTime() then return D_HT end -- an informer (sv_livingcity_resistanceops.lua)
    if IsResistance(ply) then return D_LI end
    return D_NU
end

-- A rebel zone that's on alert (someone shouted, someone's fighting): the
-- people at home put down what they're doing (sv_livingcity_rebellife.lua).
local zoneAlert = setmetatable({}, { __mode = "k" }) -- [zone] = { at, pos }
local function Alert(z, pos, now)
    if z then zoneAlert[z] = { at = now, pos = pos } end
end
function LC.RebelZoneAlert(z)
    local a = z and zoneAlert[z]
    if a and CurTime() - a.at < 25 then return a end
    return nil
end
LC.RebelAlert = Alert

-- Who's shooting at a fighter's leader (or at his fighters), and what the
-- leader shoots at: that's who the squad fires on.
LC.SquadMarks = LC.SquadMarks or setmetatable({}, { __mode = "k" }) -- [leader] = { [ent] = until }
local function MarkForSquad(leader, e, now, secs)
    if not IsValid(leader) or not IsValid(e) or e == leader then return end
    local m = LC.SquadMarks[leader] or setmetatable({}, { __mode = "k" })
    LC.SquadMarks[leader] = m
    m[e] = math.max(m[e] or 0, now + (secs or 25))
end
LC.MarkForSquad = MarkForSquad

-- A Combine NPC that's being shot at shoots back.
local function ProvokeBack(npc, e, now)
    local est = LC.NPCs[e]
    if est and LC.IsSecurity(est) and est.state ~= "hostile" then
        LC.ArmUnit(e, est)
        LC.MakeOneHostile(e, est, npc)
        est.provokedBy, est.provokedUntil = npc, now + 120
    elseif est and est.role == "scanner" then
        e:AddEntityRelationship(npc, D_FR, 99)
    end
end

-- Back to neutral with whoever they were fighting (no change of what they're doing).
local function ClearFoe(npc, st)
    local e = st.foe
    st.foe = nil
    if IsValid(e) then
        if e:IsPlayer() then
            LC.SetRel(npc, st, e, LC.RebelDisposition(npc, st, e, LC.PlayerIsZombie and LC.PlayerIsZombie(e)))
        else
            npc:AddEntityRelationship(e, D_NU, 99)
        end
    end
    npc:SetEnemy(NULL)
    npc:ClearEnemyMemory()
end

-- A fighter out with someone: the enemy is set, and the walking goes on
-- (whoever they follow comes first; they shoot as they go).
local function Engage(npc, st, e, now)
    if st.foe ~= e then
        if st.foe then ClearFoe(npc, st) end
        st.foe, st.foeSince = e, now
        if e:IsPlayer() then LC.SetRel(npc, st, e, D_HT)
        else
            npc:AddEntityRelationship(e, D_HT, 99)
            ProvokeBack(npc, e, now)
        end
    end
    if npc:GetEnemy() ~= e then npc:SetEnemy(e) end
    if npc.UpdateEnemyMemory then npc:UpdateEnemyMemory(e, e:GetPos()) end
end

local function SetFoe(npc, st, e, now)
    if LC.RebelLifeEnd and st.life then LC.RebelLifeEnd(npc, st) end
    if st.follow then
        MarkForSquad(st.follow, e, now, 25)
        st.foeSeen = now
        return Engage(npc, st, e, now)
    end
    if st.errand then -- (the box goes down, the gun comes up; home, once this is over)
        st.errand.aborted = true
        if LC.RebelErrandDrop then LC.RebelErrandDrop(npc, st) end
    end
    if not st.raid and not st.post and st.zone then Alert(st.zone, e:GetPos(), now) end
    if st.foe == e then return end
    st.foe = e
    st.foeSince = now
    if e:IsPlayer() then
        LC.SetRel(npc, st, e, D_HT)
    else
        npc:AddEntityRelationship(e, D_HT, 99)
        -- and they know it
        ProvokeBack(npc, e, now)
    end
    npc:SetEnemy(e)
    if npc.UpdateEnemyMemory then npc:UpdateEnemyMemory(e, e:GetPos()) end
    if npc:IsCurrentSchedule(SCHED_FORCED_GO) or npc:IsCurrentSchedule(SCHED_FORCED_GO_RUN) then
        npc:SetSchedule(SCHED_CHASE_ENEMY) -- a walking schedule ignores enemies
    end
    LC.SetState(npc, st, "fighting")
end
LC.RebelSetFoe = SetFoe

local function DropFoe(npc, st, now)
    ClearFoe(npc, st)
    LC.SetState(npc, st, "idle")
    st.untilT = now + math.Rand(1, 3)
end

-- A unit sent at rebels needs more than a stick.
function LC.ArmUnit(npc, st)
    if st.armed or st.role ~= "cop" then return end
    st.armed = true
    local gun = math.random() < 0.7 and "weapon_pistol" or "weapon_smg1"
    if gun == "weapon_pistol" and LC.DesperateSidearm then gun = LC.DesperateSidearm(st) end -- (an SMG when desperate: sv_livingcity_desperation.lua)
    st.hasPistol, st.sidearm = true, gun
    npc:Give(gun)
    if npc.SelectWeapon then npc:SelectWeapon(gun) end
end

------------------------------------------------------------------------
-- Thinking
------------------------------------------------------------------------

-- Combine NPCs a rebel should shoot: anyone in rebel territory, anyone taking
-- part in a skirmish, and (on a raid) any unit near the target.
local function NPCThreat(npc, st, range)
    local pos = npc:GetPos()
    local best, bd
    for other, ost in pairs(LC.NPCs) do
        if IsValid(other) and (LC.IsSecurity(ost) or ost.role == "scanner") and other:Health() > 0 then
            local d = other:GetPos():DistToSqr(pos)
            if d < range * range and (not bd or d < bd) then
                local relevant = ost.skirmish ~= nil or st.raid ~= nil
                if not relevant and ZoneAt(other:GetPos(), 0) then
                    -- on our ground: one that's come for a fight, or (closer) one that's only wandered in
                    relevant = ost.state == "hostile" or ost.state == "sweep" or d < NPC_STRAY * NPC_STRAY
                end
                if relevant and CanSee(npc, other, range) then best, bd = other, d end
            end
        end
    end
    return best
end

-- Spotting a unit in rebel territory: the first rebel to see them shouts,
-- and after a moment everyone in the zone opens fire.
local alarms = {} -- [ply] = { at = time first spotted, zone = zone }
LC.RebelAlarms = alarms

local function PlayerThreat(npc, st, now)
    local home = st.zone
    local npos = npc:GetPos()
    for _, ply in ipairs(player.GetAll()) do
        -- nothing below reaches past FIRE_RANGE: the distance first, then who they look like
        if ply:GetPos():DistToSqr(npos) < FIRE_RANGE * FIRE_RANGE and LooksCombine(ply) then
            local z = ZoneAt(ply:GetPos(), 0) -- inside it, to the line (no mercy on rebel ground)
            local onRaid = st.raid ~= nil
            if (z and (z == home or not home)) or onRaid then
                local a = alarms[ply]
                if a and now - a.at < (cvWarn:GetFloat() + 0.01) then
                    -- still shouting
                elseif a then
                    if CanSee(npc, ply, FIRE_RANGE) or (z and npc:GetPos():DistToSqr(ply:GetPos()) < CLOSE_RANGE * CLOSE_RANGE) then return ply end
                elseif CanSee(npc, ply, SPOT_RANGE) then
                    alarms[ply] = { at = now, zone = z }
                    Alert(z or home, ply:GetPos(), now)
                    npc:EmitSound(Vo(st, Pick(SPOTTED)), 85)
                    LC.Face(npc, ply:GetPos())
                    ply:ChatPrint("[Resistance] Someone shouts: 'Combine! In the yard!' You've been seen.")
                    if cvWarn:GetFloat() <= 0 then return ply end
                end
            end
        end
    end
    return nil
end

-- the alarm calls itself off once the unit is gone
timer.Create("LivingCityRebelAlarms", 3, 0, function()
    for ply, a in pairs(alarms) do
        if not IsValid(ply) or not ply:Alive() or not LooksCombine(ply) or not ZoneAt(ply:GetPos(), 900) then alarms[ply] = nil end
    end
end)

local function Wander(npc, st, now)
    local z = st.zone
    if not z then return end
    local spot = LC.RoomySpot(z) -- (somewhere with room: not a doorway or a hallway)
    if not spot then st.untilT = now + 5 return end
    st.dest = spot
    npc:SetLastPosition(spot)
    npc:SetSchedule(SCHED_FORCED_GO)
    LC.SetState(npc, st, "moving")
    st.untilT = now + 25
end

local function HeadFor(npc, st, pos, run)
    local sched = run and SCHED_FORCED_GO_RUN or SCHED_FORCED_GO
    if not st.goingTo or st.goingTo:DistToSqr(pos) > 100 * 100 or not npc:IsCurrentSchedule(sched) then
        st.goingTo = pos
        npc:SetLastPosition(pos)
        npc:SetSchedule(sched)
    end
end
LC.RebelHeadFor = HeadFor
LC.RebelCanSee = CanSee
LC.RebelLooksCombine = LooksCombine

------------------------------------------------------------------------
-- Following someone: before anything else
------------------------------------------------------------------------

-- Fallen far behind, and nobody's looking: put them just behind whoever
-- they're following, where that person can't see it happen either (for
-- rebel fighters and for people a quest has following you).
function LC.FollowCatchUp(npc, leader)
    if not IsValid(npc) or not IsValid(leader) then return false end
    local now = CurTime()
    if (npc.lcCatchUpAt or 0) > now then return false end
    npc.lcCatchUpAt = now + 2
    if LC.IsSeen(npc:GetPos() + UP) then return false end
    local lpos = leader:GetPos()
    local back = leader:GetForward() * -1
    back.z = 0
    if back:LengthSqr() < 0.01 then back = Vector(-1, 0, 0) end
    back:Normalize()
    local right = Vector(-back.y, back.x, 0)
    for _, dist in ipairs({ 150, 240, 340 }) do
        for _, side in ipairs({ 0, 60, -60 }) do
            local p = lpos + back * dist + right * side
            local g = LC.GroundAt and LC.GroundAt(p + Vector(0, 0, 30)) or p
            if math.abs(g.z - lpos.z) < 48 and LC.ClearSpot(g) and not LC.IsSeen(g + UP) then
                -- in the same space as them, not behind a wall
                local tr = util.TraceLine({ start = lpos + Vector(0, 0, 40), endpos = g + Vector(0, 0, 40), mask = MASK_NPCSOLID_BRUSHONLY, filter = leader })
                if tr.Fraction > 0.97 then
                    npc:SetPos(g + Vector(0, 0, 4))
                    if npc.SetSchedule then npc:SetSchedule(SCHED_IDLE_STAND) end
                    return true
                end
            end
        end
    end
    return false
end

-- Who a fighter out with someone shoots at, once it's on.
local function SquadThreat(npc, st, leader, now)
    local pos = npc:GetPos()
    local best, bd
    local function consider(e)
        if not IsValid(e) or e == leader or e == npc or not Alive(e) then return end
        local d = e:GetPos():DistToSqr(pos)
        if d < SQUAD_RANGE * SQUAD_RANGE and (not bd or d < bd) and CanSee(npc, e, SQUAD_RANGE) then best, bd = e, d end
    end
    -- whoever's shooting at the leader or at us, and whatever the leader shoots at
    local marks = LC.SquadMarks[leader]
    if marks then
        for e, untilT in pairs(marks) do
            if not IsValid(e) or untilT < now or not Alive(e) then marks[e] = nil else consider(e) end
        end
    end
    -- units out for the Resistance's blood
    for other, ost in pairs(LC.NPCs) do
        if IsValid(other) and LC.IsSecurity(ost) and ost.state == "hostile" and IsValid(ost.enemy) then
            local en = ost.enemy
            local enst = LC.NPCs[en]
            if en == leader or (enst and enst.role == "rebel") or (en:IsPlayer() and IsResistance(en)) then consider(other) end
        end
    end
    -- and on rebel ground, the usual: units who've been shouted at, units who've come in
    for ply, a in pairs(alarms) do
        if IsValid(ply) and now - a.at > cvWarn:GetFloat() and LooksCombine(ply) then consider(ply) end
    end
    if ZoneAt(pos, 300) then consider(NPCThreat(npc, st, NPC_RANGE)) end
    return best
end

-- Acting casual: guns put away, plain clothes on, walking like anyone else. Units take
-- them for citizens (they don't open fire on what they don't see). Shot at, or the leader
-- in a fight: guns out, all of them.
function LC.SquadCasual(npc, st, on)
    if not IsValid(npc) or not st then return end
    if on and not st.casual then
        st.casual = true
        local m = npc:GetModel() or ""
        if string.find(m, "group03", 1, true) then
            st.preCasualModel = m
            local plain = string.gsub(string.gsub(m, "group03m", "group01"), "group03", "group01")
            if not util.IsValidModel or util.IsValidModel(plain) then npc:SetModel(plain) end
        end
        local w = npc.GetActiveWeapon and npc:GetActiveWeapon()
        if IsValid(w) and w.SetNoDraw then w:SetNoDraw(true) end
        npc:SetNW2Bool("lc_casual", true)
        if st.foe then DropFoe(npc, st, CurTime()) end
    elseif not on and st.casual then
        st.casual = nil
        if st.preCasualModel then npc:SetModel(st.preCasualModel) st.preCasualModel = nil end
        local w = npc.GetActiveWeapon and npc:GetActiveWeapon()
        if IsValid(w) and w.SetNoDraw then w:SetNoDraw(false) end
        npc:SetNW2Bool("lc_casual", false)
    end
end
-- The whole squad of a leader, one way or the other.
function LC.SquadCasualAll(leader, on)
    local n = 0
    for _, f in ipairs(LC.FollowersOf and LC.FollowersOf(leader) or {}) do
        local fst = LC.NPCs[f]
        if fst and (fst.casual or false) ~= on then LC.SquadCasual(f, fst, on) n = n + 1 end
    end
    return n
end

local FOLLOW_ANGLES = { 0, 38, -38 }
local function FollowThink(npc, st, now)
    local leader = st.follow
    local pos = npc:GetPos()
    if not IsValid(leader) or not leader:Alive() or not IsResistance(leader) or (not st.meetAt and leader:GetPos():DistToSqr(pos) > 4000 * 4000) then
        LC.DismissFollower(npc, st, true)
        return false -- (and on with the rest of the think: home)
    end
    -- sent ahead to meet the leader at the job's destination: there, loitering, till the leader turns up
    if st.meetAt then
        st.nextThink = now + 0.5
        if leader:GetPos():DistToSqr(st.meetAt) < 350 * 350 and leader:GetPos():DistToSqr(pos) < 600 * 600 then
            st.meetAt = nil
            leader:ChatPrint("[Resistance] " .. LC.NPCStr(npc, "lc_pname", "A fighter") .. " falls in with you.")
        elseif pos:DistToSqr(st.meetAt) > 140 * 140 then
            HeadFor(npc, st, st.meetAt, false)
            LC.SetState(npc, st, "moving")
            return true
        else
            if npc:IsCurrentSchedule(SCHED_FORCED_GO) or npc:IsCurrentSchedule(SCHED_FORCED_GO_RUN) then npc:SetSchedule(SCHED_IDLE_STAND) end
            st.goingTo = nil
            LC.SetState(npc, st, "idle")
            return true
        end
    end
    st.nextThink = now + 0.2 -- quicker than the usual: they keep up
    if npc.CapabilitiesAdd and CAP_MOVE_SHOOT and not st.moveShoot then
        st.moveShoot = true
        npc:CapabilitiesAdd(CAP_MOVE_SHOOT) -- (and fire while they run)
    end

    -- who to shoot at, twice a second
    if now >= (st.nextLook or 0) then
        st.nextLook = now + 0.5
        local foe = SquadThreat(npc, st, leader, now)
        if foe and st.casual then
            -- under fire: guns out, all of them
            if LC.SquadCasualAll(leader, false) > 0 then leader:ChatPrint("[Resistance] Your squad pull their guns out.") end
        end
        if foe then
            Engage(npc, st, foe, now)
            st.foeSeen = now
        elseif st.foe and now - (st.foeSeen or 0) > 4 then
            ClearFoe(npc, st)
        end
    end
    local e = st.foe
    if e and not Alive(e) then ClearFoe(npc, st) e = nil end
    if e then
        if npc:GetEnemy() ~= e then npc:SetEnemy(e) end
        if npc.UpdateEnemyMemory then npc:UpdateEnemyMemory(e, e:GetPos()) end
    end
    LC.SetState(npc, st, e and "fighting" or "moving")

    local lpos = leader:GetPos()
    -- on another level from them: by a ladder if there's one, and if there
    -- isn't (or they can't get to it) they catch up, once nobody's looking
    if math.abs(lpos.z - pos.z) > 64 then
        st.apartSince = st.apartSince or now
        if now - st.apartSince > FOLLOW_STRAND and LC.FollowCatchUp(npc, leader) then
            st.goingTo, st.apartSince = nil, nil
            return true
        end
        if LC.LadderToward then
            -- a leader still on the ladder: the follower goes to its end and waits there
            -- (up they go the moment the leader's off it, not before: the leader may be coming back down)
            local climbing = leader.GetMoveType and leader:GetMoveType() == LADDER_MT
            local near, far = LC.LadderToward(pos, lpos, climbing)
            if near then
                if Vector(pos.x - near.x, pos.y - near.y, 0):LengthSqr() < 90 * 90 and math.abs(pos.z - near.z) < 72 then
                    if climbing then
                        if npc:IsCurrentSchedule(SCHED_FORCED_GO) or npc:IsCurrentSchedule(SCHED_FORCED_GO_RUN) then npc:SetSchedule(SCHED_IDLE_STAND) end
                        st.goingTo = nil
                    else
                        npc:SetPos(far + Vector(0, 0, 6))
                        npc:SetSchedule(SCHED_IDLE_STAND)
                        npc:EmitSound("player/footsteps/ladder" .. math.random(1, 4) .. ".wav", 70)
                        st.goingTo = nil
                    end
                else
                    HeadFor(npc, st, near, true)
                end
                return true
            end
        end
    else
        st.apartSince = nil
    end

    local d2 = lpos:DistToSqr(pos)
    -- fallen far behind, and nobody's looking: they catch up
    if d2 > 1400 * 1400 and LC.FollowCatchUp(npc, leader) then
        st.goingTo = nil
        return true
    end
    local slot = st.followSlot or 0
    local close = FOLLOW_CLOSE + slot * 30
    if d2 > close * close then
        -- a spot just behind them, each fighter his own
        local dir = pos - lpos
        dir.z = 0
        if dir:LengthSqr() < 1 then dir = leader:GetForward() * -1 dir.z = 0 end
        if dir:LengthSqr() < 0.01 then dir = Vector(-1, 0, 0) end
        dir:Normalize()
        local a = math.rad(FOLLOW_ANGLES[slot + 1] or 0)
        local c, s = math.cos(a), math.sin(a)
        dir = Vector(dir.x * c - dir.y * s, dir.x * s + dir.y * c, 0)
        local goal = lpos + dir * (70 + slot * 25)
        local v = leader.GetVelocity and leader:GetVelocity() or Vector(0, 0, 0)
        local leaderRunning = v:Length2D() > (leader.GetWalkSpeed and leader:GetWalkSpeed() or 110) + 20
        HeadFor(npc, st, goal, e ~= nil or leaderRunning or d2 > FOLLOW_RUN * FOLLOW_RUN)
    else
        -- at their side: stop; with an enemy in sight, stand and fire from here
        local walking = npc:IsCurrentSchedule(SCHED_FORCED_GO) or npc:IsCurrentSchedule(SCHED_FORCED_GO_RUN)
        local shoot = e and SCHED_RANGE_ATTACK1 and CanSee(npc, e, SQUAD_RANGE)
        if shoot and not npc:IsCurrentSchedule(SCHED_RANGE_ATTACK1) then
            npc:SetSchedule(SCHED_RANGE_ATTACK1)
        elseif walking then
            npc:SetSchedule(SCHED_IDLE_STAND)
        end
        st.goingTo = nil
        if not e and now > (st.untilT or 0) then
            st.untilT = now + 3
            LC.Face(npc, lpos + leader:GetForward() * 300) -- looking the way they look
        end
    end
    return true
end

-- Crouched with nothing to crouch for (a scavenging or gardening animation that ended, or the
-- engine's own taking cover): back on their feet.
local CROUCHED = {}
for _, n in ipairs({ "ACT_COVER_LOW", "ACT_CROUCHIDLE", "ACT_CROUCH", "ACT_WALK_CROUCH", "ACT_RUN_CROUCH", "ACT_COVER_SMG1_LOW",
    "ACT_RANGE_AIM_SMG1_LOW", "ACT_RANGE_AIM_PISTOL_LOW", "ACT_RANGE_AIM_LOW", "ACT_WALK_CROUCH_AIM", "ACT_RUN_CROUCH_AIM" }) do
    if _G[n] then CROUCHED[_G[n]] = true end
end
local function StandUp(npc, st, now)
    if (st.nextStandCheck or 0) > now then return end
    st.nextStandCheck = now + 2
    if st.foe or st.state == "fighting" or st.state == "hostile" or st.life or st.sneak or not npc.GetActivity then return end
    if CROUCHED[npc:GetActivity()] then
        npc:SetSchedule(SCHED_IDLE_STAND)
        if npc.SetIdealActivity and ACT_IDLE then npc:SetIdealActivity(ACT_IDLE) end
    end
end
LC.RebelStandUp = StandUp

local function ThinkRebel(npc, st, now)
    if (st.stunnedUntil or 0) > now then return end -- flashbanged
    -- cuffed, or in a cell (arrested with the baton: sv_livingcity_arrest.lua)
    if (st.state == "detained" or st.state == "jailed") and LC.PrisonerThink and LC.PrisonerThink(npc, st, now) then return end
    if st.fleeingUntil and LC.FleeThink and LC.FleeThink(npc, st, now) then return end -- (broke free, and running)
    StandUp(npc, st, now)
    if st.state == "event" then
        if now > (st.eventUntil or 0) then LC.SetState(npc, st, "idle"); st.untilT = now + 1 end
        return
    end
    local pos = npc:GetPos()
    -- off on something else: whatever they were doing at home is put down first (sv_livingcity_rebellife.lua)
    if st.life and LC.RebelLifeEnd and (st.follow or st.raid or st.foe or st.post or st.quartermaster or st.returning or st.errand) then
        LC.RebelLifeEnd(npc, st)
    end
    if st.errand and LC.RebelErrandEnd and (st.follow or st.raid or st.post or st.quartermaster) then LC.RebelErrandEnd(npc, st) end

    -- their territory was removed in the editor: move to another, or leave
    if st.zone and not table.HasValue(RebelZones(), st.zone) then
        local zones = RebelZones()
        if st.quartermaster then npc:Remove() return end -- his post is gone; a new one is set up where the zones are
        if #zones == 0 then
            if not LC.IsSeen(pos + UP) then npc:Remove() end
            return
        end
        st.zone = ZoneAt(pos, 2000) or Pick(zones)
    end

    -- an extra who has outstayed the reason they came: slip away unseen
    if st.expires and now > st.expires and not st.foe and not LC.IsSeen(pos + UP) then
        if CountIn(st.zone) > math.ceil(LC.RebelTarget() / math.max(1, #RebelZones())) or not st.zone then
            npc:Remove()
            return
        end
        st.expires, st.unmanaged, st.eventNPC = nil, nil, nil -- stays on as one of the regulars
    end

    -- out with a Resistance player: staying with them comes first, fighting included
    -- (but never a quartermaster or a lookout: they're let go and stay where they are needed)
    if st.follow and (st.quartermaster or st.post) then LC.DismissFollower(npc, st, true) end
    if st.follow and FollowThink(npc, st, now) then return end

    -- the current fight
    local e = st.foe
    if e then
        local gone = not Alive(e) or e:GetPos():DistToSqr(pos) > (st.raid and 3000 or 2500) ^ 2
        if not gone and e:IsPlayer() and e ~= st.provokedBy and not st.raid then
            -- a unit is only fair game while they're in (or right by) our territory
            gone = not LooksCombine(e) or (not ZoneAt(e:GetPos(), 900)
                and not (st.post and e:GetPos():DistToSqr(st.post.pos) < (cvPostWarn:GetFloat() + 200) ^ 2))
        end
        if gone then
            DropFoe(npc, st, now)
        else
            if npc:GetEnemy() ~= e then npc:SetEnemy(e) end
            if npc.UpdateEnemyMemory then npc:UpdateEnemyMemory(e, e:GetPos()) end
            -- a lookout fights from his post; defenders don't chase anyone far out of their territory
            if st.post and pos:DistToSqr(st.post.pos) > 350 * 350 then
                HeadFor(npc, st, st.post.pos, true)
            elseif not st.post and not st.raid and st.zone and not LCZ.Within(st.zone, pos, 1.4) then
                HeadFor(npc, st, LCZ.Heart(st.zone), true) -- (out on an errand: home, fighting as they go)
            elseif not CanSee(npc, e, 2500) and now - (st.lastChase or 0) > 3 then
                st.lastChase = now
                npc:SetLastPosition(e:GetPos())
                npc:SetSchedule(SCHED_FORCED_GO_RUN)
            elseif npc:IsCurrentSchedule(SCHED_FORCED_GO_RUN) and CanSee(npc, e, 1500) then
                npc:SetSchedule(SCHED_CHASE_ENEMY)
            end
            return
        end
    end
    if st.provokedBy and now > (st.provokedUntil or 0) then st.provokedBy = nil end

    -- asleep, and a unit comes right up (the owner, 1 November: the whole camp slept through a metrocop in
    -- the yard): footsteps close by wake them, closer still if the unit's creeping, and they raise the alarm
    if LC.RebelAsleep and LC.RebelAsleep(st) and now >= (st.nextStir or 0) then
        st.nextStir = now + 0.5
        for _, ply in ipairs(player.GetAll()) do
            local near = ply:Crouching() and 110 or 260
            if ply:GetPos():DistToSqr(npc:GetPos()) < near * near and LooksCombine(ply) then
                if LC.RebelLifeEnd then LC.RebelLifeEnd(npc, st) end
                local z = st.zone or ZoneAt(npc:GetPos(), 300)
                if z then Alert(z, ply:GetPos(), now) end
                npc:EmitSound(Vo(st, Pick(SPOTTED)), 85)
                st.nextLook = 0
                break
            end
        end
    end
    -- looking for trouble, twice a second at most (not in their sleep: the shouting wakes them)
    if now >= (st.nextLook or 0) and not (LC.RebelAsleep and LC.RebelAsleep(st)) then
        st.nextLook = now + 0.5
        local foe = (IsValid(st.provokedBy) and Alive(st.provokedBy) and CanSee(npc, st.provokedBy, 2000) and st.provokedBy)
            or (st.post and LC.LookoutPostThreat(npc, st, now))
            or PlayerThreat(npc, st, now) or NPCThreat(npc, st, st.raid and NPC_RAID or NPC_RANGE)
        if foe then return SetFoe(npc, st, foe, now) end
    end

    -- a lookout keeps his post, facing the way it faces
    if st.post then
        local d2 = pos:DistToSqr(st.post.pos)
        if d2 > 50 * 50 then
            HeadFor(npc, st, st.post.pos, d2 > 300 * 300)
        elseif now > (st.untilT or 0) then
            st.untilT = now + 3
            if npc:IsCurrentSchedule(SCHED_FORCED_GO) or npc:IsCurrentSchedule(SCHED_FORCED_GO_RUN) then npc:SetSchedule(SCHED_IDLE_STAND) end
            st.goingTo = nil
            if LC.FaceYaw then LC.FaceYaw(npc, st.post.yaw + math.random(-25, 25)) end
        end
        return
    end

    -- the quartermaster keeps his post (and goes back to it if he's been led, pushed or frightened off)
    if st.quartermaster then
        local home = st.qmHome
        if home and pos:DistToSqr(home) > 120 * 120 then
            if not LC.IsSeen(pos + UP) then
                npc:SetPos(home)
                npc:SetSchedule(SCHED_IDLE_STAND)
                st.goingTo = nil
            else
                HeadFor(npc, st, home, false)
            end
            return
        end
        if now > (st.untilT or 0) then
            st.untilT = now + 4
            for _, p in ipairs(player.GetAll()) do
                if p:Alive() and p:GetPos():DistToSqr(pos) < 300 * 300 then LC.Face(npc, p:GetPos()) break end
            end
        end
        return
    end

    -- on a raid: go and hit the target, then come home
    if st.raid then
        local r = st.raid
        if now > r.ends or r.over then
            st.raid = nil
            st.returning = true
            st.unmanaged = true
            st.expires = now + 60
        else
            -- along the city's routes, and past anything they're stuck on out of sight (sv_livingcity_rebelevents.lua)
            if not (LC.RaidWalk and LC.RaidWalk(npc, st, r, now)) then HeadFor(npc, st, r.target, true) end
            return
        end
    end
    if st.returning then
        if st.zone and LCZ.Within(st.zone, pos, 0.9) then
            st.returning = nil
            LC.SetState(npc, st, "idle")
            st.untilT = now + 3
        else
            if st.zone then HeadFor(npc, st, LCZ.Heart(st.zone), true) end
            return
        end
    end

    -- out scavenging, keeping out of sight (sv_livingcity_rebellife.lua)
    if st.errand and LC.RebelErrandThink and LC.RebelErrandThink(npc, st, now) then return end

    -- home: wander about inside the zone, and stay in it
    local z = st.zone
    if z and not LCZ.Within(z, pos, 1.3) then -- (grown ground: by its cells)
        if not LC.IsSeen(pos + UP) then
            local spot = LC.SpotInZone(z)
            if spot then npc:SetPos(spot + Vector(0, 0, 4)) end
        else
            HeadFor(npc, st, LCZ.Heart(z), false)
        end
        return
    end
    if st.state == "fighting" then LC.SetState(npc, st, "idle") st.untilT = now + 2 end
    -- something to do at home: patrols, the workbench, sleep, a seat, the fire (sv_livingcity_rebellife.lua)
    if LC.RebelLifeThink and LC.RebelLifeThink(npc, st, now) then return end
    if st.state == "moving" then
        local arrived = st.dest and pos:DistToSqr(st.dest) < 70 * 70
        if arrived or now > st.untilT or not npc:IsCurrentSchedule(SCHED_FORCED_GO) then
            npc:SetSchedule(SCHED_IDLE_STAND)
            LC.SetState(npc, st, "idle")
            st.untilT = now + math.Rand(8, 30)
            if math.random() < 0.4 then LC.FaceYaw(npc, math.random(0, 359)) end
        end
        return
    end
    if now > (st.untilT or 0) then Wander(npc, st, now) end
end
LC.Thinkers.rebel = ThinkRebel

------------------------------------------------------------------------
-- Getting shot
------------------------------------------------------------------------

hook.Add("EntityTakeDamage", "LivingCityRebels", function(victim, dmg)
    local attacker = dmg:GetAttacker()
    if not IsValid(attacker) then return end
    local ast = LC.NPCs[attacker]

    -- rebels shooting players: dangerous, but not instant death (dying is permanent here)
    if victim:IsPlayer() and ast and ast.role == "rebel" then
        dmg:SetDamage(dmg:GetDamage() * math.max(0, cvDamage:GetFloat()))
        return
    end

    local vst = LC.NPCs[victim]
    if not vst or vst.role ~= "rebel" then return end
    -- the ones at home go down quicker (the owner: half the health); a player's own squad doesn't
    if not vst.follow and not vst.quartermaster then dmg:SetDamage(dmg:GetDamage() * math.max(0, cvHomeHurt:GetFloat())) end
    local now = CurTime()
    if attacker:IsPlayer() then
        if IsResistance(attacker) then return end -- friendly fire, nobody's counting
        -- the shooter and every fighter close by turn on them
        for npc, st in pairs(LC.NPCs) do
            if IsValid(npc) and st.role == "rebel" and npc:GetPos():DistToSqr(victim:GetPos()) < 1500 * 1500 then
                st.provokedBy, st.provokedUntil = attacker, now + 60
                if not st.foe then SetFoe(npc, st, attacker, now) end
            end
        end
    elseif ast and (LC.IsSecurity(ast) or ast.role == "scanner") and not vst.foe then
        SetFoe(victim, vst, attacker, now)
    end
end)

-- A squad's marks: the leader shoots at something Combine, or something
-- Combine shoots at the leader or one of his fighters.
local function HasFollowers(ply)
    for npc, st in pairs(LC.NPCs) do
        if st.follow == ply and IsValid(npc) then return true end
    end
    return false
end

local function IsCombineThing(e)
    if e:IsPlayer() then return LooksCombine(e) end
    local st = LC.NPCs[e]
    return st ~= nil and (LC.IsSecurity(st) or st.role == "scanner")
end

hook.Add("EntityTakeDamage", "LivingCitySquadMarks", function(victim, dmg)
    local att = dmg:GetAttacker()
    if not IsValid(att) or not IsValid(victim) or att == victim then return end
    local now = CurTime()
    if att:IsPlayer() and IsResistance(att) and IsCombineThing(victim) and HasFollowers(att) then
        MarkForSquad(att, victim, now, 25)
    elseif IsCombineThing(att) then
        if victim:IsPlayer() then
            if HasFollowers(victim) then MarkForSquad(victim, att, now, 25) end
        else
            local vst = LC.NPCs[victim]
            if vst and vst.role == "rebel" and IsValid(vst.follow) then MarkForSquad(vst.follow, att, now, 25) end
        end
    end
end)

-- Units get something for it.
hook.Add("OnNPCKilled", "LivingCityRebels", function(npc, attacker)
    local st = LC.NPCs[npc]
    if not st or st.role ~= "rebel" then return end
    alarms[npc] = nil
    if IsValid(attacker) and attacker:IsPlayer() and LC.PlayerIsCP(attacker) and LC.AddXP then
        LC.AddXP(attacker, (LCF and LCF.XP and LCF.XP.rebel_kill) or 5, "anticitizen neutralized")
    end
end)

------------------------------------------------------------------------
-- Units notice armed rebels off rebel ground
------------------------------------------------------------------------

-- An armed rebel out in the city (scavenging, on the way home, with a
-- Resistance player) who walks into a unit's sight within
-- lc_units_spot_rebels units gets shot at. That's why they keep their distance.
local lastSpotRadio = 0
function LC.UnitsSpotRebels()
    local range = cvSpotReb:GetFloat()
    if range <= 0 or not LC.Running then return end
    local now = CurTime()
    local units
    for npc, st in pairs(LC.NPCs) do
        if IsValid(npc) and st.role == "rebel" and npc:Health() > 0 and not st.raid and not st.quartermaster and not st.post
            and not st.foe and not st.test and st.state ~= "event" and not st.casual then -- (acting casual: just a citizen, to them)
            local rp = npc:GetPos()
            if not ZoneAt(rp, 200) then
                if not units then
                    units = {}
                    for u, ust in pairs(LC.NPCs) do
                        if IsValid(u) and LC.IsSecurity(ust) and u:Health() > 0 and ust.state ~= "hostile" and ust.state ~= "event"
                            and ust.state ~= "detained" and not ust.test and not ust.questLock then units[#units + 1] = u end
                    end
                end
                for _, u in ipairs(units) do
                    local ust = LC.NPCs[u]
                    if ust and ust.state ~= "hostile" then
                        local to = rp - u:GetPos()
                        local d2 = to:LengthSqr()
                        if d2 < range * range then
                            local fwd = u:GetForward()
                            local facing = d2 < 150 * 150 or (fwd.x * to.x + fwd.y * to.y) > 0.3 * math.sqrt(d2)
                            if facing and CanSee(u, npc, range) then
                                LC.ArmUnit(u, ust)
                                LC.MakeOneHostile(u, ust, npc)
                                ust.provokedBy, ust.provokedUntil = npc, now + 90
                                SetFoe(npc, st, u, now) -- (a follower's squad marks it; anyone else fights, then heads home)
                                if now > lastSpotRadio + 60 then
                                    lastSpotRadio = now
                                    if LC.RadioNotice then LC.RadioNotice("cp", "Dispatch: armed anticitizen " .. (LC.DescribePlace and LC.DescribePlace(rp) or "in the city") .. ". Civil Protection units engaging.") end
                                end
                                break
                            end
                        end
                    end
                end
            end
        end
    end
end

timer.Create("LivingCityUnitsSpotRebels", 1, 0, function()
    local ok, err = pcall(LC.UnitsSpotRebels)
    if not ok then LC.Error("Civil Protection units spot rebels", err) end
end)

------------------------------------------------------------------------
-- Skirmishes
------------------------------------------------------------------------

LC.Skirmish = LC.Skirmish or nil
local nextSkirmish = nil

local function Interval()
    -- quieter when the Combine holds everything (sv_livingcity_war.lua)
    return math.max(1, cvSkirmInt:GetFloat()) * 60 * math.Rand(0.8, 1.2) * (LC.SkirmishIntervalMul and LC.SkirmishIntervalMul() or 1)
end

-- Something of the Combine's worth hitting, not too far from a rebel zone.
local function RaidTarget(z)
    local cands = {}
    for _, kind in ipairs({ "checkpoint", "patrol", "queue" }) do
        for _, p in ipairs(LC.PointsOfKind(kind)) do
            local d = p.pos:Distance(z.pos)
            if not LCZ.Near(z, p.pos, 400) and not LC.InRebelZone(p.pos) then cands[#cands + 1] = { pos = p.pos, d = d } end
        end
        if #cands > 0 then break end
    end
    if #cands == 0 then
        -- no layout to go by: wherever a unit is standing
        for npc, st in pairs(LC.NPCs) do
            if IsValid(npc) and LC.IsSecurity(st) and not LC.InRebelZone(npc:GetPos()) then
                cands[#cands + 1] = { pos = npc:GetPos(), d = npc:GetPos():Distance(z.pos) }
            end
        end
    end
    if #cands == 0 then return nil end
    table.sort(cands, function(a, b) return a.d < b.d end)
    return cands[math.random(1, math.min(3, #cands))].pos
end

local function Say(ply, msg) if IsValid(ply) then ply:ChatPrint(msg) else print(msg) end end

local function Radio(band, text)
    if LC.RadioNotice then LC.RadioNotice(band, text) end
end

-- purpose: nil for a plain raid on a checkpoint; or an operation with an
-- objective at the target ("heist", "breakout", "ambush", "screen"), worked
-- out in sv_livingcity_resistanceops.lua
local function StartRaid(z, target, purpose, data)
    z = z or Pick(RebelZones())
    if not z then return false, "no rebel territory on this map" end
    target = target or RaidTarget(z)
    if not target then return false, "nothing of the Combine's to hit" end
    -- too few fighters left in reserve: the raid waits for recruits (sv_livingcity_manpower.lua)
    local held = LC.ManpowerHold and LC.ManpowerHold("rebel")
    if held then return false, held end
    -- (the raid's own clock starts when the fighters get there: until then, time to walk it,
    -- sv_livingcity_rebelevents.lua)
    local sk = { kind = "raid", zone = z, target = target, started = CurTime(), ends = CurTime() + (LC.RaidWalkSecs or 360) + 10, rebels = {}, units = {},
        purpose = purpose, data = data or {} }
    -- bigger while the Commissary's restricted (sv_livingcity_rebelevents.lua)
    local party = LC.RaidPartySize and LC.RaidPartySize() or 4
    if LC.EventOpen then LC.EventOpen(sk) end
    -- the fighters already there go first, as many as it needs (the owner, 7 November: "just
    -- literally move those NPCs to the raid"); never the quartermaster, a lookout on his post,
    -- one out scavenging or anyone a player is with
    if LC.RaidTakeFromZone then
        for _, npc in ipairs(LC.RaidTakeFromZone(z, party)) do sk.rebels[#sk.rebels + 1] = npc end
    else
        for npc, st in pairs(LC.NPCs) do
            if #sk.rebels >= 2 then break end
            if IsValid(npc) and st.role == "rebel" and st.zone == z and not st.foe and not st.raid and not st.follow
                and not st.post and not st.quartermaster and not st.errand then
                sk.rebels[#sk.rebels + 1] = npc
            end
        end
    end
    -- still short: room under the NPC cap, or a spare NPC nobody can see swapped for a fighter at
    -- the raid's hidden spot (the city's count doesn't go up); the last-resort allowance after that
    for _ = 1, party - #sk.rebels do
        if LC.ManpowerCan and not LC.ManpowerCan("rebel") then break end -- (nobody left in reserve: the party goes short)
        if LC.EventSlot and not LC.EventSlot(sk, { "rebel", "citizen" }, z) then break end
        local p = HiddenSpot(z, true)
        if p then
            local npc, st = SpawnRebel(p + Vector(0, 0, 4), z)
            if IsValid(npc) then
                st.unmanaged = true
                sk.rebels[#sk.rebels + 1] = npc
                if LC.EventNPCAdd then LC.EventNPCAdd(sk, npc, st) end -- (counted from the start: the next one may need a swap)
            end
        end
    end
    if #sk.rebels == 0 then return false, "no fighters" end
    for _, npc in ipairs(sk.rebels) do
        local st = LC.NPCs[npc]
        if st.life and LC.RebelLifeEnd then LC.RebelLifeEnd(npc, st) end
        if st.errand and LC.RebelErrandEnd then LC.RebelErrandEnd(npc, st) end
        st.raid = { target = target + Vector(math.random(-120, 120), math.random(-120, 120), 0), ends = sk.ends, sk = sk }
        st.skirmish = sk
        st.unmanaged = true
        if LC.EventNPCAdd then LC.EventNPCAdd(sk, npc, st) end -- (still counted against lc_npc_budget, until home or gone)
        npc:SetSchedule(SCHED_IDLE_STAND)
        LC.SetState(npc, st, "moving")
    end
    LC.Skirmish = sk
    local where = LC.DescribePlace and LC.DescribePlace(target) or "in the city"
    Radio("resistance", "Our people are hitting the Combine " .. where .. ". Stay clear, or lend a hand.")
    -- the Combine's own players: a job to go and put it down ("Repel the attack", sv_livingcity_sidejobs.lua)
    if not purpose and LC.PostDirective then LC.PostDirective("cp_repelraid") end
    -- dispatch hears about it once they're close
    sk.where = where
    LC.Log("info", string.format("Skirmish: rebel raid of %d from %s toward %s", #sk.rebels, tostring(z.pos), tostring(target)))
    hook.Run("LivingCitySkirmish", "raid", sk)
    return true
end

-- A raid planned a little ahead (lc_raid_warning): the Resistance's own hear where, and
-- get a job to go and back the fighters up ("Back up the raid", sv_livingcity_sidejobs.lua).
local function PlanRaid(now)
    local z = Pick(RebelZones())
    if not z then return false end
    if LC.ManpowerHold and LC.ManpowerHold("rebel") then return false end -- (postponed, and the Resistance told why)
    local target = RaidTarget(z)
    if not target then return false end
    local lead = cvRaidLead:GetFloat()
    if lead <= 0 then return StartRaid(z, target) end
    LC.PlannedRaid = { zone = z, target = target, at = now + lead }
    local where = LC.DescribePlace and LC.DescribePlace(target) or "in the city"
    Radio("resistance", "In about " .. math.floor(lead / 10 + 0.5) * 10 .. " seconds our people hit the Combine " .. where .. ". Anyone who can, back them up.")
    for _, p in ipairs(player.GetAll()) do
        if IsResistance(p) and LC.Notice then
            LC.Notice(p, "event", "A raid is coming", "Our fighters hit the Combine " .. where .. " in about " .. math.floor(lead / 10 + 0.5) * 10 .. " seconds. Back them up: the job's on your board (F4).", 10)
        end
    end
    if LC.PostDirective then LC.PostDirective("res_backupraid") end
    return true
end
LC.PlanRebelRaid = function() return PlanRaid(CurTime()) end

function LC.StartRebelRaid(z, target, purpose, data)
    if LC.Skirmish then return false, "a skirmish is already on" end
    return StartRaid(z, target, purpose, data)
end

local function StagingSpot(z)
    for _ = 1, 40 do
        local p = LC.RandomWanderPos("cop")
        if p then
            if not LCZ.Near(z, p, 400) and LCZ.Near(z, p, 2500) and not LC.IsSeen(p + UP) and LC.ClearSpot(p)
                and (not LC.NavReachable or LC.NavReachable(p, LCZ.Heart(z))) then return p end -- (and a way in from there)
        end
    end
    for _ = 1, 20 do
        local p = LC.RandomWanderPos("cop")
        if p and not LCZ.Near(z, p, 300) and not LC.IsSeen(p + UP) then return p end
    end
    return nil
end

-- A sweep team member with nobody to fight does the sweep's work (the owner: they ran about staring
-- at the floor): the lab's scientist taken in, the pots smashed, the supply crates emptied, nearest first,
-- one unit to each. True while they're at one.
local CHORE_DONE = {
    scientist = function(e) return LC.LabShut and LC.LabShut(e) end,
    pot = function(e) return not e.lcPot or e.lcPot.state == "empty" end,
    cache = function(e) return (e.lcStock or 0) <= 0 end,
}
local CHORE_DO = {
    scientist = function(u, e) if LC.ShutLab then LC.ShutLab(nil, e) end end,
    pot = function(u, e)
        if LC.PlayGesture then LC.PlayGesture(u, { "swinggesture", "ACT_MELEE_ATTACK_SWING_GESTURE", "ACT_MELEE_ATTACK1" }, 1) end
        if LC.SweepPot then LC.SweepPot(e) end
    end,
    cache = function(u, e) if LC.SweepCache then LC.SweepCache(e) end end,
}
local function SweepChore(u, st, sk, now)
    sk.taken = sk.taken or {}
    local c = st.sweepChore
    if c and (not IsValid(c.ent) or CHORE_DONE[c.kind](c.ent)) then sk.taken[c.ent or 0] = nil st.sweepChore, c = nil, nil end
    if not c then
        local best, bd
        local function consider(ent, kind)
            if not IsValid(ent) or CHORE_DONE[kind](ent) then return end
            local who = sk.taken[ent]
            if who and who ~= u and IsValid(who) and Alive(who) then return end
            local d = ent:GetPos():DistToSqr(u:GetPos())
            if not bd or d < bd then best, bd = { ent = ent, kind = kind }, d end
        end
        local sci = LC.ScientistNear and LC.ScientistNear(sk.zone.pos, (sk.zone.r or 300) + 300)
        if sci then consider(sci, "scientist") end
        for _, t in ipairs(LC.RebelZoneThings and LC.RebelZoneThings(sk.zone) or {}) do
            if t.kind == "pot" then consider(t.ent, "pot")
            elseif t.kind == "crate" and t.cache then consider(t.ent, "cache") end
        end
        if not best then return false end
        st.sweepChore, sk.taken[best.ent], st.choreGo = best, u, 0
        c = best
        LC.SetNPCStr(u, "lc_doing", c.kind == "scientist" and "arresting the scientist" or (c.kind == "pot" and "smashing the pots" or "confiscating supplies"))
    end
    local pos = c.ent:GetPos()
    if u:GetPos():DistToSqr(pos) < 90 * 90 then
        LC.Face(u, pos)
        CHORE_DO[c.kind](u, c.ent)
        sk.taken[c.ent] = nil
        st.sweepChore = nil
        LC.SetNPCStr(u, "lc_doing", "")
        return true
    end
    if now > (st.choreGo or 0) then
        st.choreGo = now + 6
        if not (LC.GoTo and LC.GoTo(u, st, pos, true)) then
            u:SetLastPosition(pos)
            u:SetSchedule(SCHED_FORCED_GO_RUN)
        end
    end
    return true
end
LC.SweepChore = SweepChore -- (tests)

-- The Combine players on the "Join the sweep" job (sv_livingcity_sidejobs.lua).
function LC.SweepJoiners()
    local out = {}
    for _, p in ipairs(player.GetAll()) do
        local q = LC.QuestOf and LC.QuestOf[p]
        if q and q.tmpl and q.tmpl.id == "cp_joinsweep" and p:Alive() then out[#out + 1] = p end
    end
    return out
end

-- A planned sweep that can't start: whoever joined it hears why, and the job ends without blame.
function LC.SweepCalledOff(why)
    LC.Log("info", "Planned sweep called off: " .. tostring(why))
    for _, p in ipairs(LC.SweepJoiners()) do
        if LC.Notice then LC.Notice(p, "warn", "Sweep called off", "Dispatch: the sweep is called off (" .. tostring(why or "no team free") .. "). Stand down.", 8) end
        local q = LC.QuestOf[p]
        if q and LC.FinishQuest then LC.FinishQuest(q, false, "the sweep was called off") end
    end
end

-- Where a sweep team member still heads to meet the players who joined, or nil to push in: the
-- nearest joiner within reach of the territory, until the unit is with them (or the minute is up).
function LC.SweepRallyPoint(sk, u, now)
    if not sk.rally or #sk.rally == 0 or now > (sk.rallyUntil or 0) then return nil end
    local st = LC.NPCs[u]
    if not st or st.sweepRallied then return nil end
    local best, bd
    for _, p in ipairs(sk.rally) do
        if IsValid(p) and p:Alive() and LCZ.Near(sk.zone, p:GetPos(), 2500) then
            local d = p:GetPos():DistToSqr(u:GetPos())
            if not bd or d < bd then best, bd = p, d end
        end
    end
    if not best then return nil end
    if bd < 300 * 300 then
        st.sweepRallied = true
        if not sk.toldRally then
            sk.toldRally = true
            if LC.Notice then LC.Notice(best, "event", "The sweep team is with you", "The team's here. Go in with them: they fight whoever you fight.", 6) end
            u:EmitSound("npc/metropolice/vo/affirmative.wav", 70)
        end
        return nil
    end
    return best:GetPos()
end

local function StartSweep(z)
    z = z or Pick(RebelZones())
    if not z then return false, "no rebel territory on this map" end
    if not LC.Spawners or not LC.Spawners.cop then return false, "no Civil Protection units" end
    local stage = StagingSpot(z)
    if not stage then return false, "nowhere out of sight to gather a team" end
    local held = LC.ManpowerHold and LC.ManpowerHold("cp") -- (too few units in reserve: sv_livingcity_manpower.lua)
    if held then return false, held end
    -- make sure there's someone home to fight
    LC.ReinforceRebels(z, 2)
    local sk = { kind = "sweep", zone = z, stage = stage, started = CurTime(), ends = CurTime() + 150, rebels = {}, units = {} }
    local soldiers = GetConVar("lc_soldiers")
    if LC.EventOpen then LC.EventOpen(sk) end
    for i = 1, 4 do
        -- room under the NPC cap, or an idle unit or citizen nobody can see swapped for one of the
        -- team (the city's count doesn't go up: sv_livingcity_rebelevents.lua)
        local useSoldier = i == 4 and soldiers and soldiers:GetInt() > 0 and LC.Spawners.soldier and (not LC.ManpowerCan or LC.ManpowerCan("ota"))
        if LC.ManpowerCan and not LC.ManpowerCan(useSoldier and "ota" or "cp") then break end -- (nobody left in reserve: the team goes short)
        if LC.EventSlot and not LC.EventSlot(sk, { "cop", "soldier", "citizen" }) then break end
        local spawn = useSoldier and LC.Spawners.soldier or LC.Spawners.cop
        local npc, st = spawn(stage + Vector(math.random(-80, 80), math.random(-80, 80), 4))
        if IsValid(npc) then
            st.unmanaged, st.leaveAt, st.routeGroup = true, nil, nil
            st.skirmish = sk
            LC.ArmUnit(npc, st)
            LC.SetState(npc, st, "sweep")
            sk.units[#sk.units + 1] = npc
            if LC.EventNPCAdd then LC.EventNPCAdd(sk, npc, st) end
        end
    end
    if #sk.units == 0 then return false, "no Civil Protection units" end
    -- the team meets the players who joined the sweep before going in (the owner, 7 November: "joined a
    -- sweep and no one showed up"), up to a minute, then pushes in with them
    sk.rally = {}
    for _, p in ipairs(LC.SweepJoiners and LC.SweepJoiners() or {}) do sk.rally[#sk.rally + 1] = p end
    sk.rallyUntil = CurTime() + 60
    for _, p in ipairs(sk.rally) do
        if LC.Notice then LC.Notice(p, "event", "The sweep team is coming", "Dispatch: the sweep team is on its way to you. Hold where you are: they meet you, then go in with you.", 8) end
    end
    LC.Skirmish = sk
    local where = LC.DescribePlace and LC.DescribePlace(z.pos) or "rebel territory"
    Radio("cp", "Dispatch: sweep team moving into anticitizen territory " .. where .. ". Civil Protection units may assist.")
    Radio("resistance", "Combine are moving on our people " .. where .. "! Everyone who can fight, get there.")
    LC.Log("info", string.format("Skirmish: Combine sweep of %d into %s", #sk.units, tostring(z.pos)))
    hook.Run("LivingCitySkirmish", "sweep", sk)
    return true
end

LC.StartRebelRaid = StartRaid
LC.StartCombineSweep = StartSweep

-- A sweep planned a little ahead (lc_sweep_warning): the Combine's own players hear where,
-- and get a job to join the team ("Join the sweep", sv_livingcity_sidejobs.lua).
local function IsCombinePlayer(p)
    local f = p:GetNW2String("lcf_faction", "")
    return f == "cp" or f == "ota" or (LC.PlayerIsCP and LC.PlayerIsCP(p))
end
local function PlanSweep(now, z)
    z = z or Pick(RebelZones())
    if not z then return false end
    if LC.ManpowerHold and LC.ManpowerHold("cp") then return false end -- (postponed, and the Combine told why)
    local lead = cvSweepLead:GetFloat()
    if lead <= 0 then return StartSweep(z) end
    LC.PlannedSweep = { zone = z, at = now + lead }
    local where = LC.DescribePlace and LC.DescribePlace(z.pos) or "rebel territory"
    local secs = math.floor(lead / 10 + 0.5) * 10
    Radio("cp", "Dispatch: sweep team moves into anticitizen territory " .. where .. " in about " .. secs .. " seconds. All available Civil Protection units, assist.")
    for _, p in ipairs(player.GetAll()) do
        if IsCombinePlayer(p) and LC.Notice then
            LC.Notice(p, "event", "A sweep is coming", "A sweep team moves into anticitizen territory " .. where .. " in about " .. secs .. " seconds. Join it: the job's on your board (F4).", 10)
        end
    end
    if LC.PostDirective then LC.PostDirective("cp_joinsweep") end
    return true
end
LC.PlanCombineSweep = function(z) return PlanSweep(CurTime(), z) end -- (z: on that territory; else one at random)

local function EndSkirmish(sk, why)
    if sk.done then return end
    sk.done = true
    if LC.Skirmish == sk then LC.Skirmish = nil end
    -- whoever's left goes home, and the two sides go back to ignoring each other
    for _, npc in ipairs(sk.rebels) do
        local st = IsValid(npc) and LC.NPCs[npc]
        if st then
            st.skirmish = nil
            if st.raid then st.raid.over = true end
            for _, u in ipairs(sk.units) do
                if IsValid(u) then npc:AddEntityRelationship(u, D_NU, 99) end
            end
        end
    end
    for _, npc in ipairs(sk.units) do
        local st = IsValid(npc) and LC.NPCs[npc]
        if st then
            st.skirmish = nil
            if st.state == "hostile" and LC.CalmOne then LC.CalmOne(npc, st, CurTime()) end -- also back to the stick
            for _, r in ipairs(sk.rebels) do
                if IsValid(r) then npc:AddEntityRelationship(r, D_NU, 99) end
            end
            if st.unmanaged then
                -- the sweep team goes back the way it came, and is gone once out of sight
                st.withdrawing = true
                LC.SetState(npc, st, "sweep")
                npc:SetLastPosition(sk.stage or npc:GetPos())
                npc:SetSchedule(SCHED_FORCED_GO)
            end
            -- units who answered a raid just go back to their beats
        end
    end
    -- units who joined in on their own go back to work too
    for npc, st in pairs(LC.NPCs) do
        if IsValid(npc) and LC.IsSecurity(st) and st.state == "hostile" and IsValid(st.enemy) and LC.NPCs[st.enemy]
            and LC.NPCs[st.enemy].role == "rebel" and LC.CalmOne then
            npc:AddEntityRelationship(st.enemy, D_NU, 99)
            LC.CalmOne(npc, st, CurTime())
        end
    end
    local where = sk.where or (LC.DescribePlace and LC.DescribePlace(sk.zone.pos)) or ""
    if sk.kind == "raid" then
        if sk.alerted then
            Radio("cp", "Dispatch: anticitizen incursion " .. where .. " is over. Resume your beats.")
        else
            -- (they never got there: nobody pretends there was a fight)
            Radio("resistance", "Our fighters couldn't get through " .. where .. ". They're on their way home.")
        end
    else
        Radio("cp", "Dispatch: sweep team withdrawing.")
        Radio("resistance", why == "Civil Protection units down" and "They're pulling back. We held." or "The Combine have pulled back.")
    end
    LC.Log("info", "Skirmish over: " .. sk.kind .. " (" .. (why or "time") .. ")")
    hook.Run("LivingCitySkirmishEnded", sk.kind, sk, why)
end
LC.EndSkirmish = EndSkirmish

local function RunSkirmish(sk, now)
    local liveRebels, liveUnits = 0, 0
    for _, n in ipairs(sk.rebels) do if Alive(n) then liveRebels = liveRebels + 1 end end
    for _, n in ipairs(sk.units) do if Alive(n) then liveUnits = liveUnits + 1 end end

    if sk.kind == "raid" then
        if liveRebels == 0 then return EndSkirmish(sk, "raiders down") end
        -- once they're close, dispatch notices and the nearest units respond
        if not sk.alerted then
            for _, n in ipairs(sk.rebels) do
                if Alive(n) and n:GetPos():DistToSqr(sk.target) < 1800 * 1800 then sk.alerted = true break end
            end
            if sk.alerted then
                if LC.Announce then LC.Announce("response", "npc/overwatch/cityvoice/f_anticitizenreport_spkr.wav",
                    "Armed Resistance fighters are attacking " .. (sk.where or "in the city") .. ". Civil Protection units nearby are fighting them; anyone else, keep clear.") end
                Radio("cp", "Dispatch: armed anticitizens " .. (sk.where or "") .. ". All nearby Civil Protection units respond.")
                local near = {}
                for npc, st in pairs(LC.NPCs) do
                    if IsValid(npc) and LC.IsSecurity(st) and st.state ~= "hostile" and not st.questLock
                        and npc:GetPos():DistToSqr(sk.target) < 3000 * 3000 then
                        near[#near + 1] = { npc = npc, st = st, d = npc:GetPos():DistToSqr(sk.target) }
                    end
                end
                table.sort(near, function(a, b) return a.d < b.d end)
                for i = 1, math.min(4, #near) do
                    local u = near[i]
                    local raider
                    for _, r in ipairs(sk.rebels) do if Alive(r) then raider = r break end end
                    if raider then
                        u.st.skirmish = sk
                        LC.ArmUnit(u.npc, u.st)
                        LC.MakeOneHostile(u.npc, u.st, raider)
                        u.st.provokedBy, u.st.provokedUntil = raider, now + 150
                        sk.units[#sk.units + 1] = u.npc
                        local rst = LC.NPCs[raider]
                        if rst and not rst.foe then SetFoe(raider, rst, u.npc, now) end
                    end
                end
                -- the fight is on: its clock starts, units are sent if too few are here, the
                -- Combine's players see where it is (sv_livingcity_rebelevents.lua)
                if LC.RaidArrived then LC.RaidArrived(sk, now) end
            end
        end
        -- units whose raider went down pick the next one
        for _, u in ipairs(sk.units) do
            local st = IsValid(u) and LC.NPCs[u]
            if st and Alive(u) and st.state ~= "hostile" and not st.withdrawing then
                for _, r in ipairs(sk.rebels) do
                    if Alive(r) and r:GetPos():DistToSqr(u:GetPos()) < 3000 * 3000 then
                        LC.MakeOneHostile(u, st, r)
                        st.provokedBy, st.provokedUntil = r, now + 120
                        break
                    end
                end
            end
        end
    else
        if liveUnits == 0 then return EndSkirmish(sk, "Civil Protection units down") end
        if liveRebels == 0 and CountIn(sk.zone) == 0 then return EndSkirmish(sk, "territory cleared") end
        -- the team pushes in; whoever they see, they fight
        for _, u in ipairs(sk.units) do
            local st = IsValid(u) and LC.NPCs[u]
            if st and Alive(u) then
                if st.state == "idle" then LC.SetState(u, st, "sweep") end
                local rallyTo = not sk.arrived and LC.SweepRallyPoint and LC.SweepRallyPoint(sk, u, now)
                if rallyTo and st.state ~= "hostile" then
                    -- to the player who joined, first (they go in together)
                    if now > (st.nextSweepMove or 0) then
                        st.nextSweepMove = now + 3
                        if not (LC.GoTo and LC.GoTo(u, st, rallyTo, true)) then
                            u:SetLastPosition(rallyTo)
                            u:SetSchedule(SCHED_FORCED_GO_RUN)
                        end
                    end
                elseif st.state == "sweep" or st.state == "moving" then
                    local target
                    for r, rst in pairs(LC.NPCs) do
                        if IsValid(r) and rst.role == "rebel" and r:Health() > 0 and CanSee(u, r, 1600) then target = r break end
                    end
                    if target then
                        LC.MakeOneHostile(u, st, target)
                        st.provokedBy, st.provokedUntil = target, now + 120
                        local rst = LC.NPCs[target]
                        if rst and not rst.foe then SetFoe(target, rst, u, now) end
                    elseif sk.arrived and SweepChore(u, st, sk, now) then
                        -- (busy with the scientist, a pot or a crate)
                    elseif st.state == "sweep" and now > (st.nextSweepMove or 0) then
                        -- along the city's own routes (the engine alone often finds no way in)
                        st.nextSweepMove = now + 8
                        local spot = LC.SpotInZone(sk.zone) or sk.zone.pos
                        if not (LC.GoTo and LC.GoTo(u, st, spot, true)) then
                            u:SetLastPosition(spot)
                            u:SetSchedule(SCHED_FORCED_GO_RUN)
                        end
                    end
                end
            end
        end
        -- the rebels who fight back are part of it
        for r, rst in pairs(LC.NPCs) do
            if IsValid(r) and rst.role == "rebel" and rst.zone == sk.zone and rst.foe and not rst.skirmish then
                rst.skirmish = sk
                sk.rebels[#sk.rebels + 1] = r
            end
        end
    end
    if sk.kind == "sweep" and not sk.arrived then
        for _, u in ipairs(sk.units) do
            local ust = IsValid(u) and LC.NPCs[u]
            -- there: at the edge of their ground, or already fighting them
            if IsValid(u) and Alive(u) and (LCZ.Near(sk.zone, u:GetPos(), 200) or (ust and ust.state == "hostile")) then
                sk.arrived = true
                sk.ends = math.max(sk.ends, now + 120) -- (a long walk in doesn't eat the sweep)
                hook.Run("LivingCitySweepArrived", sk, u) -- (a gas bomb lobbed in first: sv_livingcity_cleanup.lua)
                break
            end
        end
        if not sk.arrived and now - sk.started > 300 then return EndSkirmish(sk, "never got there") end
        if not sk.arrived then return end
    end
    if now > sk.ends then EndSkirmish(sk, "time") end
end

-- withdrawing units walk off and are gone once nobody's looking
local function CleanupWithdrawn(now)
    for npc, st in pairs(LC.NPCs) do
        if IsValid(npc) and st.withdrawing and st.state == "sweep" then
            st.withdrawSince = st.withdrawSince or now
            if not LC.IsSeen(npc:GetPos() + UP) and (now - st.withdrawSince > 4) then npc:Remove() end
        end
    end
end

timer.Create("LivingCitySkirmishes", 2, 0, function()
    local ok, err = pcall(function()
        local now = CurTime()
        if not LC.Running then nextSkirmish = nil return end
        local sk = LC.Skirmish
        if sk then RunSkirmish(sk, now) end
        CleanupWithdrawn(now)
        -- a planned raid, or sweep, when its time comes
        local pr = LC.PlannedRaid
        if pr and now >= pr.at then
            LC.PlannedRaid = nil
            local started = false
            if not LC.Skirmish and not (LC.Event == "curfew" or LC.Event == "lockdown") then started = StartRaid(pr.zone, pr.target) end
            -- (announced ahead: if it can't go, the Resistance are told so, not left waiting for it)
            if not started then Radio("resistance", "The raid's off: our fighters can't go just now.") end
        end
        local ps = LC.PlannedSweep
        if ps and now >= ps.at then
            -- (the owner, 7 November: "joined a sweep and no one showed up") another fight still on: the
            -- sweep waits for it, up to five minutes, rather than quietly never coming; one that can't
            -- start at all is called off, and whoever joined it is told so
            if LC.Skirmish and (ps.waited or 0) < 300 then
                ps.waited, ps.at = (ps.waited or 0) + 20, now + 20
            else
                LC.PlannedSweep = nil
                local started, why = false, "another fight is still on"
                if not LC.Skirmish then started, why = StartSweep(ps.zone) end
                if not started then LC.SweepCalledOff(why) end
            end
        end
        if pr or ps then return end
        if LC.Skirmish or not cvSkirm:GetBool() or #RebelZones() == 0 or #player.GetAll() == 0 then return end
        nextSkirmish = nextSkirmish or (now + Interval())
        if now < nextSkirmish then return end
        nextSkirmish = now + Interval()
        if LC.Event == "curfew" or LC.Event == "lockdown" then return end -- the streets are locked down
        local started = math.random() < 0.5 and PlanRaid(now) or PlanSweep(now)
        if not started then
            -- if one kind can't happen on this map, try the other
            if not PlanRaid(now) then PlanSweep(now) end
        end
    end)
    if not ok then LC.Error("skirmishes", err) end
end)

hook.Add("LivingCityStopped", "LivingCityRebels", function()
    if LC.Skirmish then LC.Skirmish.done = true end
    LC.Skirmish = nil
    alarms = {}
    LC.RebelAlarms = alarms
end)

concommand.Add("lc_skirmish", function(ply, _, args)
    if IsValid(ply) and not ply:IsAdmin() then return end
    if not LC.Running then return Say(ply, "[Living City] Start the city first.") end
    if LC.Skirmish then EndSkirmish(LC.Skirmish, "called off") end
    local kind = string.lower(args[1] or "")
    local ok, why
    if kind == "sweep" then ok, why = StartSweep()
    elseif kind == "raid" then ok, why = StartRaid()
    elseif kind == "end" then return Say(ply, "[Living City] Skirmish called off.")
    else return Say(ply, "[Living City] Usage: lc_skirmish raid|sweep|end") end
    Say(ply, ok and ("[Living City] " .. kind .. " started.") or ("[Living City] Couldn't start a " .. kind .. ": " .. tostring(why)))
end)

------------------------------------------------------------------------
-- The quartermaster, and fighters who'll follow you
------------------------------------------------------------------------

local MAX_FOLLOWERS = 3
local QM_RESPAWN = 300

local function RankOf(ply) return ply:GetNW2Int("lcf_rank", 1) end

function LC.NearQuartermaster(ply)
    for npc, st in pairs(LC.NPCs) do
        if IsValid(npc) and st.quartermaster and npc:Health() > 0 and npc:GetPos():DistToSqr(ply:GetPos()) < 220 * 220 then return npc end
    end
    return nil
end

local function FollowersOf(ply)
    local out = {}
    for npc, st in pairs(LC.NPCs) do
        if IsValid(npc) and st.role == "rebel" and st.follow == ply then out[#out + 1] = npc end
    end
    return out
end
LC.FollowersOf = FollowersOf

function LC.DismissFollower(npc, st, quiet)
    local leader = st.follow
    if st.casual then LC.SquadCasual(npc, st, false) end
    st.meetAt = nil
    st.follow = nil
    st.goingTo = nil
    st.followSlot, st.followSID, st.followAt, st.apartSince = nil, nil, nil, nil
    if not (st.quartermaster or st.post) then -- (a quartermaster or lookout just carries on at his post)
        st.returning, st.unmanaged, st.expires = true, true, CurTime() + 60
    end
    if st.foe then DropFoe(npc, st, CurTime()) end
    if not quiet and IsValid(leader) then leader:ChatPrint("[Resistance] '" .. LC.NPCStr(npc, "lc_pname", "Right") .. ". I'll head back.'") end
end

local function Recruit(ply, npc, st)
    if st.follow == ply then
        LC.DismissFollower(npc, st)
        return
    end
    if st.follow or st.raid or st.quartermaster or st.post then
        ply:ChatPrint(st.post and "[Resistance] 'I'm on watch. Find someone else.'" or "[Resistance] They're busy.")
        return
    end
    if RankOf(ply) < 2 then
        ply:ChatPrint("[Resistance] '" .. "Who are you? Get someone who's earned it to ask me." .. "' (Members and up can lead fighters.)")
        return
    end
    if #FollowersOf(ply) >= MAX_FOLLOWERS then
        ply:ChatPrint("[Resistance] You've got " .. MAX_FOLLOWERS .. " with you already. Any more and you're a parade.")
        return
    end
    -- each one his own spot behind you
    local taken = {}
    for _, f in ipairs(FollowersOf(ply)) do local fst = LC.NPCs[f] if fst and fst.followSlot then taken[fst.followSlot] = true end end
    local slot = 0
    while taken[slot] do slot = slot + 1 end
    if st.life and LC.RebelLifeEnd then LC.RebelLifeEnd(npc, st) end
    if st.errand and LC.RebelErrandEnd then LC.RebelErrandEnd(npc, st) end
    if st.foe then DropFoe(npc, st, CurTime()) end
    st.follow, st.followSlot = ply, slot
    st.followSID, st.followAt = ply:SteamID(), CurTime() -- (a squad belongs to this connection, not to whoever is next in that seat)
    st.unmanaged = true -- someone else holds the fort while they're out
    st.returning, st.expires, st.raid, st.errand = nil, nil, nil, nil
    npc:EmitSound(Vo(st, Pick({ "okimready01", "okimready02", "letsgo01", "letsgo02", "leadtheway01" })), 75)
    ply:ChatPrint("[Resistance] " .. LC.NPCStr(npc, "lc_pname", "A fighter") .. " is with you, and stays with you. They hold their fire until you open up or the Combine do. E on them again to send them home.")
end
LC.RebelRecruit = Recruit -- (F2 > Freq 7 > Call for backup brings idle fighters this way: sv_livingcity_quickmore.lua)

-- A squad belongs to the connection that formed it. Anyone still marked as
-- following a player who has left, or who joined again since, goes home; and
-- a quartermaster or a lookout is never in a squad at all, whatever got him there.
local function SquadSweep()
    for npc, st in pairs(LC.NPCs) do
        local leader = st.follow
        if leader ~= nil and IsValid(npc) then
            local stale = not IsValid(leader) or not leader:IsPlayer()
                or (st.followSID ~= nil and leader:SteamID() ~= st.followSID)
                or (st.followAt ~= nil and leader.lcJoinedAt ~= nil and st.followAt < leader.lcJoinedAt)
            if stale or st.quartermaster or st.post then LC.DismissFollower(npc, st, true) end
        end
    end
end
LC.SquadSweep = SquadSweep

hook.Add("PlayerDisconnected", "LivingCityRebelSquads", function(ply)
    for _, npc in ipairs(FollowersOf(ply)) do
        local st = LC.NPCs[npc]
        if st then LC.DismissFollower(npc, st, true) end
    end
    if LC.SquadMarks then LC.SquadMarks[ply] = nil end
end)

hook.Add("PlayerInitialSpawn", "LivingCityRebelSquads", function(ply)
    ply.lcJoinedAt = CurTime()
    SquadSweep() -- (nobody is carried over from the last time)
end)

hook.Add("PlayerUse", "LivingCityRebelsUse", function(ply, ent)
    if LC.StalkerCantSpeak and LC.StalkerCantSpeak(ply, ent) then return false end
    local st = LC.NPCs[ent]
    if not st or st.role ~= "rebel" then return end
    -- the use key held down calls this every tick: only the press counts, or a long press
    -- would bring someone along and send them straight home again
    ply.lcRebelUseLast = ply.lcRebelUseLast or setmetatable({}, { __mode = "k" })
    local heldSince = ply.lcRebelUseLast[ent]
    ply.lcRebelUseLast[ent] = CurTime()
    if heldSince and CurTime() - heldSince < 0.3 then return false end
    if (ply.lcRebelUseNext or 0) > CurTime() then return false end
    ply.lcRebelUseNext = CurTime() + 0.6
    if not IsResistance(ply) then
        if st.quartermaster and not LooksCombine(ply) then
            ply:ChatPrint("[Resistance] The quartermaster looks you over. 'I don't know you. Come back with someone who does.'")
        end
        return false
    end
    if st.quartermaster then
        ent:EmitSound(Vo(st, Pick({ "hi01", "hi02" })), 70)
        ply:ChatPrint("[Quartermaster] 'What do you need?' (Work: F4. Fighters: E on any of ours here, to bring them along.)")
        if LC.HasItem and (LC.HasItem(ply, "data_chip") or LC.HasItem(ply, "master_chip")) then
            ply:ChatPrint("[Quartermaster] 'Is that a Combine chip? Don't wave it about. Take it to the lab, the doc will decode it.'")
        end
        if LC.OpenMarket then LC.OpenMarket(ply) end
        return false
    end
    Recruit(ply, ent, st)
    return false
end)

-- Orders for the squad (F2 > Squad orders / the C menu, Resistance; or the chat shortcuts !casual, !gunsout, !meet).
LC.SlashCommands = LC.SlashCommands or {}
LC.SlashCommands.casual = function(ply)
    local n = LC.SquadCasualAll(ply, true)
    ply:ChatPrint(#FollowersOf(ply) == 0 and "[Resistance] You've nobody with you." or (n > 0 and "[Resistance] Guns away, plain clothes on. They walk like anyone else now. (Shot at, they'll fight.)" or "[Resistance] They're acting casual already."))
end
LC.SlashCommands.gunsout = function(ply)
    local n = LC.SquadCasualAll(ply, false)
    ply:ChatPrint(#FollowersOf(ply) == 0 and "[Resistance] You've nobody with you." or (n > 0 and "[Resistance] Guns out." or "[Resistance] They're armed and ready already."))
end
LC.SlashCommands.meet = function(ply)
    local fs = FollowersOf(ply)
    if #fs == 0 then return ply:ChatPrint("[Resistance] You've nobody with you.") end
    local dest = LC.QuestObjectivePos and LC.QuestObjectivePos(ply)
    if not dest then return ply:ChatPrint("[Resistance] Meet you where? Take a job first: they go on ahead to where it's taking you.") end
    for i, f in ipairs(fs) do
        local fst = LC.NPCs[f]
        if fst then
            local a = math.rad(i * 70)
            fst.meetAt = dest + Vector(math.cos(a) * 90, math.sin(a) * 90, 0)
            LC.SquadCasual(f, fst, true) -- (on their own in the streets: guns away)
            fst.goingTo = nil
        end
    end
    ply:ChatPrint("[Resistance] 'We'll meet you there.' They go on ahead, acting casual, and wait for you near the job's marker.")
end
hook.Add("PlayerSay", "LivingCitySquadOrders", function(ply, text)
    local t = string.lower(string.Trim(text or ""))
    local cmd = (t == "!casual" and "casual") or ((t == "!gunsout" or t == "!guns") and "gunsout") or (t == "!meet" and "meet") or nil
    if not cmd then return end
    LC.SlashCommands[cmd](ply)
    return ""
end)
-- (how many are with you, for the menus)
timer.Create("LivingCitySquadCount", 2, 0, function()
    for _, p in ipairs(player.GetAll()) do
        local n = #FollowersOf(p)
        if p:GetNW2Int("lc_squad_n", 0) ~= n then p:SetNW2Int("lc_squad_n", n) end
    end
end)

hook.Add("PlayerDeath", "LivingCityRebelFollowers", function(ply)
    for _, npc in ipairs(FollowersOf(ply)) do
        local st = LC.NPCs[npc]
        if st then LC.DismissFollower(npc, st, true) end
    end
end)

------------------------------------------------------------------------
-- Lookout posts (the editor's "Point: rebel lookout post")
------------------------------------------------------------------------

LC.LookoutPosts = LC.LookoutPosts or {} -- [key] = { npc, nextAt }
local function PostKey(p) return string.format("%d_%d_%d", math.floor(p.pos.x), math.floor(p.pos.y), math.floor(p.pos.z)) end
local POST_GUNS = { "weapon_smg1", "weapon_smg1", "weapon_smg1", "weapon_shotgun" }

-- What a lookout sees coming: warn (a shout, and Freq 7) when the Combine is
-- in sight on the way; open fire when they're close, or on our ground.
local function PostWarn(npc, st, who, now)
    if now < (st.post.warnedAt or 0) then return end
    st.post.warnedAt = now + 45
    Alert(ZoneAt(st.post.pos, 800), who:GetPos(), now) -- (and home hears it)
    npc:EmitSound(Vo(st, Pick(SPOTTED)), 90)
    LC.Face(npc, who:GetPos())
    local where = LC.DescribePlace and LC.DescribePlace(st.post.pos) or "at a lookout post"
    if LC.RadioNotice then
        LC.RadioNotice("resistance", string.format("%s on lookout %s: Combine coming%s!", LC.NPCStr(npc, "lc_pname", "Our lookout"), where,
            who:IsPlayer() and "" or ", the city's own"))
    end
    if who:IsPlayer() then who:ChatPrint("[Resistance] Someone shouts from up ahead: 'Combine! Coming in!' You've been seen.") end
end

function LC.LookoutPostThreat(npc, st, now)
    local post = st.post.pos
    local warn, fire = cvPostWarn:GetFloat(), cvPostFire:GetFloat()
    local best, bd
    for _, ply in ipairs(player.GetAll()) do
        if ply:Alive() and LooksCombine(ply) then
            local d2 = ply:GetPos():DistToSqr(post)
            if d2 < warn * warn and CanSee(npc, ply, warn + 200) then
                if not st.post.seen or not st.post.seen[ply] then
                    st.post.seen = st.post.seen or {}
                    st.post.seen[ply] = now
                    PostWarn(npc, st, ply, now)
                end
                local close = d2 < fire * fire or ZoneAt(ply:GetPos(), 0) ~= nil
                -- (a moment's shouting first, like the rest of them)
                if close and now - (st.post.seen[ply] or now) >= cvWarn:GetFloat() and (not bd or d2 < bd) then best, bd = ply, d2 end
            elseif st.post.seen then
                st.post.seen[ply] = nil
            end
        end
    end
    if best then return best end
    for other, ost in pairs(LC.NPCs) do
        if IsValid(other) and (LC.IsSecurity(ost) or ost.role == "scanner") and other:Health() > 0 then
            local d2 = other:GetPos():DistToSqr(post)
            if d2 < warn * warn and CanSee(npc, other, warn + 200) then
                PostWarn(npc, st, other, now)
                if d2 < fire * fire and (not bd or d2 < bd) then best, bd = other, d2 end
            end
        end
    end
    return best
end

function LC.EnsureLookoutPosts()
    local now = CurTime()
    local want = {}
    for _, p in ipairs(LC.PointsOfKind and LC.PointsOfKind("rlookout") or {}) do
        local key = PostKey(p)
        want[key] = true
        local slot = LC.LookoutPosts[key] or {}
        LC.LookoutPosts[key] = slot
        local npc = slot.npc
        if IsValid(npc) and npc:Health() > 0 and LC.NPCs[npc] then
            local st = LC.NPCs[npc]
            st.post.yaw = p.yaw or 0 -- (turned in the editor)
        elseif LC.Running and now >= (slot.nextAt or 0) and not (LC.RebelQuietAt and LC.RebelQuietAt(p.pos, 0)) then
            if slot.npc ~= nil and not slot.diedAt then slot.diedAt = now end
            if not (LC.IsSeen and LC.IsSeen(p.pos + UP)) then
                local made, st = SpawnRebel(p.pos + Vector(0, 0, 4), ZoneAt(p.pos, 800), Pick(POST_GUNS))
                if IsValid(made) then
                    st.unmanaged = true
                    st.post = { pos = p.pos, yaw = p.yaw or 0 }
                    made:SetAngles(Angle(0, p.yaw or 0, 0))
                    LC.SetNPCStr(made, "lc_pjob", "Resistance lookout")
                    made:SetNW2Bool("lc_lookout", true)
                    slot.npc, slot.diedAt = made, nil
                end
            else
                slot.nextAt = now + 5 -- (someone's watching: in a moment)
            end
        end
    end
    -- a post taken out in the editor: its lookout goes (when nobody's looking)
    for key, slot in pairs(LC.LookoutPosts) do
        if not want[key] then
            if IsValid(slot.npc) and not (LC.IsSeen and LC.IsSeen(slot.npc:GetPos() + UP)) then
                slot.npc:Remove()
                LC.LookoutPosts[key] = nil
            elseif not IsValid(slot.npc) then
                LC.LookoutPosts[key] = nil
            end
        end
    end
end

hook.Add("OnNPCKilled", "LivingCityLookoutPosts", function(npc)
    local st = LC.NPCs[npc]
    if not st or not st.post then return end
    for _, slot in pairs(LC.LookoutPosts) do
        if slot.npc == npc then slot.nextAt = CurTime() + cvPostRe:GetFloat() end
    end
    if LC.RadioNotice then
        LC.RadioNotice("resistance", "We lost the lookout " .. (LC.DescribePlace and LC.DescribePlace(st.post.pos) or "") .. ". Someone will take the post, give it time.")
    end
end)

timer.Create("LivingCityLookoutPosts", 3, 0, function()
    local ok, err = pcall(LC.EnsureLookoutPosts)
    if not ok then LC.Error("lookout posts", err) end
end)

-- One quartermaster at the heart of each rebel territory you placed (touching zones are one:
-- LC.RebelTerritories, sv_livingcity_paths.lua). One whose zone was deleted, or a second one in
-- the same territory (zones redrawn, or two zones merged into one), goes.
LC.QMDead = LC.QMDead or {}
local function EnsureQuartermasters()
    if not LC.Running or cvRebels:GetInt() <= 0 then return end
    local have = {}
    local zones = RebelZones()
    for npc, st in pairs(LC.NPCs) do
        if IsValid(npc) and st.quartermaster and npc:Health() > 0 then
            local lead = st.zone and table.HasValue(zones, st.zone) and LC.RebelLeader(st.zone)
            if not lead or have[lead] then
                LC.NPCs[npc] = nil
                npc:Remove()
            else
                have[lead] = true
            end
        end
    end
    for _, z in ipairs(zones) do
        if not z.grown and LC.RebelIsLeader(z) and not have[z] and CurTime() > (LC.QMDead[z] or 0) then
            local p = HiddenSpot(z)
            if p then
                local npc, st = LC.ManpowerFree(SpawnRebel, p + Vector(0, 0, 4), z) -- (the quartermaster has rules of their own: never from the reserve)
                if IsValid(npc) then
                    st.quartermaster, st.unmanaged = true, true
                    st.qmHome = p + Vector(0, 0, 4)
                    LC.SetNPCStr(npc, "lc_pname", "Quartermaster " .. LC.NPCStr(npc, "lc_pname", ""))
                    LC.SetNPCStr(npc, "lc_pjob", "Resistance quartermaster: gear and work")
                end
            end
        end
    end
end
LC.EnsureQuartermasters = EnsureQuartermasters

hook.Add("OnNPCKilled", "LivingCityQuartermaster", function(npc)
    local st = LC.NPCs[npc]
    if st and st.quartermaster and st.zone then
        LC.QMDead[LC.RebelLeader(st.zone)] = CurTime() + QM_RESPAWN
        if LC.RadioNotice then LC.RadioNotice("resistance", "They got the quartermaster. Someone will take his place, give it time.") end
    end
end)

timer.Create("LivingCityQuartermasters", 10, 0, function()
    local ok, err = pcall(EnsureQuartermasters)
    if not ok then LC.Error("quartermasters", err) end
end)

-- The edge of rebel ground: a warning on your screen within lc_zone_mercy of it
-- (1), and inside it (2). Units inside get shot at. Not while you stand in a
-- Combine-only zone (the owner, 7 November: with the two stacked one above the
-- other, the nexus showed the rebel warning).
function LC.RebelEdgeLevel(ply)
    if not IsValid(ply) or not ply:Alive() then return 0 end
    local p = ply:GetPos()
    if LC.InCombineZone and LC.InCombineZone(p) then return 0 end
    if LC.InRebelZone(p) then return 2 elseif LC.NearRebelZone and LC.NearRebelZone(p) then return 1 end
    return 0
end
timer.Create("LivingCityRebelEdge", 0.5, 0, function()
    for _, ply in LC.Players() do
        local v = LC.RebelEdgeLevel(ply)
        if ply:GetNW2Int("lc_rebelzone", 0) ~= v then ply:SetNW2Int("lc_rebelzone", v) end
    end
end)
