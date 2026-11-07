--[[
    Living City: the Combine's own ground

    The Combine-only zones placed with the editor (the nexus, the offices, the
    armory: "Zone: Combine only") belong to the Combine (the owner, 7 November).

    Overwatch soldiers stay in them. A soldier with nothing to do walks from
    one spot to another inside the nearest Combine zone, or stands post there,
    instead of patrolling the streets. They come out only when deployed:
      for a job or a quest (an escort, a cleanup crew's guards, a story),
      as backup a unit called for, a response squad, a raid,
      a skirmish with the Resistance (a firefight in the streets),
      a lockdown (it answers violence), or
      sociostability at its worst level (red).
    The city's own soldiers (lc_soldiers) also spawn there, out of sight.
    With no Combine zone placed, soldiers patrol as they always did.

    Citizens never go in, except prisoners (and those being taken to a cell or
    out of one) and anyone a job or story is about. No walk of theirs may end
    inside one, and a citizen found inside is walked straight back out (put
    outside out of sight, if they can't find the way).

    Work that needs doing in there (litter, a dead headcrab, a mess, graffiti,
    a body, a broken streetlight or loudspeaker) isn't left to the city's
    sanitation workers, morticians or repairmen: each Combine zone's resident
    stalkers do it (sv_livingcity_zonestalkers.lua).

    Rebel territory's warning on screen ("REBEL TERRITORY AHEAD", "REBEL
    TERRITORY") is not shown to anyone standing inside a Combine zone: on maps
    where the two are stacked one above the other, the nexus isn't rebel
    ground (sv_livingcity_rebels.lua).

    Dead headcrabs left lying about go the way bodies do: one nobody has
    picked up or bagged after lc_body_time seconds is gone, once nobody is
    near enough to see it.
]]

if CLIENT then return end

LC = LC or {}

local UP = Vector(0, 0, 40)

local function Zones() return LC.ZonesOfKindShared and LC.ZonesOfKindShared("combine") or {} end

-- Inside a Combine-only zone (right to its edge: no mercy either way).
function LC.InCombineZone(pos)
    if not pos or not LCZ then return nil end
    for _, z in ipairs(Zones()) do if LCZ.Contains(z, pos, 0) then return z end end
    return nil
end
local InCombine = LC.InCombineZone

local function NearestZone(pos)
    local best, bd
    for _, z in ipairs(Zones()) do
        local d = z.pos:DistToSqr(pos)
        if not bd or d < bd then best, bd = z, d end
    end
    return best
end

------------------------------------------------------------------------
-- Overwatch soldiers stay home
------------------------------------------------------------------------

local function Worst() return LCCP and LCCP.SocioOrder and LCCP.SocioOrder[#LCCP.SocioOrder] or "red" end

-- Is the whole Overwatch garrison out on the streets? Why, if so.
function LC.SoldiersDeployed()
    if LC.Socio and LC.Socio == Worst() then return "sociostability " .. tostring(LC.Socio) end
    if LC.Skirmish then return "a firefight with the Resistance" end
    if LC.Event == "lockdown" then return "a lockdown" end
    return nil
end

-- Has this soldier been sent somewhere (a job, a quest, backup, a squad)?
function LC.SoldierOnDuty(npc, st)
    if not st then return true end
    return st.questLock or st.raid or st.skirmish or st.responder or st.withdrawing or st.workEscort or st.backupFor
        or st.adminGuard or st.cleanGuard or st.holdPos or st.guardZone or st.exUnit or st.leaving
        or (LC.ResponseSquads and LC.ResponseSquads[npc]) or false
end

-- Does the rule hold right now (a Combine zone placed, nothing serious going on)?
function LC.SoldierHomeRule()
    return #Zones() > 0 and LC.SoldiersDeployed() == nil
end

function LC.SoldierHomeBound(npc, st)
    return st ~= nil and st.role == "soldier" and LC.SoldierHomeRule() and not LC.SoldierOnDuty(npc, st)
end

-- A spot inside a Combine zone (not the prison's part of it: the guards have that).
local function SpotIn(z)
    for _ = 1, 4 do
        local p = LC.SpotInZone and LC.SpotInZone(z)
        if p and not (LC.PrisonZoneAt and LC.PrisonZoneAt(p)) then return p end
    end
    return nil
end

-- Called when an idle soldier picks what to do next (sv_livingcity.lua). True: handled.
function LC.SoldierGoHome(npc, st, now, run)
    if not LC.SoldierHomeBound(npc, st) then return false end
    local pos = npc:GetPos()
    local here = InCombine(pos)
    local z = here or NearestZone(pos)
    if not z then return false end
    -- inside: a while standing post, now and then
    if here and math.random() < 0.4 then
        if npc.SetSchedule then npc:SetSchedule(SCHED_IDLE_STAND) end
        st.untilT = now + math.Rand(8, 25)
        return true
    end
    local p = SpotIn(z)
    if p and LC.GoTo(npc, st, p, run, nil) then return true end
    st.untilT = now + 5
    return true
end

-- Where the city's own soldiers spawn while the rule holds: in a Combine zone, out of sight.
function LC.SoldierHomeSpawnPos()
    if not LC.SoldierHomeRule() then return nil end
    local zs = Zones()
    for _ = 1, 8 do
        local p = SpotIn(zs[math.random(#zs)])
        if p and not LC.IsSeen(p + UP) and (not LC.FarFromPlayers or LC.FarFromPlayers(p, 250)) then return p + Vector(0, 0, 4) end
    end
    return nil
end

------------------------------------------------------------------------
-- Citizens stay out
------------------------------------------------------------------------

-- Who may be in there all the same: prisoners, anyone on their way to a cell or out of one, and
-- anyone a job or story is about (it may have put them there on purpose).
function LC.CitizenMayEnterCombine(npc, st)
    if not st or st.role ~= "citizen" then return true end
    if st.test or st.questLock or st.jailUntil then return true end
    local s = st.state
    if s == "jailed" or s == "detained" or s == "escorted" then return true end
    if LC.Prisoners and LC.Prisoners[npc] then return true end
    if LC.InSomeonesJob and LC.InSomeonesJob(npc, st) then return true end
    return false
end

-- May this citizen not go to pos (sv_livingcity.lua's LC.GoTo, the city's work)?
function LC.CitizenBarredAt(npc, st, pos)
    if not st or st.role ~= "citizen" or not pos then return false end
    if not InCombine(pos) then return false end
    return not LC.CitizenMayEnterCombine(npc, st)
end

LC.CombineGroundStats = LC.CombineGroundStats or { walkedOut = 0, putOut = 0, barred = 0 }
local Stats = LC.CombineGroundStats

-- Anyone inside who shouldn't be: walked out, or put outside out of sight.
function LC.CombineGroundTick(now)
    if #Zones() == 0 then return end
    for npc, st in pairs(LC.NPCs or {}) do
        if st.role == "citizen" and IsValid(npc) and npc:Health() > 0 then
            local pos = npc:GetPos()
            if InCombine(pos) and not LC.CitizenMayEnterCombine(npc, st) then
                st.combineSince = st.combineSince or now
                local leaving = st.state == "moving" and st.dest and not InCombine(st.dest)
                if now - st.combineSince > 20 and not LC.IsSeen(pos + UP) then
                    -- can't find the way: outside, somewhere a citizen may stand
                    local spot = LC.SafeCitizenSpot and LC.SafeCitizenSpot()
                    if LC.NPCWorkReset then LC.NPCWorkReset(npc, st) end
                    if LC.Release then LC.Release(npc, st) end
                    if spot then
                        npc:SetPos(spot)
                        if npc.SetSchedule then npc:SetSchedule(SCHED_IDLE_STAND) end
                        if LC.SetState then LC.SetState(npc, st, "idle") end
                        st.untilT = now + 1
                    else
                        npc:Remove()
                    end
                    st.combineSince = nil
                    Stats.putOut = Stats.putOut + 1
                elseif not leaving then
                    if LC.NPCWorkReset then LC.NPCWorkReset(npc, st) end
                    if LC.Release then LC.Release(npc, st) end
                    local out = LC.RandomWanderPos and LC.RandomWanderPos("citizen", pos)
                    if out and InCombine(out) then out = nil end
                    out = out or (LC.SafeCitizenSpot and LC.SafeCitizenSpot())
                    if out and LC.GoTo(npc, st, out, false, nil) then Stats.walkedOut = Stats.walkedOut + 1 end
                end
            else
                st.combineSince = nil
            end
        end
    end
end

timer.Create("LivingCityCombineGround", 2, 0, function()
    if not LC.Running then return end
    local ok, err = pcall(LC.CombineGroundTick, CurTime())
    if not ok and LC.Error then LC.Error("combine ground", err) end
end)

------------------------------------------------------------------------
-- The work in there is the stalkers' (sv_livingcity_zonestalkers.lua)
------------------------------------------------------------------------

local function Taken(e)
    return e.lcStalkerTaken or e.lcBagging or (e.GetParent and IsValid(e:GetParent()))
end
LC.StalkerTakenItem = Taken

------------------------------------------------------------------------
-- Dead headcrabs don't lie about for ever
------------------------------------------------------------------------

function LC.CarcassDecayTick(now)
    local cv = GetConVar("lc_body_time")
    local secs = cv and cv:GetFloat() or 300
    local n = 0
    for _, e in ipairs(LC.EntsOf and LC.EntsOf("lc_item") or {}) do
        if IsValid(e) and LC.CrabCarcass and LC.CrabCarcass(e) and not Taken(e) and now - (e.lcBorn or now) > secs then
            local p = e:GetPos()
            if (not LC.FarFromPlayers or LC.FarFromPlayers(p, 600)) and not LC.IsSeen(p + Vector(0, 0, 10)) then
                e:Remove()
                n = n + 1
            end
        end
    end
    return n
end

timer.Create("LivingCityCarcassDecay", 15, 0, function()
    if not LC.Running then return end
    local ok, err = pcall(LC.CarcassDecayTick, CurTime())
    if not ok and LC.Error then LC.Error("carcass decay", err) end
end)
