--[[
    Living City: company on a patrol (the owner, 11 November: "can we also make it so that the night shift
    or patrol jobs have idk, a shady character or someone following you or hiding or something? someone
    to interact with to make it not so boring I want to close my game?")

    A Civil Protection player on the night shift or a patrol job (LC.PatrolCompanyJobs) now and then
    meets somebody. Not at once, never two at a time, and at most one every few minutes:

      a loiterer   somebody standing about out of sight near where the patrol is going. The unit is told
                   and it's marked on their screen. Seen from close by, half of them bolt and half stay
                   put with an excuse.
      a tail       somebody who walks after the unit at a distance. After a while the unit has "the
                   feeling of being followed". Looked at, or walked up to, they run.

    One who runs can be run down (get within arm's reach: they give up) or lost (they get far enough
    away, or it takes too long). Whoever is caught, or stayed, is a citizen like any other to the unit:
    stop them, search them (they are far likelier than most to carry something) or ask for their papers
    (likelier to be out of order). Running one down is 3 experience; seeing to them (a search or their
    papers) 2 more. Then they go on their way.

      lc_patrol_company 0/1 (1)
]]

if CLIENT then return end

LC = LC or {}

local FLAGS = bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED)
local cvOn = CreateConVar("lc_patrol_company", "1", FLAGS, "A unit on the night shift or a patrol job now and then meets a loiterer, or is followed (0: never)")

LC.PatrolCompanyJobs = { cp_nightshift = true, cp_patrol = true }
LC.PatrolCompanyChance = 0.5   -- each time it's considered
LC.PatrolCompanyFirst = 40     -- seconds into the job before the first
LC.PatrolCompanyGap = 150      -- seconds between two
LC.PatrolCompanyMost = 300     -- seconds one lasts at most
LC.PatrolCompany = LC.PatrolCompany or {} -- [ply] = the encounter
local MET = LC.PatrolCompany

local SEE, CATCH, LOST, RUN_SECS = 350, 110, 2200, 45
local TAIL_NEAR, TAIL_FAR, TAIL_TOLD = 280, 480, 25
local UP = Vector(0, 0, 40)
local EXCUSES = {
    "Just getting some air, officer.",
    "I'm waiting for someone. He's late.",
    "I couldn't sleep. Is that against the rules now?",
    "I dropped something. I was looking for it.",
    "My shift ran over. I'm on my way home.",
}

local function Notice(ply, kind, title, text, secs)
    if LC.Notice then LC.Notice(ply, kind, title, text, secs or 8) else ply:ChatPrint("[CP net] " .. title .. ": " .. text) end
end

local function OnPatrol(ply)
    if not IsValid(ply) or not ply:Alive() or ply:GetNW2String("lcf_faction", "") ~= "cp" then return nil end
    local q = LC.QuestOf and LC.QuestOf[ply]
    if q and not q.done and q.tmpl and LC.PatrolCompanyJobs[q.tmpl.id] then return q end
    return nil
end
LC.OnPatrolJob = OnPatrol

-- Somewhere out of the unit's sight, between near and far of base.
local function Spot(ply, base, near, far)
    if not LC.RandomWanderPos then return nil end
    local at = ply:GetPos()
    for _ = 1, 30 do
        local p = LC.RandomWanderPos("citizen", base) or LC.RandomWanderPos("citizen")
        if p then
            local d = p:DistToSqr(at)
            if d > near * near and d < far * far and math.abs(p.z - at.z) < 200 and not (LC.IsSeen and LC.IsSeen(p + UP))
                and not (LC.InCombineZone and LC.InCombineZone(p)) and not (LC.InRebelZone and LC.InRebelZone(p)) then return p end
        end
    end
    return nil
end

local function Sees(ply, npc)
    if not LC.LineOfSight then return true end
    return LC.LineOfSight(ply:EyePos(), npc:WorldSpaceCenter(), ply, npc) == true
end

local function Release(enc, now)
    local st = enc.st
    if st then
        st.unmanaged, st.suspectFor = nil, nil
        st.eventUntil, st.leaveAt = 0, (now or CurTime()) + 60
    end
end

function LC.PatrolCompanyEnd(ply, why, now)
    local enc = MET[ply]
    if not enc then return end
    MET[ply] = nil
    Release(enc, now)
    if IsValid(ply) then ply.lcCompanyNext = (now or CurTime()) + LC.PatrolCompanyGap end
    hook.Run("LivingCityPatrolCompanyEnded", ply, enc.kind, why)
end

function LC.PatrolCompanyStart(ply, kind, now)
    now = now or CurTime()
    if MET[ply] or not IsValid(ply) then return nil end
    kind = kind or (math.random() < 0.5 and "loiter" or "tail")
    local base = (kind == "loiter" and LC.QuestObjectivePos and LC.QuestObjectivePos(ply)) or ply:GetPos()
    local pos = (kind == "loiter" and Spot(ply, base, 500, 1600)) or Spot(ply, ply:GetPos(), 450, 900)
    if not pos or not (LC.Spawners and LC.Spawners.citizen) then return nil end
    local npc, st = LC.Spawners.citizen(pos)
    if not IsValid(npc) or not st then return nil end
    st.unmanaged, st.suspect, st.suspectFor = true, true, ply
    if LC.SetState then LC.SetState(npc, st, "event") end
    st.eventUntil = now + LC.PatrolCompanyMost + 60
    if npc.SetSchedule then npc:SetSchedule(SCHED_IDLE_STAND) end
    local enc = { ply = ply, npc = npc, st = st, kind = kind, at = now, phase = kind == "tail" and "follow" or "wait" }
    MET[ply] = enc
    if kind == "loiter" then
        local where = LC.DescribePlace and LC.DescribePlace(pos) or ""
        Notice(ply, "warn", "Somebody out there", "Somebody is standing about in the shadows " .. where .. ". It's marked: go and see who. Stop them, search them, or ask for their papers (F2).", 10)
        if LC.SendCompressed then LC.SendCompressed("lc_cpmark", { name = "LOITERER", x = pos.x, y = pos.y, z = pos.z, secs = 90 }, { ply }) end
    end
    hook.Run("LivingCityPatrolCompany", ply, kind, npc)
    return enc
end

local function Bolt(enc, now, told)
    enc.phase, enc.runAt, enc.nextRun = "run", now, 0
    if told then Notice(enc.ply, "warn", told[1], told[2], 7) end
    if enc.npc.EmitSound then enc.npc:EmitSound("vo/npc/male01/runforyourlife01.wav", 75) end
end

local function Stopped(enc, now, caught)
    enc.phase, enc.stopAt = "stopped", now
    enc.untilT0, enc.papers0 = enc.st.untilT, enc.st.papersAt
    if enc.npc.SetSchedule then enc.npc:SetSchedule(SCHED_IDLE_STAND) end
    if LC.Face then LC.Face(enc.npc, enc.ply:GetPos()) end
    if caught then
        if LC.AddXP then LC.AddXP(enc.ply, 3, "ran down a suspect") end
        enc.ply:ChatPrint("[CP net] They give up, out of breath. Search them (R with the baton out) or ask for their papers (F2).")
    end
end

-- Has the unit seen to them: searched them, or looked at their papers?
local function SeenTo(enc)
    local st = enc.st
    return st.contraband ~= nil or st.untilT ~= enc.untilT0 or st.papersAt ~= enc.papers0
end

function LC.PatrolCompanyStep(enc, now)
    local ply, npc, st = enc.ply, enc.npc, enc.st
    if not IsValid(ply) or not IsValid(npc) or npc:Health() <= 0 or not ply:Alive() then return LC.PatrolCompanyEnd(ply, "gone", now) end
    if now - enc.at > LC.PatrolCompanyMost or (enc.phase ~= "stopped" and not OnPatrol(ply)) then return LC.PatrolCompanyEnd(ply, "over", now) end
    local pp, np = ply:GetPos(), npc:GetPos()
    local d = pp:Distance(np)
    if enc.phase == "wait" then
        if d < SEE and Sees(ply, npc) then
            if math.random() < 0.5 then
                Bolt(enc, now, { "They're running", "They saw you coming and bolted. Run them down, or let them go." })
            else
                local name = LC.NPCStr and LC.NPCStr(npc, "lc_pname", "") or ""
                ply:ChatPrint("[" .. (name ~= "" and name or "Citizen") .. "] '" .. EXCUSES[math.random(#EXCUSES)] .. "'")
                Stopped(enc, now, false)
            end
        end
    elseif enc.phase == "follow" then
        if d > TAIL_FAR and now >= (enc.nextMove or 0) then
            enc.nextMove = now + 3
            if LC.GoTo then LC.GoTo(npc, st, pp, d > 900, nil) end
        elseif d < TAIL_NEAR and npc.SetSchedule and not enc.stood then
            enc.stood = true
            npc:SetSchedule(SCHED_IDLE_STAND)
        end
        if d > TAIL_NEAR then enc.stood = nil end
        if not enc.told and now - enc.at > TAIL_TOLD then
            enc.told = true
            Notice(ply, "warn", "Being followed", "You have the feeling of being followed. Look behind you.", 7)
        end
        -- looked at for a moment, or walked right up to
        local facing = ply:GetAimVector():Dot((np - pp):GetNormalized()) > 0.9
        local looked = d < 700 and facing and Sees(ply, npc)
        enc.looks = looked and (enc.looks or 0) + 1 or 0
        if d < 200 or enc.looks >= 2 then
            Bolt(enc, now, { "You were followed", "Somebody has been walking after you. They've seen you look, and they run. Run them down, or let them go." })
        end
    elseif enc.phase == "run" then
        if d < CATCH then return Stopped(enc, now, true) end
        if d > LOST or now - enc.runAt > RUN_SECS then
            ply:ChatPrint("[CP net] You lost them.")
            return LC.PatrolCompanyEnd(ply, "lost", now)
        end
        if now >= (enc.nextRun or 0) then
            enc.nextRun = now + 2.5
            local away = np - pp away.z = 0
            if away:LengthSqr() < 1 then away = Vector(1, 0, 0) end
            local to = np + away:GetNormalized() * 900
            if LC.GoTo then LC.GoTo(npc, st, LC.GroundAt and LC.GroundAt(to) or to, true, nil) end
        end
    elseif enc.phase == "stopped" then
        if SeenTo(enc) then
            if LC.AddXP then LC.AddXP(ply, 2, "saw to a suspect") end
            return LC.PatrolCompanyEnd(ply, "seen to", now)
        end
        if now - enc.stopAt > 75 then return LC.PatrolCompanyEnd(ply, "left", now) end
    end
end

function LC.PatrolCompanyTick(now)
    now = now or CurTime()
    for ply, enc in pairs(MET) do
        local ok, err = pcall(LC.PatrolCompanyStep, enc, now)
        if not ok then
            MET[ply] = nil
            if LC.Error then LC.Error("patrol company", err) end
        end
    end
    if not cvOn:GetBool() or not LC.Running then return end
    for _, ply in ipairs(player.GetAll()) do
        local q = not MET[ply] and OnPatrol(ply)
        if q then
            if ply.lcCompanyJob ~= q then ply.lcCompanyJob, ply.lcCompanyNext = q, now + LC.PatrolCompanyFirst end
            if now >= (ply.lcCompanyNext or 0) then
                ply.lcCompanyNext = now + 30 -- (looked at again in half a minute if nothing comes of it)
                if math.random() < LC.PatrolCompanyChance then LC.PatrolCompanyStart(ply, nil, now) end
            end
        end
    end
end

timer.Create("LivingCityPatrolCompany", 1, 0, function()
    local ok, err = pcall(LC.PatrolCompanyTick, CurTime())
    if not ok and LC.Error then LC.Error("patrol company", err) end
end)

hook.Add("PlayerDisconnected", "LivingCityPatrolCompany", function(ply) LC.PatrolCompanyEnd(ply, "gone") end)
hook.Add("LivingCityStopped", "LivingCityPatrolCompany", function()
    for ply in pairs(MET) do LC.PatrolCompanyEnd(ply, "over") end
end)
