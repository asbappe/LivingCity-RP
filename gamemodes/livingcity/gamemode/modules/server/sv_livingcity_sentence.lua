--[[
    Living City: sentences that fit the crimes, the work detail, probation
    (the owner, 10 November).

    Sentences. Every crime you're booked for (LC.ReportCrime) goes on your
    record until your next sentence, each kind once. Arrested, your sentence
    is what's on it, added up (LC.CrimeMinutes):
        petty (curfew, contraband, running, theft...)          3 minutes
        assaulting a citizen, resisting, escaping, obstructing  6
        weapons, sabotage, treason, firebombing                 8
        assaulting Civil Protection or the Administrator       10
        murder                                                  15
        murder of a Civil Protection officer or a soldier      20
    at most lc_sentence_max (30) minutes. Nothing on the record: the old
    lc_prison_time. Then the record is cleared. Only an arrest counts:
    staff jailing someone (lc_jail), a story's sentence, a conduct sentence
    and a sentence picked up again after leaving stay exactly as given.

    The work detail. In a cell, F1 > "Ask for a work detail": a prison
    guard (a Nova Prospekt guard if there is one, else the nearest unit)
    comes to your cell and walks you out to the work spot (editor: "Point:
    prison work spot"; failing that, the prison zone, or the corridor by the
    cells), where there's trash to pick up: E on each piece takes
    lc_prison_work_off (20) seconds off your sentence, up to half of it in
    all. Then he walks you back. Stray far from him and it's an escape.

    Probation. Released after an arrest, you're on probation for
    lc_probation_minutes (15): check in once with a Civil Protection unit
    (F1 > "Check in for probation", close to one), any new crime counts
    double on your record, and going into rebel territory or helping the
    Resistance (any sympathy earned) is a probation violation. Not checked
    in by the end: Failure to report. (Citizens only: the Resistance are
    the enemy, not parolees.)

      lc_sentences 0/1, lc_sentence_max (30)
      lc_prison_work 0/1, lc_prison_work_off (20)
      lc_probation 0/1, lc_probation_minutes (15)
]]

if CLIENT then return end

LC = LC or {}

local FLAGS = bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED)
local cvOn       = CreateConVar("lc_sentences", "1", FLAGS, "A sentence adds up the crimes on someone's record since their last one (petty 3 minutes up to 20 for murdering a unit)")
local cvMax      = CreateConVar("lc_sentence_max", "30", FLAGS, "The longest sentence, in minutes, however much is on someone's record")
local cvWork     = CreateConVar("lc_prison_work", "1", FLAGS, "Prisoners can ask for a work detail: a guard walks them out to pick up trash, for time off")
local cvWorkOff  = CreateConVar("lc_prison_work_off", "20", FLAGS, "Seconds off a sentence for each piece of trash picked up on a work detail")
local cvProb     = CreateConVar("lc_probation", "1", FLAGS, "Citizens released after an arrest are on probation: check in with a unit, offences count double, no Resistance")
local cvProbMins = CreateConVar("lc_probation_minutes", "15", FLAGS, "Minutes of probation after a sentence")

------------------------------------------------------------------------
-- What a crime is worth
------------------------------------------------------------------------

local function Has(r, words)
    for _, w in ipairs(words) do if string.find(r, w, 1, true) then return true end end
    return false
end
local UNIT_WORDS = { "civil protection", "overwatch", "officer", "soldier", "unit", "elite" }

-- Minutes on a sentence for one crime, and the kind it is.
function LC.CrimeMinutes(reason)
    local r = string.lower(tostring(reason or ""))
    if string.find(r, "murder", 1, true) and not string.find(r, "attempted", 1, true) then
        if Has(r, UNIT_WORDS) then return 20, "murder of a unit" end
        return 15, "murder"
    end
    if string.find(r, "attempted murder", 1, true) then return 10, "attempted murder" end
    if Has(r, { "assault", "attack" }) and Has(r, { "civil protection", "administrator", "officer", "overwatch", "unit" }) then
        return 10, "assaulting Civil Protection"
    end
    if Has(r, { "firearm", "weapon", "armed", "brandish", "firebomb", "bomb", "sabotage", "treason", "desertion" }) then
        return 8, "serious"
    end
    if Has(r, { "assault", "attack", "resisting", "escap", "abscond", "fleeing", "aiding an escape", "obstructing", "impersonating", "probation violation" }) then
        return 6, "violent or resisting"
    end
    return 3, "petty"
end

------------------------------------------------------------------------
-- The record since the last sentence (kept with the character)
------------------------------------------------------------------------

local function Rap(ply)
    if not ply.lcRap then
        ply.lcRap = ply.GetPData and util.JSONToTable(ply:GetPData("lc_rap", "") or "") or {}
    end
    return ply.lcRap
end
LC.RapSheet = Rap

local function SaveRap(ply)
    if not ply.SetPData then return end -- (a dream's stand-in, not a real person)
    local r = Rap(ply)
    if #r == 0 then ply:RemovePData("lc_rap") else ply:SetPData("lc_rap", util.TableToJSON(r)) end
end

function LC.OnProbation(ply)
    return IsValid(ply) and (ply.lcProbationUntil or 0) > CurTime()
end

hook.Add("LivingCityWanted", "LivingCitySentence", function(ply, reason, seconds)
    if not IsValid(ply) or not ply.IsPlayer or not ply:IsPlayer() or not cvOn:GetBool() then return end
    if reason == nil or reason == "" then return end
    if LC.Prisoners and LC.Prisoners[ply] then return end
    local r = Rap(ply)
    for _, c in ipairs(r) do if c.reason == reason then return end end -- (each kind once)
    local mins = LC.CrimeMinutes(reason)
    local doubled = LC.OnProbation(ply)
    if doubled then mins = mins * 2 end
    r[#r + 1] = { reason = reason, min = mins, doubled = doubled or nil }
    SaveRap(ply)
end)

hook.Add("LivingCityCharacterSwitched", "LivingCitySentence", function(ply)
    if IsValid(ply) then ply.lcRap, ply.lcProbationUntil, ply.lcProbationChecked = nil, nil, nil end
end)

-- The sentence for an arrest (LC.Incarcerate asks). Returns seconds, and the words for it (nil: unchanged).
function LC.SentenceFor(ply, seconds, reason, arrester)
    if not cvOn:GetBool() or not IsValid(ply) then return seconds end
    if ply.lcExactSentence then return seconds end -- (staff: exactly as given)
    if not IsValid(arrester) or (arrester:IsPlayer() and not LC.PlayerIsCP(arrester)) then return seconds end -- (only an arrest)
    local r = Rap(ply)
    if #r == 0 then return seconds end
    local total, parts = 0, {}
    for _, c in ipairs(r) do
        total = total + c.min
        parts[#parts + 1] = string.format("%s (%d%s)", c.reason, c.min, c.doubled and ", doubled on probation" or "")
    end
    total = math.min(total, cvMax:GetFloat())
    local words = table.concat(parts, ", ")
    if string.sub(tostring(reason or ""), 1, 11) == "Surrendered" then
        total = math.max(1, math.floor(total / 2)) -- (giving yourself up halves it, as it always has)
        words = words .. ", halved for giving yourself up"
    end
    ply.lcRap = {}
    SaveRap(ply)
    return math.max(10, math.floor(total * 60)), words .. string.format(": %d minute%s", total, total == 1 and "" or "s")
end

hook.Add("LivingCityIncarcerated", "LivingCitySentence", function(ply, seconds, reason, arrester)
    if not IsValid(ply) or not ply.SetPData then return end
    ply.lcWorkCap = math.floor((tonumber(seconds) or 0) * 0.5)
    ply.lcWorkOff = 0
    if IsValid(arrester) and not ply.lcExactSentence and cvProb:GetBool() then ply:SetPData("lc_probation_due", "1") end
    if cvWork:GetBool() and LC.Notice then
        LC.Notice(ply, "info", "In a cell", "Want time off? F1 > Ask for a work detail: a guard walks you out to pick up trash, "
            .. cvWorkOff:GetInt() .. " seconds off for each piece.", 10)
    end
end)

------------------------------------------------------------------------
-- The work detail
------------------------------------------------------------------------

LC.WorkDetails = LC.WorkDetails or {} -- [ply] = { guard, stage, area, trash = { ent }, ... }
local DETAILS = LC.WorkDetails
local TRASH_MODELS = { "models/props_junk/garbage_milkcarton002a.mdl", "models/props_junk/garbage_metalcan001a.mdl",
    "models/props_junk/garbage_newspaper001a.mdl", "models/props_junk/garbage_plasticbottle003a.mdl",
    "models/props_junk/garbage_takeoutcarton001a.mdl", "models/props_junk/garbage_bag001a.mdl" }
local PIECES = 6
local DETAIL_MAX = 240   -- seconds a detail lasts at most
local STRAY = 700        -- this far from the guard while out: an escape
local NEAR = 110

local function Up(npc) return IsValid(npc) and npc:Health() > 0 and LC.NPCs and LC.NPCs[npc] ~= nil end
local function Ground(v) return LC.GroundAt and LC.GroundAt(v) or v end

local function GuardFor(cellPos)
    local best, bd
    for npc, st in pairs(LC.NPCs or {}) do
        if Up(npc) and (st.role == "soldier" or st.role == "cop") and not st.test and not st.questLock and not st.marching
            and not st.tutorBusy and not st.workDetail and st.state ~= "hostile" and st.state ~= "event" then
            local d = npc:GetPos():DistToSqr(cellPos)
            if st.prisonGuard then d = d * 0.1 end -- (a Nova Prospekt guard first)
            if d < 5000 * 5000 and (not bd or d < bd) then best, bd = npc, d end
        end
    end
    return best
end

-- Where the trash is: the work spot, the prison zone, or the corridor by the cells.
local function WorkArea(cellPos)
    local best, bd
    for _, p in ipairs(LC.PointsOfKind and LC.PointsOfKind("prisonwork") or {}) do
        local d = p.pos:DistToSqr(cellPos)
        if not bd or d < bd then best, bd = p.pos, d end
    end
    if best then return best end
    for _, z in ipairs(LC.ZonesOfKind and LC.ZonesOfKind("prison") or {}) do
        local p = LC.GuardPostSpot and LC.GuardPostSpot(z)
        if p then return p end
    end
    local sum, n = Vector(0, 0, 0), 0
    for _, p in ipairs(LC.PointsOfKind and LC.PointsOfKind("cell") or {}) do sum = sum + p.pos n = n + 1 end
    if n > 1 then return sum / n end
    return cellPos + Vector(200, 0, 0)
end
LC.PrisonWorkArea = WorkArea

local function SpawnTrash(D)
    D.trash = {}
    for i = 1, PIECES do
        local a = (i / PIECES) * math.pi * 2 + math.Rand(-0.3, 0.3)
        local r = math.Rand(60, 220)
        local spot = Ground(D.area + Vector(math.cos(a) * r, math.sin(a) * r, 16))
        if LC.ClearSpot and not LC.ClearSpot(spot) then spot = Ground(D.area + Vector(math.Rand(-40, 40), math.Rand(-40, 40), 16)) end
        local e = ents.Create("prop_physics")
        if IsValid(e) then
            e:SetModel(TRASH_MODELS[math.random(#TRASH_MODELS)])
            e:SetPos(spot + Vector(0, 0, 4))
            e:SetAngles(Angle(0, math.random(0, 359), 0))
            e:Spawn()
            e.lcPrisonTrash = D.ply
            e:SetNW2Bool("lc_prison_trash", true)
            D.trash[#D.trash + 1] = e
        end
    end
end

local function ClearTrash(D)
    for _, e in ipairs(D.trash or {}) do if IsValid(e) then e:Remove() end end
    D.trash = {}
end

local function ReleaseGuard(D)
    local st = Up(D.guard) and LC.NPCs[D.guard]
    if not st then return end
    st.workDetail, st.questLock = nil, nil
    st.eventUntil = 0
    if st.state == "event" or st.state == "moving" then LC.SetState(D.guard, st, "idle") st.untilT = CurTime() + 2 end
end

local function EndDetail(D, back)
    local ply = D.ply
    DETAILS[ply] = nil
    ClearTrash(D)
    ReleaseGuard(D)
    local pr = IsValid(ply) and LC.Prisoners and LC.Prisoners[ply]
    if pr then
        pr.work = nil
        if back and ply:Alive() then LC.ReturnToCell(ply, back) end
    end
    if IsValid(ply) then ply:SetNW2Bool("lc_work_detail", false) end
end
LC.EndWorkDetail = EndDetail

-- Walked along beside the guard (not cuffed: he has your arm).
local function Pull(ply, lead)
    local v = lead:GetVelocity()
    v.z = 0
    local fwd = v:LengthSqr() > 100 and v:GetNormalized() or lead:GetForward()
    fwd.z = 0
    local want = lead:GetPos() - fwd * 40 + Vector(fwd.y, -fwd.x, 0) * 26
    local d = want - ply:GetPos()
    d.z = 0
    local dist = d:Length()
    if dist > 260 then
        ply:SetPos(Vector(want.x, want.y, lead:GetPos().z + 2))
    elseif dist > 30 then
        local pv = ply:GetVelocity()
        ply:SetVelocity(d:GetNormalized() * math.min(dist * 5, 240) - Vector(pv.x, pv.y, 0))
    end
end

function LC.AskWorkDetail(ply)
    if not cvWork:GetBool() then return false, "There are no work details in this prison." end
    local pr = LC.Prisoners and LC.Prisoners[ply]
    if not pr then return false, "Only prisoners get a work detail." end
    if DETAILS[ply] then return false, "You're on a work detail already." end
    local left = pr.untilT - CurTime()
    if left < 60 then return false, "Not with less than a minute left." end
    if (ply.lcWorkOff or 0) >= (ply.lcWorkCap or 0) then return false, "You've had all the time off this sentence allows." end
    local guard = GuardFor(pr.cell.pos)
    if not guard then return false, "No guard is free to take you out. Ask again in a minute." end
    local st = LC.NPCs[guard]
    st.workDetail, st.questLock = ply, true
    LC.SetState(guard, st, "event")
    st.eventUntil = CurTime() + DETAIL_MAX + 120
    local D = { ply = ply, guard = guard, stage = "fetch", startT = CurTime(), area = WorkArea(pr.cell.pos), picked = 0, tries = 0 }
    DETAILS[ply] = D
    pr.work = true
    ply:SetNW2Bool("lc_work_detail", true)
    if LC.GoTo then LC.GoTo(guard, st, pr.cell.pos, false) end
    guard:EmitSound("npc/combine_soldier/vo/copy.wav", 70)
    ply:ChatPrint("[Prison] A guard is coming to take you out on a work detail. Wait by your cell.")
    return true
end

local function GoOn(D, dest)
    local st = LC.NPCs[D.guard]
    if st.state == "moving" then return true end
    D.tries = D.tries + 1
    if D.tries > 8 then return false end
    return LC.GoTo and LC.GoTo(D.guard, st, dest, false) or false
end

local function DetailStep(D, now)
    local ply = D.ply
    local pr = IsValid(ply) and LC.Prisoners and LC.Prisoners[ply]
    if not pr or not ply:Alive() then return EndDetail(D) end
    if not Up(D.guard) then
        -- the guard's down: you're where you are, and the prison's rules again
        ply:ChatPrint("[Prison] Your guard is down.")
        return EndDetail(D)
    end
    local st = LC.NPCs[D.guard]
    st.eventUntil = now + 60
    if st.state == "hostile" then
        ply:ChatPrint("[Prison] The guard has other things to deal with. Back to your cell.")
        return EndDetail(D, "Back in your cell.")
    end
    local gd = ply:GetPos():DistToSqr(D.guard:GetPos())
    if D.stage == "fetch" then
        if D.guard:GetPos():DistToSqr(pr.cell.pos) < 160 * 160 or gd < NEAR * NEAR then
            D.stage, D.tries = "out", 0
            ply:SetPos(LC.ReleaseSpot and LC.ReleaseSpot(D.guard:GetPos() + D.guard:GetForward() * -40, ply) or D.guard:GetPos())
            ply:ChatPrint("[Prison] The guard unlocks your cell and walks you out to the work detail.")
            LC.GoTo(D.guard, st, D.area, false)
        elseif not GoOn(D, pr.cell.pos) then
            ply:ChatPrint("[Prison] No guard could get to you. Ask again later.")
            return EndDetail(D)
        end
    elseif D.stage == "out" then
        if D.guard:GetPos():DistToSqr(D.area) < 200 * 200 or (st.state ~= "moving" and D.guard:GetPos():DistToSqr(D.area) < 500 * 500) then
            D.stage, D.workAt = "work", now
            SpawnTrash(D)
            D.guard:SetSchedule(SCHED_IDLE_STAND)
            ply:ChatPrint("[Prison] Pick up the trash: E on each piece. " .. cvWorkOff:GetInt() .. " seconds off your sentence for each. Stay close to the guard.")
            if LC.Notice then LC.Notice(ply, "info", "Work detail", "Pick up the trash (E on each piece). Wander off and it's an escape.", 8) end
        elseif not GoOn(D, D.area) then
            D.area = ply:GetPos() -- (couldn't walk there: the work is here)
            D.stage, D.workAt = "work", now
            SpawnTrash(D)
        else
            Pull(ply, D.guard)
        end
    elseif D.stage == "work" then
        if gd > STRAY * STRAY then
            DETAILS[ply] = nil
            ClearTrash(D)
            ReleaseGuard(D)
            pr.work = nil
            ply:SetNW2Bool("lc_work_detail", false)
            if LC.EscapePrisoner then LC.EscapePrisoner(ply) end
            return
        end
        local left = 0
        for _, e in ipairs(D.trash) do if IsValid(e) then left = left + 1 end end
        if left == 0 or now - D.workAt > DETAIL_MAX or (ply.lcWorkOff or 0) >= (ply.lcWorkCap or 0) then
            D.stage, D.tries = "back", 0
            ClearTrash(D)
            ply:ChatPrint("[Prison] That'll do. The guard walks you back to your cell.")
            LC.GoTo(D.guard, st, pr.cell.pos, false)
        end
    elseif D.stage == "back" then
        if D.guard:GetPos():DistToSqr(pr.cell.pos) < 170 * 170 or (st.state ~= "moving" and D.guard:GetPos():DistToSqr(pr.cell.pos) < 600 * 600) then
            return EndDetail(D, "Back in your cell. The door locks behind you.")
        elseif not GoOn(D, pr.cell.pos) then
            return EndDetail(D, "Back in your cell. The door locks behind you.")
        else
            Pull(ply, D.guard)
        end
    end
end

-- A piece of trash picked up (E on it).
function LC.PickUpPrisonTrash(ply, e)
    local D = DETAILS[ply]
    if not D or D.stage ~= "work" or not IsValid(e) or e.lcPrisonTrash ~= ply then return false end
    local pr = LC.Prisoners and LC.Prisoners[ply]
    if not pr then return false end
    e:Remove()
    D.picked = D.picked + 1
    local off = math.min(cvWorkOff:GetFloat(), math.max(0, (ply.lcWorkCap or 0) - (ply.lcWorkOff or 0)), math.max(0, pr.untilT - CurTime() - 15))
    pr.untilT = pr.untilT - off
    ply.lcWorkOff = (ply.lcWorkOff or 0) + off
    ply:SetNW2Float("lc_jail_until", pr.untilT)
    ply:EmitSound("physics/cardboard/cardboard_box_impact_soft" .. math.random(1, 3) .. ".wav", 60)
    ply:ChatPrint(string.format("[Prison] Picked up. %d seconds off your sentence (%s left).", math.floor(off), string.NiceTime(math.max(0, pr.untilT - CurTime()))))
    return true
end

hook.Add("PlayerUse", "LivingCityPrisonTrash", function(ply, e)
    if IsValid(e) and e.lcPrisonTrash then
        if e.lcPrisonTrash == ply then LC.PickUpPrisonTrash(ply, e) end
        return false
    end
end)

------------------------------------------------------------------------
-- Probation
------------------------------------------------------------------------

local function Citizen(ply)
    local f = ply:GetNW2String("lcf_faction", "")
    return f == "" or f == "citizen"
end

local function StartProbation(ply, secs)
    ply.lcProbationUntil = CurTime() + secs
    ply.lcProbationChecked = false
    ply.lcProbationWarned = 0
    ply:SetNW2Float("lc_probation_until", ply.lcProbationUntil)
    ply:SetNW2Bool("lc_probation_checked", false)
end
LC.StartProbation = StartProbation

local function EndProbation(ply, quiet)
    local was = ply.lcProbationUntil
    ply.lcProbationUntil = nil
    ply:SetNW2Float("lc_probation_until", 0)
    ply:RemovePData("lc_probation_left")
    if quiet or not was then return end
    if not ply.lcProbationChecked then
        ply:ChatPrint("[Civil Protection] You never checked in. Failure to report for probation.")
        LC.ReportCrime(ply, "Failure to report for probation", 180)
    else
        ply:ChatPrint("[Civil Protection] Your probation is over. Stay out of trouble.")
    end
end
LC.EndProbation = EndProbation

hook.Add("LivingCityReleased", "LivingCitySentence", function(ply)
    if not IsValid(ply) or not ply.GetPData then return end
    local D = DETAILS[ply]
    if D then EndDetail(D) end
    ply.lcWorkCap, ply.lcWorkOff = nil, nil
    if ply:GetPData("lc_probation_due", "0") ~= "1" then return end
    ply:RemovePData("lc_probation_due")
    if not cvProb:GetBool() or not Citizen(ply) then return end
    local mins = cvProbMins:GetFloat()
    StartProbation(ply, mins * 60)
    local msg = string.format("You're on probation for %d minutes. Check in with a Civil Protection unit (F1 > Check in for probation, standing close to one). "
        .. "Any offence counts double. Stay out of rebel territory and away from the Resistance.", mins)
    ply:ChatPrint("[Civil Protection] " .. msg)
    if LC.Notice then LC.Notice(ply, "warn", "On probation", msg, 12) end
end)

local function UnitNear(ply, r)
    for npc, st in pairs(LC.NPCs or {}) do
        if Up(npc) and (st.role == "cop" or st.role == "soldier") and npc:GetPos():DistToSqr(ply:GetPos()) < r * r then return npc end
    end
    for _, p in ipairs(player.GetAll()) do
        if p ~= ply and p:Alive() and LC.PlayerIsCP(p) and p:GetPos():DistToSqr(ply:GetPos()) < r * r then return p end
    end
    return nil
end

function LC.ProbationCheckIn(ply)
    if not LC.OnProbation(ply) then return false, "You're not on probation." end
    if ply.lcProbationChecked then return false, "You've checked in already." end
    local unit = UnitNear(ply, 220)
    if not unit then return false, "Find a Civil Protection unit and stand close to them to check in." end
    ply.lcProbationChecked = true
    ply:SetNW2Bool("lc_probation_checked", true)
    if unit:IsNPC() then unit:EmitSound("npc/metropolice/vo/affirmative.wav", 70) end
    if unit:IsPlayer() then unit:ChatPrint("[Civil Protection] " .. ply:Nick() .. " checked in for probation.") end
    ply:ChatPrint("[Civil Protection] Checked in. Keep your nose clean until your probation is over.")
    return true
end

-- A probation violation: on the record (doubled, being on probation) and wanted.
function LC.ProbationViolation(ply, what)
    if not LC.OnProbation(ply) then return false end
    if CurTime() < (ply.lcProbationWarned or 0) then return false end
    ply.lcProbationWarned = CurTime() + 300
    ply:ChatPrint("[Civil Protection] Probation violation: " .. what .. ".")
    LC.ReportCrime(ply, "Probation violation: " .. what, 240)
    if LC.RadioNotice then LC.RadioNotice("cp", "Probation violation: " .. ply:Nick() .. ", " .. what .. ".") end
    return true
end

-- Helping the Resistance on probation (any sympathy earned) is a violation.
local wrapped = false
local function Wrap()
    if LC.MenuActions then LC.MenuActions.workdetail, LC.MenuActions.checkin = true, true end
    if wrapped or not LC.AddTrait then return end
    wrapped = true
    local orig = LC.AddTrait
    LC.AddTrait = function(ply, name, d, ...)
        local r = orig(ply, name, d, ...)
        if name == "sympathy" and (tonumber(d) or 0) > 0 and LC.OnProbation(ply) then
            LC.ProbationViolation(ply, "helping the Resistance")
        end
        return r
    end
end
Wrap()
hook.Add("Initialize", "LivingCitySentenceWrap", Wrap)

local function ProbationTick(now)
    for _, ply in ipairs(player.GetAll()) do
        if ply.lcProbationUntil then
            if now >= ply.lcProbationUntil then
                EndProbation(ply)
            elseif ply:Alive() and LC.InRebelZone and LC.InRebelZone(ply:GetPos()) then
                LC.ProbationViolation(ply, "in rebel territory")
            end
        end
    end
end

hook.Add("PlayerDisconnected", "LivingCitySentence", function(ply)
    local D = DETAILS[ply]
    if D then ClearTrash(D) ReleaseGuard(D) DETAILS[ply] = nil end
    if LC.OnProbation(ply) then
        ply:SetPData("lc_probation_left", math.floor(ply.lcProbationUntil - CurTime()) .. (ply.lcProbationChecked and ":1" or ":0"))
    end
end)
hook.Add("PlayerInitialSpawn", "LivingCitySentence", function(ply)
    local s = ply:GetPData("lc_probation_left", "")
    if s == "" then return end
    local left, checked = string.match(s, "^(%d+):(%d)$")
    ply:RemovePData("lc_probation_left")
    if tonumber(left) and tonumber(left) > 0 then
        StartProbation(ply, tonumber(left))
        ply.lcProbationChecked = checked == "1"
        ply:SetNW2Bool("lc_probation_checked", ply.lcProbationChecked)
    end
end)

------------------------------------------------------------------------

function LC.SentenceTick(now)
    now = now or CurTime()
    local list = {}
    for _, D in pairs(DETAILS) do list[#list + 1] = D end
    for _, D in ipairs(list) do
        if DETAILS[D.ply] == D then DetailStep(D, now) end
    end
end

local nextProb = 0
timer.Create("LivingCitySentence", 0.2, 0, function()
    local now = CurTime()
    local ok, err = pcall(function()
        if next(DETAILS) then LC.SentenceTick(now) end
        if now >= nextProb then
            nextProb = now + 2
            ProbationTick(now)
        end
    end)
    if not ok and LC.Error then LC.Error("sentence", err) end
end)

-- The menu's actions (F1): ask for a work detail, check in for probation.
if LC.MenuActions then LC.MenuActions.workdetail, LC.MenuActions.checkin = true, true end
hook.Add("PlayerSay", "LivingCitySentence", function(ply, text)
    local cmd = string.lower(string.Trim(tostring(text or "")))
    if cmd == "!workdetail" or cmd == "/workdetail" then
        local ok, why = LC.AskWorkDetail(ply)
        if not ok and why then ply:ChatPrint("[Prison] " .. why) end
        return ""
    elseif cmd == "!checkin" or cmd == "/checkin" then
        local ok, why = LC.ProbationCheckIn(ply)
        if not ok and why then ply:ChatPrint("[Civil Protection] " .. why) end
        return ""
    end
end)
