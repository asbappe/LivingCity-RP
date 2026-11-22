--[[
    Living City: people

    The city has a roster of named people. Every citizen NPC (and every Civil
    Protection unit) you meet is someone, with a profile that never changes:

      name, sex and model   the same face every time you see them
      job                   a Union job, and they spend part of their day at
                            its workplaces
      home                  a housing block, and that's where they go for curfew
      loyalty               some are secretly Resistance sympathizers. Fellow
                            Resistance members can tell, and the Resistance's
                            contacts are drawn from them

    How many of them are out on the streets at once is still set by
    lc_citizens and lc_cops: the rest are at work, at home, or elsewhere. The
    roster is saved per map (garrysmod/data/livingcity/<map>_people.json) and
    survives restarts, so it's the same people next session. A person who is
    killed stays dead; the city fills the gap with new arrivals.

    People stay (the owner, 15 November 2026: "they need to be persistent.
    They stay until they DIE"). There are always at least as many named
    citizens as lc_citizens, so nobody on the streets is a nameless extra;
    nobody is swapped out on a timer (lc_citizen_lifetime is retired); a
    person who goes indoors (night, curfew, worn down) is at home for a
    while and then comes back out as themselves. The only ways out of the
    city are dying, and for someone in despair, the train to another city.

    Every Union job is staffed: one person each in a city of about a dozen,
    up to four each from about a hundred (the roster plus the players),
    filled from the unemployed and then the most crowded trades; and a job
    nobody on the streets is doing comes out first.

    lc_roster_size, lc_roster_cops, lc_rebel_pct.
    Admin: lc_people (summary), lc_resetpeople (start the city's people over).
]]

if CLIENT then return end

LC = LC or {}

local FLAGS = bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED)
local cvSize  = CreateConVar("lc_roster_size", "30", FLAGS, "Named citizens in the city, however many are on the streets right now")
local cvCops  = CreateConVar("lc_roster_cops", "10", FLAGS, "Named Civil Protection units in the city")
local cvRebel = CreateConVar("lc_rebel_pct", "12", FLAGS, "Percent of the city's citizens who are secretly Resistance sympathizers")

local MALE   = { "male_01", "male_02", "male_03", "male_04", "male_05", "male_06", "male_07", "male_08", "male_09" }
local FEMALE = { "female_01", "female_02", "female_03", "female_04", "female_06", "female_07" }

local function File() return "livingcity/" .. game.GetMap() .. "_people.json" end

LC.People = LC.People or { next = 1, list = {}, loaded = false }
local P = LC.People

local function Pick(t) return t[math.random(#t)] end

------------------------------------------------------------------------
-- Saving and loading
------------------------------------------------------------------------

local dirty = false
local function MarkDirty() dirty = true end
LC.MarkPeopleDirty = MarkDirty

function LC.SavePeople()
    dirty = false
    if not file or not file.Write then return end
    if file.CreateDir then file.CreateDir("livingcity") end
    local out = { next = P.next, list = {} }
    for _, p in ipairs(P.list) do
        out.list[#out.list + 1] = {
            id = p.id, role = p.role, name = p.name, gender = p.gender, model = p.model, job = p.job, home = p.home,
            rebel = p.rebel or nil, alive = p.alive, born = p.born, lastSeen = p.lastSeen, died = p.died, killer = p.killer,
            moved = p.moved, -- left for another city by train (not dead)
            newcomer = p.newcomer or nil, -- new to the city, not out yet: comes in on the next train

            memory = p.memory, -- how each player's character has treated them (sv_livingcity_talk.lua)
            oldtimer = p.oldtimer or nil, -- the old man who gives advice (sv_livingcity_oldtimer.lua)
            helped = p.helped, -- what each player's character has helped him with (sv_livingcity_oldtimer.lua)
        }
    end
    LC.SafeWrite(File(), util.TableToJSON(out))
end

function LC.LoadPeople()
    P.loaded = true
    P.list, P.next = {}, 1
    do
        local t = LC.SafeReadJSON(File())
        if istable(t) and istable(t.list) then
            P.next = tonumber(t.next) or 1
            for _, p in ipairs(t.list) do
                if p.id and p.name then
                    p.alive = p.alive ~= false
                    p.role = p.role or "citizen"
                    -- rosters from before names matched faces: the face follows the name
                    local g = p.role == "citizen" and LC.NameGender and LC.NameGender(p.name)
                    if g and g ~= p.gender then
                        p.gender = g
                        p.model = "models/humans/group01/" .. Pick(g == "male" and MALE or FEMALE) .. ".mdl"
                        MarkDirty()
                    end
                    P.list[#P.list + 1] = p
                    P.next = math.max(P.next, p.id + 1)
                end
            end
        end
    end
    return #P.list
end

------------------------------------------------------------------------
-- Making people
------------------------------------------------------------------------

local function NameTaken(name)
    for _, p in ipairs(P.list) do if p.alive and p.name == name then return true end end
    return false
end

LC.PersonNameTaken = NameTaken

local function BlockNumbers() return LC.BlockNumbers and LC.BlockNumbers() or {} end

------------------------------------------------------------------------
-- Staffing: every Union job has people on it, more as the city grows
------------------------------------------------------------------------

-- How many of the city's people each job should have: one each in a city of
-- a dozen, two at thirty, three at sixty, four from about a hundred
-- (people: the roster plus the players).
function LC.JobStaffTarget()
    local n = 0
    for _, p in ipairs(P.list) do if p.alive and p.role == "citizen" then n = n + 1 end end
    n = n + #player.GetAll()
    return math.Clamp(math.floor(n / 28) + 1, 1, 4)
end

local function JobCounts()
    local count = {}
    for _, p in ipairs(P.list) do
        if p.alive and p.role == "citizen" and p.job then count[p.job] = (count[p.job] or 0) + 1 end
    end
    return count
end

-- The job that most needs a person (nil: every job has its share).
function LC.NeediestJob()
    if not LCJ then return nil end
    local target, count = LC.JobStaffTarget(), JobCounts()
    local best, bn
    for _, o in ipairs(LCJ.Occupations) do
        local n = count[o.id] or 0
        if not o.playersOnly and n < target and (not bn or n < bn or (n == bn and math.random() < 0.5)) then best, bn = o.id, n end
    end
    return best
end

local function RandomJob()
    if not LCJ then return nil end
    local need = LC.NeediestJob()
    if need then return need end
    if math.random() > 0.6 then return nil end -- every job is covered: the rest are between jobs, or extra hands
    local open = {}
    for _, o in ipairs(LCJ.Occupations) do if not o.playersOnly then open[#open + 1] = o end end
    return #open > 0 and Pick(open).id or nil
end

-- Fill the gaps, the emptiest job first: from the unemployed, then from the
-- most crowded job.
function LC.StaffRoster()
    if not LCJ then return 0 end
    local target, count = LC.JobStaffTarget(), JobCounts()
    local idle = {}
    for _, p in ipairs(P.list) do if p.alive and p.role == "citizen" and not p.job then idle[#idle + 1] = p end end
    local moved = 0
    for _ = 1, 200 do
        local need, nn
        for _, o in ipairs(LCJ.Occupations) do
            local n = count[o.id] or 0
            if not o.playersOnly and n < target and (not nn or n < nn) then need, nn = o, n end
        end
        if not need then break end
        local p = table.remove(idle)
        if not p then
            local most, mn
            for j, n in pairs(count) do if n > target and (not mn or n > mn) then most, mn = j, n end end
            if not most then break end
            for _, q in ipairs(P.list) do if q.alive and q.role == "citizen" and q.job == most then p = q break end end
            if not p then break end
            count[most] = count[most] - 1
        end
        p.job = need.id
        count[need.id] = (count[need.id] or 0) + 1
        moved = moved + 1
        if IsValid(p.npc) then LC.SetNPCStr(p.npc, "lc_pjob", need.name or "") end
    end
    if moved > 0 then MarkDirty() end
    return moved
end

function LC.NewPerson(role, want)
    want = want or {}
    local p = { id = P.next, role = role or "citizen", alive = true, born = os.time(), lastSeen = 0 }
    P.next = P.next + 1
    if p.role == "cop" then
        local n
        repeat n = math.random(10, 99) until not NameTaken("Unit " .. n) or math.random() < 0.02
        p.name, p.gender, p.model = "Unit " .. n, "male", "models/police.mdl"
    else
        -- the face first, then a name that goes with it
        p.gender = want.gender or (math.random() < 0.5 and "male" or "female")
        local name
        for _ = 1, 30 do
            name = LC.NewCharacterName and (LC.NewCharacterName(p.gender)) or ("Citizen " .. p.id)
            if not NameTaken(name) then break end
        end
        p.name = name
        p.model = "models/humans/group01/" .. Pick(p.gender == "male" and MALE or FEMALE) .. ".mdl"
        p.job = RandomJob()
        local blocks = BlockNumbers()
        if #blocks > 0 then p.home = Pick(blocks) end
        p.rebel = want.rebel == true or math.random() * 100 < cvRebel:GetFloat() * (LC.RebelStandingSympathyMul and LC.RebelStandingSympathyMul() or 1) or nil
    end
    P.list[#P.list + 1] = p
    MarkDirty()
    return p
end

local function Alive(role)
    local n = 0
    for _, p in ipairs(P.list) do if p.alive and p.role == role then n = n + 1 end end
    return n
end

local function InWorld(p) return IsValid(p.npc) end

-- Keep the roster at its size: arrivals fill the places of the dead.
function LC.TopUpPeople()
    if not P.loaded then LC.LoadPeople() end
    -- never fewer named citizens than the streets want: nobody out there is a nameless extra
    local streets = GetConVar("lc_citizens")
    local size = math.max(cvSize:GetInt(), streets and streets:GetInt() or 0)
    -- the city's first people were always here; anyone after them is new to the city, and comes in
    -- on a train (LC.ClaimProfile)
    local first = #P.list == 0
    while Alive("citizen") < size do
        local p = LC.NewPerson("citizen")
        if not first then p.newcomer = true end
    end
    -- the same for Civil Protection: as many named units as the city has out (lc_cops, and the extra
    -- units it brings in), never a nameless one
    local cops = GetConVar("lc_cops")
    local units = math.max(cvCops:GetInt(), (cops and cops:GetInt() or 0) + (LC.ExtraCops or 0) + (LC.ImbalanceCops or 0) + (LC.LedgerCops or 0))
    while Alive("cop") < units do LC.NewPerson("cop") end
    LC.StaffRoster()
    -- the dead are remembered, but not forever
    local dead = 0
    for i = #P.list, 1, -1 do
        if not P.list[i].alive then
            dead = dead + 1
            if dead > 150 then table.remove(P.list, i) end
        end
    end
end

-- Going indoors: how long they are at home before they can come back out
-- (real seconds, low to high), by the reason they went (the start of it).
local HOME = {
    { "worn down", 240, 480 },
    { "despair", 480, 900 },
    { "let out of prison", 180, 300 },
    { "the time of day", 60, 120 },
    { "curfew", 20, 40 },
}
function LC.PersonWentHome(p, why)
    if not p then return end
    local lo, hi = 90, 180
    for _, h in ipairs(HOME) do
        if why and string.sub(why, 1, #h[1]) == h[1] then lo, hi = h[2], h[3] break end
    end
    p.wentHome = math.random(lo, hi)
end
-- (the game's clock, and kept in memory only: after a restart everyone is free to come out)
local function AtHome(p) return (p.homeUntil or 0) > CurTime() end

-- Trains bring the newcomers when the city has them: on, with a platform (sv_livingcity_trains.lua).
local function TrainsBring()
    local cv = GetConVar("lc_trains")
    return cv and cv:GetBool() and LC.TrainPlatforms and #LC.TrainPlatforms() > 0 or false
end
LC.TrainsBringNewcomers = TrainsBring

-- Could this person come out now, as asked? Alive, indoors, their time at home over; off a train
-- (want.newcomer) only someone new to the city. (Someone new comes out onto the street too, but last:
-- LC.NextPerson. So the streets never run short, and the train brings who is left of them.)
local function Free(p, role, want)
    if not (p.alive and p.role == role and not InWorld(p) and not AtHome(p)) then return false end
    if want.rebel and not p.rebel then return false end
    if want.gender and p.gender ~= want.gender then return false end
    if want.newcomer then return p.newcomer == true end
    return true
end

-- Is there anyone of this role who could come out now (alive, indoors, their time at home over)?
-- want.newcomer: someone new to the city, for a train to bring.
function LC.PersonAvailable(role, want)
    if not P.loaded then LC.LoadPeople() end
    LC.TopUpPeople()
    want = want or {}
    for _, p in ipairs(P.list) do
        if Free(p, role, want) then return true end
    end
    return false
end

-- A mandatory call by day (her address, the morning exercise, a parade, a ration handout): everyone at home
-- is free to come out now, their time indoors cut short (the owner, 15 November: "please make sure all the
-- citizen NPCs show up"). How many that frees. (Whoever is leaving the city for good stays gone.)
function LC.PeopleCallOut(role)
    if not P.loaded then LC.LoadPeople() end
    role = role or "citizen"
    local n = 0
    for _, p in ipairs(P.list) do
        if p.alive and p.role == role and not InWorld(p) and AtHome(p) and not p.moving then
            p.homeUntil = 0
            n = n + 1
        end
    end
    return n
end

-- Who would come out next, without taking them yet (the same choice LC.ClaimProfile makes).
function LC.NextPerson(role, want)
    if not P.loaded then LC.LoadPeople() end
    want = want or {}
    local trains = TrainsBring()
    -- a job nobody out there is doing comes first, so every trade has someone on the streets
    local working = {}
    for _, p in ipairs(P.list) do if p.alive and InWorld(p) and p.job then working[p.job] = true end end
    local best, bt
    for _, p in ipairs(P.list) do
        if Free(p, role, want) then
            local t = (p.lastSeen or 0) + math.random() * 30 -- a little shuffle among equals
            if role == "citizen" and p.job and not working[p.job] then t = t - 1e9 end
            -- someone new to the city waits for the train while trains run: onto the street only when nobody else can
            if p.newcomer and trains and not want.newcomer then t = t + 1e12 end
            if not bt or t < bt then best, bt = p, t end
        end
    end
    return best
end

-- Somewhere in a person's own block, out of everyone's sight, for them to come back out at
-- (the block they walked into when they went home). nil: no block, or nowhere unseen in it.
function LC.PersonHomeSpot(p)
    if not (p and p.home and LC.SpotInZone) then return nil end
    local zones = {}
    for _, z in ipairs(LC.ZonesOfKind and LC.ZonesOfKind("block") or {}) do if (z.group or 0) == p.home then zones[#zones + 1] = z end end
    if #zones == 0 then return nil end
    for _ = 1, 6 do
        local spot = LC.SpotInZone(Pick(zones))
        if spot and not (LC.IsSeen and LC.IsSeen(spot + Vector(0, 0, 30)))
            and (not LC.FarFromPlayers or LC.FarFromPlayers(spot, 250))
            and (not LC.CitizenSpotOK or LC.CitizenSpotOK(spot)) then
            return spot + Vector(0, 0, 4)
        end
    end
    return nil
end

-- Who comes out next: someone not already out there, and whoever has been
-- away longest. want.rebel asks for a sympathizer, want.job for a particular trade,
-- want.person for someone already chosen (LC.NextPerson), want.newcomer for someone new to the city.
function LC.ClaimProfile(role, want)
    if not P.loaded then LC.LoadPeople() end
    LC.TopUpPeople()
    want = want or {}
    local best
    if want.person and Free(want.person, role, want) then best = want.person end
    best = best or LC.NextPerson(role, want)
    if not best and (want.rebel or want.gender) then
        best = LC.NewPerson(role, want) -- the Resistance can always find someone, and a story its character
    end
    if best then
        best.lastSeen = os.time()
        best.newcomer = nil -- (in the city now)
        MarkDirty()
    end
    return best
end

-- Put a person into an NPC they've just been spawned as.
function LC.AttachProfile(npc, st, p)
    npc.lcProfile = p
    p.npc = npc
    p.moving, p.wentHome = nil, nil -- (out again: whatever they were on their way to do last time is over)
    st.profile = p
    LC.SetNPCStr(npc, "lc_pname", p.name)
    npc:SetNW2Int("lc_pid", p.id)
    if p.role == "citizen" then
        if p.model then npc:SetModel(p.model) end
        if LC.DressPerson then LC.DressPerson(npc, p) end -- (their job's clothes: sv_livingcity_outfits.lua)
        st.gender = p.gender or st.gender
        local job = p.job and LCJ and LCJ.ById[p.job]
        LC.SetNPCStr(npc, "lc_pjob", job and job.name or "")
        npc:SetNW2Bool("lc_prebel", p.rebel == true)
        st.rebel = p.rebel == true
    end
end

------------------------------------------------------------------------
-- Deaths and departures
------------------------------------------------------------------------

hook.Add("EntityRemoved", "LivingCityPeople", function(ent)
    local p = ent.lcProfile
    if p and p.npc == ent then
        p.npc = nil
        p.lastSeen = os.time()
        if p.wentHome then p.homeUntil, p.wentHome = CurTime() + p.wentHome, nil end
        -- boarded the train for good (sv_livingcity.lua, StartLeaving): gone from this city, not dead
        if p.moving and p.alive then
            p.alive, p.moving, p.moved = false, nil, os.time()
            LC.Log("info", string.format("%s left for another city by train", p.name))
            hook.Run("LivingCityPersonMoved", p)
        end
        MarkDirty()
    end
end)

hook.Add("OnNPCKilled", "LivingCityPeople", function(npc, attacker)
    local p = npc.lcProfile
    if not p or not p.alive then return end
    p.alive = false
    p.died = os.time()
    if IsValid(attacker) then
        p.killer = attacker:IsPlayer() and (LC.CharacterName and LC.CharacterName(attacker) or attacker:Nick()) or attacker:GetClass()
    end
    MarkDirty()
    LC.Log("info", string.format("%s (%s) was killed%s", p.name, p.role, p.killer and (" by " .. p.killer) or ""))
    hook.Run("LivingCityPersonKilled", p, attacker)
end)

timer.Create("LivingCityPeopleSave", 10, 0, function()
    if dirty then LC.SavePeople() end
end)
hook.Add("ShutDown", "LivingCityPeople", function() if dirty then LC.SavePeople() end end)

hook.Add("InitPostEntity", "LivingCityPeople", function()
    timer.Simple(1, function()
        local ok, err = LC.Try(function() LC.LoadPeople() LC.TopUpPeople() end)
        if not ok then LC.Error("people", err) end
    end)
end)

------------------------------------------------------------------------
-- What they do with their days
------------------------------------------------------------------------

-- Their own workplace points, if they have a job and the map has places for it.
function LC.WorkplaceFor(st)
    local p = st.profile
    local job = p and p.job and LCJ and LCJ.ById[p.job]
    if not job then return nil end
    local pts = LC.PointsOfKind("work", job.num)
    if #pts == 0 then return nil end
    return pts[math.random(#pts)]
end

-- Their own block, for curfew.
function LC.HomeZoneFor(st)
    local p = st.profile
    if not p or not p.home then return nil end
    local zones = {}
    for _, z in ipairs(LC.ZonesOfKind("block")) do if (z.group or 0) == p.home then zones[#zones + 1] = z end end
    if #zones == 0 then return nil end
    return zones[math.random(#zones)]
end

------------------------------------------------------------------------
-- Commands
------------------------------------------------------------------------

local function Say(ply, msg) if IsValid(ply) then ply:ChatPrint(msg) else print(msg) end end

concommand.Add("lc_people", function(ply, _, args)
    if IsValid(ply) and not ply:IsAdmin() then return end
    if not P.loaded then LC.LoadPeople() end
    local out, dead, rebels, withJob = 0, 0, 0, 0
    for _, p in ipairs(P.list) do
        if p.alive then
            if InWorld(p) then out = out + 1 end
            if p.rebel then rebels = rebels + 1 end
            if p.job then withJob = withJob + 1 end
        else
            dead = dead + 1
        end
    end
    Say(ply, string.format("[Miscount] %d citizens and %d Civil Protection units alive (%d out now), %d sympathizers, %d with jobs, %d dead remembered",
        Alive("citizen"), Alive("cop"), out, rebels, withJob, dead))
    if args[1] == "list" then
        for _, p in ipairs(P.list) do
            if p.alive and InWorld(p) then
                Say(ply, string.format("  %s%s%s", p.name, p.job and (" (" .. p.job .. ")") or "", p.rebel and " [sympathizer]" or ""))
            end
        end
    end
end)

concommand.Add("lc_resetpeople", function(ply)
    if IsValid(ply) and not ply:IsSuperAdmin() then return end
    for _, p in ipairs(P.list) do
        if IsValid(p.npc) then p.npc.lcProfile = nil end
    end
    P.list, P.next, P.loaded = {}, 1, true
    LC.TopUpPeople()
    LC.SavePeople()
    Say(ply, "[Miscount] The city's people have been replaced. People already on the streets keep their old faces until they leave.")
end)
