--[[
    Living City: the trains

    With a train platform on the map (an editor point, "Point: train platform";
    or failing that, the Intake Processor's workplace), a train comes in every
    lc_train_minutes (24, give or take). A horn at the platform, a notice
    for everyone, and a few new arrivals step off, suitcase in hand, and walk
    to their housing blocks. For a minute and a half after, anyone leaving the
    city (their day is done) walks to the platform with a suitcase and
    boards, instead of going out through a doorway. Then the train pulls out.

    A real train (the owner, 20 November: "the train has to actually show up for
    those to trigger"; 25 November: "let's wire this up and not flip it on in the
    gamemode yet"): with lc_train_real 1 (0 by default) on a map that has a train
    to the station, nothing arrives until the map's train has. When one is due
    the gamemode Triggers the map's relay lc_train_station_run; the map Triggers
    its relay lc_train_station_arrived when the train stands at the station, and
    only then do the horn, the notice and the arrivals happen. A train the map
    sends by itself counts too, if half the usual wait has passed. While that
    line's tracks lie wrecked (an IED: sv_livingcity_ied.lua) no train is called.
    On a map without those two names, and with the setting off, all is as before.

    Intake Processors are told when a train is in (their "New arrivals" shift
    is the time to work the platform). lc_trains 0 turns them off;
    lc_train (admin) brings one in now.
]]

if CLIENT then return end

LC = LC or {}

local FLAGS = bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED)
local cvOn      = CreateConVar("lc_trains", "1", FLAGS, "Trains come into the station now and then, with new arrivals; people leaving the city board them")
local cvMinutes = CreateConVar("lc_train_minutes", "24", FLAGS, "Minutes between trains (give or take a quarter)")
local cvReal    = CreateConVar("lc_train_real", "0", FLAGS, "New arrivals wait for the map's own train to reach the station (needs lc_train_station_run and lc_train_station_arrived in the map)")
local BOARDING = 90

local ORIGINS = { "City 14", "the coast", "the industrial district", "City 9", "the outlands transfer", "Nova Prospekt processing" }
local SUITCASE = "models/props_c17/suitcase001a.mdl"

LC.Train = LC.Train or { nextAt = 0, boardingUntil = 0, platform = nil }
local T = LC.Train

local function Pick(t) return t[math.random(#t)] end

function LC.TrainPlatforms()
    local pts = LC.PointsOfKind("platform")
    if #pts > 0 then return pts end
    local job = LCJ and LCJ.ById and LCJ.ById.porter
    return job and LC.PointsOfKind("work", job.num) or {}
end

-- A spot on the platform, near where the train stopped.
local function OnPlatform(p)
    for _ = 1, 6 do
        local pos = p.pos + Vector(math.Rand(-120, 120), math.Rand(-120, 120), 8)
        if not LC.ClearSpot or LC.ClearSpot(pos) then return pos end
    end
    return p.pos + Vector(0, 0, 8)
end

-- Where a new arrival lives: their own block, a block, or a doorway.
local function Home(st, from)
    local z = LC.HomeZoneFor and LC.HomeZoneFor(st)
    if not z then
        local blocks = LC.ZonesOfKind("block")
        if #blocks > 0 then z = Pick(blocks) end
    end
    local spot = z and LC.SpotInZone and LC.SpotInZone(z)
    if spot then return spot end
    local doors = LC.PointsOfKind("spawn")
    return #doors > 0 and Pick(doors).pos or nil
end

function LC.TrainArrive(force)
    if not force and (not cvOn:GetBool() or not LC.Running) then return false end
    local plats = LC.TrainPlatforms()
    if #plats == 0 then return false end
    local p = Pick(plats)
    local now = CurTime()
    T.platform, T.boardingUntil = p, now + BOARDING
    T.nextAt = now + cvMinutes:GetFloat() * 60 * math.Rand(0.75, 1.25)
    if sound and sound.Play then sound.Play("ambient/alarms/train_horn2.wav", p.pos, 110) end
    local from = Pick(ORIGINS)
    local where = LC.DescribePlace and LC.DescribePlace(p.pos) or "at the station"
    for _, ply in ipairs(player.GetAll()) do
        ply:ChatPrint("[Station] The train from " .. from .. " has arrived " .. where .. ".")
        if ply:GetNW2String("lcj_job", "") == "porter" then ply:ChatPrint("[Union] A train is in. Arrivals on the platform: your shift.") end
    end
    -- who gets off: new faces, each with a suitcase, going home
    local arrivals = {}
    local budget = GetConVar("lc_npc_budget")
    local room = budget and ((LC.NPCBudget and LC.NPCBudget() or budget:GetInt()) - table.Count(LC.NPCs or {})) or 4
    for _ = 1, math.min(math.random(2, 4), math.max(0, room)) do
        local npc, st
        -- (only someone new to the city: the people who fill the places of the dead and the departed
        -- wait for the train; nobody new, nobody steps off. Never a nameless extra.)
        local want = { newcomer = true }
        if LC.SpawnCitizen and (not LC.PersonAvailable or LC.PersonAvailable("citizen", want)) then npc, st = LC.SpawnCitizen(OnPlatform(p), want) end
        if IsValid(npc) and st then
            arrivals[#arrivals + 1] = npc
            local home = Home(st, p.pos)
            if home and LC.NPCWorkDispatch then
                -- through Civil Intake first, in line with everyone else, if the city has it (sv_livingcity_intake.lua)
                local steps = LC.IntakeSteps and LC.IntakeSteps(npc) or {}
                steps[#steps + 1] = { pos = home, secs = 2, doing = "just off the train, carrying a suitcase",
                    done = function(n, s) if LC.NPCDropCarry then LC.NPCDropCarry(n, s) end end }
                LC.NPCWorkDispatch(npc, st, "arrival", "just off the train", {
                    onStart = function(n, s) if LC.NPCCarry then LC.NPCCarry(n, s, SUITCASE) end end,
                    steps = steps,
                })
            end
        end
    end
    timer.Create("LivingCityTrainLeaves", BOARDING, 1, function()
        if T.platform and sound and sound.Play then sound.Play("ambient/alarms/train_horn2.wav", T.platform.pos, 105, 92) end
        T.boardingUntil = 0
        hook.Run("LivingCityTrainDeparted", T.platform)
    end)
    hook.Run("LivingCityTrainArrived", p, arrivals, from)
    return true, arrivals
end

-- Somebody leaving the city: to the platform, if a train is boarding.
function LC.TrainBoardingPos()
    if CurTime() > (T.boardingUntil or 0) or not T.platform then return nil end
    return OnPlatform(T.platform)
end

timer.Create("LivingCityTrains", 5, 0, function()
    if not cvOn:GetBool() or not LC.Running then return end
    local now = CurTime()
    if (T.nextAt or 0) == 0 then T.nextAt = now + math.Rand(120, 300) return end -- the first one a little after the city wakes
    if now < T.nextAt then return end
    if LC.Event == "curfew" or LC.Event == "lockdown" then T.nextAt = now + 120 return end
    if #LC.TrainPlatforms() == 0 then T.nextAt = now + 300 return end
    if LC.TrainReal() then LC.TrainCall() return end -- (the arrivals wait for the map's train: below)
    local ok, err = LC.Try(LC.TrainArrive)
    if not ok and LC.Error then LC.Error("trains", err) end
end)

------------------------------------------------------------------------
-- The map's own train to the station (lc_train_real)
------------------------------------------------------------------------

local function Named(n) return ents.FindByName and ents.FindByName(n) or {} end

-- Is the real train in charge? The setting on, and the map has both relays.
function LC.TrainReal()
    return cvReal:GetBool() and #Named("lc_train_station_run") > 0 and #Named("lc_train_station_arrived") > 0
end

-- A train is due: call the map's. It is asked again in three minutes if it never shows.
function LC.TrainCall()
    local now = CurTime()
    if LC.TracksWrecked and LC.TracksWrecked("lc_train_station") then T.nextAt = now + 120 return false end
    for _, e in ipairs(Named("lc_train_station_run")) do if IsValid(e) and e.Fire then e:Fire("Trigger", "", 0) end end
    T.calledAt, T.nextAt = now, now + 180
    hook.Run("LivingCityTrainCalled")
    return true
end

-- The map says its train stands at the station.
function LC.TrainShowedUp()
    if not LC.TrainReal() or not LC.Running then return false end
    local now = CurTime()
    local wait = cvMinutes:GetFloat() * 60
    if not T.calledAt and now - (T.arrivedAt or -1e9) < wait * 0.5 then return false end -- (one the map sent by itself, too soon after the last)
    T.calledAt, T.arrivedAt = nil, now
    return LC.TrainArrive()
end

hook.Add("AcceptInput", "LivingCityTrains", function(ent, input)
    if not IsValid(ent) or string.lower(input or "") ~= "trigger" then return end
    if (ent.GetName and ent:GetName() or "") ~= "lc_train_station_arrived" then return end
    local ok, err = LC.Try(LC.TrainShowedUp)
    if not ok and LC.Error then LC.Error("trains", err) end
end)

concommand.Add("lc_train", function(ply)
    if IsValid(ply) and not ply:IsAdmin() then return end
    local ok = LC.TrainArrive(true)
    local msg = ok and "[Miscount] A train pulls in." or "[Miscount] No platform: place a \"Point: train platform\" with the editor."
    if IsValid(ply) then ply:ChatPrint(msg) else print(msg) end
end)
