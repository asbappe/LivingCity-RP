--[[
    Living City: doors

    Door tags (set with the Living City Editor tool, saved per map):
      cp      Civil Protection only. NPC citizens never open it; CP players and admins can.
      locked  Stays locked for everyone.
      open    Opened when the city starts and left open.
      ignore  NPCs never open it, but players use it normally (good for doors that
              lead nowhere, or that NPCs keep getting stuck in).
      force   Treat this as a door NPCs can use, even if it doesn't look like one
              (wide gates and shutters the shape check rejects).
      (none)  A normal door. Unlocked on start in Sandbox if lc_unlock_doors is 1.

    NPCs get doors opened for them two ways: any door right next to them, and any
    door standing between them and the next point on their route.
]]

if CLIENT then return end

LC = LC or {}
LC.OpenedDoors = LC.OpenedDoors or {} -- [door] = time it may auto-close
LC.Relock = LC.Relock or {}           -- [door] = true if we unlocked it for an NPC

local FLAGS = bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED)
local cvUnlock      = CreateConVar("lc_unlock_doors", "1", FLAGS, "Unlock untagged map doors when Living City starts (Sandbox only)")
local cvPlayerDoors = CreateConVar("lc_player_doors", "1", FLAGS, "Let players open brush doors with E (Sandbox only)")
local cvNPCDoors    = CreateConVar("lc_npc_doors", "1", FLAGS, "Open doors for Living City NPCs as they walk up")

local DOOR_CLASSES = { prop_door_rotating = true, func_door = true, func_door_rotating = true }
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
local function IsRealDoor(ent)
    if not LC.IsDoorEntity(ent) then return false end
    local tag = LC.GetDoorTag(ent)
    if tag == "force" then return true end
    return ShapeLooksLikeDoor(ent)
end
LC.IsRealDoor = IsRealDoor

-- Doors with no tag of your own are locked to everyone but Civil Protection when
-- they stand by a prison cell, inside the prison area, or in a Combine-only zone.
-- Tag a door (open, ignore, force, locked...) and your tag wins.
local AUTO_CELL_RADIUS = 450

function LC.AutoDoorTag(door)
    if not IsValid(door) or LC.GetDoorTag(door) or LC.IsRP() then return nil end
    if not LC.IsDoorEntity(door) then return nil end
    local pos = door:WorldSpaceCenter()
    for _, z in ipairs(LC.Zones or {}) do
        if (z.kind == "prison" or z.kind == "combine") and pos:DistToSqr(z.pos) < z.r * z.r then return "cp" end
    end
    for _, p in ipairs(LC.Points or {}) do
        if (p.kind == "cell" or p.kind == "release") and pos:DistToSqr(p.pos) < AUTO_CELL_RADIUS * AUTO_CELL_RADIUS then return "cp" end
    end
    return nil
end

local function IsLocked(door)
    return door:GetInternalVariable("m_bLocked") == true
end

------------------------------------------------------------------------
-- Applying tags to the world
------------------------------------------------------------------------

function LC.ApplyDoorState(door)
    if not IsValid(door) then return end
    local tag = LC.GetDoorTag(door)
    LC.OpenedDoors[door] = nil
    LC.Relock[door] = nil
    if tag == "locked" then
        door:Fire("Close")
        door:Fire("Lock", "", 0.1)
    elseif tag == "cp" or (not tag and LC.AutoDoorTag and LC.AutoDoorTag(door) == "cp") then
        -- Combine doors, and the ones by the cells, are physically locked, not just "denied":
        -- units and keycards open them, nothing else does
        door:Fire("Close")
        door:Fire("Lock", "", 0.1)
    elseif tag == "open" then
        door:Fire("Unlock")
        door:Fire("Open", "", 0.1)
    elseif cvUnlock:GetBool() and not LC.IsRP() then
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
    if tag == "cp" then
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
    if locked then
        LC.Relock[door] = true
        door:Fire("Unlock")
    end
    door:Fire("Open")
    LC.OpenedDoors[door] = CurTime() + 4
end

local function SomeoneNear(door)
    for _, ent in ipairs(ents.FindInSphere(door:WorldSpaceCenter(), 110)) do
        if ent:IsPlayer() or ent:IsNPC() then return true end
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

local function DoorThink()
    if not cvNPCDoors:GetBool() then return end
    local now = CurTime()

    for npc, st in pairs(LC.NPCs or {}) do
        if IsValid(npc) and (st.state == "moving" or st.state == "inspect_approach" or st.state == "escort"
            or st.state == "escorted") then
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
                if LC.Relock[door] then door:Fire("Lock", "", 1) end
                LC.OpenedDoors[door] = nil
                LC.Relock[door] = nil
            end
        end
    end
end

-- Apply door tags each time Living City starts.
local wasRunning = false
timer.Create("LivingCityDoors", 0.3, 0, function()
    if LC.Running and not wasRunning then LC.ApplyAllDoors() end
    wasRunning = LC.Running
    local ok, err = pcall(DoorThink)
    if not ok then LC.Error("doors", err) end
end)

------------------------------------------------------------------------
-- Players and doors
------------------------------------------------------------------------

local nextUse = {}
hook.Add("PlayerUse", "LivingCityDoorUse", function(ply, ent)
    if not LC.IsDoorEntity(ent) then return end
    local tag = LC.EffectiveDoorTag(ent)

    local denied = tag == "locked" or (tag == "cp" and not LC.PlayerMayUseCPDoor(ply, ent))
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
    if tag == "cp" and IsLocked(ent) and not (LC.DoorPicked and LC.DoorPicked(ent)) then
        ent:Fire("Unlock")
        ent:Fire("Open", "", 0.1)
        LC.OpenedDoors[ent] = CurTime() + 5
        LC.Relock[ent] = true
        return false
    end

    -- Brush doors without "use opens" ignore E in Sandbox. Toggle them ourselves.
    if LC.IsRP() or not cvPlayerDoors:GetBool() then return end -- RP gamemodes handle keys themselves
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
    if not LC.GetDoorTag(door) and LC.AutoDoorTag(door) then
        lines[#lines + 1] = "Locked automatically: it's by a prison cell or in a Combine-only area (tag it to override)"
    end
    if LC.DoorIsCPByGamemode(door) then lines[#lines + 1] = "Gamemode door group: Civil Protection only" end
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
