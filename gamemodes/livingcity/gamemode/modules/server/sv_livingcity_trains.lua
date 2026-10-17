--[[
    Living City: the trains

    With a train platform on the map (an editor point, "Point: train platform";
    or failing that, the Intake Processor's workplace), a train comes in every
    lc_train_minutes (12, give or take). A horn at the platform, a notice
    for everyone, and a few new arrivals step off, suitcase in hand, and walk
    to their housing blocks. For a minute and a half after, anyone leaving the
    city (their day is done) walks to the platform with a suitcase and
    boards, instead of going out through a doorway. Then the train pulls out.

    Intake Processors are told when a train is in (their "New arrivals" shift
    is the time to work the platform). lc_trains 0 turns them off;
    lc_train (admin) brings one in now.
]]

if CLIENT then return end

LC = LC or {}

local FLAGS = bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED)
local cvOn      = CreateConVar("lc_trains", "1", FLAGS, "Trains come into the station now and then, with new arrivals; people leaving the city board them")
local cvMinutes = CreateConVar("lc_train_minutes", "12", FLAGS, "Minutes between trains (give or take a quarter)")
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
    local room = budget and (budget:GetInt() - table.Count(LC.NPCs or {})) or 4
    for _ = 1, math.min(math.random(2, 4), math.max(0, room)) do
        local npc, st
        if LC.SpawnCitizen then npc, st = LC.SpawnCitizen(OnPlatform(p)) end
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
    local ok, err = pcall(LC.TrainArrive)
    if not ok and LC.Error then LC.Error("trains", err) end
end)

concommand.Add("lc_train", function(ply)
    if IsValid(ply) and not ply:IsAdmin() then return end
    local ok = LC.TrainArrive(true)
    local msg = ok and "[Living City] A train pulls in." or "[Living City] No platform: place a \"Point: train platform\" with the editor."
    if IsValid(ply) then ply:ChatPrint(msg) else print(msg) end
end)
