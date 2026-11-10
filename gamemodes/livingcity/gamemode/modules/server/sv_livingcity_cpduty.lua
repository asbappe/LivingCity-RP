--[[
    Living City: a Civil Protection shift, with a quota and a review
    (the owner, 10 November: "Love it all, yes please": something for the
    Combine to do when there are no rebels about).

    Every Civil Protection player on duty works shifts of lc_cp_shift_minutes
    (15; the owner, 10 November: "30 ... is a bit extreme, let's do 15"). Each shift has a quota, on F2 > My shift:
      - searches        lc_cp_quota_searches (3): anyone, a player or one of
                        the city's people (the pat-down, the baton's reload)
      - papers duty     lc_cp_quota_papers (1): F2 > My shift > Checkpoint
                        papers duty, the travelers' papers checked against
                        today's rules (the Intake Processor's game), at a
                        checkpoint post or Civil Intake if there is one near
      - an inspection   lc_cp_quota_inspections (1): F2 > My shift > Get an
                        inspection order names a resident (a player who's
                        online) and their block; go there and F2 > My shift >
                        Inspect the residence (8 seconds). Their stash is
                        gone through: contraband in it is confiscated and they
                        are charged, as a block raid would (online or, if
                        they've left since, when they next join)
    At the end of the shift comes a performance review: a grade from the
    quota met (A all of it, B most, C some, D none), with arrests counting
    for extra, and experience for it (A 30, B 20, C 10), which is what
    promotes a unit. The last five reviews are kept (F2 > My shift).

      lc_cp_duty 0/1, lc_cp_shift_minutes (15), lc_cp_quota_searches (3),
      lc_cp_quota_papers (1), lc_cp_quota_inspections (1)
]]

if CLIENT then return end

LC = LC or {}

local FLAGS = bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED)
local cvOn      = CreateConVar("lc_cp_duty", "1", FLAGS, "Civil Protection players work shifts with a quota (searches, papers duty, an inspection) and a performance review")
local cvMins    = CreateConVar("lc_cp_shift_minutes", "15", FLAGS, "Minutes in a Civil Protection shift")
local cvSearch  = CreateConVar("lc_cp_quota_searches", "3", FLAGS, "Searches in a Civil Protection shift's quota")
local cvPapers  = CreateConVar("lc_cp_quota_papers", "1", FLAGS, "Checkpoint papers duties in a Civil Protection shift's quota")
local cvInspect = CreateConVar("lc_cp_quota_inspections", "1", FLAGS, "Residence inspections in a Civil Protection shift's quota")

local REVIEW_XP = { A = 30, B = 20, C = 10, D = 0 }
local INSPECT_SECS = 8
local FIND_CHANCE = 0.8 -- (each contraband item in a stash: found this often)

local function OnDuty(ply)
    return cvOn:GetBool() and IsValid(ply) and ply:IsPlayer() and ply:GetNW2String("lcf_faction", "") == "cp" and not ply.lcOffDuty
end
LC.CPOnDuty = OnDuty

local function Shift(ply)
    if not OnDuty(ply) then return nil end
    local s = ply.lcShift
    if not s then
        s = { startT = CurTime(), searches = 0, papers = 0, inspections = 0, arrests = 0 }
        ply.lcShift = s
    end
    return s
end
LC.CPShift = Shift

local function Quota()
    return { searches = math.max(0, cvSearch:GetInt()), papers = math.max(0, cvPapers:GetInt()), inspections = math.max(0, cvInspect:GetInt()) }
end
LC.CPQuota = Quota

local function Sync(ply)
    local s = Shift(ply)
    if not s then ply:SetNW2String("lc_shift", "") return end
    local q = Quota()
    local o = ply.lcInspectOrder
    ply:SetNW2String("lc_shift", util.TableToJSON({
        left = math.max(0, math.floor(s.startT + cvMins:GetFloat() * 60 - CurTime())),
        searches = s.searches, papers = s.papers, inspections = s.inspections, arrests = s.arrests,
        q = q, order = o and { name = o.name, block = o.blockName } or nil,
    }) or "")
end
LC.CPShiftSync = Sync

local function Count(ply, what, n)
    local s = Shift(ply)
    if not s then return end
    local before = s[what] or 0
    s[what] = before + (n or 1)
    local q = Quota()[what]
    if q and before < q and s[what] >= q then
        ply:ChatPrint(string.format("[CP net] Quota: %s done for this shift.", what == "searches" and "searches" or (what == "papers" and "papers duty" or "the inspection")))
    end
    Sync(ply)
end
LC.CPCount = Count

------------------------------------------------------------------------
-- Counting what they do
------------------------------------------------------------------------

hook.Add("LivingCitySearched", "LivingCityCPDuty", function(searcher, target)
    if IsValid(searcher) and searcher:IsPlayer() then Count(searcher, "searches") end
end)
-- a search of one of the city's people (sv_livingcity_underground.lua), found something or not
local wrapped = false
local function Wrap()
    if wrapped or not LC.SearchNPCFound or not LC.SearchNPCClean then return end
    wrapped = true
    local found, clean = LC.SearchNPCFound, LC.SearchNPCClean
    LC.SearchNPCFound = function(cop, ...) local r = found(cop, ...) if IsValid(cop) and cop:IsPlayer() then Count(cop, "searches") end return r end
    LC.SearchNPCClean = function(cop, ...) local r = clean(cop, ...) if IsValid(cop) and cop:IsPlayer() then Count(cop, "searches") end return r end
end
Wrap()
hook.Add("Initialize", "LivingCityCPDuty", Wrap)
hook.Add("LivingCityIncarcerated", "LivingCityCPDuty", function(ply, secs, reason, arrester)
    if IsValid(arrester) and arrester:IsPlayer() then Count(arrester, "arrests") end
end)

------------------------------------------------------------------------
-- Checkpoint papers duty
------------------------------------------------------------------------

function LC.CPPapersDuty(ply)
    if not OnDuty(ply) then return false, "Civil Protection on duty only." end
    if not LC.JobGameStart then return false, "There's no papers duty here." end
    local g = LC.JobGames and LC.JobGames[ply]
    if g then return false, "Finish what you're doing first." end
    if not LC.JobGameStart(ply, "papers", nil, { cpDuty = true }) then return false, "Papers duty couldn't start here." end
    ply.lcPapersDuty = LC.JobGames[ply]
    ply:ChatPrint("[CP net] Checkpoint papers duty. Check each traveler against today's rules (E on them).")
    return true
end

------------------------------------------------------------------------
-- Residence inspections
------------------------------------------------------------------------

function LC.CPInspectOrder(ply)
    if not OnDuty(ply) then return false, "Civil Protection on duty only." end
    if ply.lcInspectOrder and IsValid(ply.lcInspectOrder.target) then
        return false, string.format("You have an order already: %s, %s.", ply.lcInspectOrder.name, ply.lcInspectOrder.blockName)
    end
    local cands = {}
    for _, p in ipairs(player.GetAll()) do
        local f = p:GetNW2String("lcf_faction", "")
        if p ~= ply and (f == "" or f == "citizen" or f == "resistance") and LC.PlayerBlock and LC.PlayerBlock(p) then cands[#cands + 1] = p end
    end
    if #cands == 0 then return false, "No residences to inspect right now: nobody housed is in the city." end
    local t = cands[math.random(#cands)]
    local block = LC.PlayerBlock(t)
    local name = (LC.CharacterName and LC.CharacterName(t)) or t:Nick()
    ply.lcInspectOrder = { target = t, name = name, block = block, blockName = LC.BlockName and LC.BlockName(block) or ("Block " .. block) }
    ply:ChatPrint(string.format("[CP net] Inspection order: the residence of %s, %s. Go there, and F2 > My shift > Inspect the residence.", name, ply.lcInspectOrder.blockName))
    Sync(ply)
    return true
end

function LC.CPInspect(ply)
    local o = ply.lcInspectOrder
    if not OnDuty(ply) or not o then return false, "No inspection order: F2 > My shift > Get an inspection order." end
    if not IsValid(o.target) then
        ply.lcInspectOrder = nil
        Sync(ply)
        return false, "The resident has left the city. Get another order."
    end
    if not (LC.InBlock and LC.InBlock(ply:GetPos(), o.block)) then return false, "You're not in " .. o.blockName .. " yet." end
    if not LC.StartTask then return false end
    ply:EmitSound("physics/wood/wood_box_impact_soft" .. math.random(1, 3) .. ".wav", 60)
    return LC.StartTask(ply, INSPECT_SECS, "Searching the residence...", { maxMove = 160, cancelText = "You stop the inspection.",
        done = function(p)
            local t = o.target
            p.lcInspectOrder = nil
            local found, names = 0, {}
            if IsValid(t) and LC.Stash and LCS then
                local st = LC.Stash(t)
                for id, n in pairs(table.Copy(st)) do
                    local it = LCS.Items[id]
                    if it and it.contraband then
                        local k = 0
                        for _ = 1, n do if math.random() < FIND_CHANCE then k = k + 1 end end
                        if k > 0 then
                            st[id] = (n - k > 0) and (n - k) or nil
                            found = found + k
                            names[#names + 1] = it.name .. (k > 1 and (" x" .. k) or "")
                            if LC.EvidenceAdd then LC.EvidenceAdd(id, k, "inspection") end
                        end
                    end
                end
                if found > 0 and t.SetPData then t:SetPData("lci_stash_" .. game.GetMap(), util.TableToJSON(st)) end
            end
            Count(p, "inspections")
            if found > 0 then
                p:ChatPrint(string.format("[CP net] Inspection of %s's residence: confiscated %s.", o.name, table.concat(names, ", ")))
                if LC.AddXP then LC.AddXP(p, 5 * found, "contraband found in an inspection") end
                if IsValid(t) and LC.RaidCharge then
                    t:ChatPrint("[Civil Protection] Your residence in " .. o.blockName .. " was inspected.")
                    LC.RaidCharge(t, found, o.block)
                end
            else
                p:ChatPrint(string.format("[CP net] Inspection of %s's residence: clean.", o.name))
                if IsValid(t) then t:ChatPrint("[Civil Protection] Your residence in " .. o.blockName .. " was inspected. Nothing was found.") end
            end
            hook.Run("LivingCityResidenceInspected", p, t, found)
            Sync(p)
        end })
end

------------------------------------------------------------------------
-- The review, at the end of a shift
------------------------------------------------------------------------

function LC.CPReview(ply)
    local s = ply.lcShift
    if not s then return nil end
    local q = Quota()
    local parts, met, total = {}, 0, 0
    for _, k in ipairs({ "searches", "papers", "inspections" }) do
        if q[k] > 0 then
            total = total + 1
            local frac = math.min(1, (s[k] or 0) / q[k])
            met = met + frac
            parts[#parts + 1] = string.format("%s %d/%d", k, s[k] or 0, q[k])
        end
    end
    local score = total > 0 and (met / total) or 1
    score = score + math.min(0.25, (s.arrests or 0) * 0.1) -- (arrests count for extra)
    local grade = score >= 1 and "A" or (score >= 0.66 and "B" or (score >= 0.33 and "C" or "D"))
    local xp = REVIEW_XP[grade] or 0
    if xp > 0 and LC.AddXP then LC.AddXP(ply, xp, "performance review: " .. grade) end
    local line = string.format("Grade %s. %s%s.", grade, table.concat(parts, ", "), (s.arrests or 0) > 0 and (", arrests " .. s.arrests) or "")
    local list = util.JSONToTable(ply:GetPData("lc_cp_reviews", "") or "") or {}
    table.insert(list, 1, { grade = grade, line = line, at = os.time() })
    while #list > 5 do table.remove(list) end
    ply:SetPData("lc_cp_reviews", util.TableToJSON(list))
    ply:SetNW2String("lc_cp_reviews", util.TableToJSON(list))
    local text = "Performance review. " .. line .. (xp > 0 and string.format(" %d experience.", xp) or " Do better next shift.")
    if LC.Notice then LC.Notice(ply, grade == "D" and "warn" or "info", "End of shift", text, 12) end
    ply:ChatPrint("[CP net] " .. text)
    ply.lcShift = nil
    hook.Run("LivingCityCPReview", ply, grade, s)
    return grade, xp
end

-- The checklist done early: reviewed now, and the next shift starts straight away (the owner, 10 November:
-- "adjust it so CP units do not have to take breaks between shifts if they so choose").
function LC.CPReportIn(ply)
    local s = Shift(ply)
    if not s then return false, "You're not on a shift." end
    local q = Quota()
    for k, n in pairs(q) do
        if (s[k] or 0) < n then return false, "Finish the checklist first (F2 > Me > My shift), or wait for the end of the shift." end
    end
    LC.CPReview(ply)
    Shift(ply)
    Sync(ply)
    ply:ChatPrint("[CP net] Reported in. Your next shift starts now.")
    return true
end

-- A break, if they want one: off duty, no shift and no review, until they're back.
function LC.CPBreak(ply)
    if not cvOn:GetBool() or not IsValid(ply) or ply:GetNW2String("lcf_faction", "") ~= "cp" then return false, "Civil Protection only." end
    if ply.lcOffDuty then
        ply.lcOffDuty = nil
        ply:SetNW2Bool("lc_offduty", false)
        Shift(ply)
        Sync(ply)
        ply:ChatPrint("[CP net] Back on duty. A new shift starts now.")
    else
        ply.lcOffDuty = true
        ply.lcShift, ply.lcInspectOrder = nil, nil
        ply:SetNW2Bool("lc_offduty", true)
        ply:SetNW2String("lc_shift", "")
        ply:ChatPrint("[CP net] On a break: no shift until you're back on duty (F2 > Me > Back on duty). The shift you were on is dropped.")
    end
    return true
end

local function Tick()
    local now = CurTime()
    for _, ply in ipairs(player.GetAll()) do
        if OnDuty(ply) then
            local s = Shift(ply)
            -- papers duty finished: counted
            local g = ply.lcPapersDuty
            if g and LC.JobGames and LC.JobGames[ply] ~= g then
                ply.lcPapersDuty = nil
                if (g.done or 0) >= 3 then Count(ply, "papers") end -- (most of the travelers seen: it counts)
            end
            if now >= s.startT + cvMins:GetFloat() * 60 then LC.CPReview(ply) Shift(ply) end
            if ply.lcInspectOrder and not IsValid(ply.lcInspectOrder.target) then
                ply.lcInspectOrder = nil
                ply:ChatPrint("[CP net] Your inspection order is cancelled: the resident has left the city.")
            end
            Sync(ply)
        elseif ply.lcShift then
            ply.lcShift, ply.lcInspectOrder = nil, nil
            ply:SetNW2String("lc_shift", "")
        end
    end
end
LC.CPDutyTick = Tick
timer.Create("LivingCityCPDuty", 5, 0, function()
    local ok, err = pcall(Tick)
    if not ok and LC.Error then LC.Error("cp duty", err) end
end)

hook.Add("PlayerInitialSpawn", "LivingCityCPDuty", function(ply)
    timer.Simple(5, function()
        if IsValid(ply) then ply:SetNW2String("lc_cp_reviews", ply:GetPData("lc_cp_reviews", "") or "") end
    end)
end)

-- The menu's actions (F2 > My shift).
local function Wrap2()
    if LC.MenuActions then
        LC.MenuActions.papersduty, LC.MenuActions.inspectorder, LC.MenuActions.inspect = true, true, true
        LC.MenuActions.reportin, LC.MenuActions.shiftbreak = true, true
    end
end
Wrap2()
hook.Add("Initialize", "LivingCityCPDutyActions", Wrap2)
hook.Add("PlayerSay", "LivingCityCPDuty", function(ply, text)
    local cmd = string.lower(string.Trim(tostring(text or "")))
    local fn = (cmd == "!papersduty" and LC.CPPapersDuty) or (cmd == "!inspectorder" and LC.CPInspectOrder) or (cmd == "!inspect" and LC.CPInspect)
        or (cmd == "!reportin" and LC.CPReportIn) or (cmd == "!shiftbreak" and LC.CPBreak)
    if not fn then return end
    local ok, why = fn(ply)
    if not ok and why then ply:ChatPrint("[CP net] " .. why) end
    return ""
end)
