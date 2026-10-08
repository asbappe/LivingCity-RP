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
    lc_citizens and lc_cops: the rest are at work, at home, or elsewhere, and
    take their turn. The roster is saved per map (garrysmod/data/livingcity/
    <map>_people.json) and survives restarts, so it's the same people next
    session. A person who is killed stays dead; the city fills the gap with
    new arrivals.

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
            memory = p.memory, -- how each player's character has treated them (sv_livingcity_talk.lua)
        }
    end
    file.Write(File(), util.TableToJSON(out))
end

function LC.LoadPeople()
    P.loaded = true
    P.list, P.next = {}, 1
    if file and file.Exists and file.Exists(File(), "DATA") then
        local t = util.JSONToTable(file.Read(File(), "DATA") or "")
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

local function RandomJob()
    if not LCJ or math.random() > 0.7 then return nil end -- the rest are between jobs
    return Pick(LCJ.Occupations).id
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
        p.rebel = want.rebel == true or math.random() * 100 < cvRebel:GetFloat() or nil
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
    while Alive("citizen") < cvSize:GetInt() do LC.NewPerson("citizen") end
    while Alive("cop") < cvCops:GetInt() do LC.NewPerson("cop") end
    -- the dead are remembered, but not forever
    local dead = 0
    for i = #P.list, 1, -1 do
        if not P.list[i].alive then
            dead = dead + 1
            if dead > 150 then table.remove(P.list, i) end
        end
    end
end

-- Who comes out next: someone not already out there, and whoever has been
-- away longest. want.rebel asks for a sympathizer, want.job for a particular trade.
function LC.ClaimProfile(role, want)
    if not P.loaded then LC.LoadPeople() end
    LC.TopUpPeople()
    want = want or {}
    local best, bt
    for _, p in ipairs(P.list) do
        if p.alive and p.role == role and not InWorld(p) and (not want.rebel or p.rebel)
            and (not want.gender or p.gender == want.gender) then
            local t = (p.lastSeen or 0) + math.random() * 30 -- a little shuffle among equals
            if not bt or t < bt then best, bt = p, t end
        end
    end
    if not best and (want.rebel or want.gender) then
        best = LC.NewPerson(role, want) -- the Resistance can always find someone, and a story its character
    end
    if best then
        best.lastSeen = os.time()
        MarkDirty()
    end
    return best
end

-- Put a person into an NPC they've just been spawned as.
function LC.AttachProfile(npc, st, p)
    npc.lcProfile = p
    p.npc = npc
    st.profile = p
    npc:SetNW2String("lc_pname", p.name)
    npc:SetNW2Int("lc_pid", p.id)
    if p.role == "citizen" then
        if p.model then npc:SetModel(p.model) end
        st.gender = p.gender or st.gender
        local job = p.job and LCJ and LCJ.ById[p.job]
        npc:SetNW2String("lc_pjob", job and job.name or "")
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
        local ok, err = pcall(function() LC.LoadPeople() LC.TopUpPeople() end)
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
    Say(ply, string.format("[Living City] %d citizens and %d units alive (%d out now), %d sympathizers, %d with jobs, %d dead remembered",
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
    Say(ply, "[Living City] The city's people have been replaced. People already on the streets keep their old faces until they leave.")
end)
