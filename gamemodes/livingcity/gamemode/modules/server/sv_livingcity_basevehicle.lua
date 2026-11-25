--[[
    Living City: a vehicle for the Resistance's base (the owner, 20 November: "each base has one vehicle
    available when the base is setup there": the buggy, and the airboat for the canal's shantytown).

    A spot for one is a "Point: Resistance base vehicle" placed with the Miscount Editor (it faces the way
    you faced), or an info_target in the map named lc_base_vehicle... (with "airboat" or "buggy" in the name
    to say which). A spot in water gets Half-Life 2's airboat, any other its buggy.

    While the base is live, the spot nearest its flag (within REACH) has its vehicle. Anyone can drive it,
    a unit too. Left empty far from its spot for five minutes, it is back at the spot. When the base is
    struck, ransacked or moved, the vehicle is gone as soon as nobody sits in it. Nothing is written on
    anyone's screen: it is there or it is not.
]]

LC = LC or {}
LC.BaseVehicle = LC.BaseVehicle or {}
local V = LC.BaseVehicle

local REACH = 4000   -- (how far from the flag a spot may be and still be that base's)
local STRAY = 600    -- (further from its spot than this, and empty, it is counted as left behind)
local BACK = 300     -- (seconds left behind before it is back at its spot)

V.Kinds = {
    buggy = { class = "prop_vehicle_jeep", model = "models/buggy.mdl", script = "scripts/vehicles/jeep_test.txt", up = 16 },
    airboat = { class = "prop_vehicle_airboat", model = "models/airboat.mdl", script = "scripts/vehicles/airboat.txt", up = 24 },
}

local function InWater(pos)
    if LC.InWater then return LC.InWater(pos + Vector(0, 0, 8)) and true or false end
    return util.PointContents and bit.band(util.PointContents(pos + Vector(0, 0, 8)), CONTENTS_WATER or 32) ~= 0 or false
end

-- Every spot: the editor's points and the map's own markers.
function V.Spots()
    local out = {}
    for _, p in ipairs(LC.PointsOfKind and LC.PointsOfKind("basevehicle") or {}) do
        out[#out + 1] = { pos = p.pos, yaw = p.yaw or 0 }
    end
    for _, t in ipairs(ents.FindByName and ents.FindByName("lc_base_vehicle*") or {}) do
        if IsValid(t) then
            local n = string.lower(tostring(t.GetName and t:GetName() or ""))
            local kind = (string.find(n, "airboat", 1, true) and "airboat") or ((string.find(n, "buggy", 1, true) or string.find(n, "jeep", 1, true)) and "buggy") or nil
            local a = t.GetAngles and t:GetAngles()
            out[#out + 1] = { pos = t:GetPos(), yaw = a and (a.y or a.yaw) or 0, kind = kind }
        end
    end
    for _, s in ipairs(out) do s.kind = s.kind or (InWater(s.pos) and "airboat" or "buggy") end
    return out
end

-- The live base's spot: the nearest to its flag, within reach.
function V.SpotOf(pos)
    if not pos then return nil end
    local best, bd
    for _, s in ipairs(V.Spots()) do
        local d = s.pos:DistToSqr(pos)
        if d <= REACH * REACH and (not bd or d < bd) then best, bd = s, d end
    end
    return best
end

local function Empty(veh)
    local d = veh.GetDriver and veh:GetDriver()
    return not IsValid(d)
end

function V.Spawn(spot)
    local k = V.Kinds[spot.kind] or V.Kinds.buggy
    if util.IsValidModel and not util.IsValidModel(k.model) then return nil end
    local veh = ents.Create(k.class)
    if not IsValid(veh) then return nil end
    veh:SetModel(k.model)
    veh:SetKeyValue("vehiclescript", k.script)
    veh:SetPos(spot.pos + Vector(0, 0, k.up))
    veh:SetAngles(Angle(0, spot.yaw or 0, 0))
    veh:Spawn()
    if veh.Activate then veh:Activate() end
    veh.lcBaseVehicle = true
    return veh
end

function V.Remove()
    if IsValid(V.ent) then V.ent:Remove() end
    V.ent, V.spot, V.strayAt = nil, nil, nil
end

-- Every few seconds: the live base has its vehicle, and nobody else does.
function V.Tick()
    local B = LC.Base
    local live = LC.BaseLive and LC.BaseLive() and B and B.S and B.S.pos or nil
    local spot = live and V.SpotOf(live) or nil
    if IsValid(V.ent) then
        local moved = not spot or not V.spot or spot.pos:DistToSqr(V.spot.pos) > 1
        if moved then
            if Empty(V.ent) then V.Remove() end -- (whoever is driving keeps it until they get out)
        elseif Empty(V.ent) and V.ent:GetPos():DistToSqr(V.spot.pos) > STRAY * STRAY then
            V.strayAt = V.strayAt or CurTime()
            if CurTime() - V.strayAt >= BACK then V.Remove() end
        else
            V.strayAt = nil
        end
    else
        V.ent = nil
    end
    if spot and not IsValid(V.ent) then
        V.ent = V.Spawn(spot)
        V.spot = IsValid(V.ent) and spot or nil
        V.strayAt = nil
    end
end

timer.Create("LivingCityBaseVehicle", 5, 0, function()
    if LC.Running == false then return end
    local ok, err = LC.Try(V.Tick)
    if not ok and LC.Error then LC.Error("base vehicle", err) end
end)
hook.Add("LivingCityStopped", "LivingCityBaseVehicle", function() V.Remove() end)
hook.Add("PostCleanupMap", "LivingCityBaseVehicle", function() V.ent, V.spot, V.strayAt = nil, nil, nil end)
