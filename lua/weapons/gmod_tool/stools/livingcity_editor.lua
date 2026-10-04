--[[
    Living City Editor (toolgun)
    Q menu > Tools > Living City > Living City Editor

    Left click   place / tag / select (depends on mode)
    Right click  remove what's under your aim, or clear a door tag
    Reload       next mode
    Z            undo, like any other tool

    Every change saves immediately for this map.
]]

TOOL.Category = "Living City"
TOOL.Name = "#tool.livingcity_editor.name"
TOOL.ClientConVar = { mode = "idle", group = "1", radius = "300" }
TOOL.Information = {
    { name = "left" },
    { name = "right" },
    { name = "reload" },
}

local MODES = {
    { id = "idle",        label = "Point: loiter spot (citizens)" },
    { id = "sit",         label = "Point: sit on the ground (citizens)" },
    { id = "sitchair",    label = "Point: sit on a bench or chair (citizens)" },
    { id = "lean",        label = "Point: lean on a wall (citizens)" },
    { id = "queue",       label = "Point: ration line slot (line #, front first)", group = true },
    { id = "patrol",      label = "Point: patrol stop (beat #, 0 = random patrols)", group = true },
    { id = "checkpoint",  label = "Point: checkpoint post (security)" },
    { id = "spawn",       label = "Point: spawn / exit doorway" },
    { id = "cell",        label = "Point: prison cell" },
    { id = "release",     label = "Point: prison release spot" },
    { id = "work",        label = "Point: workplace (job #, see the list in the panel)", group = true },
    { id = "vending",     label = "Fixture: water vending machine" },
    { id = "dispenser",   label = "Fixture: ration dispenser" },
    { id = "terminal",    label = "Fixture: commissary terminal" },
    { id = "stove",       label = "Fixture: stove" },
    { id = "fire",        label = "Fixture: burning barrel" },
    { id = "dealer",      label = "Fixture: black market dealer" },
    { id = "node",        label = "Path: node (links to your last node)" },
    { id = "link",        label = "Path: link / unlink two nodes" },
    { id = "zone_nogo",   label = "Zone: no-go", radius = true },
    { id = "zone_rebel",  label = "Zone: rebel territory (no security)", radius = true },
    { id = "zone_block",  label = "Zone: housing block (block #)", radius = true, group = true },
    { id = "zone_prison", label = "Zone: prison area", radius = true },
    { id = "zone_infest", label = "Zone: infestation (zombies live here)", radius = true },
    { id = "door_cp",     label = "Door: Civil Protection only" },
    { id = "door_locked", label = "Door: always locked" },
    { id = "door_open",   label = "Door: always open" },
    { id = "door_ignore", label = "Door: NPCs ignore it" },
    { id = "door_force",  label = "Door: force NPCs to treat it as a door" },
    { id = "door_test",   label = "Door: test open / close" },
    { id = "inspect",     label = "Inspect anything" },
    { id = "walker",      label = "Test walker: send a citizen here" },
}

-- sit, bench and lean spots, and fixtures, face the person placing them
local FACE_PLACER = { sit = true, sitchair = true, lean = true, vending = true, dispenser = true, terminal = true, stove = true, dealer = true }

local function ModeIndex(id)
    for i, m in ipairs(MODES) do if m.id == id then return i end end
    return 1
end
local function Mode(id) return MODES[ModeIndex(id)] end

if CLIENT then
    language.Add("tool.livingcity_editor.name", "Living City Editor")
    language.Add("tool.livingcity_editor.desc", "Build routines, paths, zones and door rules for Living City")
    language.Add("tool.livingcity_editor.left", "Place / tag / select")
    language.Add("tool.livingcity_editor.right", "Remove what you're aiming at")
    language.Add("tool.livingcity_editor.reload", "Next mode")
end

local function Tell(ply, msg) ply:ChatPrint("[Living City] " .. msg) end

local function CheckAccess(ply)
    if LC and LC.CanEdit and LC.CanEdit(ply) then return true end
    Tell(ply, "Only superadmins can edit the city layout.")
    return false
end

local function Undoable(ply, label, fn)
    undo.Create("Living City: " .. label)
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
    local group = Mode(mode.id).group and self:GetClientNumber("group", 1) or 0
    local p = LC.AddPoint(trace.HitPos, yaw, mode.id, group)
    if not p then return false end
    Undoable(ply, mode.id .. " point", function() LC.RemovePoint(p) end)
    local extra = ""
    if mode.id == "queue" then
        extra = group > 0 and string.format(" Line %d now has %d slot(s).", group, #LC.PointsOfKind("queue", group))
            or " (Line 0 is a loose standing spot, not a line.)"
    elseif mode.id == "patrol" and group > 0 then
        extra = string.format(" Beat %d now has %d stop(s).", group, #LC.PointsOfKind("patrol", group))
    end
    Tell(ply, "Placed " .. mode.id .. " point." .. extra)
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

local function PlaceZone(self, ply, trace, mode)
    if not trace.Hit then return false end
    local kind = string.sub(mode.id, 6)
    local r = math.Clamp(self:GetClientNumber("radius", 300), 32, 4000)
    local group = mode.group and math.max(1, self:GetClientNumber("group", 1)) or 0
    local z = LC.AddZone(trace.HitPos, r, kind, group)
    if not z then return false end
    Undoable(ply, kind .. " zone", function() LC.RemoveZone(z) end)
    Tell(ply, string.format("Placed %s zone, radius %d.%s", kind, r,
        kind == "block" and (" " .. LC.BlockName(group) .. ".") or ""))
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
        Tell(ply, string.format("%s zone, radius %d%s", z.kind, z.r, (z.group or 0) > 0 and (", #" .. z.group) or ""))
        return true
    end
    local route = LC.BuildRoute and LC.BuildRoute(ply:GetPos(), trace.HitPos, "citizen")
    Tell(ply, route and string.format("Nothing here. A citizen would get here from you in %d path hops.", #route - 1)
        or "Nothing here. A citizen would walk here using the map's own navigation.")
    return true
end

function TOOL:LeftClick(trace)
    if CLIENT then return true end
    local ply = self:GetOwner()
    if not CheckAccess(ply) then return false end
    local mode = Mode(self:GetClientInfo("mode"))
    local id = mode.id

    if LC.POINT_KINDS[id] then return PlacePoint(self, ply, trace, mode) end
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
        if mode.radius then extra[#extra + 1] = "radius " .. self:GetClientNumber("radius", 300) end
        local text = mode.label .. (#extra > 0 and ("   [" .. table.concat(extra, ", ") .. "]") or "")
        draw.SimpleTextOutlined(text, "DermaLarge", ScrW() / 2, ScrH() - 140, color_white,
            TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 2, color_black)
        draw.SimpleTextOutlined("Every change saves straight away to data/livingcity/" .. game.GetMap() .. ".json   |   lc_backups lists backups",
            "DermaDefault", ScrW() / 2, ScrH() - 112, Color(200, 200, 200), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, color_black)
        -- zone modes: the shaded preview of the new zone is drawn by the overlay (cl_livingcity.lua)
    end
end

function TOOL.BuildCPanel(panel)
    local function Header(text)
        local l = panel:Help(text)
        if IsValid(l) then l:SetFont("DermaDefaultBold") end
    end

    panel:Help("Build the city. Every click saves for this map. Z undoes.")

    local combo = panel:ComboBox("Mode")
    for _, m in ipairs(MODES) do combo:AddChoice(m.label, m.id) end
    local cur = GetConVar("livingcity_editor_mode")
    combo:SetValue(Mode(cur and cur:GetString() or "idle").label)
    combo.OnSelect = function(_, _, _, id) RunConsoleCommand("livingcity_editor_mode", id) end

    panel:NumSlider("Line / beat / block number", "livingcity_editor_group", 0, 32, 0)
    panel:NumSlider("Zone radius", "livingcity_editor_radius", 32, 2000, 0)
    panel:Help("Lines and beats: place slots/stops in order, front first. Sit, bench and lean spots: aim at the foot of the wall; they'll face you.")
    if LCJ and LCJ.Occupations then
        local jobs = {}
        for _, o in ipairs(LCJ.Occupations) do jobs[#jobs + 1] = o.num .. " " .. o.place end
        panel:Help("Workplace numbers: " .. table.concat(jobs, ", ") .. ".")
    end

    panel:CheckBox("Shade zones on the ground", "lc_zone_fill")
    panel:Help("Aim at a zone to highlight it and see its radius. Aim at its center marker to pick it out of overlapping zones.")

    Header("Saving")
    panel:Help("Every change saves straight away to garrysmod/data/livingcity/<map>.json, and older versions are backed up automatically every few minutes.")
    panel:Button("Back up the layout now", "lc_backup")
    panel:Button("List backups (restore with lc_restore <number>)", "lc_backups")

    Header("City")
    panel:Button("Start the city", "lc_start")
    panel:Button("Stop and clear NPCs", "lc_stop")
    panel:Button("Calm security", "lc_calm")
    panel:CheckBox("Start automatically on map load", "lc_autostart")

    Header("Population")
    panel:NumSlider("Citizens", "lc_citizens", 0, 80, 0)
    panel:NumSlider("Civil Protection", "lc_cops", 0, 30, 0)
    panel:NumSlider("Overwatch soldiers", "lc_soldiers", 0, 20, 0)
    panel:NumSlider("Scanners", "lc_scanners", 0, 10, 0)
    panel:NumSlider("Zombies (infestation zones)", "lc_zombies", 0, 40, 0)
    panel:NumSlider("NPC budget (hard cap)", "lc_npc_budget", 10, 200, 0)
    panel:Button("Save these numbers for this map", "lc_savesettings")

    Header("Events")
    panel:Button("Ration distribution", "lc_event", "rations")
    panel:Button("Inspection sweep", "lc_event", "sweep")
    panel:Button("Curfew", "lc_event", "curfew")
    panel:Button("Lockdown", "lc_event", "lockdown")
    panel:Button("End current event", "lc_endevent")
    panel:Button("Play an announcement", "lc_announce")
    panel:CheckBox("Run events automatically", "lc_auto_events")
    panel:CheckBox("Cops enforce curfew on players", "lc_curfew_enforce")
    panel:CheckBox("Radio chatter", "lc_chatter")

    Header("Paths and doors")
    panel:Button("Auto-link nearby path nodes", "lc_autolink")
    panel:Button("Unlock all doors now", "lc_unlockdoors")
    panel:Button("Open all doors now", "lc_opendoors")
    panel:CheckBox("Unlock untagged doors on start (Sandbox)", "lc_unlock_doors")
    panel:CheckBox("Security chases people into rebel zones", "lc_rebel_pursuit")

    Header("Survival and economy")
    panel:CheckBox("Hunger and thirst", "lc_needs")
    panel:NumSlider("Minutes until starving", "lc_hunger_minutes", 5, 240, 0)
    panel:NumSlider("Minutes until dehydrated", "lc_thirst_minutes", 5, 240, 0)
    panel:NumSlider("Birds", "lc_birds", 0, 30, 0)
    panel:NumSlider("Headcrab vermin", "lc_vermin", 0, 15, 0)
    panel:CheckBox("Credits, Civil Standing and the Commissary", "lc_economy")

    Header("Contraband and searches")
    panel:CheckBox("Civil Protection NPCs stop and search players", "lc_stops")
    panel:NumSlider("Checkpoint stop chance (%)", "lc_stop_chance", 0, 100, 0)
    panel:NumSlider("Street stop chance (%)", "lc_street_stop_chance", 0, 20, 0)
    panel:NumSlider("Seconds between stops (per person)", "lc_stop_cooldown", 60, 1800, 0)
    panel:NumSlider("Disguise risk near units (% per minute)", "lc_disguise_risk", 0, 50, 0)
    panel:NumSlider("Sweeps raid stashes (%)", "lc_raid_chance", 0, 100, 0)

    Header("Prison and conduct")
    panel:NumSlider("Sentence (seconds)", "lc_prison_time", 30, 1200, 0)
    panel:CheckBox("Security NPCs arrest instead of kill", "lc_npc_arrests")
    panel:CheckBox("Judge player kills (anti-RDM)", "lc_conduct")
    panel:NumSlider("Spawn protection (seconds)", "lc_spawn_protect", 0, 30, 0)

    Header("Factions (Sandbox servers)")
    panel:CheckBox("Enable factions and ranks", "lc_factions")
    panel:Button("Open faction menu", "lcf_menu")

    Header("Debugging")
    panel:Button("Copy debug report", "lc_debugreport")
    panel:Button("Status to chat", "lc_status")
    panel:Button("Reload saved layout", "lc_reload")
    panel:CheckBox("Show layout without the tool", "lc_show")
    panel:CheckBox("Show what NPCs are doing", "lc_show_npcs")
end
