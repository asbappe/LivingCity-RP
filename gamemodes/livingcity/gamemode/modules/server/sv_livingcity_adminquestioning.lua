--[[
    Living City: the would-be assassin is hers to question (the owner, 16 November)

    "if/when the would-be assassin is ever captured, the interrogation for the would-be assassin is a special
    interrogation led by the administrator, and she is given a stunstick for it". And: "please make sure that
    the NPC/player is turned into a stalker after the interrogation by the administrator."

    A player marked for an attempt on her life (LC.AdminNeverForgotten, sv_livingcity_adminsecurity.lua) who
    is put in a cell is not questioned by a unit. Instead, once per stay in the cells:

      - A player is the Administrator: the job "Question the would-be assassin" goes on her board (F4),
        announced once. Taking it marks the cell. When she reaches it the cell door opens, she is handed a
        stunstick (weapon_lc_baton) and the questioning menu a unit uses, with her own questions. F2 >
        "Interrogate this prisoner" at the cell begins it too. The prisoner answers from the menu they know.
        A blow of her stunstick (the menu's baton, or a real swing at the prisoner: it never does damage of
        its own) takes one resolve and a little health, never under 10; with one resolve left a lie can't be
        held, with none silence can't either. It ends when the questions are done, when she says so, walks
        away or dies, or when either of them leaves; the door shuts and her stunstick is taken back (unless
        she had one already).
      - Nobody plays her: the city's own Administrator (lc_administrator_model, as at her address) comes with
        two soldiers, from out of sight and on foot, or placed at the cell door when no way in is found; she
        puts the same questions through the cell questioning's own code, and they go and are removed out of
        sight.

    One of the city's own that tried to kill her (npc.lcRegicide, set where the attempt is marked) and is put
    in a cell is hers too. A player Administrator gets the same job and questions it the way a prison guard
    questions a prisoner who isn't a player (sv_livingcity_prisonguard.lua), with her questions; the city's
    own comes with her soldiers, and her stunstick is heard three times.

    What comes of it is what a unit's questioning gives (sv_livingcity_interrogation.lua): the truth from a
    member of the Resistance is marked for every unit; anyone else has nothing to give and is asked why. And
    the state of the city: her authority +3 when they break (any truth), -1 when every question was put and
    they gave nothing.

    Then they are made a stalker, whoever they are and however it ended (lc_stalkers 1): a player by the
    stalker's chair custody has (LC.StalkerScene), ten seconds after she is done and once her party has gone;
    one of the city's own is replaced where it stands by a stalker of the Combine zones
    (LC.ZoneStalkerAdopt, sv_livingcity_zonestalkers.lua). If a player Administrator never takes the job, the
    same when the ten minutes are up. Until then they are not let out: a player's sentence does not run out,
    one of the city's own is held as a job's prisoner is. With lc_stalkers 0 nobody is made a stalker: what
    custody had waiting for a player (the broken feet) comes instead.

    Nothing here listens to a hook that someone else could answer first: sv_livingcity_custody.lua and
    sv_livingcity_prison.lua call in when they are brought in, the sessions' own onEnd when it is over, and
    the stunstick calls LC.AdminQuestioningBlow before it does any damage.
]]

if CLIENT then return end

LC = LC or {}

local BATON = "weapon_lc_baton"
local ASKER = "The Administrator"
local WAIT = 12          -- seconds in the cell before anything is arranged (as a unit's questioning)
local OFFER_SECS = 600   -- a player Administrator has this long to take it
local COME_SECS = 60     -- the city's own: on foot this long at most, then placed at the cell door
local NEAR = 500         -- she begins this close to the prisoner (walking 520 away ends it: sv_livingcity_interrogation.lua)
local AWAY = 520
local BROKE, HELD = 3, 1 -- her authority: up when they break, down when they hold out to the end
local THEN_SECS = 10     -- after her questioning, and with her party gone: this long before they are made a stalker
local BLOWS = 3          -- the city's own on one of the city's own: her stunstick this many times

-- Her questions. A member of the Resistance (or anyone hunted or dressed as one):
LC.AdminQuestions = {
    { key = "names", text = "Who sent you?" },
    { key = "supplies", text = "Who armed you?" },
    { key = "hideout", text = "Where do they meet?" },
}
-- Anyone else has nothing to give, and is asked why:
LC.AdminQuestionsNobody = {
    { key = "why", text = "You tried to kill me. Why?", own = true },
    { key = "who", text = "Who put you up to it?", own = true },
}
local function Questions(ply)
    return (LC.CanInterrogate and LC.CanInterrogate(ply)) and LC.AdminQuestions or LC.AdminQuestionsNobody
end

-- [prisoner] = { stage = due / waiting / coming / asking, npc = true for one of the city's own, ... }
LC.AdminQuestioning = LC.AdminQuestioning or {}
local Q = LC.AdminQuestioning
local Gone = {}  -- parties on their way out
local Later = {} -- questioned (or never fetched): what follows
local TEMPLATE

local function PlayerAdministrator()
    for _, p in ipairs(player.GetAll()) do
        if LC.IsAdministrator and LC.IsAdministrator(p) then return p end
    end
    return nil
end

function LC.AdminQuestioningHolds(who) return Q[who] ~= nil end

-- What holds them in a cell: a player's record (LC.Prisoners), or the state of one of the city's own while jailed.
local function Held(who, A)
    if not IsValid(who) then return nil end
    if A.npc then
        local st = LC.NPCs and LC.NPCs[who]
        return st ~= nil and st == A.st and st.state == "jailed" and st or nil
    end
    return LC.Prisoners and LC.Prisoners[who] or nil
end
local function Living(who, A)
    if A.npc then return who:Health() > 0 end
    return who:Alive()
end
local function StalkersOn()
    local cv = GetConVar("lc_stalkers")
    return not cv or cv:GetBool()
end

-- The job comes off her board when nobody is waiting for her any more.
local function Withdraw()
    for _, A in pairs(Q) do if A.stage == "waiting" and not A.job then return end end
    for _, list in pairs(LC.Postings or {}) do
        for _, p in ipairs(list) do if p.tmpl == TEMPLATE and not p.q then p.dead = true end end
    end
end

------------------------------------------------------------------------
-- The cell: where they stand, and its door
------------------------------------------------------------------------

local function Ground(p) return (LC.GroundAt and LC.GroundAt(p + Vector(0, 0, 30))) or p end

-- The cell's door: the nearest one within a few steps of the cell point.
local function DoorBy(cell)
    local best, bd
    for _, e in ipairs(ents.FindInSphere(cell, 220)) do
        if LC.IsDoorEntity and LC.IsDoorEntity(e) then
            local d = e:GetPos():DistToSqr(cell)
            if not bd or d < bd then best, bd = e, d end
        end
    end
    return best
end

local function CellPos(who, A, rec)
    local point = not A.npc and rec.cell or nil
    return point and point.pos or who:GetPos(), point and point.yaw or who:GetAngles().y
end

-- Three places: hers, a step from the prisoner towards the door, and a soldier each side of the door.
local function Spots(who, A, rec)
    local cell, yaw = CellPos(who, A, rec)
    local door = DoorBy(cell)
    local dir, reach = Angle(0, yaw or 0, 0):Forward(), 110
    if IsValid(door) then
        local at = door.WorldSpaceCenter and door:WorldSpaceCenter() or door:GetPos()
        local d = Vector(at.x - cell.x, at.y - cell.y, 0)
        local len = d:Length()
        if len > 1 then dir, reach = d * (1 / len), math.max(60, len) end
    end
    dir.z = 0
    local side = Vector(-dir.y, dir.x, 0)
    local base = cell + dir * reach
    return { Ground(cell + dir * math.min(60, reach * 0.6)), Ground(base + side * 36), Ground(base - side * 36) }, door
end

local function OpenDoor(A, door)
    if not IsValid(door) then return end
    A.door = door
    door.lcHeldOpen = true -- (a prison door slams shut again otherwise: sv_livingcity_doors.lua)
    door:Fire("Unlock")
    door:Fire("Open", "", 0.1)
end
local function ShutDoor(A)
    local door = A.door
    A.door = nil
    if not IsValid(door) then return end
    door.lcHeldOpen = nil
    door:Fire("Close")
    if LC.PrisonDoors and LC.PrisonDoors[door] then door:Fire("Lock", "", 1) end
end

------------------------------------------------------------------------
-- The city's own: her and two soldiers, in and out on foot
------------------------------------------------------------------------

local function Her(pos, yaw)
    local c = GetConVar("lc_administrator_model")
    local mdl = c and string.Trim(c:GetString()) or ""
    if mdl == "" or (util.IsValidModel and not util.IsValidModel(mdl)) then mdl = "models/mossman.mdl" end
    local her = ents.Create("npc_citizen")
    if not IsValid(her) then return nil end
    her:SetModel(mdl)
    her:SetPos(pos + Vector(0, 0, 4))
    her:SetAngles(Angle(0, yaw or 0, 0))
    her:Spawn()
    if her.Activate then her:Activate() end
    if her.AddRelationship then
        for _, cls in ipairs({ "npc_metropolice", "npc_combine_s", "npc_cscanner" }) do her:AddRelationship(cls .. " D_NU 99") end
    end
    if LC.SetNPCStr then
        LC.SetNPCStr(her, "lc_pname", (LC.AdministratorName and LC.AdministratorName()) or "The City Administrator")
        LC.SetNPCStr(her, "lc_pjob", "City Administrator")
    end
    her.lcAdminHer = true
    -- the stunstick in her hand
    local stick = ents.Create("prop_dynamic")
    if IsValid(stick) then
        stick:SetModel("models/weapons/w_stunbaton.mdl")
        stick:SetPos(her:GetPos())
        stick:SetParent(her)
        if stick.AddEffects and EF_BONEMERGE then stick:AddEffects(EF_BONEMERGE) end
        stick:Spawn()
        her.lcStick = stick
    end
    return her
end

local function Remove(npc)
    if not IsValid(npc) then return end
    if IsValid(npc.lcStick) then npc.lcStick:Remove() end
    if LC.NPCs then LC.NPCs[npc] = nil end
    npc:Remove()
end

-- A walk of their own (hop by hop along the city's route, like LC.GoTo): she is nobody the city manages.
local function Go(w, to)
    w.there, w.hop, w.issued = false, 1, 0
    local route = LC.BuildRoute and LC.BuildRoute(w.npc:GetPos(), to, "soldier")
    if route == false then w.route = nil return false end
    w.route = route or { to }
    return true
end
local function Step(w, now)
    local npc = w.npc
    if not IsValid(npc) or w.there then return true end
    if not w.route then return false end
    local last = w.hop >= #w.route
    if npc:GetPos():DistToSqr(w.route[w.hop]) < (last and 60 * 60 or 96 * 96) then
        if last then w.there, w.route = true, nil return true end
        w.hop, w.issued = w.hop + 1, 0
    end
    if now >= w.issued then
        w.issued = now + 2
        npc:SetLastPosition(w.route[w.hop])
        npc:SetSchedule(SCHED_FORCED_GO)
    end
    return false
end

-- Her party goes: back the way it came, and removed out of sight. Returns what is leaving (or nil).
local function Leave(A)
    local party = A.party
    A.party = nil
    if not party then return nil end
    for _, w in ipairs(party) do
        w.there = not A.from
        if A.from and IsValid(w.npc) then Go(w, A.from) end
    end
    local L = { party = party, untilT = CurTime() + (A.from and 90 or 20) }
    Gone[#Gone + 1] = L
    return L
end

local function LeavingTick(now)
    for i = #Gone, 1, -1 do
        local L = Gone[i]
        local left = 0
        for _, w in ipairs(L.party) do
            if IsValid(w.npc) then
                local there = Step(w, now)
                if now > L.untilT or (there and not (LC.IsSeen and LC.IsSeen(w.npc:GetPos() + Vector(0, 0, 40)))) then
                    Remove(w.npc)
                else
                    left = left + 1
                end
            end
        end
        if left == 0 then table.remove(Gone, i) end
    end
end

------------------------------------------------------------------------
-- What follows: a stalker
------------------------------------------------------------------------

-- One of the city's own: gone from its people (not dead, and not coming back), and a stalker stands where it
-- stood, one of the Combine zones' own from then on (sv_livingcity_zonestalkers.lua).
local function TurnNPC(npc)
    local pos, yaw = npc:GetPos(), npc:GetAngles().y
    local p = npc.lcProfile
    if p and p.alive then p.alive, p.moved = false, os.time() end
    npc:Remove() -- (the city tidies up after one of its own that is gone: its cell is free again)
    local stalker = LC.ZoneStalkerAdopt and LC.ZoneStalkerAdopt(pos, yaw)
    if IsValid(stalker) then stalker:EmitSound("npc/stalker/breathing3.wav", 70) end
    return stalker
end

-- rec: what holds them, still the stay she questioned them in (nil: let out, escaped or gone since).
local function Then(who, A, rec)
    if A.npc then
        if A.st.questLock == A then A.st.questLock = nil end
        if rec and StalkersOn() then TurnNPC(who) end
        return
    end
    if not rec then return end
    if StalkersOn() and LC.StalkerScene then
        LC.StalkerScene(who) -- (the stalker's chair, as custody has it: sv_livingcity_custody.lua)
    elseif A.after then
        LC.Try(A.after)
    end
end

-- Not let out before she has been, or before what follows is done.
local function KeepIn(ply, pr, now)
    if pr.untilT < now + 60 then
        pr.untilT = now + 60
        ply:SetNW2Float("lc_jail_until", pr.untilT)
    end
end

local function LaterTick(now)
    for i = #Later, 1, -1 do
        local T = Later[i]
        local who, A = T.who, T.A
        local rec = Held(who, A)
        if rec ~= T.rec then rec = nil end -- (another stay in the cells by now: not this one's business)
        if rec and not A.npc then KeepIn(who, rec, now) end
        if not rec then
            Then(who, A, nil)
            table.remove(Later, i)
        elseif T.fired then
            -- (in the stalker's chair: kept in until it is done)
            if not rec or not who.lcStalkerScene then table.remove(Later, i) end
        else
            local party = false
            for _, w in ipairs(T.L and T.L.party or {}) do if IsValid(w.npc) then party = true end end
            if now >= T.at and (not party or now >= T.cap) then
                Then(who, A, rec)
                if not A.npc and IsValid(who) and who.lcStalkerScene then T.fired = true else table.remove(Later, i) end
            end
        end
    end
end

------------------------------------------------------------------------
-- How it ends
------------------------------------------------------------------------

local function TakeBack(A)
    local adm = A.by
    if not (A.gave and IsValid(adm)) then return end
    A.gave = nil
    if adm:HasWeapon(BATON) then adm:StripWeapon(BATON) end
    if A.held and adm:HasWeapon(A.held) then adm:SelectWeapon(A.held) end
end

-- Over, however it ended (or it never began: released, escaped, gone, or she never came). broke: they told the
-- truth; all: every question was put. wait: seconds before what follows.
local function Finish(who, A, broke, all, wait)
    if Q[who] ~= A then return end
    Q[who] = nil
    local rec = Held(who, A)
    if rec and not A.npc then rec.adminQ = "done" end
    ShutDoor(A)
    A.broke = broke
    if LC.LedgerAdd then
        if broke then LC.LedgerAdd("authority", BROKE, nil) elseif all then LC.LedgerAdd("authority", -HELD, nil) end
    end
    local adm = A.by
    if IsValid(adm) then
        TakeBack(A)
        net.Start("lc_intr_cp") -- (her menu closes, however it ended)
        net.WriteString("{\"done\":true}")
        net.Send(adm)
        local q = LC.QuestOf and LC.QuestOf[adm]
        if q and q.tmpl == TEMPLATE and q.data and q.data.prisoner == who then
            q.data.asked = true
            if broke then q.bonus = (q.bonus or 0) + 10 end
        end
    end
    local L = Leave(A)
    Withdraw()
    local now = CurTime()
    Later[#Later + 1] = { who = who, A = A, rec = rec, at = now + (wait or 0), L = L, cap = now + 60 }
end
local function Drop(who, A) Finish(who, A, nil, false, 0) end

-- A player's session's onEnd (sv_livingcity_custody.lua, EndInterrogation).
local function Over(ply, it)
    local A = Q[ply]
    if not A then return end
    it = it or {}
    local broke = (it.truths or 0) > 0 or it.talked == true
    local all = it.qs ~= nil
    for i = 1, #(it.qs or {}) do if not (it.asked and it.asked[i]) then all = false end end
    Finish(ply, A, broke, all, THEN_SECS)
end

-- The onEnd of a player Administrator's questioning of one of the city's own (sv_livingcity_prisonguard.lua).
local function OverNPC(who, A, s)
    s = s or A.s or {}
    local all = true
    for i = 1, #LC.AdminQuestions do if not (s.asked and s.asked[i]) then all = false end end
    Finish(who, A, s.last == "truth", all, THEN_SECS)
end

------------------------------------------------------------------------
-- A player is the Administrator
------------------------------------------------------------------------

-- She is at the cell: the door, the stunstick, and her questions.
function LC.AdminQuestioningLead(adm, who)
    local A = Q[who]
    local rec = A and Held(who, A)
    if not (rec and A.stage == "waiting") or not (LC.IsAdministrator and LC.IsAdministrator(adm)) then return false end
    if not A.npc and LC.Interrogations[who] then return false end
    -- (the prisoner out of the cell, on a work detail: not until she is with them, or it would end as she began)
    if adm:GetPos():DistToSqr(who:GetPos()) > NEAR * NEAR then return false end
    if A.npc then
        -- one of the city's own: questioned the way a guard questions it, with her questions
        if not LC.NPCInterrogationStart then return false end
        local opts = { qs = LC.AdminQuestions, admin = true, onEnd = function(_, s) OverNPC(who, A, s) end }
        if not LC.NPCInterrogationStart(adm, who, nil, opts) then return false end
        A.s = LC.NPCInterrogations[adm]
    end
    A.stage, A.by = "asking", adm
    local held = adm.GetActiveWeapon and adm:GetActiveWeapon()
    A.held = IsValid(held) and held:GetClass() or nil
    if not adm:HasWeapon(BATON) then
        adm:Give(BATON)
        A.gave = true
    end
    adm:SelectWeapon(BATON)
    local _, door = Spots(who, A, rec)
    OpenDoor(A, door)
    if not A.npc then
        local it = { hits = 0, resolve = 3, byPlayer = adm, led = true, untilT = CurTime() + 600, qs = Questions(who),
            admin = true, asker = ASKER, onEnd = Over }
        A.it = it
        LC.Interrogations[who] = it
        who:SetNW2Bool("lc_interrogated", true)
        if LC.InterrogationPushCP then LC.InterrogationPushCP(who, it) end
    end
    Withdraw()
    return true
end

-- A swing of her stunstick at the prisoner (weapon_lc_baton.lua asks before it does any damage): a blow of the
-- questioning, as the menu's, and never more than that. Past the most the questioning allows, a swing is only a
-- swing: nothing more, and nothing said about it.
function LC.AdminQuestioningBlow(adm, target)
    local it = LC.Interrogations and LC.Interrogations[target]
    if it and it.admin and it.byPlayer == adm then
        if LC.PlayerInterrogationDo and (it.hits or 0) < (LC.InterrogationMaxHits or 8) then LC.PlayerInterrogationDo(adm, "baton") end
        return true
    end
    local s = LC.NPCInterrogations and LC.NPCInterrogations[adm]
    if s and s.admin and s.npc == target then
        if LC.NPCInterrogationDo and (s.hits or 0) < (LC.NPCInterrogationMaxHits or 6) then LC.NPCInterrogationDo(adm, "baton") end
        return true
    end
    return false
end

local function Waiting()
    for who, A in pairs(Q) do
        if A.stage == "waiting" and not A.job and Held(who, A) then return who, A end
    end
    return nil
end

TEMPLATE = {
    id = "admin_assassin", factions = { admin = true }, first = true, recheck = true,
    available = function() return Waiting() ~= nil end,
    over = function(q)
        if q.data.asked then return true end
        local A = Q[q.data.prisoner]
        if not A or (A.by and A.by ~= q.owner) then return false, "the prisoner is gone" end
    end,
    build = function()
        local who, A = Waiting()
        local rec = who and Held(who, A)
        if not rec then return nil end
        local cell = CellPos(who, A, rec)
        return {
            title = "Question the would-be assassin", reward = 20, limit = 600, data = { prisoner = who },
            desc = "They tried to kill you and they're in the cells; question them yourself.",
            stages = {
                { kind = "goto", pos = cell, r = 200, text = "Go to their cell (marked)",
                  onEnter = function(q) local W = Q[q.data.prisoner] if W then W.job = q end end,
                  onDone = function(q) if IsValid(q.owner) then LC.AdminQuestioningLead(q.owner, q.data.prisoner) end end },
                { kind = "count", event = "admin_questioned", need = 1, text = "Ask your questions" },
            },
            -- (given up or out of time with the questions still going: they stop)
            onFinish = function(q)
                local W = Q[q.data.prisoner]
                if not W then return end
                if W.job == q then W.job = nil end
                if W.stage == "asking" and W.by == q.owner and not q.data.asked and LC.PlayerInterrogationDo then
                    LC.PlayerInterrogationDo(W.by, "done")
                end
            end,
        }
    end,
}
if LC.QuestTemplates then
    for i = #LC.QuestTemplates, 1, -1 do if LC.QuestTemplates[i].id == TEMPLATE.id then table.remove(LC.QuestTemplates, i) end end
    LC.QuestTemplates[#LC.QuestTemplates + 1] = TEMPLATE
end

------------------------------------------------------------------------
-- Nobody plays her
------------------------------------------------------------------------

local function Summon(who, A, rec, now)
    if LC.Running == false then return Drop(who, A) end -- (the city is stopped: nobody comes)
    local spots, door = Spots(who, A, rec)
    local from = LC.AlarmSquadSpot and LC.AlarmSquadSpot(spots[2]) or nil
    local her = Her(from or spots[1], (who:GetPos() - spots[1]):Angle().y)
    if not her then return Drop(who, A) end
    A.party = { { npc = her, spot = spots[1], there = not from } }
    local sp = LC.Spawners and LC.Spawners.soldier
    for i = 2, 3 do
        local at = from and (from + Vector((i - 2.5) * 90, 50, 0)) or spots[i]
        if sp and LC.ManpowerFree then
            local ok, npc, st = LC.Try(LC.ManpowerFree, sp, at, "ar2") -- (her escort: never from the reserve)
            if ok and IsValid(npc) and st then
                st.unmanaged, st.adminParty = true, true
                if LC.SetState then LC.SetState(npc, st, "event") end
                st.eventUntil = math.huge
                A.party[#A.party + 1] = { npc = npc, spot = spots[i], there = not from }
            end
        end
    end
    A.stage, A.from, A.arriveBy = "coming", from, from and (now + COME_SECS) or 0
    OpenDoor(A, door)
    if from then
        for _, w in ipairs(A.party) do
            if not Go(w, w.spot) then A.arriveBy = 0 end -- (no way in: placed at the cell door)
        end
    end
    Withdraw()
end

local function Coming(who, A, now)
    local all = true
    for _, w in ipairs(A.party) do if not Step(w, now) then all = false end end
    if not all and now < A.arriveBy then return end
    if not IsValid(A.party[1].npc) then return Drop(who, A) end
    for _, w in ipairs(A.party) do
        local npc = w.npc
        if IsValid(npc) then
            if npc:GetPos():DistToSqr(w.spot) > 80 * 80 then npc:SetPos(w.spot + Vector(0, 0, 4)) end
            w.route, w.there = nil, true
            npc:SetSchedule(SCHED_IDLE_STAND)
            if LC.Face then LC.Face(npc, who:GetPos()) end
        end
    end
    if A.npc then
        -- one of the city's own in the cell: nobody to answer on a menu. Her stunstick is heard, and she is done.
        A.stage, A.blows, A.nextBlow = "asking", 0, now + 3
        return
    end
    -- her questions, through the cell questioning's own code (sv_livingcity_interrogation.lua)
    local it = { hits = 0, resolve = 3, untilT = now + 150, next = now + 3, qs = Questions(who), admin = true,
        asker = ASKER, onEnd = Over }
    A.stage, A.it = "asking", it
    LC.Interrogations[who] = it
    who:SetNW2Bool("lc_interrogated", true)
end

------------------------------------------------------------------------
-- Brought in, and what happens then
------------------------------------------------------------------------

-- Called by sv_livingcity_custody.lua when a player is put in a cell. after: what custody had waiting for them
-- besides the stalker's chair (it comes only with lc_stalkers 0). True when they are hers to question (a unit's
-- questioning does not happen).
function LC.AdminQuestioningStart(ply, after)
    if not (IsValid(ply) and ply:IsPlayer() and LC.AdminNeverForgotten and LC.AdminNeverForgotten(ply)) then return false end
    if LC.PlayerIsStalker and LC.PlayerIsStalker(ply) then return false end -- (Combine property already)
    local pr = LC.Prisoners and LC.Prisoners[ply]
    if not pr or pr.adminQ or Q[ply] then return false end -- (once per stay in the cells)
    pr.adminQ = "due"
    Q[ply] = { stage = "due", at = CurTime() + WAIT, after = after }
    return true
end

-- Called by sv_livingcity_prison.lua when one of the city's own that tried to kill her (npc.lcRegicide) reaches
-- its cell. Once per stay; it is not let out until she has been (held as a job's prisoner is: st.questLock).
function LC.AdminQuestioningStartNPC(npc, st)
    if not (IsValid(npc) and st and npc.lcRegicide == true) or Q[npc] then return false end
    local cv = GetConVar("lc_custody_punish")
    if cv and not cv:GetBool() then return false end
    local stay = st.jailUntil or true
    if st.adminQ == stay then return false end
    st.adminQ = stay
    local A = { stage = "due", at = CurTime() + WAIT, npc = true, st = st }
    if st.questLock == nil then st.questLock = A end
    Q[npc] = A
    return true
end

function LC.AdminQuestioningTick(now)
    now = now or CurTime()
    for who, A in pairs(Q) do
        local rec = Held(who, A)
        if rec and not A.npc then KeepIn(who, rec, now) end
        if A.stage == "asking" and A.npc then
            if A.party then
                -- the city's own on one of the city's own: her stunstick, a few times
                if not rec or not IsValid(A.party[1].npc) or A.blows >= BLOWS then
                    if now >= A.nextBlow then Finish(who, A, nil, false, THEN_SECS) end
                elseif now >= A.nextBlow then
                    A.blows, A.nextBlow = A.blows + 1, now + 4
                    who:EmitSound("weapons/stunstick/stunstick_impact" .. math.random(1, 4) .. ".wav", 70)
                    who:SetHealth(math.max(10, who:Health() - 6))
                end
            else
                local adm = A.by
                if not (IsValid(adm) and LC.NPCInterrogations and LC.NPCInterrogations[adm] == A.s) then
                    -- (she left the server, or it ended some way that told nobody)
                    if adm ~= nil and LC.NPCInterrogations and LC.NPCInterrogations[adm] == A.s then LC.NPCInterrogations[adm] = nil end
                    OverNPC(who, A, A.s)
                elseif not rec or not adm:Alive() or adm:GetPos():DistToSqr(who:GetPos()) > AWAY * AWAY then
                    LC.NPCInterrogationDo(adm, "done")
                end
            end
        elseif A.stage == "asking" then
            if (LC.Interrogations and LC.Interrogations[who]) ~= A.it then
                Over(who, A.it) -- (ended some way that told nobody)
            elseif not rec or (A.party and not IsValid(A.party[1].npc)) then
                LC.EndInterrogation(who)
            end
        elseif not rec then
            Drop(who, A)
        elseif not Living(who, A) then
            -- (dead in the cell: dying doesn't end a sentence, and it doesn't get them out of this)
        elseif A.stage == "due" then
            if now >= A.at then
                if PlayerAdministrator() then
                    A.stage, A.dropAt = "waiting", now + OFFER_SECS
                    if LC.PostDirective then LC.PostDirective(TEMPLATE.id) end
                else
                    Summon(who, A, rec, now)
                end
            end
        elseif A.stage == "waiting" then
            if not PlayerAdministrator() then
                Summon(who, A, rec, now) -- (she left the server: the city's own comes)
            elseif A.job and not A.job.done then
                -- (at the cell with the prisoner out of it, on a work detail: it begins when she is with them)
                if (A.job.stage or 1) > 1 and IsValid(A.job.owner) then LC.AdminQuestioningLead(A.job.owner, who) end
            elseif now > A.dropAt then
                Drop(who, A)
            end
        elseif A.stage == "coming" then
            Coming(who, A, now)
        end
    end
    LeavingTick(now)
    LaterTick(now)
end

timer.Create("LivingCityAdminQuestioning", 0.5, 0, function()
    if next(Q) == nil and #Gone == 0 and #Later == 0 then return end
    local ok, err = LC.Try(LC.AdminQuestioningTick)
    if not ok and LC.Error then LC.Error("admin questioning", err) end
end)
