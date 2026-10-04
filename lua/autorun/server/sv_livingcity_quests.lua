--[[
    Living City: quests

    Radiant-style jobs built on the fly from the live map: a real citizen to
    arrest, a real checkpoint to sabotage, your actual ration line and housing
    blocks. Each faction gets its own board:

      Civil Protection: Directives    Overwatch: Protocols    Administrator: Agenda
      Resistance: Operations          Citizen: Assignments    Infested: Urges

    Some steps are choices with d20 checks (d20 + skill against a difficulty).
    Skills come from rank and three traits your choices build over time:
    Loyalty, Sympathy, Corruption.

    Built for crowded servers as much as singleplayer:
      - no job ever targets a player; violence is only ever against NPCs
      - each faction's board holds a limited number of postings, scaled to how
        many people are in that faction
      - violent jobs are capped city-wide (one per lc_quest_violent_ratio players)
      - others in your faction can join your job as a squad (lc_quest_squad)

    F3, !jobs or lcq_board opens your board.
]]

if CLIENT then return end

for _, n in ipairs({ "lcq_board", "lcq_accept", "lcq_abandon", "lcq_state", "lcq_choice_open", "lcq_choice", "lcq_request" }) do
    util.AddNetworkString(n)
end

LC = LC or {}
LC.QuestOf = LC.QuestOf or {}       -- [ply] = the quest they're on (as owner or squad member)
LC.ActiveQuests = LC.ActiveQuests or {}
LC.Postings = LC.Postings or {}     -- [faction] = { posting, ... }
LC.QuestTemplates = {}

local FLAGS = bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED)
local cvOn       = CreateConVar("lc_quests", "1", FLAGS, "Offer quests")
local cvViolent  = CreateConVar("lc_quest_violent_ratio", "8", FLAGS, "One violent job city-wide per this many players (always at least one)")
local cvSquad    = CreateConVar("lc_quest_squad", "3", FLAGS, "Most people on one job")
local cvCooldown = CreateConVar("lc_quest_cooldown", "30", FLAGS, "Seconds between jobs for one player")
local cvPacing   = CreateConVar("lc_story_pacing", "45", FLAGS, "Seconds before the next part of a story appears")

local BOARDS = {
    cp = "Directives", ota = "Protocols", admin = "Agenda",
    resistance = "Operations", citizen = "Assignments", zombie = "Urges",
}

local nextId = 1
local function Pick(t) return t[math.random(#t)] end

------------------------------------------------------------------------
-- Who's asking, and what they're good at
------------------------------------------------------------------------

function LC.QuestFaction(ply)
    if LC.FactionsActive and LC.FactionsActive() then
        local f = ply:GetNW2String("lcf_faction", "")
        if f ~= "" then return f end
    end
    if LC.PlayerIsZombie(ply) then return "zombie" end
    if LC.PlayerIsCP(ply) then return "cp" end
    return "citizen"
end

local function RankIndex(ply) return ply:GetNW2Int("lcf_rank", 1) end
local function Special(ply) return ply:GetNW2String("lcf_special", "") end

local TRAITS = { loyalty = true, sympathy = true, corruption = true }
function LC.Trait(ply, name) return tonumber(ply:GetPData("lcq_" .. name, 0)) or 0 end
function LC.AddTrait(ply, name, d)
    if not TRAITS[name] or not IsValid(ply) then return end
    ply:SetPData("lcq_" .. name, math.max(0, LC.Trait(ply, name) + d))
end

local SKILLS = {
    authority = function(ply)
        return math.floor(RankIndex(ply) / 2) + (LC.PlayerIsCP(ply) and 1 or 0) + math.floor(LC.Trait(ply, "loyalty") / 3)
    end,
    empathy = function(ply)
        return math.floor(LC.Trait(ply, "sympathy") / 2) + (Special(ply) == "chaplain" and 3 or 0)
    end,
    guile = function(ply)
        return math.floor(LC.Trait(ply, "corruption") / 2)
            + (LC.QuestFaction(ply) == "resistance" and math.floor(RankIndex(ply) / 2) or 0)
    end,
    nerve = function(ply) return math.floor((tonumber(ply:GetPData("lcq_done", 0)) or 0) / 5) end,
}

function LC.SkillMod(ply, skill)
    local fn = SKILLS[skill]
    return math.Clamp(fn and fn(ply) or 0, 0, 8)
end

------------------------------------------------------------------------
-- Story memory: what you've done, and where you are in each chain.
-- Saved by SteamID, so it follows you across maps and restarts.
------------------------------------------------------------------------

function LC.Story(ply)
    if ply.lcStory then return ply.lcStory end
    local raw = ply:GetPData("lcq_story", "")
    local t = raw ~= "" and util.JSONToTable(raw) or nil
    t = istable(t) and t or {}
    t.counters = istable(t.counters) and t.counters or {}
    t.chains = istable(t.chains) and t.chains or {}
    t.notified = istable(t.notified) and t.notified or {}
    t.flags = istable(t.flags) and t.flags or {}
    ply.lcStory = t
    return t
end

function LC.SaveStory(ply)
    if IsValid(ply) and ply.lcStory then ply:SetPData("lcq_story", util.TableToJSON(ply.lcStory)) end
end

function LC.Bump(ply, counter, n)
    if not IsValid(ply) or not ply:IsPlayer() then return end
    local st = LC.Story(ply)
    st.counters[counter] = (st.counters[counter] or 0) + (n or 1)
    LC.SaveStory(ply)
    hook.Run("LivingCityCounter", ply, counter, n or 1)
end

function LC.Counter(ply, counter) return LC.Story(ply).counters[counter] or 0 end

-- Story flags: get with LC.StoryFlag(ply, name), set with LC.StoryFlag(ply, name, value).
function LC.StoryFlag(ply, name, value)
    local st = LC.Story(ply)
    if value == nil then return st.flags[name] end
    st.flags[name] = value
    LC.SaveStory(ply)
    return value
end

------------------------------------------------------------------------
-- Reading the world
------------------------------------------------------------------------

local CRIMES = {
    "hoarding ration units", "unauthorized assembly", "possession of contraband", "failing a loyalty check",
    "breaking curfew", "anti-civil remarks", "trading ration units", "unregistered relocation",
    "tampering with a city terminal", "harboring an anticitizen",
}
-- Half-Life 2 has no proper elderly citizen model; these are its older faces.
LC.ELDERLY_MODELS = {
    "models/humans/group01/male_02.mdl", "models/humans/group01/male_07.mdl", "models/humans/group01/male_09.mdl",
}

local CONTRABAND = {
    { "an unregistered radio", "models/props_lab/citizenradio.mdl" },
    { "a stash of ration units", "models/props_junk/cardboard_box004a.mdl" },
    { "Resistance pamphlets", "models/props_c17/paper01.mdl" },
    { "a weapons cache", "models/items/ammocrate_smg1.mdl" },
}
local TRASH = {
    "models/props_junk/garbage_metalcan001a.mdl", "models/props_junk/garbage_milkcarton002a.mdl",
    "models/props_junk/garbage_newspaper001a.mdl", "models/props_junk/popcan01a.mdl",
}
local NOTES = {
    "The note says only: the canal gate opens at four.",
    "A child's drawing of a lambda, and an address you memorize and burn.",
    "Coordinates, and a single word: Ravenholm. You decide not to go.",
    "A list of unit numbers. Two are crossed out.",
}

local function CitizenID() return string.format("#%02d-%03d", math.random(10, 99), math.random(100, 999)) end

local DIRS = { "east", "north-east", "north", "north-west", "west", "south-west", "south", "south-east" }
local function Compass(from, to)
    local d = to - from
    local ang = math.deg(math.atan2(d.y, d.x)) % 360
    return DIRS[math.floor((ang + 22.5) / 45) % 8 + 1]
end

function LC.DescribePlace(pos, from)
    for _, z in ipairs(LC.ZonesOfKind("block")) do
        if (z.group or 0) > 0 and pos:DistToSqr(z.pos) < (z.r + 400) ^ 2 then return "near " .. LC.BlockName(z.group) end
    end
    if LC.InRebelZone(pos) then return "in rebel territory" end
    for _, z in ipairs(LC.ZonesOfKind("prison")) do
        if pos:DistToSqr(z.pos) < (z.r + 300) ^ 2 then return "by the prison" end
    end
    local function near(kind, r)
        for _, p in ipairs(LC.PointsOfKind(kind)) do if p.pos:DistToSqr(pos) < r * r then return true end end
        return false
    end
    if near("queue", 600) then return "by the ration line" end
    if near("checkpoint", 500) then return "at a checkpoint" end
    if near("spawn", 400) then return "outside an apartment doorway" end
    if from then return string.format("%d m %s of you", math.floor(from:Distance(pos) * 0.019), Compass(from, pos)) end
    return "somewhere in the city"
end
local Place = LC.DescribePlace

-- Citizen jobs never send you onto Combine ground or into the infestation, and
-- NPCs placed there (patients, targets) wouldn't survive it.
local function GoodSpot(p, role)
    return (role and role ~= "citizen") or not LC.CitizenSpotOK or LC.CitizenSpotOK(p)
end

local function Spot(ply, minD, maxD, role)
    local origin = ply:GetPos()
    for _ = 1, 40 do
        local p = LC.RandomWanderPos(role or "citizen")
        if not p then break end
        local d = p:Distance(origin)
        if d >= minD and d <= maxD and GoodSpot(p, role) then return p end
    end
    for _ = 1, 20 do
        local p = LC.RandomWanderPos(role or "citizen")
        if p and GoodSpot(p, role) then return p end
    end
    return LC.RandomWanderPos(role or "citizen")
end

-- Real bins already standing in the map (the server can see physics and
-- dynamic props; map-static ones are invisible to it).
local BIN_MODELS = { "trashcan", "trashbin", "dumpster", "garbagecan", "garbage_can" }
local BIN_CLASSES = { prop_physics = true, prop_dynamic = true, prop_physics_multiplayer = true, prop_physics_override = true }

local function FindBins(ply, minD, maxD, n)
    local origin = ply:GetPos()
    local out = {}
    for _, e in ipairs(ents.GetAll()) do
        if IsValid(e) and BIN_CLASSES[e:GetClass()] and not e.lcQuest then
            local m = string.lower(e:GetModel() or "")
            for _, pat in ipairs(BIN_MODELS) do
                if string.find(m, pat, 1, true) then
                    local d = e:GetPos():Distance(origin)
                    if d >= minD and d <= maxD and GoodSpot(e:GetPos()) then out[#out + 1] = e end
                    break
                end
            end
        end
    end
    -- shuffled, then the first n that aren't stacked on each other
    for i = #out, 2, -1 do local j = math.random(i); out[i], out[j] = out[j], out[i] end
    local picked = {}
    for _, e in ipairs(out) do
        if #picked >= n then break end
        local ok = true
        for _, o in ipairs(picked) do if o:GetPos():DistToSqr(e:GetPos()) < 150 * 150 then ok = false end end
        if ok then picked[#picked + 1] = e end
    end
    return picked
end

local function SpotsNear(center, n, radius)
    local out = {}
    for _ = 1, 60 do
        if #out >= n then break end
        local p = LC.RandomWanderPos("citizen")
        if p and p:DistToSqr(center) < radius * radius then
            local far = true
            for _, q in ipairs(out) do if q:DistToSqr(p) < 120 * 120 then far = false end end
            if far then out[#out + 1] = p end
        end
    end
    while #out < n do
        local a = math.random() * math.pi * 2
        out[#out + 1] = center + Vector(math.cos(a), math.sin(a), 0) * math.random(80, radius * 0.6)
    end
    return out
end

local FREE_STATES = { idle = true, moving = true, inline = true, busy = true }

local function RandomCitizen(near, maxD)
    local list = {}
    for npc, st in pairs(LC.NPCs or {}) do
        if IsValid(npc) and st.role == "citizen" and not st.test and not st.questLock and not st.leaving
            and FREE_STATES[st.state] and (not near or npc:GetPos():DistToSqr(near) < maxD * maxD) then
            list[#list + 1] = npc
        end
    end
    return #list > 0 and Pick(list) or nil
end

local function CountRole(role)
    local n = 0
    for npc, st in pairs(LC.NPCs or {}) do if IsValid(npc) and st.role == role and not st.test then n = n + 1 end end
    return n
end

local function SecurityCount()
    local n = 0
    for npc, st in pairs(LC.NPCs or {}) do if IsValid(npc) and LC.IsSecurity(st) then n = n + 1 end end
    return n
end

function LC.SeenBySecurity(ply, dist)
    local eye = ply:EyePos()
    for npc, st in pairs(LC.NPCs or {}) do
        if IsValid(npc) and LC.IsSecurity(st) and npc:GetPos():DistToSqr(ply:GetPos()) < dist * dist then
            local tr = util.TraceLine({ start = npc:EyePos(), endpos = eye, mask = MASK_OPAQUE, filter = npc })
            if tr.Fraction > 0.97 then return true end
        end
    end
    return false
end

local function NearestZone(kind, pos)
    local best, bd
    for _, z in ipairs(LC.ZonesOfKind(kind)) do
        local d = z.pos:DistToSqr(pos)
        if not bd or d < bd then best, bd = z, d end
    end
    return best
end

-- Somewhere safe for the Resistance: rebel territory if there is any, else far away.
local function SafeHouse(ply)
    local z = NearestZone("rebel", ply:GetPos())
    if z then return z.pos, math.max(150, z.r * 0.8), "rebel territory" end
    local p = Spot(ply, 1500, 5000)
    return p, 150, Place(p, ply:GetPos())
end

local function IsZombieNPC(npc)
    local c = npc:GetClass()
    return string.find(c, "zombie", 1, true) ~= nil or string.find(c, "headcrab", 1, true) ~= nil
end

------------------------------------------------------------------------
-- Quest machinery
------------------------------------------------------------------------

local function Members(q)
    local out = {}
    for _, p in ipairs(q.members) do if IsValid(p) then out[#out + 1] = p end end
    return out
end

local function AnyMemberNear(q, pos, r, crouch)
    for _, p in ipairs(Members(q)) do
        if p:Alive() and p:GetPos():DistToSqr(pos) < r * r and (not crouch or p:Crouching()) then return p end
    end
    return nil
end

local function Stage(q) return q.stages[q.stage] end

local function Lock(q, npc)
    local st = LC.NPCs[npc]
    if st then st.questLock = q; q.marked[npc] = true end
end

local function Unlock(q)
    for npc in pairs(q.marked) do
        local st = IsValid(npc) and LC.NPCs[npc]
        if st and st.questLock == q then
            st.questLock = nil
            if st.state == "event" then st.eventUntil = 0 end
        end
    end
    q.marked = {}
end

local function Freeze(npc, secs)
    local st = LC.NPCs[npc]
    if not st then return end
    if LC.LeaveLine then LC.LeaveLine(npc, st) end
    npc:SetSchedule(SCHED_IDLE_STAND)
    LC.SetState(npc, st, "event")
    st.eventUntil = CurTime() + secs
end

local function SpawnItem(q, model, pos, keep)
    local e = ents.Create("prop_physics")
    if not IsValid(e) then return nil end
    e:SetModel(model)
    e:SetPos(pos + Vector(0, 0, 10))
    e:Spawn()
    local phys = e.GetPhysicsObject and e:GetPhysicsObject()
    if IsValid(phys) then phys:EnableMotion(false) end
    if not keep then
        e.lcQuest = q
        q.ents[#q.ents + 1] = e
    end
    return e
end

local function Boom(pos)
    if sound and sound.Play then sound.Play("ambient/explosions/explode_4.wav", pos, 90) end
    if util.Effect and EffectData then
        local ed = EffectData()
        ed:SetOrigin(pos)
        util.Effect("Explosion", ed, true, true)
    end
end

local SendState, SendStateAll, EnterStage

local function Narrate(q, text)
    q.narration = text
    for _, p in ipairs(Members(q)) do p:ChatPrint("[" .. q.board .. "] " .. text) end
end

local function InsertStages(q, list)
    for i, s in ipairs(list) do table.insert(q.stages, q.stage + i, s) end
end

local function Finish(q, success, why)
    if q.done then return end
    q.done = true
    LC.ActiveQuests[q] = nil
    if q.posting then q.posting.q = nil; q.posting.dead = true end
    Unlock(q)
    for _, e in ipairs(q.ents) do
        if IsValid(e) then
            local est = LC.NPCs[e]
            if est and (est.state == "escorted" or est.state == "jailed") then
                -- an arrested story character stays in the world and serves their sentence
                est.unmanaged = nil
                est.leaveAt = CurTime() + 600
            else
                e:Remove()
            end
        end
    end

    for _, p in ipairs(Members(q)) do
        LC.QuestOf[p] = nil
        p.lcqNext = CurTime() + cvCooldown:GetFloat()
        if success then
            local share = (p == q.owner) and 1 or 0.75
            local xp = math.floor((q.reward + (q.bonus or 0)) * share)
            if xp > 0 and LC.AddXP then LC.AddXP(p, xp, q.title) end
            if xp > 0 and LC.Gamemode() == "darkrp" then pcall(function() p:addMoney(xp * 5) end) end
            p:SetPData("lcq_done", (tonumber(p:GetPData("lcq_done", 0)) or 0) + 1)
            p:ChatPrint(string.format("[%s] Complete: %s%s", q.board, q.title, xp > 0 and string.format(" (+%d XP)", xp) or ""))
            p:EmitSound("buttons/bell1.wav", 60)
        else
            p:ChatPrint(string.format("[%s] Failed: %s%s", q.board, q.title, why and (" (" .. why .. ")") or ""))
        end
        hook.Run(success and "LivingCityQuestComplete" or "LivingCityQuestFailed", p, q)
        SendState(p)
    end
    if q.chain and IsValid(q.owner) and LC.AdvanceChain then LC.AdvanceChain(q, success) end
    if success then
        for _, p in ipairs(Members(q)) do if LC.CheckUnlocks then LC.CheckUnlocks(p) end end
    end
    LC.Log("info", string.format("Quest %s: %s [%s]%s", success and "complete" or "failed", q.title, q.tmpl.id,
        why and (" (" .. why .. ")") or ""))
end
LC.FinishQuest = Finish

local function Advance(q)
    local st = Stage(q)
    if st and st.onDone then st.onDone(q, st) end
    if q.done then return end
    q.stage = q.stage + 1
    if q.stage > #q.stages then return Finish(q, true) end
    EnterStage(q)
end

local function OpenChoice(q, st)
    if not IsValid(q.owner) then return end
    local opts = {}
    for i, o in ipairs(st.options) do
        if not o.when or o.when(q) then
            opts[#opts + 1] = {
                i = i, text = o.text,
                skill = o.check and o.check[1], dc = o.check and o.check[2],
                mod = o.check and LC.SkillMod(q.owner, o.check[1]),
            }
        end
    end
    LC.SendCompressed("lcq_choice_open", { qid = q.id, title = q.title, prompt = st.prompt, options = opts }, { q.owner })
end

function EnterStage(q)
    local st = Stage(q)
    st.got, st.progress, st.seen = 0, 0, {}
    if st.onEnter and st.onEnter(q, st) == false then
        return Finish(q, false, st.failText or "the trail went cold")
    end
    -- heading for a housing block (or rebel territory, or the prison): walking
    -- into the zone counts, not just its exact center
    if st.pos and (st.kind == "goto" or st.kind == "deliver" or st.kind == "escort") then
        for _, z in ipairs(LC.Zones or {}) do
            if (z.kind == "block" or z.kind == "rebel" or z.kind == "prison") and z.pos:DistToSqr(st.pos) < 16 then
                st.r = math.max(st.r or 0, z.r * 0.9)
            end
        end
    end
    if st.kind == "collect" then
        st.items = {}
        for _, pos in ipairs(st.spots) do
            local e = SpawnItem(q, st.model or Pick(TRASH), pos)
            if e then st.items[e] = true end
        end
        if st.models then
            for e in pairs(st.items) do e:SetModel(Pick(st.models)) end
        end
    elseif st.kind == "pickup" then
        st.item = SpawnItem(q, st.model, st.pos)
    elseif st.kind == "choice" then
        OpenChoice(q, st)
    end
    if st.narrate then Narrate(q, st.narrate) end
    SendStateAll(q)
end

------------------------------------------------------------------------
-- State for the HUD tracker
------------------------------------------------------------------------

local function MarkerFor(q, st, viewer)
    if st.kind == "collect" and st.items then
        local best, bd
        for e in pairs(st.items) do
            if IsValid(e) then
                local d = e:GetPos():DistToSqr(viewer:GetPos())
                if not bd or d < bd then best, bd = e, d end
            end
        end
        return best, nil
    end
    local ent = st.npc or st.item
    if IsValid(ent) then return ent, nil end
    return nil, st.pos
end

function SendState(ply)
    local q = LC.QuestOf[ply]
    if not q or q.done then
        LC.SendCompressed("lcq_state", { active = false }, { ply })
        return
    end
    local st = Stage(q)
    local forgetting = (ply.lcForgetUntil or 0) > CurTime()
    local t = {
        active = true, id = q.id, title = q.title, board = q.board, objective = st and st.text or "",
        left = math.max(0, math.floor(q.expires - CurTime())), members = #Members(q),
        narration = q.narration, step = q.stage, steps = #q.stages, owner = q.owner == ply,
    }
    if st then
        if st.need then t.progress = string.format("%d/%d", st.got or 0, st.need) end
        if st.secs then t.progress = string.format("%ds / %ds", math.floor(st.progress or 0), st.secs) end
        local ent, pos = MarkerFor(q, st, ply)
        -- always send where it is too: far-away entities don't exist on the client
        if IsValid(ent) then
            t.ent = ent:EntIndex()
            pos = ent:GetPos()
        end
        if pos then t.pos = { pos.x, pos.y, pos.z } end
        t.choice = st.kind == "choice" and not st.resolved
    end
    if forgetting then
        t.objective = "You can't quite remember what you were doing."
        t.progress, t.pos, t.ent, t.forget = nil, nil, nil, true
    end
    LC.SendCompressed("lcq_state", t, { ply })
end

function SendStateAll(q)
    for _, p in ipairs(Members(q)) do SendState(p) end
end
LC.SendQuestState = function(ply) SendState(ply) end

------------------------------------------------------------------------
-- Ticking quests
------------------------------------------------------------------------

local function PollEscort(q, st)
    local npc = st.npc
    local nst = IsValid(npc) and LC.NPCs[npc]
    if not nst then return Finish(q, false, "you lost them") end
    local leader, bd
    for _, p in ipairs(Members(q)) do
        if p:Alive() then
            local d = p:GetPos():DistToSqr(npc:GetPos())
            if not bd or d < bd then leader, bd = p, d end
        end
    end
    LC.SetState(npc, nst, "event")
    nst.eventUntil = CurTime() + 2
    if leader then
        -- follow like a person: aim for a spot just behind you on their side,
        -- only re-plan when you've actually moved on, run only to catch up,
        -- and stop and wait when they're close
        local npos, lpos = npc:GetPos(), leader:GetPos()
        local d = math.sqrt(bd)
        local moving = npc:IsCurrentSchedule(SCHED_FORCED_GO) or npc:IsCurrentSchedule(SCHED_FORCED_GO_RUN)
        if d > 100 then
            local dir = npos - lpos
            dir.z = 0
            if dir:LengthSqr() < 1 then dir = Vector(1, 0, 0) end
            local goal = lpos + dir:GetNormalized() * 60
            local run = not st.walkOnly and (d > 450 or (st.running and d > 250))
            if not moving or not st.goal or st.goal:DistToSqr(goal) > 90 * 90 or run ~= st.running then
                npc:SetLastPosition(goal)
                npc:SetSchedule(run and SCHED_FORCED_GO_RUN or SCHED_FORCED_GO)
                st.goal = goal
            end
            st.running = run
        elseif moving then
            npc:SetSchedule(SCHED_IDLE_STAND)
            st.goal, st.running = nil, false
            if LC.Face then LC.Face(npc, lpos) end
        end
    end
    if npc:GetPos():DistToSqr(st.pos) < (st.r or 200) ^ 2 then
        if st.vanish then
            q.marked[npc] = nil
            npc:Remove()
        end
        Advance(q)
    end
end

local function Poll(q, now)
    if now > q.expires then return Finish(q, false, "out of time") end
    local mem = Members(q)
    if #mem == 0 then return Finish(q, false, "nobody left on the job") end
    if not IsValid(q.owner) or not table.HasValue(mem, q.owner) then q.owner = mem[1] end
    if q.failOnArrest then
        for _, p in ipairs(mem) do
            if LC.Prisoners and LC.Prisoners[p] then return Finish(q, false, "taken into custody") end
        end
    end

    if q.tick then q.tick(q, now) end
    if q.done then return end
    local st = Stage(q)
    if not st then return end
    local k = st.kind
    if k == "tail" then
        -- follow someone: close enough to keep them in sight, far enough not to be noticed
        local npc = st.npc
        if not IsValid(npc) or not LC.NPCs[npc] then return Finish(q, false, "you lost them") end
        local best
        for _, p in ipairs(mem) do
            if p:Alive() then
                local d = p:GetPos():Distance(npc:GetPos())
                if not best or d < best then best = d end
            end
        end
        best = best or 1e9
        if best < st.min then
            st.close = (st.close or 0) + 0.5
            if st.close >= 2 then
                st.close = 0
                if st.onNoticed then return st.onNoticed(q, st) end
                return Finish(q, false, "they spotted you")
            end
        else
            st.close = 0
        end
        if best > st.lost then
            st.away = (st.away or 0) + 0.5
            if st.away >= 12 then return Finish(q, false, "you lost them") end
        else
            st.away = 0
        end
        if best >= st.min and best <= st.max then
            st.progress = st.progress + 0.5
            if st.progress >= st.secs then Advance(q) end
        end
        return
    end
    if k == "goto" or k == "deliver" then
        if AnyMemberNear(q, st.pos, st.r or 120) then Advance(q) end
    elseif k == "hold" then
        if AnyMemberNear(q, st.pos, st.r or 150, st.crouch) then
            st.progress = st.progress + 0.5
            if st.progress >= st.secs then Advance(q) end
        end
    elseif k == "survive" then
        for _, p in ipairs(mem) do
            if p:Alive() and (not st.cond or st.cond(q, p)) then
                st.progress = st.progress + 0.5
                if st.progress >= st.secs then return Advance(q) end
                break
            end
        end
    elseif k == "target" then
        local npc = st.npc
        if not IsValid(npc) or not LC.NPCs[npc] then return Finish(q, false, st.lostText or "the target is gone") end
        if st.action == "reach" and AnyMemberNear(q, npc:GetPos(), st.r or 150) then
            Advance(q)
        elseif st.action == "arrest" then
            local s = LC.NPCs[npc].state
            if s == "jailed" and not st.armed then
                Narrate(q, "Another unit brought them in. Credit shared.")
                q.reward = math.floor(q.reward / 2)
                Advance(q)
            end
        end
    elseif k == "escort" then
        PollEscort(q, st)
    elseif k == "count" and st.poll then
        st.poll(q, st)
    end
end

timer.Create("LivingCityQuests", 0.5, 0, function()
    local now = CurTime()
    local tick = math.floor(now * 2) % 2 == 0
    for q in pairs(LC.ActiveQuests) do
        local ok, err = pcall(Poll, q, now)
        if not ok then
            LC.Error("quest " .. tostring(q.tmpl and q.tmpl.id), err)
            Finish(q, false, "something went wrong")
        elseif tick and not q.done then
            local st = Stage(q)
            if st and (st.kind == "hold" or st.kind == "survive" or st.kind == "collect" or st.kind == "escort"
                or st.kind == "target" or st.kind == "tail") then
                SendStateAll(q)
            end
        end
    end
end)

------------------------------------------------------------------------
-- Things happening in the world
------------------------------------------------------------------------

function LC.QuestEvent(name, ply, a, b)
    local q = IsValid(ply) and LC.QuestOf[ply]
    if not q or q.done then return end
    local st = Stage(q)
    if not st then return end

    if st.kind == "count" and st.event == name then
        if st.filter and not st.filter(q, ply, a, b) then return end
        if st.distinct and a ~= nil then
            if st.seen[a] then return end
            st.seen[a] = true
        end
        st.got = st.got + 1
        if st.got >= st.need then Advance(q) else SendStateAll(q) end
    elseif st.kind == "target" and IsValid(st.npc) and a == st.npc then
        if st.action == "arrest" and name == "arrested" then
            Advance(q)
        elseif st.action == "free" and name == "used_npc" then
            local nst = LC.NPCs[st.npc]
            if nst and (nst.state == "jailed" or nst.state == "escorted") then
                LC.Release(st.npc, nst)
                nst.jailUntil = nil
                Freeze(st.npc, 5)
                Advance(q)
            end
        elseif st.action == "use" and name == "used_npc" then
            Advance(q)
        end
    elseif st.kind == "pickup" and name == "used_item" and a == st.item then
        a:Remove()
        q.data.carrying = true
        Advance(q)
    elseif st.kind == "collect" and name == "used_item" and st.items and st.items[a] then
        st.items[a] = nil
        a:Remove()
        st.got = st.got + 1
        if st.got >= st.need then Advance(q) else SendStateAll(q) end
    end
end

hook.Add("LivingCityPlayerUsedNPC", "LivingCityQuests", function(ply, npc, st) LC.QuestEvent("used_npc", ply, npc, st) end)
hook.Add("LivingCityIncarcerated", "LivingCityQuests", function(target, secs, reason, arrester)
    if IsValid(arrester) and arrester:IsPlayer() then LC.QuestEvent("arrested", arrester, target) end
end)
hook.Add("OnNPCKilled", "LivingCityQuests", function(npc, attacker)
    if IsValid(attacker) and attacker:IsPlayer() then LC.QuestEvent("killed", attacker, npc) end
end)
hook.Add("LivingCityHealed", "LivingCityQuests", function(healer, target, amount) LC.QuestEvent("healed", healer, target, amount) end)
hook.Add("LivingCityPreached", "LivingCityQuests", function(ply) LC.QuestEvent("preached", ply, nil) end)
hook.Add("LivingCityServed", "LivingCityQuests", function(npc)
    for q in pairs(LC.ActiveQuests) do
        local st = Stage(q)
        if st and st.kind == "count" and st.event == "served" and AnyMemberNear(q, st.pos, st.r or 300) then
            LC.QuestEvent("served", q.owner, npc)
        end
    end
end)
hook.Add("PlayerUse", "LivingCityQuestItems", function(ply, ent)
    if not ent.lcQuest then return end
    if LC.QuestOf[ply] == ent.lcQuest then LC.QuestEvent("used_item", ply, ent) end
    return false
end)

hook.Add("PlayerDisconnected", "LivingCityQuests", function(ply)
    local q = LC.QuestOf[ply]
    if not q then return end
    LC.QuestOf[ply] = nil
    for i, p in ipairs(q.members) do if p == ply then table.remove(q.members, i) break end end
    local left = 0
    for _, p in ipairs(q.members) do if IsValid(p) and p ~= ply then left = left + 1 end end
    if left == 0 then Finish(q, false) elseif q.owner == ply then q.owner = nil end
end)

------------------------------------------------------------------------
-- Building blocks for templates
------------------------------------------------------------------------

local function Goto(pos, text, r) return { kind = "goto", pos = pos, r = r or 120, text = text } end
local function Deliver(pos, text, r) return { kind = "deliver", pos = pos, r = r or 150, text = text } end
local function Hold(pos, secs, text, r, crouch) return { kind = "hold", pos = pos, secs = secs, r = r or 150, crouch = crouch, text = text } end
local function Count(event, need, text, filter, distinct)
    return { kind = "count", event = event, need = need, text = text, filter = filter, distinct = distinct ~= false }
end
local function Choice(prompt, options) return { kind = "choice", prompt = prompt, options = options, text = "Decide what to do" } end

local function IsCitizenNPC(_, _, npc) local st = LC.NPCs[npc] return st ~= nil and st.role == "citizen" end
local function IsCopNPC(_, _, npc) local st = LC.NPCs[npc] return st ~= nil and st.role == "cop" end

local function T(def)
    def.factions = def.factions or {}
    LC.QuestTemplates[#LC.QuestTemplates + 1] = def
end

-- Pick a random NPC citizen when a stage begins, give them a made-up identity.
local function FindCitizenStage(text, r, onFound)
    return {
        kind = "target", action = "reach", r = r or 150, text = text,
        onEnter = function(q, st)
            local npc = q.data.target
            if not IsValid(npc) then npc = RandomCitizen() end
            if not npc then return false end
            Lock(q, npc)
            q.data.target = npc
            st.npc = npc
        end,
        onDone = function(q, st) if onFound then onFound(q, st) end end,
    }
end

local function ArrestStage(text)
    return {
        kind = "target", action = "arrest", text = text or "Detain them with the Arrest Baton (right click)",
        onEnter = function(q, st) st.npc = q.data.target; if not IsValid(st.npc) then return false end end,
    }
end

local function Flee(q)
    local npc = q.data.target
    local st = IsValid(npc) and LC.NPCs[npc]
    if not st then return end
    st.eventUntil = 0
    LC.GoTo(npc, st, LC.RandomWanderPos("citizen"), true, nil)
end

------------------------------------------------------------------------
-- Civil Protection: Directives
------------------------------------------------------------------------

T{
    id = "cp_patrol", factions = { cp = true, ota = true },
    build = function(ply)
        local stops = {}
        local beats = {}
        for _, p in ipairs(LC.PointsOfKind("patrol")) do if (p.group or 0) > 0 then beats[p.group] = true end end
        local groups = table.GetKeys(beats)
        if #groups > 0 then
            for _, p in ipairs(LC.PointsOfKind("patrol", Pick(groups))) do
                if #stops < 4 then stops[#stops + 1] = p.pos end
            end
        end
        while #stops < 3 do
            local s = Spot(ply, 500, 3000)
            if not s then return nil end
            stops[#stops + 1] = s
        end
        local stages = {}
        for i, s in ipairs(stops) do stages[i] = Goto(s, string.format("Patrol stop %d of %d, %s", i, #stops, Place(s, ply:GetPos())), 150) end
        return {
            title = "Patrol sweep " .. Place(stops[1], ply:GetPos()), reward = 15 + 5 * #stops, limit = 240 + 60 * #stops,
            desc = "Walk the route and be seen. Visibility is the deterrent.", stages = stages,
            intro = Pick({ "Dispatch wants boots on the street. Yours will do.", "Overwatch reports elevated noncompliance. Show them the uniform." }),
        }
    end,
}

T{
    id = "cp_inspect", factions = { cp = true },
    available = function() return LC.Running and CountRole("citizen") >= 3 end,
    build = function()
        local need = math.random(3, 5)
        return {
            title = "Civil status inspections", reward = 10 + 5 * need, limit = 360,
            desc = string.format("Stop %d citizens and check their papers. Nobody is above suspicion.", need),
            stages = { Count("used_npc", need, "Stop citizens for inspection (walk up and press E)", IsCitizenNPC) },
        }
    end,
}

T{
    id = "cp_apprehend", factions = { cp = true }, violent = true,
    available = function() return LC.Running and CountRole("citizen") >= 1 and LC.PrisonAvailable() end,
    build = function(ply)
        local id, crime = CitizenID(), Pick(CRIMES)
        local stash = Pick(CONTRABAND)
        return {
            title = "Apprehend citizen " .. id, reward = 35, limit = 420,
            desc = string.format("Citizen %s is wanted for %s. An informant has marked them for you.", id, crime),
            stages = {
                FindCitizenStage("Find citizen " .. id .. " (marked)", 140, function(q) Freeze(q.data.target, 40) end),
                Choice(string.format("Citizen %s freezes. Their eyes go to your baton, then to the street behind you.", id), {
                    { text = "Detain them." },
                    { text = "Make them name their supplier.", check = { "authority", 12 },
                      success = function(q, p)
                          local spot = Spot(p, 300, 1500)
                          Narrate(q, "They crack. There's " .. stash[1] .. " " .. Place(spot, p:GetPos()) .. ".")
                          LC.AddTrait(p, "loyalty", 1)
                          q.bonus = (q.bonus or 0) + 15
                          InsertStages(q, { { kind = "collect", spots = { spot }, model = stash[2], need = 1,
                              text = "Seize " .. stash[1] .. " (press E)" } })
                      end,
                      fail = function(q)
                          Narrate(q, "They shove past you and run!")
                          Flee(q)
                      end },
                    { text = "Take their ration units and walk away.",
                      pick = function(q, p)
                          LC.AddTrait(p, "corruption", 1)
                          LC.Bump(p, "bribes")
                          q.reward = 10
                          Narrate(q, "The units are warm from their pocket. Nobody will ever know. You will.")
                          return "complete"
                      end },
                    { text = "Let them go.",
                      pick = function(q, p)
                          LC.AddTrait(p, "sympathy", 1)
                          LC.Bump(p, "mercies")
                          q.reward = 0
                          Narrate(q, "You look away. They're gone before you look back.")
                          return "complete"
                      end },
                }),
                ArrestStage(),
            },
        }
    end,
}

T{
    id = "cp_checkpoint", factions = { cp = true, ota = true },
    available = function() return #LC.PointsOfKind("checkpoint") > 0 end,
    build = function(ply)
        local p = Pick(LC.PointsOfKind("checkpoint"))
        local secs = math.random(9, 14) * 10
        return {
            title = "Checkpoint duty " .. Place(p.pos, ply:GetPos()), reward = 25, limit = secs + 240,
            desc = "Hold the checkpoint. Nobody passes without being looked at.",
            stages = { Goto(p.pos, "Report to the checkpoint", 250), Hold(p.pos, secs, "Hold the checkpoint", 260) },
        }
    end,
}

T{
    id = "cp_contraband", factions = { cp = true },
    build = function(ply)
        local center = Spot(ply, 500, 2500)
        if not center then return nil end
        local kind = Pick(CONTRABAND)
        return {
            title = "Contraband sweep " .. Place(center, ply:GetPos()), reward = 30, limit = 420,
            desc = "An informant reports " .. kind[1] .. " hidden around the area. Find all three.",
            stages = { { kind = "collect", spots = SpotsNear(center, 3, 700), model = kind[2], need = 3,
                text = "Confiscate " .. kind[1] .. " (press E)" } },
        }
    end,
}

T{
    id = "cp_disturbance", factions = { cp = true }, violent = true,
    available = function() return LC.Running and LC.PrisonAvailable() end,
    build = function(ply)
        local center = Spot(ply, 800, 3000)
        if not center then return nil end
        return {
            title = "Disturbance " .. Place(center, ply:GetPos()), reward = 40, limit = 240,
            desc = "Reports of a disturbance. Respond quickly.",
            stages = {
                Goto(center, "Respond to the disturbance (hurry)", 300),
                {
                    kind = "target", action = "arrest", text = "Catch the suspect and detain them",
                    onEnter = function(q, st)
                        local npc = RandomCitizen(center, 1200)
                        if not npc then npc = LC.Spawners.citizen(center + Vector(0, 0, 4)) end
                        if not IsValid(npc) then return false end
                        Lock(q, npc)
                        q.data.target = npc
                        st.npc = npc
                        Flee(q)
                    end,
                    narrate = "Someone breaks from the crowd and runs!",
                },
            },
        }
    end,
}

T{
    id = "cp_rationduty", factions = { cp = true },
    available = function() return LC.Running and next(LC.Lines) ~= nil end,
    build = function(ply)
        local g = Pick(table.GetKeys(LC.Lines))
        local front = LC.Lines[g].slots[1].pos
        return {
            title = "Ration line supervision", reward = 30, limit = 600,
            desc = "Keep order at ration line " .. g .. " while units are distributed.",
            stages = {
                Goto(front, "Report to ration line " .. g, 220),
                Choice("The line is restless. A woman at the front is shaking, and the man behind her keeps looking at your hands.", {
                    { text = "Keep order, by the book.", pick = function(q, p) LC.AddTrait(p, "loyalty", 1) end },
                    { text = "Calm the line with a few quiet words.", check = { "empathy", 11 },
                      success = function(q, p)
                          LC.AddTrait(p, "sympathy", 1)
                          q.bonus = (q.bonus or 0) + 10
                          Narrate(q, "The shaking stops. Somebody actually says thank you.")
                      end,
                      fail = function(q) Narrate(q, "Someone spits near your boots. The line goes quiet anyway.") end },
                    { text = "Pocket a few ration units while nobody's counting.",
                      pick = function(q, p) LC.AddTrait(p, "corruption", 1) LC.Bump(p, "bribes") end },
                }),
                { kind = "count", event = "served", need = 3, pos = front, r = 320, distinct = false,
                  text = "Supervise the distribution (stay near the front)" },
            },
        }
    end,
}

T{
    id = "cp_infest", factions = { cp = true, ota = true }, violent = true,
    available = function() return #LC.ZonesOfKind("infest") > 0 and CountRole("zombie") > 0 end,
    build = function(ply)
        local z = Pick(LC.ZonesOfKind("infest"))
        return {
            title = "Containment " .. Place(z.pos, ply:GetPos()), reward = 40, limit = 480,
            desc = "Infestation is spreading past the line. Push it back.",
            stages = {
                Goto(z.pos, "Reach the infestation", math.max(200, z.r)),
                Count("killed", 3, "Put down the infested", function(_, _, npc) return IsZombieNPC(npc) end),
            },
        }
    end,
}

T{
    id = "cp_transfer", factions = { cp = true },
    available = function() return LC.Running and CountRole("citizen") >= 1 and LC.PrisonAvailable() end,
    build = function(ply)
        local id = CitizenID()
        return {
            title = "Detainee transfer: " .. id, reward = 25, limit = 420,
            desc = "Another unit detained citizen " .. id .. " and was called away. Take them into custody.",
            stages = {
                FindCitizenStage("Find detainee " .. id .. " (marked)", 140, function(q) Freeze(q.data.target, 60) end),
                Choice("The detainee was flagged by an informant. They swear they've done nothing, and their voice is steady.", {
                    { text = "Process them." },
                    { text = "Hear them out.", check = { "empathy", 14 },
                      success = function(q, p)
                          LC.AddTrait(p, "sympathy", 1)
                          q.bonus = (q.bonus or 0) + 10
                          Narrate(q, "Their story holds. The informant owed them money. You note it in the file. It won't matter.")
                      end,
                      fail = function(q) Narrate(q, "Halfway through, they contradict themselves. You stop listening.") end },
                    { text = "Lean on them for names.", check = { "authority", 10 },
                      success = function(q, p)
                          LC.AddTrait(p, "loyalty", 1)
                          q.bonus = (q.bonus or 0) + 10
                          Narrate(q, "Two names. You'll see them on a directive soon.")
                      end,
                      fail = function(q) Narrate(q, "They go silent. Smarter than they look.") end },
                }),
                ArrestStage(),
            },
        }
    end,
}

------------------------------------------------------------------------
-- Overwatch: Protocols    Administrator: Agenda
------------------------------------------------------------------------

T{
    id = "ota_raid", factions = { ota = true }, violent = true,
    available = function() return #LC.ZonesOfKind("rebel") > 0 end,
    build = function(ply)
        local z = Pick(LC.ZonesOfKind("rebel"))
        return {
            title = "Incursion " .. Place(z.pos, ply:GetPos()), reward = 50, limit = 420,
            desc = "Enter anticitizen territory and hold it. Sixty seconds.",
            stages = {
                Goto(z.pos, "Enter rebel territory", math.max(150, z.r * 0.8)),
                { kind = "survive", secs = 60, text = "Hold position inside rebel territory",
                  cond = function(_, p) return LC.InRebelZone(p:GetPos()) end },
            },
        }
    end,
}

T{
    id = "admin_address", factions = { admin = true },
    build = function(ply)
        local spots = LC.PointsOfKind("idle")
        local pos = #spots > 0 and Pick(spots).pos or Spot(ply, 300, 2000)
        if not pos then return nil end
        return {
            title = "Address the citizens", reward = 20, limit = 360,
            desc = "The people need to hear their Administrator. Go out among them.",
            stages = {
                Goto(pos, "Go to the plaza", 150),
                Hold(pos, 40, "Deliver your address", 220),
                Choice("The crowd watches you in silence. How do you end it?", {
                    { text = "Announce additional rations.", pick = function(q, p)
                        LC.AddTrait(p, "sympathy", 1)
                        if LC.Running then LC.StartEvent("rations") end
                        return "complete" end },
                    { text = "Remind them of their duty to the city.", pick = function(q, p)
                        LC.AddTrait(p, "loyalty", 1)
                        if LC.Running then LC.StartEvent("sweep") end
                        return "complete" end },
                    { text = "Declare a curfew. Effective immediately.", pick = function(q, p)
                        LC.AddTrait(p, "loyalty", 2)
                        if LC.Running then LC.StartEvent("curfew") end
                        return "complete" end },
                }),
            },
        }
    end,
}

T{
    id = "admin_review", factions = { admin = true },
    available = function() return LC.Running and CountRole("cop") >= 1 end,
    build = function()
        local need = math.min(3, math.max(1, CountRole("cop")))
        return {
            title = "Review the units", reward = 15, limit = 360,
            desc = "See for yourself that Civil Protection is doing its job.",
            stages = { Count("used_npc", need, "Speak with Civil Protection units (press E)", IsCopNPC) },
        }
    end,
}

------------------------------------------------------------------------
-- Resistance: Operations
------------------------------------------------------------------------

T{
    id = "res_supply", factions = { resistance = true },
    build = function(ply)
        local a = Spot(ply, 600, 2500)
        if not a then return nil end
        local dest, r, where = SafeHouse(ply)
        return {
            title = "Supply run", reward = 35, limit = 480, failOnArrest = true,
            desc = "A crate of medical supplies is waiting " .. Place(a, ply:GetPos()) .. ". Bring it home to " .. where .. ".",
            stages = {
                LC.QB.Contact("Meet your contact and take the crate (press E)", a, "citizen", "'Don't thank me. Don't look back, either.'", { rebel = true }),
                Choice("The crate is heavier than it should be. There's a unit posted at the end of the street.", {
                    { text = "Walk it out in plain sight." },
                    { text = "Bury it under a coat and some laundry.", check = { "guile", 11 },
                      success = function(q) Narrate(q, "Nobody looks twice at a tired citizen with laundry.") end,
                      fail = function(q, p)
                          Narrate(q, "A unit shouts after you. Run!")
                          LC.ReportCrime(p, "Carrying contraband", 120)
                      end },
                }),
                LC.QB.Contact("Hand it to the quartermaster at " .. where .. " (press E)", dest, "citizen", "He's already prying the lid up. 'Good. We needed this yesterday.'", { rebel = true }),
            },
        }
    end,
}

T{
    id = "res_propaganda", factions = { resistance = true },
    build = function(ply)
        local spots = { Spot(ply, 400, 2500), Spot(ply, 400, 2500), Spot(ply, 400, 2500) }
        if not spots[3] then return nil end
        local stages = {}
        for i, s in ipairs(spots) do
            stages[i] = Hold(s, 3, string.format("Post flyer %d of 3 %s (crouch at the spot)", i, Place(s, ply:GetPos())), 90, true)
            stages[i].onDone = function(q)
                local flyer = SpawnItem(q, "models/props_c17/paper01.mdl", s, true)
                if IsValid(flyer) then SafeRemoveEntityDelayed(flyer, 600) end
                local p = q.owner
                if IsValid(p) and LC.SeenBySecurity(p, 700) then
                    Narrate(q, "A unit saw that.")
                    LC.ReportCrime(p, "Distributing propaganda", 150)
                end
            end
        end
        return {
            title = "Paper the walls", reward = 30, limit = 480, failOnArrest = true,
            desc = "Three flyers, three places people will see them. Don't get seen putting them up.",
            stages = stages,
        }
    end,
}

T{
    id = "res_sabotage", factions = { resistance = true }, violent = true,
    available = function() return #LC.PointsOfKind("checkpoint") > 0 end,
    build = function(ply)
        local cp = Pick(LC.PointsOfKind("checkpoint"))
        local dest, r, where = SafeHouse(ply)
        local plant = Hold(cp.pos, 5, "Plant the charge at the checkpoint (crouch)", 100, true)
        plant.onDone = function(q)
            Boom(cp.pos + Vector(0, 0, 20))
            cp.disabledUntil = CurTime() + 300
            local p = q.owner
            if IsValid(p) then
                LC.ReportCrime(p, "Sabotage", 240)
                if LC.Running then LC.MakeCopsHostile(p, cp.pos, 1500) end
            end
            Narrate(q, "The checkpoint goes up in a shower of sparks. Every unit in the sector heard that.")
        end
        return {
            title = "Sabotage " .. Place(cp.pos, ply:GetPos()), reward = 45, limit = 480, failOnArrest = true,
            desc = "Take that checkpoint offline for a while, then get clear.",
            stages = { plant, Deliver(dest, "Get clear: reach " .. where, r) },
        }
    end,
}

T{
    id = "res_jailbreak", factions = { resistance = true },
    available = function()
        if #LC.PointsOfKind("cell") == 0 then return false end
        for npc, st in pairs(LC.NPCs or {}) do if IsValid(npc) and st.state == "jailed" then return true end end
        return LC.Running and CountRole("citizen") >= 1
    end,
    build = function(ply)
        local id = CitizenID()
        local dest, r, where = SafeHouse(ply)
        return {
            title = "Jailbreak: " .. id, reward = 50, limit = 600, failOnArrest = true,
            desc = "Citizen " .. id .. " was taken last night. They know too much to stay in there.",
            stages = {
                {
                    kind = "target", action = "free", text = "Break them out (press E on them in their cell)",
                    onEnter = function(q, st)
                        local npc
                        for n, s in pairs(LC.NPCs) do if IsValid(n) and s.state == "jailed" and not s.questLock then npc = n break end end
                        if not npc then
                            npc = RandomCitizen()
                            if not npc or not LC.ArrestNPC(npc, nil) then return false end
                        end
                        Lock(q, npc)
                        q.data.target = npc
                        st.npc = npc
                    end,
                    onDone = function(q)
                        if IsValid(q.owner) then LC.ReportCrime(q.owner, "Aiding an escape", 240) end
                        Narrate(q, "The lock gives. Alarms don't, yet. Move.")
                    end,
                },
                { kind = "escort", pos = dest, r = r, vanish = true, text = "Get them to " .. where,
                  onEnter = function(q, st) st.npc = q.data.target; if not IsValid(st.npc) then return false end end },
            },
        }
    end,
}

T{
    id = "res_recruit", factions = { resistance = true },
    available = function() return LC.Running and CountRole("citizen") >= 3 end,
    build = function()
        local last = 0
        return {
            title = "Sound out the neighbors", reward = 25, limit = 480,
            desc = "Find three people who might be ready. Talk to them where Civil Protection can't see.",
            stages = { Count("used_npc", 3, "Quietly talk to citizens (press E) away from Civil Protection", function(q, p, npc)
                if not IsCitizenNPC(q, p, npc) then return false end
                if LC.SeenBySecurity(p, 700) then
                    if CurTime() > last then p:ChatPrint("[Operations] A unit is watching. Not here."); last = CurTime() + 5 end
                    return false
                end
                return true
            end) },
        }
    end,
}

T{
    id = "res_deaddrop", factions = { resistance = true },
    build = function(ply)
        local a, b = Spot(ply, 500, 2500), Spot(ply, 500, 2500)
        if not a or not b then return nil end
        return {
            title = "Dead drop", reward = 25, limit = 420,
            desc = "Meet a contact, then leave a message where it'll be found.",
            stages = {
                Goto(a, "Go to the meeting point " .. Place(a, ply:GetPos()), 120),
                Hold(a, 20, "Wait for your contact", 160),
                Choice("Your contact doesn't come. Instead, a child walks past and presses a folded note into your hand.", {
                    { text = "Read it.", pick = function(q) Narrate(q, Pick(NOTES)) end },
                    { text = "Burn it unread.", pick = function(q) Narrate(q, "Some things are safer not known.") end },
                }),
                Goto(b, "Leave the message " .. Place(b, ply:GetPos()), 120),
            },
        }
    end,
}

T{
    id = "res_ambush", factions = { resistance = true }, violent = true,
    available = function(ply) return LC.Running and SecurityCount() >= 2 and (LC.PlayerIsHunted(ply) or RankIndex(ply) >= 3) end,
    build = function()
        return {
            title = "Ambush a patrol", reward = 40, limit = 480,
            desc = "Fighters only. Take down two units and disappear.",
            stages = { Count("killed", 2, "Take down Civil Protection units", function(_, _, npc)
                local st = LC.NPCs[npc]
                return st ~= nil and LC.IsSecurity(st)
            end) },
        }
    end,
}

T{
    id = "res_rescue", factions = { resistance = true },
    available = function() return #LC.ZonesOfKind("rebel") > 0 end,
    build = function(ply)
        local where = Spot(ply, 600, 2500)
        if not where then return nil end
        local dest, r, safe = SafeHouse(ply)
        return {
            title = "Extraction", reward = 40, limit = 600,
            desc = "Someone on a CP list is hiding " .. Place(where, ply:GetPos()) .. ". Bring them in.",
            stages = {
                {
                    kind = "target", action = "reach", r = 140, text = "Find the fugitive (marked)",
                    onEnter = function(q, st)
                        local npc = LC.Spawners.citizen(where + Vector(0, 0, 4))
                        if not IsValid(npc) then return false end
                        Lock(q, npc)
                        Freeze(npc, 600)
                        q.data.target = npc
                        st.npc = npc
                    end,
                },
                { kind = "escort", pos = dest, r = r, vanish = true, text = "Lead them to " .. safe,
                  onEnter = function(q, st) st.npc = q.data.target; if not IsValid(st.npc) then return false end end },
            },
        }
    end,
}

T{
    id = "res_ministry", factions = { resistance = true },
    available = function(ply) return Special(ply) == "chaplain" end,
    build = function()
        return {
            title = "The ministry", reward = 30, limit = 600,
            desc = "Tend to your flock. The Combine call it contraband. You call it Sunday.",
            stages = {
                Choice("A woman catches your sleeve. Her husband was taken last night. She asks you to pray with her, here, in the open.", {
                    { text = "Pray with her where she stands.", pick = function(q, p)
                        LC.AddTrait(p, "sympathy", 1)
                        q.bonus = (q.bonus or 0) + 10
                        if LC.SeenBySecurity(p, 800) then
                            Narrate(q, "You finish the prayer. Then you hear the boots.")
                            LC.ReportCrime(p, "Unlawful worship", 180)
                        else
                            Narrate(q, "She holds your hand through all of it. Nobody comes.")
                        end
                    end },
                    { text = "Promise to pray for him tonight, somewhere safe.", check = { "empathy", 10 },
                      success = function(q, p) LC.AddTrait(p, "sympathy", 1) Narrate(q, "She nods. It's enough. For now it's enough.") end,
                      fail = function(q) Narrate(q, "She lets go of your sleeve and doesn't look back.") end },
                }),
                Count("healed", 3, "Tend to the wounded with The Blessing", nil, true),
                Count("preached", 1, "Preach the Word (reload) where people can hear", nil, false),
            },
        }
    end,
}

------------------------------------------------------------------------
-- Citizens: Assignments
------------------------------------------------------------------------

T{
    id = "cit_rations", factions = { citizen = true },
    available = function() return next(LC.Lines) ~= nil end,
    build = function()
        local g = Pick(table.GetKeys(LC.Lines))
        local front = LC.Lines[g].slots[1].pos
        return {
            title = "Collect your ration", reward = LC.Event == "rations" and 20 or 10, limit = 300,
            desc = "Your ration allocation is ready at line " .. g .. ".",
            stages = { Goto(front, "Go to ration line " .. g, 200), Hold(front, 10, "Wait at the front of the line", 110) },
        }
    end,
}

T{
    id = "cit_cleanup", factions = { citizen = true },
    build = function(ply)
        local center = Spot(ply, 300, 2000)
        if not center then return nil end
        return {
            title = "Union work order: sanitation", reward = 20, limit = 420,
            desc = "Clear the litter " .. Place(center, ply:GetPos()) .. ". A clean city is a compliant city.",
            stages = { { kind = "collect", spots = SpotsNear(center, 4, 600), models = TRASH, need = 4,
                text = "Pick up the litter (press E)" } },
        }
    end,
}

T{
    id = "cit_errand", factions = { citizen = true },
    build = function(ply)
        -- Mrs. Kleiner lives in a housing block: the parcel is picked up inside one
        -- (yours if you have one), only falling back to the streets on maps without blocks
        local a
        local blocks = LC.ZonesOfKind and LC.ZonesOfKind("block") or {}
        if #blocks > 0 then
            local mine = LC.PlayerBlock and LC.PlayerBlock(ply)
            local own = {}
            for _, z in ipairs(blocks) do if mine and z.group == mine then own[#own + 1] = z end end
            local pool = #own > 0 and own or blocks
            for _ = 1, 6 do
                a = LC.SpotInZone(pool[math.random(#pool)])
                if a then break end
            end
        end
        local inBlock = a ~= nil
        a = a or Spot(ply, 400, 2000)
        local b = Spot(ply, 600, 3000)
        if not a or not b then return nil end
        local deliver = LC.QB.Contact("Give the parcel to her cousin " .. Place(b, ply:GetPos()) .. " (press E)", b, "citizen",
            "'From Kleiner? Tell her I'm fine.' It's not true, and you both know it.")
        return {
            title = "A neighbor's errand", reward = 20, limit = 420,
            desc = inBlock and "Mrs. Kleiner from the third floor has left a parcel in the block, to be carried across the district."
                or "Mrs. Kleiner from the third floor needs a parcel carried across the district.",
            stages = {
                LC.QB.Contact(inBlock and "Speak to Mrs. Kleiner inside the block (press E)" or "Speak to Mrs. Kleiner (press E)", a, "citizen",
                    "'It's only a little parcel. It's gone to the third floor and back already.' She presses it into your hands."),
                Choice("The parcel is taped shut. It's light, and something inside slides when you tilt it.", {
                    { text = "Deliver it unopened." },
                    { text = "Peel back the tape and look.", check = { "guile", 12 },
                      success = function(q)
                          InsertStages(q, { Choice("Resistance pamphlets. Your hands are suddenly cold.", {
                              { text = "Deliver it anyway.", pick = function(q2, p) LC.AddTrait(p, "sympathy", 1) LC.Bump(p, "pamphlets") end },
                              { text = "Hand it to Civil Protection instead.", pick = function(q2, p)
                                  LC.AddTrait(p, "loyalty", 2)
                                  LC.Bump(p, "reports")
                                  q2.stages[q2.stage + 1] = Count("used_npc", 1, "Hand it to a Civil Protection unit (press E)", IsCopNPC)
                              end },
                          }) })
                      end,
                      fail = function(q) Narrate(q, "The tape tears loudly. Better just deliver it, and fast.") end },
                }),
                deliver,
            },
        }
    end,
}

T{
    id = "cit_report", factions = { citizen = true },
    build = function(ply)
        -- sometimes it's behind a dumpster that's really in the map; otherwise on a quiet corner.
        -- Either way two people are actually there, and you walk up and see them.
        local bin = FindBins(ply, 300, 2500, 1)[1]
        local atBin = bin ~= nil and math.random() < 0.6
        local s = atBin and bin:GetPos() or Spot(ply, 400, 2500)
        if not s then return nil end
        local prompt = atBin and "Two people swap a bundle behind the dumpster. One has a lambda scratched into his sleeve."
            or "A man you know from your block hands a child a radio and walks away fast."
        local look = Goto(s, atBin and "Go over to the dumpster, casually" or "Go and look, casually", 150)
        look.onEnter = function(q)
            -- the two of them, a little apart, facing each other
            q.data.watched = {}
            for i, off in ipairs({ Vector(45, 0, 0), Vector(-45, 0, 0) }) do
                local npc = LC.QB.SpawnActor(q, "citizen", s + off, 900)
                if npc then q.data.watched[#q.data.watched + 1] = npc end
            end
            local a, b = q.data.watched[1], q.data.watched[2]
            if IsValid(a) and IsValid(b) then LC.Face(a, b:GetPos()) LC.Face(b, a:GetPos()) end
        end
        return {
            title = "Something you saw", reward = 20, limit = 420,
            desc = atBin and ("Neighbors whisper about something going on behind a dumpster " .. Place(s, ply:GetPos()) .. ".")
                or ("Neighbors whisper about strange comings and goings " .. Place(s, ply:GetPos()) .. "."),
            stages = {
                look,
                Hold(s, 6, "Watch quietly", 220),
                Choice(prompt, {
                    { text = "Report it to a unit.", pick = function(q, p)
                        LC.AddTrait(p, "loyalty", 1)
                        LC.Bump(p, "reports")
                        InsertStages(q, { Count("used_npc", 1, "Tell a Civil Protection unit (press E)", IsCopNPC) })
                    end },
                    { text = "Keep it to yourself.", pick = function(q, p)
                        LC.AddTrait(p, "sympathy", 1)
                        LC.Bump(p, "silences")
                        q.reward = 5
                        Narrate(q, "You saw nothing. You'll keep seeing nothing.")
                        return "complete"
                    end },
                }),
            },
        }
    end,
}

T{
    id = "cit_lost", factions = { citizen = true },
    available = function() return #LC.ZonesOfKind("block") > 0 or #LC.PointsOfKind("spawn") > 0 end,
    build = function(ply)
        local where = Spot(ply, 400, 2000)
        if not where then return nil end
        local blocks = LC.ZonesOfKind("block")
        local home, homeName
        if #blocks > 0 then
            local z = Pick(blocks)
            home, homeName = z.pos, LC.BlockName(z.group)
        else
            home = Pick(LC.PointsOfKind("spawn")).pos
            homeName = "his doorway"
        end
        return {
            title = "The confused old man", reward = 25, limit = 600,
            desc = "An old man is wandering " .. Place(where, ply:GetPos()) .. ", asking everyone for directions.",
            stages = {
                {
                    kind = "target", action = "reach", r = 140, text = "Find the old man (marked)",
                    onEnter = function(q, st)
                        local npc = LC.Spawners.citizen(where + Vector(0, 0, 4))
                        if not IsValid(npc) then return false end
                        npc:SetModel(Pick(LC.ELDERLY_MODELS)) -- Half-Life 2's older faces
                        if LC.NPCs[npc] then LC.NPCs[npc].gender = "male" end
                        Lock(q, npc)
                        Freeze(npc, 600)
                        q.data.target = npc
                        st.npc = npc
                    end,
                },
                Choice("He doesn't remember his block number. He keeps asking for his daughter.", {
                    { text = "Calm him down first.", check = { "empathy", 10 },
                      success = function(q) q.bonus = (q.bonus or 0) + 5 Narrate(q, "He takes your arm. His hand is light as paper.") end,
                      fail = function(q) Narrate(q, "He shuffles after you anyway, still asking.") end },
                    { text = "Just lead the way." },
                }),
                { kind = "escort", pos = home, r = 200, vanish = true, walkOnly = true, text = "Walk him home to " .. homeName,
                  onEnter = function(q, st) st.npc = q.data.target; if not IsValid(st.npc) then return false end end },
            },
        }
    end,
}

T{
    id = "cit_loyalty", factions = { citizen = true },
    available = function() return LC.Running and #LC.PointsOfKind("checkpoint") > 0 and CountRole("cop") > 0 end,
    build = function(ply)
        local cp = Pick(LC.PointsOfKind("checkpoint"))
        return {
            title = "Loyalty check", reward = 15, limit = 360,
            desc = "You've been summoned to a checkpoint for a routine loyalty check.",
            stages = {
                Goto(cp.pos, "Report to the checkpoint", 260),
                Count("used_npc", 1, "Present yourself to an officer (press E)", IsCopNPC),
                Choice("The officer's mask tilts. Where were you last night, citizen?", {
                    { text = "Tell the truth.", pick = function(q, p) LC.AddTrait(p, "loyalty", 1) end },
                    { text = "Give a smooth, boring alibi.", check = { "guile", 12 },
                      success = function(q) q.bonus = (q.bonus or 0) + 5 Narrate(q, "He waves you through. Boring is safe.") end,
                      fail = function(q, p)
                          Narrate(q, "He doesn't buy it.")
                          LC.ReportCrime(p, "Failing a loyalty check", 90)
                      end },
                }),
            },
        }
    end,
}

------------------------------------------------------------------------
-- The Infested: Urges
------------------------------------------------------------------------

T{
    id = "z_hunt", factions = { zombie = true }, violent = true,
    available = function() return LC.Running and CountRole("citizen") >= 2 end,
    build = function()
        return {
            title = "Hunger", reward = 30, limit = 480,
            desc = "Feed.",
            stages = { Count("killed", 2, "Feed on citizens", function(_, _, npc)
                local st = LC.NPCs[npc]
                return st ~= nil and st.role == "citizen"
            end) },
        }
    end,
}

T{
    id = "z_terrorize", factions = { zombie = true },
    available = function() return LC.Running and CountRole("citizen") >= 4 end,
    build = function()
        local st = Count("near_citizen", 4, "Get close to the living (they'll scatter)", nil, true)
        st.poll = function(q, s)
            for _, p in ipairs(Members(q)) do
                if p:Alive() then
                    for npc, ns in pairs(LC.NPCs) do
                        if IsValid(npc) and ns.role == "citizen" and npc:GetPos():DistToSqr(p:GetPos()) < 150 * 150 then
                            LC.QuestEvent("near_citizen", p, npc)
                            if q.done or Stage(q) ~= s then return end
                        end
                    end
                end
            end
        end
        return { title = "Terror", reward = 20, limit = 420, desc = "Let them see you.", stages = { st } }
    end,
}

T{
    id = "z_roam", factions = { zombie = true },
    available = function() return #LC.ZonesOfKind("infest") > 0 end,
    build = function()
        return {
            title = "Wander", reward = 25, limit = 400,
            desc = "Leave the nest. Stay out.",
            stages = { { kind = "survive", secs = 120, text = "Stay out of the infestation zones",
                cond = function(_, p) return LC.InfestZoneAt(p:GetPos()) == nil end } },
        }
    end,
}

------------------------------------------------------------------------
-- Stories: chains of parts, unlocked by what you've done
------------------------------------------------------------------------

LC.Chains = {}
LC.ChainList = {}

function LC.Chain(def)
    def.factions = def.factions or {}
    LC.Chains[def.id] = def
    LC.ChainList[#LC.ChainList + 1] = def
end

local function ChainFits(chain, ply)
    if chain.special then return Special(ply) == chain.special end
    return chain.factions[LC.QuestFaction(ply)] == true
end

function LC.ChainState(ply, id)
    local s = LC.Story(ply)
    s.chains[id] = s.chains[id] or { data = {} }
    s.chains[id].data = s.chains[id].data or {}
    return s.chains[id]
end

local function NextPart(ply, chain)
    local s = LC.Story(ply)
    if chain.gate then
        local ok, open = pcall(chain.gate, ply, s)
        if not ok or not open then return nil end
    end
    local cs = s.chains[chain.id]
    if cs and cs.done then return nil end
    if cs and (cs.readyAt or 0) > os.time() then return nil end
    if cs and cs.part then return cs.part end
    local ok, yes = pcall(chain.unlock, ply, s)
    if ok and yes then return chain.start end
    return nil
end

function LC.StoryPostings(ply)
    ply.lcStoryPostings = ply.lcStoryPostings or {}
    local out = {}
    for _, chain in ipairs(LC.ChainList) do
        if ChainFits(chain, ply) then
            local part = NextPart(ply, chain)
            local cached = ply.lcStoryPostings[chain.id]
            if cached and cached.q and not cached.dead then
                out[#out + 1] = cached
            elseif not part then
                ply.lcStoryPostings[chain.id] = nil
            elseif cached and cached.part == part and not cached.dead then
                out[#out + 1] = cached
            else
                local def = chain.parts[part]
                local cs = LC.ChainState(ply, chain.id)
                local ok, spec = pcall(def.build, ply, cs.data)
                if not ok then
                    LC.Error("story " .. chain.id .. "/" .. part, spec)
                elseif spec then
                    spec.id = nextId
                    nextId = nextId + 1
                    spec.tmpl = { id = chain.id .. "/" .. part }
                    spec.story, spec.chain, spec.part, spec.chainName = true, chain.id, part, chain.name
                    spec.partNum = def.num or 1
                    if chain.flat then
                        spec.title = string.format("%s: %s", chain.name, spec.title)
                    else
                        spec.title = string.format("%s, part %d: %s", chain.name, spec.partNum, spec.title)
                    end
                    spec.faction = LC.QuestFaction(ply)
                    spec.data = spec.data or {}
                    spec.expiresPost = CurTime() + 1e9
                    spec.owner = ply
                    ply.lcStoryPostings[chain.id] = spec
                    out[#out + 1] = spec
                end
            end
        end
    end
    return out
end

function LC.AdvanceChain(q, success)
    local ply = q.owner
    local chain = LC.Chains[q.chain]
    if not chain then return end
    local cs = LC.ChainState(ply, chain.id)
    local def = chain.parts[q.chainPart]
    if ply.lcStoryPostings then ply.lcStoryPostings[chain.id] = nil end
    local pace = cvPacing:GetFloat()

    if success and q.chainDecline then
        cs.part = nil
        cs.readyAt = os.time() + 1800
        ply:ChatPrint("[Story] " .. chain.name .. ": maybe another time.")
    elseif success and q.chainEnd then
        cs.done, cs.part = q.chainEnd, nil
        local ending = chain.endings and chain.endings[q.chainEnd] or q.chainEnd
        ply:ChatPrint("[Story] " .. chain.name .. " has ended. " .. ending)
        LC.Log("info", string.format("Story %s ended for %s: %s", chain.id, ply:Nick(), q.chainEnd))
        hook.Run("LivingCityStoryEnded", ply, chain.id, q.chainEnd)
    elseif success then
        local nextPart = q.chainNext or (def and def.next)
        if nextPart and chain.parts[nextPart] then
            cs.part = nextPart
            cs.readyAt = os.time() + pace
            ply:ChatPrint("[Story] " .. chain.name .. " continues." .. (pace > 0 and " Check your board (F3) in a little while." or " Check your board (F3)."))
        else
            cs.done, cs.part = "complete", nil
            ply:ChatPrint("[Story] " .. chain.name .. " has ended.")
        end
    else
        cs.part = q.chainPart
        cs.readyAt = os.time() + pace
        ply:ChatPrint("[Story] " .. chain.name .. ": that didn't go to plan. You'll get another chance.")
    end
    LC.SaveStory(ply)
end

function LC.CheckUnlocks(ply)
    if not IsValid(ply) then return end
    local s = LC.Story(ply)
    local changed = false
    for _, chain in ipairs(LC.ChainList) do
        if ChainFits(chain, ply) and not s.chains[chain.id] and not s.notified[chain.id] then
            local ok, yes = pcall(chain.unlock, ply, s)
            if ok and yes then
                s.notified[chain.id] = true
                changed = true
                ply:ChatPrint("[Story] Something has changed. Check your board (F3).")
            end
        end
    end
    if changed then LC.SaveStory(ply) end
end

-- Story NPCs: real people placed in the world for one quest.
local function SpawnActor(q, role, pos, holdSecs, keep, want)
    local spawner = LC.Spawners and LC.Spawners[role]
    if not spawner or not pos then return nil end
    local npc, st = spawner(pos + Vector(math.random(-40, 40), math.random(-40, 40), 4), role == "citizen" and want or nil)
    if not IsValid(npc) then return nil end
    st.unmanaged = true
    st.leaveAt = nil
    st.routeGroup = nil
    Lock(q, npc)
    if holdSecs then
        npc:SetSchedule(SCHED_IDLE_STAND)
        LC.SetState(npc, st, "event")
        st.eventUntil = CurTime() + holdSecs
    end
    if not keep then q.ents[#q.ents + 1] = npc end
    return npc, st
end

-- True while this player's current job is to speak with a Civil Protection unit,
-- so units don't treat walking up to one as crowding him.
function LC.QuestWantsCop(ply)
    local q = LC.QuestOf and LC.QuestOf[ply]
    local st = q and not q.done and Stage(q)
    return st ~= nil and st.kind == "count" and st.event == "used_npc" and st.filter == IsCopNPC
end

-- Somewhere to stand a person: inside the housing block if pos is a block's center,
-- else the spot itself.
local function PersonSpot(pos)
    for _, z in ipairs(LC.ZonesOfKind and LC.ZonesOfKind("block") or {}) do
        if z.pos:DistToSqr(pos) < 16 then return LC.SpotInZone(z) or pos end
    end
    return pos
end

-- A person to meet: someone is waiting at pos (marked on your HUD) and you press E
-- on them. role is "citizen" (default) or "cop". If nobody can be placed, it falls
-- back to simply walking there. line is what the quest says when you've met.
local function Contact(text, pos, role, line, want)
    local where = PersonSpot(pos)
    return {
        kind = "target", action = "use", pos = where, r = 140, text = text,
        onEnter = function(q, st)
            local npc = SpawnActor(q, role or "citizen", where, 900, nil, want)
            if not npc then
                st.kind, st.r, st.npc = "deliver", 150, nil
                return
            end
            st.npc = npc
        end,
        onDone = line and function(q) Narrate(q, line) end or nil,
    }
end

-- Everything the story file needs to build parts out of the same pieces.
LC.QB = {
    Contact = Contact, PersonSpot = PersonSpot,
    Goto = Goto, Deliver = Deliver, Hold = Hold, Count = Count, Choice = Choice,
    FindCitizenStage = FindCitizenStage, ArrestStage = ArrestStage, Flee = Flee,
    Spot = Spot, SpotsNear = SpotsNear, FindBins = FindBins, Place = Place, SafeHouse = SafeHouse, NearestZone = NearestZone,
    Freeze = Freeze, Lock = Lock, SpawnActor = SpawnActor, SpawnItem = SpawnItem,
    CitizenID = CitizenID, Pick = Pick, Narrate = Narrate, InsertStages = InsertStages,
    IsCitizenNPC = IsCitizenNPC, IsCopNPC = IsCopNPC, RandomCitizen = RandomCitizen, CountRole = CountRole,
    Members = Members, Stage = Stage, Advance = Advance, Finish = Finish,
    RankIndex = RankIndex, Special = Special, IsZombieNPC = IsZombieNPC,
    CONTRABAND = CONTRABAND, CRIMES = CRIMES, TRASH = TRASH,
}

------------------------------------------------------------------------
-- Boards
------------------------------------------------------------------------

local function FactionPlayers(f)
    local n = 0
    for _, p in ipairs(player.GetAll()) do if LC.QuestFaction(p) == f then n = n + 1 end end
    return n
end

local function ViolentInUse()
    local n = 0
    for q in pairs(LC.ActiveQuests) do if q.violent then n = n + 1 end end
    for _, list in pairs(LC.Postings) do
        for _, p in ipairs(list) do if p.violent and not p.q and not p.dead then n = n + 1 end end
    end
    return n
end

function LC.ViolentCap()
    return math.max(1, math.floor(#player.GetAll() / math.max(1, cvViolent:GetFloat())))
end

local function Shuffle(t)
    for i = #t, 2, -1 do
        local j = math.random(i)
        t[i], t[j] = t[j], t[i]
    end
    return t
end
LC.QB.Shuffle = Shuffle

function LC.RefreshBoard(ply)
    local f = LC.QuestFaction(ply)
    local now = CurTime()
    local list = {}
    for _, p in ipairs(LC.Postings[f] or {}) do
        if not p.dead and (p.q or now < p.expiresPost) then list[#list + 1] = p end
    end
    LC.Postings[f] = list

    local want = math.Clamp(2 + math.ceil(FactionPlayers(f) * 0.6), 3, 10)
    local open = 0
    local used = {}
    for _, p in ipairs(list) do
        if not p.q then open = open + 1 end
        used[p.tmpl] = true
    end

    local cands = {}
    for _, t in ipairs(LC.QuestTemplates) do
        if t.factions[f] and not used[t] then
            local ok, avail = pcall(function() return not t.available or t.available(ply) end)
            if ok and avail then cands[#cands + 1] = t end
        end
    end
    for _, t in ipairs(Shuffle(cands)) do
        if open >= want then break end
        if not t.violent or ViolentInUse() < LC.ViolentCap() then
            local ok, spec = pcall(t.build, ply)
            if not ok then
                LC.Error("quest " .. t.id, spec)
            elseif spec then
                spec.id = nextId
                nextId = nextId + 1
                spec.tmpl = t
                spec.violent = t.violent
                spec.faction = f
                spec.expiresPost = now + 240
                spec.data = spec.data or {}
                list[#list + 1] = spec
                open = open + 1
            end
        end
    end
    return list, f
end

function LC.SendBoard(ply)
    if not cvOn:GetBool() then return ply:ChatPrint("[Living City] Quests are turned off on this server.") end
    local list, f = LC.RefreshBoard(ply)
    local out = {}
    local mine = LC.QuestOf[ply]
    for _, p in ipairs(LC.StoryPostings and LC.StoryPostings(ply) or {}) do
        out[#out + 1] = {
            id = p.id, title = p.title, desc = p.desc, reward = p.reward, violent = false, limit = p.limit,
            taken = p.q and 1 or 0, max = 1, mine = mine ~= nil and mine.posting == p,
            story = true, chain = p.chainName, part = p.partNum,
        }
    end
    for _, p in ipairs(list) do
        out[#out + 1] = {
            id = p.id, title = p.title, desc = p.desc, reward = p.reward, violent = p.violent == true,
            limit = p.limit, taken = p.q and #Members(p.q) or 0, max = cvSquad:GetInt(), mine = mine ~= nil and mine.posting == p,
        }
    end
    local jobs
    if LC.CanWork and LC.CanWork(ply) and LCJ then
        jobs = { current = ply:GetNW2String("lcj_job", ""), list = {} }
        for _, o in ipairs(LCJ.Occupations) do jobs.list[#jobs.list + 1] = { id = o.id, name = o.name, desc = o.desc } end
    end
    LC.SendCompressed("lcq_board", {
        jobs = jobs, credits = LC.Credits and LC.Credits(ply) or nil, standing = LC.Standing and LC.Standing(ply) or nil,
        board = BOARDS[f] or "Jobs", faction = f, postings = out, active = mine ~= nil,
        traits = { loyalty = LC.Trait(ply, "loyalty"), sympathy = LC.Trait(ply, "sympathy"), corruption = LC.Trait(ply, "corruption") },
        wait = math.max(0, math.ceil((ply.lcqNext or 0) - CurTime())),
    }, { ply })
end

function LC.AcceptPosting(ply, pid)
    if not cvOn:GetBool() then return false end
    if LC.QuestOf[ply] then ply:ChatPrint("[Living City] Finish or abandon your current job first.") return false end
    if (ply.lcqNext or 0) > CurTime() then
        ply:ChatPrint("[Living City] Take a breath. Next job in " .. math.ceil(ply.lcqNext - CurTime()) .. "s.")
        return false
    end
    local f = LC.QuestFaction(ply)
    local posting
    for _, p in ipairs(LC.Postings[f] or {}) do if p.id == pid then posting = p end end
    if not posting and ply.lcStoryPostings then
        for _, p in pairs(ply.lcStoryPostings) do if p.id == pid then posting = p end end
    end
    if not posting or posting.dead then ply:ChatPrint("[Living City] That posting is gone.") return false end
    if posting.story and posting.owner ~= ply then return false end

    if posting.q then
        if posting.story then return false end
        local q = posting.q
        if #Members(q) >= cvSquad:GetInt() then ply:ChatPrint("[Living City] That job has enough people.") return false end
        table.insert(q.members, ply)
        LC.QuestOf[ply] = q
        Narrate(q, ply:Nick() .. " has joined.")
        SendStateAll(q)
        return true
    end

    local q = {
        id = posting.id, posting = posting, tmpl = posting.tmpl, title = posting.title, desc = posting.desc,
        reward = posting.reward, violent = posting.violent, board = BOARDS[f] or "Jobs",
        owner = ply, members = { ply }, stages = posting.stages, stage = 1,
        expires = CurTime() + (posting.limit or 300), ents = {}, marked = {}, data = posting.data or {},
        failOnArrest = posting.failOnArrest, tick = posting.tick,
    }
    if posting.story then
        q.chain, q.chainPart, q.board = posting.chain, posting.part, posting.chainName
        local cs = LC.ChainState(ply, posting.chain)
        cs.part = posting.part
        q.chainData = cs.data
        LC.SaveStory(ply)
    end
    posting.q = q
    LC.QuestOf[ply] = q
    LC.ActiveQuests[q] = true
    ply:ChatPrint("[" .. q.board .. "] " .. q.title .. ". " .. (q.desc or ""))
    if posting.intro then Narrate(q, posting.intro) end
    LC.Log("info", string.format("Quest accepted: %s [%s] by %s", q.title, q.tmpl.id, ply:Nick()))
    EnterStage(q)
    return true
end

function LC.AbandonQuest(ply)
    local q = LC.QuestOf[ply]
    if not q then return end
    if q.owner == ply and #Members(q) <= 1 then return Finish(q, false, "abandoned") end
    for i, p in ipairs(q.members) do if p == ply then table.remove(q.members, i) break end end
    LC.QuestOf[ply] = nil
    ply.lcqNext = CurTime() + cvCooldown:GetFloat()
    if q.owner == ply then q.owner = Members(q)[1] end
    Narrate(q, ply:Nick() .. " left the job.")
    SendState(ply)
    SendStateAll(q)
end

function LC.ResolveChoice(ply, qid, idx)
    local q = LC.QuestOf[ply]
    if not q or q.id ~= qid or q.owner ~= ply then return end
    local st = Stage(q)
    if not st or st.kind ~= "choice" or st.resolved then return end
    local o = st.options[idx]
    if not o or (o.when and not o.when(q)) then return end
    st.resolved = true

    local success = true
    if o.check then
        local roll, mod = math.random(20), LC.SkillMod(ply, o.check[1])
        success = (roll ~= 1) and (roll == 20 or roll + mod >= o.check[2])
        Narrate(q, string.format("%s check: rolled %d + %d = %d against %d. %s", string.upper(o.check[1]), roll, mod,
            roll + mod, o.check[2], success and "Success." or "Failure."))
    end
    local fn = o.pick
    if not fn then
        if success then fn = o.success else fn = o.fail end
    end
    local result = fn and fn(q, ply) or "next"
    if q.done then return end
    if result == "complete" then return Finish(q, true) end
    if result == "fail" then return Finish(q, false, o.failText) end
    Advance(q)
end

net.Receive("lcq_accept", function(_, ply) LC.AcceptPosting(ply, net.ReadUInt(32)); LC.SendBoard(ply) end)
net.Receive("lcq_abandon", function(_, ply) LC.AbandonQuest(ply) end)
net.Receive("lcq_choice", function(_, ply)
    local qid, idx = net.ReadUInt(32), net.ReadUInt(8)
    LC.ResolveChoice(ply, qid, idx)
end)
net.Receive("lcq_request", function(_, ply)
    SendState(ply)
    local q = LC.QuestOf[ply]
    local st = q and Stage(q)
    if st and st.kind == "choice" and not st.resolved and q.owner == ply then OpenChoice(q, st) end
end)

hook.Add("ShowSpare1", "LivingCityQuests", function(ply) LC.SendBoard(ply) end)
concommand.Add("lcq_board", function(ply) if IsValid(ply) then LC.SendBoard(ply) end end)
hook.Add("PlayerSay", "LivingCityQuestsChat", function(ply, text)
    local t = string.lower(string.Trim(text))
    if t == "!jobs" or t == "!quests" or t == "!board" or t == "!directives" then LC.SendBoard(ply) return "" end
    if t == "!abandon" then LC.AbandonQuest(ply) return "" end
end)

------------------------------------------------------------------------
-- Story admin (handy for trying chains in singleplayer)
------------------------------------------------------------------------

local function StoryTarget(ply, name)
    if name and name ~= "" then return LC.FindPlayer(name) end
    return IsValid(ply) and ply or nil
end

concommand.Add("lcq_startchain", function(ply, _, args)
    if IsValid(ply) and not (ply:IsAdmin() or LC.CanEdit(ply)) then return end
    local chain = LC.Chains[args[1] or ""]
    local target = StoryTarget(ply, args[2])
    local function out(m) if IsValid(ply) then ply:ChatPrint(m) else print(m) end end
    if not chain then
        local ids = {}
        for _, c in ipairs(LC.ChainList) do ids[#ids + 1] = c.id end
        return out("[Story] Chains: " .. table.concat(ids, ", ") .. ". Usage: lcq_startchain <chain> [player]")
    end
    if not target then return out("[Story] Player not found.") end
    local s = LC.Story(target)
    s.chains[chain.id] = { part = chain.start, data = {}, readyAt = 0 }
    LC.SaveStory(target)
    if target.lcStoryPostings then target.lcStoryPostings[chain.id] = nil end
    out("[Story] " .. chain.name .. " is ready on " .. target:Nick() .. "'s board (F3).")
end)

concommand.Add("lcq_story", function(ply, _, args)
    if IsValid(ply) and not (ply:IsAdmin() or LC.CanEdit(ply)) then return end
    local target = StoryTarget(ply, args[1])
    local function out(m) if IsValid(ply) then ply:ChatPrint(m) else print(m) end end
    if not target then return out("[Story] Player not found.") end
    local s = LC.Story(target)
    out(string.format("[Story] %s: loyalty %d, sympathy %d, corruption %d", target:Nick(),
        LC.Trait(target, "loyalty"), LC.Trait(target, "sympathy"), LC.Trait(target, "corruption")))
    local c = {}
    for k, v in SortedPairs(s.counters) do c[#c + 1] = k .. " " .. v end
    out("  counters: " .. (#c > 0 and table.concat(c, ", ") or "none"))
    for id, cs in SortedPairs(s.chains) do
        out(string.format("  %s: %s", id, cs.done and ("ended (" .. cs.done .. ")") or ("at " .. tostring(cs.part))))
    end
end)

concommand.Add("lcq_resetstory", function(ply, _, args)
    if IsValid(ply) and not (ply:IsAdmin() or LC.CanEdit(ply)) then return end
    local target = StoryTarget(ply, args[1])
    if not target then return end
    target.lcStory = nil
    target.lcStoryPostings = nil
    target:RemovePData("lcq_story")
    for _, t in ipairs({ "loyalty", "sympathy", "corruption" }) do target:RemovePData("lcq_" .. t) end
    target:ChatPrint("[Story] Your story has been reset.")
end)
