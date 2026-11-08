--[[
    Living City: the City Administrator's office, and idle players (the owner, 1 November)

    Who: anyone with lc_admin_hours (8) played on the server in all, elected. Run for the post (C >
    Me > Run for City Administrator, or /run) while nobody holds it: a city vote opens for
    lc_admin_vote_minutes (2), every player votes on screen, and the winner is the Administrator
    (staff can still whitelist someone as before). Hours count only while you're not idle.

    The office (the Administrator's tablet, weapon_lc_admin; right click opens it), each with a cooldown:
      Call a city event     a curfew, a ration day, an inspection sweep, or a Combine parade (10 min apart)
      Rations               generous (full packets for everyone) or austere (short ones) for an hour
      Commissary prices     up or down by up to 25% for an hour
      A Union job bonus     one job pays half again for an hour
      Commend / censure     up to 25 Civil Standing, given or taken, 5 a day, announced
      Pardon                one wanted citizen's record cleared, once an hour (never a unit killer's)
      Housing               a free apartment for a week (no rent)
      Permits               a curfew permit, 3 a day
    The bodyguard: two Overwatch Elites always with the Administrator, twice the health and twice the
    damage. Left click with the tablet at someone: "kill them", at once. Anyone who hurts the
    Administrator is theirs too.

    Idle: no input for lc_afk_minutes (20) and you're AFK (shown to everyone; no pay or XP for the time),
    and at lc_afk_kick_minutes (20) you're kicked (staff never). (The owner, 2 November: 20 for both, so a
    short break never counts as away when an ending is waiting on the Administrator.)

      lc_admin_hours (8), lc_admin_vote_minutes (2), lc_admin_guards (2), lc_afk_minutes (20), lc_afk_kick_minutes (20)
]]

if CLIENT then return end

LC = LC or {}
LC.SlashCommands = LC.SlashCommands or {}

local FLAGS = bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED)
local cvHours   = CreateConVar("lc_admin_hours", "8", FLAGS, "Hours played on the server, in all, before someone can run for City Administrator")
local cvVote    = CreateConVar("lc_admin_vote_minutes", "2", FLAGS, "Minutes a City Administrator election stays open")
local cvGuards  = CreateConVar("lc_admin_guards", "2", FLAGS, "Overwatch Elites guarding the City Administrator")
local cvAfk     = CreateConVar("lc_afk_minutes", "20", FLAGS, "Minutes without input before a player is AFK")
local cvAfkKick = CreateConVar("lc_afk_kick_minutes", "20", FLAGS, "Minutes without input before a player is kicked (0: never; staff never)")

util.AddNetworkString("lc_election")
util.AddNetworkString("lc_election_vote")
util.AddNetworkString("lc_admin_office")
util.AddNetworkString("lc_admin_do")

local function Say(ply, t) if IsValid(ply) then ply:ChatPrint(t) end end
local function Name(p) return LC.CharacterName and LC.CharacterName(p) or p:Nick() end
local function IsAdministrator(p) return IsValid(p) and p:IsPlayer() and p:GetNW2String("lcf_faction", "") == "admin" end
LC.IsCityAdministrator = IsAdministrator

------------------------------------------------------------------------
-- Idle, and hours played
------------------------------------------------------------------------

hook.Add("StartCommand", "LivingCityAFK", function(ply, cmd)
    if not cmd.GetButtons then return end
    if cmd:GetButtons() ~= 0 or (cmd.GetMouseX and (cmd:GetMouseX() ~= 0 or cmd:GetMouseY() ~= 0)) then
        ply.lcLastInput = CurTime()
        if ply.lcAfk then ply.lcAfk = false ply:SetNW2Bool("lc_afk", false) end
    end
end)
function LC.IsAFK(ply) return IsValid(ply) and ply.lcAfk == true end

function LC.PlayedHours(ply)
    return (tonumber(ply:GetPData("lc_played_min", "0")) or 0) / 60
end

-- The Administration path (the owner, 2 November): each Records Clerk shift counts towards the hours
-- needed to run for City Administrator, on top of the time played.
local cvClerkMin = CreateConVar("lc_admin_clerk_minutes", "20", FLAGS, "Minutes each Records Clerk shift counts for, towards the hours needed to run for City Administrator")
function LC.AdminHours(ply)
    local shifts = LC.Counter and LC.Counter(ply, "clerk_shifts") or 0
    return LC.PlayedHours(ply) + shifts * math.max(0, cvClerkMin:GetFloat()) / 60, shifts
end

timer.Create("LivingCityAFK", 30, 0, function()
    local now = CurTime()
    for _, ply in ipairs(player.GetAll()) do
        ply.lcLastInput = ply.lcLastInput or now
        local idle = now - ply.lcLastInput
        if not ply.lcAfk and idle > math.max(1, cvAfk:GetFloat()) * 60 then
            ply.lcAfk = true
            ply:SetNW2Bool("lc_afk", true)
        end
        local kick = cvAfkKick:GetFloat()
        if kick > 0 and idle > kick * 60 and not ply:IsAdmin() and not (ply.IsBot and ply:IsBot()) then
            ply:Kick("Idle for " .. math.floor(kick) .. " minutes")
        end
    end
end)
timer.Create("LivingCityPlayedMinutes", 60, 0, function()
    for _, ply in ipairs(player.GetAll()) do
        if not ply.lcAfk then ply:SetPData("lc_played_min", (tonumber(ply:GetPData("lc_played_min", "0")) or 0) + 1) end
    end
end)

------------------------------------------------------------------------
-- The election
------------------------------------------------------------------------

LC.Election = LC.Election or nil -- { candidates = {ply,...}, votes = {[voter] = cand}, ends }

local function OfficeHeld()
    for _, p in ipairs(player.GetAll()) do if IsAdministrator(p) then return p end end
    return nil
end

-- Who votes for (and recalls) the City Administrator (the owner, 2 November): Civil Protection (the
-- Overwatch included) and the Administration. Not citizens, the Resistance, vortigaunts, stalkers or
-- the infested; by faction, so a rebel in a stolen uniform doesn't get a vote either.
local VOTERS = { cp = true, admin = true }
local function Voter(p) return IsValid(p) and p:IsPlayer() and VOTERS[p:GetNW2String("lcf_faction", "")] == true end
LC.AdminVoter = Voter
local function Voters() local out = {} for _, p in ipairs(player.GetAll()) do if Voter(p) then out[#out + 1] = p end end return out end

local function Broadcast()
    local e = LC.Election
    if not e then return end
    local names = {}
    for i, c in ipairs(e.candidates) do if IsValid(c) then names[#names + 1] = { i = i, name = Name(c) } end end
    net.Start("lc_election")
    net.WriteFloat(e.ends - CurTime())
    net.WriteUInt(#names, 6)
    for _, n in ipairs(names) do net.WriteUInt(n.i, 6) net.WriteString(n.name) end
    net.Send(Voters())
end

function LC.StandForAdministrator(ply)
    if not IsValid(ply) then return false end
    if OfficeHeld() then return false, "There's an Administrator already: " .. Name(OfficeHeld()) .. "." end
    local need = cvHours:GetFloat()
    local have, shifts = LC.AdminHours(ply)
    if have < need and not ply:IsSuperAdmin() then
        return false, string.format("The city elects only those it knows: %d hours played. You have %.1f (each Records Clerk shift counts as %d minutes; you've done %d).",
            need, have, math.floor(cvClerkMin:GetFloat()), shifts)
    end
    local e = LC.Election
    if not e then
        e = { candidates = {}, votes = {}, ends = CurTime() + math.max(0.5, cvVote:GetFloat()) * 60 }
        LC.Election = e
        for _, p in ipairs(player.GetAll()) do
            if LC.Notice then LC.Notice(p, "event", "An election", "The office of City Administrator is open, and " .. Name(ply) .. " is running. " ..
                (Voter(p) and "Vote on screen." or "Civil Protection and the Administration choose."), 10) end
        end
    end
    if table.HasValue(e.candidates, ply) then return false, "You're already running." end
    e.candidates[#e.candidates + 1] = ply
    Broadcast()
    return true
end
LC.SlashCommands.run = function(ply) local ok, why = LC.StandForAdministrator(ply) if not ok and why then Say(ply, why) end end
if LC.MenuActions then LC.MenuActions.run = true end

net.Receive("lc_election_vote", function(_, ply)
    local e = LC.Election
    local i = net.ReadUInt(6)
    if not e or not IsValid(e.candidates[i]) or not Voter(ply) then return end
    e.votes[ply] = e.candidates[i]
    Say(ply, "[Election] Your vote is cast.")
end)

function LC.ElectionTick(now)
    local e = LC.Election
    if not e or now < e.ends then return end
    LC.Election = nil
    local tally = {}
    for _, c in pairs(e.votes) do if IsValid(c) then tally[c] = (tally[c] or 0) + 1 end end
    local best, bn = nil, -1
    for _, c in ipairs(e.candidates) do
        if IsValid(c) and (tally[c] or 0) > bn then best, bn = c, tally[c] or 0 end
    end
    if not IsValid(best) then return end
    best:SetPData("lcf_wl_admin", "1")
    for _, p in ipairs(player.GetAll()) do
        if LC.Notice then LC.Notice(p, "event", "The city has chosen", Name(best) .. " is City Administrator (" .. bn .. " vote" .. (bn == 1 and "" or "s") .. ").", 10) end
    end
    if LC.SetFaction then LC.SetFaction(best, "admin", nil, true) end
    hook.Run("LivingCityAdministratorChosen", best, "elected")
end
timer.Create("LivingCityElection", 2, 0, function() pcall(LC.ElectionTick, CurTime()) end)

------------------------------------------------------------------------
-- The recall (the owner, 2 November): someone the G-Man has chosen (sv_livingcity_directives.lua,
-- lc_gman_rival_until) can put the sitting Administrator to a vote of Civil Protection and the
-- Administration. More yes than no, and the Administrator is out and they're in.
------------------------------------------------------------------------

util.AddNetworkString("lc_recall")
util.AddNetworkString("lc_recall_vote")
function LC.CallRecall(ply)
    if not IsValid(ply) then return false end
    if ply:GetNW2Float("lc_gman_rival_until", 0) < CurTime() then return false, "Only someone the city has chosen can call a recall." end
    local sitting = OfficeHeld()
    if not IsValid(sitting) or sitting == ply then return false, "There's no Administrator to recall." end
    if LC.Recall or LC.Election then return false, "A vote is already under way." end
    local r = { rival = ply, sitting = sitting, votes = {}, ends = CurTime() + math.max(0.5, cvVote:GetFloat()) * 60 }
    LC.Recall = r
    ply:SetNW2Float("lc_gman_rival_until", 0)
    for _, p in ipairs(player.GetAll()) do
        if LC.Notice then LC.Notice(p, "event", "A recall", Name(ply) .. " calls for " .. Name(sitting) .. " to be removed as City Administrator. " ..
            (Voter(p) and "Vote on screen." or "Civil Protection and the Administration decide."), 10) end
    end
    net.Start("lc_recall")
    net.WriteFloat(r.ends - CurTime())
    net.WriteString(Name(sitting))
    net.WriteString(Name(ply))
    net.Send(Voters())
    return true
end
LC.SlashCommands.recall = function(ply) local ok, why = LC.CallRecall(ply) if not ok and why then Say(ply, why) end end
if LC.MenuActions then LC.MenuActions.recall = true end
net.Receive("lc_recall_vote", function(_, ply)
    local r = LC.Recall
    if not r or not Voter(ply) then return end
    r.votes[ply] = net.ReadBool()
    Say(ply, "[Recall] Your vote is cast.")
end)
function LC.RecallTick(now)
    local r = LC.Recall
    if not r or now < r.ends then return end
    LC.Recall = nil
    local yes, no = 0, 0
    for _, v in pairs(r.votes) do if v then yes = yes + 1 else no = no + 1 end end
    if yes > no and IsValid(r.rival) and IsValid(r.sitting) then
        r.sitting:SetPData("lcf_wl_admin", "0")
        if LC.SetFaction then LC.SetFaction(r.sitting, "citizen", nil, true) end
        r.rival:SetPData("lcf_wl_admin", "1")
        if LC.SetFaction then LC.SetFaction(r.rival, "admin", nil, true) end
        for _, p in ipairs(player.GetAll()) do
            if LC.Notice then LC.Notice(p, "event", "Recalled", Name(r.rival) .. " replaces " .. Name(r.sitting) .. " as City Administrator (" .. yes .. " to " .. no .. ").", 10) end
        end
        hook.Run("LivingCityAdministratorChosen", r.rival, "recall")
    else
        for _, p in ipairs(player.GetAll()) do
            if LC.Notice then LC.Notice(p, "event", "The recall fails", (IsValid(r.sitting) and Name(r.sitting) or "The Administrator") .. " keeps the office (" .. yes .. " to " .. no .. ").", 10) end
        end
    end
    return yes > no
end
timer.Create("LivingCityRecall", 2, 0, function() pcall(LC.RecallTick, CurTime()) end)

------------------------------------------------------------------------
-- The office
------------------------------------------------------------------------

LC.AdminState = LC.AdminState or { rations = nil, rationsUntil = 0, priceMul = 1, priceUntil = 0, bonusJob = nil, bonusUntil = 0 }
local A = LC.AdminState

-- the city's dials, read by the economy, rations and work (wrapped around the loyalty rewards' own)
local basePay, basePrice, baseRation = LC.LoyalPayMul, LC.LoyalPriceMul, LC.RationFor
LC.LoyalPayMul = function(p)
    local m = basePay and basePay(p) or 1
    local job = IsValid(p) and LC.Job and LC.Job(p)
    if A.bonusJob and CurTime() < A.bonusUntil and job and job.id == A.bonusJob then m = m * 1.5 end
    return m
end
LC.LoyalPriceMul = function(p)
    local m = basePrice and basePrice(p) or 1
    if CurTime() < A.priceUntil then m = m * A.priceMul end
    return m
end
if baseRation then
    LC.RationFor = function(p)
        if CurTime() < A.rationsUntil then
            if A.rations == "generous" then return "ration" end
            if A.rations == "austere" then return "ration_short" end
        end
        return baseRation(p)
    end
end

local function Cool(ply, key, secs)
    ply.lcAdminNext = ply.lcAdminNext or {}
    local at = ply.lcAdminNext[key] or 0
    if CurTime() < at then return false, string.format("Not yet: %d more minute%s.", math.ceil((at - CurTime()) / 60), math.ceil((at - CurTime()) / 60) == 1 and "" or "s") end
    ply.lcAdminNext[key] = CurTime() + secs
    return true
end
local function Daily(ply, key, max)
    local day = os.date("%Y%m%d")
    ply.lcAdminDaily = ply.lcAdminDaily or {}
    local d = ply.lcAdminDaily[key]
    if not d or d.day ~= day then d = { day = day, n = 0 } ply.lcAdminDaily[key] = d end
    if d.n >= max then return false, "That's all of those for today." end
    d.n = d.n + 1
    return true
end
local function Announce(text)
    for _, p in ipairs(player.GetAll()) do if LC.Notice then LC.Notice(p, "event", "The City Administrator", text, 9) end end
end

local EVENTS = { curfew = "a curfew", rations = "a ration day", sweep = "an inspection sweep", parade = "a Combine parade" }

-- One of the office's acts. arg: the event, "generous"/"austere", a price factor, a job id, or a target player.
function LC.AdminDo(ply, what, arg, target)
    if not IsAdministrator(ply) then return false, "Only the City Administrator." end
    if what == "dream" then -- (tonight's dream: sv_livingcity_dreams.lua)
        if not LC.DreamAdminPick then return false end
        return LC.DreamAdminPick(ply, arg)
    end
    if what == "dreamstar" then -- (star in propaganda dreams herself: sv_livingcity_propagandadreams.lua)
        if not LC.DreamStarSet then return false end
        return LC.DreamStarSet(ply, arg == "on")
    end
    if what == "event" then
        if not EVENTS[arg] then return false end
        local ok, why = Cool(ply, "event", 600)
        if not ok then return false, why end
        if not (LC.StartEvent and LC.StartEvent(arg)) then ply.lcAdminNext.event = 0 return false, "That can't happen right now (or the map has nowhere for it)." end
        Announce("By order of the City Administrator: " .. EVENTS[arg] .. ".")
        return true
    elseif what == "rations" then
        if arg ~= "generous" and arg ~= "austere" and arg ~= "normal" then return false end
        local ok, why = Cool(ply, "rations", 900)
        if not ok then return false, why end
        A.rations, A.rationsUntil = arg, (arg == "normal" and 0 or CurTime() + 3600)
        Announce(arg == "generous" and "Rations are increased for the hour. The Union provides." or (arg == "austere" and "Rations are reduced for the hour. Sacrifice strengthens us." or "Rations are as usual."))
        return true
    elseif what == "prices" then
        local f = math.Clamp(tonumber(arg) or 1, 0.75, 1.25)
        local ok, why = Cool(ply, "prices", 900)
        if not ok then return false, why end
        A.priceMul, A.priceUntil = f, CurTime() + 3600
        Announce(string.format("Commissary prices are %s for the hour (%d%%).", f < 1 and "lowered" or (f > 1 and "raised" or "as usual"), math.floor(f * 100 + 0.5)))
        return true
    elseif what == "bonus" then
        local job = LCJ and LCJ.ById and LCJ.ById[arg]
        if not job then return false end
        local ok, why = Cool(ply, "bonus", 900)
        if not ok then return false, why end
        A.bonusJob, A.bonusUntil = job.id, CurTime() + 3600
        Announce("For the hour, " .. job.name .. " shifts pay half again. The city needs hands there.")
        return true
    end
    -- the rest are about a person
    if not IsValid(target) or not target:IsPlayer() or target == ply then return false, "Look at someone, or pick them." end
    if what == "commend" or what == "censure" then
        local ok, why = Daily(ply, "standing", 5)
        if not ok then return false, why end
        local n = math.Clamp(math.floor(tonumber(arg) or 15), 1, 25)
        if LC.AddStanding then LC.AddStanding(target, what == "commend" and n or -n, what == "commend" and "Commended by the Administrator" or "Censured by the Administrator") end
        Announce(Name(target) .. (what == "commend" and " is commended for their service to the city." or " is censured. Let them remember it."))
        return true
    elseif what == "pardon" then
        if not (LC.PlayerIsWanted and LC.PlayerIsWanted(target)) then return false, "They aren't wanted." end
        local rec = string.lower(tostring(target:GetNW2String("lc_wanted_why", "")))
        if string.find(rec, "murder", 1, true) or string.find(rec, "killing", 1, true) or string.find(rec, "officer", 1, true) then
            return false, "Not for that. Not even the Administrator."
        end
        local ok, why = Cool(ply, "pardon", 3600)
        if not ok then return false, why end
        if LC.ClearWanted then LC.ClearWanted(target) end
        Announce(Name(target) .. " is pardoned. The city is merciful.")
        return true
    elseif what == "housing" then
        local ok, why = Daily(ply, "housing", 3)
        if not ok then return false, why end
        target:SetPData("lc_rent_free_until", os.time() + 7 * 86400)
        Say(target, "[City] The Administrator grants you a week's rent-free housing.")
        return true
    elseif what == "permit" then
        local ok, why = Daily(ply, "permit", 3)
        if not ok then return false, why end
        if LC.GiveOrDrop then LC.GiveOrDrop(target, "permit", 1) end
        Say(target, "[City] The Administrator issues you a curfew permit.")
        return true
    end
    return false
end

-- a week's free housing (the office): read by the rent
local baseRent = LC.RentPrice
if baseRent then
    LC.RentPrice = function(ply, ...)
        if IsValid(ply) and (tonumber(ply:GetPData("lc_rent_free_until", "0")) or 0) > os.time() then return 0, "rent-free, by the Administrator's grant" end
        return baseRent(ply, ...)
    end
end

net.Receive("lc_admin_do", function(_, ply)
    local what, arg, target = net.ReadString(), net.ReadString(), net.ReadEntity()
    local ok, why = LC.AdminDo(ply, what, arg, target)
    Say(ply, ok and "[Office] Done." or ("[Office] " .. (why or "No.")))
end)

function LC.OpenAdminOffice(ply)
    if not IsAdministrator(ply) then return end
    local jobs = {}
    for _, o in ipairs(LCJ and LCJ.Occupations or {}) do if not LCJ.Closed(o) then jobs[#jobs + 1] = { id = o.id, name = o.name } end end
    local people = {}
    for _, p in ipairs(player.GetAll()) do if p ~= ply then people[#people + 1] = { idx = p:EntIndex(), name = Name(p), wanted = LC.PlayerIsWanted and LC.PlayerIsWanted(p) or false } end end
    LC.SendCompressed("lc_admin_office", { jobs = jobs, people = people, dream = LC.DreamOffice and LC.DreamOffice() or nil,
        dreamStar = LC.DreamStarWants and (LC.DreamStarWants(ply) and "on" or "off") or nil }, { ply })
end

------------------------------------------------------------------------
-- The bodyguard
------------------------------------------------------------------------

LC.AdminGuards = LC.AdminGuards or {} -- [npc] = administrator

local function SpawnGuard(admin)
    local p = admin:GetPos() - admin:GetForward() * 120
    p = LC.GroundAt and LC.GroundAt(p + Vector(0, 0, 40)) or p
    if not LC.SpawnSoldier then return nil end
    local npc, st = LC.ManpowerFree(LC.SpawnSoldier, p + Vector(0, 0, 4)) -- (the Administrator's guard: never from Overwatch's reserve)
    if not IsValid(npc) or not st then return nil end
    if not util.IsValidModel or util.IsValidModel("models/combine_super_soldier.mdl") then npc:SetModel("models/combine_super_soldier.mdl") end
    if npc.Give then npc:Give("weapon_ar2") end
    local hp = npc:Health() * 2
    if npc.SetMaxHealth then npc:SetMaxHealth(hp) end
    npc:SetHealth(hp)
    st.unmanaged, st.questLock, st.adminGuard = true, true, admin
    LC.SetState(npc, st, "adminguard")
    npc:SetNW2String("lc_doing", "guarding the City Administrator")
    LC.AdminGuards[npc] = admin
    return npc
end

-- "Kill them": every guard on it, at once.
function LC.AdminOrderKill(admin, target)
    if not IsAdministrator(admin) or not IsValid(target) or target == admin then return false end
    if not (target:IsPlayer() or target:IsNPC()) then return false end
    local n = 0
    for npc, who in pairs(LC.AdminGuards) do
        if who == admin and IsValid(npc) then
            local st = LC.NPCs[npc]
            if st then st.adminTarget = target end
            if npc.AddEntityRelationship then npc:AddEntityRelationship(target, D_HT, 99) end
            if npc.SetEnemy then npc:SetEnemy(target) end
            if npc.UpdateEnemyMemory then npc:UpdateEnemyMemory(target, target:GetPos()) end
            if npc.SetSchedule then npc:SetSchedule(SCHED_RANGE_ATTACK1) end
            n = n + 1
        end
    end
    if n > 0 then
        admin:EmitSound("npc/combine_soldier/vo/affirmative.wav", 70)
        if target:IsPlayer() and LC.ReportCrime then LC.ReportCrime(target, "Threat to the City Administrator", 300) end
    end
    return n > 0
end

local function GuardTick(now)
    -- the dead and the dismissed
    for npc, admin in pairs(LC.AdminGuards) do
        if not IsValid(npc) or npc:Health() <= 0 or not IsAdministrator(admin) then
            if IsValid(npc) and not IsAdministrator(admin) then npc:Remove() end
            LC.AdminGuards[npc] = nil
        end
    end
    for _, admin in ipairs(player.GetAll()) do
        if IsAdministrator(admin) and admin:Alive() then
            local mine = {}
            for npc, who in pairs(LC.AdminGuards) do if who == admin then mine[#mine + 1] = npc end end
            if #mine < cvGuards:GetInt() and now >= (admin.lcGuardNext or 0) then
                admin.lcGuardNext = now + 30
                SpawnGuard(admin)
            end
            for i, npc in ipairs(mine) do
                local st = LC.NPCs[npc]
                local t = st and st.adminTarget
                if IsValid(t) and ((t:IsPlayer() and t:Alive()) or (t:IsNPC() and t:Health() > 0)) then
                    if npc.SetEnemy then npc:SetEnemy(t) end
                    if npc.UpdateEnemyMemory then npc:UpdateEnemyMemory(t, t:GetPos()) end
                else
                    if st then st.adminTarget = nil end
                    local d = npc:GetPos():DistToSqr(admin:GetPos())
                    -- stuck (a door, a corner: the owner, 2 November): not moving for 4 seconds while
                    -- more than 250 units behind, and they're brought to the Administrator's side
                    local moved = not npc.lcGuardLast or npc:GetPos():DistToSqr(npc.lcGuardLast) > 20 * 20
                    if moved or d < 250 * 250 then npc.lcGuardLast, npc.lcGuardStill = npc:GetPos(), now end
                    local stuck = d > 250 * 250 and now - (npc.lcGuardStill or now) > 4
                    if stuck then npc.lcGuardStill = now end
                    if d > 900 * 900 or stuck then
                        npc:SetPos(admin:GetPos() - admin:GetForward() * 90 + admin:GetRight() * (i % 2 == 0 and 50 or -50) + Vector(0, 0, 4))
                    elseif d > 160 * 160 and npc.SetLastPosition and npc.SetSchedule then
                        npc:SetLastPosition(admin:GetPos() - admin:GetForward() * 70 + admin:GetRight() * (i % 2 == 0 and 50 or -50))
                        npc:SetSchedule(d > 450 * 450 and SCHED_FORCED_GO_RUN or SCHED_FORCED_GO)
                    end
                end
            end
        end
    end
end
LC.AdminGuardTick = GuardTick
timer.Create("LivingCityAdminGuards", 0.5, 0, function()
    if not LC.Running then return end
    local ok, err = pcall(GuardTick, CurTime())
    if not ok and LC.Error then LC.Error("admin guards", err) end
end)

-- twice the damage they do; anyone who hurts the Administrator is theirs
hook.Add("EntityTakeDamage", "LivingCityAdminGuards", function(victim, dmg)
    local att = dmg:GetAttacker()
    if IsValid(att) and LC.AdminGuards[att] then dmg:ScaleDamage(2) end
    if IsAdministrator(victim) and IsValid(att) and att ~= victim and (att:IsPlayer() or att:IsNPC()) and not LC.AdminGuards[att] then
        LC.AdminOrderKill(victim, att)
    end
end)
