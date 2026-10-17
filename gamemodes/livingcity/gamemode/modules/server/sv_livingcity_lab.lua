--[[
    Living City: the Resistance lab

    A lab ("Fixture: Resistance lab" in the editor; entities/lc_workbench.lua)
    is one of Dr. Kleiner's own lab workstations with a scientist standing
    beside it (entities/lc_scientist.lua): the Resistance's own. He decodes
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
    still made by hand, from F2, anywhere.
]]

if CLIENT then return end

LC = LC or {}

util.AddNetworkString("lc_lab")
util.AddNetworkString("lc_lab_make")
util.AddNetworkString("lc_lab_decode")

local FLAGS = bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED)
local cvShut  = CreateConVar("lc_lab_shutdown", "600", FLAGS, "Seconds a Resistance lab stays shut after a Civil Protection unit finds it")
local cvPrice = CreateConVar("lc_lab_price", "0.6", FLAGS, "What the Resistance's scientist charges, times the black market dealer's price")

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
            LC.PlaceScientist(bench, s)
            s:Spawn()
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
        if IsValid(e) and not LC.LabShut(e) then
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
    local it = LCS.Items[r.out]
    local p = math.ceil((g and g.price or 50) * cvPrice:GetFloat())
    if it and it.arms then
        local qm = GetConVar("lc_quartermaster_arms_bonus")
        p = math.max(p, math.ceil((it.sell or 0) * (qm and qm:GetFloat() or 1.5)) + 2)
    end
    return p
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
            items[#items + 1] = { id = r.id, name = it.name, desc = r.desc or it.desc, mats = mats, canMats = can,
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
    LC.SendCompressed("lc_lab", { items = items, credits = credits, busy = busy, decode = decode }, { ply })
end

local GREET = {
    "He looks up from a tangle of wires. \"Ah! Yes, hello. What do you need?\"",
    "\"Mind the, ah, the jar. What can I make for you?\"",
    "He pushes his glasses up his nose. \"Materials, or credits? Either will do.\"",
}

function LC.UseScientist(ply, sci)
    if not IsValid(ply) or not IsValid(sci) or not ply:Alive() or LC.LabShut(sci) then return end
    if (ply.lcLabUse or 0) > CurTime() then return end
    ply.lcLabUse = CurTime() + 0.8
    if LC.PlayerIsCP and LC.PlayerIsCP(ply) then return LC.ShutLab(ply, sci) end
    if not Rebel(ply) then
        sci:EmitSound("vo/k_lab/kl_ohdear.wav", 70)
        Say(ply, "He steps between you and the bench. \"I'm terribly sorry, I don't believe we've met. This is a private... laboratory. Please, go.\"")
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
            if not LC.GiveItem(p, r.out) and LC.SpawnWorldItem then LC.SpawnWorldItem(r.out, p:GetPos() + p:GetForward() * 30 + Vector(0, 0, 20)) end
            if IsValid(sci) then sci:EmitSound("vo/k_lab/kl_excellent.wav", 65) end
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
