--[[
    Living City: Labor Assignment (Union work, given out in person)

    The owner: "all new players that register at the intake terminal should be
    assigned a job; whatever job has the most openings or randomly. They should
    be tied to this job for at least 30 minutes or whenever they complete 4
    shifts. I feel like they should have to walk to a terminal to register a
    new job ... It has to be used after intake registration before housing can
    be assigned."

    A terminal placed with the editor ("Fixture: Labor Assignment"), the same
    kind of desk as Civil Intake and Housing Allocation (lc_intake.lua, the
    screens and the processing are sv_livingcity_intake.lua's). With one in the
    city:

      - A registered citizen with no Union work goes to it after Civil Intake.
        Housing Allocation turns them away until they have work, and says where
        to go. The terminal gives them the post with the most openings (the
        fewest people on it; a random one of those that tie). Infestation
        Cleanup, Intake Processor and the Block Warden are never handed out.
      - That assignment holds for lc_labor_min_minutes (30) minutes in the city
        on it, or lc_labor_min_shifts (4) finished shifts, whichever comes
        first. Kept over a rejoin (saved data).
      - Then they can come back and pick another job from the list. Infestation
        Cleanup needs Civil Standing lc_labor_cleanup_standing (25), Intake
        Processor (the station's papers check) lc_labor_porter_standing (50);
        a job they can't have yet is listed with the reason. A job picked here
        holds for the same stint. The Union's own wait between job changes
        (lc_job_cooldown, 900 seconds) still counts.
      - Jobs are changed nowhere else: the board (F4) says "Go to a Labor
        Assignment terminal to change your assignment" and marks the nearest.
        Staff (lc_setjob) still can. Losing the job (a Civil Protection unit,
        an anticitizen) works as before, and ends the stint.

    No terminal on the map: everything is as before (the Union assigns work at
    registration, the board changes it). A superadmin on a map with Civil
    Intake but no Labor Assignment is told so, once.

      lc_labor_min_minutes, lc_labor_min_shifts, lc_labor_cleanup_standing,
      lc_labor_porter_standing
]]

if CLIENT then return end

LC = LC or {}
if not LCJ then return end

local FLAGS = bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED)
local cvMinutes = CreateConVar("lc_labor_min_minutes", "30", FLAGS, "Minutes in the city a citizen works an assignment from Labor Assignment before they can ask for another (or lc_labor_min_shifts shifts, whichever comes first; 0 with no lock at all)")
local cvShifts  = CreateConVar("lc_labor_min_shifts", "4", FLAGS, "Union shifts that end an assignment's stint early (or lc_labor_min_minutes minutes, whichever comes first)")
local cvCleanup = CreateConVar("lc_labor_cleanup_standing", "25", FLAGS, "Civil Standing Labor Assignment asks before it offers Infestation Cleanup")
local cvPorter  = CreateConVar("lc_labor_porter_standing", "50", FLAGS, "Civil Standing Labor Assignment asks before it offers Intake Processor (checking travelers' papers at the station)")

-- Jobs the terminal only offers to those in good enough standing, and never hands out as a first assignment.
local GATED = { cleanup = cvCleanup, porter = cvPorter }

-- This city has a Labor Assignment terminal (in its layout).
function LC.LaborDesk() return LC.IntakeHasDesk and LC.IntakeHasDesk("labor") or false end

local function Standing(ply) return LC.Standing and LC.Standing(ply) or 0 end
local function Fresh(ply) return ply:GetPData("lc_intake", "0") == "1" end

------------------------------------------------------------------------
-- The stint: how long on the job the terminal gave them, and how many shifts
------------------------------------------------------------------------

local function Stint(ply)
    local s = ply.lcLabor
    if not s then
        s = { job = ply:GetPData("lc_labor_job", "") or "", secs = tonumber(ply:GetPData("lc_labor_secs", 0)) or 0,
            shifts = tonumber(ply:GetPData("lc_labor_shifts", 0)) or 0 }
        ply.lcLabor = s
    end
    return s
end
local function SaveStint(ply)
    local s = ply.lcLabor
    if not s then return end
    ply:SetPData("lc_labor_job", s.job)
    ply:SetPData("lc_labor_secs", math.floor(s.secs))
    ply:SetPData("lc_labor_shifts", s.shifts)
end
LC.LaborStint = Stint

-- Has done a stint already (or was in the city before Civil Intake): picks their own job.
local function Veteran(ply)
    return ply:GetPData("lc_labor_done", "0") == "1" or not Fresh(ply)
end
LC.LaborVeteran = Veteran

-- A brand-new person (sv_livingcity_intake.lua, LC.IntakeNew): no assignment yet, ever.
function LC.LaborNew(ply)
    if not IsValid(ply) then return end
    for _, k in ipairs({ "lc_labor_job", "lc_labor_secs", "lc_labor_shifts", "lc_labor_done" }) do ply:RemovePData(k) end
    ply.lcLabor = nil
end

-- Still tied to the job the terminal gave them? locked, seconds left, shifts left.
function LC.LaborLocked(ply)
    if not IsValid(ply) then return false end
    local job = LC.Job and LC.Job(ply)
    if not job then return false end
    local s = Stint(ply)
    if s.job ~= job.id then return false end
    local needSecs, needShifts = math.max(0, cvMinutes:GetFloat() * 60), math.max(0, cvShifts:GetInt())
    if s.secs >= needSecs or s.shifts >= needShifts then return false end
    return true, needSecs - s.secs, needShifts - s.shifts
end

local function Plural(n, one, many) return n == 1 and ("1 " .. one) or (n .. " " .. many) end

-- One line about it, for the board and the terminal.
function LC.LaborLockLine(ply)
    local locked, secs, shifts = LC.LaborLocked(ply)
    if not locked then return LC.LABOR_GO end
    return string.format("Tied to this job for %s more or %s more, whichever comes first; then a Labor Assignment terminal can change it.",
        Plural(math.max(1, math.ceil(secs / 60)), "minute", "minutes"), Plural(shifts, "shift", "shifts"))
end

-- The stint's done: they're free to ask for another job.
local function Complete(ply, s)
    local job = LC.Job(ply)
    s.job, s.secs, s.shifts = "", 0, 0
    SaveStint(ply)
    ply:SetPData("lc_labor_done", "1")
    if LC.Notice then
        LC.Notice(ply, "event", "Labor Assignment", "You've done your stint" .. (job and (" as " .. job.name) or "")
            .. ". If you want a different job, a Labor Assignment terminal can change it now. Or stay where you are.", 12)
    end
    hook.Run("LivingCityLaborStintDone", ply)
end

-- Time on the job, while they're in the city.
timer.Create("LivingCityLabor", 5, 0, function()
    local now = CurTime()
    for _, ply in ipairs(player.GetAll()) do
        local job = LC.Job and LC.Job(ply)
        local s = job and Stint(ply)
        if s and s.job == job.id then
            local last = ply.lcLaborTick or now
            ply.lcLaborTick = now
            s.secs = s.secs + math.Clamp(now - last, 0, 30)
            if not LC.LaborLocked(ply) then
                Complete(ply, s)
            elseif now >= (ply.lcLaborSave or 0) then
                ply.lcLaborSave = now + 60
                SaveStint(ply)
            end
        else
            ply.lcLaborTick = nil
        end
    end
end)

-- A finished shift counts towards it.
hook.Add("LivingCityQuestComplete", "LivingCityLabor", function(ply, q)
    if not q or q.chain ~= "shift" or not IsValid(ply) or not ply:IsPlayer() then return end
    local job = LC.Job and LC.Job(ply)
    local s = job and Stint(ply)
    if not s or s.job ~= job.id then return end
    s.shifts = s.shifts + 1
    SaveStint(ply)
    if not LC.LaborLocked(ply) then Complete(ply, s) end
end)

-- A new job from the terminal starts a stint; any other change (staff, losing it) ends one.
hook.Add("LivingCityJobChanged", "LivingCityLabor", function(ply, id)
    if not IsValid(ply) then return end
    local s = Stint(ply)
    s.job = (ply.lcLaborAssigning and id ~= "") and id or ""
    s.secs, s.shifts = 0, 0
    ply.lcLaborTick = nil
    SaveStint(ply)
end)

hook.Add("PlayerDisconnected", "LivingCityLabor", function(ply) SaveStint(ply) end)
hook.Add("LivingCityCharacterSwitched", "LivingCityLabor", function(ply) ply.lcLabor, ply.lcLaborTick = nil, nil end)

------------------------------------------------------------------------
-- Who has to come here, and what they're offered
------------------------------------------------------------------------

-- A registered citizen with no Union work, in a city with the terminal (Housing Allocation waits on it).
function LC.AwaitingLabor(ply)
    if not IsValid(ply) or not ply:IsPlayer() or not LC.LaborDesk() then return false end
    local cv = GetConVar("lc_assign_work")
    if cv and not cv:GetBool() then return false end -- (nobody is made to work)
    if ply:GetNW2String("lcf_faction", "") ~= "citizen" then return false end
    if LC.IntakePending and LC.IntakePending(ply) then return false end
    if LC.Job and LC.Job(ply) then return false end
    return LC.CanWork and LC.CanWork(ply) or false
end

local function Holders()
    local counts = {}
    for _, p in ipairs(player.GetAll()) do
        local j = p:GetNW2String("lcj_job", "")
        if j ~= "" then counts[j] = (counts[j] or 0) + 1 end
    end
    return counts
end

-- A post the Union hands out as a first assignment.
local function Assignable(o)
    return not LCJ.Closed(o) and not o.minStanding and not o.playersOnly and not GATED[o.id]
end

-- The post with the most openings (the fewest people on it), a random one of those that tie.
function LC.LaborPickFirst()
    local counts, best, bn = Holders(), {}, nil
    for _, o in ipairs(LCJ.Occupations or {}) do
        if Assignable(o) then
            local n = counts[o.id] or 0
            if not bn or n < bn then best, bn = { o }, n
            elseif n == bn then best[#best + 1] = o end
        end
    end
    if #best == 0 then return nil end
    return best[math.random(#best)]
end

-- Why they can't have a job here (nil: they can). A post only the most loyal can have isn't listed at all
-- below that (the board does the same: the Block Warden).
local function Barred(ply, o)
    if LCJ.Closed(o) then return "closed right now", true end
    if o.minStanding and Standing(ply) < o.minStanding then return "for the most loyal only", true end
    local cv = GATED[o.id]
    if cv and Standing(ply) < cv:GetInt() then
        return string.format("needs Civil Standing %d (yours is %d)", cv:GetInt(), Standing(ply))
    end
    return nil
end

-- What the terminal's screen shows (sv_livingcity_intake.lua, LC.SendDesk).
function LC.LaborDeskInfo(ply)
    local job = LC.Job and LC.Job(ply)
    local locked, secs, shifts = LC.LaborLocked(ply)
    local s = Stint(ply)
    local t = {
        job = job and job.id or "", jobName = job and job.name or nil, place = job and job.place or nil,
        locked = locked and true or false, minsLeft = locked and math.max(1, math.ceil(secs / 60)) or 0, shiftsLeft = locked and shifts or 0,
        minMinutes = cvMinutes:GetInt(), minShifts = cvShifts:GetInt(), mins = math.floor(s.secs / 60), shifts = s.shifts,
        veteran = Veteran(ply), registered = not (LC.IntakePending and LC.IntakePending(ply)),
        canWork = LC.CanWork and LC.CanWork(ply) or false, papers = LC.HasItem and LC.HasItem(ply, "id_papers") or false,
        housingNext = (LC.AwaitingHousing and LC.AwaitingHousing(ply) and LC.IntakeHasDesk and LC.IntakeHasDesk("housing")) and true or false,
        standing = Standing(ply), wait = math.max(0, math.ceil((ply.lcjNext or 0) - CurTime())),
        jobs = {},
    }
    t.first = not job and not t.veteran
    if not t.first and not t.locked then
        for _, o in ipairs(LCJ.Occupations or {}) do
            local why, hide = Barred(ply, o)
            if not hide then
                t.jobs[#t.jobs + 1] = { num = o.num, id = o.id, name = o.name, place = o.place, desc = o.desc, path = o.path or "",
                    locked = why, current = job ~= nil and job.id == o.id or nil }
            end
        end
    end
    return t
end

-- A button on the terminal's screen, checked before it starts working on them.
-- ok, why, and the job asked for (nil: the Union's choice).
function LC.LaborCanAct(ply, action, arg)
    if not IsValid(ply) then return false end
    if LC.IntakePending and LC.IntakePending(ply) then return false, "You're not registered. Register at Civil Intake first." end
    if not (LC.CanWork and LC.CanWork(ply)) then return false, "The Union only gives work to citizens." end
    if LC.HasItem and not LC.HasItem(ply, "id_papers") and not ply.lcIdentity then
        return false, "Present your identity papers. You have none on you: Civil Intake can give you new ones."
    end
    local job = LC.Job and LC.Job(ply)
    if action == "assign" then
        if job then return false, "You already have work: " .. job.name .. "." end
        return true
    end
    if action ~= "choose" then return false end
    local want = LCJ.ByNum[tonumber(arg) or -1]
    if not want then return false, "That job doesn't exist." end
    if not job and not Veteran(ply) then return false, "Your first assignment comes from the Union: ask for an assignment." end
    if job and job.id == want.id then return false, "That's already your job." end
    local locked = LC.LaborLocked(ply)
    if locked then return false, LC.LaborLockLine(ply) end
    local why = Barred(ply, want)
    if why then return false, want.name .. ": " .. why .. "." end
    if (ply.lcjNext or 0) > CurTime() then
        local left = math.ceil(ply.lcjNext - CurTime())
        return false, "You changed jobs recently. The Union lets you change again in " .. (left >= 120 and (math.ceil(left / 60) .. " minutes") or (left .. " seconds")) .. "."
    end
    return true, nil, want.id
end

-- The terminal has worked on them (sv_livingcity_intake.lua, Finish).
function LC.LaborFinish(ply, data)
    if not IsValid(ply) then return false end
    local title = "[Labor Assignment] "
    local pick, ok, why
    if data and data.job then
        local o = LCJ.ById[data.job]
        ok, why = LC.LaborCanAct(ply, "choose", o and o.num)
        if not ok then if why then ply:ChatPrint(title .. why) end return false end
        pick = o
        ply.lcLaborAssigning = true
        ok, why = LC.SetJob(ply, pick.id, false, true)
        ply.lcLaborAssigning = nil
    else
        ok, why = LC.LaborCanAct(ply, "assign")
        if not ok then if why then ply:ChatPrint(title .. why) end return false end
        pick = LC.LaborPickFirst()
        if not pick then ply:ChatPrint(title .. "No Union posts are open right now. Try again later.") return false end
        ply.lcLaborAssigning = true
        ok, why = LC.SetJob(ply, pick.id, true) -- (the Union's own assignment)
        ply.lcLaborAssigning = nil
    end
    if not ok then if why then ply:ChatPrint(title .. why) end return false end
    local mins, shifts = cvMinutes:GetInt(), cvShifts:GetInt()
    local tied = (mins > 0 and shifts > 0) and string.format(" You're tied to it for %s or %s, whichever comes first; then come back here if you want a change.",
        Plural(mins, "minute", "minutes"), Plural(shifts, "shift", "shifts")) or ""
    ply:ChatPrint(title .. "Assignment approved: " .. pick.name .. ". Go to the " .. string.lower(pick.place) .. " to work; your shifts are on your board (F4)." .. tied)
    if LC.Notice then LC.Notice(ply, "event", "Work assignment", "Labor Assignment has given you a job: " .. pick.name .. "." .. tied, 12) end
    if LC.AwaitingHousing and LC.AwaitingHousing(ply) and LC.IntakeHasDesk and LC.IntakeHasDesk("housing") then
        ply:ChatPrint(title .. "Next, Housing Allocation gives you a room. It's marked on your screen.")
        if LC.WaypointTo then LC.WaypointTo(ply, "housing") end
    end
    if LC.IntakeFlags then LC.IntakeFlags(ply) end
    hook.Run("LivingCityLaborAssigned", ply, pick.id)
    return true
end

------------------------------------------------------------------------
-- A map without the terminal: superadmins are told, once
------------------------------------------------------------------------

local function TellStaff(ply)
    if not IsValid(ply) or ply.lcLaborTold or not ply:IsSuperAdmin() then return end
    if LC.LaborDesk() or not (LC.IntakeHasDesk and LC.IntakeHasDesk("register")) then return end
    if LC.IntakeOn and not LC.IntakeOn() then return end
    ply.lcLaborTold = true
    if LC.Notice then
        LC.Notice(ply, "info", "Labor Assignment", "This map has no Labor Assignment terminal, so new citizens are given Union work automatically and change jobs on their board (F4)."
            .. " To make them walk to one, place \"Fixture: Labor Assignment\" with the Living City Editor.", 14)
    end
end
LC.LaborTellStaff = TellStaff
hook.Add("PlayerInitialSpawn", "LivingCityLabor", function(ply)
    ply.lcLabor = nil
    timer.Simple(25, function() TellStaff(ply) end)
end)
