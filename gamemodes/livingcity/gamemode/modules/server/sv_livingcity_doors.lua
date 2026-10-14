--[[
    Living City: doors

    Door tags (set with the Living City Editor tool, saved per map):
      cp      Civil Protection only. NPC citizens never open it; CP players and admins can.
              In a blackout (sv_livingcity_power.lua) its lock goes dead and it opens.
      prison  A prison or cell door: Civil Protection only, like cp, but it stays
              locked when the power goes, and if anything else opens it (a map
              button, a trigger) it shuts and locks itself again at once.
      locked  Stays locked for everyone.
      open    Opened when the city starts and kept open: its own timer that swings it
              shut again is turned off, it's locked in the open position (E does
              nothing), and if anything shuts it anyway (map logic) it opens again.
      ignore  NPCs never open it, but players use it normally (good for doors that
              lead nowhere, or that NPCs keep getting stuck in).
      force   Treat this as a door NPCs can use, even if it doesn't look like one
              (wide gates and shutters the shape check rejects).
      rent    An apartment door people can rent (!rent): locked to everyone but
              the tenant and whoever they give a key to.
      (none)  A normal door. Unlocked on start if lc_unlock_doors is 1.

    NPCs get doors opened for them two ways: any door right next to them, and any
    door standing between them and the next point on their route.
]]

if CLIENT then return end

LC = LC or {}
LC.OpenedDoors = LC.OpenedDoors or {} -- [door] = time it may auto-close
LC.Relock = LC.Relock or {}           -- [door] = true if we unlocked it for an NPC

local FLAGS = bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED)
local cvUnlock      = CreateConVar("lc_unlock_doors", "1", FLAGS, "Unlock untagged map doors when the city starts")
local cvPlayerDoors = CreateConVar("lc_player_doors", "1", FLAGS, "Let players open brush doors with E")
local cvNPCDoors    = CreateConVar("lc_npc_doors", "1", FLAGS, "Open doors for Living City NPCs as they walk up")

local DOOR_CLASSES = { prop_door_rotating = true, func_door = true, func_door_rotating = true, func_movelinear = true } -- (movelinear: the Combine's sliding doors, on some maps)
local SF_DOOR_USE_OPENS = 256
local LOCKED_SOUND = "doors/default_locked.wav"

local function Say(ply, msg)
    if IsValid(ply) then ply:ChatPrint("[Living City] " .. msg) else print("[Living City] " .. msg) end
end

local function ShapeLooksLikeDoor(ent)
    if ent:GetClass() == "prop_door_rotating" then return true end
    local size = ent:OBBMaxs() - ent:OBBMins()
    return size.z >= 60 and math.min(size.x, size.y) <= 40
end

-- func_door is also used for lifts and platforms. Only treat it as a door if it
-- is tall and thin (or tagged "force"), so NPCs never set off an elevator.
-- A door you've tagged (Civil Protection only, prison, always open, force...)
-- is a door whatever its shape: a wide Combine shutter, a sliding brush. So is
-- one that's Combine-only or a prison door by where it is. ("ignore" stays out.)
local function IsRealDoor(ent)
    if not LC.IsDoorEntity(ent) then return false end
    local now = CurTime()
    local c = ent.lcTagCache
    if not c or c.t < now then
        c = { t = now + 5, tag = LC.EffectiveDoorTag and LC.EffectiveDoorTag(ent) or LC.GetDoorTag(ent) }
        ent.lcTagCache = c
    end
    if c.tag and c.tag ~= "ignore" then return true end
    return ShapeLooksLikeDoor(ent)
end
LC.IsRealDoor = IsRealDoor

-- Doors with no tag of your own lock themselves: by a prison cell, the release
-- point or inside the prison area they're prison doors; in a Combine-only zone
-- they're Civil Protection only. Tag a door (open, ignore, force, locked...)
-- and your tag wins.
local AUTO_CELL_RADIUS = 450

function LC.AutoDoorTag(door)
    if not IsValid(door) or LC.GetDoorTag(door) then return nil end
    if not LC.IsDoorEntity(door) then return nil end
    local pos = door:WorldSpaceCenter()
    for _, p in ipairs(LC.Points or {}) do
        if (p.kind == "cell" or p.kind == "release") and pos:DistToSqr(p.pos) < AUTO_CELL_RADIUS * AUTO_CELL_RADIUS then return "prison" end
    end
    local cp = false
    for _, z in ipairs(LC.Zones or {}) do
        if z.kind == "prison" and LCZ.Contains(z, pos) then return "prison" end
        if z.kind == "combine" and LCZ.Contains(z, pos) then cp = true end
    end
    return cp and "cp" or nil
end

-- Locked to everyone but units (and keycards, and picks that take long enough).
local function UnitsOnly(tag) return tag == "cp" or tag == "prison" end
LC.UnitsOnlyDoorTag = UnitsOnly

local function IsLocked(door)
    return door:GetInternalVariable("m_bLocked") == true
end

------------------------------------------------------------------------
-- Applying tags to the world
------------------------------------------------------------------------

LC.PrisonDoors = LC.PrisonDoors or {} -- [door] = true: the ones that lock themselves again
LC.KeptOpen = LC.KeptOpen or {}       -- [door] = true: tagged "open", held open

-- A door's own "close again after a while" (func_door: wait; prop_door_rotating:
-- returndelay). -1 is never. Off for a door kept open, and put back as it was
-- when it isn't any more.
local RETURN_KEY = { prop_door_rotating = { "returndelay", "m_flAutoReturnDelay" },
    func_door = { "wait", "m_flWait" }, func_door_rotating = { "wait", "m_flWait" } }
local function HoldOpen(door, on)
    local k = RETURN_KEY[door:GetClass()]
    if not k then return end
    if on then
        if door.lcReturnWas == nil then
            local v = door:GetInternalVariable(k[2])
            door.lcReturnWas = v ~= nil and tostring(v) or false
        end
        door:SetKeyValue(k[1], "-1")
    elseif door.lcReturnWas ~= nil then
        if door.lcReturnWas then door:SetKeyValue(k[1], door.lcReturnWas) end
        door.lcReturnWas = nil
    end
end

-- Shut, or swinging shut? (nil if the door won't say.)
local function Shutting(door)
    if door:GetClass() == "prop_door_rotating" then
        local s = door:GetInternalVariable("m_eDoorState")
        if s == nil then return nil end
        return s == 0 or s == 3 -- (closed, closing)
    end
    local s = door:GetInternalVariable("m_toggle_state")
    if s == nil then return nil end
    return s == 1 or s == 3 -- (at the bottom, going down)
end

local function OpenAndHold(door)
    door:Fire("Unlock")
    door:Fire("Open", "", 0.1)
    door:Fire("Lock", "", 1.5) -- (in the open position: E won't shut it)
end

function LC.ApplyDoorState(door)
    if not IsValid(door) then return end
    if door.lcHeldOpen then OpenAndHold(door) return end -- (a secret ending locked every door open)
    local tag = LC.GetDoorTag(door)
    local auto = not tag and LC.AutoDoorTag and LC.AutoDoorTag(door) or nil
    LC.OpenedDoors[door] = nil
    LC.Relock[door] = nil
    LC.PrisonDoors[door] = (tag == "prison" or auto == "prison") or nil
    LC.KeptOpen[door] = tag == "open" or nil
    HoldOpen(door, tag == "open")
    if tag == "locked" then
        door:Fire("Close")
        door:Fire("Lock", "", 0.1)
    elseif tag == "prison" or auto == "prison" then
        -- a prison door is locked whatever happens, power or no power
        door:Fire("Close")
        door:Fire("Lock", "", 0.1)
    elseif tag == "cp" or auto == "cp" then
        -- Combine doors, and the ones by the cells, are physically locked, not just "denied":
        -- units and keycards open them, nothing else does. (Unless the power's out: sv_livingcity_power.lua)
        if LC.PowerOut and LC.PowerOut[door] then
            door:Fire("Unlock")
        else
            door:Fire("Close")
            door:Fire("Lock", "", 0.1)
        end
    elseif tag == "open" then
        OpenAndHold(door)
    elseif tag == "rent" then
        -- an apartment: locked while somebody rents it and keeps it locked (sv_livingcity_business.lua)
        if LC.ApplyRentDoor then LC.ApplyRentDoor(door) else door:Fire("Unlock") end
    elseif cvUnlock:GetBool() then
        door:Fire("Unlock") -- RP gamemodes own their doors; leave them be
    end
end

function LC.ApplyAllDoors()
    local n = 0
    for class in pairs(DOOR_CLASSES) do
        for _, door in ipairs(ents.FindByClass(class)) do
            LC.ApplyDoorState(door)
            n = n + 1
        end
    end
    return n
end

------------------------------------------------------------------------
-- Opening doors for NPCs
------------------------------------------------------------------------

local function NPCMayOpen(role, tag, locked, st)
    if role == "zombie" or role == "scanner" then return false end
    if tag == "locked" or tag == "open" or tag == "ignore" then return false end
    if UnitsOnly(tag) then
        if role == "cop" or role == "soldier" then return true end
        -- a prisoner being walked in, or let out, is taken through
        return role == "citizen" and st ~= nil and (st.state == "escorted" or (st.poi ~= nil and st.poi.kind == "release"))
    end
    return not locked -- a door a player locked stays shut
end

local function TryOpenFor(st, door)
    if not IsRealDoor(door) then return end
    if LC.OpenedDoors[door] then
        LC.OpenedDoors[door] = math.max(LC.OpenedDoors[door], CurTime() + 4)
        return
    end
    local locked = IsLocked(door)
    if not NPCMayOpen(st.role, LC.EffectiveDoorTag(door), locked, st) then return end
    if st.workEscort and LC.EscortWatchDoor then LC.EscortWatchDoor(st.workEscort, door) end -- (sv_livingcity_escort.lua)
    if locked then
        LC.Relock[door] = true
        door:Fire("Unlock")
    end
    door:Fire("Open")
    LC.OpenedDoors[door] = CurTime() + 4
    -- a pigeon in the swing would stop the door dead
    if LC.Wildlife and LC.ShooBird then
        for e, kind in pairs(LC.Wildlife) do
            if IsValid(e) and kind == "bird" and e:Health() > 0 and (door:WorldSpaceCenter():DistToSqr(e:GetPos()) < 110 * 110 or door:GetPos():DistToSqr(e:GetPos()) < 110 * 110) then LC.ShooBird(e, door) end
        end
    end
end

-- Someone in the doorway: don't shut it on them. (A prisoner hanging about by
-- their cell door doesn't hold it open.)
local function InCustody(ent)
    if ent:IsPlayer() then return (LC.Prisoners and LC.Prisoners[ent] ~= nil) or (LC.InCustody and LC.InCustody(ent)) end
    local st = LC.NPCs and LC.NPCs[ent]
    return st ~= nil and (st.state == "jailed" or st.state == "detained")
end
local function SomeoneNear(door)
    local prison = LC.PrisonDoors[door]
    for _, ent in ipairs(ents.FindInSphere(door:WorldSpaceCenter(), 110)) do
        if (ent:IsPlayer() or ent:IsNPC()) and not (prison and InCustody(ent)) then return true end
    end
    return false
end

local function DoorAhead(npc, st)
    local hop = st.route and st.route[st.hop]
    if not hop then return nil end
    local from = npc:WorldSpaceCenter()
    local dir = hop + Vector(0, 0, 36) - from
    local len = dir:Length()
    if len < 1 then return nil end
    local tr = util.TraceLine({
        start = from, endpos = from + dir * (math.min(len, 140) / len),
        filter = npc, mask = MASK_NPCSOLID,
    })
    if IsValid(tr.Entity) and DOOR_CLASSES[tr.Entity:GetClass()] then return tr.Entity end
    return nil
end

-- Doors stay where they are: a coarse grid of them, so a walker with no door
-- anywhere near isn't searched for one (rebuilt now and then, for doors
-- spawned in build mode).
local GRID = 256
local doorGrid, gridAt, gridCount = nil, -1e9, -1
local function Key(cx, cy) return (cx + 4096) * 8192 + (cy + 4096) end
local function DoorCount()
    local n = 0
    for cls in pairs(DOOR_CLASSES) do n = n + #LC.EntsOf(cls) end
    return n
end
local function BuildDoorGrid()
    doorGrid = {}
    gridCount = DoorCount()
    for cls in pairs(DOOR_CLASSES) do
        for _, d in ipairs(LC.EntsOf(cls)) do
            local p = d:WorldSpaceCenter()
            doorGrid[Key(math.floor(p.x / GRID), math.floor(p.y / GRID))] = true
        end
    end
    gridAt = CurTime()
end
LC.RebuildDoorGrid = BuildDoorGrid
local function DoorNear(pos)
    local cx, cy = math.floor(pos.x / GRID), math.floor(pos.y / GRID)
    for dx = -1, 1 do
        for dy = -1, 1 do
            if doorGrid[Key(cx + dx, cy + dy)] then return true end
        end
    end
    return false
end

local function DoorThink()
    if not cvNPCDoors:GetBool() then return end
    local now = CurTime()
    if not doorGrid or now - gridAt > 30 or DoorCount() ~= gridCount then BuildDoorGrid() end

    for npc, st in pairs(LC.NPCs or {}) do
        if IsValid(npc) and (st.state == "moving" or st.state == "inspect_approach" or st.state == "escort"
            or st.state == "escorted" or st.state == "workescort") and DoorNear(npc:GetPos()) then
            for _, door in ipairs(ents.FindInSphere(npc:GetPos() + Vector(0, 0, 40), 80)) do
                if DOOR_CLASSES[door:GetClass()] then TryOpenFor(st, door) end
            end
            local ahead = DoorAhead(npc, st)
            if ahead then TryOpenFor(st, ahead) end
        end
    end

    for door, closeAt in pairs(LC.OpenedDoors) do
        if not IsValid(door) then
            LC.OpenedDoors[door] = nil
            LC.Relock[door] = nil
        elseif now > closeAt then
            if SomeoneNear(door) then
                LC.OpenedDoors[door] = now + 2
            else
                door:Fire("Close")
                if LC.Relock[door] and not (LC.PowerOut and LC.PowerOut[door]) then door:Fire("Lock", "", 1) end
                LC.OpenedDoors[door] = nil
                LC.Relock[door] = nil
            end
        end
    end
end

------------------------------------------------------------------------
-- Prison doors stay shut
------------------------------------------------------------------------

-- Open (or opening)? nil if the door won't say.
local function DoorOpen(door)
    if door:GetClass() == "prop_door_rotating" then
        local s = door:GetInternalVariable("m_eDoorState")
        if s == nil then return nil end
        return s ~= 0 -- (0: closed)
    end
    local s = door:GetInternalVariable("m_toggle_state")
    if s == nil then return nil end
    return s ~= 1 -- (1: at rest, shut)
end
LC.DoorIsOpen = DoorOpen

-- Anything that opens a prison door without a unit's say-so (a map button, a
-- trigger, someone else's map logic) and it slams shut and locks again. A unit,
-- an NPC officer walking someone through, a pick or a bypass charge, or the
-- few seconds after a unit presses a button, are the say-so.
function LC.PrisonDoorThink(now)
    if (LC.PrisonDoorsAllowUntil or 0) > now then return 0 end
    local shut = 0
    for door in pairs(LC.PrisonDoors) do
        if not IsValid(door) then
            LC.PrisonDoors[door] = nil
        elseif not LC.OpenedDoors[door] and not door.lcHeldOpen and not (LC.DoorPicked and LC.DoorPicked(door)) then
            if DoorOpen(door) then
                door:Fire("Close")
                door:Fire("Lock", "", 0.1)
                shut = shut + 1
                hook.Run("LivingCityPrisonDoorShut", door)
            elseif not IsLocked(door) then
                door:Fire("Lock")
            end
        end
    end
    return shut
end

-- Doors tagged "open" stay open: anything that shuts one (the map's own logic, a
-- timer the map gave it) and it opens again.
function LC.KeepOpenThink(now)
    now = now or CurTime()
    local n = 0
    for door in pairs(LC.KeptOpen) do
        if not IsValid(door) or LC.GetDoorTag(door) ~= "open" then
            if IsValid(door) then HoldOpen(door, false) end
            LC.KeptOpen[door] = nil
        elseif Shutting(door) and now >= (door.lcKeepNext or 0) then
            door.lcKeepNext = now + 2 -- (something in the way: try again in a moment, not every tick)
            HoldOpen(door, true)
            OpenAndHold(door)
            n = n + 1
        end
    end
    return n
end

-- Map buttons: prisoners don't press them, and a unit pressing one may open the cells.
local BUTTONS = { func_button = true, func_rot_button = true, momentary_rot_button = true }
hook.Add("PlayerUse", "LivingCityPrisonButtons", function(ply, ent)
    if not IsValid(ent) or not BUTTONS[ent:GetClass()] then return end
    if LC.Prisoners and LC.Prisoners[ply] then return false end
    if LC.PlayerIsCP(ply) or (LC.IsBuilder and LC.IsBuilder(ply)) then LC.PrisonDoorsAllowUntil = CurTime() + 10 end
end)

-- Apply door tags each time Living City starts.
local wasRunning = false
timer.Create("LivingCityDoors", 0.3, 0, function()
    if LC.Running and not wasRunning then LC.ApplyAllDoors() end
    wasRunning = LC.Running
    local ok, err = pcall(DoorThink)
    if not ok then LC.Error("doors", err) end
    if LC.Running then
        ok, err = pcall(LC.PrisonDoorThink, CurTime())
        if not ok then LC.Error("prison doors", err) end
        ok, err = pcall(LC.KeepOpenThink, CurTime())
        if not ok then LC.Error("doors kept open", err) end
    end
end)

------------------------------------------------------------------------
-- Players and doors
------------------------------------------------------------------------

local nextUse = {}
hook.Add("PlayerUse", "LivingCityDoorUse", function(ply, ent)
    if not LC.IsDoorEntity(ent) then return end
    local tag = LC.EffectiveDoorTag(ent)
    if tag == "rent" and LC.RentDoorUse then
        local r = LC.RentDoorUse(ply, ent)
        if r ~= nil then return r end
    end

    if tag == "open" then return false end -- kept open
    local denied = tag == "locked" or (UnitsOnly(tag) and not LC.PlayerMayUseCPDoor(ply, ent))
    -- somebody in custody doesn't open doors, whoever they are
    if LC.Prisoners and LC.Prisoners[ply] then denied = true end
    if LC.DoorPicked and LC.DoorPicked(ent) then denied = false end -- picked or bypassed, for a little while
    if denied then
        if (nextUse[ent] or 0) < CurTime() then
            ent:EmitSound(LOCKED_SOUND, 70)
            nextUse[ent] = CurTime() + 1
        end
        return false
    end

    -- a Combine door is physically locked: a unit's (or keycard's) E unlocks it for a few seconds
    if UnitsOnly(tag) and IsLocked(ent) and not (LC.DoorPicked and LC.DoorPicked(ent)) then
        ent:Fire("Unlock")
        ent:Fire("Open", "", 0.1)
        LC.OpenedDoors[ent] = CurTime() + 5
        LC.Relock[ent] = true
        return false
    end

    -- Brush doors without "use opens" ignore E. Toggle them ourselves.
    if not cvPlayerDoors:GetBool() then return end
    local class = ent:GetClass()
    if class ~= "func_door" and class ~= "func_door_rotating" then return end
    if bit.band(ent:GetSpawnFlags(), SF_DOOR_USE_OPENS) ~= 0 then return end
    if (nextUse[ent] or 0) > CurTime() then return end
    nextUse[ent] = CurTime() + 1
    ent:Fire("Unlock")
    ent:Fire("Toggle")
    LC.OpenedDoors[ent] = nil -- a door you opened stays how you left it
end)

------------------------------------------------------------------------
-- Editor helpers: inspect and test
------------------------------------------------------------------------

function LC.DoorInfo(door)
    local lines = {}
    local id = door:MapCreationID()
    lines[#lines + 1] = string.format("%s (map id %s)", door:GetClass(), id and id >= 0 and id or "none: spawned, can't be tagged")
    lines[#lines + 1] = "Locked right now: " .. (IsLocked(door) and "yes" or "no")
    lines[#lines + 1] = "Your tag: " .. (LC.GetDoorTag(door) or "none")
    local auto = not LC.GetDoorTag(door) and LC.AutoDoorTag(door)
    if auto == "prison" then
        lines[#lines + 1] = "A prison door, automatically: it's by a cell or the release point, or in the prison area. Locked to all but units, even in a blackout (tag it to override)"
    elseif auto then
        lines[#lines + 1] = "Locked automatically: it's in a Combine-only area. Its lock goes dead in a blackout (tag it to override)"
    end
    if door:GetClass() ~= "prop_door_rotating" then
        local shape = ShapeLooksLikeDoor(door)
        lines[#lines + 1] = "NPCs treat it as a door: " .. ((shape or LC.GetDoorTag(door) == "force") and "yes" or
            "no (looks like a lift or platform; tag it 'force' if it really is a door)")
        lines[#lines + 1] = "Opens with E by itself: " .. (bit.band(door:GetSpawnFlags(), SF_DOOR_USE_OPENS) ~= 0 and "yes" or "no")
    end
    return lines
end

function LC.TestDoor(door)
    local wasLocked = IsLocked(door)
    door:Fire("Unlock")
    door:Fire("Toggle", "", 0.05)
    LC.OpenedDoors[door] = nil
    return wasLocked
end

------------------------------------------------------------------------
-- Commands
------------------------------------------------------------------------

concommand.Add("lc_unlockdoors", function(ply)
    if not LC.CanEdit(ply) then return end
    local n = 0
    for class in pairs(DOOR_CLASSES) do
        for _, door in ipairs(ents.FindByClass(class)) do
            if LC.GetDoorTag(door) ~= "locked" then
                door:Fire("Unlock")
                n = n + 1
            end
        end
    end
    Say(ply, "Unlocked " .. n .. " doors (locked-tagged doors left alone).")
end)

-- Every door in the city, open and locked open (a secret ending: nothing
-- gets stuck behind one, and nobody can shut one; sv_livingcity_endings.lua).
-- Locked-tagged ones too. The map reloads afterwards, which puts them back.
function LC.OpenEveryDoor()
    local n = 0
    for class in pairs(DOOR_CLASSES) do
        for _, door in ipairs(ents.FindByClass(class)) do
            if IsRealDoor(door) then
                door.lcHeldOpen = true
                LC.OpenedDoors[door] = nil
                LC.Relock[door] = nil
                LC.PrisonDoors[door] = nil
                LC.KeptOpen[door] = true
                HoldOpen(door, true) -- (it doesn't swing back by itself)
                OpenAndHold(door)    -- (open, then locked in the open position: E won't shut it)
                n = n + 1
            end
        end
    end
    return n
end

-- And back as they were (an ending cancelled without the reload).
function LC.ReleaseEveryDoor()
    for class in pairs(DOOR_CLASSES) do
        for _, door in ipairs(ents.FindByClass(class)) do
            if door.lcHeldOpen then
                door.lcHeldOpen = nil
                LC.KeptOpen[door] = nil
                HoldOpen(door, false)
                door:Fire("Unlock")
                LC.ApplyDoorState(door)
            end
        end
    end
end

concommand.Add("lc_opendoors", function(ply)
    if not LC.CanEdit(ply) then return end
    local n = 0
    for class in pairs(DOOR_CLASSES) do
        for _, door in ipairs(ents.FindByClass(class)) do
            if IsRealDoor(door) and LC.GetDoorTag(door) ~= "locked" then
                door:Fire("Unlock")
                door:Fire("Open")
                LC.OpenedDoors[door] = nil
                n = n + 1
            end
        end
    end
    Say(ply, "Opened " .. n .. " doors. They will stay open.")
end)

-- New cells, zones or tags change which doors lock.
hook.Add("LivingCityLayoutChanged", "LivingCityDoors", function()
    timer.Simple(0.5, function() if LC.Running then LC.ApplyAllDoors() end end)
end)
