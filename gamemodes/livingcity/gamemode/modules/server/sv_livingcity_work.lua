--[[
    Living City: occupations

    Citizens (and Resistance members who still pass for citizens, or who wear
    citizen clothes) take a Union job from their board (F3). Each job hands them a steady stream of shifts,
    one at a time, as a personal posting called "Union shift". Shifts happen at
    workplaces marked with the editor ("Point: workplace", number = job number
    in sh_livingcity_jobs.lua), or on the streets around you if there are none.

    Shifts pay Credits and Civil Standing (see sv_livingcity_economy.lua) and
    faction XP, and some carry small moral choices that feed your traits.
]]

if CLIENT then return end

util.AddNetworkString("lcj_set")

LC = LC or {}
local Q = LC.QB
if not Q or not LCJ then return end

local FLAGS = bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED)
local cvCooldown = CreateConVar("lc_job_cooldown", "120", FLAGS, "Seconds between changing jobs")

local Goto, Deliver, Hold, Count, Choice = Q.Goto, Q.Deliver, Q.Hold, Q.Count, Q.Choice
local Narrate, Insert, Pick, Place = Q.Narrate, Q.InsertStages, Q.Pick, Q.Place
local function Trait(p, n, d) LC.AddTrait(p, n, d) end

------------------------------------------------------------------------
-- Employment
------------------------------------------------------------------------

function LC.Job(ply) return LCJ.ById[ply:GetNW2String("lcj_job", "")] end

local WORKERS = { citizen = true, resistance = true }

function LC.CanWork(ply)
    local f = LC.QuestFaction(ply)
    if not WORKERS[f] then return false end
    if f == "resistance" and LC.PlayerIsHunted(ply) and not (LC.PassesAsCitizen and LC.PassesAsCitizen(ply)) then return false end
    return true
end

local function GiveTools(ply)
    local job = LC.Job(ply)
    if not job or not job.tools or not ply:Alive() then return end
    for _, cls in ipairs(job.tools) do
        if not ply:HasWeapon(cls) then ply:Give(cls) end
    end
end

LC.GiveJobTools = GiveTools

function LC.SetJob(ply, id, force)
    local job = LCJ.ById[id]
    if id ~= "" and not job then return false, "That job doesn't exist." end
    if job and LCJ.Closed(job) and not force then return false, "That job is closed right now. Pick a different one." end
    if not force then
        if not LC.CanWork(ply) then return false, "Only citizens can take Union jobs." end
        if id ~= "" and LC.IntakePending and LC.IntakePending(ply) then
            return false, "Only registered citizens can take Union jobs. Register at Civil Intake first, then pick a job."
        end
        if (ply.lcjNext or 0) > CurTime() then
            return false, "You changed jobs recently. You can change again in " .. math.ceil(ply.lcjNext - CurTime()) .. " seconds."
        end
    end
    -- the old job's shift goes with the old job (it stayed on the HUD and blocked the new one's)
    local cur = LC.QuestOf and LC.QuestOf[ply]
    if cur and not cur.done and cur.chain == "shift" and LC.AbandonQuest then
        LC.AbandonQuest(ply)
        ply.lcqNext = 0
    end
    ply:SetNW2String("lcj_job", id)
    ply:SetPData("lcj_job", id)
    ply.lcjNext = CurTime() + cvCooldown:GetFloat()
    local s = LC.Story(ply)
    s.chains.shift = nil
    LC.SaveStory(ply)
    if ply.lcStoryPostings then ply.lcStoryPostings.shift = nil end
    GiveTools(ply)
    if job then ply:ChatPrint("[Union] Your job is now: " .. job.name .. ". Open your board (F3) to find your shifts.") end
    hook.Run("LivingCityJobChanged", ply, id)
    return true
end

-- Everyone works (the owner: "everyone should be forced to work a job and the only ones who
-- don't are the rebels"). A registered citizen with no job is given one by the Union, the
-- post with fewest hands; they can ask for another (F3 > Jobs). The Resistance aren't
-- assigned (one can still take a job, passing as a citizen).
local cvAssign = CreateConVar("lc_assign_work", "1", bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED), "Every registered citizen without a job is assigned Union work (rebels aren't)")
function LC.GiveUnionWork(ply)
    if not cvAssign:GetBool() or not IsValid(ply) or not ply:Alive() then return false end
    if ply:GetNW2String("lcf_faction", "") ~= "citizen" or LC.Job(ply) then return false end
    if (LC.IntakePending and LC.IntakePending(ply)) or not LC.CanWork(ply) then return false end
    local counts = {}
    for _, p in ipairs(player.GetAll()) do
        local j = p:GetNW2String("lcj_job", "")
        if j ~= "" then counts[j] = (counts[j] or 0) + 1 end
    end
    local best, bn = nil, nil
    for _, o in ipairs(LCJ.Occupations or {}) do
        if not LCJ.Closed(o) then
            local n = counts[o.id] or 0
            if not bn or n < bn or (n == bn and math.random() < 0.4) then best, bn = o, n end
        end
    end
    if not best then return false end
    if not LC.SetJob(ply, best.id, true) then return false end
    ply.lcjNext = 0 -- (they can ask for another straight away)
    if LC.Notice then
        LC.Notice(ply, "event", "Union work assignment", "The Union has given you a job: " .. best.name .. ". Go to the " .. string.lower(best.place)
            .. " to work. Your shifts are on your board (F3), and you can ask for a different job there.", 12)
    end
    return true
end
hook.Add("LivingCityRegistered", "LivingCityAssignWork", function(ply) timer.Simple(2, function() LC.GiveUnionWork(ply) end) end)
hook.Add("PlayerSpawn", "LivingCityAssignWork", function(ply) timer.Simple(5, function() LC.GiveUnionWork(ply) end) end)

net.Receive("lcj_set", function(_, ply)
    local ok, why = LC.SetJob(ply, net.ReadString())
    if not ok and why then ply:ChatPrint("[Union] " .. why) end
    if LC.SendBoard then LC.SendBoard(ply) end
end)

hook.Add("PlayerInitialSpawn", "LivingCityJobs", function(ply)
    timer.Simple(1, function()
        if IsValid(ply) then ply:SetNW2String("lcj_job", ply:GetPData("lcj_job", "")) end
    end)
end)

-- A post the Union no longer gives players (sh_livingcity_jobs.lua: npcOnly, or gameOnly with lc_jobgames 0):
-- whoever held it is told, and picks another.
timer.Create("LivingCityClosedJobs", 10, 0, function()
    for _, ply in ipairs(player.GetAll()) do
        local job = LC.Job(ply)
        if job and LCJ.Closed(job) then
            ply:SetNW2String("lcj_job", "")
            ply:SetPData("lcj_job", "")
            local s = LC.Story and LC.Story(ply)
            if s and s.chains then s.chains.shift = nil if LC.SaveStory then LC.SaveStory(ply) end end
            if ply.lcStoryPostings then ply.lcStoryPostings.shift = nil end
            ply:ChatPrint("[Union] Your job (" .. job.name .. ") has been closed, so you don't have one now. Pick a new job on your board (F3).")
            if LC.SendBoard then LC.SendBoard(ply) end
        end
    end
end)

hook.Add("PlayerSpawn", "LivingCityJobs", function(ply)
    timer.Simple(0.5, function() if IsValid(ply) then GiveTools(ply) end end)
end)

------------------------------------------------------------------------
-- Building blocks
------------------------------------------------------------------------

local function WorkSpot(ply, num, minD, maxD)
    local pts = LC.PointsOfKind("work", num)
    if #pts > 0 then return Pick(pts).pos end
    return Q.Spot(ply, minD or 300, maxD or 2000)
end

-- A spot placed with the editor for this (a loading dock, a graffiti wall,
-- a rubble pile), the nearer ones first; nil if the map has none.
local function Marked(kind, ply, avoid)
    local pts, near = LC.PointsOfKind(kind), {}
    for _, p in ipairs(pts) do
        if not (avoid and avoid[p]) and p.pos:DistToSqr(ply:GetPos()) < 3500 * 3500 then near[#near + 1] = p end
    end
    if #near == 0 then
        for _, p in ipairs(pts) do if not (avoid and avoid[p]) then near[#near + 1] = p end end
    end
    if #near == 0 then return nil end
    local p = Pick(near)
    if avoid then avoid[p] = true end
    return p.pos
end
LC.MarkedSpot = Marked

local function Sound(path, pos)
    if sound and sound.Play then sound.Play(path, pos, 70) end
end

-- Treat patients until they're back on their feet (works with any healing).
local function Patients(spots, text)
    local st = Count("patched", #spots, text, nil, true)
    st.pos = spots[1]
    st.onEnter = function(q, s)
        q.data.patients = {}
        for _, pos in ipairs(spots) do
            local npc = Q.SpawnActor(q, "citizen", pos, 900)
            if npc then
                npc:SetHealth(math.max(1, math.floor(npc:GetMaxHealth() * 0.25)))
                q.data.patients[#q.data.patients + 1] = npc
            end
        end
        if #q.data.patients == 0 then return false end
        s.need = #q.data.patients
    end
    st.poll = function(q, s)
        for _, npc in ipairs(q.data.patients or {}) do
            if IsValid(npc) and npc:Health() >= npc:GetMaxHealth() * 0.9 then
                LC.QuestEvent("patched", q.owner, npc)
                if q.done or Q.Stage(q) ~= s then return end
            end
        end
    end
    return st
end

local function PatchOne(text)
    local st = Count("patched", 1, text, nil, true)
    st.poll = function(q, s)
        local npc = q.data.actor
        if IsValid(npc) and npc:Health() >= npc:GetMaxHealth() * 0.9 then LC.QuestEvent("patched", q.owner, npc) end
    end
    return st
end

------------------------------------------------------------------------
-- Shifts, by job
------------------------------------------------------------------------

local SHIFTS = {}

SHIFTS.sanitation = {
    function(ply, job)
        local center = WorkSpot(ply, job.num, 300, 2000)
        if not center then return nil end
        return {
            title = "Litter sweep", reward = 15, limit = 420,
            desc = "Pick up 5 pieces of litter " .. Place(center, ply:GetPos()) .. ".",
            stages = { { kind = "collect", spots = Q.HideSpots(center, 5, 700, true), models = Q.TRASH, need = 5,
                text = "Pick up the litter: press E on each piece (5 in all)" } },
        }
    end,
    function(ply)
        -- the bins that are already in the map; only if it has none do we put some down
        local bins = Q.FindBins(ply, 200, 2500, 3)
        local stages = {}
        for i = 1, 3 do
            local bin = bins[i]
            local sp
            if bin then
                sp = bin.pos
            else
                sp = Q.Spot(ply, 300, 2000)
                if not sp then return nil end
                local tr = util.TraceLine({ start = sp + Vector(0, 0, 40), endpos = sp - Vector(0, 0, 300), mask = MASK_SOLID_BRUSHONLY })
                if tr.Hit then sp = tr.HitPos end -- on the ground, not floating
            end
            local h = Hold(sp, 6, string.format("Go to bin %d of 3 (%s) and stay next to it for 6 seconds to empty it", i, Place(sp, ply:GetPos())), 110)
            if bin then
                h.item = bin.ent
            else
                h.onEnter = function(q, st) st.item = Q.SpawnItem(q, "models/props_trainstation/trashcan_indoor001a.mdl", sp) end
            end
            stages[i] = h
        end
        return { title = "Bin round", reward = 15, limit = 480, desc = "Three bins are overflowing. Go to each one and empty it.", stages = stages }
    end,
    function(ply)
        local sp = Marked("graffiti", ply) or Q.Spot(ply, 300, 2000)
        if not sp then return nil end
        return {
            title = "Graffiti removal", reward = 20, limit = 420,
            desc = "Someone reported graffiti " .. Place(sp, ply:GetPos()) .. ". Go there and scrub it off.",
            stages = {
                Goto(sp, "Go to the graffiti (marked)", 150),
                Choice("Someone has sprayed a lambda (the Resistance symbol) and a name across the wall. You know the name: it's your neighbor's boy.", {
                    { text = "Scrub off all of it, lambda and name.", pick = function(q, p) Trait(p, "loyalty", 1) end },
                    { text = "Scrub off only the name and leave the lambda (if you're caught, you're wanted).", check = { "guile", 11 },
                      success = function(q, p)
                          Trait(p, "sympathy", 1)
                          LC.Bump(p, "silences")
                          Narrate(q, "Somebody will see that lambda tomorrow and feel a little less alone.")
                      end,
                      fail = function(q, p)
                          Narrate(q, "A Civil Protection unit on the corner saw you leave the lambda on the wall. You're now wanted.")
                          LC.ReportCrime(p, "Defacing city property", 90)
                      end },
                    { text = "Report the boy's name to a Civil Protection unit.", pick = function(q, p)
                        Trait(p, "loyalty", 2)
                        LC.Bump(p, "reports")
                        Insert(q, { Count("used_npc", 1, "Find a Civil Protection unit and press E on them to report the name", Q.IsCopNPC) })
                    end },
                }),
                Hold(sp, 5, "Crouch at the wall for 5 seconds to scrub it clean", 100, true),
            },
        }
    end,
}

-- Ration Production: rations are factory bars and gel, made, counted and
-- handed out; nobody cooks them.
local function Dispenser(ply)
    local list = LC.EntsOf and LC.EntsOf("lc_dispenser") or {}
    if #list > 0 then return Pick(list):GetPos() end
    local lines = table.GetKeys(LC.Lines or {})
    if #lines > 0 then return LC.Lines[Pick(lines)].slots[1].pos end
    return nil
end

SHIFTS.kitchen = {
    function(ply, job)
        local station = WorkSpot(ply, job.num)
        if not station then return nil end
        return {
            title = "The sealing line", reward = 15, limit = 360,
            desc = "Ration bars and gel get sealed in foil here, thousands a day. Go to the ration plant and work the sealing line.",
            stages = { Goto(station, "Go to the ration plant (marked)", 180), Hold(station, 40, "Stay at the line for 40 seconds to seal ration packs", 160) },
        }
    end,
    function(ply, job)
        local truck = Marked("dock", ply) or Q.Spot(ply, 600, 2500)
        local dest = Dispenser(ply) or WorkSpot(ply, job.num)
        if not truck or not dest then return nil end
        return {
            title = "Supply run", reward = 20, limit = 480,
            desc = "The supply truck is waiting " .. Place(truck, ply:GetPos()) .. ". Get the crate of ration packs from the driver and take it to the dispenser attendant.",
            stages = {
                Q.Contact("Go to the truck driver (marked) and press E on them to take the ration crate", truck, "citizen", "'Sign here. No, nobody has a pen. Just take it.'"),
                Q.Contact("Take the crate to the dispenser attendant (marked) and press E on them", dest, "citizen",
                    "She counts the packs twice and doesn't say what the number should have been."),
            },
        }
    end,
    function(ply, job)
        local at = Dispenser(ply) or WorkSpot(ply, job.num)
        if not at then return nil end
        return {
            title = "The count", reward = 20, limit = 420,
            desc = "Every ration pack in the dispensers must match the register. Go to the dispensers and count them.",
            stages = {
                Goto(at, "Go to the dispensers (marked)", 200),
                Hold(at, 25, "Stay at the dispensers for 25 seconds to count the packs against the register", 180),
                Choice("The count is three packs short. Nobody signed for them, and the register doesn't care whose fault that is.", {
                    { text = "Report the missing packs to the supervisor.", pick = function(q, p)
                        Trait(p, "loyalty", 1)
                        q.bonus = 5
                        Narrate(q, "The supervisor writes it down. Somebody is going to have a very bad week. It isn't you. (5 extra XP for this shift.)")
                    end },
                    { text = "Change the register so the numbers match.", pick = function(q, p)
                        Trait(p, "corruption", 1)
                        Narrate(q, "A stroke of the pen and the register matches the shelves. Nobody will ever know. Probably.")
                    end },
                    { text = "Write it down as six short and keep three packs for yourself (if you're caught, you're wanted).", check = { "guile", 12 },
                      success = function(q, p)
                          Trait(p, "corruption", 1)
                          if LC.GiveOrDrop then LC.GiveOrDrop(p, "ration", 3) end
                          Narrate(q, "You take three ration packs for yourself. The register will blame whoever worked here before you.")
                      end,
                      fail = function(q, p)
                          Narrate(q, "A dispenser attendant saw you take the packs. She doesn't say anything. She doesn't have to: you're now wanted for ration fraud.")
                          LC.ReportCrime(p, "Ration fraud", 120)
                      end },
                }),
            },
        }
    end,
    function(ply)
        local lines = table.GetKeys(LC.Lines or {})
        if #lines == 0 or not LC.Running then return nil end
        local g = Pick(lines)
        local front = LC.Lines[g].slots[1].pos
        return {
            title = "The counter", reward = 25, limit = 600,
            desc = "You're checking ration cards at line " .. g .. " today. Each valid card gets one ration pack. Forged cards get nothing.",
            stages = {
                Goto(front, "Go to the ration counter (marked)", 220),
                Choice("A card with a smudged stamp and a citizen number that's one digit too long: it's forged. The man holding it is very thin.", {
                    { text = "Take the card and report him to Civil Protection.", pick = function(q, p)
                        Trait(p, "loyalty", 1)
                        q.bonus = 10
                        Narrate(q, "A Civil Protection unit takes him by the arm. The card goes in the box with the others. (10 extra XP for this shift.)")
                    end },
                    { text = "Accept the card and give him his ration.", pick = function(q, p)
                        Trait(p, "sympathy", 1)
                        LC.Bump(p, "silences")
                        Narrate(q, "He takes the pack and doesn't look back. Neither do you.")
                    end },
                    { text = "Keep the forged card for yourself (if you're caught, you're wanted).", check = { "guile", 10 },
                      success = function(q, p)
                          Trait(p, "corruption", 1)
                          if LC.GiveOrDrop then LC.GiveOrDrop(p, "ration_forged", 1) end
                          Narrate(q, "'Invalid,' you tell him, and the card goes in your pocket instead of the box. He doesn't argue.")
                      end,
                      fail = function(q, p)
                          Narrate(q, "The supervisor saw the card go in your pocket. 'Ration fraud,' he says, almost bored. You're now wanted.")
                          LC.ReportCrime(p, "Ration fraud", 120)
                      end },
                }),
                { kind = "count", event = "served", need = 3, pos = front, r = 320, distinct = false,
                  text = "Stay at the counter until 3 citizens have been handed their rations" },
            },
        }
    end,
}

SHIFTS.medic = {
    function(ply, job)
        local center = WorkSpot(ply, job.num, 300, 2000)
        if not center then return nil end
        return {
            title = "Clinic rounds", reward = 25, limit = 600,
            desc = "Three injured patients are waiting at the clinic. Heal each one with your medkit until they're back on their feet.",
            stages = {
                Goto(center, "Go to the clinic (marked)", 200),
                Patients(Q.SpotsNear(center, 3, 300), "Heal the patients: hold your medkit and press primary fire (left click) on each one until they're healed"),
            },
        }
    end,
    function(ply)
        local sp = Q.Spot(ply, 400, 2500)
        if not sp then return nil end
        return {
            title = "House call", reward = 25, limit = 480,
            desc = "A man was hurt " .. Place(sp, ply:GetPos()) .. " and can't walk to the clinic. Go to him and heal him.",
            stages = {
                {
                    kind = "target", action = "reach", r = 140, text = "Go to the injured man (marked)", pos = sp,
                    onEnter = function(q, st)
                        local npc = Q.SpawnActor(q, "citizen", sp, 900)
                        if not npc then return false end
                        npc:SetHealth(math.max(1, math.floor(npc:GetMaxHealth() * 0.25)))
                        q.data.actor = npc
                        st.npc = npc
                    end,
                },
                Choice("Stunstick bruises, in neat rows: Civil Protection did this. He grabs your wrist. 'Please. Don't write it down. Say I fell.'", {
                    { text = "Write down the truth: a stunstick beating.", pick = function(q, p) Trait(p, "loyalty", 1) end },
                    { text = "Cover for him: write 'fell down the stairs'.", pick = function(q, p)
                        Trait(p, "sympathy", 1)
                        LC.Bump(p, "silences")
                        Narrate(q, "He closes his eyes. 'Thank you.'")
                    end },
                }),
                PatchOne("Heal him: hold your medkit and press primary fire (left click) on him until he's healed"),
            },
        }
    end,
}

SHIFTS.factory = {
    function(ply, job)
        local a = WorkSpot(ply, job.num)
        if not a then return nil end
        local b = WorkSpot(ply, job.num)
        if not b or b:DistToSqr(a) < 100 * 100 then b = Q.SpotsNear(a, 1, 500)[1] end
        return {
            title = "Assembly quota", reward = 25, limit = 600,
            desc = "Today's quota is posted: work the line, then carry the finished part to the next station and fit it. Nobody asks what the parts are for.",
            stages = {
                Goto(a, "Go to the factory line (marked)", 180),
                Hold(a, 25, "Stay at the line for 25 seconds to work it", 160),
                { kind = "pickup", pos = a, model = "models/props_junk/cardboard_box004a.mdl", text = "Pick up the finished part: press E on the box" },
                Deliver(b, "Carry the part to the next station (marked)", 150),
                Hold(b, 15, "Stay at the station for 15 seconds to fit the part", 160),
            },
        }
    end,
    function(ply, job)
        local dock = Marked("dock", ply) or Q.Spot(ply, 500, 2500)
        local station = WorkSpot(ply, job.num)
        if not dock or not station then return nil end
        local stages = {}
        for i = 1, 2 do
            stages[#stages + 1] = { kind = "pickup", pos = dock, model = "models/props_junk/cardboard_box004a.mdl",
                text = string.format("Go to the loading dock (marked) and press E on crate %d of 2 to pick it up", i) }
            stages[#stages + 1] = Deliver(station, string.format("Carry crate %d to the factory floor (marked)", i), 160)
        end
        return { title = "Loading dock", reward = 25, limit = 600, desc = "Carry two crates, one at a time, from the loading dock to the factory floor.", stages = stages }
    end,
    function(ply, job)
        local station = WorkSpot(ply, job.num)
        if not station then return nil end
        return {
            title = "Short count", reward = 20, limit = 420,
            desc = "Another shift working the factory line.",
            stages = {
                Goto(station, "Go to the factory line (marked)", 180),
                Hold(station, 20, "Stay at the line for 20 seconds to work it", 160),
                Choice("The parts count is short again. You see the foreman slide a box of parts under his coat, and he sees you watching.", {
                    { text = "Report the foreman to Civil Protection.", pick = function(q, p)
                        Trait(p, "loyalty", 1)
                        LC.Bump(p, "reports")
                        Insert(q, { Count("used_npc", 1, "Find a Civil Protection unit and press E on them to report the foreman", Q.IsCopNPC) })
                    end },
                    { text = "Say nothing.", pick = function(q, p) LC.Bump(p, "silences") end },
                    { text = "Ask him for a share of what he's stealing.", pick = function(q, p)
                        Trait(p, "corruption", 1)
                        LC.Bump(p, "bribes")
                        q.bonus = 10
                        Narrate(q, "He grins like you've always been friends. (10 extra XP for this shift.)")
                    end },
                }),
            },
        }
    end,
}

SHIFTS.courier = {
    function(ply, job)
        -- real letters, from people in the city to people in the city (sv_livingcity_mail.lua)
        local letters = LC.LettersOut and LC.LettersOut(3) or {}
        if #letters == 0 then return nil end
        local office = WorkSpot(ply, job.num)
        local stages, carried = {}, {}
        if office then
            stages[1] = Q.Contact("Go to the post office (marked) and press E on the postal clerk to collect today's letters", office, "citizen",
                "'Real post, for once. Mind none of it goes astray.'")
        end
        for _, l in ipairs(letters) do
            local dest = LC.LetterDestination(l, ply:GetPos())
            if dest then
                carried[#carried + 1] = l
                local h = Hold(dest, 3, "", 140)
                h.onDone = function(q) LC.DeliverLetter(l, q.owner) end
                stages[#stages + 1] = h
            end
        end
        if #carried == 0 then return nil end
        local n = 0
        for _, st in ipairs(stages) do
            if st.kind == "hold" then
                n = n + 1
                st.text = string.format("Take letter %d of %d to %s (marked) and stay at their door for 3 seconds to push it under", n, #carried, carried[n].toName or "someone")
            end
        end
        -- they're yours from the moment you start
        local first = stages[1]
        local prev = first.onEnter
        first.onEnter = function(q, st)
            for _, l in ipairs(carried) do l.claimed = true end
            if prev then return prev(q, st) end
        end
        return {
            title = "The real mail", reward = 25, limit = 900,
            desc = #carried .. " letter" .. (#carried == 1 and "" or "s") .. " written by people in the city, for you to deliver to other people in the city.",
            stages = stages,
            onFinish = function() for _, l in ipairs(carried) do if l.state == "out" then l.claimed = nil end end end,
        }
    end,
    function(ply, job)
        local office = WorkSpot(ply, job.num)
        if not office then return nil end
        local doors = {}
        for _, z in ipairs(LC.ZonesOfKind("block")) do doors[#doors + 1] = { z.pos, LC.BlockName(z.group) } end
        for _, p in ipairs(LC.PointsOfKind("spawn")) do doors[#doors + 1] = { p.pos, "an apartment doorway" } end
        while #doors < 3 do
            local s = Q.Spot(ply, 400, 2500)
            if not s then return nil end
            doors[#doors + 1] = { s, Place(s, ply:GetPos()) }
        end
        Q.Shuffle(doors)
        -- the mail comes from the clerk at the post office, and goes to people, by hand
        local stages = { Q.Contact("Go to the post office (marked) and press E on the postal clerk to collect the mail", office, "citizen",
            "'Three for the district. Two are overdue. Don't tell them I said so.'") }
        for i = 1, 3 do
            local g = math.random() < 0.5 and "male" or "female"
            local name = LC.NewCharacterName(g)
            stages[#stages + 1] = Q.Contact(string.format("Hand letter %d of 3 to %s, %s (marked): go there and press E on them", i, name, doors[i][2]), doors[i][1], "citizen",
                Pick({ "They take it without looking at who sent it.", "'Finally,' they say, and shut the door on the rest of the sentence.",
                    "A nod. Nobody says anything useful in this city out loud.", "They read the envelope twice before they put it away." }),
                { gender = g }) -- whoever answers the door looks like the name on the envelope
        end
        return { title = "Mail round", reward = 25, limit = 600, desc = "Collect three letters from the clerk at the post office, then hand each one to the person it's addressed to.", stages = stages }
    end,
    function(ply, job)
        local office = WorkSpot(ply, job.num)
        local dest = Q.Spot(ply, 600, 3000)
        local family = Q.Spot(ply, 400, 2500)
        if not office or not dest then return nil end
        return {
            title = "Sealed envelope", reward = 20, limit = 480,
            desc = "Collect an envelope with a Civil Protection seal from the post office and deliver it to someone " .. Place(dest, ply:GetPos()) .. ".",
            stages = {
                Q.Contact("Go to the post office (marked) and press E on the clerk to collect the envelope", office, "citizen", "'Hand it over in person. Nobody signs for these.'"),
                Choice("The seal is a Combine stamp, and it's not glued very well. You could probably open it.", {
                    { text = "Deliver it unopened." },
                    { text = "Steam it open and read it (the seal might tear).", check = { "guile", 12 },
                      success = function(q)
                          Insert(q, { Choice("It's an eviction order for the family in 3B, the one with the twins. They have to be out by tomorrow.", {
                              { text = "Deliver it as addressed and say nothing.", pick = function(q2, p) Trait(p, "loyalty", 1) end },
                              { text = "Warn the family before you deliver it.", pick = function(q2, p)
                                  Trait(p, "sympathy", 1)
                                  LC.Bump(p, "silences")
                                  if family then Insert(q2, { Goto(family, "Go to the family's home (marked) to quietly warn them", 150) }) end
                              end },
                          }) })
                      end,
                      fail = function(q) Narrate(q, "The seal tears. You'll have to hope nobody checks.") end },
                }),
                Q.Contact("Take the envelope to the person it's addressed to (marked) and press E on them", dest, "citizen", "They take it with both hands, like it might go off."),
            },
        }
    end,
}

SHIFTS.maintenance = {
    function(ply)
        -- the city's own streetlights, the broken ones first (sv_livingcity_propaganda.lua)
        local lamps = LC.StreetFixtures and LC.StreetFixtures("lc_streetlight", ply:GetPos(), 3000) or {}
        if #lamps > 0 then
            local stages = {}
            for i = 1, math.min(3, #lamps) do
                local lamp = lamps[i]
                local h = Hold(lamp:GetPos(), 8, string.format("Go to streetlight %d of %d (%s) and stay next to it to repair it", i, math.min(3, #lamps), Place(lamp:GetPos(), ply:GetPos())), 130)
                h.onDone = function()
                    Sound("ambient/energy/spark" .. math.random(1, 6) .. ".wav", lamp:GetPos())
                    if LC.RepairStreetFixture then LC.RepairStreetFixture(lamp) end
                end
                stages[i] = h
            end
            return { title = "Lights out", reward = 20, limit = 540, desc = "Streetlights are broken across the district. Go to each one and repair it.", stages = stages }
        end
        local stages = {}
        for i = 1, 3 do
            local sp = Q.Spot(ply, 300, 2500)
            if not sp then return nil end
            local h = Hold(sp, 6, string.format("Go to fuse box %d of 3 (%s) and stay next to it to repair it", i, Place(sp, ply:GetPos())), 100)
            h.onEnter = function(q) Q.SpawnItem(q, "models/props_lab/powerbox02a.mdl", sp) end
            h.onDone = function() Sound("ambient/energy/spark" .. math.random(1, 6) .. ".wav", sp) end
            stages[i] = h
        end
        return { title = "Lights out", reward = 20, limit = 540, desc = "Three fuse boxes are broken across the district. Go to each one and repair it.", stages = stages }
    end,
    function(ply)
        local cps = LC.PointsOfKind("checkpoint")
        local pos = #cps > 0 and Pick(cps).pos or Q.Spot(ply, 400, 2000)
        if not pos then return nil end
        return {
            title = "Terminal fault", reward = 20, limit = 420,
            desc = "A scanner terminal at a checkpoint keeps breaking down. Go there and repair it.",
            stages = {
                Goto(pos, "Go to the broken terminal (marked)", 220),
                Hold(pos, 20, "Stay next to the terminal to repair it", 200),
                Choice("While the terminal reboots, its log scrolls past. One of last night's entries is your neighbor, out at 3 a.m.", {
                    { text = "Leave the log as it is.", pick = function(q, p) Trait(p, "loyalty", 1) end },
                    { text = "Erase your neighbor's entry while you're in there (if you're caught, you're wanted).", check = { "guile", 12 },
                      success = function(q, p)
                          Trait(p, "sympathy", 1)
                          LC.Bump(p, "silences")
                          Narrate(q, "One line of the log becomes noise. Terminals glitch all the time.")
                      end,
                      fail = function(q, p)
                          Narrate(q, "The terminal flags the edit. Every Civil Protection unit in the sector gets the alert. You're now wanted.")
                          LC.ReportCrime(p, "Tampering with a city terminal", 120)
                      end },
                }),
            },
        }
    end,
}

------------------------------------------------------------------------
-- Helpers for the newer jobs
------------------------------------------------------------------------

local function Give(p, id, n) if LC.GiveOrDrop then LC.GiveOrDrop(p, id, n) end end

-- Somewhere people live: a housing block, an apartment doorway, or a street.
local function Residence(ply)
    local blocks = LC.ZonesOfKind("block")
    if #blocks > 0 then
        local z = Pick(blocks)
        return z.pos, LC.BlockName(z.group or 0), math.max(150, math.min(z.r, 300))
    end
    local doors = LC.PointsOfKind("spawn")
    if #doors > 0 then return Pick(doors).pos, "an apartment doorway", 150 end
    local s = Q.Spot(ply, 500, 2500)
    return s, s and Place(s, ply:GetPos()) or "", 150
end

-- Somewhere Civil Protection works: a checkpoint, the prison, or a street.
local function Precinct(ply)
    local cps = LC.PointsOfKind("checkpoint")
    if #cps > 0 then return Pick(cps).pos, "the checkpoint" end
    local z = Q.NearestZone("prison", ply:GetPos())
    if z then return z.pos, "the prison" end
    local s = Q.Spot(ply, 500, 2500)
    return s, s and Place(s, ply:GetPos()) or ""
end

-- Scenery that leaves with the job.
local function Prop(q, cls, model, pos)
    local e = ents.Create(cls)
    if not IsValid(e) then return nil end
    e:SetModel(model)
    e:SetPos(pos + Vector(0, 0, 8))
    e:Spawn()
    q.ents[#q.ents + 1] = e
    return e
end

-- Drop the next stage (the plan changed).
local function SkipNext(q) table.remove(q.stages, q.stage + 1) end

local BODIES = {
    "models/humans/group01/male_01.mdl", "models/humans/group01/male_09.mdl",
    "models/humans/group01/female_02.mdl", "models/humans/group01/male_06.mdl",
}
local METAL = {
    "models/props_junk/garbage_metalcan002a.mdl", "models/props_c17/metalpot001a.mdl",
    "models/props_junk/metal_paintcan001a.mdl", "models/props_c17/canister01a.mdl",
}
local RUBBLE = { "models/props_junk/rock001a.mdl", "models/props_debris/wood_chunk03a.mdl" }

------------------------------------------------------------------------
-- Intake Processor
------------------------------------------------------------------------

SHIFTS.porter = {
    function(ply, job)
        local platform = WorkSpot(ply, job.num, 300, 2000)
        local home, homeName, homeR = Residence(ply)
        if not platform or not home then return nil end
        return {
            title = "New arrivals", reward = 20, limit = 540,
            desc = "A train has arrived. Meet one of the new arrivals on the platform and walk him to his assigned housing.",
            stages = {
                {
                    kind = "target", action = "reach", r = 140, text = "Go to the new arrival on the platform (marked)",
                    onEnter = function(q, st)
                        local npc = Q.SpawnActor(q, "citizen", platform, 900)
                        if not npc then return false end
                        q.data.actor = npc
                        st.npc = npc
                        q.data.dest, q.data.destName, q.data.destR = home, homeName, homeR
                    end,
                },
                Choice("He's holding a transfer slip like it might bite him. Under his breath he asks: 'Is there anywhere in this city they don't look?'", {
                    { text = "Tell him: 'Go to your block and keep your head down.'", pick = function(q, p) Trait(p, "loyalty", 1) end },
                    { text = "Tell him about the canals (rebel territory) and walk him there instead.",
                      when = function() return #LC.ZonesOfKind("rebel") > 0 end,
                      pick = function(q, p)
                          Trait(p, "sympathy", 1)
                          LC.Bump(p, "silences")
                          local pos, r, name = Q.SafeHouse(p)
                          q.data.dest, q.data.destR, q.data.destName = pos, r, name
                          Narrate(q, "He doesn't say thank you. He doesn't have to.")
                      end },
                    { text = "Report what he said to a Civil Protection unit.", pick = function(q, p)
                        Trait(p, "loyalty", 2)
                        LC.Bump(p, "reports")
                        if IsValid(q.data.actor) and LC.ArrestNPC then LC.ArrestNPC(q.data.actor, nil) end
                        Narrate(q, "A Civil Protection unit takes him by the arm. He looks back at you once.")
                        SkipNext(q)
                    end },
                }),
                {
                    kind = "escort", vanish = true, text = "Walk him to his new home (marked)",
                    onEnter = function(q, st)
                        st.npc = q.data.actor
                        if not IsValid(st.npc) then return false end
                        st.pos, st.r = q.data.dest, q.data.destR or 200
                        st.text = "Walk him to " .. (q.data.destName or "his new home")
                    end,
                },
            },
        }
    end,
    function(ply, job)
        local platform = WorkSpot(ply, job.num, 300, 2000)
        local dest, destName = Residence(ply)
        if not platform or not dest then return nil end
        return {
            title = "Luggage", reward = 15, limit = 480,
            desc = "A suitcase was left on the train platform. Pick it up and return it to its owner, " .. destName .. ".",
            stages = {
                { kind = "pickup", pos = platform, model = "models/props_c17/suitcase_passenger_physics.mdl",
                  text = "Go to the platform (marked) and press E on the suitcase to pick it up" },
                Choice("The suitcase is heavier than clothes. Something inside slides and settles, like a stack of paper.", {
                    { text = "Just carry it. It's not your business." },
                    { text = "Open it and look inside (if you're caught, you're wanted).", check = { "guile", 11 },
                      success = function(q, p)
                          Narrate(q, "Under the shirts: a stack of blank identity forms. You take one. Nobody counts them twice.")
                          Give(p, "papers_blank")
                          LC.Bump(p, "thefts")
                      end,
                      fail = function(q, p)
                          Narrate(q, "The latches snap open loud enough to turn heads. A Civil Protection unit is already walking over. You're now wanted.")
                          LC.ReportCrime(p, "Theft from a traveler", 90)
                      end },
                    { text = "Hand it to Civil Protection.", pick = function(q, p)
                        Trait(p, "loyalty", 2)
                        LC.Bump(p, "reports")
                        SkipNext(q)
                        Insert(q, { Count("used_npc", 1, "Find a Civil Protection unit and press E on them to hand over the suitcase", Q.IsCopNPC) })
                    end },
                }),
                Q.Contact("Take the suitcase to its owner, " .. destName .. " (marked), and press E on them", dest, "citizen", "'That's mine. I thought I'd lost it.' They don't say thank you."),
            },
        }
    end,
    function(ply, job)
        local platform = WorkSpot(ply, job.num, 300, 2000)
        if not platform then return nil end
        return {
            title = "Ticket check", reward = 20, limit = 540,
            desc = "Check the ticket and transit permit of everyone boarding the train.",
            stages = {
                Goto(platform, "Go to the train platform (marked)", 220),
                Count("used_npc", 3, "Check three travelers' tickets: press E on citizens on the platform", Q.IsCitizenNPC),
                Choice("An old woman has a ticket, but no transit permit. \"I'm going to see my son,\" she says. \"He's in Nova Prospekt.\"", {
                    { text = "Let her board anyway (if you're caught, you're wanted).", check = { "guile", 10 },
                      success = function(q, p)
                          Trait(p, "sympathy", 1)
                          LC.Bump(p, "silences")
                          Narrate(q, "She squeezes your hand on the way past. It's the last train she'll ever take, and you both know it.")
                      end,
                      fail = function(q, p)
                          Narrate(q, "The platform scanner flags her before she reaches the door. And you, for letting her through: you're now wanted.")
                          LC.ReportCrime(p, "Aiding unauthorized travel", 90)
                      end },
                    { text = "Refuse, and send her back.", pick = function(q, p) Trait(p, "loyalty", 1) end },
                    { text = "Report her to Civil Protection.", pick = function(q, p)
                        Trait(p, "loyalty", 2)
                        LC.Bump(p, "reports")
                        Insert(q, { Count("used_npc", 1, "Find a Civil Protection unit and press E on them to report her", Q.IsCopNPC) })
                    end },
                }),
            },
        }
    end,
}

------------------------------------------------------------------------
-- (Records Clerk and Uniform Laundry are NPC jobs only: standing at a desk
-- or a machine was no work for a player. sh_livingcity_jobs.lua)
------------------------------------------------------------------------

------------------------------------------------------------------------
-- Mortician
------------------------------------------------------------------------

-- Hauling a body to the incinerator (sv_livingcity_mortuary.lua). Done when
-- that body goes in; if somebody else sees to it first, that counts too.
local function HaulStage(text)
    local st = Count("cremated", 1, text, function(q, _, body) return body == q.data.body end, false)
    st.onEnter = function(q, s)
        local body = q.data.body
        local proc = LC.NearestBodyProcessor and LC.NearestBodyProcessor(IsValid(body) and body:GetPos() or q.owner:GetPos())
        if not proc then return false end
        s.pos, s.r = proc.pos, 200
        s.text = text .. ", " .. proc.name
    end
    st.poll = function(q)
        if not IsValid(q.data.body) then
            q.data.body = "gone"
            LC.QuestEvent("cremated", q.owner, "gone")
        end
    end
    return st
end

local function Unclaim(q) if q.data and IsValid(q.data.body) and q.data.body.lcBody then q.data.body.lcBody.claimed = nil end end

SHIFTS.mortuary = {
    function(ply)
        -- a real body if the city has left one lying about, or a reported one
        local proc = LC.NearestBodyProcessor and LC.NearestBodyProcessor(ply:GetPos())
        if not proc then return nil end -- no incinerator and no morgue: nowhere to take them
        local body = LC.UnclaimedBody and LC.UnclaimedBody(ply:GetPos(), 3500)
        local spot = IsValid(body) and body:GetPos() or Q.Spot(ply, 400, 2500)
        local home, homeName = Residence(ply)
        if not spot then return nil end
        local go = Goto(spot, "Go to the body " .. Place(spot, ply:GetPos()), 150)
        go.onEnter = function(q)
            if IsValid(body) and not body.lcBody.claimed and not (LC.HauledBy and LC.HauledBy(body)) then
                q.data.body = body
                body.lcBody.claimed = true
            else
                q.data.body = LC.SpawnBody and LC.SpawnBody(Pick(BODIES), spot) or Prop(q, "prop_ragdoll", Pick(BODIES), spot)
                if IsValid(q.data.body) then
                    q.data.body.lcBody = q.data.body.lcBody or { role = "citizen" }
                    q.data.body.lcBody.claimed = true
                    q.ents[#q.ents + 1] = q.data.body
                end
            end
            if IsValid(q.data.body) then go.pos = q.data.body:GetPos() end
        end
        return {
            title = "Collection", reward = 20, limit = 600,
            desc = "A body was reported " .. Place(spot, ply:GetPos()) .. ". Nobody has claimed it. Collect it and take it to the incinerator or morgue.",
            onFinish = Unclaim,
            stages = {
                go,
                Choice("His coat pocket holds identity papers, still valid. Nobody has reported him dead yet.", {
                    { text = "Hand everything in, papers included.", pick = function(q, p) Trait(p, "loyalty", 1) end },
                    { text = "Keep his identity papers.", pick = function(q, p)
                        Give(p, "papers_dead")
                        LC.Bump(p, "thefts")
                        Narrate(q, "They're good papers. They'll be good for somebody.")
                    end },
                    { text = "Tell his family before you take him away.", pick = function(q, p)
                        Trait(p, "sympathy", 1)
                        if home then Insert(q, { Goto(home, "Go and tell his family: " .. homeName, 160) }) end
                    end },
                }),
                HaulStage("Drag the body (press E on it to grab it, E again to let go) to the marked spot"),
            },
        }
    end,
    function(ply, job)
        -- clear the streets: whatever bodies are lying around
        local proc = LC.NearestBodyProcessor and LC.NearestBodyProcessor(ply:GetPos())
        if not proc then return nil end
        local n = 0
        for _, b in ipairs(LC.Bodies or {}) do
            if IsValid(b.ent) and b.ent.lcBody and not b.ent.lcBody.claimed and not (LC.HauledBy and LC.HauledBy(b.ent)) then n = n + 1 end
        end
        if n < 2 then return nil end
        n = math.min(3, n)
        local st = Count("cremated", n, string.format("Drag %d bodies off the streets to %s (press E on a body to grab it, E again to let go)", n, proc.name), nil, false)
        st.pos, st.r = proc.pos, 200
        return {
            title = "Clear the streets", reward = 15 + 10 * n, limit = 900,
            desc = "There's been trouble, and bodies are lying in the streets. Take them to the incinerator or morgue: the city wants them gone before morning.",
            stages = { st },
        }
    end,
    function(ply, job)
        local incs = LC.EntsOf("lc_incinerator")
        local inc = #incs > 0 and Pick(incs) or nil
        local morgue = IsValid(inc) and inc:GetPos() or WorkSpot(ply, job.num)
        if not morgue then return nil end
        local work = Hold(morgue, 30, "Stay at the incinerator for 30 seconds to burn the bodies", 160)
        work.onDone = function() if IsValid(inc) then inc:SetNW2Float("lc_burn_until", CurTime() + 8) end end
        return {
            title = "Incinerator", reward = 15, limit = 420,
            desc = "The incinerator runs all night, and somebody has to feed it the bodies. Go there and work it.",
            stages = {
                Goto(morgue, IsValid(inc) and "Go to the incinerator (marked)" or "Go to the morgue (marked)", 180),
                work,
                Choice("The next body still has a wedding ring on.", {
                    { text = "Leave the ring on her." },
                    { text = "Keep the ring for yourself.", pick = function(q, p)
                        Trait(p, "corruption", 1)
                        Give(p, "keepsake")
                    end },
                    { text = "Set the ring aside for her family.", pick = function(q, p) Trait(p, "sympathy", 1) end },
                }),
            },
        }
    end,
}

-- Dead headcrabs: bag every carcass lying about (or the ones reported), burn them
SHIFTS.mortuary[#SHIFTS.mortuary + 1] = function(ply, job)
    local proc = LC.NearestBodyProcessor and LC.NearestBodyProcessor(ply:GetPos())
    if not proc then return nil end
    local real, spots = {}, {}
    for _, e in ipairs(LC.EntsOf("lc_item")) do
        if LC.CrabCarcass and LC.CrabCarcass(e) and not e.lcBagging and e:GetPos():DistToSqr(ply:GetPos()) < 3500 * 3500 and #spots < 6 then
            real[#real + 1] = e
            spots[#spots + 1] = e:GetPos()
        end
    end
    if #spots < 3 then
        local c = Q.Spot(ply, 300, 2000)
        if not c then return nil end
        for _, sp in ipairs(Q.HideSpots(c, 4 - #spots, 600, true)) do spots[#spots + 1] = sp end
    end
    if #spots < 2 then return nil end
    local bag = { kind = "collect", spots = spots, models = { "models/headcrabclassic.mdl" }, need = #spots,
        text = "Find the dead headcrabs and press E on each one to bag it" }
    bag.onEnter = function(q)
        for _, e in ipairs(real) do if IsValid(e) then e:Remove() end end -- (the bag stage puts its own where they lay)
    end
    local burn = Deliver(proc.pos, "Take the bags to " .. proc.name .. " (marked) to burn them", 200)
    burn.onDone = function() if IsValid(proc.ent) then proc.ent:SetNW2Float("lc_burn_until", CurTime() + 8) end end
    return {
        title = "Headcrab collection", reward = 10 + 3 * #spots, limit = 600,
        desc = "Dead headcrabs left lying in the street breed flies and worse. Bag every one, then take them to be burned.",
        stages = { bag, burn },
    }
end

------------------------------------------------------------------------
-- Reclamation Crew
------------------------------------------------------------------------

SHIFTS.scrap = {
    function(ply, job)
        local yard = WorkSpot(ply, job.num)
        local center = Q.Spot(ply, 300, 2000)
        if not yard or not center then return nil end
        return {
            title = "Scrap run", reward = 20, limit = 540,
            desc = "Scrap metal is lying " .. Place(center, ply:GetPos()) .. ". Collect 5 pieces and bring them to the reclamation yard. The Union needs all of it.",
            stages = {
                { kind = "collect", spots = Q.HideSpots(center, 5, 700, true), models = METAL, need = 5,
                  text = "Collect the scrap: press E on each piece (5 in all)" },
                Choice("One good piece of copper wasn't on anybody's list.", {
                    { text = "Log it with the rest.", pick = function(q, p) Trait(p, "loyalty", 1) end },
                    { text = "Keep it to sell to the dealer (you get 2 scrap).", pick = function(q, p)
                        Give(p, "scrap", 2)
                        LC.Bump(p, "thefts")
                    end },
                }),
                Deliver(yard, "Bring the scrap to the reclamation yard (marked)", 180),
            },
        }
    end,
    function(ply)
        local stages, used = {}, {}
        for i = 1, 3 do
            local sp = Marked("rubble", ply, used) or Q.Spot(ply, 300, 2500)
            if not sp then return nil end
            local h = Hold(sp, 8, string.format("Go to rubble pile %d of 3 (%s) and stay next to it to clear it", i, Place(sp, ply:GetPos())), 110)
            h.onEnter = function(q) Q.SpawnItem(q, Pick(RUBBLE), sp) end
            stages[#stages + 1] = h
        end
        table.insert(stages, 3, Choice("Under the bricks: a canvas bag. Inside, a pistol and a magazine wrapped in oilcloth. Someone hid it here on purpose.", {
            { text = "Report the hidden gun to Civil Protection.", pick = function(q, p)
                Trait(p, "loyalty", 2)
                LC.Bump(p, "reports")
                Insert(q, { Count("used_npc", 1, "Find a Civil Protection unit and press E on them to report the gun", Q.IsCopNPC) })
            end },
            { text = "Leave it where it is.", pick = function(q, p)
                LC.Bump(p, "silences")
                Narrate(q, "You put the bricks back exactly how they were.")
            end },
            { text = "Take the pistol (if a unit sees you take it, you're wanted).", pick = function(q, p)
                p:Give("weapon_pistol")
                p:GiveAmmo(18, "Pistol")
                if LC.SeenBySecurity and LC.SeenBySecurity(p, 900) then
                    Narrate(q, "A Civil Protection unit saw you pull the gun out of the rubble. You're now wanted.")
                    LC.ReportCrime(p, "Possession of a firearm", 240)
                else
                    Narrate(q, "It's cold and heavy and nobody saw.")
                end
            end },
        }))
        return { title = "Rubble clearing", reward = 20, limit = 600, desc = "Clear three piles of rubble left over from the old city.", stages = stages }
    end,
}

------------------------------------------------------------------------
-- (Radio Repair, Uniform Laundry and the Records Clerk are games only: see
-- the end of this file and sv_livingcity_moregames.lua.)
------------------------------------------------------------------------

------------------------------------------------------------------------
-- The shift chain: one personal posting at a time, forever
------------------------------------------------------------------------

------------------------------------------------------------------------
-- Work you actually do (sv_livingcity_jobgames.lua): the street sweep, the
-- factory line and the papers check take the place of the shifts that were
-- standing at a spot. lc_jobgames 0 puts the old ones back.
------------------------------------------------------------------------

local function GamesOn() return LC.JobGamesOn and LC.JobGamesOn() end

-- Arriving at a stage starts the game; the next stage is the game itself.
local function GameGo(pos, text, kind, opts)
    local go = Goto(pos, text, 180)
    go.onDone = function(q) if IsValid(q.owner) then LC.JobGameStart(q.owner, kind, q, opts) end end
    return go
end
local function GameStage(text) return Count("game_done", 1, text) end

-- An old shift, with its standing (stage idx) turned into a game started by the stage before it.
local function Gamify(spec, idx, kind, text, opts)
    if not spec or not spec.stages[idx] or idx < 2 then return spec end
    local before = spec.stages[idx - 1]
    local o = opts or {}
    o.station = o.station or before.pos
    o.depot = o.depot or before.pos
    before.onDone = function(q) if IsValid(q.owner) then LC.JobGameStart(q.owner, kind, q, o) end end
    spec.stages[idx] = GameStage(text)
    return spec
end

-- Every "stand here" stage of a shift as a game there: a walk to the spot
-- (with the stage's own setting-up), then the game (with its finishing-off).
local function GamifyHolds(spec, kind, text, opts, keepEnter)
    if not spec then return spec end
    local out = {}
    for _, st in ipairs(spec.stages) do
        if st.kind == "hold" then
            local go = Goto(st.pos, st.text, st.r or 150)
            if keepEnter then go.onEnter = st.onEnter end
            local o = table.Copy(opts or {})
            o.pos, o.what = st.pos, o.what
            go.onDone = function(q) if IsValid(q.owner) then LC.JobGameStart(q.owner, kind, q, o) end end
            local gs = GameStage(type(text) == "function" and text(st) or text)
            gs.onDone = st.onDone
            out[#out + 1] = go
            out[#out + 1] = gs
        else
            out[#out + 1] = st
        end
    end
    spec.stages = out
    return spec
end

local LINE_TEXT = "Work the line: throw the bad parts (rust-red and sparking) in the scrap bin and let the good ones pass. E grabs a part, left click throws it"

do
    local litter = SHIFTS.sanitation[1]
    SHIFTS.sanitation[1] = function(ply, job)
        if not GamesOn() then return litter(ply, job) end
        local depot = WorkSpot(ply, job.num, 300, 1500)
        local spots = depot and Q.HideSpots(depot, 10, 900, true) or {}
        if not depot or #spots < 5 then return litter(ply, job) end
        return {
            title = "Street sweep", reward = 10, limit = 600,
            desc = "Take your cart from the sanitation depot, fill it with rubbish from the streets and bring it back. You're paid credits for every piece in the cart.",
            stages = {
                GameGo(depot, "Go to the sanitation depot (marked): your cart is there", "sweep", { depot = depot, spots = spots }),
                GameStage("Fill the cart and push it back to the depot. E on the cart grabs it to push (E again lets go). E picks up rubbish, left click throws it in the cart"),
            },
        }
    end

    local quota = SHIFTS.factory[1]
    SHIFTS.factory[1] = function(ply, job)
        if not GamesOn() then return quota(ply, job) end
        local station = WorkSpot(ply, job.num)
        if not station then return nil end
        return {
            title = "On the line", reward = 10, limit = 600,
            desc = "Work the factory line: throw the bad parts in the scrap bin before they reach the end. Good parts go through.",
            stages = { GameGo(station, "Go to the factory line (marked)", "line", { station = station }), GameStage(LINE_TEXT) },
        }
    end
    local seal = SHIFTS.kitchen[1]
    SHIFTS.kitchen[1] = function(ply, job)
        if not GamesOn() then return seal(ply, job) end
        local station = WorkSpot(ply, job.num)
        if not station then return nil end
        return {
            title = "The sealing line", reward = 10, limit = 600,
            desc = "Ration bars and gel get sealed in foil here, thousands a day. Throw the split packs in the reject bin: only sealed ones go through.",
            stages = { GameGo(station, "Go to the sealing line at the ration plant (marked)", "line", { station = station, variant = "rations" }),
                GameStage("Work the sealing line: throw split, leaking packs (sickly green) in the reject bin and let the sealed ones pass. E grabs a pack, left click throws it") },
        }
    end
    local short = SHIFTS.factory[3]
    SHIFTS.factory[3] = function(ply, job)
        local spec = short(ply, job)
        if spec and GamesOn() then spec = Gamify(spec, 2, "line", LINE_TEXT) end
        return spec
    end
    -- The loading dock (two crates, a long walk each way) is the Intake Processor's work now; the
    -- factory floor gets more of the line instead (the owner: "an absolute grind").
    local dock = SHIFTS.factory[2]
    SHIFTS.porter[#SHIFTS.porter + 1] = function(ply, job)
        local spec = dock(ply, job)
        if spec then
            spec.title, spec.desc = "Freight from the dock", "Carry two crates, one at a time, from the loading dock to the station."
            for _, st in ipairs(spec.stages or {}) do
                if st.text then st.text = string.gsub(st.text, "the factory floor", "the station") end
            end
        end
        return spec
    end
    SHIFTS.factory[2] = function(ply, job)
        local station = WorkSpot(ply, job.num)
        if not station then return nil end
        if GamesOn() then
            return {
                title = "Overtime on the line", reward = 10, limit = 600,
                desc = "The quota went up again. Work the factory line: bad parts in the scrap bin, good ones through. The line doesn't stop for you.",
                stages = { GameGo(station, "Go to the factory line (marked)", "line", { station = station }), GameStage(LINE_TEXT) },
            }
        end
        return {
            title = "Overtime on the line", reward = 20, limit = 420, desc = "The quota went up again. Go to the factory line and work it.",
            stages = { Goto(station, "Go to the factory line (marked)", 180), Hold(station, 40, "Stay at the line for 40 seconds to work it", 160) },
        }
    end

    -- Maintenance: every repair is a wiring panel
    for i, build in ipairs(SHIFTS.maintenance) do
        SHIFTS.maintenance[i] = function(ply, job)
            local spec = build(ply, job)
            if spec and GamesOn() then
                spec = GamifyHolds(spec, "wiring", "Rewire it: click the tiles to turn them (right-click turns back) until the current reaches the lamp. Don't turn a tile while it's sparking: it shocks you",
                    { what = string.find(spec.title, "Terminal", 1, true) and "the terminal" or "the box" }, true)
            end
            return spec
        end
    end

    -- Clinic Medic: rounds are triage
    local rounds = SHIFTS.medic[1]
    SHIFTS.medic[1] = function(ply, job)
        if not GamesOn() then return rounds(ply, job) end
        local center = WorkSpot(ply, job.num)
        if not center then return nil end
        return {
            title = "Triage", reward = 10, limit = 600,
            desc = "Patients are coming into the clinic faster than you can treat them. Treat the worst hurt first.",
            stages = {
                GameGo(center, "Go to the clinic (marked)", "triage", { center = center, spots = Q.SpotsNear(center, 4, 260) }),
                GameStage("Heal the patients with your medkit (primary fire, left click) before they bleed out. The bar over each one's head shows who's worst"),
            },
        }
    end

    -- Reclamation Crew: rubble is something you break up
    local rubble = SHIFTS.scrap[2]
    SHIFTS.scrap[2] = function(ply, job)
        local spec = rubble(ply, job)
        if spec and GamesOn() then spec = GamifyHolds(spec, "rubble", "Break up the rubble: hit it with your crowbar (primary fire, left click)") end
        return spec
    end

    local ticket = SHIFTS.porter[3]
    SHIFTS.porter[3] = function(ply, job)
        local spec = ticket(ply, job)
        if spec and GamesOn() then
            spec = Gamify(spec, 2, "papers", "Check the travelers' papers: press E on each traveler, then approve, deny, or call a Civil Protection unit")
            spec.title = "Papers check"
            spec.reward = 10
            spec.desc = "Check the papers and permits of everyone boarding the train. Today's rules are shown next to their papers."
        end
        return spec
    end
end

-- The rest of the hands-on games (sv_livingcity_moregames.lua)
do
    -- Courier: a parcel run against the clock (they aren't letters)
    SHIFTS.courier[#SHIFTS.courier + 1] = function(ply, job)
        if not GamesOn() then return nil end
        local office = WorkSpot(ply, job.num)
        if not office then return nil end
        local stops = {}
        for _, z in ipairs(LC.ZonesOfKind("block")) do stops[#stops + 1] = { pos = z.pos, name = LC.BlockName(z.group) } end
        for _, p in ipairs(LC.PointsOfKind("spawn")) do stops[#stops + 1] = { pos = p.pos, name = "an apartment doorway" } end
        Q.Shuffle(stops)
        while #stops > 3 do table.remove(stops) end
        while #stops < 3 do
            local sp = Q.Spot(ply, 500, 2500)
            if not sp then return nil end
            stops[#stops + 1] = { pos = sp, name = Place(sp, ply:GetPos()) }
        end
        return {
            title = "Parcel run", reward = 10, limit = 900,
            desc = "Deliver three parcels before time runs out: the faster you are, the more you're paid. They aren't letters, and nobody tells you what's in them.",
            stages = {
                GameGo(office, "Go to the post office (marked) to collect the parcels", "parcel", { stops = stops }),
                GameStage("Deliver the parcels to the marked spots before time runs out. Civil Protection units stop couriers they get a good look at, so crouch when you pass them"),
            },
        }
    end

    -- Mortuary: the incinerator shift is searching the dead before they go in
    local incinerator = SHIFTS.mortuary[3]
    SHIFTS.mortuary[3] = function(ply, job)
        if not GamesOn() then return incinerator(ply, job) end
        local incs = LC.EntsOf("lc_incinerator")
        local inc = #incs > 0 and Pick(incs) or nil
        local morgue = IsValid(inc) and inc:GetPos() or WorkSpot(ply, job.num)
        if not morgue then return nil end
        local slab = IsValid(inc) and (inc:GetPos() + inc:GetForward() * 90) or morgue
        return {
            title = "Before the fire", reward = 10, limit = 600,
            desc = "Three bodies go in the incinerator tonight. Search every pocket first. The overseer checks on you now and then: don't get caught keeping anything.",
            stages = {
                GameGo(morgue, IsValid(inc) and "Go to the incinerator (marked)" or "Go to the morgue (marked)", "search", { pos = slab, inc = inc }),
                GameStage("Search each body before it goes in: press E on it, check every pocket, then put it in the fire"),
            },
        }
    end

    -- The jobs that were the city's own: each shift is a game at the workplace
    local function AtWork(kind, title, desc, go, text)
        return function(ply, job)
            if not GamesOn() then return nil end
            local at = WorkSpot(ply, job.num)
            if not at then return nil end
            return { title = title, reward = 10, limit = 600, desc = desc,
                stages = { GameGo(at, go, kind), GameStage(text) } }
        end
    end
    SHIFTS.laundry = { AtWork("laundry", "Sorting", "Sort the washed and pressed Civil Protection uniforms back to their own divisions. Civil Protection units leave things in their pockets.",
        "Go to the Nexus laundry (marked)", "Put each uniform in its division's bin (the bins are labelled). Bloodstained ones go to the incident wash. If you close the window, press E to open it again") }
    SHIFTS.clerk = { AtWork("filing", "Filing", "File the in-tray by citizen number. Any form that doesn't match the register goes in the discrepancy tray.",
        "Go to the civil records office (marked)", "File every form in its drawer by citizen number. Forms that don't match the register go in the discrepancy tray. If you close the window, press E to open it again") }
    SHIFTS.radio = { AtWork("radio", "Repairs", "Four radio sets on the shelf, all hissing. Tune each one to its station, then adjust its screws until the sound comes through clean.",
        "Go to the radio repair shop (marked)", "Repair the sets: turn the dial to the station, then turn the screws while you listen, until the static is gone. If you close the window, press E to open it again") }
end

-- (tests: finish a game at once)
LC.JobGameFinishForTest = function(ply) if LC.JobGames and LC.JobGames[ply] then LC.JobGameEnd(ply, "test") else LC.QuestEvent("game_done", ply) end end

local function Employed(ply) return LC.Job(ply) ~= nil and LC.CanWork(ply) end

LC.Chain{
    id = "shift", name = "Union shift", factions = { citizen = true, resistance = true }, flat = true,
    unlock = Employed, gate = Employed,
    start = "work",
    parts = {
        work = { num = 1, next = "work", build = function(ply)
            local job = LC.Job(ply)
            local list = job and SHIFTS[job.id]
            if not list then return nil end
            local order = {}
            for i = 1, #list do order[i] = i end
            for _, i in ipairs(Q.Shuffle(order)) do
                local spec = list[i](ply, job)
                if spec then
                    spec.title = job.name .. ": " .. spec.title
                    local last = spec.stages[#spec.stages]
                    local prev = last.onDone
                    last.onDone = function(q, st)
                        if prev then prev(q, st) end
                        LC.Bump(q.owner, "shifts")
                    end
                    return spec
                end
            end
            return nil
        end },
    },
}

------------------------------------------------------------------------
-- Civil rehabilitation: community service for anyone whose Civil Standing
-- has gone below zero. No job needed, no pay, just standing (+40 a shift,
-- see sv_livingcity_economy.lua). Turning yourself in to a unit and serving
-- your time is the other way back.
------------------------------------------------------------------------

local function NeedsRehab(ply)
    if not LC.Standing or LC.Standing(ply) >= 0 or LC.PlayerIsCP(ply) then return false end
    if LC.PlayerIsHunted and LC.PlayerIsHunted(ply) and not (LC.PassesAsCitizen and LC.PassesAsCitizen(ply)) then return false end
    return true
end
LC.NeedsRehab = NeedsRehab

LC.Chain{
    id = "rehab", name = "Civil rehabilitation", factions = { citizen = true, resistance = true }, flat = true,
    unlock = NeedsRehab, gate = NeedsRehab,
    start = "service",
    parts = {
        service = { num = 1, next = "service", build = function(ply)
            local job = LCJ.ById.sanitation
            local order = Q.Shuffle({ 1, 2 }) -- a litter sweep or a bin round; nothing with choices in it
            for _, i in ipairs(order) do
                local spec = SHIFTS.sanitation[i](ply, job)
                if spec then
                    spec.title = "Community service: " .. spec.title
                    spec.desc = string.format("Your Civil Standing is %d. %s Each shift of service restores 40.",
                        LC.Standing(ply), spec.desc)
                    return spec
                end
            end
            return nil
        end },
    },
}

concommand.Add("lc_setjob", function(ply, _, args)
    if IsValid(ply) and not ply:IsAdmin() then return end
    local target = LC.FindPlayer(args[1])
    if not target then return end
    LC.SetJob(target, args[2] or "", true)
end)
