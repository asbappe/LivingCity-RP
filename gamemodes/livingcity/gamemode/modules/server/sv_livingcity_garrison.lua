--[[
    Living City: the nexus garrison

    Every Combine-only zone (the nexus, the offices, the armory) is manned.
    Mostly Overwatch soldiers, with a metrocop or two, spread through the zone:
    some standing post, some walking from one end of it to the other. They're
    on top of the city's own numbers, so the streets don't empty to fill the
    nexus. One killed is replaced after a while, out of sight.

      lc_garrison           most units in one zone (0 = no garrison); a small
                            zone gets fewer (about one per 15x15 metres of floor)
      lc_garrison_cops      out of every ten, how many are metrocops (3)
      lc_garrison_respawn   seconds before a lost unit is replaced (90)
      lc_prison_guards      the prison: only Nova Prospekt guards, this many (2),
                            half again a soldier's health; nobody else garrisoned in it
]]

if CLIENT then return end

LC = LC or {}

local FLAGS = bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED)
local cvMax     = CreateConVar("lc_garrison", "6", FLAGS, "Most Combine units garrisoned in one Combine-only zone (0 = none)")
local cvCops    = CreateConVar("lc_garrison_cops", "3", FLAGS, "Out of every ten garrison Civil Protection units, how many are metrocops (the rest are Overwatch soldiers)")
local cvRespawn = CreateConVar("lc_garrison_respawn", "90", FLAGS, "Seconds before a lost garrison Civil Protection unit is replaced")

LC.Garrison = LC.Garrison or {} -- [npc] = zone

local nextFill = {} -- [zone] = time it may get its next unit

-- How many a zone holds: about one per 15x15 metres (600x600 units) of floor, at least two.
function LC.GarrisonSize(z)
    local most = cvMax:GetInt()
    if most <= 0 then return 0 end
    local area
    if z.box then
        area = (z.box.maxs.x - z.box.mins.x) * (z.box.maxs.y - z.box.mins.y)
    else
        area = math.pi * (z.r or 0) ^ 2
    end
    return math.Clamp(math.floor(area / (600 * 600) + 0.5), math.min(2, most), most)
end

-- The prison (the owner, 1 November): only Nova Prospekt guards, lc_prison_guards (2) of them; no
-- metrocops or soldiers garrisoned in it (a Combine zone that takes it in leaves it to them).
local cvPrison = CreateConVar("lc_prison_guards", "2", FLAGS, "Nova Prospekt prison guards garrisoned in each prison zone (only they guard it)")
LC.GarrisonPrisonGuards = function() return math.max(0, cvPrison:GetInt()) end

local function Count(z)
    local n, cops = 0, 0
    for npc, gz in pairs(LC.Garrison) do
        if gz == z and IsValid(npc) and npc:Health() > 0 then
            n = n + 1
            local st = LC.NPCs[npc]
            if st and st.role == "cop" then cops = cops + 1 end
        end
    end
    return n, cops
end

-- A spot for one to turn up: inside the zone, out of sight, not on top of anyone, and not in a
-- doorway (one stood in a sliding door gets stuck inside it when it closes).
local DOORS = { func_door = true, func_door_rotating = true, prop_door_rotating = true, func_movelinear = true }
local function NearDoor(p)
    for _, e in ipairs(ents.FindInSphere(p, 80)) do if IsValid(e) and DOORS[e:GetClass()] then return true end end
    return false
end
local function InPrison(p)
    for _, pz in ipairs(LC.ZonesOfKind and LC.ZonesOfKind("prison") or {}) do if LCZ.Contains(pz, p, 0) then return true end end
    return false
end
-- Not in a cell, nor by its door (the owner, 7 November: a guard and a soldier stood inside a
-- prisoner's cell, and the door, held open by them, stayed open). Cells and the release spot are
-- kept clear by CELL_CLEAR units, prison doors by DOOR_CLEAR.
local CELL_CLEAR, DOOR_CLEAR = 260, 140
local function NearCell(p)
    for _, kind in ipairs({ "cell", "release" }) do
        for _, c in ipairs(LC.PointsOfKind and LC.PointsOfKind(kind) or {}) do
            if c.pos and c.pos:DistToSqr(p) < CELL_CLEAR * CELL_CLEAR then return true end
        end
    end
    for door in pairs(LC.PrisonDoors or {}) do
        if IsValid(door) and door:WorldSpaceCenter():DistToSqr(p) < DOOR_CLEAR * DOOR_CLEAR then return true end
    end
    return false
end
-- A spot for a prison guard to stand or walk to: in the zone, not in a cell or a cell doorway.
function LC.GuardPostSpot(z)
    for _ = 1, 8 do
        local p = LC.SpotInZone(z)
        if p and not NearCell(p) and not NearDoor(p) then return p end
    end
    return nil
end
local function SpawnSpot(z, prison)
    for _ = 1, 8 do
        local p = LC.SpotInZone(z)
        if p and (prison or not LC.CombineZoneAt or LC.CombineZoneAt(p) == z) and (prison or not InPrison(p)) and not NearDoor(p)
            and not (prison and NearCell(p))
            and not (LC.IsSeen and LC.IsSeen(p + Vector(0, 0, 40)))
            and (not LC.FarFromPlayers or LC.FarFromPlayers(p, 300)) then
            return p
        end
    end
end

function LC.GarrisonOne(z, role)
    local p = SpawnSpot(z, z.kind == "prison")
    if not p then return nil end
    local spawn = role == "cop" and LC.SpawnCop or LC.SpawnSoldier -- (a prison "guard" is a soldier, dressed and armoured below)
    if not spawn then return nil end
    local npc, st = spawn(p + Vector(0, 0, 4))
    if not IsValid(npc) or not st then return nil end
    st.unmanaged = true -- (on top of the city's own numbers)
    st.guardZone = z
    st.routeGroup = nil -- (no beat out on the streets)
    st.garrison = true
    LC.Garrison[npc] = z
    if role == "guard" then
        -- a Nova Prospekt prison guard: all that armour, half again a soldier's health
        if util.IsValidModel == nil or util.IsValidModel("models/combine_soldier_prisonguard.mdl") then npc:SetModel("models/combine_soldier_prisonguard.mdl") end
        local hp = math.floor(npc:Health() * 1.5)
        if npc.SetMaxHealth then npc:SetMaxHealth(hp) end
        npc:SetHealth(hp)
        st.prisonGuard = true
    end
    return npc, st
end

function LC.GarrisonTick(now)
    -- the dead and the gone are forgotten; a zone that's been deleted sends its units away
    for npc, z in pairs(LC.Garrison) do
        if not IsValid(npc) or npc:Health() <= 0 then
            LC.Garrison[npc] = nil
            nextFill[z] = math.max(nextFill[z] or 0, now + cvRespawn:GetFloat())
        elseif not table.HasValue(LC.Zones or {}, z) and not (LC.IsSeen and LC.IsSeen(npc:GetPos() + Vector(0, 0, 40))) then
            LC.Garrison[npc] = nil
            npc:Remove()
        end
    end
    for _, z in ipairs(LC.ZonesOfKind and LC.ZonesOfKind("prison") or {}) do
        local n = Count(z)
        if cvMax:GetInt() > 0 and n < cvPrison:GetInt() and now >= (nextFill[z] or 0) then -- (lc_garrison 0: no garrison anywhere)
            nextFill[z] = now + (LC.GarrisonOne(z, "guard") and 2 or 5)
        end
    end
    for _, z in ipairs(LC.ZonesOfKind and LC.ZonesOfKind("combine") or {}) do
        local want = LC.GarrisonSize(z)
        local n, cops = Count(z)
        if n < want and now >= (nextFill[z] or 0) then
            -- keep the mix: about three in ten metrocops, the rest soldiers
            local copsWant = math.floor(want * math.Clamp(cvCops:GetInt(), 0, 10) / 10 + 0.5)
            if cvCops:GetInt() > 0 and want >= 2 then copsWant = math.max(1, copsWant) end
            local soldiers, soldiersWant = n - cops, want - copsWant
            local role = "soldier"
            if cops < copsWant and (soldiers >= soldiersWant or math.random() < 0.3) then role = "cop" end
            if LC.GarrisonOne(z, role) then
                nextFill[z] = now + (n + 1 < want and 2 or 0) -- (filling up: one every couple of seconds)
            else
                nextFill[z] = now + 5
            end
        elseif n > want then
            -- the editor turned it down: the extras slip away when nobody's looking
            for npc, gz in pairs(LC.Garrison) do
                if n <= want then break end
                if gz == z and IsValid(npc) and not (LC.IsSeen and LC.IsSeen(npc:GetPos() + Vector(0, 0, 40))) then
                    LC.Garrison[npc] = nil
                    npc:Remove()
                    n = n - 1
                end
            end
        end
    end
end

timer.Create("LivingCityGarrison", 2, 0, function()
    if not LC.Running then return end
    local ok, err = pcall(LC.GarrisonTick, CurTime())
    if not ok and LC.Log then LC.Log("error", "garrison: " .. tostring(err)) end
end)

hook.Add("LivingCityStopped", "LivingCityGarrison", function()
    LC.Garrison = {}
    nextFill = {}
end)
