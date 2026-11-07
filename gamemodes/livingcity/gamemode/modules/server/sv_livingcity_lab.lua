--[[
    Living City: the Resistance lab

    A lab ("Fixture: Resistance lab" in the editor; entities/lc_workbench.lua)
    is one of Dr. Kleiner's own lab workstations with a scientist standing
    beside it (entities/lc_scientist.lua): the Resistance's own, Dr. Kleiner,
    Eli Vance or Dr. Magnusson, a different one at each lab. He decodes
    Combine data chips (use one from your pockets beside him), and makes
    what a cell needs and can't buy in the open (LCS.Lab, the shared shop
    config): guns, ammunition, armour, jammers, bypass charges, smoke bombs,
    and a Union radio retuned to Freq 7.

      Bring him the materials and he makes it for nothing. Or pay him:
      lc_lab_price (60%) of what the black market dealer charges, and never
      less than the quartermaster would pay for it (no money in buying from
      him to sell on). He takes a few seconds; stay in the lab, or he hands
      it all back.

    Only for the Resistance. Anyone else gets shown the door, and buys these
    at the black market dealer instead. A unit who finds him shuts the lab
    down: the scientist is taken away for lc_lab_shutdown (600) seconds.

    Every rebel base needs a lab for its guns. Lockpicks and bandages are
    still made by hand, from F3, anywhere.
]]

if CLIENT then return end

LC = LC or {}

util.AddNetworkString("lc_lab")
util.AddNetworkString("lc_lab_make")
util.AddNetworkString("lc_lab_decode")
util.AddNetworkString("lc_lab_surgery")

local FLAGS = bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED)
local cvShut  = CreateConVar("lc_lab_shutdown", "600", FLAGS, "Seconds a Resistance lab stays shut after a Civil Protection unit finds it")
local cvPrice = CreateConVar("lc_lab_price", "0.6", FLAGS, "What the Resistance's scientist charges, times the black market dealer's price")
local cvSurgery = CreateConVar("lc_surgery_price", "300", FLAGS, "Credits for a new face at the Resistance lab (0: no surgery)")
local cvSurgeryWait = CreateConVar("lc_surgery_minutes", "60", FLAGS, "Minutes before the same person can have their face changed again")
local cvSurgeryFloor = CreateConVar("lc_surgery_standing", "-50", FLAGS, "A new face: the city's records can't put a name to it, so a Civil Standing lower than this comes back up to it")

local NEAR = 170 -- how close to him you stand to deal with him

local function Rebel(ply) return ply:GetNW2String("lcf_faction", "") == "resistance" end
local function Say(ply, text) ply:ChatPrint("[Scientist] " .. text) end
local function Where(pos) return LC.DescribePlace and LC.DescribePlace(pos) or "" end

------------------------------------------------------------------------
-- The lab itself
------------------------------------------------------------------------

-- Dr. Kleiner's lab kit, on the bench: { model, across (0..1), along (0..1), yaw }
local CLUTTER = {
    { "models/props_lab/monitor01a.mdl", 0.45, 0.30, 180 },
    { "models/props_lab/reciever01a.mdl", 0.40, 0.62, 170 },
    { "models/props_lab/jar01a.mdl", 0.60, 0.80, 0 },
    { "models/props_lab/harddrive02.mdl", 0.55, 0.48, 90 },
}

-- Who runs each lab: Dr. Kleiner, Eli Vance or Dr. Magnusson, a different one at each
-- (the first that isn't at another lab already; any of them again past three labs).
LC.SCIENTISTS = {
    { id = "kleiner", name = "Dr. Kleiner", model = "models/kleiner.mdl" },
    { id = "eli", name = "Eli Vance", model = "models/eli.mdl" },
    { id = "magnusson", name = "Dr. Magnusson", model = "models/magnusson.mdl" },
}
-- Each scientist's own voice (the owner, 1 November: they all spoke in Dr. Kleiner's): Kleiner his lab
-- lines, the others an ordinary man's (Half-Life 2 has none of theirs for these).
local SCI_VOICE = {
    kleiner = { ohdear = "vo/k_lab/kl_ohdear.wav", excellent = "vo/k_lab/kl_excellent.wav" },
    other = { ohdear = "vo/npc/male01/ohno.wav", excellent = "vo/npc/male01/yeah02.wav" },
}
local function SciSay(sci, kind, lvl)
    if not IsValid(sci) then return end
    local v = SCI_VOICE[sci.lcWho == "kleiner" and "kleiner" or "other"]
    sci:EmitSound(v[kind] or v.excellent, lvl or 65)
end
LC.ScientistSay = SciSay

function LC.PickScientist(bench)
    local taken = {}
    for _, e in ipairs(LC.EntsOf and LC.EntsOf("lc_scientist") or ents.FindByClass("lc_scientist")) do
        if IsValid(e) and e.lcWho and e.lcLab ~= bench then taken[e.lcWho] = true end
    end
    local free = {}
    for _, s in ipairs(LC.SCIENTISTS) do
        if not taken[s.id] and (not util.IsValidModel or util.IsValidModel(s.model)) then free[#free + 1] = s end
    end
    if #free == 0 then
        for _, s in ipairs(LC.SCIENTISTS) do if not util.IsValidModel or util.IsValidModel(s.model) then free[#free + 1] = s end end
    end
    return free[math.random(math.max(1, #free))] or LC.SCIENTISTS[1]
end

-- Set a lab up: the clutter on the bench, and the scientist beside it. (The
-- bench calls this once it's in place; calling it again changes nothing.)
function LC.SetupLab(bench)
    if not IsValid(bench) then return end
    local mins, maxs = bench:OBBMins(), bench:OBBMaxs()
    if not bench.lcClutter and not bench.lcKleiner then -- (Kleiner's workstations come with their own kit)
        bench.lcClutter = {}
        for _, c in ipairs(CLUTTER) do
            if not util.IsValidModel or util.IsValidModel(c[1]) then
                local spot = bench:LocalToWorld(Vector(mins.x + (maxs.x - mins.x) * c[2], mins.y + (maxs.y - mins.y) * c[3], maxs.z + 4))
                -- down onto the bench's top, wherever its shape puts it
                local tr = util.TraceLine({ start = spot + Vector(0, 0, 30), endpos = spot - Vector(0, 0, (maxs.z - mins.z)), filter = bench.lcClutter })
                local top = (tr and tr.Hit and tr.Entity == bench) and tr.HitPos or spot
                local p = ents.Create("prop_dynamic")
                if IsValid(p) then
                    p:SetModel(c[1])
                    p:SetPos(top)
                    p:SetAngles(bench:GetAngles() + Angle(0, c[4], 0))
                    p:Spawn()
                    if p.SetSolid then p:SetSolid(SOLID_NONE) end
                    p:SetParent(bench)
                    bench.lcClutter[#bench.lcClutter + 1] = p
                end
            end
        end
    end
    if not IsValid(bench.lcScientist) then
        local s = ents.Create("lc_scientist")
        if IsValid(s) then
            local who = LC.PickScientist(bench)
            s.lcModel, s.lcWho = who.model, who.id
            LC.PlaceScientist(bench, s)
            s:Spawn()
            s:SetNW2String("lc_pname", who.name)
            s:SetNW2String("lc_pjob", "The Resistance's scientist: decodes chips, makes what a cell needs")
            s.lcLab = bench
            bench.lcScientist = s
        end
    end
    return bench.lcScientist
end

-- Stand the scientist beside the bench, facing the way it faces (towards
-- whoever placed it); the other side if that's a wall. Also when the bench
-- is moved with the physgun, so he goes with it.
function LC.PlaceScientist(bench, s)
    s = s or (IsValid(bench) and bench.lcScientist)
    if not IsValid(bench) or not IsValid(s) then return end
    local mins, maxs = bench:OBBMins(), bench:OBBMaxs()
    local mid = bench:LocalToWorld(Vector((mins.x + maxs.x) / 2, (mins.y + maxs.y) / 2, mins.z + 40))
    local pos
    for _, side in ipairs({ maxs.y + 24, mins.y - 24 }) do
        local try = bench:LocalToWorld(Vector((mins.x + maxs.x) / 2 + 8, side, mins.z + 40))
        local tr = util.TraceLine({ start = mid, endpos = try, mask = MASK_SOLID_BRUSHONLY })
        if not (tr and tr.Hit) then pos = try break end
    end
    pos = pos or bench:LocalToWorld(Vector(maxs.x + 26, 0, mins.z + 40))
    s:SetPos(LC.GroundAt and LC.GroundAt(pos) or (pos - Vector(0, 0, 40)))
    s:SetAngles(Angle(0, bench:GetAngles().y, 0))
end

-- The scientist within reach of pos (and not taken away), or nil.
function LC.ScientistNear(pos, dist)
    dist = dist or NEAR
    local best, bd
    for _, e in ipairs(LC.EntsOf and LC.EntsOf("lc_scientist") or {}) do
        if IsValid(e) and not LC.LabShut(e) and not (LC.LabBroken and LC.LabBroken(e)) then -- (wrecked: sv_livingcity_labdamage.lua)
            local d = e:GetPos():DistToSqr(pos)
            if d < dist * dist and (not bd or d < bd) then best, bd = e, d end
        end
    end
    return best
end

function LC.LabShut(sci) return IsValid(sci) and sci:GetNW2Float("lc_away_until", 0) > CurTime() end

-- What he charges for one, in credits.
function LC.LabPrice(r)
    local g = LCS.BlackById and LCS.BlackById[r.out]
    local it = LCS.Items[r.item or r.out]
    local p = math.ceil((g and g.price or 50) * cvPrice:GetFloat())
    if it and it.arms then
        local qm = GetConVar("lc_quartermaster_arms_bonus")
        p = math.max(p, math.ceil((it.sell or 0) * (qm and qm:GetFloat() or 1.5)) + 2)
    elseif it and it.sell then
        p = math.max(p, it.sell + 1) -- (never less than it sells back for: no credits out of thin air)
    end
    return p * (r.count or 1) -- (a batch: so many at once)
end

------------------------------------------------------------------------
-- Dealing with him
------------------------------------------------------------------------

function LC.SendLab(ply, sci)
    local credits = LC.Credits and LC.Credits(ply) or 0
    local inv = LC.Inventory and LC.Inventory(ply) or {}
    local items = {}
    for _, r in ipairs(LCS.Lab or {}) do
        local it = LCS.Items[r.out]
        if it then
            local can, mats = true, {}
            for id, n in pairs(r.needs) do
                local have = inv[id] or 0
                if have < n then can = false end
                mats[#mats + 1] = { name = LCS.Items[id] and LCS.Items[id].name or id, have = math.min(have, n), need = n }
            end
            table.sort(mats, function(a, b) return a.name < b.name end)
            local price = LC.LabPrice(r)
            items[#items + 1] = { id = r.id, name = it.name .. ((r.count or 1) > 1 and string.format(" (%d)", r.count) or ""), desc = r.desc or it.desc, mats = mats, canMats = can,
                price = price, canPay = credits >= price, secs = r.secs }
        end
    end
    local job = IsValid(sci) and sci.lcLabJob
    local busy = job and IsValid(job.ply) and job.ply ~= ply and job.untilT > CurTime() and math.ceil(job.untilT - CurTime()) or nil
    -- the Combine's data, decoded here (sv_livingcity_heist.lua)
    local decode = {}
    for _, id in ipairs({ "data_chip", "master_chip" }) do
        if (inv[id] or 0) > 0 and LCS.Items[id] then
            decode[#decode + 1] = { id = id, name = LCS.Items[id].name, n = inv[id],
                desc = id == "master_chip" and "150 XP, 150 credits, and every Civil Protection unit marked for the whole Resistance for ten minutes"
                    or "50 XP, 50 credits, and every Civil Protection unit marked for the whole Resistance for five minutes" }
        end
    end
    -- a new face (LC.LabSurgery)
    local surgery
    if cvSurgery:GetInt() > 0 then
        local ok, why = LC.SurgeryReady(ply)
        surgery = { price = cvSurgery:GetInt(), ok = ok, why = why }
    end
    LC.SendCompressed("lc_lab", { items = items, credits = credits, busy = busy, decode = decode, surgery = surgery }, { ply })
end

local GREET = {
    "He looks up from a tangle of wires. \"Ah! Yes, hello. What do you need?\"",
    "\"Mind the, ah, the jar. What can I make for you?\"",
    "He pushes his glasses up his nose. \"Materials, or credits? Either will do.\"",
}

function LC.UseScientist(ply, sci)
    if not IsValid(ply) or not IsValid(sci) or not ply:Alive() or LC.LabShut(sci) then return end
    if LC.StalkerCantSpeak and LC.StalkerCantSpeak(ply, sci) then return end
    if (ply.lcLabUse or 0) > CurTime() then return end
    ply.lcLabUse = CurTime() + 0.8
    if LC.PlayerIsCP and LC.PlayerIsCP(ply) then return LC.ShutLab(ply, sci) end
    if not Rebel(ply) then
        SciSay(sci, "ohdear", 70)
        Say(ply, "He steps between you and the bench. \"I'm terribly sorry, I don't believe we've met. This is a private... laboratory. Please, go.\"")
        return
    end
    -- wrecked by the Combine: nothing to work with until it's fixed (sv_livingcity_labdamage.lua)
    if LC.LabBroken and LC.LabBroken(sci) then
        SciSay(sci, "ohdear", 70)
        Say(ply, "He waves at the smoking bench. \"Look at it! I can't make so much as a fuse until this is repaired. Spare parts, and a pair of hands: the job's on your board (F4), 'Get the lab running'.\"")
        if LC.Notice then LC.Notice(ply, "warn", "The lab is wrecked", "Nothing can be made, decoded or done here until it's repaired. Take the job 'Get the lab running' from your board (F4).", 7) end
        return
    end
    if (ply.lcLabGreet or 0) < CurTime() then
        ply.lcLabGreet = CurTime() + 120
        Say(ply, GREET[math.random(#GREET)])
    end
    if LC.HasItem and (LC.HasItem(ply, "data_chip") or LC.HasItem(ply, "master_chip") or LC.HasItem(ply, "data_shard")) then
        Say(ply, LC.HasItem(ply, "data_shard") and not LC.HasItem(ply, "data_chip") and not LC.HasItem(ply, "master_chip")
            and "\"Half a chip? Bring me the other fragment and I'll decode the lot.\""
            or "\"Is that Combine data? I can decode that. (Decode: at the top of my list.)\"")
    end
    LC.SendLab(ply, sci)
end

-- Have him make one. how: "mats" (from your pockets) or "pay". True, or false and why not.
function LC.LabMake(ply, id, how)
    local r = LCS.LabById and LCS.LabById[id]
    if not r or not IsValid(ply) then return false end
    if not Rebel(ply) then return false, "He only works for the Resistance." end
    local sci = LC.ScientistNear(ply:GetPos())
    if not IsValid(sci) then return false, "Find the scientist in the lab." end
    if LC.Busy and LC.Busy(ply) then return false, "You're busy." end
    local job = sci.lcLabJob
    if job and IsValid(job.ply) and job.untilT > CurTime() then
        if job.ply == ply then return false, "He's still working on the last thing." end
        return false, string.format("He's in the middle of someone else's work (%ds).", math.ceil(job.untilT - CurTime()))
    end
    local it = LCS.Items[r.out]
    local price = LC.LabPrice(r)
    if how == "pay" then
        if not LC.Credits or LC.Credits(ply) < price then return false, "He wants " .. price .. " credits for that. You don't have them." end
        LC.AddCredits(ply, -price, "the lab")
    else
        for mid, n in pairs(r.needs) do
            if not LC.HasItem(ply, mid, n) then return false, "You're missing the materials (" .. string.lower(LCS.Items[mid] and LCS.Items[mid].name or mid) .. ")." end
        end
        for mid, n in pairs(r.needs) do LC.TakeItem(ply, mid, n) end
    end
    local job = { ply = ply, untilT = CurTime() + r.secs }
    local settled = false
    -- Once only. Someone who died mid-job gets nothing back (that life's
    -- credits are gone with it); their materials are left on the bench.
    local function Refund(p)
        if settled then return end
        settled = true
        if not IsValid(p) then return end
        if not p:Alive() then
            if how ~= "pay" and LC.SpawnWorldItem then
                local at = (IsValid(sci) and sci:GetPos() or p:GetPos()) + Vector(0, 0, 40)
                for mid, n in pairs(r.needs) do for _ = 1, n do LC.SpawnWorldItem(mid, at) end end
            end
            return
        end
        if how == "pay" then LC.AddCredits(p, price, "the lab, handed back")
        else for mid, n in pairs(r.needs) do LC.GiveOrDrop(p, mid, n) end end
    end
    local function Clear() if IsValid(sci) and sci.lcLabJob == job then sci.lcLabJob = nil end end
    sci.lcLabJob = job
    sci:EmitSound("buttons/lever7.wav", 60)
    Say(ply, how == "pay" and "\"Credits. Yes. Fine. Give me a moment.\"" or "\"Ah, good, good. Let me see what I can do with these.\"")
    local ok, why = LC.StartTask(ply, r.secs, "The scientist is making your " .. string.lower(it.name) .. "... stay in the lab", {
        maxMove = 220,
        done = function(p)
            settled = true
            Clear()
            for _ = 1, r.count or 1 do
                if not LC.GiveItem(p, r.out) and LC.SpawnWorldItem then LC.SpawnWorldItem(r.out, p:GetPos() + p:GetForward() * 30 + Vector(0, 0, 20)) end
            end
            SciSay(sci, "excellent", 65)
            Say(p, "\"There. Do be careful with it.\" He hands you: " .. it.name .. ".")
            hook.Run("LivingCityLabMade", p, r.out, how)
        end,
        cancel = function(p) Clear() Refund(p) end,
        cancelText = "[Scientist] You wander off. He sighs, and hands it all back.",
    })
    if not ok then
        Clear()
        Refund(ply)
        return false, why
    end
    return true
end

------------------------------------------------------------------------
-- A new face. Papers in a dead man's name don't stop a unit who knows your
-- face; the scientist can change it. Twenty seconds under (stay on the table),
-- lc_surgery_price credits, and you wake with someone else's face, bandaged
-- and slow on your feet for a few minutes. Nobody's looking for that face:
-- your wanted status, any BOLO on you and the scanners' pictures are gone,
-- a wanted notice won't match it, and a Civil Standing below
-- lc_surgery_standing (-50) comes back up to it (the records can't put a name
-- to the face). Get wanted again and they learn the new one.
------------------------------------------------------------------------

function LC.SurgeryReady(ply)
    if not Rebel(ply) then return false, "He only works for the Resistance." end
    local price = cvSurgery:GetInt()
    if price <= 0 then return false, "\"Surgery? Here? Good heavens, no.\"" end
    local next = tonumber(ply:GetPData("lc_surgery_next", 0)) or 0
    if os.time() < next then return false, string.format("\"Your face needs to heal first.\" (%d min)", math.ceil((next - os.time()) / 60)) end
    if not LC.Credits or LC.Credits(ply) < price then return false, string.format("%d credits, and you don't have them.", price) end
    return true
end

local function NewFace(ply)
    local cur = string.lower(ply:GetNW2String("lc_model", ply:GetModel() or ""))
    local female = string.find(cur, "female", 1, true) ~= nil
    local list = {}
    for _, m in ipairs(LCF and LCF.CitizenModels or {}) do
        if string.lower(m) ~= cur and (string.find(string.lower(m), "female", 1, true) ~= nil) == female then list[#list + 1] = m end
    end
    return #list > 0 and list[math.random(#list)] or nil
end

function LC.LabSurgery(ply)
    local ok, why = LC.SurgeryReady(ply)
    if not ok then return false, why end
    local sci = LC.ScientistNear(ply:GetPos())
    if not IsValid(sci) then return false, "Find the scientist in the lab." end
    local job = sci.lcLabJob
    if job and IsValid(job.ply) and job.untilT > CurTime() then return false, "He's in the middle of someone else's work." end
    local price = cvSurgery:GetInt()
    LC.AddCredits(ply, -price, "a new face")
    job = { ply = ply, untilT = CurTime() + 20 }
    sci.lcLabJob = job
    local function Clear() if IsValid(sci) and sci.lcLabJob == job then sci.lcLabJob = nil end end
    Say(ply, "\"Lie down, lie down. You'll feel a little... well. You won't feel anything, actually. Count backwards from ten.\"")
    ply:ScreenFade(bit.bor(SCREENFADE.OUT or 2, SCREENFADE.STAYOUT or 8), Color(0, 0, 0, 255), 2, 0)
    ply:EmitSound("items/medshot4.wav", 60)
    local okT, whyT = LC.StartTask(ply, 20, "Under the knife... stay on the table", {
        maxMove = 120,
        done = function(p)
            Clear()
            p:ScreenFade(SCREENFADE.PURGE or 16, Color(0, 0, 0, 0), 0, 0)
            p:ScreenFade(SCREENFADE.IN, Color(0, 0, 0, 255), 4, 1)
            local model = NewFace(p)
            if model and LC.SetCharacter then LC.SetCharacter(p, nil, model) end
            if LC.ClearWanted then LC.ClearWanted(p) end
            if LC.ResetHeat then LC.ResetHeat(p) end
            if LC.CalmCops then LC.CalmCops(p) end
            if LC.DropBolosFor and LC.RecordKey then LC.DropBolosFor(LC.RecordKey(p)) if LC.SyncBolos then LC.SyncBolos() end end
            p:SetNW2Float("lc_spotted_until", 0)
            p:SetPData("lc_new_face", "1")
            local floor = cvSurgeryFloor:GetInt()
            local s = LC.Standing and LC.Standing(p) or 0
            if LC.AddStanding and s < floor then LC.AddStanding(p, floor - s, "a face the records don't know") end
            p:SetPData("lc_surgery_next", os.time() + cvSurgeryWait:GetFloat() * 60)
            p:SetNW2Float("lc_crippled_until", CurTime() + 180) -- (bandaged, and slow on your feet a while)
            p:SetNW2Float("lc_bandaged_until", CurTime() + 300)
            SciSay(sci, "excellent", 65)
            Say(p, "\"There. Nobody will know you. Well, I hardly do. Keep the bandages on a few minutes, and don't run.\"")
            if LC.Notice then LC.Notice(p, "info", "A new face", "Nobody's looking for this face. Your wanted status, any BOLO and the scanners' pictures are gone, and a wanted notice won't match it. Get wanted again and they'll learn this one.", 10) end
            hook.Run("LivingCitySurgery", p)
        end,
        cancel = function(p)
            Clear()
            if IsValid(p) then
                p:ScreenFade(SCREENFADE.PURGE or 16, Color(0, 0, 0, 0), 0, 0)
                LC.AddCredits(p, price, "the lab, handed back")
            end
        end,
        cancelText = "[Scientist] You sit up too soon. \"No, no, no! We'll have to do this another time.\" He hands your credits back.",
    })
    if not okT then
        Clear()
        ply:ScreenFade(SCREENFADE.PURGE or 16, Color(0, 0, 0, 0), 0, 0)
        LC.AddCredits(ply, price, "the lab, handed back")
        return false, whyT
    end
    return true
end

net.Receive("lc_lab_surgery", function(_, ply)
    if not IsValid(ply) or (ply.lcLabNext or 0) > CurTime() then return end
    ply.lcLabNext = CurTime() + 0.5
    local ok, why = LC.LabSurgery(ply)
    if not ok and why then ply:ChatPrint("[Lab] " .. why) end
end)

net.Receive("lc_lab_decode", function(_, ply)
    local id = net.ReadString()
    if (id ~= "data_chip" and id ~= "master_chip") or not LC.DecodeChip then return end
    local ok, why = LC.DecodeChip(ply, id)
    if not ok and why then Say(ply, why) end
    if ok then Say(ply, "He slots it into a humming console and leans in. \"Oh, this is marvellous. Get the word out.\"") end
    local sci = LC.ScientistNear(ply:GetPos())
    if IsValid(sci) then LC.SendLab(ply, sci) end
end)

net.Receive("lc_lab_make", function(_, ply)
    if not IsValid(ply) or (ply.lcLabNext or 0) > CurTime() then return end
    ply.lcLabNext = CurTime() + 0.5
    local id, how = net.ReadString(), net.ReadString()
    local ok, why = LC.LabMake(ply, id, how == "pay" and "pay" or "mats")
    if not ok and why then ply:ChatPrint("[Lab] " .. why) end
end)

------------------------------------------------------------------------
-- A unit finds it
------------------------------------------------------------------------

function LC.ShutLab(cop, sci)
    if not IsValid(sci) or LC.LabShut(sci) then return false end
    local secs = cvShut:GetFloat()
    sci:SetNW2Float("lc_away_until", CurTime() + secs)
    sci:SetNotSolid(true)
    sci:SetNoDraw(true)
    sci:EmitSound("npc/metropolice/vo/holdit.wav", 80)
    local job = sci.lcLabJob
    sci.lcLabJob = nil
    if job and IsValid(job.ply) and LC.CancelTask then LC.CancelTask(job.ply) end
    if IsValid(cop) then
        cop:ChatPrint("[Civil Protection] A Resistance lab. The scientist is taken into custody and the equipment smashed. Nothing will be made here for a while.")
        if LC.AddCredits then LC.AddCredits(cop, 30, "a Resistance lab shut down") end
        if LC.AddXP then LC.AddXP(cop, 15, "Shut down a Resistance lab") end
        if LC.AddStanding then LC.AddStanding(cop, 10) end
    end
    if LC.RadioNotice then
        LC.RadioNotice("resistance", "They found the lab " .. Where(sci:GetPos()) .. ". The scientist's been taken. Nothing comes out of there for a while.")
    end
    timer.Simple(secs, function()
        if not IsValid(sci) then return end
        sci:SetNotSolid(false)
        sci:SetNoDraw(false)
        if LC.RadioNotice then LC.RadioNotice("resistance", "The scientist's back at the lab " .. Where(sci:GetPos()) .. ".") end
    end)
    hook.Run("LivingCityLabShut", cop, sci)
    return true
end
