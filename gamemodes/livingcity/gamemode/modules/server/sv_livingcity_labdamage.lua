--[[
    Living City: a Resistance lab can be shot up (the owner's 7 November playtest)

    The lab's bench (lc_workbench, sv_livingcity_lab.lua) takes lc_lab_health (250) damage from
    anyone who isn't the Resistance's own: a unit's gun, a grenade. Every quarter of that blows a
    part of it (a bang, sparks, a piece of kit gone) and it smokes; at the end it's wrecked:
    sparking and smoking, and nothing is made, decoded or done there (the scientist is still
    there, but has nothing to work with) until the Resistance fixes it.

    Fixing it is a job on the Resistance's board (F4), "Get the lab running": get the parts (dug out
    at the reclamation yard, pocketed at the radio repair shop, pulled from a loudspeaker's utility
    box; a spare part hidden nearby for any the map lacks), bring them to the lab, and rewire the bench
    with the scientist (the wiring game). Searching is by hand, holding E (sv_livingcity_questsearch.lua). Only a player
    can do it. Done, and the smoke and sparks stop.

    A bench that's only been knocked about (not wrecked) still works; the scientist patches it
    up himself after lc_lab_shutdown seconds without being hit again.

    The unit who wrecks it is paid (15 XP, 20 credits); a citizen who wrecks it isn't.

    This is beside the scientist being taken away by a unit (LC.ShutLab): that shuts the lab
    until he's back, and needs no repair. A wrecked lab stays wrecked whether he's there or not.
    The smoke is drawn on each player's screen (cl_livingcity_labdamage.lua).
]]

if CLIENT then return end

LC = LC or {}

local FLAGS = bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED)
local cvHP = CreateConVar("lc_lab_health", "250", FLAGS, "Damage a Resistance lab's bench takes before it's wrecked and has to be repaired (0: it can't be damaged)")

local PARTS = 3 -- parts that blow before it's wrecked (each a quarter of its health)

local function Where(pos) return LC.DescribePlace and LC.DescribePlace(pos) or "" end
local function Bench(e)
    if not IsValid(e) then return nil end
    if e:GetClass() == "lc_scientist" then return e.lcLab end
    return e
end

-- Wrecked (a bench, or its scientist)?
function LC.LabBroken(e)
    local b = Bench(e)
    return IsValid(b) and b:GetNW2Bool("lc_lab_broken", false) or false
end

function LC.BrokenLabs()
    local out = {}
    for _, b in ipairs(LC.EntsOf and LC.EntsOf("lc_workbench") or ents.FindByClass("lc_workbench")) do
        if IsValid(b) and b:GetNW2Bool("lc_lab_broken", false) then out[#out + 1] = b end
    end
    return out
end

-- Who can break it: anyone but the Resistance (and their fighters).
local function Breaker(a)
    if not IsValid(a) then return false end
    if a:IsPlayer() then return a:GetNW2String("lcf_faction", "") ~= "resistance" end
    local st = LC.NPCs and LC.NPCs[a]
    return st ~= nil and LC.IsSecurity ~= nil and LC.IsSecurity(st)
end

-- A part goes: a bang where it was, sparks, and a piece of kit off the bench.
local function BlowPart(bench, i)
    local mins, maxs = bench:OBBMins(), bench:OBBMaxs()
    local f = ({ 0.25, 0.75, 0.5 })[i] or math.Rand(0.2, 0.8)
    local pos = bench:LocalToWorld(Vector((mins.x + maxs.x) / 2, mins.y + (maxs.y - mins.y) * f, maxs.z))
    if EffectData then
        local fx = EffectData()
        fx:SetOrigin(pos)
        fx:SetMagnitude(1)
        fx:SetScale(1)
        util.Effect("Explosion", fx, true, true) -- (the look and the sound: nobody's hurt)
        local sp = EffectData()
        sp:SetOrigin(pos)
        sp:SetMagnitude(4)
        util.Effect("Sparks", sp, true, true)
    end
    local kit = bench.lcClutter and bench.lcClutter[i]
    if IsValid(kit) then kit:Remove() end
end

-- Who is paid for wrecking one: a unit (Civil Protection, the Overwatch, the Administrator).
-- A citizen who wrecks it gets nothing extra (the owner, 7 November).
function LC.LabWreckPays(ply)
    if not (IsValid(ply) and ply:IsPlayer()) then return false end
    local f = ply:GetNW2String("lcf_faction", "")
    return f == "cp" or f == "ota" or f == "admin" or (LC.PlayerIsCP and LC.PlayerIsCP(ply)) == true
end

-- Wrecked: nothing works there until it's fixed.
function LC.WreckLab(bench, by)
    if not IsValid(bench) or bench:GetNW2Bool("lc_lab_broken", false) then return false end
    bench:SetNW2Bool("lc_lab_broken", true)
    bench:SetNW2Int("lc_lab_dmg", PARTS)
    bench.lcLabHP = 0
    local sci = bench.lcScientist
    if IsValid(sci) then
        if LC.ScientistSay then LC.ScientistSay(sci, "ohdear", 80) end
        local job = sci.lcLabJob
        sci.lcLabJob = nil
        if job and IsValid(job.ply) and LC.CancelTask then LC.CancelTask(job.ply) end
    end
    if IsValid(by) and by:IsPlayer() and LC.LabWreckPays(by) then
        by:ChatPrint("[Civil Protection] The Resistance lab is wrecked. Nothing will be made there until they fix it.")
        if LC.AddXP then LC.AddXP(by, 15, "Wrecked a Resistance lab") end
        if LC.AddCredits then LC.AddCredits(by, 20, "a Resistance lab wrecked") end
    end
    if LC.RadioNotice then
        LC.RadioNotice("resistance", "The Combine wrecked our lab " .. Where(bench:GetPos()) .. ". Nothing comes out of it until it's fixed: the job's on your board (F4).")
    end
    if LC.PostDirective then LC.PostDirective("res_fixlab", bench) end
    LC.Log("info", "Lab wrecked at " .. tostring(bench:GetPos()))
    hook.Run("LivingCityLabWrecked", bench, by)
    return true
end

-- Fixed: whole again, and the smoke stops.
function LC.RepairLab(bench, by)
    if not IsValid(bench) then return false end
    local was = bench:GetNW2Bool("lc_lab_broken", false)
    bench:SetNW2Bool("lc_lab_broken", false)
    bench:SetNW2Int("lc_lab_dmg", 0)
    bench.lcLabHP, bench.lcLabHitAt = nil, nil
    -- the kit back on the bench (Dr. Kleiner's workstations have their own)
    if bench.lcClutter then
        for _, c in ipairs(bench.lcClutter) do if IsValid(c) then c:Remove() end end
        bench.lcClutter = nil
    end
    if LC.SetupLab then LC.SetupLab(bench) end
    local sci = bench.lcScientist
    if IsValid(sci) and LC.ScientistSay then LC.ScientistSay(sci, "excellent", 75) end
    if LC.LabClean then
        if IsValid(sci) then LC.LabClean(sci) elseif bench.RemoveAllDecals then bench:RemoveAllDecals() end
    end
    if was then
        if IsValid(by) and by:IsPlayer() then by:ChatPrint("[Scientist] \"Splendid! Everything's back on. The lab's open again.\"") end
        if LC.RadioNotice then LC.RadioNotice("resistance", "The lab " .. Where(bench:GetPos()) .. " is running again.") end
        hook.Run("LivingCityLabRepaired", bench, by)
    end
    return true
end

function LC.LabDamage(bench, amount, by)
    local max = cvHP:GetFloat()
    if not IsValid(bench) or max <= 0 or bench:GetNW2Bool("lc_lab_broken", false) or (amount or 0) <= 0 then return end
    local hp = (bench.lcLabHP or max) - amount
    bench.lcLabHP = hp
    bench.lcLabHitAt = CurTime()
    local parts = math.Clamp(math.floor((1 - hp / max) * (PARTS + 1)), 0, PARTS)
    local was = bench:GetNW2Int("lc_lab_dmg", 0)
    while was < parts do
        was = was + 1
        BlowPart(bench, was)
    end
    bench:SetNW2Int("lc_lab_dmg", was)
    if hp <= 0 then LC.WreckLab(bench, by) end
end

hook.Add("EntityTakeDamage", "LivingCityLabDamage", function(ent, dmg)
    if not IsValid(ent) or ent:GetClass() ~= "lc_workbench" then return end
    local a = dmg:GetAttacker()
    if not Breaker(a) then return end
    LC.LabDamage(ent, dmg:GetDamage(), a)
end)

-- Knocked about but not wrecked: the scientist patches it up himself, given time.
timer.Create("LivingCityLabPatch", 10, 0, function()
    local now, wait = CurTime(), (GetConVar("lc_lab_shutdown") and GetConVar("lc_lab_shutdown"):GetFloat() or 600)
    for _, b in ipairs(LC.EntsOf and LC.EntsOf("lc_workbench") or ents.FindByClass("lc_workbench")) do
        if IsValid(b) and not b:GetNW2Bool("lc_lab_broken", false) and b:GetNW2Int("lc_lab_dmg", 0) > 0
            and now - (b.lcLabHitAt or 0) > wait then
            LC.RepairLab(b, nil)
        end
    end
end)

------------------------------------------------------------------------
-- The job: get the lab running (the Resistance's board)
------------------------------------------------------------------------

local PART_MODELS = { "models/props_lab/reciever01b.mdl", "models/props_lab/harddrive01.mdl", "models/props_c17/consolebox01a.mdl",
    "models/props_lab/powerbox02d.mdl" }

local function FixLabTemplate()
    local Q = LC.QB
    return {
        id = "res_fixlab", factions = { resistance = true }, squad = 4,
        available = function() return #LC.BrokenLabs() > 0 end,
        build = function(ply, focus)
            local labs = LC.BrokenLabs()
            if #labs == 0 then return nil end
            local bench = labs[1]
            for _, b in ipairs(labs) do
                if b == focus then bench = b break end
                if b:GetPos():DistToSqr(ply:GetPos()) < bench:GetPos():DistToSqr(ply:GetPos()) then bench = b end
            end
            local pos = bench:GetPos()
            local where = Q.Place(pos, ply:GetPos())
            local stages = {}
            -- The parts are found, not lying on walkways (the owner, 13 November playtest: "Dig one out at
            -- the reclamation point, steal a radio or a part from the radio repair shop, and a third"): one
            -- dug out of the reclamation yard's scrap, one pocketed at the radio repair shop (seen by a unit,
            -- it's theft), and one pulled out of a loudspeaker's utility box (seen, it's sabotage). Each
            -- the map lacks is a spare part hidden somewhere nearby instead, as before.
            local from = ply:GetPos()
            local function NearestOf(list) local b, bd for _, x in ipairs(list) do local d = x:DistToSqr(from) if not bd or d < bd then b, bd = x, d end end return b end
            local function PointsOf(jobId)
                local job = LCJ and LCJ.ById and LCJ.ById[jobId]
                local out = {}
                for _, pt in ipairs(job and LC.PointsOfKind and LC.PointsOfKind("work", job.num) or {}) do out[#out + 1] = pt.pos end
                return out
            end
            local yardList = PointsOf("scrap")
            for _, e in ipairs(LC.EntsOf and LC.EntsOf("lc_recycler") or {}) do yardList[#yardList + 1] = e:GetPos() end
            local yard, shop = NearestOf(yardList), NearestOf(PointsOf("radio"))
            local boxes = {}
            for _, e in ipairs(LC.EntsOf and LC.EntsOf("lc_utilitybox") or {}) do boxes[#boxes + 1] = e:GetPos() end
            local box = NearestOf(boxes)
            local missing = 0
            local function Seen(q, crime)
                local p = q.owner
                if IsValid(p) and LC.SeenBySecurity and LC.SeenBySecurity(p, 1200) and LC.ReportCrime then
                    LC.ReportCrime(p, crime)
                    Q.Narrate(q, "A unit saw that.")
                end
            end
            -- (no "stand here" steps: the owner, 14 November. A search by hand, or the rewiring game.)
            local JUNK = { "models/props_junk/metal_paintcan001a.mdl", "models/props_junk/cardboard_box001a.mdl", "models/props_c17/oildrum001.mdl",
                "models/props_junk/garbage_metalcan002a.mdl", "models/props_debris/metal_panel01a.mdl" }
            local SHELF = { "models/props_lab/reciever01a.mdl", "models/props_lab/reciever01b.mdl", "models/props_junk/cardboard_box002a.mdl",
                "models/props_lab/harddrive02.mdl", "models/props_c17/consolebox03a.mdl" }
            if yard then
                stages[#stages + 1] = LC.QuestSearchStage({ pos = yard, r = 160, min = 5, junk = JUNK, hide = true,
                    text = "Dig through the scrap at the reclamation yard " .. Q.Place(yard, from) .. " (marked): hold E on the heaps until you find a part that works",
                    empty = { "Rust and bent tin.", "Nothing useful in this lot.", "A dead motor, seized solid." },
                    found = function(q, st, ent, p) p:ChatPrint("[Search] Under the junk: a coil that still works. That'll do.") end })
            else missing = missing + 1 end
            if shop then
                stages[#stages + 1] = LC.QuestSearchStage({ pos = shop, r = 140, min = 4, junk = SHELF, hide = true,
                    text = "Find a working radio at the radio repair shop " .. Q.Place(shop, from) .. " (marked): hold E on the sets and boxes, and don't let a unit see you take it",
                    empty = { "Gutted for parts already.", "This one's dead.", "Empty casing." },
                    found = function(q, st, ent, p) p:ChatPrint("[Search] This one hums when you shake it. Into your coat.") Seen(q, "Theft") end })
            else missing = missing + 1 end
            if box then
                local st = Q.GameGo(box, "Get to a loudspeaker's utility box " .. Q.Place(box, from) .. " (marked)", "wiring", { what = "the utility box", pos = box }, 100)
                stages[#stages + 1] = st
                local free = Q.GameStage("Rewire the box so the circuit board comes free (without a unit seeing you)")
                free.onDone = function(q) Seen(q, "Sabotage of city property") end
                stages[#stages + 1] = free
            else missing = missing + 1 end
            if missing > 0 then
                local cache = Q.Spot(ply, 500, 2200)
                local spots = cache and Q.HideSpots(cache, missing, 600) or {}
                if #spots > 0 then
                    table.insert(stages, 1, { kind = "collect", spots = spots, need = #spots, models = PART_MODELS,
                        text = #spots == 1 and "Find a spare part for the lab (marked) and press E on it" or "Find spare parts for the lab (marked) and press E on each" })
                end
            end
            stages[#stages + 1] = Q.Deliver(pos, "Bring the parts to the scientist at the lab " .. where, 220)
            stages[#stages + 1] = Q.GameGo(pos, "Back to the bench " .. where .. " (marked) to put it together with the scientist", "wiring", { what = "the bench", pos = pos }, 220)
            local fix = Q.GameStage("Rewire the bench while the scientist holds the panel")
            fix.onDone = function(q)
                if IsValid(bench) then
                    LC.RepairLab(bench, q.owner)
                    Q.Narrate(q, "The last panel clicks shut. The smoke clears, and the bench hums again.")
                end
            end
            stages[#stages + 1] = fix
            return {
                title = "Get the lab running " .. where, reward = 45, limit = 900,
                desc = "The Combine wrecked our lab " .. where .. ". Nothing can be made there until it's fixed. Get the parts (the reclamation yard, the radio repair shop, a loudspeaker's box), bring them to the scientist, and put the bench back together with him.",
                stages = stages,
            }
        end,
    }
end

-- (added once the quest machinery is loaded; this file comes after it)
if LC.QuestTemplates and LC.QB then
    for i = #LC.QuestTemplates, 1, -1 do if LC.QuestTemplates[i].id == "res_fixlab" then table.remove(LC.QuestTemplates, i) end end
    LC.QuestTemplates[#LC.QuestTemplates + 1] = FixLabTemplate()
end
