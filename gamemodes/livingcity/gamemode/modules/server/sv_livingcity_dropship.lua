--[[
    Living City: the Combine's dropship

    Overwatch landings (sv_livingcity_resistanceops.lua) and supply drops
    (sv_livingcity_convoy.lua) arrive by air when there's open sky over the
    spot: a dropship comes in from a distance, descends, hovers while its
    soldiers come out (or sets its cargo container down), and climbs away again.

      LC.FlyDropship{ pos = ground spot, hold = seconds over it,
                      cargo = true (bring a container and leave it there),
                      troops = true (as Half-Life 2 does it: the troop
                        container stays in the claws, hovering just off the
                        ground; its door opens, the soldiers come out of it,
                        the door shuts and it all lifts away together),
                      pickup = entity (lift it away),
                      onLanded(ship, ground, container, door) (door: troops
                        only, { pos, dir } just outside the open door),
                      onLeaving(ship), onGone() }
        returns the ship, or nil and why (no open sky over the spot, or no
        clear way in): the caller does it another way (on foot, by road).

    Nothing collides with the ship; it's flown by the server along its path.
]]

if CLIENT then return end

LC = LC or {}
LC.Dropships = LC.Dropships or {} -- list of flights

local SHIP = "models/combine_dropship.mdl"
local CONTAINER = "models/combine_dropship_container.mdl"
local UP = Vector(0, 0, 1)

local function ModelOK(m) return not util.IsValidModel or util.IsValidModel(m) end

-- Open air straight above pos: how much, and whether it's sky at the top (not a ceiling).
local function Headroom(pos)
    local tr = util.TraceLine({ start = pos + Vector(0, 0, 10), endpos = pos + Vector(0, 0, 6000), mask = MASK_SOLID_BRUSHONLY })
    if not tr or not tr.Hit then return 6000, true end
    return tr.HitPos.z - pos.z, tr.HitSky == true
end
LC.DropshipHeadroom = Headroom

local function Clear(a, b)
    local tr = util.TraceLine({ start = a, endpos = b, mask = MASK_SOLID_BRUSHONLY })
    return tr and not tr.Hit
end

local function Ease(kind, f)
    if kind == "out" then return 1 - (1 - f) * (1 - f) end
    if kind == "in" then return f * f end
    if kind == "inout" then return f < 0.5 and 2 * f * f or 1 - 2 * (1 - f) * (1 - f) end
    return f
end

-- The flight: in from afar to a point over the spot, down, a while there, up, and away.
-- above: how high over the ground the ship's origin hovers.
local function Plan(ground, shipMins, shipMaxs, above, hold)
    local room, sky = Headroom(ground)
    if not sky then return nil, "there's a roof over it, not open sky" end
    local hoverZ = ground.z + above
    local hover = Vector(ground.x, ground.y, hoverZ)
    local shipH = shipMaxs.z - shipMins.z
    local climb = math.min(900, room - (hoverZ - ground.z) - shipMaxs.z - 60)
    if climb < 150 then return nil, "not enough open sky over it" end
    local top = hover + UP * climb
    local offset = math.random() * 360
    local ways = {}
    for i = 0, 15 do
        local dir = Angle(0, offset + i * 22.5, 0):Forward()
        for _, dist in ipairs({ 3000, 2200, 1500 }) do
            local far = top + dir * dist
            if Clear(top, far) and Clear(top + Vector(0, 0, -shipH * 0.5), far + Vector(0, 0, -shipH * 0.5)) then
                ways[#ways + 1] = { dir = dir, far = far }
                break
            end
        end
    end
    if #ways == 0 then return nil, "no clear way in over the rooftops" end
    local inWay = ways[1]
    local outWay = inWay
    for _, w in ipairs(ways) do
        if w.dir:Dot(inWay.dir) < -0.2 then outWay = w break end -- (out the other side, if it can)
    end
    local yawIn = (top - inWay.far):Angle().y
    local yawOut = (outWay.far - top):Angle().y
    return {
        { a = inWay.far, b = top, secs = 10, ease = "out", yaw = yawIn, pitch = 8 },
        { a = top, b = hover, secs = 5, ease = "inout", yaw = yawIn, landing = true },
        { a = hover, b = hover, secs = hold or 12, hold = true, yaw = yawIn },
        { a = hover, b = top, secs = 4, ease = "inout", yaw = yawIn, leaving = true },
        { a = top, b = outWay.far, secs = 9, ease = "in", yaw = yawOut, pitch = 10 },
    }, hover
end

-- Where a carried container hangs: in the ship's claws. The container model is
-- drawn in the ship's own frame (Half-Life 2 puts it at the ship's origin, at
-- the ship's angles, and parents it there), so it goes exactly where the ship
-- is, tilting with it. (It used to be hung a further body-length down, and
-- dangled about fifteen feet under the ship.)
local function Hang(f)
    if not IsValid(f.ship) or not IsValid(f.cargo) then return end
    f.cargo:SetPos(f.ship:GetPos())
    f.cargo:SetAngles(f.ship:GetAngles())
end

function LC.FlyDropship(opts)
    if not opts or not opts.pos then return nil, "nowhere to go" end
    if not ModelOK(SHIP) then return nil, "no dropship model on this server" end
    if #LC.Dropships >= 3 then return nil, "the sky's busy" end
    local ship = ents.Create("lc_dropship")
    if not IsValid(ship) then return nil, "no dropship" end
    ship.lcModel = SHIP
    ship:SetModel(SHIP)
    local sMins, sMaxs = ship:OBBMins(), ship:OBBMaxs()
    -- the container it brings, or the one it's come for (hanging at the ship's origin: Hang)
    local cargo, above = nil, -sMins.z + 60
    if opts.troops and ModelOK(CONTAINER) then
        -- a troop container: animated (its door), and never let go of
        cargo = ents.Create("prop_dynamic")
        if IsValid(cargo) then
            cargo:SetModel(CONTAINER)
            local cMins = cargo:OBBMins()
            above = -cMins.z + 12 -- (hovering just off the ground, doorway at boot height)
            cargo.lcContainerMins = cMins
            cargo.lcTroops = true
        end
    elseif opts.cargo and ModelOK(CONTAINER) then
        cargo = ents.Create("prop_physics")
        if IsValid(cargo) then
            cargo:SetModel(CONTAINER)
            local cMins = cargo:OBBMins()
            above = -cMins.z + 16 -- (the container's bottom just off the ground, then set down)
            cargo.lcContainerMins = cMins
        end
    elseif IsValid(opts.pickup) then
        above = -opts.pickup:OBBMins().z + 1 -- (down to where it sits, to take hold of it)
    end
    local legs, hover = Plan(opts.pos, sMins, sMaxs, above, opts.hold)
    if not legs then
        ship:Remove()
        if IsValid(cargo) then cargo:Remove() end
        return nil, hover
    end
    ship:SetPos(legs[1].a)
    ship:SetAngles(Angle(legs[1].pitch or 0, legs[1].yaw, 0))
    ship:Spawn()
    ship:Activate()
    if IsValid(cargo) then
        cargo:SetPos(legs[1].a)
        cargo:Spawn()
        cargo:Activate()
        local phys = cargo:GetPhysicsObject()
        if IsValid(phys) then phys:EnableMotion(false) end
        if cargo.SetCollisionGroup then cargo:SetCollisionGroup(COLLISION_GROUP_WORLD) end -- (nobody's knocked flat by it on the way in)
        cargo.lcDressing = true
    end
    local f = { ship = ship, legs = legs, leg = 1, legStart = CurTime(), ground = opts.pos, hover = hover,
        cargo = cargo, pickup = opts.pickup, opts = opts, nextDust = 0 }
    LC.Dropships[#LC.Dropships + 1] = f
    if sound and sound.Play then sound.Play("ambient/machines/heli_pass_distant1.wav", opts.pos, 100) end
    Hang(f)
    return ship
end

-- The container's door: open, shut, and the spot just outside it.
local function ContainerSeq(c, names)
    if not IsValid(c) or not c.LookupSequence then return false end
    for _, n in ipairs(names) do
        local seq = c:LookupSequence(n)
        if seq and seq >= 0 then c:ResetSequence(seq) return true end
    end
    return false
end

function LC.DropshipDoor(c)
    if not IsValid(c) then return nil end
    -- Half-Life 2's container marks where its troops step off; else its back end
    for _, a in ipairs({ "deploy_landpoint", "Deploy_Landpoint", "deploy_start", "Deploy_Start" }) do
        local id = c.LookupAttachment and c:LookupAttachment(a) or 0
        if id and id > 0 then
            local att = c:GetAttachment(id)
            if att and att.Pos then
                local dir = att.Pos - c:WorldSpaceCenter() dir.z = 0
                return { pos = att.Pos, dir = dir:GetNormalized() }
            end
        end
    end
    local mins, maxs = c:OBBMins(), c:OBBMaxs()
    local dir = -c:GetForward()
    return { pos = c:LocalToWorld(Vector(mins.x - 24, (mins.y + maxs.y) / 2, mins.z + 4)), dir = dir }
end

local function Dust(pos)
    if util.Effect and EffectData then
        local ed = EffectData()
        ed:SetOrigin(pos)
        ed:SetScale(320)
        util.Effect("ThumperDust", ed, true, true)
    end
end

local function Step(f, now)
    if not IsValid(f.ship) then
        if IsValid(f.cargo) and f.cargo ~= f.dropped then f.cargo:Remove() end
        return false
    end
    local leg = f.legs[f.leg]
    local t = math.Clamp((now - f.legStart) / leg.secs, 0, 1)
    local pos = LerpVector(Ease(leg.ease, t), leg.a, leg.b)
    if leg.hold then pos = pos + Vector(0, 0, math.sin(now * 1.6) * 5) end
    local pitch = (leg.pitch or 0) * math.sin(t * math.pi)
    f.ship:SetPos(pos)
    f.ship:SetAngles(Angle(pitch, leg.yaw, 0))
    Hang(f)
    -- the downdraught kicks up the dust
    if (leg.landing and t > 0.4 or leg.hold or (leg.leaving and t < 0.5)) and now > f.nextDust then
        f.nextDust = now + 0.6
        Dust(f.ground)
    end
    if t < 1 then return true end
    -- the end of a leg
    if leg.landing then
        if IsValid(f.cargo) and f.cargo.lcTroops then
            -- troops: the door opens where it hangs; it stays in the claws
            ContainerSeq(f.cargo, { "open_idle", "open", "door_open" })
            f.cargo:EmitSound("doors/heavy_metal_move1.wav", 85)
            f.door = LC.DropshipDoor(f.cargo)
            if f.opts.onLanded then
                local ok, err = LC.Try(f.opts.onLanded, f.ship, f.ground, f.cargo, f.door)
                if not ok and LC.Error then LC.Error("dropship", err) end
            end
            f.leg = f.leg + 1
            f.legStart = now
            return true
        elseif IsValid(f.cargo) then
            -- set the container down, and let go of it
            local c = f.cargo
            local mins = c.lcContainerMins or c:OBBMins()
            c:SetPos(Vector(f.ground.x, f.ground.y, f.ground.z - mins.z + 1))
            c:SetAngles(Angle(0, leg.yaw, 0))
            if c.SetCollisionGroup then c:SetCollisionGroup(COLLISION_GROUP_NONE) end
            c:EmitSound("physics/metal/metal_box_impact_hard" .. math.random(1, 3) .. ".wav", 90)
            f.dropped, f.cargo = c, nil
        end
        if IsValid(f.pickup) then
            f.cargo = f.pickup -- (lifted with it from here)
            if f.cargo.SetCollisionGroup then f.cargo:SetCollisionGroup(COLLISION_GROUP_WORLD) end
        end
        if f.opts.onLanded then
            local ok, err = LC.Try(f.opts.onLanded, f.ship, f.ground, f.dropped)
            if not ok and LC.Error then LC.Error("dropship", err) end
        end
    elseif leg.hold then
        if IsValid(f.cargo) and f.cargo.lcTroops then
            ContainerSeq(f.cargo, { "close_idle", "close", "door_close" })
            f.cargo:EmitSound("doors/heavy_metal_stop1.wav", 85)
        end
        -- (a troop carrier takes its container away again)
        if f.opts.takeAway and IsValid(f.dropped) and not f.cargo then
            f.cargo = f.dropped
            f.dropped = nil
            if f.cargo.SetCollisionGroup then f.cargo:SetCollisionGroup(COLLISION_GROUP_WORLD) end
            f.cargo:EmitSound("physics/metal/metal_box_impact_soft" .. math.random(1, 3) .. ".wav", 85)
        end
        if f.opts.onLeaving then LC.Try(f.opts.onLeaving, f.ship) end
    end
    f.leg = f.leg + 1
    f.legStart = now
    if f.leg > #f.legs then
        f.ship:Remove()
        if IsValid(f.cargo) then f.cargo:Remove() end -- (what it lifted goes with it)
        if f.opts.onGone then LC.Try(f.opts.onGone) end
        return false
    end
    return true
end

timer.Create("LivingCityDropships", 0.03, 0, function()
    if #LC.Dropships == 0 then return end
    local now = CurTime()
    for i = #LC.Dropships, 1, -1 do
        local ok, keep = LC.Try(Step, LC.Dropships[i], now)
        if not ok then
            if LC.Error then LC.Error("dropship", keep) end
            local f = LC.Dropships[i]
            if IsValid(f.ship) then f.ship:Remove() end
            keep = false
        end
        if not keep then table.remove(LC.Dropships, i) end
    end
end)

hook.Add("LivingCityStopped", "LivingCityDropships", function()
    for _, f in ipairs(LC.Dropships) do
        if IsValid(f.ship) then f.ship:Remove() end
        if IsValid(f.cargo) then f.cargo:Remove() end
    end
    LC.Dropships = {}
end)
