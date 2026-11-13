--[[
    Living City Editor (toolgun)
    Q menu > Tools > Living City > Living City Editor

    Left click   place / tag / select (depends on mode)
    Right click  remove what's under your aim, or clear a door tag
    Reload       next mode
    Z            undo, like any other tool

    Every change saves immediately for this map.
]]

-- Only in the Living City gamemode (it's the gamemode's editor; elsewhere it isn't listed)
if engine.ActiveGamemode() ~= "livingcity" then TOOL.AddToMenu = false return end

TOOL.Category = "Miscount"
TOOL.Name = "#tool.livingcity_editor.name"
TOOL.ClientConVar = { mode = "idle", group = "1", radius = "300", shape = "box", height = "192" }

if SERVER then util.AddNetworkString("lc_boxcorner") end
TOOL.Information = {
    { name = "left" },
    { name = "right" },
    { name = "reload" },
}

local MODES = {
    { id = "idle",        label = "Point: loiter spot (citizens)" },
    { id = "sit",         label = "Point: sit on the ground (citizens; rebels too, inside rebel territory)" },
    { id = "sitchair",    label = "Point: sit on a bench or chair (citizens; rebels too, inside rebel territory)" },
    { id = "lean",        label = "Point: lean on a wall (citizens; rebels too, inside rebel territory)" },
    { id = "queue",       label = "Point: ration line slot (line #, front first)", group = true },
    { id = "patrol",      label = "Point: patrol stop (beat #, 0 = random patrols)", group = true },
    { id = "checkpoint",  label = "Point: checkpoint post (security)" },
    { id = "spawn",       label = "Point: spawn / exit doorway" },
    { id = "cell",        label = "Point: prison cell" },
    { id = "release",     label = "Point: prison release spot" },
    { id = "prisonwork",  label = "Point: prison work spot (where a prisoner's work detail picks up trash)" },
    { id = "speech",      label = "Point: speech stand (where the City Administrator speaks to the city; face it toward the crowd)" },
    { id = "speechcrowd", label = "Point: speech crowd (where the city gathers for her address; with one placed, attendance is mandatory)" },
    { id = "zspawn",      label = "Point: infestation spawn (zombies, infested players)" },
    { id = "rspawn",      label = "Point: resistance spawn (rebel players)" },
    { id = "rlookout",    label = "Point: rebel lookout post (an armed fighter stands guard here; place it from where the Combine would come, so he faces that way)" },
    { id = "bunk",        label = "Point: bunk (a rebel sleeps here now and then; aim at the middle of the bed from its foot or head, so it lies along the bed)" },
    { id = "sspawn",      label = "Point: scanner launch spot (where flown scanners go up)" },
    { id = "platform",    label = "Point: train platform (trains stop here: new arrivals, people leaving the city)" },
    { id = "arrival",     label = "Point: arrival (where new people step into the city, before Civil Intake; place it from the way they should face, Civil Intake say)" },
    { id = "desk",        label = "Her last stand: the Administrator's desk (only if the map's own desk isn't found by itself: on the desk or beside it, within 100 feet of her power)" },
    { id = "suppressor",  label = "Fixture: the suppression device (the Nexus mortar: in BLACK it shells rebels under open sky near a Combine zone; blow it up to stop it)" },
    { id = "adminpower",  label = "Her last stand: the Administrator's power (place 2 or 3; # is its guards: 1 manhacks, 2 turrets, 3 mines; its glass screen goes on the side facing you; her shield holds till all are destroyed)", group = true },
    { id = "studio",      label = "Point: broadcast studio (the Administrator speaks here, filmed live, when no player is Director of Propaganda)" },
    { id = "jogroute",    label = "Point: jogging route stop (morning jog: place them in order round the route, the first is the start; route #)", group = true },
    { id = "yard",        label = "Point: exercise yard (morning drill: stand where the rows of citizens will be and aim at where the leader stands)" },
    { id = "parade",      label = "Point: parade route stop (morning parade: in order, the first is where the column forms up; route #)", group = true },
    { id = "sterm",       label = "Point: stalker terminal (a Combine zone's stalker works a terminal here: stand where it should stand, facing the terminal, and aim at the floor at your feet)" },
    { id = "lz",          label = "Point: Overwatch landing zone (a dropship brings soldiers down here: open sky above it)" },
    { id = "dream",       label = "Point: dream (the secret endings play here as shared dreams for everyone asleep: put it out of the map, where nobody can walk to)" },
    { id = "dock",        label = "Point: loading dock (supply drops come in here, by dropship under open sky; supply trucks, crates)" },
    { id = "graffiti",    label = "Point: graffiti wall (sanitation scrubs it; aim at the foot of the wall)" },
    { id = "rubble",      label = "Point: rubble pile (reclamation crews and work orders clear it)" },
    { id = "pipe",        label = "Point: leaky pipe (citizens' work orders patch it)" },
    { id = "vending",     label = "Fixture: water vending machine" },
    { id = "dispenser",   label = "Fixture: ration dispenser" },
    { id = "terminal",    label = "Fixture: commissary terminal" },
    { id = "cpsupply",    label = "Fixture: Civil Protection Commissary (Civil Protection units are issued grenades, ammunition, armour and rations here)" },
    { id = "conveyor",    label = "Fixture: factory conveyor (the Factory Worker's line runs parts along it)" },
    { id = "intake",      label = "Fixture: Civil Intake (registration: new people get their papers here; NPC arrivals queue in front)" },
    { id = "housingterm", label = "Fixture: Housing Allocation (registered new arrivals ask for a room here)" },
    { id = "laborterm",   label = "Fixture: Labor Assignment (citizens are given Union work here, and change jobs here; before Housing Allocation)" },
    { id = "stove",       label = "Fixture: stove" },
    { id = "bed",         label = "Fixture: bed (sleep here at night; the map's own beds work too)" },
    { id = "toilet",      label = "Fixture: toilet (for parasites; the map's own toilets work too)" },
    { id = "bath",        label = "Fixture: bathtub (a wash after soiling yourself; the map's own tubs and showers work too)" },
    { id = "fire",        label = "Fixture: burning barrel" },
    { id = "dealer",      label = "Fixture: black market dealer" },
    { id = "locker",      label = "Fixture: locker (people keep things in it)" },
    { id = "screen",      label = "Fixture: city screen (shows broadcasts)" },
    { id = "lawboard",    label = "Fixture: law board" },
    { id = "cpfeed",      label = "Fixture: Civil Protection incident feed (arrests and reports, from the chronicle)" },
    { id = "evidlocker",  label = "Fixture: evidence locker (what Civil Protection confiscates; it can be broken into)" },
    { id = "rebelboard",  label = "Fixture: Resistance notice board (what the cell has seen, from the chronicle)" },
    { id = "interrochair", label = "Fixture: Resistance interrogation chair (with its lamp)" },
    { id = "rebelcage",   label = "Fixture: Resistance holding cage (chain link; the gate faces you)" },
    { id = "infodesk",    label = "Fixture: Citizen Information desk (a clerk who answers questions; place behind a counter)" },
    { id = "civposter",   label = "Fixture: Civil notice poster (its words fit what's nearest: rations, water, the Commissary...)" },
    { id = "console",     label = "Fixture: Combine console (fly a scanner: prisoners and Civil Protection units)" },
    { id = "workbench",   label = "Fixture: Resistance lab (a scientist makes guns, ammunition, jammers and radios for the Resistance; one in every rebel base)" },
    { id = "recycler",    label = "Fixture: Union reclamation point (hand in scrap for credits)" },
    { id = "citybin",     label = "Street: bin (searchable; sanitation bin runs stop at it)" },
    { id = "streetlight", label = "Street: streetlight (lights the street; maintenance fixes it when it breaks)" },
    { id = "loudspeaker", label = "Street: loudspeaker (the PA and broadcasts; broken, nobody near it hears them)" },
    { id = "screen_big",  label = "Street: giant Breencast screen" },
    { id = "tv",          label = "Street: small TV (set it on a table)" },
    { id = "transformer", label = "Fixture: transformer (powers the district: lights, loudspeakers, screens, forcefields, Combine locks)" },
    { id = "forcefield",  label = "Fixture: Combine forcefield (place it facing you, across a doorway; Civil Protection units pass)" },
    { id = "incinerator", label = "Fixture: incinerator (the dead are hauled here; mortuary attendants)" },
    { id = "hazbarrel",   label = "Fixture: infestation control barrel (Infestation Cleanup workers empty their hoovers into it; every infestation's warning post has one too)" },
    { id = "powerbank",   label = "Fixture: Combine power bank (a checkpoint's heart: turrets and forcefields near it run off it)" },
    { id = "turret",      label = "Fixture: Combine turret (at a checkpoint, near a power bank or forcefield; facing you)" },
    { id = "barricade_low",  label = "Fixture: Combine barricade, low (facing you)" },
    { id = "barricade",      label = "Fixture: Combine barricade, medium (facing you)" },
    { id = "barricade_tall", label = "Fixture: Combine barricade, tall (facing you)" },
    { id = "dataterm",    label = "Fixture: Combine data terminal (the Resistance steal data; put it in the nexus)" },
    { id = "masterterm",  label = "Fixture: Combine master terminal (the motherlode; one, deep in the nexus)" },
    { id = "bin",         label = "Point: searchable bin (any spot: rubbish, a skip, a crate)" },
    { id = "salvage",     label = "Point: salvage pile (junk to pry apart with a crowbar)" },
    { id = "node",        label = "Path: node (links to your last node)" },
    { id = "link",        label = "Path: link / unlink two nodes" },
    { id = "ladder",      label = "Path: ladder end (give its bottom and top the same #; NPCs hop up it)", group = true },
    { id = "zone_nogo",   label = "Zone: no-go", radius = true },
    { id = "zone_rebel",  label = "Zone: rebel territory (Resistance ground: street Civil Protection units stay out)", radius = true },
    { id = "zone_block",  label = "Zone: housing block (block #)", radius = true, group = true },
    { id = "zone_prison", label = "Zone: prison area", radius = true },
    { id = "zone_combine", label = "Zone: Combine only (nexus, offices, armory)", radius = true },
    { id = "zone_infest", label = "Zone: infestation (zombies live here)", radius = true },
    { id = "zone_dream",  label = "Zone: dream (round the dream point: nothing in a dream goes past its edge)", radius = true },
    { id = "door_cp",     label = "Door: Civil Protection only (its lock dies in a blackout)" },
    { id = "door_prison", label = "Door: prison or cell (Civil Protection units only, stays locked in a blackout)" },
    { id = "door_locked", label = "Door: always locked" },
    { id = "door_open",   label = "Door: always open" },
    { id = "door_ignore", label = "Door: NPCs ignore it" },
    { id = "door_force",  label = "Door: force NPCs to treat it as a door" },
    { id = "door_rent",   label = "Door: apartment people can rent (!rent)" },
    { id = "door_office", label = "Door: the City Administrator's office (the Administrator, their guards and staff)" },
    { id = "door_test",   label = "Door: test open / close" },
    { id = "prop",        label = "Prop: make persistent (spawn a prop, place it, zap it: saved with the layout, frozen)" },
    { id = "inspect",     label = "Inspect anything" },
    { id = "walker",      label = "Test walker: send a citizen here" },
}

-- Workplaces, one per Union job (a workplace point with that job's number).
if LCJ and LCJ.Occupations then
    for _, o in ipairs(LCJ.Occupations) do
        MODES[#MODES + 1] = { id = "work_" .. o.id, kind = "work", num = o.num, label = "Workplace: " .. o.place .. " (" .. o.name .. " shifts)" }
    end
else
    table.insert(MODES, 16, { id = "work", label = "Point: workplace (job #, see the list in the panel)", group = true })
end

-- sit, bench and lean spots, and fixtures, face the person placing them
local FACE_PLACER = { rebelcage = true, adminpower = true, bed = true, toilet = true, bath = true, conveyor = true, intake = true, housingterm = true, laborterm = true, cpsupply = true, arrival = true, sit = true, sitchair = true, lean = true, vending = true, dispenser = true, terminal = true, stove = true, dealer = true, locker = true, screen = true, lawboard = true, infodesk = true, civposter = true, console = true, workbench = true, recycler = true, sspawn = true, rlookout = true, bunk = true, dataterm = true, masterterm = true, citybin = true, streetlight = true, loudspeaker = true, screen_big = true, tv = true, incinerator = true, hazbarrel = true, graffiti = true, studio = true, transformer = true, forcefield = true, powerbank = true, turret = true, barricade_low = true, barricade = true, barricade_tall = true, yard = true }

local function ModeIndex(id)
    for i, m in ipairs(MODES) do if m.id == id then return i end end
    return 1
end
local function Mode(id) return MODES[ModeIndex(id)] end

if CLIENT then
    language.Add("tool.livingcity_editor.name", "Miscount Editor")
    language.Add("tool.livingcity_editor.desc", "Build routines, paths, zones and door rules for Miscount")
    language.Add("tool.livingcity_editor.left", "Place / tag / select")
    language.Add("tool.livingcity_editor.right", "Remove what you're aiming at")
    language.Add("tool.livingcity_editor.reload", "Next mode")
end

local function Tell(ply, msg) ply:ChatPrint("[Miscount] " .. msg) end

local function CheckAccess(ply)
    if LC and LC.CanEdit and LC.CanEdit(ply) then return true end
    Tell(ply, "Only superadmins can edit the city layout.")
    return false
end

local function Undoable(ply, label, fn)
    undo.Create("Miscount: " .. label)
    undo.AddFunction(function() fn() end)
    undo.SetPlayer(ply)
    undo.Finish()
end

local function Select(ply, node)
    if SERVER then
        net.Start("lc_select")
        net.WriteUInt(node and node.id or 0, 32)
        net.Send(ply)
    end
end

-- per-player editor memory (server)
local lastNode, linkSel = {}, {}

------------------------------------------------------------------------
-- Left click
------------------------------------------------------------------------

local function PlacePoint(self, ply, trace, mode)
    if not trace.Hit or trace.HitNormal.z < 0.7 then
        Tell(ply, "Aim at the floor to place a point.")
        return false
    end
    local yaw = ply:EyeAngles().y
    if FACE_PLACER[mode.id] then yaw = yaw + 180 end
    local kind = mode.kind or mode.id
    local group = mode.num or (Mode(mode.id).group and self:GetClientNumber("group", 1)) or 0
    local p = LC.AddPoint(trace.HitPos, yaw, kind, group)
    if not p then return false end
    Undoable(ply, kind .. " point", function() LC.RemovePoint(p) end)
    local extra = ""
    if mode.id == "queue" then
        extra = group > 0 and string.format(" Line %d now has %d slot(s).", group, #LC.PointsOfKind("queue", group))
            or " (Line 0 is a loose standing spot, not a line.)"
    elseif mode.id == "patrol" and group > 0 then
        extra = string.format(" Beat %d now has %d stop(s).", group, #LC.PointsOfKind("patrol", group))
    elseif mode.id == "jogroute" or mode.id == "parade" then
        local n = #LC.PointsOfKind(mode.id, group)
        extra = string.format(" %s route %d now has %d stop(s)%s.", mode.id == "jogroute" and "Jogging" or "Parade", group, n,
            n < 2 and " (it needs at least two)" or "")
    elseif mode.id == "yard" then
        extra = " The rows form up in front of it, facing it."
    end
    Tell(ply, "Placed " .. (mode.num and (string.gsub(mode.label, "^Workplace: ", "") .. " workplace") or (mode.id .. " point")) .. "." .. extra)
    return true
end

local function PlaceNode(ply, trace)
    if not trace.Hit or trace.HitNormal.z < 0.7 then
        Tell(ply, "Aim at the floor to place a path node.")
        return false
    end
    local existing = LC.NearestNode(trace.HitPos, 40)
    if existing then
        lastNode[ply] = existing
        Select(ply, existing)
        Tell(ply, "Continuing the path from node " .. existing.id .. ".")
        return true
    end
    local n = LC.AddNode(trace.HitPos)
    local prev = lastNode[ply]
    local linkedTo
    if prev and LC.Nodes[prev.id] == prev and prev.pos:DistToSqr(n.pos) < 1200 * 1200 then
        LC.ToggleLink(prev, n)
        linkedTo = prev
        if not LC.Walkable(prev.pos, n.pos) then
            Tell(ply, "Linked, but something blocks the straight line between these two (a wall, railing or stairs). " ..
                "NPCs may still manage; run a test walker to be sure.")
        end
    end
    lastNode[ply] = n
    Select(ply, n)
    Undoable(ply, "path node", function() LC.RemoveNode(n) end)
    Tell(ply, "Node " .. n.id .. (linkedTo and (" linked to " .. linkedTo.id .. ".") or " placed. Place the next one to link them."))
    return true
end

local function LinkClick(ply, trace)
    local n = LC.NearestNode(trace.HitPos, 64)
    if not n then
        Tell(ply, "Aim at a path node.")
        return false
    end
    local a = linkSel[ply]
    if not a or LC.Nodes[a.id] ~= a or a == n then
        linkSel[ply] = n
        Select(ply, n)
        Tell(ply, "Selected node " .. n.id .. ". Click another node to link or unlink them.")
        return true
    end
    local linked = LC.ToggleLink(a, n)
    Undoable(ply, "link", function() if LC.Nodes[a.id] and LC.Nodes[n.id] then LC.ToggleLink(a, n) end end)
    Tell(ply, string.format("Nodes %d and %d %s.", a.id, n.id, linked and "linked" or "unlinked"))
    if linked and not LC.Walkable(a.pos, n.pos) then Tell(ply, "Heads up: something blocks the straight line between them.") end
    linkSel[ply] = n
    Select(ply, n)
    return true
end

-- Box zones take two clicks: one corner, then the opposite one.
local boxCorner = {} -- [ply] = { pos, kind }

local function SendCorner(ply, pos)
    net.Start("lc_boxcorner")
    net.WriteBool(pos ~= nil)
    if pos then net.WriteVector(pos) end
    net.Send(ply)
end

local function PlaceZone(self, ply, trace, mode)
    if not trace.Hit then return false end
    local kind = string.sub(mode.id, 6)
    local group = mode.group and math.max(1, self:GetClientNumber("group", 1)) or 0
    local where = kind == "block" and (" " .. LC.BlockName(group) .. ".") or ""
    if self:GetClientInfo("shape") == "box" then
        local c = boxCorner[ply]
        if not c or c.kind ~= kind then
            boxCorner[ply] = { pos = trace.HitPos, kind = kind }
            SendCorner(ply, trace.HitPos)
            Tell(ply, "First corner set. Click the opposite corner of the room or area. (Right click cancels.)")
            return true
        end
        boxCorner[ply] = nil
        SendCorner(ply, nil)
        local box = LCZ.BoxFromCorners(c.pos, trace.HitPos, self:GetClientNumber("height", 192))
        local sx, sy = box.maxs.x - box.mins.x, box.maxs.y - box.mins.y
        if sx < 32 or sy < 32 then Tell(ply, "That box is too thin. Start again: click one corner, then the opposite one.") return false end
        local z = LC.AddZone(nil, nil, kind, group, box)
        if not z then return false end
        Undoable(ply, kind .. " zone", function() LC.RemoveZone(z) end)
        Tell(ply, string.format("Placed %s zone, a box %d by %d, %d tall.%s", kind, sx, sy, box.maxs.z - box.mins.z, where))
        return true
    end
    local r = math.Clamp(self:GetClientNumber("radius", 300), 32, 4000)
    local z = LC.AddZone(trace.HitPos, r, kind, group)
    if not z then return false end
    Undoable(ply, kind .. " zone", function() LC.RemoveZone(z) end)
    Tell(ply, string.format("Placed %s zone, radius %d.%s", kind, r, where))
    return true
end

local function TagDoor(ply, trace, mode)
    local door = trace.Entity
    if not LC.IsDoorEntity(door) then
        Tell(ply, "Aim at a door.")
        return false
    end
    local tag = string.sub(mode.id, 6)
    local ok, old = LC.SetDoorTag(door, tag)
    if not ok then
        Tell(ply, "That door was spawned in, not part of the map, so it can't be saved.")
        return false
    end
    Undoable(ply, "door tag", function() if IsValid(door) then LC.SetDoorTag(door, old) end end)
    Tell(ply, "Door set to: " .. mode.label)
    return true
end

local function Inspect(ply, trace)
    local ent = trace.Entity
    if LC.IsDoorEntity(ent) then
        for _, l in ipairs(LC.DoorInfo(ent)) do Tell(ply, l) end
        return true
    end
    if IsValid(ent) and ent.lcPersistId then
        Tell(ply, string.format("Persistent prop #%d: %s, saved with the layout.", ent.lcPersistId, ent:GetModel() or "?"))
        return true
    end
    local st = IsValid(ent) and LC.NPCs[ent]
    if st then
        Tell(ply, string.format("%s, state %s, hp %d", st.role, tostring(st.state), ent:Health()))
        Tell(ply, string.format("route hop %s of %s, recoveries %d, errors %d%s%s%s",
            tostring(st.hop or "-"), tostring(st.route and #st.route or "-"), st.recoveries or 0, st.errors or 0,
            st.routeGroup and (", beat " .. st.routeGroup) or "", st.line and (", line " .. st.line) or "",
            st.claim and (", using a " .. st.claim.kind .. " point") or ""))
        return true
    end
    if IsValid(ent) and ent:IsPlayer() then
        Tell(ply, string.format("%s | %s | block %s | CP %s | wanted %s%s", ent:Nick(), ent:GetNW2String("lcf_title", "-"),
            tostring(LC.PlayerBlock(ent) or "-"), tostring(LC.PlayerIsCP(ent)), tostring(LC.PlayerIsWanted(ent)),
            LC.ConductSummary and (" | " .. LC.ConductSummary(ent)) or ""))
        return true
    end
    local p = LC.NearestPoint(trace.HitPos, 64)
    if p then
        Tell(ply, string.format("%s point, group %d, facing %d", p.kind, p.group or 0, math.floor(p.yaw or 0)))
        return true
    end
    local n = LC.NearestNode(trace.HitPos, 64)
    if n then
        Tell(ply, string.format("Path node %d with %d link(s).", n.id, table.Count(n.links)))
        return true
    end
    local z = LC.ZoneAt(trace.HitPos)
    if z then
        Tell(ply, string.format("%s zone, %s%s", z.kind,
            z.cells and string.format("grown along the path nodes: %d cells in %d rectangles, 8 feet tall", z.n or 0, #(z.rects or {}))
            or z.box and string.format("a box %d by %d", z.box.maxs.x - z.box.mins.x, z.box.maxs.y - z.box.mins.y) or ("radius " .. z.r),
            (z.group or 0) > 0 and (", #" .. z.group) or ""))
        return true
    end
    local route = LC.BuildRoute and LC.BuildRoute(ply:GetPos(), trace.HitPos, "citizen")
    Tell(ply, route == false and "Nothing here. A citizen couldn't walk here from where you are (not connected in the map's navigation)."
        or route and string.format("Nothing here. A citizen would get here from you in %d legs.", #route)
        or "Nothing here. A citizen would walk here using the map's own navigation.")
    return true
end

function TOOL:LeftClick(trace)
    if CLIENT then return true end
    local ply = self:GetOwner()
    if not CheckAccess(ply) then return false end
    local mode = Mode(self:GetClientInfo("mode"))
    local id = mode.id

    if LC.POINT_KINDS[mode.kind or id] then return PlacePoint(self, ply, trace, mode) end
    if id == "node" then return PlaceNode(ply, trace) end
    if id == "link" then return LinkClick(ply, trace) end
    if string.StartWith(id, "zone_") then return PlaceZone(self, ply, trace, mode) end
    if id == "door_test" then
        if not LC.IsDoorEntity(trace.Entity) then Tell(ply, "Aim at a door.") return false end
        Tell(ply, LC.TestDoor(trace.Entity) and "Door was locked; unlocked it and toggled." or "Toggled.")
        return true
    end
    if string.StartWith(id, "door_") then return TagDoor(ply, trace, mode) end
    if id == "inspect" then return Inspect(ply, trace) end
    if id == "prop" then
        local e = trace.Entity
        local ok, what = LC.PersistProp(ply, e)
        if not ok then Tell(ply, what) return false end
        if what == "new" then
            Undoable(ply, "persistent prop", function() if IsValid(e) and e.lcPersistId then LC.UnpersistProp(e, true) end end)
            Tell(ply, "Persistent: frozen, and saved with the layout. It's here every time the map loads. (Right click: not any more.)")
        else
            Tell(ply, "Saved as it is now.")
        end
        return true
    end
    if id == "walker" then
        if not trace.Hit or trace.HitNormal.z < 0.7 then Tell(ply, "Aim at the floor where the walker should go.") return false end
        return LC.SpawnTestWalker(ply, trace.HitPos)
    end
    return false
end

------------------------------------------------------------------------
-- Right click
------------------------------------------------------------------------

function TOOL:RightClick(trace)
    if SERVER and boxCorner[self:GetOwner()] then
        boxCorner[self:GetOwner()] = nil
        SendCorner(self:GetOwner(), nil)
        Tell(self:GetOwner(), "Box cancelled.")
        return true
    end
    if CLIENT then return true end
    local ply = self:GetOwner()
    if not CheckAccess(ply) then return false end
    local id = self:GetClientInfo("mode")

    if id == "link" then
        linkSel[ply] = nil
        Select(ply, nil)
        Tell(ply, "Selection cleared.")
        return true
    end

    local ent = trace.Entity
    if id == "prop" then
        if not (IsValid(ent) and ent.lcPersistId) then Tell(ply, "That isn't a persistent prop.") return false end
        LC.UnpersistProp(ent, true)
        Undoable(ply, "not persistent", function() if IsValid(ent) then LC.PersistProp(ply, ent) end end)
        Tell(ply, "No longer persistent: it stays until the map changes (the remover takes it away now).")
        return true
    end
    if LC.IsDoorEntity(ent) then
        if id == "door_test" or id == "inspect" then
            for _, l in ipairs(LC.DoorInfo(ent)) do Tell(ply, l) end
            return true
        end
        local old = LC.GetDoorTag(ent)
        if old then
            LC.SetDoorTag(ent, nil)
            Undoable(ply, "door tag", function() if IsValid(ent) then LC.SetDoorTag(ent, old) end end)
            Tell(ply, "Door tag cleared.")
            return true
        end
    end

    local pos = trace.HitPos
    local function RemoveNode()
        local n = LC.NearestNode(pos, 64)
        if not n then return false end
        local links = table.GetKeys(n.links)
        LC.RemoveNode(n)
        if lastNode[ply] == n then lastNode[ply] = nil; Select(ply, nil) end
        Undoable(ply, "remove node", function()
            if LC.Nodes[n.id] then return end
            n.links = {}
            LC.Nodes[n.id] = n
            for _, other in ipairs(links) do
                local o = LC.Nodes[other]
                if o then n.links[other] = true; o.links[n.id] = true end
            end
            LC.SaveData()
        end)
        Tell(ply, "Removed path node " .. n.id .. ".")
        return true
    end
    local function RemovePoint()
        local p = LC.NearestPoint(pos, 64)
        if not p then return false end
        LC.RemovePoint(p)
        Undoable(ply, "remove point", function() LC.Points[#LC.Points + 1] = p; LC.SaveData() end)
        Tell(ply, "Removed " .. p.kind .. " point.")
        return true
    end
    local function RemoveZone()
        local z = LC.ZoneForEditing(pos)
        if not z then return false end
        LC.RemoveZone(z)
        Undoable(ply, "remove zone", function() LC.Zones[#LC.Zones + 1] = z; LC.SaveData() end)
        Tell(ply, "Removed " .. z.kind .. " zone.")
        return true
    end

    if id == "walker" then
        for npc, st in pairs(LC.NPCs) do if st.test and st.owner == ply and IsValid(npc) then npc:Remove() end end
        Tell(ply, "Removed your test walkers.")
        return true
    end

    local order
    if string.StartWith(id, "zone_") then order = { RemoveZone, RemovePoint, RemoveNode }
    elseif id == "node" then order = { RemoveNode, RemovePoint, RemoveZone }
    else order = { RemovePoint, RemoveNode, RemoveZone } end
    for _, fn in ipairs(order) do if fn() then return true end end
    Tell(ply, "Nothing to remove there.")
    return false
end

function TOOL:Reload()
    if CLIENT then return false end
    local ply = self:GetOwner()
    local nextMode = MODES[ModeIndex(self:GetClientInfo("mode")) % #MODES + 1]
    ply:ConCommand("livingcity_editor_mode " .. nextMode.id)
    Tell(ply, "Mode: " .. nextMode.label)
    return false
end

function TOOL:Holster()
    if SERVER then Select(self:GetOwner(), nil) end
end

------------------------------------------------------------------------
-- HUD and control panel
------------------------------------------------------------------------

if CLIENT then
    function TOOL:DrawHUD()
        local mode = Mode(self:GetClientInfo("mode"))
        local extra = {}
        if mode.group then extra[#extra + 1] = "#" .. self:GetClientNumber("group", 1) end
        if mode.radius then
            if self:GetClientInfo("shape") == "box" then
                extra[#extra + 1] = (LC_CL and LC_CL.boxCorner) and "box: click the opposite corner" or "box: click one corner"
                extra[#extra + 1] = "height " .. self:GetClientNumber("height", 192)
            else
                extra[#extra + 1] = "radius " .. self:GetClientNumber("radius", 300)
            end
        end
        local text = mode.label .. (#extra > 0 and ("   [" .. table.concat(extra, ", ") .. "]") or "")
        draw.SimpleTextOutlined(text, "DermaLarge", ScrW() / 2, ScrH() - 140, color_white,
            TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 2, color_black)
        draw.SimpleTextOutlined("Every change saves straight away to data/livingcity/" .. game.GetMap() .. ".json   |   lc_backups lists backups",
            "DermaDefault", ScrW() / 2, ScrH() - 112, Color(200, 200, 200), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, color_black)
        -- zone modes: the shaded preview of the new zone is drawn by the overlay (cl_livingcity.lua)
    end
end

-- The city's settings live on the server: on a hosted server your game can't
-- change them itself, so the panel's checkboxes and sliders ask the server to
-- (admins only), and show what the server has. (Your own display settings,
-- lc_show and the like, stay yours.)
local MINE = { lc_zone_fill = true, lc_show = true, lc_show_npcs = true, lc_show_all_npcs = true, lc_editor_markers = true, lc_editor_xray = true, lc_editor_arrange = true }
local bound = {} -- [convar] = { control, kind }

if CLIENT then
    net.Receive("lc_settings", function()
        local t = net.ReadTable() or {}
        for name, v in pairs(t) do
            local b = bound[name]
            if b and IsValid(b[1]) then
                b[1].lcQuiet = true
                if b[2] == "check" then b[1]:SetChecked(tonumber(v) ~= nil and tonumber(v) ~= 0) else b[1]:SetValue(tonumber(v) or 0) end
                b[1].lcQuiet = nil
            end
        end
    end)
end

local function SendSetting(name, value)
    net.Start("lc_setting")
    net.WriteString(name)
    net.WriteString(tostring(value))
    net.SendToServer()
end

function TOOL.BuildCPanel(panel)
    local function Header(text)
        local l = panel:Help(text)
        if IsValid(l) then l:SetFont("DermaDefaultBold") end
    end
    local wanted = {}
    local function Check(label, name)
        if MINE[name] then return panel:CheckBox(label, name) end
        local c = panel:CheckBox(label)
        bound[name] = { c, "check" }
        wanted[#wanted + 1] = name
        c.OnChange = function(self, v) if not self.lcQuiet then SendSetting(name, v and 1 or 0) end end
        return c
    end
    local function Slider(label, name, lo, hi, dec)
        local sl = panel:NumSlider(label, nil, lo, hi, dec)
        bound[name] = { sl, "slider" }
        wanted[#wanted + 1] = name
        sl.OnValueChanged = function(self, v)
            if self.lcQuiet then return end
            -- (only once you stop dragging it)
            timer.Create("lc_setting_" .. name, 0.4, 1, function() SendSetting(name, math.Round(v, dec or 0)) end)
        end
        return sl
    end
    -- what the server has, for every one of them, once the panel's built
    timer.Simple(0, function()
        if #wanted == 0 then return end
        net.Start("lc_settings_get")
        net.WriteTable(wanted)
        net.SendToServer()
    end)

    panel:Help("Build the city. Every click saves for this map. Z undoes.")

    if LC_CL and LC_CL.BuildLayoutBrowser then
        LC_CL.BuildLayoutBrowser(panel, MODES)
    else
        local combo = panel:ComboBox("Mode")
        for _, m in ipairs(MODES) do combo:AddChoice(m.label, m.id) end
        local cur = GetConVar("livingcity_editor_mode")
        combo:SetValue(Mode(cur and cur:GetString() or "idle").label)
        combo.OnSelect = function(_, _, _, id) RunConsoleCommand("livingcity_editor_mode", id) end
    end

    local groupSl = panel:NumSlider("Line / beat / block number", "livingcity_editor_group", 0, 32, 0)
    -- (the owner, 1 November: hard to remember which numbers are taken) a tick under each number already used by
    -- a zone, in that kind of zone's colour (a number only groups zones of one kind: a rebel 30 and an
    -- infestation 30 are separate)
    if IsValid(groupSl) and IsValid(groupSl.Slider) then
        local base = groupSl.Slider.Paint
        groupSl.Slider.Paint = function(self, w, h)
            if base then base(self, w, h) end
            local used = {}
            for _, z in ipairs(LC_CL and LC_CL.zones or {}) do
                local g = tonumber(z.group) or 0
                if g > 0 and g <= 32 then used[g] = used[g] or {} used[g][z.kind] = true end
            end
            for g, kinds in pairs(used) do
                local x = math.floor(g / 32 * (w - 14) + 7)
                local row = 0
                for kind in pairs(kinds) do
                    local col = (LC_CL.ZONE_COLORS and LC_CL.ZONE_COLORS[kind]) or Color(255, 255, 255)
                    surface.SetDrawColor(col.r, col.g, col.b, 255)
                    surface.DrawRect(x - 1, h - 4 - row * 4, 3, 3)
                    row = row + 1
                end
            end
        end
    end
    panel:Help("Coloured ticks under the number: numbers already used, by zone kind (its colour). A number only groups zones of the same kind.")
    local shape = panel:ComboBox("Zone shape")
    shape:AddChoice("Box: click two opposite corners (fits rooms)", "box")
    shape:AddChoice("Circle: one click, at the radius below", "circle")
    local scv = GetConVar("livingcity_editor_shape")
    shape:SetValue((scv and scv:GetString() == "circle") and "Circle: one click, at the radius below" or "Box: click two opposite corners (fits rooms)")
    shape.OnSelect = function(_, _, _, v) RunConsoleCommand("livingcity_editor_shape", v) end
    panel:NumSlider("Box zone height", "livingcity_editor_height", 64, 1024, 0)
    panel:NumSlider("Circle zone radius", "livingcity_editor_radius", 32, 2000, 0)
    panel:Help("Every zone has about eight feet of leeway at its edge (lc_zone_mercy): your block, the prison and rebel ground reach a little past the line, Combine-only zones start a little inside it.")
    panel:Help("Lines and beats: place slots/stops in order, front first. Sit, bench and lean spots: aim at the foot of the wall; they'll face you.")
    panel:Help("Workplaces: every Union job has its own line under Workplaces. Put one (or a few) where that job is done: shifts happen there. Without any, shifts happen out on the streets.")

    panel:CheckBox("Shade zones on the ground", "lc_zone_fill")
    panel:CheckBox("Show the editor's markers (untick to hide them all)", "lc_editor_markers")
    panel:CheckBox("See markers through walls (untick: only what's in sight)", "lc_editor_xray")
    panel:Help("Aim at a zone to highlight it and see its radius. Aim at its center marker to pick it out of overlapping zones.")

    Header("Saving")
    panel:Help("Every change saves straight away to garrysmod/data/livingcity/<map>.json, and older versions are backed up automatically every few minutes.")
    panel:Button("Back up the layout now", "lc_backup")
    panel:Button("List backups (restore with lc_restore <number>)", "lc_backups")

    Header("Secret endings")
    panel:Button("Endings menu: tune them live (superadmin)", "lc_endings_menu")
    panel:Help("Pick an ending, play it, and tune its dances bone by bone and all its settings while it plays.")


    Header("City")
    panel:Button("Job outfits (who wears what)", "lc_outfits_edit")
    panel:Button("Start the city", "lc_start")
    panel:Button("Stop and clear NPCs", "lc_stop")
    panel:Button("Calm security", "lc_calm")
    Check("Start automatically on map load", "lc_autostart")

    Header("Population")
    Slider("Citizens", "lc_citizens", 0, 80, 0)
    Slider("Civil Protection", "lc_cops", 0, 30, 0)
    Slider("Overwatch soldiers", "lc_soldiers", 0, 20, 0)
    Slider("Scanners", "lc_scanners", 0, 10, 0)
    Slider("Zombies (infestation zones)", "lc_zombies", 0, 40, 0)
    Slider("Resistance fighters (rebel zones)", "lc_rebels", 0, 20, 0)
    Check("Rebel raids and Combine sweeps, now and then", "lc_skirmishes")
    Slider("Minutes between skirmishes", "lc_skirmish_interval", 2, 60, 0)
    Check("Rebel and infestation zones spread when left alone", "lc_territory_spread")
    Slider("Minutes between rebel growth", "lc_rebel_spread_minutes", 2, 120, 0)
    Slider("Minutes between infestation growth", "lc_infest_spread_minutes", 2, 120, 0)
    Slider("Most patches a zone can grow", "lc_territory_max", 0, 20, 0)
    Slider("Kills to push back a patch", "lc_territory_hits", 1, 10, 0)
    Slider("NPC budget (for a 32-slot server: 1.75 times at 64 slots, 2.5 times at 120, at most 250)", "lc_npc_budget", 10, 200, 0)
    Check("NPCs far from everyone sleep (engine AI off until someone comes near)", "lc_npc_sleep")
    Check("The city's minds: how the named people feel, written down in data/livingcity/minds/", "lc_minds")
    Check("The minds act: choices bend with mood, and a break happens in the street", "lc_minds_act")
    Slider("Unrest among the minds from which sociostability goes yellow (0: never)", "lc_minds_unrest", 0, 1, 2)
    Check("Talking to a named person says how they seem and why (the city's minds)", "lc_minds_show")
    Check("Citizens fond of a drink and a smoke light up or take out a bottle now and then", "lc_npc_vices")
    Header("The director and free talk (a hosted model: needs a key, and costs a little per request)")
    panel:Help("Paste the key here and press Save. It is kept on the server (data/livingcity/brain_key.txt) and never shown again. Save with the box empty to clear it. What players say to a named person is sent to the service with their character's name.")
    local keyBox = panel:TextEntry("Key")
    local saveKey = panel:Button("Save the key")
    saveKey.DoClick = function()
        net.Start("lc_brain_key")
        net.WriteString(IsValid(keyBox) and keyBox:GetValue() or "")
        net.SendToServer()
        if IsValid(keyBox) then keyBox:SetValue("") end
    end
    local testKey = panel:Button("Test the connection")
    testKey.DoClick = function()
        net.Start("lc_brain_test")
        net.SendToServer()
    end
    Check("The director and free talk are on (nothing happens without a key)", "lc_brain")
    Check("Free talk: say something in character while looking at a named person and they answer", "lc_brain_talk")
    Slider("The director: 0 off, 1 only writes down what it would do, 2 does it", "lc_director", 0, 2, 0)
    Slider("Minutes between the director's looks at the city", "lc_director_minutes", 1, 30, 0)
    Check("With no player as the City Administrator, the model sits in her office (events, rations, prices, a job bonus, commend, censure, pardon)", "lc_brain_admin")
    Slider("Minutes between her looks at the city", "lc_brain_admin_minutes", 2, 60, 0)
    Slider("Most requests to the hosted model in a day (0: no limit)", "lc_brain_daily", 0, 10000, 0)
    Header("Her voice: the city's own Administrator's decrees, spoken (ElevenLabs; off until you turn it on)")
    panel:Help("Paste the ElevenLabs key and the voice id (shown beside the voice in ElevenLabs' voice list) and press Save. A box left empty keeps what is saved. Both are kept on the server (data/livingcity/) and never shown again. Each spoken sentence costs a little.")
    local voiceKey = panel:TextEntry("Voice key")
    local voiceId = panel:TextEntry("Voice id")
    local function SendVoice(clear)
        net.Start("lc_voice_key")
        net.WriteString(IsValid(voiceKey) and voiceKey:GetValue() or "")
        net.WriteString(IsValid(voiceId) and voiceId:GetValue() or "")
        net.WriteBool(clear)
        net.SendToServer()
        if IsValid(voiceKey) then voiceKey:SetValue("") end
        if IsValid(voiceId) then voiceId:SetValue("") end
    end
    panel:Button("Save the voice key and id").DoClick = function() SendVoice(false) end
    panel:Button("Test her voice (you alone hear it)").DoClick = function()
        net.Start("lc_voice_test")
        net.SendToServer()
    end
    panel:Button("Clear the voice key and id").DoClick = function() SendVoice(true) end
    Check("Her decrees are spoken in her voice (needs the key and the voice id)", "lc_voice")
    Slider("Most spoken lines in a day (0: no limit)", "lc_voice_daily", 0, 2000, 0)
    Slider("Civil Protection size (1 = HL2's own)", "lc_cp_scale", 0.8, 1.3, 2)
    Slider("Overwatch soldier size (1 = HL2's own)", "lc_soldier_scale", 0.8, 1.3, 2)
    Slider("Civil Protection health (HL2's own: 40)", "lc_cp_health", 10, 300, 0)
    Slider("Overwatch soldier health (HL2's own: 50)", "lc_soldier_health", 10, 300, 0)
    Slider("Overwatch Elite health", "lc_elite_health", 10, 400, 0)
    Check("Outnumbered Combine fight dirtier (SMGs, grenades, energy balls, a little more damage)", "lc_desperation")
    Slider("Resistance fighter health (HL2's own: 40)", "lc_rebel_health", 10, 300, 0)
    Slider("Resistance fighters for each Combine NPC on the streets (at least)", "lc_rebel_per_combine", 0, 3, 2)
    Slider("Sympathy a citizen needs to join the Resistance (0: anyone)", "lc_resistance_join_sympathy", 0, 20, 0)
    panel:Help("Every setting in this panel is saved with this map's layout as you change it, and comes back after a restart.")

    Header("Desperate Combine: test it")
    panel:Help("Try each level alone: it's pinned for you for 30 minutes (no creeping up), and the Combine's grenades and energy balls go after you whatever your side. Pick a level, then send a squad at you. The city must be running.")
    local DESP = {
        { 0, "0%: by the book", "Combine hold their own (under 1.5 Resistance players per Combine player, or under 4 Resistance). Pistols, no grenades, Elites 2 energy balls, normal damage." },
        { 20, "20%: outnumbered 2 to 1", "e.g. 10 Resistance, 5 Combine. 1 in 5 metrocops with SMGs, a soldier throws about every 38 s, Elites 2 balls (an extra every 26 s), +2% damage." },
        { 40, "40%: 2.5 to 1", "e.g. 10 Resistance, 4 Combine. 2 in 5 SMGs, a grenade every 32 s, Elites 3 balls (extra every 21 s), +4%." },
        { 60, "60%: 3 to 1", "e.g. 15 Resistance, 5 Combine. 3 in 5 SMGs, a grenade every 25 s, Elites 3 balls (extra every 17 s), +6%." },
        { 80, "80%: 3.5 to 1", "e.g. 14 Resistance, 4 Combine. 4 in 5 SMGs, a grenade every 19 s, Elites 4 balls (extra every 12 s), +8%." },
        { 100, "100%: 4 to 1 or worse", "e.g. 20 Resistance, 5 Combine, or 4 Resistance and no Combine players. All SMGs, a grenade every 12 s, Elites 4 balls (extra every 8 s), +10%." },
    }
    for _, d in ipairs(DESP) do
        panel:Button(d[2], "lc_desperation_test", tostring(d[1]))
        panel:Help(d[3])
    end
    panel:Button("Send 4 soldiers at me (grenades)", "lc_desperation_squad", "soldiers")
    panel:Button("Send an Elite and 3 soldiers at me (energy balls)", "lc_desperation_squad", "elite")
    panel:Button("Send 3 armed metrocops at me (SMGs)", "lc_desperation_squad", "cops")
    panel:Button("Back to normal (real player counts, test units gone)", "lc_desperation_test", "off")
    panel:Help("Grenades are thrown at you from 250 to 1100 units away, when they can see you; Elites fire from 300 to 1600. Test units leave after 5 minutes.")

    Header("The collapse (sociostability BLACK) and the Administrator's last stand")
    Check("Long red can collapse the city to BLACK (the G-Man, her choice, her last stand)", "lc_black")
    Slider("Minutes of red before the collapse", "lc_black_minutes", 5, 180, 0)
    Slider("Players online before it can happen", "lc_black_min_players", 1, 32, 0)
    Slider("Minutes she has to answer the G-Man", "lc_black_answer_minutes", 1, 20, 0)
    Slider("Minutes between his steps after she refuses", "lc_black_phase_minutes", 1, 20, 0)
    Slider("Minutes her last stand lasts", "lc_black_stand_minutes", 5, 60, 0)
    Slider("Elites guarding her", "lc_black_elites", 0, 12, 0)
    Slider("Resistance fighters storming her office", "lc_black_rebels", 0, 24, 0)
    Slider("Her health", "lc_black_admin_health", 100, 3000, 0)
    Slider("Each transformer's health (her shield holds till all are destroyed)", "lc_black_power_health", 200, 10000, 0)
    Slider("Manhacks guarding transformer #1, with 1 or 2 Resistance players", "lc_black_manhacks", 0, 40, 0)
    Slider("Manhacks with 20 or more Resistance players", "lc_black_manhacks_max", 0, 150, 0)
    Slider("Floor turrets guarding transformer #2, with 1 or 2 Resistance players", "lc_black_turrets", 0, 20, 0)
    Slider("Floor turrets with 20 or more Resistance players", "lc_black_turrets_max", 0, 40, 0)
    Slider("Shield panels falling round her office (carry one, ram turrets with it)", "lc_black_panels", 0, 12, 0)
    Slider("Hopper mines guarding transformer #3", "lc_black_mines", 0, 12, 0)
    Slider("Rollermines guarding transformer #3", "lc_black_rollermines", 0, 10, 0)
    Slider("Gravity guns left near transformer #3", "lc_black_gravguns", 0, 6, 0)
    Slider("Seconds between Overwatch squads, 1 or 2 Resistance players attacking her", "lc_black_squad_gap_few", 10, 300, 0)
    Slider("Seconds between Overwatch squads, 20 or more attacking her", "lc_black_squad_gap_many", 5, 120, 0)
    Slider("Soldiers in each squad (an Elite leading)", "lc_black_squad_size", 0, 10, 0)
    Slider("How far her shield reaches from it (16 units a foot)", "lc_black_power_range", 400, 4000, 0)
    Slider("Credits for those there when she falls", "lc_black_reward", 0, 2000, 0)
    Check("In BLACK, the suppression device shells rebels under open sky near a Combine zone", "lc_black_suppressor")
    Slider("Its shell's damage", "lc_black_suppressor_damage", 0, 500, 0)
    Slider("Its shell's blast radius", "lc_black_suppressor_radius", 50, 600, 0)
    Slider("Seconds the ring glows before it lands", "lc_black_suppressor_warn", 1, 8, 1)
    Slider("Seconds between shells", "lc_black_suppressor_gap", 1, 60, 0)
    Slider("How far from a Combine zone it reaches (16 units a foot)", "lc_black_suppressor_range", 1000, 32000, 0)
    Slider("The device's health (blown up, the shelling stops)", "lc_black_suppressor_health", 100, 5000, 0)
    Check("Heroes: Barney, then Gordon Freeman, played by players of the rebellion", "lc_black_heroes")
    Slider("Minutes into her stand before Barney comes", "lc_black_barney_minutes", 0, 30, 0)
    Slider("Minutes after Barney before Freeman comes", "lc_black_freeman_minutes", 0, 30, 0)
    Slider("Unit kills that make a player the first pick for a hero", "lc_black_hero_kills", 0, 20, 0)
    Check("A minute after she falls, start the map over (a fresh city)", "lc_black_reset_map")
    panel:Help("Place 2 or 3 \"Her last stand: the Administrator's power\" (Combine transformers) round her office, each with its number (1 manhacks, 2 turrets, 3 mines) and facing the way attackers come in: its glass screen goes on the side facing you. Her desk within 100 feet of them is found by itself (any model with \"desk\" in its name, even the map's static props). Not found: place \"Her last stand: the Administrator's desk\" on the desk or beside it. Her shield deflects every bullet while any transformer stands; destroy them all and she can be killed. Overwatch squads, each led by an Elite, come in every 100 seconds with 1 or 2 Resistance players attacking her, every 15 with 20; manhacks (8 to 100) and turrets (4 to 25) scale the same way. No transformer placed: the G-Man brings one beside her desk point (else her office door, the broadcast studio, a Combine zone).")
    panel:Button("Test: collapse to BLACK now (the G-Man comes to the Administrator)", "lc_collapse_test", "black")
    panel:Button("Test: the G-Man's next step now (crates, waking armed, the grid failing, the stand)", "lc_collapse_test", "next")
    panel:Button("Test: her last stand now", "lc_collapse_test", "stand")
    panel:Button("Test: Barney now (picked from the rebellion)", "lc_collapse_test", "barney")
    panel:Button("Test: Freeman now (picked from the rebellion)", "lc_collapse_test", "freeman")
    panel:Button("Test: make me Barney", "lc_collapse_test", "mebarney")
    panel:Button("Test: make me Freeman", "lc_collapse_test", "mefreeman")
    panel:Button("Test: the city halfway to collapse (see it on screen)", "lc_collapse_test", "chaos")
    panel:Button("Back to normal (end it, chaos cleared)", "lc_collapse_test", "off")

    Header("Events")
    panel:Button("Ration distribution", "lc_event", "rations")
    panel:Button("Inspection sweep", "lc_event", "sweep")
    panel:Button("Curfew", "lc_event", "curfew")
    panel:Button("Lockdown", "lc_event", "lockdown")
    panel:Button("Morning exercise: the jog", "lc_exercise", "jog")
    panel:Button("Morning exercise: the drill", "lc_exercise", "drill")
    panel:Button("Morning exercise: the parade", "lc_exercise", "parade")
    panel:Button("End current event", "lc_endevent")
    panel:Button("Play an announcement", "lc_announce")
    Check("Half-Life 2's own Overwatch voice for what you have no recording of", "lc_announce_stock")
    Check("Run events automatically", "lc_auto_events")
    Check("Cops enforce curfew on players", "lc_curfew_enforce")
    Check("Morning exercise for citizens (at dawn)", "lc_morning_exercise")
    Slider("Morning exercise every N mornings", "lc_exercise_every", 1, 7, 0)
    panel:Help("Morning exercise needs its points: a jogging route, an exercise yard, a parade route (under Points). They take turns; one with no points is skipped.")
    Check("Radio chatter", "lc_chatter")
    Check("Alarms send a response squad", "lc_squad")
    Slider("Squad: metrocops", "lc_squad_cops", 0, 6, 0)
    Slider("Squad: soldiers", "lc_squad_soldiers", 0, 6, 0)
    Slider("Squad: seconds after the alarm", "lc_squad_delay", 0, 30, 0)
    Slider("Garrison per Combine-only zone", "lc_garrison", 0, 12, 0)
    Slider("Garrison metrocops (out of 10)", "lc_garrison_cops", 0, 10, 0)
    Slider("Stalkers per Combine-only zone (its terminals, cleaning, repairs)", "lc_zone_stalkers", 0, 4, 0)

    Header("Paths and doors")
    panel:Button("Path mapping: on / off (walk to draw nodes)", "lc_pathmap")
    panel:Button("Path mapping: undo this session's nodes", "lc_pathmap_undo")
    panel:Button("Auto-link nearby path nodes", "lc_autolink")
    panel:Button("Unlock all doors now", "lc_unlockdoors")
    panel:Button("Open all doors now", "lc_opendoors")
    Check("Unlock untagged doors on start", "lc_unlock_doors")
    Check("Street Civil Protection units chase people into rebel territory (off: rebel ground is safe from street patrols)", "lc_rebel_pursuit")

    Header("How it feels")
    panel:Help("A person in a city too big for them. Field of view: the widest anyone sees (75 is Half-Life 2's; 0 leaves it to each player). Eye height: 64 is GMod's; lower and people stand over you.")
    Slider("Field of view (widest)", "lc_fov", 0, 100, 0)
    Slider("Eye height", "lc_eye_height", 54, 66, 0)
    Slider("Highest ledge you can climb (jump at it)", "lc_mantle_height", 60, 160, 0)
    Check("Camera sways with your steps (players can turn theirs off: !bob)", "lc_view_bob")
    Slider("Camera sway strength (%)", "lc_view_bob_amount", 0, 200, 0)
    Check("Quiet HUD: no XP, credits, standing or kill feed on screen", "lc_quiet_hud")
    Slider("Seconds on the death card before respawning", "lc_respawn_secs", 0, 60, 0)
    Check("Word gets around when someone dies", "lc_word_gets_around")

    Header("Civil Intake")
    panel:Help("New people arrive with nothing and ask for it: register at Civil Intake (name, face, description, a citizen number), then ask Housing Allocation for a room. Place the two fixtures and an arrival point (Mode list). With no Civil Intake on the map, people are registered and housed as they arrive.")
    Check("New arrivals go through Civil Intake", "lc_intake")
    Slider("Seconds a desk takes to process someone", "lc_intake_secs", 2, 30, 0)
    Slider("Minutes to register before it's a crime", "lc_intake_grace", 1, 60, 0)

    Header("Labor Assignment")
    panel:Help("Place \"Fixture: Labor Assignment\" and Union work is given out and changed only there, in person: a new citizen goes there after Civil Intake, before Housing Allocation, and stays on the job for a stint. Without one, the Union assigns work and the board (F4) changes it, as before.")
    Slider("Minutes on an assignment before it can change", "lc_labor_min_minutes", 0, 240, 0)
    Slider("Or this many shifts, whichever comes first", "lc_labor_min_shifts", 0, 20, 0)
    Slider("Civil Standing for Infestation Cleanup", "lc_labor_cleanup_standing", 0, 200, 0)
    Slider("Civil Standing for Intake Processor", "lc_labor_porter_standing", 0, 200, 0)

    Header("Survival and economy")
    Check("Hunger and thirst", "lc_needs")
    Slider("Minutes until starving", "lc_hunger_minutes", 5, 240, 0)
    Slider("Minutes until dehydrated", "lc_thirst_minutes", 5, 240, 0)
    Slider("Birds", "lc_birds", 0, 30, 0)
    Slider("Headcrab vermin", "lc_vermin", 0, 15, 0)
    Check("Credits, Civil Standing and the Commissary", "lc_economy")
    Check("Hands-on Union shifts (street sweep, factory line, papers check)", "lc_jobgames")
    Check("Rations come from the city's stores", "lc_stockpile")
    Slider("Rations the stores hold", "lc_stock_max", 50, 2000, 0)
    Slider("Citizens per ration the city eats a minute (lower: emptier)", "lc_stock_eat", 5, 200, 0)
    panel:Button("Fill the city's ration stores", "lc_stock", "100000")

    Header("Contraband and searches")
    Check("Civil Protection NPCs stop and search players", "lc_stops")
    Slider("Checkpoint stop chance (%)", "lc_stop_chance", 0, 100, 0)
    Slider("Street stop chance (%)", "lc_street_stop_chance", 0, 20, 0)
    Slider("Seconds between stops (per person)", "lc_stop_cooldown", 60, 1800, 0)
    Slider("Disguise risk near Civil Protection units (% per minute)", "lc_disguise_risk", 0, 50, 0)
    Slider("Sweeps raid stashes (%)", "lc_raid_chance", 0, 100, 0)

    Header("Prison and conduct")
    Slider("Sentence (seconds)", "lc_prison_time", 30, 1200, 0)
    Check("Security NPCs arrest instead of kill", "lc_npc_arrests")
    Check("Civil Protection units walk the arrested to the prison", "lc_march")
    Slider("Longest walk to the prison (seconds)", "lc_march_max", 30, 600, 0)
    Check("Judge player kills (anti-RDM)", "lc_conduct")
    Slider("Spawn protection (seconds)", "lc_spawn_protect", 0, 30, 0)

    Header("Factions")
    panel:Button("Open faction menu", "lcf_menu")

    Header("Debugging")
    panel:Button("Copy debug report", "lc_debugreport")
    panel:Button("Status to chat", "lc_status")
    panel:Button("Reload saved layout", "lc_reload")
    panel:CheckBox("Show layout without the tool", "lc_show")
    panel:CheckBox("Show what the NPC I'm looking at is doing", "lc_show_npcs")
    panel:CheckBox("Show every nearby NPC (cluttered)", "lc_show_all_npcs")
    panel:Button("Performance debugger (what's slow: hooks, timers, net messages, hitches)", "lc_perfdebug_menu")

    Header("Dreams: test one")
    panel:Help("Try any dream yourself, right now: you go into it awake, at the dream point, alone (the city's people stand in). Nobody asleep is pulled in, and it isn't tonight's dream. Stop whenever you like; nothing you win or lose counts. Needs a Point: dream (Mode list).")
    local dreamPick = panel:ComboBox("Dream")
    local function FillDreams(t)
        if not IsValid(dreamPick) then return end
        dreamPick:Clear()
        for _, d in ipairs(t.list or {}) do dreamPick:AddChoice(d.mood .. ": " .. d.name .. (d.kind == "ending" and " (an ending)" or ""), d.id) end
        if not t.point then dreamPick:SetValue("No dream point on this map yet: place one first")
        elseif t.on == false then dreamPick:SetValue("Dreams are off (lc_dreams 0)")
        else dreamPick:SetValue("Pick a dream to test") end
    end
    if LC_CL then
        LC_CL.DreamTestWatchers = LC_CL.DreamTestWatchers or {}
        LC_CL.DreamTestWatchers.editor = FillDreams
        if LC_CL.DreamTestList then FillDreams(LC_CL.DreamTestList) end
    end
    timer.Simple(0.2, function()
        local me = LocalPlayer()
        if IsValid(me) and me:IsSuperAdmin() and LC_CL and LC_CL.DreamTestAct then LC_CL.DreamTestAct("list") end
    end)
    local testBtn = panel:Button("Test it now (just me)")
    if IsValid(testBtn) then testBtn.DoClick = function()
        local _, id = dreamPick:GetSelected()
        if not id then
            notification.AddLegacy("Pick a dream first.", NOTIFY_HINT or 3, 3)
            if LC_CL and LC_CL.DreamTestAct then LC_CL.DreamTestAct("list") end
            return
        end
        if LC_CL and LC_CL.DreamTestAct then LC_CL.DreamTestAct("test", id) end
    end end
    local stopBtn = panel:Button("Stop the test (wake up)")
    if IsValid(stopBtn) then stopBtn.DoClick = function() if LC_CL and LC_CL.DreamTestAct then LC_CL.DreamTestAct("stop") end end end
    panel:Button("Vortigaunts break into the next propaganda dream (for sure)", "lc_vortwar_next")
    panel:Help("Press it, then test a propaganda dream: a quarter to nearly half way through, purple vortigaunts break in. Stand in their light to pull toward them.")
    local listBtn = panel:Button("Refresh the list")
    if IsValid(listBtn) then listBtn.DoClick = function() if LC_CL and LC_CL.DreamTestAct then LC_CL.DreamTestAct("list") end end end
    local winBtn = panel:Button("Dreams window (tonight's dream, wake everyone, snapshots)")
    if IsValid(winBtn) then winBtn.DoClick = function() if LC_CL and LC_CL.DreamsMenu then LC_CL.DreamsMenu() end end end
end
