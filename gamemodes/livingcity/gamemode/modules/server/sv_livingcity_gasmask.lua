--[[
    Living City: gas masks, and how people take the gas and the flashbang

    The owner, 13 November.
      Masks        A gas mask is contraband: no citizen NPC ever has one.
                   Rebel players get them from a Civil Protection uniform in
                   their pockets (F3: Scavenge gas mask; the uniform is used
                   up), or by searching a dead unit: half the time an intact
                   mask, otherwise a broken one (dead, the mask most likely
                   broke with them); four broken masks make one (F3, Make).
                   About 1 in 3 rebel fighters (NPCs) carries one
                   (lc_gasmask_rebels, 0.33).
      In the gas   Whoever has a mask puts it on by themselves as the gas
                   reaches them (players too, nothing to pick) and takes no
                   harm from chlorine or weedkiller gas; it comes off by itself
                   a few seconds after they're out of it. Everyone else in it
                   covers their mouth with their left hand and coughs for as
                   long as they're in it, and NPCs (never the masked
                   Metrocops and Overwatch) run from it as fast as they can:
                   first along a way out that keeps clear of Combine units,
                   and straight into them only when there's no other way out.
      Flashbang    A blinded NPC covers their eyes with their left hand (the
                   right is where the gun was) and stumbles about
                   (sv_livingcity_fieldops.lua).
    Drawn by cl_livingcity_gasmask.lua: NW2 lc_gasmask_on (the mask: a unit's
    helmet and mask, on the face), lc_handface ("eyes" or "mouth") until
    lc_handface_until.
]]

if CLIENT then return end

LC = LC or {}

local FLAGS = bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED)
local cvRebels = CreateConVar("lc_gasmask_rebels", "0.33", FLAGS, "How many Resistance fighters (NPCs) carry a gas mask (0 to 1)")
LC.GASMASK_INTACT = 0.5 -- (a dead unit's mask: half the time it's whole)
local OFF_AFTER = 3     -- seconds out of the gas before a mask comes off

------------------------------------------------------------------------
-- Hands to the face
------------------------------------------------------------------------

function LC.HandToFace(ent, kind, secs)
    if not IsValid(ent) or not ent.SetNW2String then return end
    if ent:GetNW2String("lc_handface", "") ~= kind then ent:SetNW2String("lc_handface", kind) end
    ent:SetNW2Float("lc_handface_until", CurTime() + (secs or 1.5))
end
function LC.HandFromFace(ent)
    if IsValid(ent) and ent.SetNW2Float then ent:SetNW2Float("lc_handface_until", 0) end
end

------------------------------------------------------------------------
-- Masks
------------------------------------------------------------------------

LC.GasMaskWorn = LC.GasMaskWorn or {} -- [ent] = last time it was needed

function LC.CarriesGasMask(ply)
    return IsValid(ply) and ply:IsPlayer() and LC.HasItem ~= nil and LC.HasItem(ply, "gas_mask") == true
end

-- An NPC's: only a Resistance fighter, decided once (a citizen never: it's contraband).
function LC.NPCHasGasMask(npc, st)
    if not st or st.role ~= "rebel" then return false end
    if st.gasMask == nil then st.gasMask = math.random() < cvRebels:GetFloat() end
    return st.gasMask == true
end

-- On it goes (for a player, the first time they're told).
function LC.GasMaskOn(ent)
    if not IsValid(ent) then return end
    local was = LC.GasMaskWorn[ent]
    LC.GasMaskWorn[ent] = CurTime()
    if not ent:GetNW2Bool("lc_gasmask_on", false) then
        ent:SetNW2Bool("lc_gasmask_on", true)
        ent:EmitSound("player/suit_sprint.wav", 60, 70)
        if ent:IsPlayer() and not was and LC.Notice then
            LC.Notice(ent, "info", "Gas mask", "You pull your gas mask on. The gas can't get at you while you're wearing it.", 5)
        end
    end
end
function LC.GasMaskOff(ent)
    LC.GasMaskWorn[ent] = nil
    if IsValid(ent) and ent:GetNW2Bool("lc_gasmask_on", false) then ent:SetNW2Bool("lc_gasmask_on", false) end
end

-- A player in the gas with a mask in their pockets puts it on (sv_livingcity_crafting.lua's Masked asks this).
function LC.GasMaskPlayer(ply)
    if not LC.CarriesGasMask(ply) then return false end
    LC.GasMaskOn(ply)
    return true
end

-- Off by themselves once out of it a few seconds (or the mask is gone from their pockets, or they died).
timer.Create("LivingCityGasMaskOff", 1, 0, function()
    local now = CurTime()
    for ent, t in pairs(LC.GasMaskWorn) do
        local gone = not IsValid(ent) or (ent:IsPlayer() and (not ent:Alive() or not LC.CarriesGasMask(ent))) or (ent:IsNPC() and ent:Health() <= 0)
        if gone or now - t > OFF_AFTER then LC.GasMaskOff(ent) end
    end
end)

------------------------------------------------------------------------
-- Getting one: off a uniform, off the dead, four broken ones
------------------------------------------------------------------------

function LC.ScavengeGasMask(ply)
    if not IsValid(ply) then return false end
    if LC.PlayerIsCP and LC.PlayerIsCP(ply) then return false, "You have your own mask." end
    if not (LC.HasItem and LC.HasItem(ply, "uniform_cp")) then return false, "You need a Civil Protection uniform in your pockets." end
    if LC.Busy and LC.Busy(ply) then return false, "You're busy." end
    if LC.StartTask then
        return LC.StartTask(ply, 5, "Cutting the mask out of the uniform... keep still", {
            maxMove = 40, cancelText = "You put the uniform down.",
            done = function(p)
                if not LC.HasItem(p, "uniform_cp") then return end
                LC.TakeItem(p, "uniform_cp")
                if not LC.GiveItem(p, "gas_mask") and LC.SpawnWorldItem then LC.SpawnWorldItem("gas_mask", p:GetPos() + p:GetForward() * 30 + Vector(0, 0, 20)) end
                p:EmitSound("physics/cardboard/cardboard_box_break1.wav", 55)
                p:ChatPrint("You cut the gas mask out of the uniform. The rest of it is no good to anyone now.")
                if LC.SeenBySecurity and LC.SeenBySecurity(p, 900) and LC.ReportCrime then
                    LC.ReportCrime(p, "Possessing Combine equipment", 120)
                end
            end,
        })
    end
    LC.TakeItem(ply, "uniform_cp")
    LC.GiveItem(ply, "gas_mask")
    return true
end

-- A dead unit's mask, for whoever searches them (sv_livingcity_bodies.lua's loot): whole or broken.
function LC.DeadUnitMask()
    return math.random() < LC.GASMASK_INTACT and "gas_mask" or "gas_mask_broken"
end

------------------------------------------------------------------------
-- Running from the gas
------------------------------------------------------------------------

local function CombineSpots()
    local out = {}
    for npc, st in pairs(LC.NPCs or {}) do
        if IsValid(npc) and npc:Health() > 0 and LC.IsSecurity and LC.IsSecurity(st) then out[#out + 1] = npc:GetPos() end
    end
    for _, p in ipairs(player.GetAll()) do
        if p:Alive() and LC.RadioUnit and LC.RadioUnit(p) then out[#out + 1] = p:GetPos() end
    end
    return out
end
LC.GasCombineSpots = CombineSpots

-- How many Combine units are near the way from a to b (within 380 of the line, or 450 of the end).
local function CombineOnTheWay(a, b, spots)
    local n = 0
    local ab = b - a
    local len2 = math.max(1, ab:LengthSqr())
    for _, c in ipairs(spots) do
        local t = math.Clamp((c - a):Dot(ab) / len2, 0, 1)
        if (a + ab * t):DistToSqr(c) < 380 * 380 or c:DistToSqr(b) < 450 * 450 then n = n + 1 end
    end
    return n
end
LC.GasCombineOnTheWay = CombineOnTheWay

-- Where to run: eight ways out of the cloud, each as far as there's room; the way out with no Combine unit on
-- it, the farthest from the gas; with none, the way with the fewest (straight into them, if that's all there is).
function LC.GasFleeSpot(npc, g, spots)
    local from = npc:GetPos()
    local centre = Vector(g.pos.x, g.pos.y, from.z)
    local away = from - centre
    away.z = 0
    if away:LengthSqr() < 1 then away = Vector(1, 0, 0) end
    away:Normalize()
    local base = math.deg(math.atan2(away.y, away.x))
    local best, bestN, bestD
    for i = 0, 7 do
        local a = math.rad(base + i * 45)
        local dir = Vector(math.cos(a), math.sin(a), 0)
        local want = centre + dir * (g.r + 260)
        local tr = util.TraceHull({ start = from + Vector(0, 0, 18), endpos = want + Vector(0, 0, 18), mins = Vector(-14, -14, 0),
            maxs = Vector(14, 14, 50), mask = MASK_NPCSOLID_BRUSHONLY, filter = npc })
        local dest = tr.HitPos - Vector(0, 0, 18) - dir * (tr.Hit and 20 or 0)
        local clear = dest:Distance(centre)
        if clear > g.r + 40 then
            local n = CombineOnTheWay(from, dest, spots)
            if not best or n < bestN or (n == bestN and clear > bestD) then best, bestN, bestD = dest, n, clear end
        end
    end
    -- walled in on every side: straight away from the middle, whatever is there
    return best or (from + away * (g.r + 200)), bestN or 0
end

-- An NPC in a cloud (sv_livingcity_crafting.lua's gas timer, once a second). Returns true if a mask kept it out.
function LC.GasNPC(npc, st, g, now, spots)
    if LC.IsSecurity and LC.IsSecurity(st) then return false end -- (masked anyway; the crafting timer decides)
    if st.role == "zombie" or st.role == "scanner" then return false end
    if LC.NPCHasGasMask(npc, st) then
        LC.GasMaskOn(npc)
        return true
    end
    LC.HandToFace(npc, "mouth", 1.6)
    if (st.gasCoughAt or 0) <= now then
        st.gasCoughAt = now + math.Rand(0.8, 1.6)
        npc:EmitSound("ambient/voices/cough" .. math.random(1, 4) .. ".wav", 70, math.random(95, 110))
    end
    return false
end

-- Run: as fast as they can, the way GasFleeSpot picks; kept for a moment so they don't turn back and forth.
function LC.GasFlee(npc, st, g, now, spots)
    if not (IsValid(npc) and npc:Health() > 0 and npc.SetLastPosition) then return end
    if st.state == "detained" or st.state == "jailed" or npc:GetNW2Bool("lc_cuffed", false) then return end
    if not st.gasFleeTo or (st.gasFleeAt or 0) < now - 3 or npc:GetPos():DistToSqr(st.gasFleeTo) < 60 * 60 then
        st.gasFleeTo = LC.GasFleeSpot(npc, g, spots or CombineSpots())
        st.gasFleeAt = now
    end
    st.gasFleeUntil = now + 1.6 -- (their own thinking waits while they run: sv_livingcity.lua's Think)
    npc:SetEnemy(NULL)
    npc:SetLastPosition(st.gasFleeTo)
    npc:SetSchedule(SCHED_FORCED_GO_RUN)
end
