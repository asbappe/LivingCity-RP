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
    if id ~= "" and not job then return false, "No such job." end
    if not force then
        if not LC.CanWork(ply) then return false, "The Union only employs citizens." end
        if id ~= "" and LC.IntakePending and LC.IntakePending(ply) then
            return false, "The Union only employs registered citizens. Register at Civil Intake first."
        end
        if (ply.lcjNext or 0) > CurTime() then
            return false, "You can change jobs again in " .. math.ceil(ply.lcjNext - CurTime()) .. " seconds."
        end
    end
    ply:SetNW2String("lcj_job", id)
    ply:SetPData("lcj_job", id)
    ply.lcjNext = CurTime() + cvCooldown:GetFloat()
    local s = LC.Story(ply)
    s.chains.shift = nil
    LC.SaveStory(ply)
    if ply.lcStoryPostings then ply.lcStoryPostings.shift = nil end
    GiveTools(ply)
    if job then ply:ChatPrint("[Union] You are now employed as: " .. job.name .. ". Your shifts appear on your board (F3).") end
    return true
end

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
            desc = "Clear the litter " .. Place(center, ply:GetPos()) .. ".",
            stages = { { kind = "collect", spots = Q.HideSpots(center, 5, 700, true), models = Q.TRASH, need = 5,
                text = "Pick up the litter (press E)" } },
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
            local h = Hold(sp, 6, string.format("Empty bin %d of 3, %s", i, Place(sp, ply:GetPos())), 110)
            if bin then
                h.item = bin.ent
            else
                h.onEnter = function(q, st) st.item = Q.SpawnItem(q, "models/props_trainstation/trashcan_indoor001a.mdl", sp) end
            end
            stages[i] = h
        end
        return { title = "Bin round", reward = 15, limit = 480, desc = "Three bins, overflowing again.", stages = stages }
    end,
    function(ply)
        local sp = Marked("graffiti", ply) or Q.Spot(ply, 300, 2000)
        if not sp then return nil end
        return {
            title = "Graffiti removal", reward = 20, limit = 420,
            desc = "Graffiti reported " .. Place(sp, ply:GetPos()) .. ".",
            stages = {
                Goto(sp, "Go to the reported graffiti", 150),
                Choice("Someone has sprayed a lambda and a name across the wall. You know the name: your neighbor's boy.", {
                    { text = "Scrub all of it off.", pick = function(q, p) Trait(p, "loyalty", 1) end },
                    { text = "Scrub the name. Leave the lambda.", check = { "guile", 11 },
                      success = function(q, p)
                          Trait(p, "sympathy", 1)
                          LC.Bump(p, "silences")
                          Narrate(q, "Somebody will see that lambda tomorrow and feel a little less alone.")
                      end,
                      fail = function(q, p)
                          Narrate(q, "A unit on the corner watches you skip it.")
                          LC.ReportCrime(p, "Defacing city property", 90)
                      end },
                    { text = "Report the name to a unit.", pick = function(q, p)
                        Trait(p, "loyalty", 2)
                        LC.Bump(p, "reports")
                        Insert(q, { Count("used_npc", 1, "Report the name to a unit (press E)", Q.IsCopNPC) })
                    end },
                }),
                Hold(sp, 5, "Scrub the wall (crouch)", 100, true),
            },
        }
    end,
}

SHIFTS.kitchen = {
    function(ply, job)
        local station = WorkSpot(ply, job.num)
        if not station then return nil end
        return {
            title = "Prep shift", reward = 15, limit = 360,
            desc = "Ration packs don't assemble themselves. Report to the kitchen.",
            stages = { Goto(station, "Go to the kitchen", 180), Hold(station, 40, "Prepare ration packs", 160) },
        }
    end,
    function(ply, job)
        local truck = Marked("dock", ply) or Q.Spot(ply, 600, 2500)
        local lines = table.GetKeys(LC.Lines or {})
        local dest = #lines > 0 and LC.Lines[Pick(lines)].slots[1].pos or WorkSpot(ply, job.num)
        if not truck or not dest then return nil end
        return {
            title = "Supply run", reward = 20, limit = 480,
            desc = "The supply truck is waiting " .. Place(truck, ply:GetPos()) .. ". Bring the driver's crate in.",
            stages = {
                Q.Contact("Get the ration crate from the truck driver (press E)", truck, "citizen", "'Sign here. No, nobody has a pen. Just take it.'"),
                Q.Contact("Hand the crate to the kitchen hand at the distribution point (press E)", dest, "citizen",
                    "She counts the packs twice and doesn't say what the number should have been."),
            },
        }
    end,
    function(ply)
        local lines = table.GetKeys(LC.Lines or {})
        if #lines == 0 or not LC.Running then return nil end
        local g = Pick(lines)
        local front = LC.Lines[g].slots[1].pos
        return {
            title = "Serve the line", reward = 25, limit = 600,
            desc = "You're on the counter at ration line " .. g .. " today.",
            stages = {
                Goto(front, "Take your place at the counter", 220),
                Choice("A mother with two small children holds out a single ration card. She doesn't say anything. She doesn't have to.", {
                    { text = "Follow the rules. One card, one ration.", pick = function(q, p) Trait(p, "loyalty", 1) end },
                    { text = "Slip her an extra ration.", check = { "guile", 10 },
                      success = function(q, p)
                          Trait(p, "sympathy", 1)
                          LC.Bump(p, "silences")
                          Narrate(q, "It's gone into her coat before anyone sees. The older child looks back at you all the way out.")
                      end,
                      fail = function(q, p)
                          Narrate(q, "The supervisor saw. 'Ration fraud,' he says, almost bored.")
                          LC.ReportCrime(p, "Ration fraud", 120)
                      end },
                }),
                { kind = "count", event = "served", need = 3, pos = front, r = 320, distinct = false,
                  text = "Serve the line (stay at the counter)" },
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
            desc = "Three patients waiting. Use your medkit on them until they're on their feet.",
            stages = {
                Goto(center, "Go to the clinic", 200),
                Patients(Q.SpotsNear(center, 3, 300), "Treat the injured (medkit, primary fire)"),
            },
        }
    end,
    function(ply)
        local sp = Q.Spot(ply, 400, 2500)
        if not sp then return nil end
        return {
            title = "House call", reward = 25, limit = 480,
            desc = "A man was hurt " .. Place(sp, ply:GetPos()) .. ". He can't walk to the clinic.",
            stages = {
                {
                    kind = "target", action = "reach", r = 140, text = "Find the injured man (marked)", pos = sp,
                    onEnter = function(q, st)
                        local npc = Q.SpawnActor(q, "citizen", sp, 900)
                        if not npc then return false end
                        npc:SetHealth(math.max(1, math.floor(npc:GetMaxHealth() * 0.25)))
                        q.data.actor = npc
                        st.npc = npc
                    end,
                },
                Choice("Stunstick bruises, in neat rows. He grabs your wrist. 'Please. Don't write it down. Say I fell.'", {
                    { text = "Log it truthfully.", pick = function(q, p) Trait(p, "loyalty", 1) end },
                    { text = "Write 'fell down the stairs'.", pick = function(q, p)
                        Trait(p, "sympathy", 1)
                        LC.Bump(p, "silences")
                        Narrate(q, "He closes his eyes. 'Thank you.'")
                    end },
                }),
                PatchOne("Treat him (medkit, primary fire)"),
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
            desc = "Today's quota is posted. Nobody asks what the parts are for.",
            stages = {
                Goto(a, "Report to the line", 180),
                Hold(a, 25, "Work the line", 160),
                { kind = "pickup", pos = a, model = "models/props_junk/cardboard_box004a.mdl", text = "Take the finished part (press E)" },
                Deliver(b, "Carry it to the next station", 150),
                Hold(b, 15, "Fit the part", 160),
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
                text = string.format("Collect crate %d of 2 from the loading dock (press E)", i) }
            stages[#stages + 1] = Deliver(station, string.format("Bring crate %d to the factory floor", i), 160)
        end
        return { title = "Loading dock", reward = 25, limit = 600, desc = "Two crates, loading dock to the floor.", stages = stages }
    end,
    function(ply, job)
        local station = WorkSpot(ply, job.num)
        if not station then return nil end
        return {
            title = "Short count", reward = 20, limit = 420,
            desc = "Another shift on the line.",
            stages = {
                Goto(station, "Report to the line", 180),
                Hold(station, 20, "Work the line", 160),
                Choice("The parts count is short again. You watch the foreman slide a box under his coat, and he sees you watching.", {
                    { text = "Report him.", pick = function(q, p)
                        Trait(p, "loyalty", 1)
                        LC.Bump(p, "reports")
                        Insert(q, { Count("used_npc", 1, "Report the foreman to a unit (press E)", Q.IsCopNPC) })
                    end },
                    { text = "Say nothing.", pick = function(q, p) LC.Bump(p, "silences") end },
                    { text = "Ask for your cut.", pick = function(q, p)
                        Trait(p, "corruption", 1)
                        LC.Bump(p, "bribes")
                        q.bonus = 10
                        Narrate(q, "He grins like you've always been friends.")
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
            stages[1] = Q.Contact("Collect today's letters from the postal clerk (press E)", office, "citizen",
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
                st.text = string.format("Deliver letter %d of %d to %s (push it under their door)", n, #carried, carried[n].toName or "someone")
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
            desc = #carried .. " letter" .. (#carried == 1 and "" or "s") .. " from people in the city, to people in the city.",
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
        local stages = { Q.Contact("Collect the mail from the postal clerk (press E)", office, "citizen",
            "'Three for the district. Two are overdue. Don't tell them I said so.'") }
        for i = 1, 3 do
            local g = math.random() < 0.5 and "male" or "female"
            local name = LC.NewCharacterName(g)
            stages[#stages + 1] = Q.Contact(string.format("Hand letter %d of 3 to %s, %s (press E)", i, name, doors[i][2]), doors[i][1], "citizen",
                Pick({ "They take it without looking at who sent it.", "'Finally,' they say, and shut the door on the rest of the sentence.",
                    "A nod. Nobody says anything useful in this city out loud.", "They read the envelope twice before they put it away." }),
                { gender = g }) -- whoever answers the door looks like the name on the envelope
        end
        return { title = "Mail round", reward = 25, limit = 600, desc = "Three letters, three people. Collect them at the post office.", stages = stages }
    end,
    function(ply, job)
        local office = WorkSpot(ply, job.num)
        local dest = Q.Spot(ply, 600, 3000)
        local family = Q.Spot(ply, 400, 2500)
        if not office or not dest then return nil end
        return {
            title = "Sealed envelope", reward = 20, limit = 480,
            desc = "One envelope, Civil Protection seal, to be delivered " .. Place(dest, ply:GetPos()) .. ".",
            stages = {
                Q.Contact("Collect the envelope from the clerk (press E)", office, "citizen", "'Hand it over in person. Nobody signs for these.'"),
                Choice("The seal is a Combine stamp. It's not glued very well.", {
                    { text = "Deliver it unopened." },
                    { text = "Steam it open.", check = { "guile", 12 },
                      success = function(q)
                          Insert(q, { Choice("An eviction order. The family in 3B, the one with the twins. Effective tomorrow.", {
                              { text = "Deliver it as addressed.", pick = function(q2, p) Trait(p, "loyalty", 1) end },
                              { text = "Warn the family first.", pick = function(q2, p)
                                  Trait(p, "sympathy", 1)
                                  LC.Bump(p, "silences")
                                  if family then Insert(q2, { Goto(family, "Warn the family, quietly", 150) }) end
                              end },
                          }) })
                      end,
                      fail = function(q) Narrate(q, "The seal tears. You'll have to hope nobody checks.") end },
                }),
                Q.Contact("Hand the envelope to the addressee (press E)", dest, "citizen", "They take it with both hands, like it might go off."),
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
                local h = Hold(lamp:GetPos(), 8, string.format("Fix streetlight %d of %d, %s", i, math.min(3, #lamps), Place(lamp:GetPos(), ply:GetPos())), 130)
                h.onDone = function()
                    Sound("ambient/energy/spark" .. math.random(1, 6) .. ".wav", lamp:GetPos())
                    if LC.RepairStreetFixture then LC.RepairStreetFixture(lamp) end
                end
                stages[i] = h
            end
            return { title = "Lights out", reward = 20, limit = 540, desc = "Streetlights down across the district.", stages = stages }
        end
        local stages = {}
        for i = 1, 3 do
            local sp = Q.Spot(ply, 300, 2500)
            if not sp then return nil end
            local h = Hold(sp, 6, string.format("Repair fuse box %d of 3, %s", i, Place(sp, ply:GetPos())), 100)
            h.onEnter = function(q) Q.SpawnItem(q, "models/props_lab/powerbox02a.mdl", sp) end
            h.onDone = function() Sound("ambient/energy/spark" .. math.random(1, 6) .. ".wav", sp) end
            stages[i] = h
        end
        return { title = "Lights out", reward = 20, limit = 540, desc = "Three fuse boxes down across the district.", stages = stages }
    end,
    function(ply)
        local cps = LC.PointsOfKind("checkpoint")
        local pos = #cps > 0 and Pick(cps).pos or Q.Spot(ply, 400, 2000)
        if not pos then return nil end
        return {
            title = "Terminal fault", reward = 20, limit = 420,
            desc = "A checkpoint scanner terminal is throwing faults.",
            stages = {
                Goto(pos, "Go to the faulty terminal", 220),
                Hold(pos, 20, "Repair the terminal", 200),
                Choice("The terminal's log scrolls past while it reboots. One of last night's entries is your neighbor, at 3 a.m.", {
                    { text = "Leave the log intact.", pick = function(q, p) Trait(p, "loyalty", 1) end },
                    { text = "Corrupt that entry while you're in there.", check = { "guile", 12 },
                      success = function(q, p)
                          Trait(p, "sympathy", 1)
                          LC.Bump(p, "silences")
                          Narrate(q, "One line of the log becomes noise. Terminals glitch all the time.")
                      end,
                      fail = function(q, p)
                          Narrate(q, "The terminal flags the edit. Every unit in the sector gets the alert.")
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
-- Station Porter
------------------------------------------------------------------------

SHIFTS.porter = {
    function(ply, job)
        local platform = WorkSpot(ply, job.num, 300, 2000)
        local home, homeName, homeR = Residence(ply)
        if not platform or not home then return nil end
        return {
            title = "New arrivals", reward = 20, limit = 540,
            desc = "A train came in. One of the new arrivals needs walking to their assigned housing.",
            stages = {
                {
                    kind = "target", action = "reach", r = 140, text = "Meet the new arrival on the platform (marked)",
                    onEnter = function(q, st)
                        local npc = Q.SpawnActor(q, "citizen", platform, 900)
                        if not npc then return false end
                        q.data.actor = npc
                        st.npc = npc
                        q.data.dest, q.data.destName, q.data.destR = home, homeName, homeR
                    end,
                },
                Choice("He's holding a transfer slip like it might bite him. Under his breath: 'Is there anywhere in this city they don't look?'", {
                    { text = "'Your block. Keep your head down.'", pick = function(q, p) Trait(p, "loyalty", 1) end },
                    { text = "Tell him about the canals, and walk him there instead.",
                      when = function() return #LC.ZonesOfKind("rebel") > 0 end,
                      pick = function(q, p)
                          Trait(p, "sympathy", 1)
                          LC.Bump(p, "silences")
                          local pos, r, name = Q.SafeHouse(p)
                          q.data.dest, q.data.destR, q.data.destName = pos, r, name
                          Narrate(q, "He doesn't say thank you. He doesn't have to.")
                      end },
                    { text = "Repeat the question to a unit.", pick = function(q, p)
                        Trait(p, "loyalty", 2)
                        LC.Bump(p, "reports")
                        if IsValid(q.data.actor) and LC.ArrestNPC then LC.ArrestNPC(q.data.actor, nil) end
                        Narrate(q, "A unit takes him by the arm. He looks back at you once.")
                        SkipNext(q)
                    end },
                }),
                {
                    kind = "escort", vanish = true, text = "Walk him to his new home",
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
            desc = "A suitcase was left on the platform. It goes to its owner, " .. destName .. ".",
            stages = {
                { kind = "pickup", pos = platform, model = "models/props_c17/suitcase_passenger_physics.mdl",
                  text = "Collect the suitcase from the platform (press E)" },
                Choice("The suitcase is heavier than clothes. Something inside slides and settles, like a stack of paper.", {
                    { text = "Carry it. It's not your business." },
                    { text = "Take a look inside.", check = { "guile", 11 },
                      success = function(q, p)
                          Narrate(q, "Under the shirts: a stack of blank identity forms. You take one. Nobody counts them twice.")
                          Give(p, "papers_blank")
                          LC.Bump(p, "thefts")
                      end,
                      fail = function(q, p)
                          Narrate(q, "The latches snap open loud enough to turn heads. A unit is already walking over.")
                          LC.ReportCrime(p, "Theft from a traveler", 90)
                      end },
                    { text = "Hand it to Civil Protection.", pick = function(q, p)
                        Trait(p, "loyalty", 2)
                        LC.Bump(p, "reports")
                        SkipNext(q)
                        Insert(q, { Count("used_npc", 1, "Hand the suitcase to a unit (press E)", Q.IsCopNPC) })
                    end },
                }),
                Q.Contact("Return the suitcase to its owner, " .. destName .. " (press E)", dest, "citizen", "'That's mine. I thought I'd lost it.' They don't say thank you."),
            },
        }
    end,
    function(ply, job)
        local platform = WorkSpot(ply, job.num, 300, 2000)
        if not platform then return nil end
        return {
            title = "Ticket check", reward = 20, limit = 540,
            desc = "Tickets and transit permits, everyone boarding.",
            stages = {
                Goto(platform, "Go to the platform", 220),
                Count("used_npc", 3, "Check three travelers' tickets (press E on citizens)", Q.IsCitizenNPC),
                Choice("An old woman has a ticket but no transit permit. She's going to see her son, she says. He's in Nova Prospekt.", {
                    { text = "Let her board.", check = { "guile", 10 },
                      success = function(q, p)
                          Trait(p, "sympathy", 1)
                          LC.Bump(p, "silences")
                          Narrate(q, "She squeezes your hand on the way past. It's the last train she'll ever take, and you both know it.")
                      end,
                      fail = function(q, p)
                          Narrate(q, "The platform scanner flags her before she reaches the door. And you, for letting her through.")
                          LC.ReportCrime(p, "Aiding unauthorized travel", 90)
                      end },
                    { text = "Turn her back.", pick = function(q, p) Trait(p, "loyalty", 1) end },
                    { text = "Call a unit.", pick = function(q, p)
                        Trait(p, "loyalty", 2)
                        LC.Bump(p, "reports")
                        Insert(q, { Count("used_npc", 1, "Report her to a unit (press E)", Q.IsCopNPC) })
                    end },
                }),
            },
        }
    end,
}

------------------------------------------------------------------------
-- Records Clerk
------------------------------------------------------------------------

SHIFTS.clerk = {
    function(ply, job)
        local office = WorkSpot(ply, job.num)
        if not office then return nil end
        return {
            title = "Filing", reward = 15, limit = 360,
            desc = "The day's files: relocations, ration audits, three deaths by natural causes.",
            stages = { Goto(office, "Go to the records office", 180), Hold(office, 30, "Process the day's files", 160) },
        }
    end,
    function(ply, job)
        local office = WorkSpot(ply, job.num)
        if not office then return nil end
        return {
            title = "Permit desk", reward = 20, limit = 420,
            desc = "You're on the permit desk today.",
            stages = {
                Goto(office, "Go to the permit desk", 180),
                Choice("A woman's relocation papers are missing one stamp. Without it, her family gets split across two districts. She's watching your hands.", {
                    { text = "Stamp it anyway.", check = { "guile", 12 },
                      success = function(q, p)
                          Trait(p, "sympathy", 1)
                          LC.Bump(p, "silences")
                          Narrate(q, "One stamp. It's the easiest thing you've ever done.")
                      end,
                      fail = function(q, p)
                          Narrate(q, "Your supervisor checks the stamp log at the end of the day.")
                          LC.ReportCrime(p, "Falsifying records", 120)
                      end },
                    { text = "Reject the application.", pick = function(q, p) Trait(p, "loyalty", 1) end },
                    { text = "Reject it, and flag her file.", pick = function(q, p)
                        Trait(p, "loyalty", 2)
                        LC.Bump(p, "reports")
                    end },
                }),
                Hold(office, 15, "Finish the paperwork", 160),
            },
        }
    end,
    function(ply, job)
        local office = WorkSpot(ply, job.num)
        if not office then return nil end
        return {
            title = "Supply cabinet", reward = 15, limit = 420,
            desc = "Restock the forms before the morning queue.",
            stages = {
                Goto(office, "Go to the records office", 180),
                Hold(office, 20, "Restock the forms", 160),
                Choice("The cabinet with the blank identity forms is unlocked, and your supervisor is at lunch.", {
                    { text = "Lock it and move on.", pick = function(q, p) Trait(p, "loyalty", 1) end },
                    { text = "Slip one into your coat.", check = { "guile", 11 },
                      success = function(q, p)
                          Give(p, "papers_blank")
                          LC.Bump(p, "thefts")
                          Narrate(q, "One form. Nobody counts them. Probably.")
                      end,
                      fail = function(q, p)
                          Narrate(q, "Your supervisor comes back early.")
                          LC.ReportCrime(p, "Theft of state documents", 180)
                      end },
                    { text = "Take a stack.", check = { "guile", 16 },
                      success = function(q, p)
                          Give(p, "papers_blank", 3)
                          LC.Bump(p, "thefts")
                          Narrate(q, "Three forms flat against your ribs. Your heart is louder than the printer.")
                      end,
                      fail = function(q, p)
                          Narrate(q, "A stack that size doesn't hide. Your supervisor is already calling it in.")
                          LC.ReportCrime(p, "Theft of state documents", 240)
                      end },
                }),
            },
        }
    end,
}

------------------------------------------------------------------------
-- Uniform Laundry
------------------------------------------------------------------------

SHIFTS.laundry = {
    function(ply, job)
        local room = WorkSpot(ply, job.num)
        if not room then return nil end
        return {
            title = "Wash cycle", reward = 15, limit = 360,
            desc = "Forty uniforms, one cycle.",
            stages = { Goto(room, "Go to the laundry", 180), Hold(room, 35, "Run the machines", 160) },
        }
    end,
    function(ply, job)
        local room = WorkSpot(ply, job.num)
        local dest, destName = Precinct(ply)
        if not room or not dest then return nil end
        return {
            title = "Pressed uniforms", reward = 20, limit = 480,
            desc = "A bundle of pressed uniforms, due at " .. destName .. ".",
            stages = {
                { kind = "pickup", pos = room, model = "models/props_junk/cardboard_box003a.mdl", text = "Collect the bundle (press E)" },
                Choice("The count is wrong. There's one uniform too many, mask and all, folded at the bottom. Nobody would miss it.", {
                    { text = "Deliver the count as it is.", pick = function(q, p) Trait(p, "loyalty", 1) end },
                    { text = "Keep the spare.", check = { "guile", 13 },
                      success = function(q, p)
                          Give(p, "uniform_cp")
                          LC.Bump(p, "thefts")
                          Narrate(q, "It goes under your coat. It's heavier than you'd think, being one of them.")
                      end,
                      fail = function(q, p)
                          Narrate(q, "The quartermaster recounts in front of you.")
                          LC.ReportCrime(p, "Theft of Civil Protection property", 240)
                      end },
                }),
                destName == "the checkpoint"
                    and Q.Contact("Hand the uniforms to the unit at the checkpoint (press E)", dest, "cop")
                    or Deliver(dest, "Deliver the uniforms to " .. destName, 180),
            },
        }
    end,
    function(ply, job)
        local room = WorkSpot(ply, job.num)
        local home, homeName = Residence(ply)
        if not room then return nil end
        return {
            title = "Stains", reward = 15, limit = 420,
            desc = "The bloodstained ones need doing by hand.",
            stages = {
                Goto(room, "Go to the laundry", 180),
                Hold(room, 20, "Scrub the stains", 160),
                Choice("This sleeve is stiff with blood, still fresh. The tag pinned to it isn't a unit number. It's a citizen's.", {
                    { text = "Wash it.", pick = function(q, p) Trait(p, "loyalty", 1) end },
                    { text = "Keep the tag. Someone's family should know.", pick = function(q, p)
                        Trait(p, "sympathy", 1)
                        LC.Bump(p, "silences")
                        if home then Insert(q, { Goto(home, "Leave the tag where his family will find it, " .. homeName, 160) }) end
                    end },
                    { text = "Report the irregularity.", pick = function(q, p)
                        Trait(p, "loyalty", 1)
                        Narrate(q, "Your supervisor tells you to wash it and forget it. You wash it.")
                    end },
                }),
            },
        }
    end,
}

------------------------------------------------------------------------
-- Mortuary Attendant
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
        local go = Goto(spot, "Collect the body " .. Place(spot, ply:GetPos()), 150)
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
            desc = "A body was reported " .. Place(spot, ply:GetPos()) .. ". Nobody has claimed it.",
            onFinish = Unclaim,
            stages = {
                go,
                Choice("His coat pocket holds identity papers, still valid. Nobody has reported him dead yet.", {
                    { text = "Turn everything in.", pick = function(q, p) Trait(p, "loyalty", 1) end },
                    { text = "Keep his papers.", pick = function(q, p)
                        Give(p, "papers_dead")
                        LC.Bump(p, "thefts")
                        Narrate(q, "They're good papers. They'll be good for somebody.")
                    end },
                    { text = "Find his family first.", pick = function(q, p)
                        Trait(p, "sympathy", 1)
                        if home then Insert(q, { Goto(home, "Tell his family, " .. homeName, 160) }) end
                    end },
                }),
                HaulStage("Haul him (E on the body to drag, E to let go)"),
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
        local st = Count("cremated", n, string.format("Haul %d bodies off the streets to %s", n, proc.name), nil, false)
        st.pos, st.r = proc.pos, 200
        return {
            title = "Clear the streets", reward = 15 + 10 * n, limit = 900,
            desc = "There's been trouble. The city wants the streets clean before morning.",
            stages = { st },
        }
    end,
    function(ply, job)
        local incs = LC.EntsOf("lc_incinerator")
        local inc = #incs > 0 and Pick(incs) or nil
        local morgue = IsValid(inc) and inc:GetPos() or WorkSpot(ply, job.num)
        if not morgue then return nil end
        local work = Hold(morgue, 30, "Work the incinerator", 160)
        work.onDone = function() if IsValid(inc) then inc:SetNW2Float("lc_burn_until", CurTime() + 8) end end
        return {
            title = "Incinerator", reward = 15, limit = 420,
            desc = "The incinerator runs all night. Somebody has to feed it.",
            stages = {
                Goto(morgue, IsValid(inc) and "Go to the incinerator" or "Go to the morgue", 180),
                work,
                Choice("The next one still has a wedding ring on.", {
                    { text = "Leave it on her." },
                    { text = "Pocket the ring.", pick = function(q, p)
                        Trait(p, "corruption", 1)
                        Give(p, "keepsake")
                    end },
                    { text = "Set it aside for the family.", pick = function(q, p) Trait(p, "sympathy", 1) end },
                }),
            },
        }
    end,
}

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
            desc = "Metal " .. Place(center, ply:GetPos()) .. ". The Union needs all of it.",
            stages = {
                { kind = "collect", spots = Q.HideSpots(center, 5, 700, true), models = METAL, need = 5,
                  text = "Collect the scrap (press E)" },
                Choice("One good piece of copper wasn't on anybody's list.", {
                    { text = "Log it.", pick = function(q, p) Trait(p, "loyalty", 1) end },
                    { text = "Keep it for the dealer.", pick = function(q, p)
                        Give(p, "scrap", 2)
                        LC.Bump(p, "thefts")
                    end },
                }),
                Deliver(yard, "Bring it to the reclamation yard", 180),
            },
        }
    end,
    function(ply)
        local stages, used = {}, {}
        for i = 1, 3 do
            local sp = Marked("rubble", ply, used) or Q.Spot(ply, 300, 2500)
            if not sp then return nil end
            local h = Hold(sp, 8, string.format("Clear rubble %d of 3, %s", i, Place(sp, ply:GetPos())), 110)
            h.onEnter = function(q) Q.SpawnItem(q, Pick(RUBBLE), sp) end
            stages[#stages + 1] = h
        end
        table.insert(stages, 3, Choice("Under the bricks: a canvas bag. Inside, a pistol and a magazine wrapped in oilcloth. Someone hid it here on purpose.", {
            { text = "Report the cache.", pick = function(q, p)
                Trait(p, "loyalty", 2)
                LC.Bump(p, "reports")
                Insert(q, { Count("used_npc", 1, "Report the cache to a unit (press E)", Q.IsCopNPC) })
            end },
            { text = "Leave it where it is.", pick = function(q, p)
                LC.Bump(p, "silences")
                Narrate(q, "You put the bricks back exactly how they were.")
            end },
            { text = "Take it.", pick = function(q, p)
                p:Give("weapon_pistol")
                p:GiveAmmo(18, "Pistol")
                if LC.SeenBySecurity and LC.SeenBySecurity(p, 900) then
                    Narrate(q, "A unit saw the oilcloth come out of the rubble.")
                    LC.ReportCrime(p, "Possession of a firearm", 240)
                else
                    Narrate(q, "It's cold and heavy and nobody saw.")
                end
            end },
        }))
        return { title = "Rubble clearing", reward = 20, limit = 600, desc = "Three rubble piles from the old city.", stages = stages }
    end,
}

------------------------------------------------------------------------
-- Radio Repair
------------------------------------------------------------------------

SHIFTS.radio = {
    function(ply)
        -- the city's own loudspeakers, the broken ones first (sv_livingcity_propaganda.lua)
        local speakers = LC.StreetFixtures and LC.StreetFixtures("lc_loudspeaker", ply:GetPos(), 3500) or {}
        if #speakers > 0 then
            local stages = {}
            for i = 1, math.min(3, #speakers) do
                local sp = speakers[i]
                local h = Hold(sp:GetPos(), 8, string.format("Fix loudspeaker %d of %d, %s", i, math.min(3, #speakers), Place(sp:GetPos(), ply:GetPos())), 220)
                h.onDone = function()
                    if LC.RepairStreetFixture then LC.RepairStreetFixture(sp) end
                    Sound("npc/overwatch/cityvoice/f_innactionisconspiracy_spkr.wav", sp:GetPos())
                end
                stages[i] = h
            end
            return { title = "Loudspeakers", reward = 20, limit = 540, desc = "The city's loudspeakers need seeing to. The city must be heard.", stages = stages }
        end
        local stages = {}
        for i = 1, 3 do
            local sp = Q.Spot(ply, 300, 2500)
            if not sp then return nil end
            local h = Hold(sp, 8, string.format("Fix loudspeaker %d of 3, %s", i, Place(sp, ply:GetPos())), 120)
            h.onEnter = function(q) Q.SpawnItem(q, "models/props_wasteland/speakercluster01a.mdl", sp) end
            h.onDone = function() Sound("npc/overwatch/cityvoice/f_innactionisconspiracy_spkr.wav", sp) end
            stages[i] = h
        end
        return { title = "Loudspeakers", reward = 20, limit = 540, desc = "Three loudspeakers down. The city must be heard.", stages = stages }
    end,
    function(ply, job)
        local shop = WorkSpot(ply, job.num)
        if not shop then return nil end
        return {
            title = "Repair bench", reward = 15, limit = 420,
            desc = "Radios in for repair.",
            stages = {
                Goto(shop, "Go to the repair shop", 180),
                Hold(shop, 20, "Repair the radios on the bench", 160),
                Choice("One radio came in already retuned, to a frequency the Union doesn't broadcast on. The owner's block number is on the tag.", {
                    { text = "Reset it and log the owner.", pick = function(q, p)
                        Trait(p, "loyalty", 2)
                        LC.Bump(p, "reports")
                    end },
                    { text = "Reset it. Say nothing.", pick = function(q, p) LC.Bump(p, "silences") end },
                    { text = "Keep it.", pick = function(q, p)
                        Give(p, "radio_tuned")
                        LC.Bump(p, "thefts")
                        Narrate(q, "Freq 7 hisses softly in your coat.")
                    end },
                }),
            },
        }
    end,
    function(ply, job)
        local shop = WorkSpot(ply, job.num)
        if not shop then return nil end
        return {
            title = "Union radio order", reward = 20, limit = 420,
            desc = "A batch of Union radios to assemble.",
            stages = {
                Goto(shop, "Go to the repair shop", 180),
                Hold(shop, 25, "Assemble the radios", 160),
                Choice("One is left over at the end of the count.", {
                    { text = "Return it to stores.", pick = function(q, p) Trait(p, "loyalty", 1) end },
                    { text = "Take it home.", check = { "guile", 11 },
                      success = function(q, p) Give(p, "radio") end,
                      fail = function(q, p)
                          Narrate(q, "Stores counts them again while you're still there.")
                          LC.ReportCrime(p, "Theft of Union property", 90)
                      end },
                    { text = "Retune it to Freq 7 first.", check = { "guile", 14 },
                      success = function(q, p)
                          Give(p, "radio_tuned")
                          LC.Bump(p, "thefts")
                      end,
                      fail = function(q, p)
                          Narrate(q, "The bench tester squeals on the unlisted frequency. Everyone turns around.")
                          LC.ReportCrime(p, "Possession of an unregistered radio", 150)
                      end },
                }),
            },
        }
    end,
}

------------------------------------------------------------------------
-- The shift chain: one personal posting at a time, forever
------------------------------------------------------------------------

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
