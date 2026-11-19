--[[
    Living City: the Resistance's fund

    The owner, 18 November: "I think we need to add a limiter to all of this: the
    resistance leader can only order this if they've saved up enough money themselves to
    put into this extra pay, or have gathered enough funds in a Resistance fund, of sorts,
    that they can increase by having successful supply convoy raids and such; I suppose I
    am requesting that various successful missions where supplies are raided or people
    saved (who then donate small amounts of credits that they may have saved) would all be
    spit between the partakers of the activities and a general resistance fund, which is
    used to supply the resistance and then eventually can get large enough to fund these
    operations."

    The fund    A whole number of credits that belongs to the Resistance and to no player.
                Kept with the state of the city (LC.Ledger: "fund" in
                data/livingcity/<map>_city.json) and written the moment it changes, so it
                is there after a restart or a map change.
    The take    Each success below has a take in credits. Half goes to the fund; the other
                half is shared equally among the Resistance's players who took part, each
                paid by LC.AddCredits ("your share"). What does not divide stays with the
                fund. With no player of ours in it (the city's own fighters did it alone)
                the fund has its half, and the other half is the fighters' own.
                It is on top of what the success pays or gives already: no reward that
                was there is changed.
    Supplies    A load pried out of a supply convoy's crate by one of ours
                (LivingCitySupplyLooted): 20; the one who pried it.
                Our fighters' raid on a supply drop that got loads out of the crate
                (LivingCityRebelOpDone "supply": the city's own, or a planned operation):
                40; those who joined the plan and were there. A crate already cleaned
                out is no success.
                A crate of the Union's supplies stolen and brought home (the job
                res_supplyrun, finished): 30; everyone on the job.
    People      Someone saved "donates" a small sum, 10 to 30 (random), whoever they are.
                A player who is saved is never charged for it: nothing leaves their
                pockets.
                A prisoner out of the cells (LivingCityBreakout): whoever got the cell
                open and those on that job with them (res_breakout); with nobody named
                (the fighters' own operation), those who joined the plan and were there,
                once the operation says it worked.
                A vortigaunt cut loose by one of ours (LivingCityVortFreed): the one who
                cut. (The city's own team freeing one nobody came for: nothing.)
                A citizen broken out and led to safety, a fugitive brought home, a
                shackled vortigaunt led home (the jobs res_jailbreak, res_rescue and
                res_freevort, finished): everyone on the job.
    Pays for    The leader's order to kill the Administrator (lc_resistance_order_cost,
                sv_livingcity_adminplot.lua), and, since 19 November, the guns and rounds
                its players are issued by rank (sv_livingcity_fundgear.lua: the record of
                every change, the screen in the camp, donations).
    Seen        F2 > Resistance has one row for every member: "Fund: 120 credits"
                (sv_livingcity_quickmore.lua sends it). Nothing is said when it grows or
                is spent: no chat line, no notice, nothing on the radio.

    LC.ResistanceFund()                  how much it holds
    LC.ResistanceFundAdd(n, why, who)    n more (why: for the server's log and the record; who:
                                         the players it was for); how much now
    LC.ResistanceFundTake(n, why, who)   n out of it: true; false when it holds less
    LC.ResistanceFundSuccess(kind, who)  a success counted: "load", "raid", "run" or
                                         "saved", and the players who took part; what
                                         went to the fund and what each of them had

    Hooks heard (nothing is answered to any): LivingCitySupplyLooted, LivingCityRebelOpDone,
    LivingCityBreakout, LivingCityVortFreed, LivingCityQuestComplete. No settings, no
    commands, no file of its own: the numbers are the constants below.
]]

if CLIENT then return end

LC = LC or {}

local SPLIT = 0.5       -- the fund's part of every take; the rest is shared among those of ours who took part
local TAKE = {
    load = 20,          -- a load pried out of a supply convoy's crate by one of ours
    raid = 40,          -- our fighters' raid on a supply drop that got loads out of the crate
    run = 30,           -- a crate of the Union's supplies stolen and brought home (a job)
}
local SAVED = { 5, 15 } -- someone saved gives twice a number between these: 10 to 30, always even
local JOBS = {          -- a job finished that is one of these successes (what the others are counted by is in the header)
    res_supplyrun = "run", res_jailbreak = "saved", res_rescue = "saved", res_freevort = "saved",
}
local BREAKOUT_JOB = "res_breakout" -- the job whose members share a prisoner got out of the cells
local REACH = 1500      -- who was there, for a planned operation (as it pays them: sv_livingcity_opplan.lua)
local WHY = "your share" -- what each of them reads with their credits, as with any pay

local function Ours(p) return IsValid(p) and p:IsPlayer() and p:GetNW2String("lcf_faction", "") == "resistance" end

------------------------------------------------------------------------
-- The fund
------------------------------------------------------------------------

local function Book() return LC.Ledger and LC.Ledger() or nil end

function LC.ResistanceFund()
    local book = Book()
    return book and math.max(0, math.floor(tonumber(book.fund) or 0)) or 0
end

-- Written at once: what is paid out of it is kept with a player's own record, and the two must agree after a crash.
-- who: the players it was for or because of (the record names those of ours).
local function Set(n, why, who)
    local book = Book()
    if not book then return false end
    local was = LC.ResistanceFund()
    book.fund = math.max(0, math.floor(n))
    -- (one entry in the fund's record, which the screen in the camp shows: sv_livingcity_fundgear.lua)
    if LC.ResistanceFundRecord and book.fund ~= was then LC.Try(LC.ResistanceFundRecord, book.fund - was, why, who) end
    if LC.LedgerSave then LC.Try(LC.LedgerSave) end
    if LC.Log and book.fund ~= was then
        LC.Log("info", string.format("The Resistance's fund: %+d (%s), now %d", book.fund - was, tostring(why or "?"), book.fund))
    end
    return true
end

function LC.ResistanceFundAdd(n, why, who)
    n = math.floor(tonumber(n) or 0)
    if n > 0 then Set(LC.ResistanceFund() + n, why, who) end
    return LC.ResistanceFund()
end

function LC.ResistanceFundTake(n, why, who)
    n = math.floor(tonumber(n) or 0)
    if n <= 0 then return true end
    local has = LC.ResistanceFund()
    if has < n then return false end
    return Set(has - n, why, who)
end

------------------------------------------------------------------------
-- A success, and its take
------------------------------------------------------------------------

-- The players of ours among them, each once.
local function Partakers(list, except)
    local out, seen = {}, {}
    for _, p in pairs(list or {}) do
        if Ours(p) and p ~= except and not seen[p] then
            seen[p] = true
            out[#out + 1] = p
        end
    end
    return out
end

-- Half to the fund, half shared equally among those who took part (what does not divide stays with the fund).
-- What went to the fund, and what each of them had.
function LC.ResistanceFundSuccess(kind, who, except)
    local take = TAKE[kind] or (kind == "saved" and 2 * math.random(SAVED[1], SAVED[2])) or 0
    if take <= 0 then return 0, 0 end
    local party = Partakers(who, except)
    local shared = math.floor(take * (1 - SPLIT))
    local each = #party > 0 and math.floor(shared / #party) or 0
    local kept = #party > 0 and (take - each * #party) or (take - shared)
    LC.ResistanceFundAdd(kept, kind, party)
    if each > 0 and LC.AddCredits then
        for _, p in ipairs(party) do LC.AddCredits(p, each, WHY) end
    end
    return kept, each
end
local Success = LC.ResistanceFundSuccess

-- Whoever is named, and those on that job with them.
local function Party(by, job)
    local out = { by }
    local q = LC.QuestOf and LC.QuestOf[by]
    if istable(q) and istable(q.tmpl) and q.tmpl.id == job then
        for _, p in ipairs(q.members or {}) do out[#out + 1] = p end
    end
    return out
end

-- Those who joined the plan of an operation and were there when it worked.
local function There(sk)
    local plan, out = istable(sk) and sk.planned or nil, {}
    if not (istable(plan) and istable(plan.joined) and plan.pos) then return out end
    for p in pairs(plan.joined) do
        if IsValid(p) and p:Alive() and p:GetPos():DistToSqr(plan.pos) < REACH * REACH then out[#out + 1] = p end
    end
    return out
end

-- An error here never spoils the success itself, nor what it pays already: it is written in the errors file.
local function Heard(what, fn, ...)
    local okH, err = LC.Try(fn, ...)
    if not okH and LC.Error then LC.Error("the Resistance's fund (" .. what .. ")", err) end
end

------------------------------------------------------------------------
-- Supplies raided
------------------------------------------------------------------------

local pried = setmetatable({}, { __mode = "k" }) -- [a supply drop] = loads pried out of its crate by hand, whoever by

hook.Add("LivingCitySupplyLooted", "LivingCityResistanceFund", function(ply)
    Heard("a load", function()
        local s = LC.Supply
        if istable(s) then pried[s] = (pried[s] or 0) + 1 end
        if Ours(ply) then Success("load", { ply }) end
    end)
end)

local sprung -- a prisoner let out with nobody named (the fighters' own operation), until it says it worked: { who, at }

hook.Add("LivingCityRebelOpDone", "LivingCityResistanceFund", function(purpose, sk)
    Heard("an operation", function()
        if purpose == "supply" then
            -- (the crate was down and still held a load when they got into it: "cleaned out already" is no success)
            local s = LC.Supply
            if not (istable(s) and IsValid(s.crate)) then return end
            if (tonumber(s.loads) or 0) - (pried[s] or 0) <= 0 then return end
            pried[s] = tonumber(s.loads) or 0 -- (all of it is gone now)
            Success("raid", There(sk))
        elseif purpose == "breakout" then
            local out = sprung
            sprung = nil
            if out and CurTime() - out.at < 1 then Success("saved", There(sk), out.who) end
        end
    end)
end)

------------------------------------------------------------------------
-- People saved
------------------------------------------------------------------------

hook.Add("LivingCityBreakout", "LivingCityResistanceFund", function(prisoner, by)
    Heard("a breakout", function()
        if IsValid(by) and by:IsPlayer() then
            if Ours(by) then Success("saved", Party(by, BREAKOUT_JOB), prisoner) end
            return
        end
        sprung = { who = prisoner, at = CurTime() }
    end)
end)

hook.Add("LivingCityVortFreed", "LivingCityResistanceFund", function(vort, by)
    Heard("a vortigaunt freed", function()
        if Ours(by) then Success("saved", { by }, vort) end
    end)
end)

local counted = setmetatable({}, { __mode = "k" }) -- [a job] = true: one success, however many were on it

hook.Add("LivingCityQuestComplete", "LivingCityResistanceFund", function(ply, q)
    Heard("a job", function()
        local kind = istable(q) and istable(q.tmpl) and JOBS[q.tmpl.id] or nil
        if not kind or counted[q] then return end
        counted[q] = true
        Success(kind, q.members)
    end)
end)

------------------------------------------------------------------------
-- What a job feeds the fund, for the job boards
------------------------------------------------------------------------

-- Every job lists what it can put in the fund (the owner, 19 November: "the range of credits that will/can go into the
-- resistance fund. this means all players feel responsible for helping grow the resistance fund"). Read from the takes
-- above, so the board and the fund never disagree (LC.PostingPay, sv_livingcity_quests.lua).

-- How a finished job of this id is counted: the kind of success, its partakers everyone on the job; or nil.
function LC.ResistanceFundJobKind(id)
    return JOBS[id] or (id == BREAKOUT_JOB and "saved") or nil
end

-- A job step counted by one of these events is a success of that kind each time, the one who did it its only partaker
-- (a load pried out of a supply drop's crate; a collared vortigaunt cut loose: LC.FreeStreetVort).
LC.ResistanceFundStepKinds = { supply_looted = "load", vort_freed = "saved" }

-- A success of that kind with n of ours taking part: the least and the most the fund keeps, and the least and the
-- most each of them has, as LC.ResistanceFundSuccess shares it.
function LC.ResistanceFundShares(kind, n)
    n = math.max(0, math.floor(tonumber(n) or 0))
    local takes = {}
    if TAKE[kind] then
        takes[1] = TAKE[kind]
    elseif kind == "saved" then
        for k = SAVED[1], SAVED[2] do takes[#takes + 1] = 2 * k end
    end
    local keptLo, keptHi, eachLo, eachHi
    for _, take in ipairs(takes) do
        local shared = math.floor(take * (1 - SPLIT))
        local each = n > 0 and math.floor(shared / n) or 0
        local kept = n > 0 and (take - each * n) or (take - shared)
        keptLo, keptHi = math.min(keptLo or kept, kept), math.max(keptHi or kept, kept)
        eachLo, eachHi = math.min(eachLo or each, each), math.max(eachHi or each, each)
    end
    return keptLo or 0, keptHi or 0, eachLo or 0, eachHi or 0
end
