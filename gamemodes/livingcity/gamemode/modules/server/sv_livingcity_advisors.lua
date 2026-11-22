--[[
    Living City (server): the Advisor screens (the owner, 22 November, approving the ideas of 21 November)

    The Advisors are only ever a face on a screen (Valve's d3_citadel and ep1_citadel). The Administrator
    deals with them at an Advisor screen (the editor's "Fixture: Advisor screen", entities/lc_advisorscreen.lua)
    or on her F2 > City orders > The Advisors: a player whose faction is "admin"; with nobody playing her,
    the city's own Administrator does it by itself. They speak only through their screens: until one is
    placed on the map, nothing here happens.

    Their patience
        One hidden figure (0 to 100, kept with the state of the city: sv_livingcity_ledger.lua), never shown
        as a number: her menu's title says it in words, "The Advisors are patient / growing impatient / out
        of patience". It comes back slowly (30 a city day).
    Asking them (each uses some up; asked while the city is calm, half as much again)
        Overwatch troops   an Overwatch drop (LC.StartOverwatchDrop, sv_livingcity_resistanceops.lua)  30
        A supply drop      LC.StartSupplyDrop (sv_livingcity_convoy.lua)                               20
        More units         Civil Protection 3 more on the streets for 20 minutes, with 3 more in its
                           reserve (sv_livingcity_manpower.lua)                                         20
        Asked again within 15 minutes, or while they are out of patience: refused, and that costs 5.
    Reporting in
        Every third night the Advisors call for her report, due by the next nightfall. She tells them the
        truth about the unrest (pleasing while the city is calm, costly while it is not), or lies (claims
        it calmer). A lie pleases them now; every night until the next call it may be found out (a fifth of
        a chance for each step it hid), and that costs more than the truth would have. The city's own
        reports by itself: honestly, or a step calmer when the city is in real unrest and her hold is weak.
    A missed report, or their patience run out
        First, the city's rations are cut for half a city day (citizens get short packets, and longer between
        them). Again before their patience has come back: an Overwatch officer (an Elite) stands watch near
        her office for 20 minutes. Again: a player Administrator is removed from the post (a citizen again);
        the city's own is replaced (with a new name, if she has one). Then it starts over.

      lc_advisors 1/0
]]

if CLIENT then return end

LC = LC or {}

local FLAGS = bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED)
local cvOn = CreateConVar("lc_advisors", "1", FLAGS, "The Advisors: at an Advisor screen the Administrator asks them for troops, supplies or units, and reports to them every third night")

util.AddNetworkString("lc_advisors_open")
util.AddNetworkString("lc_advisors_do")

local START, PATIENT, IMPATIENT = 70, 60, 20 -- (the figure they start at, and where the words change)
local REFILL_PER_DAY = 30
local COST = { troops = 30, supply = 20, cops = 20 }
local CALM_MUL = 1.5
local ASK_GAP = 15 * 60
local PESTER = 5
local REPORT_EVERY = 3
local TRUTH = { [0] = 12, [1] = 6, [2] = -2, [3] = -8 } -- (what a report saying the city is this calm does to their patience)
local FOUND_CHANCE = 0.2 -- (a night's chance of a lie coming out, for each step it hid)
local FOUND_COST, FOUND_STEP = 10, 10
local MISSED_COST = 20
local AFTER_STRIKE = 5
local COPS_N, COPS_SECS = 3, 20 * 60
local WATCH_SECS = 20 * 60
local CITY_ASK_GAP = 30 * 60
local NAMES = { "Kessel", "Moravec", "Lindqvist", "Arendt", "Halloran", "Sorel", "Brandt", "Varga", "Ilves", "Okafor" }
local CV = "npc/overwatch/cityvoice/"
local VOICE = "ambient/levels/citadel/strange_talk" -- (the Citadel's voices: the Advisor, speaking)
local DEFAULT_NAME = "The Administrator"

-- What lives only while the server runs.
local A = LC.AdvisorsLive or { cutUntil = 0, copsUntil = 0, watchUntil = 0, lastAsk = -1e9, cityAsk = 0 }
LC.AdvisorsLive = A
LC.AdvisorCops = LC.AdvisorCops or 0

local function On() return cvOn:GetBool() end
local function DayLen() local c = GetConVar("lc_day_minutes") return math.max(5, c and c:GetFloat() or 60) * 60 end

-- The figure and the nights, with the state of the city.
local function S()
    local l = LC.Ledger and LC.Ledger()
    if not istable(l) then A.mem = A.mem or {} l = A.mem end
    local s = l.advisors
    if not istable(s) then s = {} l.advisors = s end
    s.patience = tonumber(s.patience) or START
    s.nights = tonumber(s.nights) or 0
    s.strikes = tonumber(s.strikes) or 0
    return s
end
LC.AdvisorState = S

local function Save() if LC.LedgerSave then LC.Try(LC.LedgerSave) end end

-- Their screens: with none on the map there are no Advisors.
local function Screens() return (LC.EntsOf and LC.EntsOf("lc_advisorscreen")) or ents.FindByClass("lc_advisorscreen") end
function LC.AdvisorsHere()
    if not On() then return false end
    for _, e in ipairs(Screens()) do if IsValid(e) then return true end end
    return false
end
-- (her last stand and the endings have their own story: the Advisors wait)
local function Quiet() return (LC.CollapseActive and LC.CollapseActive()) or (LC.EndingBusy and LC.EndingBusy()) or false end

local function IsAdmin(p) return IsValid(p) and p:IsPlayer() and p:GetNW2String("lcf_faction", "") == "admin" end
local function PlayerAdmins()
    local t = {}
    for _, p in ipairs(player.GetAll()) do if IsAdmin(p) then t[#t + 1] = p end end
    return t
end

-- The one line the Advisors say to her (who: a list of players), with their voice.
local function Tell(who, text)
    for _, p in ipairs(who or {}) do
        if IsValid(p) and LC.Notice then
            p:EmitSound(VOICE .. math.random(1, 6) .. ".wav", 55, 85)
            LC.Notice(p, "speech", "The Advisors", text, 6)
        end
    end
end

-- The city hears it over the PA.
local function Announce(clip, text)
    if LC.Announce then LC.Try(LC.Announce, "advisors", CV .. clip, text) end
end

------------------------------------------------------------------------
-- Their patience
------------------------------------------------------------------------

function LC.AdvisorWord(p)
    p = p or S().patience
    if p >= PATIENT then return "patient" end
    if p >= IMPATIENT then return "impatient" end
    return "out"
end

-- How unsettled the city is, as they see it: 0 calm, 1 uneasy, 2 unrest, 3 revolt.
function LC.AdvisorUnrest()
    local socio = LC.Socio or "green"
    local lvl = (socio == "yellow" and 1) or (socio == "red" and 2) or (socio == "black" and 3) or 0
    if LC.CityState and LC.CityState() == "unrest" then lvl = lvl >= 2 and 3 or 2 end
    local book = LC.Ledger and LC.Ledger()
    local cv = GetConVar("lc_ledger")
    if istable(book) and cv and cv:GetBool() and (tonumber(book.morale) or 50) < 30 then lvl = math.max(lvl, 1) end
    return math.min(3, lvl)
end

local Strike

local function Gain(n)
    local s = S()
    s.patience = math.min(100, s.patience + n)
end

-- Used up; run out, and they act (true: they did).
local function Spend(n, why)
    local s = S()
    s.patience = math.max(0, s.patience - n)
    if s.patience > 0 then return false end
    s.patience = AFTER_STRIKE
    Strike(why)
    return true
end

local function Change(d, why) if d >= 0 then Gain(d) return false end return Spend(-d, why) end

local function Publish()
    if not LC.AdvisorsHere() then SetGlobal2String("lc_advisors", "") return end
    local s = S()
    local now = CurTime()
    SetGlobal2String("lc_advisors", util.TableToJSON({ w = LC.AdvisorWord(), due = s.due and true or nil, lvl = LC.AdvisorUnrest(),
        drop = LC.OverwatchDrop and true or nil, sup = LC.Supply and true or nil, cops = A.copsUntil > now or nil }) or "")
end
LC.AdvisorPublish = Publish

------------------------------------------------------------------------
-- What they do when it runs out
------------------------------------------------------------------------

function LC.AdvisorRationCut() return On() and A.cutUntil > CurTime() end

local function CutRations()
    A.cutUntil = CurTime() + DayLen() / 2
    Tell(PlayerAdmins(), "The Advisors have cut the city's rations.")
    Announce("f_rationunitsdeduct_3_spkr.wav", "By order of the Combine, rations are cut for now.")
end

-- Near her office: her desk or office door, else an Advisor screen, else her studio.
local function OfficeSpot()
    local pos, how
    if LC.CollapseOffice then pos, how = LC.CollapseOffice() end
    if pos and (how == "desk" or how == "door") then return pos end
    local scr = Screens()[1]
    if IsValid(scr) then return scr:GetPos() + scr:GetForward() * 80 end
    if pos and how == "studio" then return pos end
    return nil
end

local function SendOfficer()
    local at = OfficeSpot()
    local sp = LC.Spawners and LC.Spawners.soldier
    if not at or not sp then return false end
    local spot = LC.GroundAt and LC.GroundAt(at + Vector(0, 0, 30)) or at
    -- (from outside the city: never from Overwatch's reserve)
    local ok, npc, st = LC.Try(function() return (LC.ManpowerFree or function(f, ...) return f(...) end)(sp, spot + Vector(0, 0, 4), "elite") end)
    if not ok or not IsValid(npc) or not st then return false end
    st.unmanaged, st.questLock, st.advisorWatch = true, true, true
    st.holdPos = spot
    if LC.SetState then LC.SetState(npc, st, "advisorwatch") end
    if LC.SetNPCStr then LC.SetNPCStr(npc, "lc_doing", "watching the Administrator") end
    if IsValid(A.watch) then A.watch:Remove() end
    A.watch, A.watchUntil = npc, CurTime() + WATCH_SECS
    Tell(PlayerAdmins(), "The Advisors have sent an officer to watch you.")
    return true
end

local function BaseName()
    local cv = GetConVar("lc_administrator_name")
    local n = cv and string.Trim(cv:GetString() or "") or ""
    return n ~= "" and n or DEFAULT_NAME
end

local function Replace()
    local admins = PlayerAdmins()
    if #admins > 0 then
        for _, p in ipairs(admins) do
            Tell({ p }, "The Advisors have removed you from office.")
            -- (as she leaves the post anywhere else: sv_livingcity_collapse.lua)
            p:SetPData("lcf_wl_admin", "0")
            if LC.SetFaction then LC.SetFaction(p, "citizen", nil, true) end
        end
        Announce("f_citizenshiprevoked_6_spkr.wav", "By order of the Combine, the Administrator is relieved of her post.")
    else
        -- the city's own: someone else in her place, with a new name if she has one
        local s = S()
        local base, old = BaseName(), LC.AdministratorName and LC.AdministratorName() or BaseName()
        local new
        if base ~= DEFAULT_NAME then
            for _ = 1, 10 do
                new = "Administrator " .. NAMES[math.random(#NAMES)]
                if new ~= old then break end
            end
            s.newName, s.nameWas = new, base
        else
            s.newName, s.nameWas = nil, nil
        end
        Announce("f_citizenshiprevoked_6_spkr.wav", new and (old .. " is relieved of her post. " .. new .. " is the city's Administrator now.")
            or "By order of the Combine, the city has a new Administrator.")
    end
    hook.Run("LivingCityAdvisorReplaced", #admins > 0)
end

-- A missed report, or their patience run out: the next thing they do.
Strike = function(why)
    local s = S()
    s.strikes = s.strikes + 1
    local n = s.strikes
    if n == 1 then
        CutRations()
    elseif n == 2 then
        if not SendOfficer() then CutRations() end -- (nowhere near an office to stand: the rations again)
    else
        Replace()
        s.strikes, s.patience = 0, math.max(s.patience, 50)
    end
    hook.Run("LivingCityAdvisorStrike", n, why)
    Save()
    Publish()
end
LC.AdvisorStrike = function(why) return Strike(why) end

-- The city's own name, once she has been replaced (until the owner names her again).
if LC.AdministratorName and not LC.AdvisorNameWrapped then
    LC.AdvisorNameWrapped = true
    local base = LC.AdministratorName
    LC.AdministratorName = function(...)
        local cur = base(...)
        local l = LC.Ledger and LC.Ledger()
        local s = istable(l) and istable(l.advisors) and l.advisors or nil
        if s and s.newName and s.nameWas == cur then return s.newName end
        return cur
    end
end

-- The cut: short packets for citizens (never units), and longer between them.
if not LC.AdvisorRationsWrapped then
    LC.AdvisorRationsWrapped = true
    local baseFor, baseMul = LC.RationFor, LC.RationIntervalMul
    if baseFor then
        LC.RationFor = function(p, ...)
            if LC.AdvisorRationCut() and not (LC.PlayerIsCP and LC.PlayerIsCP(p)) then return "ration_short" end
            return baseFor(p, ...)
        end
    end
    LC.RationIntervalMul = function(...)
        return (baseMul and baseMul(...) or 1) * (LC.AdvisorRationCut() and 1.5 or 1)
    end
end

------------------------------------------------------------------------
-- Asking them
------------------------------------------------------------------------

local REQUESTS = {
    troops = function()
        if LC.OverwatchDrop then return false, "Overwatch soldiers are already here." end
        if not LC.StartOverwatchDrop then return false end
        local ok = LC.StartOverwatchDrop()
        if not ok then return false, "There is nowhere for a dropship to land." end
        return true
    end,
    supply = function()
        if LC.Supply then return false, "A supply drop is already on its way." end
        if not LC.StartSupplyDrop then return false end
        local ok = LC.StartSupplyDrop()
        if not ok then return false, "There is nowhere to put it." end
        return true
    end,
    cops = function()
        if A.copsUntil > CurTime() then return false, "They have sent units already." end
        A.copsUntil = CurTime() + COPS_SECS
        LC.AdvisorCops = COPS_N
        if LC.ManpowerOn and LC.ManpowerOn() and LC.ManpowerPool then
            local p = LC.ManpowerPool("cp")
            p.reserve = p.reserve + COPS_N
        end
        return true
    end,
}
local GRANTED = { troops = "The Advisors send soldiers.", supply = "The Advisors send supplies.", cops = "The Advisors send more units." }

-- ply: a player Administrator, or nil for the city's own.
function LC.AdvisorAsk(ply, what)
    if not LC.AdvisorsHere() or Quiet() or not REQUESTS[what] then return false end
    if ply ~= nil and not IsAdmin(ply) then return false end
    local tell = ply and { ply } or {}
    local now = CurTime()
    local out = LC.AdvisorWord() == "out"
    if out or now - A.lastAsk < ASK_GAP then
        -- (one line at a time: what they do when it runs out says it instead)
        if not Spend(PESTER, "pestered") then Tell(tell, out and "The Advisors refuse." or "The Advisors refuse. You ask too often.") end
        Save() Publish()
        return false, "refused"
    end
    local ok, why = REQUESTS[what]()
    if not ok then
        if why then Tell(tell, why) end
        return false, why
    end
    A.lastAsk = now
    if not Spend(COST[what] * (LC.AdvisorUnrest() == 0 and CALM_MUL or 1), what) then Tell(tell, GRANTED[what]) end
    hook.Run("LivingCityAdvisorAsked", what, ply)
    Save() Publish()
    return true
end

-- The city's own asks when the city needs it, and only while they are patient.
local function CityAsks(now)
    if now - A.cityAsk < CITY_ASK_GAP or now - A.lastAsk < ASK_GAP or S().patience < PATIENT then return end
    local lvl = LC.AdvisorUnrest()
    local stock = LC.StockLevel and LC.StockLevel() or "normal"
    local what
    if lvl >= 2 and not LC.OverwatchDrop then what = "troops"
    elseif (stock == "empty" or stock == "short") and not LC.Supply then what = "supply"
    elseif lvl >= 1 and A.copsUntil <= now then what = "cops" end
    if what then
        A.cityAsk = now
        LC.AdvisorAsk(nil, what)
    end
end

------------------------------------------------------------------------
-- Reporting in
------------------------------------------------------------------------

-- claim: how calm she says the city is (0 to 3); calmer than it is, a lie. ply nil: the city's own.
function LC.AdvisorReport(ply, claim)
    local s = S()
    if not LC.AdvisorsHere() or not s.due then return false end
    if ply ~= nil and not IsAdmin(ply) then return false end
    local lvl = LC.AdvisorUnrest()
    claim = math.Clamp(math.floor(tonumber(claim) or lvl), 0, lvl) -- (never worse than it is)
    s.due = nil
    s.lie = claim < lvl and { size = lvl - claim, night = s.nights, city = ply == nil or nil } or nil
    if not Change(TRUTH[claim] or 0, "report") and ply then Tell({ ply }, "The Advisors listen.") end
    hook.Run("LivingCityAdvisorReport", ply, lvl, claim)
    Save() Publish()
    return true
end

-- The city's own: honestly, or a step calmer when the city is in real unrest and her hold is weak.
function LC.AdvisorCityReport()
    local lvl = LC.AdvisorUnrest()
    local book = LC.Ledger and LC.Ledger()
    local weak = (istable(book) and (tonumber(book.authority) or 50) < 40) or S().patience < 40
    return LC.AdvisorReport(nil, (lvl >= 2 and weak) and (lvl - 1) or lvl)
end

local function Missed()
    local s = S()
    s.due = nil
    s.patience = math.max(AFTER_STRIKE, s.patience - MISSED_COST)
    Strike("missed")
end

-- Nightfall: the deadline for a report called the night before, a lie that may come out, and every third
-- night a new call.
function LC.AdvisorNight()
    if not LC.AdvisorsHere() or Quiet() then return end
    local s = S()
    s.nights = s.nights + 1
    if s.due then
        if #PlayerAdmins() > 0 then Missed() else LC.AdvisorCityReport() end
    end
    local lie = s.lie
    if lie and (tonumber(lie.night) or 0) < s.nights and math.random() < FOUND_CHANCE * (tonumber(lie.size) or 1) then
        s.lie = nil
        if not lie.city then Tell(PlayerAdmins(), "The Advisors know you lied.") end
        Spend(FOUND_COST + FOUND_STEP * (tonumber(lie.size) or 1), "lie")
    end
    if s.nights % REPORT_EVERY == 0 then
        s.lie = nil
        s.due = { night = s.nights }
        local her = PlayerAdmins()
        if #her > 0 then Tell(her, "The Advisors await your report.") else LC.AdvisorCityReport() end
    end
    Save()
    Publish()
end

hook.Add("LivingCityDayPhase", "LivingCityAdvisors", function(phase)
    if phase == "night" then LC.Try(LC.AdvisorNight) end
end)

------------------------------------------------------------------------
-- The screen, and her menu
------------------------------------------------------------------------

function LC.AdvisorScreenUse(ply, ent)
    if not LC.AdvisorsHere() or not IsValid(ply) or not ply:IsPlayer() then return false end
    if IsValid(ent) and ent:GetNW2Bool("lc_nopower", false) then return false end
    if not IsAdmin(ply) then
        if IsValid(ent) then ent:EmitSound("buttons/combine_button_locked.wav", 60) end
        return false
    end
    if IsValid(ent) and ply:GetPos():DistToSqr(ent:GetPos()) > 200 * 200 then return false end
    Publish()
    if IsValid(ent) then ent:EmitSound(VOICE .. math.random(1, 6) .. ".wav", 60, 85) end
    net.Start("lc_advisors_open")
    net.WriteEntity(ent)
    net.Send(ply)
    return true
end

net.Receive("lc_advisors_do", function(_, ply)
    local what = net.ReadString() or ""
    if not IsValid(ply) or (ply.lcAdvisorNext or 0) > CurTime() then return end
    ply.lcAdvisorNext = CurTime() + 1
    if not IsAdmin(ply) then return end
    local claim = string.match(what, "^report(%d)$")
    if claim then LC.AdvisorReport(ply, tonumber(claim)) else LC.AdvisorAsk(ply, what) end
end)

------------------------------------------------------------------------
-- The clock
------------------------------------------------------------------------

local lastTick
function LC.AdvisorTick(now)
    now = now or CurTime()
    local dt = lastTick and math.max(0, now - lastTick) or 0
    lastTick = now
    if A.copsUntil <= now then LC.AdvisorCops = 0 end
    if IsValid(A.watch) then
        if now >= A.watchUntil or not On() then
            A.watch:Remove()
            A.watch = nil
        else
            local st = LC.NPCs and LC.NPCs[A.watch]
            if st and st.holdPos and A.watch:GetPos():DistToSqr(st.holdPos) > 150 * 150 and LC.GoTo then LC.GoTo(A.watch, st, st.holdPos, false, nil) end
        end
    end
    if not LC.AdvisorsHere() then
        if not On() then A.cutUntil, A.copsUntil, LC.AdvisorCops = 0, 0, 0 end
        Publish()
        return
    end
    if not Quiet() then
        local s = S()
        s.patience = math.min(100, s.patience + REFILL_PER_DAY * dt / DayLen())
        if s.patience >= PATIENT and s.strikes > 0 then s.strikes = 0 end -- (their patience back: a fresh start)
        if #PlayerAdmins() == 0 then
            if s.due then LC.AdvisorCityReport() end
            CityAsks(now)
        end
    end
    Publish()
end

timer.Create("LivingCityAdvisors", 5, 0, function() LC.Try(LC.AdvisorTick) end)

-- (for the tests: a fresh start)
function LC.AdvisorReset()
    local l = LC.Ledger and LC.Ledger()
    if istable(l) then l.advisors = nil end
    A.mem = nil
    if IsValid(A.watch) then A.watch:Remove() end
    A.watch, A.cutUntil, A.copsUntil, A.watchUntil, A.lastAsk, A.cityAsk = nil, 0, 0, 0, -1e9, CurTime()
    LC.AdvisorCops = 0
    lastTick = nil
end
