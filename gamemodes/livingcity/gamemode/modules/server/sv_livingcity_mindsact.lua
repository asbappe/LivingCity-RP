--[[
    Living City: the city's minds, acting (the owner, 10 November: "Let's get
    the minds fully operational")

    sv_livingcity_minds.lua watches and writes down. This file turns what a
    mind comes to into something seen in the streets:

      their ordinary choices bend (LC.MindsBias, asked by ChooseCitizenTask in
      sv_livingcity.lua): the hungry to the ration line, the worn down to the
      benches and away from work, the timid home and away from units, the
      lonely into a chat

      a break happens for real (LC.MindsAct, called where the log's WOULD line
      is written; the log gets a DID line saying what was done):
        tantrum   walks up to a unit and screams at him; stopped, now and then taken in
        despair   sits down or goes home, and won't work or queue for a while
        defy      paints over a poster; becomes a Resistance sympathizer
        inform    becomes an informant; names a player they hold a grudge against to a unit
        seek      goes to find a friend
        hoard     back to the ration line for more than their share
        accuse    calls someone an informer, out loud; the word spreads
        sabotage  breaks a streetlight or a loudspeaker
        binge     drinks in the street for a good while
        brutal    (a unit) beats the nearest citizen
        drink     (a unit) drinks on duty: no stops from him for a while
        leak      (a unit) tells the Resistance who has been informing, or that patrols are thin
        share     gives food to their hungriest friend
        shelter   sides with the Resistance; Freq 7 hears they can be trusted
        steady    calms the people around them

      informants come from who people are (LC.MindsIsInformer, asked by
      LC.IsSnitch): the timid, loyal, greedy and cold of the roster, the same
      share as lc_snitch_chance; never a sympathizer

      the city's unrest reaches sociostability (LC.MindsUnrestHigh, asked by
      LC.SocioAuto): yellow, "the mood of the city", from lc_minds_unrest up

    lc_minds_act 0 puts the minds back to watching only. lc_minds 0 still turns
    the whole thing off.
]]

LC = LC or {}
local Psy = LC.Psy

local FLAGS = FCVAR_ARCHIVE
local cvAct = CreateConVar("lc_minds_act", "1", FLAGS, "The city's minds act: choices bend with mood, and a break happens in the street (0: they are only watched and written down)")
local cvUnrest = CreateConVar("lc_minds_unrest", "0.4", FLAGS, "Unrest among the city's minds (0 to 1) from which sociostability goes yellow (0: never)")

local NEAR = 140          -- this close, they have arrived
local ERRAND_SECS = 75    -- an errand not done by then is dropped
local HEAR = 600          -- players this near are told what happened
local LOW_SECS = 900      -- despair: this long without work or the queue
local REBEL_CAP = 0.4     -- sympathizers made by the minds stop at this share of the roster's citizens

LC.MindsActs = LC.MindsActs or { errands = {}, did = {} }
local A = LC.MindsActs

local function On() return Psy ~= nil and LC.MindsOn and LC.MindsOn() and cvAct:GetBool() end
LC.MindsActOn = On

local function Mind(npc)
    local p = IsValid(npc) and npc.lcProfile
    return p and LC.Minds and LC.Minds.byId[p.id] or nil
end

local function Body(m)
    local npc = m and m.p and m.p.npc
    if not IsValid(npc) or npc:Health() <= 0 then return nil end
    local st = LC.NPCs and LC.NPCs[npc]
    if not st or st.test then return nil end
    return npc, st
end

-- Free to be sent somewhere: standing about, walking, or in a queue.
local FREE = { idle = true, moving = true, inline = true }
local function Free(st)
    return FREE[st.state] and not st.questLock and not st.leaving and not st.snitchReport and not st.mindErrand
        and LC.Event ~= "curfew" and LC.Event ~= "lockdown"
end

local function Vo(st, name) return "vo/npc/" .. (st.gender or "male") .. "01/" .. name .. ".wav" end

-- What they say as it happens: a recorded line if there is one (sv_livingcity_lines.lua), heard by whoever is near.
local function Line(npc, st, id)
    if LC.LineSay and IsValid(npc) and st then LC.LineSay(npc, st, id) end
end

-- What players near see, as a line of the scene.
local function Scene(pos, text)
    for _, ply in ipairs(player.GetAll()) do
        if ply:GetPos():DistToSqr(pos) < HEAR * HEAR then ply:ChatPrint("** " .. text) end
    end
end

local function UnitName(npc)
    local p = IsValid(npc) and npc.lcProfile
    return p and p.name or "A unit"
end

local function NearestOf(pos, range, ok)
    local best, bst, bd
    for npc, st in pairs(LC.NPCs or {}) do
        if IsValid(npc) and npc:Health() > 0 and not st.test and ok(npc, st) then
            local d = npc:GetPos():DistToSqr(pos)
            if d < range * range and (not bd or d < bd) then best, bst, bd = npc, st, d end
        end
    end
    return best, bst
end

local function IsUnit(_, st) return st.role == "cop" and st.state ~= "hostile" end
local function IsCitizen(_, st) return st.role == "citizen" and (st.state == "idle" or st.state == "moving" or st.state == "inline") end

local function PlayerOf(key)
    for _, ply in ipairs(player.GetAll()) do
        if "pl:" .. ((LC.MemoryKey and LC.MemoryKey(ply)) or ply:SteamID()) == key then return ply end
    end
end

local function Worst(m, ok)
    local worst, wv
    for id, v in pairs(m.psy and m.psy.ties or {}) do
        if v < 0 and (not wv or v < wv) and (not ok or ok(id, v)) then worst, wv = id, v end
    end
    return worst, wv
end

local function Best(m, ok)
    local best, bv
    for id, v in pairs(m.psy and m.psy.ties or {}) do
        if v > 0 and (not bv or v > bv) and (not ok or ok(id, v)) then best, bv = id, v end
    end
    return best, bv
end

------------------------------------------------------------------------
-- Errands: walk to someone or something, then do it
------------------------------------------------------------------------
local function EndErrand(npc, st)
    A.errands[npc] = nil
    if not st then return end
    st.mindErrand, st.questLock = nil, nil
    if st.state == "event" or st.state == "moving" then
        st.eventUntil = 0
        LC.SetState(npc, st, "idle")
        st.untilT = CurTime() + 2
    end
end

-- target: an entity. fn(npc, st, target) runs on arrival.
local function Errand(npc, st, target, fn)
    local now = CurTime()
    if st.state == "inline" and LC.LeaveLine then LC.LeaveLine(npc, st) end
    st.mindErrand = { target = target, fn = fn, at = now, tries = 0 }
    LC.SetState(npc, st, "event")
    st.eventUntil, st.questLock = now + ERRAND_SECS + 15, true
    A.errands[npc] = st
    if LC.GoTo then LC.GoTo(npc, st, target:GetPos(), false) end
    return true
end

function LC.MindsErrandTick(now)
    now = now or CurTime()
    for npc, st in pairs(A.errands) do
        local e = st.mindErrand
        if not e or not IsValid(npc) or npc:Health() <= 0 or LC.NPCs[npc] ~= st or st.state == "hostile"
            or st.state == "jailed" or st.state == "detained" or st.state == "escorted" then
            A.errands[npc] = nil
            st.mindErrand = nil
            st.questLock = nil
        elseif not IsValid(e.target) then
            EndErrand(npc, st)
        else
            local pos = e.target:GetPos()
            if npc:GetPos():DistToSqr(pos) < NEAR * NEAR then
                EndErrand(npc, st)
                local ok, err = pcall(e.fn, npc, st, e.target)
                if not ok and LC.Error then LC.Error("minds (errand)", err) end
            elseif now - e.at > ERRAND_SECS then
                EndErrand(npc, st)
            elseif st.state ~= "moving" and now >= (e.next or 0) then
                e.next, e.tries = now + 3, e.tries + 1
                if not (LC.GoTo and LC.GoTo(npc, st, pos, false)) and e.tries > 4 then EndErrand(npc, st) end
            end
        end
    end
end

------------------------------------------------------------------------
-- Their ordinary choices, bent (ChooseCitizenTask: sv_livingcity.lua)
------------------------------------------------------------------------
function LC.MindsBias(npc, st, now)
    if not On() then return nil end
    local m = Mind(npc)
    if not m or not m.psy then return nil end
    local b = Psy.Bias(m)
    if not b then return nil end
    now = now or CurTime()
    if (st.mindLowUntil or 0) > now then
        b.work, b.line, b.sit = 0, b.line * 0.3, b.sit * 3
    end
    if b.chatty > 1 and st.nextChat then st.nextChat = math.min(st.nextChat, now + 5) end
    return b
end

-- Places to go, without the ones near a unit (for those keeping away from them).
function LC.MindsAwayFromUnits(spots)
    local units = {}
    for npc, st in pairs(LC.NPCs or {}) do
        if IsValid(npc) and (st.role == "cop" or st.role == "soldier") then units[#units + 1] = npc:GetPos() end
    end
    if #units == 0 then return spots end
    local out = {}
    for _, p in ipairs(spots) do
        local near = false
        for _, u in ipairs(units) do if u:DistToSqr(p.pos) < 600 * 600 then near = true break end end
        if not near then out[#out + 1] = p end
    end
    return #out > 0 and out or spots
end

------------------------------------------------------------------------
-- Informants, from who people are (LC.IsSnitch: sv_livingcity_snitches.lua)
------------------------------------------------------------------------
local function InformScore(m)
    local t = Psy.Traits(m)
    return (0.6 - t.brave) * (0.5 + t.loyal) + t.greed - 0.5 * t.compassion
end

-- true or false for a named citizen; nil for anyone else (the old roll stands).
function LC.MindsIsInformer(npc, st)
    if not On() then return nil end
    local m = Mind(npc)
    if not m or m.role ~= "citizen" then return nil end
    if m.p.rebel or st.rebel then return false end
    local now = CurTime()
    if not A.informers or now > (A.informersUntil or 0) then
        local list = {}
        for _, q in pairs(LC.Minds.byId) do
            if q.role == "citizen" and q.p and q.p.alive ~= false and not q.p.rebel then list[#list + 1] = q end
        end
        table.sort(list, function(a, b)
            local sa, sb = InformScore(a), InformScore(b)
            if sa ~= sb then return sa > sb end
            return tostring(a.id) < tostring(b.id)
        end)
        local cv = GetConVar("lc_snitch_chance")
        local share = math.Clamp((cv and cv:GetFloat() or 0.12) * (LC.LedgerSnitchMul or 1), 0, 1)
        local n = math.floor(share * #list + 0.5)
        A.informers = {}
        for i = 1, n do A.informers[list[i].id] = true end
        A.informersUntil = now + 60
    end
    return A.informers[m.id] == true
end

------------------------------------------------------------------------
-- Unrest, for sociostability (LC.SocioAuto: sv_livingcity_cp.lua)
------------------------------------------------------------------------
function LC.MindsUnrest()
    if not (Psy and LC.MindsOn and LC.MindsOn()) then return 0 end
    local now = CurTime()
    if A.unrest and now < (A.unrestUntil or 0) then return A.unrest end
    local roster = {}
    for _, m in pairs(LC.Minds.byId) do
        if m.role == "citizen" and m.psy and m.p and m.p.alive ~= false and not m.dead then roster[#roster + 1] = m end
    end
    A.unrest, A.unrestUntil = Psy.Unrest(roster), now + 30
    return A.unrest
end

-- Yellow from the line up, and it stays until the mood has eased a little below it.
function LC.MindsUnrestHigh()
    if not On() then A.high = nil return false end
    local line = cvUnrest:GetFloat()
    if line <= 0 then A.high = nil return false end
    local u = LC.MindsUnrest()
    if u >= line then A.high = true elseif u < line - 0.08 then A.high = nil end
    return A.high == true
end

------------------------------------------------------------------------
-- A break, for real
------------------------------------------------------------------------
local function MakeSympathizer(m)
    local p = m.p
    if not p or p.rebel or m.role ~= "citizen" then return false end
    local all, reb = 0, 0
    for _, q in pairs(LC.Minds.byId) do
        if q.role == "citizen" and q.p and q.p.alive ~= false then
            all = all + 1
            if q.p.rebel then reb = reb + 1 end
        end
    end
    if all > 0 and (reb + 1) / all > REBEL_CAP then return false end
    p.rebel = true
    m.rebel = true
    local npc, st = Body(m)
    if npc then
        st.rebel, st.snitch = true, false
        npc:SetNW2Bool("lc_prebel", true)
    end
    A.informers = nil
    if LC.SavePeople then LC.SavePeople() end
    return true
end

local function Stop(npc, st, secs)
    if st.state == "inline" and LC.LeaveLine then LC.LeaveLine(npc, st) end
    LC.SetState(npc, st, "detained")
    st.untilT = CurTime() + secs
    if npc.SetSchedule and SCHED_IDLE_STAND then npc:SetSchedule(SCHED_IDLE_STAND) end
end

local ACT = {}

function ACT.tantrum(m, now)
    local npc, st = Body(m)
    Psy.Think(m, "vented", now)
    if not npc or not Free(st) then return "let it out at home" end
    local unit = NearestOf(npc:GetPos(), 1500, IsUnit)
    if not unit then
        Line(npc, st, "say_break_tantrum")
        Scene(npc:GetPos(), m.name .. " kicks at the wall and shouts at nobody.")
        return "shouted in the street"
    end
    Errand(npc, st, unit, function(n, s, u)
        if LC.Face then LC.Face(n, u:GetPos()) LC.Face(u, n:GetPos()) end
        Line(n, s, "say_break_tantrum")
        Scene(n:GetPos(), m.name .. " screams in " .. UnitName(u) .. "'s face.")
        local who = LC.MindsWhoKey and LC.MindsWhoKey(u)
        if who then Psy.Bond(m, who, -1) end
        if LC.ArrestNPC and math.random() < 0.25 and LC.ArrestNPC(n, u) then return end
        Stop(n, s, 30)
    end)
    return "went to scream at " .. UnitName(unit)
end

function ACT.despair(m, now)
    local npc, st = Body(m)
    if not npc then return "stayed in" end
    st.mindLowUntil = now + LOW_SECS
    if not Free(st) then return "gave up for a while" end
    local spots = LC.FreePoints and LC.FreePoints({ sit = true, sitchair = true, lean = true }, npc) or {}
    Line(npc, st, "say_break_despair")
    Scene(npc:GetPos(), m.name .. " stops where they are and stares at nothing.")
    if #spots > 0 then
        local p = spots[math.random(#spots)]
        LC.Claim(npc, st, p)
        LC.GoTo(npc, st, p.pos, false, p)
        return "sat down and gave up for a while"
    end
    if LC.StartLeaving then LC.StartLeaving(npc, st, false, "despair: gone home") end
    return "went home"
end

function ACT.defy(m, now)
    local npc, st = Body(m)
    local joined = MakeSympathizer(m)
    if npc and Free(st) then
        local poster, pd
        for _, e in ipairs(ents.FindByClass("lc_civposter")) do
            if not e.lcTornDown and not e:GetNW2Bool("lc_defaced", false) and string.sub(e:GetNW2String("lc_notice", ""), 1, 6) ~= "rebel_" then
                local d = e:GetPos():DistToSqr(npc:GetPos())
                if d < 1500 * 1500 and (not pd or d < pd) then poster, pd = e, d end
            end
        end
        if poster then
            Errand(npc, st, poster, function(n, s, e)
                if e:GetNW2Bool("lc_defaced", false) then return end
                e:SetNW2Bool("lc_defaced", true)
                e.lcDefacedBy = n
                Line(n, s, "say_break_defy")
                Scene(n:GetPos(), m.name .. " drags a line of paint across the poster and walks on.")
                hook.Run("LivingCityPosterDefaced", n, e)
            end)
            return "went to paint over a poster" .. (joined and ", and sides with the Resistance now" or "")
        end
    end
    return joined and "sides with the Resistance now" or "kept it to themselves"
end

-- A unit hears a name (sv_livingcity_snitches.lua has the same for what a snitch saw).
local function Named(npc, m, ply)
    if not IsValid(ply) or not ply:Alive() then return end
    local where = (LC.DescribePlace and LC.DescribePlace(ply:GetPos())) or ""
    ply:SetNW2Float("lc_spotted_until", CurTime() + 60)
    ply:SetNW2String("lc_spotted_why", "a citizen's word")
    local who = ply:GetNW2String("lc_desc", "") ~= "" and ply:GetNW2String("lc_desc", "") or ((LC.CharacterName and LC.CharacterName(ply)) or ply:Nick())
    for _, p in ipairs(player.GetAll()) do
        if LC.PlayerIsCP and LC.PlayerIsCP(p) then
            p:ChatPrint("[CP net] A citizen names a troublemaker" .. (where ~= "" and (", " .. where) or "") .. ": " .. who .. ". Outlined for 60 seconds.")
        end
    end
    ply:ChatPrint("[Miscount] Somebody gave Civil Protection your name.")
    hook.Run("LivingCitySnitched", npc, ply, "named as a troublemaker")
end

function ACT.inform(m, now)
    local npc, st = Body(m)
    if m.p and m.p.rebel then return "thought about it, and didn't" end
    if npc then st.snitch = true end
    m.informer = true
    if not npc or not Free(st) then return "would talk to a unit, given the chance" end
    local key = Worst(m, function(id, v) return v <= -2 and string.sub(tostring(id), 1, 3) == "pl:" and IsValid(PlayerOf(id)) end)
    local ply = key and PlayerOf(key)
    local unit = NearestOf(npc:GetPos(), 5000, IsUnit)
    if IsValid(ply) and not (LC.PlayerIsCP and LC.PlayerIsCP(ply)) and unit then
        Errand(npc, st, unit, function(n, s, u)
            if LC.Face then LC.Face(n, u:GetPos()) LC.Face(u, n:GetPos()) end
            Line(n, s, "say_break_inform")
            Named(n, m, ply)
        end)
        return "went to give a unit a name"
    end
    return "is an informant now"
end

function ACT.seek(m, now)
    local npc, st = Body(m)
    if not npc or not Free(st) then return "wished for company" end
    local id = Best(m, function(fid)
        local q = LC.Minds.byId[fid]
        return q and q.p and IsValid(q.p.npc) and q.p.npc ~= npc
    end)
    local q = id and LC.Minds.byId[id]
    if not q then return "looked for a friend and found nobody out" end
    Errand(npc, st, q.p.npc, function(n, s, other)
        local ost = LC.NPCs[other]
        if LC.Face then LC.Face(n, other:GetPos()) LC.Face(other, n:GetPos()) end
        Line(n, s, "say_break_seek")
        if ost then timer.Simple(2.5, function() local path = Vo(ost, string.format("answer%02d", math.random(1, 20))) if IsValid(other) and not (LC.OwnVoice and LC.OwnVoice(other, ost, path)) then other:EmitSound(path, 70) elseif IsValid(other) and LC.Cue then LC.Cue(other, ost, "say_greet_warm", { force = true }) end end) end
        Psy.Chat(m, q, CurTime(), LC.MindsCtx or {})
        Psy.Think(m, "comforted", CurTime(), q.id)
        m.psy.stress = m.psy.stress * 0.8
    end)
    return "went to find " .. (q.name or "a friend")
end

function ACT.hoard(m, now)
    local npc, st = Body(m)
    m.psy.food = math.min(1, m.psy.food + 0.3)
    if npc and Free(st) and st.state ~= "inline" and LC.Lines and next(LC.Lines) and LC.JoinLine then
        st.servedUntil = nil
        if LC.JoinLine(npc, st) then return "went back to the line for more than their share" end
    end
    return "kept food back"
end

function ACT.accuse(m, now)
    local id = Worst(m, function(fid) local q = LC.Minds.byId[fid] return q and q.role == "citizen" and q.p and q.p.alive ~= false end)
    local q = id and LC.Minds.byId[id]
    if not q then return "trusts nobody, and said nothing" end
    Psy.Think(q, "accused", now, m.id)
    Psy.Bond(q, m.id, -3)
    local npc = Body(m)
    local item = { k = "accused", about = q.id, to = m.id, w = 1, hop = 0 }
    Psy.Hear(m, item, now)
    if npc then
        for _, w in ipairs(LC.MindsNearby and LC.MindsNearby(npc:GetPos(), npc) or {}) do
            if w.role == "citizen" and w.id ~= q.id then
                local heard = Psy.Hear(w, { k = "accused", about = q.id, to = m.id, w = 0.6, hop = 1 }, now)
                if heard then Psy.OnNews(w, heard, now, LC.MindsCtx or {}) end
            end
        end
        local _, nst = Body(m)
        Line(npc, nst, "say_break_accuse")
        local other, ost = Body(q)
        if other and other:GetPos():DistToSqr(npc:GetPos()) < HEAR * HEAR then
            timer.Simple(3, function() if IsValid(other) then Line(other, ost, "say_break_accused") end end)
        end
        Scene(npc:GetPos(), m.name .. " says it loud enough for the street to hear: " .. (q.name or "someone") .. " talks to Civil Protection.")
    end
    return "called " .. (q.name or "someone") .. " an informer"
end

function ACT.sabotage(m, now)
    local npc, st = Body(m)
    if not npc or not Free(st) or not LC.BreakStreetFixture then return "did their work badly on purpose" end
    local best, bd
    for _, cls in ipairs({ "lc_streetlight", "lc_loudspeaker" }) do
        for _, e in ipairs(ents.FindByClass(cls)) do
            if not e:GetNW2Bool("lc_broken", false) then
                local d = e:GetPos():DistToSqr(npc:GetPos())
                if d < 1500 * 1500 and (not bd or d < bd) then best, bd = e, d end
            end
        end
    end
    if not best then return "did their work badly on purpose" end
    Errand(npc, st, best, function(n, s, e)
        if LC.BreakStreetFixture(e, n) then Scene(n:GetPos(), m.name .. " does something quick to the wiring and walks away.") end
    end)
    return "went to break a " .. (best:GetClass() == "lc_loudspeaker" and "loudspeaker" or "streetlight")
end

function ACT.binge(m, now)
    local npc, st = Body(m)
    if not npc or not LC.NPCViceStart then return "drank at home" end
    if LC.NPCViceStop then LC.NPCViceStop(npc) end
    if LC.NPCViceStart(npc, "drink", now) and LC.NPCVices and LC.NPCVices[npc] then
        LC.NPCVices[npc].untilT = now + 150
        Line(npc, st, "say_break_binge")
        Scene(npc:GetPos(), m.name .. " has a bottle out and doesn't care who sees.")
        return "drank in the street"
    end
    return "drank at home"
end

function ACT.brutal(m, now)
    local npc, st = Body(m)
    if not npc or st.state == "hostile" then return "took it out on the cells" end
    local cit, cst = NearestOf(npc:GetPos(), 400, IsCitizen)
    if not cit then return "found nobody to take it out on" end
    if LC.Face then LC.Face(npc, cit:GetPos()) end
    npc:EmitSound("weapons/stunstick/stunstick_fleshhit" .. math.random(1, 2) .. ".wav", 80)
    Line(npc, st, "unit_brutal")
    timer.Simple(1.2, function() if IsValid(cit) and cit:Health() > 0 then Line(cit, cst, "say_break_beaten") end end)
    local victim = cit.lcProfile and cit.lcProfile.name or "a citizen"
    Scene(cit:GetPos(), m.name .. " lays into " .. victim .. " with the stick, for nothing.")
    local dmg = math.min(12, math.max(0, cit:Health() - 5))
    if LC.MindsHurt then LC.MindsHurt(cit, npc, dmg) end
    if dmg > 0 then cit:SetHealth(cit:Health() - dmg) end
    Stop(cit, cst, 20)
    return "beat " .. victim
end

function ACT.drink(m, now)
    local npc, st = Body(m)
    if not npc then return "drank off duty" end
    st.nextInspect = math.max(st.nextInspect or 0, now + 300)
    Line(npc, st, "unit_drink")
    Scene(npc:GetPos(), m.name .. " takes a pull from a flask when he thinks nobody is looking.")
    return "drank on duty: no stops from him for five minutes"
end

function ACT.leak(m, now)
    if not LC.RadioNotice then return "said nothing after all" end
    local names = {}
    for npc, st in pairs(LC.NPCs or {}) do
        if IsValid(npc) and st.role == "citizen" and st.snitch == true and npc.lcProfile and npc.lcProfile.name then names[#names + 1] = npc.lcProfile.name end
    end
    if #names > 0 then
        local name = names[math.random(#names)]
        LC.RadioNotice("resistance", "Word from inside Civil Protection: " .. name .. " has been talking to them.")
        return "told the Resistance about " .. name
    end
    for npc, st in pairs(LC.NPCs or {}) do
        if IsValid(npc) and st.role == "cop" then st.nextInspect = math.max(st.nextInspect or 0, now + 180) end
    end
    LC.RadioNotice("resistance", "Word from inside Civil Protection: the patrols are slack for the next few minutes.")
    return "told the Resistance the patrols are slack"
end

function ACT.share(m, now)
    local id, low
    for fid, v in pairs(m.psy.ties) do
        local q = LC.Minds.byId[fid]
        if v > 0 and q and q.psy and q.p and q.p.alive ~= false and (not low or q.psy.food < low) then id, low = fid, q.psy.food end
    end
    local q = id and LC.Minds.byId[id]
    if not q or low > 0.6 then return "had nobody hungry to share with" end
    q.psy.food = math.min(1, q.psy.food + 0.3)
    m.psy.food = math.max(0, m.psy.food - 0.2)
    Psy.Think(q, "kindness", now, m.id)
    Psy.Bond(q, m.id, 2)
    local npc = Body(m)
    local other = Body(q)
    if npc and other and npc:GetPos():DistToSqr(other:GetPos()) < HEAR * HEAR then
        local _, nst = Body(m)
        Line(npc, nst, "say_break_share")
        Scene(npc:GetPos(), m.name .. " presses half a ration into " .. (q.name or "a friend") .. "'s hands.")
    end
    return "shared food with " .. (q.name or "a friend")
end

function ACT.shelter(m, now)
    local joined = MakeSympathizer(m)
    if joined and LC.RadioNotice then
        LC.RadioNotice("resistance", "Word in the blocks: " .. (m.name or "someone") .. " can be trusted, and would hide one of ours.")
    end
    return joined and "sides with the Resistance now, and would hide one of theirs" or "would hide a friend"
end

function ACT.steady(m, now)
    local npc = Body(m)
    if not npc then return "kept the household calm" end
    local n = 0
    for _, w in ipairs(LC.MindsNearby and LC.MindsNearby(npc:GetPos(), npc) or {}) do
        if w.psy and w.role == "citizen" then
            w.psy.stress = math.max(0, w.psy.stress - 3)
            Psy.Think(w, "steadied", now, m.id)
            n = n + 1
        end
    end
    if n > 0 then
        local _, nst = Body(m)
        Line(npc, nst, "say_break_steady")
        Scene(npc:GetPos(), m.name .. " has a quiet word with the people nearby, and shoulders come down.")
    end
    return "steadied " .. n .. " people nearby"
end

LC.MindsActKinds = ACT
LC.MindsFree, LC.MindsErrand, LC.MindsNamed = Free, Errand, Named -- (the director and free talk: sv_livingcity_brain.lua)

-- Called by the minds where a break is written down. Returns what was done, or nil (watching only).
function LC.MindsAct(m, kind, now)
    if not On() or not m or not m.psy or not ACT[kind] then return nil end
    now = now or CurTime()
    local ok, did = pcall(ACT[kind], m, now)
    if not ok then
        if LC.Error then LC.Error("minds (act " .. tostring(kind) .. ")", did) end
        return nil
    end
    A.did[kind] = (A.did[kind] or 0) + 1
    A.last = { who = m.name, kind = kind, did = did, at = now }
    hook.Run("LivingCityMindBroke", m, kind, did)
    return did
end

-- For the debug report.
function LC.MindsActReport()
    if not On() then return { "watching only (lc_minds_act 0)" } end
    local c = {}
    for k, v in pairs(A.did) do c[#c + 1] = k .. "=" .. v end
    table.sort(c)
    local errands = 0
    for _ in pairs(A.errands) do errands = errands + 1 end
    local out = { string.format("acting: unrest %.2f (yellow from %s%s) | errands under way %d | done: %s", LC.MindsUnrest(), cvUnrest:GetString(),
        A.high and ", and it is" or "", errands, #c > 0 and table.concat(c, " ") or "(nothing yet)") }
    if A.last then out[#out + 1] = string.format("last: %s, %s: %s", tostring(A.last.who), A.last.kind, tostring(A.last.did)) end
    return out
end

timer.Create("LivingCityMindsAct", 1, 0, function()
    if LC.TimeStopped or not next(A.errands) then return end
    local ok, err = pcall(LC.MindsErrandTick, CurTime())
    if not ok and LC.Error then LC.Error("minds (errands)", err) end
end)
