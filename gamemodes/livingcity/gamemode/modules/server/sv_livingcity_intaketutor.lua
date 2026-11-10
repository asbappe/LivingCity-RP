--[[
    Living City: the arrival search (the owner, 10 November).

    New arrivals are searched by Civil Protection before or after they go
    through Civil Intake, and can learn how a search works while it happens.

    - A unit stands beside each Civil Intake terminal and each Housing
      Allocation terminal (one each) while anyone new is in the city who
      hasn't been searched yet. Walk past and he searches you.
    - The search is a copy of the pat-down (sv_livingcity_patsearch.lua),
      done by the unit: Jacket, Waist, Legs and Boots, one at a time, and the
      person searched may press R once to slip something into a spot already
      checked. First they choose: "Show me how searches work" (slower, every
      step explained, with a practice token to hide, and afterwards a go at
      the other side, searching someone) or "Just search me".
    - Whatever real contraband turns up is taken, with a warning and no
      charge: it's their first day.
    - Out of the station without being searched (the units were busy): the
      nearest unit comes and does it there, the same way.
    - Out of the station without registering: the nearest unit stops them,
      searches them if nobody has, looks at their papers (none), cuffs them
      and walks them back to the Civil Intake terminal, where the cuffs come
      off. Never to the cells: if the walk gets stuck, they're simply handed
      over at the desk.

    The station is everywhere within lc_intake_station units of a Civil
    Intake terminal or an arrival point.

      lc_intake_tutor 0/1, lc_intake_escort 0/1, lc_intake_station (1500)
]]

if CLIENT then return end

LC = LC or {}

local FLAGS = bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED)
local cvOn      = CreateConVar("lc_intake_tutor", "1", FLAGS, "New arrivals are searched by a Civil Protection unit at the Civil Intake and Housing Allocation terminals, and can learn how searches work")
local cvEscort  = CreateConVar("lc_intake_escort", "1", FLAGS, "A new arrival who leaves the station without registering is stopped, cuffed and walked back to Civil Intake")
local cvStation = CreateConVar("lc_intake_station", "1500", FLAGS, "How far from a Civil Intake terminal or arrival point still counts as the station, for the arrival search")

local SPOTS = { "Jacket", "Waist", "Legs", "Boots" }
local SLIP_CHANCE = 0.6   -- (as in the real pat-down)
local LEARN_SECS = 3.5    -- a spot, with it explained
local QUICK_SECS = 1.2    -- a spot, just searched
local LEARN_INTRO = 4     -- before the first spot, while it's explained
local ANSWER_SECS = 15    -- to choose; no answer: just searched
local TUTOR_REACH = 320   -- a unit at a desk searches whoever walks this close
local POST_SLACK = 220    -- a unit this far from his post is still "at the desk"
local FAR_CALL = 3000     -- outside the station, the nearest unit within this comes
local CLOSE = 70          -- close enough to search
local STRAY = 260         -- moved this far mid-search: he follows and starts the spot again
local GIVE_UP = 25        -- seconds to reach them before another unit is tried
local IDLE_RELEASE = 120  -- seconds with nobody to search before the units go back to their day
local ESCORT_MAX = 150    -- seconds the walk back may take before they're simply handed over
local THERE = 170         -- this close to the desk: the cuffs come off
local MAX_TUTORS = 4
local PRACTICE = "a folded practice note (not real)"

util.AddNetworkString("lc_tut_offer")  -- (server to client: choose how)
util.AddNetworkString("lc_tut_choice") -- (client: true = show me how)
util.AddNetworkString("lc_tut_state")  -- (server to client: the search as it goes)
util.AddNetworkString("lc_tut_slip")   -- (client: try to slip something)
util.AddNetworkString("lc_tut_close")  -- (server to client: over)
util.AddNetworkString("lc_tut_done")   -- (server to client: the lesson's last page)

LC.TutorPosts = LC.TutorPosts or {}   -- [i] = { kind, pos, yaw, npc }
LC.TutorFlows = LC.TutorFlows or {}   -- [ply] = the search (and maybe the walk back)
local FLOWS = LC.TutorFlows
LC.TutorSlipChance = SLIP_CHANCE

local function Ok(e) return IsValid(e) end
local function Up(npc) return IsValid(npc) and npc:Health() > 0 and LC.NPCs and LC.NPCs[npc] ~= nil end
local function Pick(t) return t[math.random(#t)] end

function LC.TutorOn() return cvOn:GetBool() and (not LC.IntakeOn or LC.IntakeOn()) end

-- A new arrival nobody has searched yet: on their way through the desks (not registered, or not housed yet).
function LC.TutorWants(ply)
    if not LC.TutorOn() or not Ok(ply) or not ply:IsPlayer() or ply.lcTutSearched then return false end
    if not ply:Alive() then return false end
    return (LC.IntakePending and LC.IntakePending(ply)) or (LC.AwaitingHousing and LC.AwaitingHousing(ply)) or false
end

local function ResetPlayer(ply)
    if not Ok(ply) then return end
    ply.lcTutSearched, ply.lcTutEscorts = nil, nil
end
LC.TutorReset = ResetPlayer
hook.Add("LivingCityCharacterSwitched", "LivingCityIntakeTutor", ResetPlayer)

------------------------------------------------------------------------
-- The station, and the units at the desks
------------------------------------------------------------------------

local function Anchors()
    local out = {}
    for _, p in ipairs(LC.PointsOfKind and LC.PointsOfKind("intake") or {}) do out[#out + 1] = p.pos end
    for _, p in ipairs(LC.ArrivalSpots and LC.ArrivalSpots() or {}) do out[#out + 1] = p.pos end
    return out
end

function LC.InStation(pos)
    local anchors = Anchors()
    if #anchors == 0 then return true end -- (no desks, no station: nobody is ever "out of it")
    local r = cvStation:GetFloat()
    for _, a in ipairs(anchors) do
        if a:DistToSqr(pos) < r * r then return true end
    end
    return false
end

local function Ground(v) return LC.GroundAt and LC.GroundAt(v) or v end

-- Beside the terminal, out of the line in front of it.
local function PostSpot(p)
    local ang = Angle(0, p.yaw or 0, 0)
    local fwd, right = ang:Forward(), ang:Right()
    for _, side in ipairs({ 1, -1 }) do
        local spot = Ground(p.pos + fwd * 60 + right * 75 * side + Vector(0, 0, 8))
        if not LC.ClearSpot or LC.ClearSpot(spot) then return spot end
    end
    return Ground(p.pos + fwd * 90 + Vector(0, 0, 8))
end

local function Posts()
    local want = {}
    for _, kind in ipairs({ "intake", "housingterm" }) do
        for _, p in ipairs(LC.PointsOfKind and LC.PointsOfKind(kind) or {}) do
            if #want < MAX_TUTORS then want[#want + 1] = { kind = kind, src = p } end
        end
    end
    -- keep the units already posted where the desk is the same
    local old = LC.TutorPosts
    local posts = {}
    for i, w in ipairs(want) do
        local keep
        for _, o in ipairs(old) do
            if o.src == w.src then keep = o break end
        end
        posts[i] = keep or { kind = w.kind, src = w.src, pos = PostSpot(w.src), yaw = (w.src.yaw or 0) + 180 }
    end
    for _, o in ipairs(old) do
        local kept = false
        for _, p in ipairs(posts) do if p == o then kept = true end end
        if not kept and Up(o.npc) then
            local st = LC.NPCs[o.npc]
            st.holdPos, st.tutorPost = nil, nil
        end
    end
    LC.TutorPosts = posts
    return posts
end

local function FreeUnit(st)
    return st.role == "cop" and not st.test and not st.questLock and not st.marching and not st.holdPos and not st.guardZone
        and not st.unmanaged and not st.tutorPost and not st.tutorBusy and not st.raid and not st.escortee and not st.subject
        and (st.state == "idle" or st.state == "moving")
end

local function NearestUnit(pos, within, ok)
    local best, bd
    for npc, st in pairs(LC.NPCs or {}) do
        if Up(npc) and ok(st) then
            local d = npc:GetPos():DistToSqr(pos)
            if d < within * within and (not bd or d < bd) then best, bd = npc, d end
        end
    end
    return best
end

local function Post(npc, post)
    local st = LC.NPCs[npc]
    post.npc = npc
    st.tutorPost, st.holdPos = post, post.pos
    if LC.GoTo then LC.GoTo(npc, st, post.pos, false, nil) end
end

local function Unpost(post)
    if Up(post.npc) then
        local st = LC.NPCs[post.npc]
        st.tutorPost, st.holdPos = nil, nil
    end
    post.npc = nil
end

local lastNeed = -1e9
local function Staff(now)
    local need = false
    for _, ply in ipairs(player.GetAll()) do
        if LC.TutorWants(ply) then need = true break end
    end
    if need then lastNeed = now end
    local posts = Posts()
    if now - lastNeed > IDLE_RELEASE then
        for _, post in ipairs(posts) do if post.npc then Unpost(post) end end
        return
    end
    for _, post in ipairs(posts) do
        if not Up(post.npc) then
            post.npc = nil
            local npc = NearestUnit(post.pos, 6000, FreeUnit)
            if not npc and LC.SpawnCop and (post.nextSpawn or 0) < now then
                post.nextSpawn = now + 30
                npc = LC.SpawnCop(LC.FreeSpawnPos and LC.FreeSpawnPos(post.pos) or post.pos)
            end
            if Up(npc) then Post(npc, post) end
        else
            local st = LC.NPCs[post.npc]
            if not st.tutorBusy and st.state == "idle" and post.npc:GetPos():DistToSqr(post.pos) < 60 * 60 and LC.FaceYaw then
                LC.FaceYaw(post.npc, post.yaw)
            end
        end
    end
end

------------------------------------------------------------------------
-- The search
------------------------------------------------------------------------

local function ItemName(it)
    if it.practice then return PRACTICE end
    if LC.PatSearchItemName then return LC.PatSearchItemName(it) end
    return tostring(it.gun or it.id)
end

local function Send(ply, name, t)
    if not Ok(ply) then return end
    net.Start(name)
    net.WriteString(util.TableToJSON(t or {}) or "{}")
    net.Send(ply)
end

local function Push(F)
    if not F.spots then return end
    local anyDone = false
    for _, sp in ipairs(F.spots) do if sp.done then anyDone = true end end
    local t = { learn = F.learn, step = F.step, checking = F.checking, secs = F.secs, spots = {},
        slip = F.slipUsed and "used" or (anyDone and "ready" or "wait"), key = "R", tip = F.tip }
    for i, sp in ipairs(F.spots) do
        local mine = {}
        for _, it in ipairs(sp.items) do mine[#mine + 1] = ItemName(it) end
        t.spots[i] = { name = sp.name, state = sp.done and 2 or (F.checking == i and 1 or 0), mine = table.concat(mine, ", "), found = sp.found }
    end
    Send(F.ply, "lc_tut_state", t)
end
LC.TutorPush = Push

local function Say(F, line)
    if Up(F.cop) and line then F.cop:EmitSound(line, 75) end
end

-- What each spot is about, while it's checked (the lesson).
local TIPS = {
    intro = "A search: the unit checks four spots, Jacket, Waist, Legs and Boots, one at a time. Whatever he finds that's contraband is taken. A spot he never checks keeps what's in it.",
    Jacket = "Jacket: inside pockets, the lining. Small things hide here, and it's the first place most units look.",
    Waist = "Waist: belt and waistband. Quick for him to check, so it's a poor hiding place.",
    Legs = "Legs: trouser pockets and down the seams. Once a spot's been checked, press R to slip one thing into it: he won't look there again.",
    Boots = "Boots: last, and the one units most often skip. Slipping something only works 6 times in 10; if he feels it, it's found there and then.",
}

local function StartSearch(F, learn)
    local ply = F.ply
    F.stage, F.learn = "search", learn and true or false
    F.secs = F.learn and LEARN_SECS or QUICK_SECS
    F.spots = {}
    for i, name in ipairs(SPOTS) do F.spots[i] = { name = name, items = {} } end
    -- what a search would find on them, worked out now and spread over the spots (taken only when checked)
    for _, f in ipairs(LC.SearchPockets and LC.SearchPockets(ply, 0.1, true) or {}) do
        table.insert(F.spots[math.random(#F.spots)].items, { id = f.id, n = f.n })
    end
    for _, cls in ipairs(LC.SearchWeapons and LC.SearchWeapons(ply, 0.1, true) or {}) do
        table.insert(F.spots[math.random(#F.spots)].items, { gun = cls })
    end
    F.order = { 1, 2, 3, 4 }
    if not F.learn then
        for i = #F.order, 2, -1 do local j = math.random(i) F.order[i], F.order[j] = F.order[j], F.order[i] end
    else
        table.insert(F.spots[4].items, { practice = true }) -- (Boots, checked last: time to try R first)
    end
    F.step = 0
    F.found, F.guns = {}, {}
    F.nextAt = CurTime() + (F.learn and LEARN_INTRO or 0.6)
    F.tip = F.learn and TIPS.intro or nil
    F.origin = ply:GetPos()
    ply.lcBeingSearched = F.cop
    ply:SetNW2Float("lcu_stop_until", CurTime() + 30)
    if Up(F.cop) and LC.PlayGesture then LC.PlayGesture(F.cop, LC.FRISK_ANIMS or {}, 6) end
    Say(F, "npc/metropolice/vo/apply.wav")
    if F.learn then
        ply:SetPData("lc_tut_lesson", "1") -- (seen it once: next time "Just search me" is the first choice)
    end
    Push(F)
end

local function Take(F, it)
    local ply = F.ply
    if it.practice then return true end
    if it.gun then
        if not ply:HasWeapon(it.gun) then return false end
        ply:StripWeapon(it.gun)
        F.guns[#F.guns + 1] = it.gun
        return true
    end
    local n = math.min(it.n or 1, (LC.Inventory and LC.Inventory(ply) or {})[it.id] or 0)
    if n <= 0 then return false end
    LC.TakeItem(ply, it.id, n)
    F.found[#F.found + 1] = { id = it.id, n = n }
    return true
end

local function CheckSpot(F, i)
    local sp = F.spots[i]
    sp.done = true
    local got, keep = {}, {}
    for _, it in ipairs(sp.items) do
        if it.slipped then keep[#keep + 1] = it
        elseif Take(F, it) then got[#got + 1] = ItemName(it) end
    end
    sp.items = keep
    sp.found = #got > 0 and table.concat(got, ", ") or nil
    if sp.found then
        F.ply:ChatPrint("[Search] " .. sp.name .. ": the unit finds " .. sp.found .. ".")
        if F.learn then
            for _, it in ipairs(got) do
                if it == PRACTICE then
                    F.ply:ChatPrint("[Search] That was the practice note. In a real search, whatever he finds is taken, and it can be a crime.")
                end
            end
        end
    end
end

-- The person searched tries to slip one thing from an unchecked spot into a checked one. Once a search.
function LC.TutorSlip(ply)
    local F = FLOWS[ply]
    if not F or F.stage ~= "search" or F.slipUsed then return false end
    local done, from = {}, {}
    for i, sp in ipairs(F.spots) do
        if sp.done then done[#done + 1] = i
        elseif F.checking ~= i then
            for k, it in ipairs(sp.items) do from[#from + 1] = { i = i, k = k, it = it } end
        end
    end
    if #done == 0 then
        ply:ChatPrint("[Search] Nothing's been checked yet: wait until a spot is done.")
        return false
    end
    if #from == 0 then
        ply:ChatPrint("[Search] Nothing left to move.")
        return false
    end
    F.slipUsed = true
    local pick = from[math.random(#from)]
    table.remove(F.spots[pick.i].items, pick.k)
    local name = ItemName(pick.it)
    if math.random() < SLIP_CHANCE then
        local into = F.spots[done[math.random(#done)]]
        pick.it.slipped = true
        table.insert(into.items, pick.it)
        ply:ChatPrint("[Search] You ease the " .. name .. " into your " .. string.lower(into.name) .. ". He didn't notice.")
        if pick.it.practice then ply:ChatPrint("[Search] In a real search, you'd have kept it.") end
    else
        Take(F, pick.it)
        Say(F, "npc/metropolice/vo/holdit.wav")
        ply:ChatPrint("[Search] He felt it. The " .. name .. " is found.")
        if pick.it.practice then ply:ChatPrint("[Search] In a real search, it's taken, and he knows you tried to hide it.") end
    end
    Push(F)
    return true
end

------------------------------------------------------------------------
-- The walk back to Civil Intake (cuffed; never to the cells)
------------------------------------------------------------------------

local function DeskSpot(from)
    local best, bd
    for _, p in ipairs(LC.PointsOfKind and LC.PointsOfKind("intake") or {}) do
        local d = p.pos:DistToSqr(from)
        if not bd or d < bd then best, bd = p, d end
    end
    if not best then return nil end
    local fwd = Angle(0, best.yaw or 0, 0):Forward()
    return Ground(best.pos + fwd * 80 + Vector(0, 0, 8))
end
LC.TutorDeskSpot = DeskSpot

-- Handed over at the desk: right there, cuffs off.
local function HandOver(F, how)
    local ply = F.ply
    if Ok(ply) and ply:Alive() and F.dest then
        local spot = LC.FreeSpawnPos and LC.FreeSpawnPos(F.dest) or F.dest
        if how == "placed" then ply:SetPos(spot) end
        if LC.IsTied and LC.IsTied(ply) then LC.Untie(ply, nil, true) end
        ply:ChatPrint("[Civil Protection] " .. (how == "placed" and "They hand you over at Civil Intake and take the cuffs off. " or "The unit takes the cuffs off. ")
            .. "Register. Now.")
        if LC.Notice then LC.Notice(ply, "info", "Civil Intake", "Register at the terminal before you go into the city: press E on it.") end
    end
end

local function StartEscort(F)
    local ply, cop = F.ply, F.cop
    local st = LC.NPCs[cop]
    if not (LC.IntakePending and LC.IntakePending(ply)) then return false end -- (only ever someone not on the register)
    F.dest = DeskSpot(ply:GetPos())
    if not F.dest then return false end
    F.stage, F.escortAt, F.tries = "escort", CurTime(), 0
    ply.lcTutEscorts = (ply.lcTutEscorts or 0) + 1
    if LC.IsTied and not LC.IsTied(ply) then LC.TiePlayer(ply, nil) end
    st.questLock = true
    Say(F, "npc/metropolice/vo/movingtocode3.wav")
    ply:ChatPrint("[Civil Protection] No papers, not registered. You're cuffed and walked back to Civil Intake.")
    if LC.Notice then LC.Notice(ply, "warn", "Back to Civil Intake", "Nobody goes into the city without registering. The unit is walking you back to the terminal.") end
    if not LC.GoTo or not LC.GoTo(cop, st, F.dest, false) then
        -- no way to walk there: handed over at the desk
        HandOver(F, "placed")
        return "done"
    end
    return true
end

local function Heading(npc)
    local v = npc:GetVelocity()
    v.z = 0
    if v:LengthSqr() > 100 then return v:GetNormalized() end
    local f = npc:GetForward()
    f.z = 0
    return f:GetNormalized()
end

local function Pull(ply, lead)
    local fwd = Heading(lead)
    local right = Vector(fwd.y, -fwd.x, 0)
    local want = lead:GetPos() - fwd * 40 + right * 26
    local d = want - ply:GetPos()
    d.z = 0
    local dist = d:Length()
    if dist > 220 then
        local tr = util.TraceLine({ start = lead:GetPos() + Vector(0, 0, 36), endpos = want + Vector(0, 0, 36),
            mask = MASK_PLAYERSOLID or MASK_SOLID, filter = { lead, ply } })
        local spot = tr.Hit and (tr.HitPos - (want - lead:GetPos()):GetNormalized() * 20) or (want + Vector(0, 0, 36))
        ply:SetPos(Vector(spot.x, spot.y, lead:GetPos().z + 2))
    elseif dist > 30 then
        local v = ply:GetVelocity()
        ply:SetVelocity(d:GetNormalized() * math.min(dist * 5, 240) - Vector(v.x, v.y, 0))
    end
end

------------------------------------------------------------------------
-- One flow: the unit comes, searches, and maybe walks them back
------------------------------------------------------------------------

local function Release(F)
    local cop = F.cop
    local st = Up(cop) and LC.NPCs[cop]
    if not st then return end
    st.tutorBusy, st.questLock = nil, nil
    if st.state == "event" or st.state == "moving" then
        st.eventUntil = 0
        LC.SetState(cop, st, "idle")
        st.untilT = CurTime() + 2
    end
end

local function End(F, how)
    local ply = F.ply
    FLOWS[ply] = nil
    Release(F)
    if Ok(ply) then
        ply.lcBeingSearched = nil
        ply:SetNW2Float("lcu_stop_until", 0)
        ply.lcStopNext = CurTime() + 60 -- (no ordinary stop straight after)
        Send(ply, "lc_tut_close", {})
        if F.stage == "escort" and how ~= "done" and LC.IsTied and LC.IsTied(ply) then LC.Untie(ply, nil, true) end
    end
    hook.Run("LivingCityTutorEnded", ply, F, how)
end
LC.TutorEnd = End

-- Searched: what comes next. True: the flow carries on (the walk back).
local function AfterSearch(F)
    local ply = F.ply
    ply.lcTutSearched = true
    ply.lcBeingSearched = nil
    Send(ply, "lc_tut_close", {})
    -- what was found: taken, with a warning (their first day)
    local names = LC.SearchDescribe and LC.SearchDescribe(F.found, F.guns) or ""
    if names ~= "" then
        Say(F, "npc/metropolice/vo/prepareforjudgement.wav")
        ply:ChatPrint("[Civil Protection] Confiscated: " .. names .. ". A warning, this once: you're new here. Next time it's a crime.")
    else
        Say(F, Pick({ "npc/metropolice/vo/allrightyoucango.wav", "npc/metropolice/vo/movealong.wav" }))
    end
    if F.learn then
        Send(ply, "lc_tut_done", { found = names })
    end
    hook.Run("LivingCityTutorSearched", ply, F.cop, F.found, F.guns)
    -- papers
    local pending = LC.IntakePending and LC.IntakePending(ply)
    if pending and F.out and cvEscort:GetBool() then
        local r = StartEscort(F)
        if r == true then return true end
        return false
    end
    if pending then
        ply:ChatPrint("[Civil Protection] No papers yet. Report to the Civil Intake terminal and register.")
    else
        ply:ChatPrint("[Civil Protection] Searched. Move along.")
    end
    return false
end

-- Begin: the unit is on his way to them. out: they're outside the station.
local function Begin(ply, cop, out, why)
    local st = LC.NPCs[cop]
    local now = CurTime()
    st.tutorBusy = true
    LC.SetState(cop, st, "event")
    st.eventUntil = now + 60
    local F = { ply = ply, cop = cop, out = out, why = why, stage = "approach", startT = now, untilT = now + GIVE_UP }
    FLOWS[ply] = F
    ply.lcStopNext = now + 120
    cop:SetLastPosition(LC.SpotInFrontOf and LC.SpotInFrontOf(ply, cop, 40) or ply:GetPos())
    cop:SetSchedule(SCHED_FORCED_GO)
    if why == "escape" then
        cop:EmitSound("npc/metropolice/vo/holdit.wav", 80)
        ply:ChatPrint("[Civil Protection] Hold it. New arrival? Stand still.")
    elseif why == "unsearched" then
        cop:EmitSound("npc/metropolice/vo/holdit.wav", 78)
        ply:ChatPrint("[Civil Protection] You. New arrivals are searched. Stand still.")
    end
    return F
end
LC.TutorBegin = Begin

local function Offer(F)
    F.stage = "offer"
    F.offerAt = CurTime()
    if Up(F.cop) then
        F.cop:SetSchedule(SCHED_IDLE_STAND)
        LC.Face(F.cop, F.ply:GetPos())
    end
    Say(F, "npc/metropolice/vo/apply.wav")
    F.ply:ChatPrint("[Civil Protection] Arms out. Every arrival is searched.")
    Send(F.ply, "lc_tut_offer", { seen = F.ply:GetPData("lc_tut_lesson", "0") == "1", secs = ANSWER_SECS })
end

function LC.TutorChoose(ply, learn)
    local F = FLOWS[ply]
    if not F or F.stage ~= "offer" then return false end
    StartSearch(F, learn)
    return true
end

local function Step(F, now)
    local ply, cop = F.ply, F.cop
    local st = LC.NPCs and LC.NPCs[cop]
    if not Ok(ply) or not ply:Alive() then return End(F, "gone") end
    if not Up(cop) or not st then return End(F, "lost") end
    if F.stage ~= "escort" and st.state == "hostile" then return End(F, "lost") end
    if F.stage ~= "escort" then st.eventUntil = now + 30 end
    local d2 = ply:GetPos():DistToSqr(cop:GetPos())

    if F.stage == "approach" then
        if d2 < CLOSE * CLOSE then
            if F.spots then F.stage = "search" Push(F) else Offer(F) end
        elseif now > F.untilT then
            ply.lcTutRetry = now + 15
            return End(F, "lost")
        elseif not cop:IsCurrentSchedule(SCHED_FORCED_GO) and not cop:IsCurrentSchedule(SCHED_FORCED_GO_RUN) then
            cop:SetLastPosition(LC.SpotInFrontOf and LC.SpotInFrontOf(ply, cop, 40) or ply:GetPos())
            cop:SetSchedule(d2 > 400 * 400 and SCHED_FORCED_GO_RUN or SCHED_FORCED_GO)
        end
        return
    end

    if F.stage == "offer" then
        LC.Face(cop, ply:GetPos())
        if d2 > STRAY * STRAY then
            F.stage, F.untilT = "approach", now + GIVE_UP
            cop:EmitSound("npc/metropolice/vo/holdit.wav", 78)
            ply:ChatPrint("[Civil Protection] Stand still.")
        elseif now - F.offerAt > ANSWER_SECS then
            StartSearch(F, false)
        end
        return
    end

    if F.stage == "search" then
        LC.Face(cop, ply:GetPos())
        if d2 > STRAY * STRAY then
            -- walked off mid-search: he follows; the spot he was on starts again (no crime, it's their first day)
            F.checking = nil
            F.stage, F.untilT = "approach", now + GIVE_UP
            cop:EmitSound("npc/metropolice/vo/holdit.wav", 78)
            ply:ChatPrint("[Civil Protection] Stand still for the search.")
            Push(F)
            return
        end
        ply:SetNW2Float("lcu_stop_until", now + 5)
        if F.checking then
            if now >= F.checkAt + F.secs then
                CheckSpot(F, F.checking)
                F.checking = nil
                F.nextAt = now + (F.learn and 1.2 or 0.3)
                Push(F)
            end
        elseif now >= F.nextAt then
            F.step = F.step + 1
            local i = F.order[F.step]
            if not i then
                if AfterSearch(F) then return end
                return End(F, "done")
            end
            F.checking, F.checkAt = i, now
            F.tip = F.learn and TIPS[SPOTS[i]] or nil
            Push(F)
        end
        return
    end

    if F.stage == "escort" then
        st.eventUntil = now + 30
        local dd = cop:GetPos():DistToSqr(F.dest)
        if st.state == "hostile" then
            -- he's fighting: he lets go of you, and the cuffs come off (it was only ever back to the desk)
            ply:ChatPrint("[Civil Protection] The unit lets go of you to fight. Go back to Civil Intake and register.")
            return End(F, "lost")
        elseif dd < THERE * THERE or (st.state ~= "moving" and dd < 450 * 450) then
            HandOver(F, ply:GetPos():DistToSqr(F.dest) < 300 * 300 and "walked" or "placed")
            return End(F, "done")
        elseif now - F.escortAt > ESCORT_MAX then
            HandOver(F, "placed")
            return End(F, "done")
        end
        if st.state ~= "moving" and now >= (F.nextTry or 0) then
            -- stuck: set off again, a few times; then simply handed over at the desk (never the cells)
            F.tries = F.tries + 1
            F.nextTry = now + 2
            if F.tries > 6 or not LC.GoTo(cop, st, F.dest, false) then
                HandOver(F, "placed")
                return End(F, "done")
            end
        end
        Pull(ply, cop)
    end
end

------------------------------------------------------------------------
-- Who needs a unit now
------------------------------------------------------------------------

local function Available(ply, now)
    return ply:Alive() and not ply:InVehicle() and not FLOWS[ply] and now > (ply.lcTutRetry or 0)
        and not ply.lcBeingSearched
        and not (LC.InCustody and LC.InCustody(ply)) and not (LC.IsTied and LC.IsTied(ply))
        and not (LC.IntakeProcessing and LC.IntakeProcessing(ply))
        and not ply:GetNW2Bool("lc_sleeping", false)
        and not (LC.EditorHeld and LC.EditorHeld(ply))
end

local function Scan(now)
    if not LC.TutorOn() then return end
    for _, ply in ipairs(player.GetAll()) do
        if Available(ply, now) then
            local pending = LC.IntakePending and LC.IntakePending(ply)
            local wants = LC.TutorWants(ply)
            local out = not LC.InStation(ply:GetPos())
            if wants and not out then
                -- a unit at a desk, close by and free
                for _, post in ipairs(LC.TutorPosts) do
                    local npc = post.npc
                    local st = Up(npc) and LC.NPCs[npc]
                    if st and not st.tutorBusy and st.state ~= "hostile" and npc:GetPos():DistToSqr(post.pos) < POST_SLACK * POST_SLACK
                        and npc:GetPos():DistToSqr(ply:GetPos()) < TUTOR_REACH * TUTOR_REACH then
                        Begin(ply, npc, false, "desk")
                        break
                    end
                end
            elseif out and (wants or (pending and cvEscort:GetBool())) then
                -- out of the station: the nearest free unit comes
                local npc = NearestUnit(ply:GetPos(), FAR_CALL, function(st)
                    return (FreeUnit(st) or (st.tutorPost and not st.tutorBusy)) and st.state ~= "hostile"
                end)
                if npc then Begin(ply, npc, true, pending and "escape" or "unsearched") end
            end
        end
    end
end

-- Searched already and unregistered, out of the station: the walk back starts straight after the papers.
local function Skip(F)
    if F.stage == "approach" and F.spots == nil and F.ply.lcTutSearched and F.out and Ok(F.cop)
        and cvEscort:GetBool() and LC.IntakePending and LC.IntakePending(F.ply)
        and F.ply:GetPos():DistToSqr(F.cop:GetPos()) < CLOSE * CLOSE then
        F.cop:SetSchedule(SCHED_IDLE_STAND)
        LC.Face(F.cop, F.ply:GetPos())
        F.cop:EmitSound("npc/metropolice/vo/apply.wav", 75)
        F.ply:ChatPrint("[Civil Protection] Papers. None?")
        if StartEscort(F) ~= true then End(F, "done") end
        return true
    end
    return false
end

function LC.TutorTick(now)
    now = now or CurTime()
    local list = {}
    for _, F in pairs(FLOWS) do list[#list + 1] = F end
    for _, F in ipairs(list) do
        if FLOWS[F.ply] == F and not Skip(F) then Step(F, now) end
    end
end

local nextStaff, nextScan = 0, 0
timer.Create("LivingCityIntakeTutor", 0.2, 0, function()
    local now = CurTime()
    local ok, err = pcall(function()
        if next(FLOWS) then LC.TutorTick(now) end
        if now >= nextStaff then
            nextStaff = now + 1
            if LC.TutorOn() then Staff(now) end
        end
        if now >= nextScan then
            nextScan = now + 1
            Scan(now)
        end
    end)
    if not ok and LC.Error then LC.Error("intaketutor", err) end
end)

net.Receive("lc_tut_choice", function(_, ply) LC.TutorChoose(ply, net.ReadBool()) end)
net.Receive("lc_tut_slip", function(_, ply) LC.TutorSlip(ply) end)

-- Units don't beat someone they're walking back; they can't work at these cuffs while held.
hook.Add("EntityTakeDamage", "LivingCityIntakeTutor", function(victim, dmg)
    local F = IsValid(victim) and victim:IsPlayer() and FLOWS[victim]
    if F and F.stage == "escort" and dmg:GetAttacker() == F.cop then dmg:SetDamage(0) return true end
end)
hook.Add("LivingCityCanStruggle", "LivingCityIntakeTutor", function(ply)
    local F = FLOWS[ply]
    if F and F.stage == "escort" then return false end
end)
hook.Add("PlayerDisconnected", "LivingCityIntakeTutor", function(ply)
    local F = FLOWS[ply]
    if F then End(F, "gone") end
end)
hook.Add("PlayerDeath", "LivingCityIntakeTutor", function(ply)
    local F = FLOWS[ply]
    if F then End(F, "gone") end
end)
