--[[
    Living City: the hive boss (the owner's long-term list, 3: "blind, hunts by sound ... bullets barely
    hurt it ... spawns when much of the city is infested; killing it crashes the infestation").

    The owner chose a Workshop NextBot for it, 25 November: "half life alyx jeff npc/nextbot"
    (steamcommunity.com/sharedfiles/filedetails/?id=2149660804). That addon is the creature: it hears
    running and jumping, walks the map's navmesh and only explosives hurt it. This module only decides
    when it comes, where, and what its death does. Without the addon on the server nothing happens.

      lc_hiveboss 0        (the default) it never comes by itself; staff can still send one:
                           F4 > Factions > Admin: testing tools > Testing alone > Hive boss.
      lc_hiveboss 1        it comes when at least half the districts are badly infested (two at least),
                           in the infestation nearest the worst one, out of players' sight; one at a time,
                           and not again for lc_hiveboss_minutes (90) after one dies.
      lc_hiveboss_class    its entity class. Empty: found by itself (the addon's class with "jeff" in it).

    Dead, the infestation crashes: every infestation loses half of what it had grown, the furthest first.
    Near it the air is thick with spores: anyone within 500 units with no gas mask coughs (a mask in the
    pockets goes on by itself, as in gas). Nothing is written on anyone's screen.

    The addon needs a navmesh for the map (maps/<map>.nav on the server). Not run in the real game yet.
]]

LC = LC or {}
LC.HiveBoss = LC.HiveBoss or {}
local H = LC.HiveBoss

H.Workshop = "2149660804"

local FLAGS = bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED)
local cvOn = CreateConVar("lc_hiveboss", "0", FLAGS, "The hive boss comes by itself when half the districts are badly infested (needs the Workshop NextBot 2149660804 on the server)")
local cvMin = CreateConVar("lc_hiveboss_minutes", "90", FLAGS, "Minutes after a hive boss dies before another can come")
local cvClass = CreateConVar("lc_hiveboss_class", "", FLAGS, "The hive boss's entity class (empty: the installed class with 'jeff' in its name)")

local SPORES, BAD = 500, 50
local COUGHS = { "ambient/voices/cough1.wav", "ambient/voices/cough2.wav", "ambient/voices/cough3.wav", "ambient/voices/cough4.wav" }

-- Players who join download the addon's model and sounds, once the boss is switched on.
if resource and resource.AddWorkshop and cvOn:GetBool() then resource.AddWorkshop(H.Workshop) end

-- The creature's class: the setting, else whatever the server has with "jeff" in its name.
function H.Class()
    local set = string.Trim(cvClass:GetString() or "")
    if set ~= "" then return set end
    local found = {}
    for name in pairs(scripted_ents and scripted_ents.GetList and scripted_ents.GetList() or {}) do
        if string.find(string.lower(tostring(name)), "jeff", 1, true) then found[#found + 1] = name end
    end
    for name, t in pairs(list and list.Get and list.Get("NPC") or {}) do
        local class = istable(t) and t.Class or name
        if string.find(string.lower(tostring(name) .. " " .. tostring(class)), "jeff", 1, true) and not table.HasValue(found, class) then found[#found + 1] = class end
    end
    table.sort(found)
    return found[1]
end

function H.Alive() return IsValid(H.ent) and (not H.ent.Health or H.ent:Health() > 0) end

-- Where: the placed infestation nearest the worst district's middle (any, if districts say nothing).
function H.Spot()
    local worst, score
    for _, n in ipairs(LC.BlockNumbers and LC.BlockNumbers() or {}) do
        local v = LC.DistrictInfest and LC.DistrictInfest(n) or 0
        if not score or v > score then worst, score = n, v end
    end
    local mid = worst and LC.BlockCenter and LC.BlockCenter(worst) or nil
    local best, bd
    for _, z in ipairs(LC.ZonesOfKind and LC.ZonesOfKind("infest") or {}) do
        if not z.grown then
            local d = mid and z.pos:DistToSqr(mid) or 0
            local seen = LC.IsSeen and LC.IsSeen(z.pos + Vector(0, 0, 40))
            if seen then d = d + 1e12 end -- (out of sight first)
            if not bd or d < bd then best, bd = z, d end
        end
    end
    return best and best.pos or nil
end

function H.Spawn(pos)
    if H.Alive() then return false, "One is already out." end
    local class = H.Class()
    if not class then return false, "The hive boss addon is not on this server (Workshop 2149660804)." end
    pos = pos or H.Spot()
    if not pos then return false, "No infestation is placed on this map." end
    local e = ents.Create(class)
    if not IsValid(e) then return false, "The class " .. tostring(class) .. " could not be made." end
    e:SetPos(pos + Vector(0, 0, 8))
    e:Spawn()
    if e.Activate then e:Activate() end
    e.lcHiveBoss = true
    H.ent, H.bornAt = e, CurTime()
    hook.Run("LivingCityHiveBoss", e)
    return true
end

function H.Remove()
    local e = H.ent
    H.ent = nil
    if IsValid(e) then e.lcHiveBoss = nil e:Remove() end
end

-- Its death: every placed infestation loses half of what grew from it, the furthest first.
function H.Crash()
    local gone = 0
    for _, seed in ipairs(LC.ZonesOfKind and LC.ZonesOfKind("infest") or {}) do
        if not seed.grown then
            local grown = {}
            for _, z in ipairs(LC.Zones) do if z.grown and z.seed == seed then grown[#grown + 1] = z end end
            table.sort(grown, function(a, b) return a.pos:DistToSqr(seed.pos) > b.pos:DistToSqr(seed.pos) end)
            for i = 1, math.ceil(#grown / 2) do
                local z = grown[i]
                for k, q in ipairs(LC.Zones) do if q == z then table.remove(LC.Zones, k) break end end
                gone = gone + 1
                hook.Run("LivingCityTerritoryReceded", seed, z, "the hive boss is dead")
            end
        end
    end
    if gone > 0 then
        if LC.SaveTerritory then LC.SaveTerritory() end
        if LC.DistrictInfestForget then LC.DistrictInfestForget() end
    end
    return gone
end

function H.Died(by)
    if not H.ent then return end
    H.ent, H.deadAt = nil, CurTime()
    local gone = H.Crash()
    if LC.Log then LC.Log("info", "The hive boss is dead: " .. gone .. " patches of infestation gone") end
    hook.Run("LivingCityHiveBossDead", by, gone)
end

hook.Add("OnNPCKilled", "LivingCityHiveBoss", function(npc, attacker) if npc == H.ent then H.Died(attacker) end end)
hook.Add("EntityRemoved", "LivingCityHiveBoss", function(e)
    -- (a NextBot that dies is removed without OnNPCKilled on some bases: gone with no health left counts)
    if e == H.ent and e.lcHiveBoss and e.Health and e:Health() <= 0 then H.Died(nil) end
end)

-- Should one come by itself now?
function H.Due()
    if not cvOn:GetBool() or H.Alive() then return false end
    if H.deadAt and CurTime() - H.deadAt < cvMin:GetFloat() * 60 then return false end
    local blocks = LC.BlockNumbers and LC.BlockNumbers() or {}
    local bad = 0
    for _, n in ipairs(blocks) do if (LC.DistrictInfest and LC.DistrictInfest(n) or 0) >= BAD then bad = bad + 1 end end
    return bad >= 2 and bad * 2 >= #blocks
end

function H.Tick()
    if H.ent and not IsValid(H.ent) then H.ent = nil end
    if H.Due() then H.Spawn() end
end

-- The spores round it.
function H.Spores()
    if not H.Alive() then return end
    local at = H.ent:GetPos()
    for _, p in ipairs(player.GetAll()) do
        if p:Alive() and p:GetPos():DistToSqr(at) <= SPORES * SPORES and (p.lcSporeCough or 0) <= CurTime() then
            if not (LC.GasMaskPlayer and LC.GasMaskPlayer(p)) then
                p.lcSporeCough = CurTime() + math.Rand(4, 8)
                p:EmitSound(COUGHS[math.random(#COUGHS)], 75, math.random(92, 108))
            else
                p.lcSporeCough = CurTime() + 2
            end
        end
    end
end

timer.Create("LivingCityHiveBoss", 60, 0, function()
    if LC.Running == false then return end
    local ok, err = LC.Try(H.Tick)
    if not ok and LC.Error then LC.Error("hive boss", err) end
end)
timer.Create("LivingCityHiveBossSpores", 1, 0, function() LC.Try(H.Spores) end)
hook.Add("LivingCityStopped", "LivingCityHiveBoss", function() H.Remove() end)
hook.Add("PostCleanupMap", "LivingCityHiveBoss", function() H.ent = nil end)
