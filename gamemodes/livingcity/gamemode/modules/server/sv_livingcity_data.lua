--[[
    Living City: saved layout

    One file per map: garrysmod/data/livingcity/<map>.json
    Holds every point, path node, link, zone, door tag, and every Living City
    setting changed on this map (the editor's sliders and checkboxes, or the
    console). Saved on every edit, loaded on map start, so a restart keeps
    them. Copy the file to another server to bring the whole layout along.
]]

if CLIENT then return end

util.AddNetworkString("lc_data")
util.AddNetworkString("lc_request")
util.AddNetworkString("lc_route")
util.AddNetworkString("lc_select")

LC = LC or {}
LC.Points = LC.Points or {}     -- { pos, yaw, kind, group }
LC.Nodes = LC.Nodes or {}       -- [id] = { id, pos, links = { [id] = true } }
LC.Zones = LC.Zones or {}       -- { pos, r, kind, group }
LC.DoorTags = LC.DoorTags or {} -- [MapCreationID] = tag
LC.NextNodeId = LC.NextNodeId or 1

LC.POINT_KINDS = {
    idle = true, sit = true, sitchair = true, lean = true, queue = true,
    patrol = true, checkpoint = true, spawn = true, cell = true, release = true, prisonwork = true, speech = true,
    work = true, vending = true, dispenser = true, terminal = true, stove = true, fire = true, dealer = true, locker = true, screen = true, lawboard = true, cpfeed = true, rebelboard = true, interrochair = true, console = true,
    infodesk = true, civposter = true,
    workbench = true, recycler = true, bin = true, salvage = true, -- (sv_livingcity_salvage.lua)
    conveyor = true, -- the factory line (sv_livingcity_jobgames.lua)
    bed = true, toilet = true, bath = true, -- sleep and hygiene (sv_livingcity_rest.lua, sv_livingcity_hygiene.lua)
    citybin = true, streetlight = true, loudspeaker = true, screen_big = true, tv = true, -- street furniture (sv_livingcity_propaganda.lua)
    lz = true, -- where Overwatch drops soldiers (sv_livingcity_resistanceops.lua)
    dataterm = true, masterterm = true, -- the Resistance steal data from these (sv_livingcity_heist.lua)
    sspawn = true, -- where scanners flown from a console go up (sv_livingcity_scanner.lua)
    transformer = true, forcefield = true, -- the power grid, and Combine forcefields (sv_livingcity_power.lua)
    powerbank = true, turret = true, barricade_low = true, barricade = true, barricade_tall = true, -- checkpoints (sv_livingcity_checkpoints.lua)
    platform = true, -- where the trains stop (sv_livingcity_trains.lua)
    intake = true, housingterm = true, arrival = true, -- Civil Intake, Housing Allocation, where new people arrive (sv_livingcity_intake.lua)
    laborterm = true, -- Labor Assignment: Union work is given out and changed here (sv_livingcity_labor.lua)
    cpsupply = true, -- the Civil Protection Commissary (sv_livingcity_cpsupply.lua)
    studio = true, -- where Dr. Breen speaks when no player is Director of Propaganda (sv_livingcity_propaganda.lua)
    desk = true, adminpower = true, suppressor = true, -- her last stand: her desk, and the transformer powering her shield (sv_livingcity_collapse.lua)
    incinerator = true, -- where the dead go (sv_livingcity_mortuary.lua)
    hazbarrel = true, -- an infestation control barrel: cleanup workers empty their hoovers here (sv_livingcity_cleanup.lua)
    dock = true, graffiti = true, rubble = true, pipe = true, -- loading docks, walls that get tagged, rubble piles (Union shifts)
    ladder = true, -- two with the same number: a ladder NPCs can use (sv_livingcity_navgraph.lua)
    zspawn = true, rspawn = true, -- infested and resistance respawn/spawn points
    rlookout = true, -- an armed rebel stands guard here (sv_livingcity_rebels.lua)
    bunk = true, -- a rebel sleeps here now and then (sv_livingcity_rebellife.lua)
    jogroute = true, yard = true, parade = true, -- morning exercise: the jogging route, the drill yard, the parade route (sv_livingcity_exercise.lua)
    dream = true, -- where the shared dreams happen, out of the map (sv_livingcity_dreams.lua)
    sterm = true, -- a Combine zone's stalker works the map's terminal here (sv_livingcity_zonestalkers.lua)
}
LC.ZONE_KINDS = { nogo = true, infest = true, prison = true, block = true, rebel = true, combine = true,
    dream = true } -- (the shared dreams' edge: sv_livingcity_dreams.lua)
LC.DOOR_TAGS = { cp = true, prison = true, locked = true, open = true, ignore = true, force = true, rent = true, office = true }

local DOOR_CLASSES = { prop_door_rotating = true, func_door = true, func_door_rotating = true, func_movelinear = true } -- (movelinear: the Combine's sliding doors, on some maps)
local SETTINGS = { "lc_citizens", "lc_cops", "lc_soldiers", "lc_scanners", "lc_zombies", "lc_rebels" }

-- One of ours, and a server setting that exists (not a client's own preference).
local function OurSetting(name)
    return type(name) == "string" and (string.match(name, "^lc_[%w_]+$") or string.match(name, "^lc[fq]_[%w_]+$")) ~= nil
        and ConVarExists(name)
end
LC.IsCitySetting = OurSetting

local function Path() return "livingcity/" .. game.GetMap() .. ".json" end
LC.LayoutPath = Path -- (core: CORE.md)

function LC.CanEdit(ply)
    if not IsValid(ply) then return true end -- server console
    return game.SinglePlayer() or ply:IsListenServerHost() or ply:IsSuperAdmin()
end

function LC.IsDoorEntity(ent)
    return IsValid(ent) and DOOR_CLASSES[ent:GetClass()] == true
end

------------------------------------------------------------------------
-- Compressed table sending (layouts can get big). Small ones go at once as
-- they always did; big or many go in pieces and at a pace each player's game
-- can take, and wait while it loads in (sh_livingcity_net.lua).
------------------------------------------------------------------------

function LC.SendCompressed(msg, tbl, recipients)
    return LC.Net.SendCompressed(msg, tbl, recipients)
end

local function Editors()
    local out = {}
    for _, ply in ipairs(player.GetAll()) do
        if LC.CanEdit(ply) then out[#out + 1] = ply end
    end
    return out
end

local function Snapshot()
    local pts = {}
    for _, p in ipairs(LC.Points) do
        pts[#pts + 1] = { x = p.pos.x, y = p.pos.y, z = p.pos.z, yaw = p.yaw or 0, kind = p.kind, group = p.group or 0 }
    end
    local nodes = {}
    for id, n in pairs(LC.Nodes) do
        local links = {}
        for other in pairs(n.links) do if other > id then links[#links + 1] = other end end
        nodes[#nodes + 1] = { id = id, x = n.pos.x, y = n.pos.y, z = n.pos.z, l = links }
    end
    local zones = {}
    for _, z in ipairs(LC.Zones) do
        zones[#zones + 1] = { x = z.pos.x, y = z.pos.y, z = z.pos.z, r = z.r, h = z.h, kind = z.kind, group = z.group or 0, grown = z.grown or nil,
            box = LCZ.PackBox(z.box), ground = z.cells and LCZ.PackGround(z) or nil }
    end
    local doors = {}
    for id, tag in pairs(LC.DoorTags) do
        local e = ents.GetMapCreatedEntity(id)
        if IsValid(e) then doors[#doors + 1] = { idx = e:EntIndex(), tag = tag } end
    end
    local props = {}
    for _, r in ipairs(LC.Props or {}) do
        props[#props + 1] = { x = r.pos.x, y = r.pos.y, z = r.pos.z, model = r.model }
    end
    return { points = pts, nodes = nodes, zones = zones, doors = doors, props = props }
end

function LC.SendData(target)
    local recipients = IsValid(target) and { target } or Editors()
    if #recipients == 0 then return end
    LC.SendCompressed("lc_data", Snapshot(), recipients)
end

net.Receive("lc_request", function(_, ply)
    if LC.CanEdit(ply) then LC.SendData(ply) end
end)

------------------------------------------------------------------------
-- Save and load
------------------------------------------------------------------------

local function Changed()
    if LC.RebuildGraph then LC.RebuildGraph() end
    if LC.OnLayoutChanged then LC.OnLayoutChanged() end
    if LC.BroadcastPublic then LC.BroadcastPublic() end
end

------------------------------------------------------------------------
-- Backups: hours of editing shouldn't be one bad click (or one broken file)
-- away from gone. Before the layout is overwritten, the previous version is
-- copied to garrysmod/data/livingcity/backups/<map>/ at most every few
-- minutes, and the newest 30 are kept. lc_backups lists them, lc_restore
-- brings one back (after backing up what's there now).
------------------------------------------------------------------------

local BACKUP_EVERY, BACKUP_KEEP = 300, 30

local function BackupDir() return "livingcity/backups/" .. game.GetMap() end

function LC.ListBackups()
    local names = file.Find(BackupDir() .. "/*.json", "DATA") or {}
    table.sort(names, function(a, b) return a > b end) -- newest first (names are timestamps)
    return names
end

function LC.BackupLayout(reason)
    local raw = file.Read(Path(), "DATA")
    if not raw or raw == "" then return nil end
    file.CreateDir("livingcity")
    file.CreateDir("livingcity/backups")
    file.CreateDir(BackupDir())
    local name = os.date("%Y%m%d_%H%M%S") .. (reason and ("_" .. reason) or "") .. ".json"
    file.Write(BackupDir() .. "/" .. name, raw)
    LC.LastBackupAt = SysTime()
    local all = LC.ListBackups()
    for i = BACKUP_KEEP + 1, #all do file.Delete(BackupDir() .. "/" .. all[i]) end
    return name
end

function LC.RestoreBackup(which)
    local all = LC.ListBackups()
    local name = all[tonumber(which) or 0] or which
    if not name or not table.HasValue(all, name) then return false, "No such backup. lc_backups lists them." end
    local raw = file.Read(BackupDir() .. "/" .. name, "DATA")
    if not raw or not util.JSONToTable(raw) then return false, "That backup can't be read." end
    LC.BackupLayout("before_restore")
    LC.SafeWrite(Path(), raw, { force = true }) -- (an admin's own choice)
    LC.LayoutBroken = nil
    LC.LoadData(false)
    if LC.ApplyAllDoors then LC.ApplyAllDoors() end
    return true, name
end

-- settingsOnly: only the settings changed (no need to rebuild paths or resend the layout)
function LC.SaveData(settingsOnly)
    file.CreateDir("livingcity")
    if LC.LayoutBroken then
        -- the file on disk couldn't be read; keep a copy before anything overwrites it
        local raw = file.Read(Path(), "DATA")
        if raw then file.Write("livingcity/" .. game.GetMap() .. "_unreadable_" .. os.date("%Y%m%d_%H%M%S") .. ".txt", raw) end
        LC.LayoutBroken = nil
        LC.SafeFileAllow(Path()) -- (kept just above: the layout may be saved again)
    end
    if not LC.LastBackupAt or SysTime() - LC.LastBackupAt > BACKUP_EVERY then LC.BackupLayout() end
    local out = {
        version = 3, map = game.GetMap(), nextNodeId = LC.NextNodeId,
        points = {}, nodes = {}, links = {}, zones = {}, doors = {}, settings = LC.Settings,
    }
    for _, p in ipairs(LC.Points) do
        out.points[#out.points + 1] = { x = p.pos.x, y = p.pos.y, z = p.pos.z, yaw = p.yaw, kind = p.kind, group = p.group or 0 }
    end
    for id, n in pairs(LC.Nodes) do
        out.nodes[#out.nodes + 1] = { id = id, x = n.pos.x, y = n.pos.y, z = n.pos.z }
        for other in pairs(n.links) do
            if other > id then out.links[#out.links + 1] = { id, other } end
        end
    end
    for _, z in ipairs(LC.Zones) do
        -- territory that spread on its own lives in its own file (sv_livingcity_territory.lua)
        if not z.grown then
            out.zones[#out.zones + 1] = { x = z.pos.x, y = z.pos.y, z = z.pos.z, r = z.r, kind = z.kind, group = z.group or 0,
                box = LCZ.PackBox(z.box) }
        end
    end
    for id, tag in pairs(LC.DoorTags) do
        out.doors[#out.doors + 1] = { id = id, tag = tag }
    end
    out.props = LC.PropsToSave and LC.PropsToSave() or nil -- persistent props (sv_livingcity_props.lua)
    LC.SafeWrite(Path(), util.TableToJSON(out, true))
    if settingsOnly then return end
    Changed()
    LC.SendData(nil)
end

function LC.LoadData(applySettings)
    LC.Points, LC.Nodes, LC.Zones, LC.DoorTags, LC.Settings = {}, {}, {}, {}, nil
    LC.NextNodeId = 1
    local migrated = false

    local t, how = LC.SafeReadJSON(Path()) -- (an unreadable file falls back to its .bak.txt: sv_livingcity_safefile.lua)
    if how == "failed" then
        LC.LayoutBroken = true
        LC.Log("error", "Layout file " .. Path() .. " couldn't be read. A copy is kept before anything overwrites it; lc_backups lists earlier versions.")
    end
    if t then
        local pts = t.points or t -- version 1 files were a bare list of points
        for _, p in ipairs(pts) do
            if p.kind == "fence" then p.kind = "dealer"; migrated = true end -- renamed
            if p.x and LC.POINT_KINDS[p.kind] then
                LC.Points[#LC.Points + 1] = {
                    pos = Vector(p.x, p.y, p.z), yaw = p.yaw or 0, kind = p.kind, group = tonumber(p.group) or 0,
                }
            end
        end
        for _, n in ipairs(t.nodes or {}) do
            local id = tonumber(n.id)
            if id then
                LC.Nodes[id] = { id = id, pos = Vector(n.x, n.y, n.z), links = {} }
                LC.NextNodeId = math.max(LC.NextNodeId, id + 1)
            end
        end
        for _, l in ipairs(t.links or {}) do
            local a, b = LC.Nodes[tonumber(l[1])], LC.Nodes[tonumber(l[2])]
            if a and b then a.links[b.id] = true; b.links[a.id] = true end
        end
        for _, z in ipairs(t.zones or {}) do
            if LC.ZONE_KINDS[z.kind] then
                LC.Zones[#LC.Zones + 1] = {
                    pos = Vector(z.x, z.y, z.z), r = tonumber(z.r) or 150, kind = z.kind, group = tonumber(z.group) or 0,
                    box = LCZ.UnpackBox(z.box),
                }
            end
        end
        for _, d in ipairs(t.doors or {}) do
            if LC.DOOR_TAGS[d.tag] then LC.DoorTags[tonumber(d.id)] = d.tag end
        end
        LC.NextNodeId = math.max(LC.NextNodeId, tonumber(t.nextNodeId) or 1)
        LC.Settings = t.settings
        if (t.version or 1) < 3 then migrated = true end
    end

    -- the very first builds kept Civil Protection door tags in a separate file
    local oldPath = "livingcity/" .. game.GetMap() .. "_cpdoors.json"
    local oldRaw = file.Read(oldPath, "DATA")
    if oldRaw then
        for _, id in ipairs(util.JSONToTable(oldRaw) or {}) do LC.DoorTags[tonumber(id)] = "cp" end
        file.Delete(oldPath)
        migrated = true
    end

    if applySettings then
        if istable(LC.Settings) then
            for name, v in pairs(LC.Settings) do
                if OurSetting(name) and (isnumber(v) or isstring(v) or isbool(v)) then
                    if isbool(v) then v = v and 1 or 0 end
                    RunConsoleCommand(name, tostring(v))
                end
            end
        end
        -- from here on, a setting that's changed is remembered (not while the map's
        -- own are being put back)
        LC.SettingsReady = true
    end

    if LC.PropsFromSave then LC.PropsFromSave(t and t.props or {}) end
    if LC.RestoreTerritory then LC.RestoreTerritory() end
    -- path nodes under the jogging route, for a layout laid out before there were any (sv_livingcity_exercise.lua)
    if LC.LayJogNodes and LC.LayJogNodes() then migrated = true end
    if migrated then LC.SaveData() else Changed(); LC.SendData(nil) end
end

function LC.SaveSettings()
    LC.Settings = istable(LC.Settings) and LC.Settings or {}
    for _, name in ipairs(SETTINGS) do
        local cv = GetConVar(name)
        if cv then LC.Settings[name] = cv:GetString() end
    end
    LC.SaveData(true)
end

-- A setting changed (the editor, the console, rcon): kept with this map's layout,
-- written a moment later (a slider dragged about is one write, not fifty).
function LC.RememberSetting(name, value)
    if not LC.SettingsReady or not OurSetting(name) then return end
    LC.Settings = istable(LC.Settings) and LC.Settings or {}
    value = tostring(value)
    if LC.Settings[name] ~= nil and tostring(LC.Settings[name]) == value then return end
    LC.Settings[name] = value
    timer.Create("LivingCitySaveSettings", 1, 1, function() LC.SaveData(true) end)
end

------------------------------------------------------------------------
-- Points
------------------------------------------------------------------------

function LC.AddPoint(pos, yaw, kind, group)
    if not LC.POINT_KINDS[kind] then return nil end
    local p = { pos = pos, yaw = yaw or 0, kind = kind, group = math.max(0, math.floor(tonumber(group) or 0)) }
    LC.Points[#LC.Points + 1] = p
    if kind == "jogroute" and LC.LayJogNodes then LC.LayJogNodes() end -- (a path node under every jogging stop: sv_livingcity_exercise.lua)
    LC.SaveData()
    return p
end

function LC.RemovePoint(p)
    for i, q in ipairs(LC.Points) do
        if q == p then
            table.remove(LC.Points, i)
            LC.SaveData()
            return true
        end
    end
    return false
end

function LC.NearestPoint(pos, radius)
    local best, bestD
    for _, p in ipairs(LC.Points) do
        local d = p.pos:DistToSqr(pos)
        if d < radius * radius and (not bestD or d < bestD) then best, bestD = p, d end
    end
    return best
end

function LC.RemoveNearestPoint(pos, radius)
    local p = LC.NearestPoint(pos, radius)
    if p and LC.RemovePoint(p) then return p.kind, p end
    return nil
end

------------------------------------------------------------------------
-- Path nodes and links
------------------------------------------------------------------------

function LC.AddNode(pos, noSave)
    local id = LC.NextNodeId
    LC.NextNodeId = id + 1
    local n = { id = id, pos = pos, links = {} }
    LC.Nodes[id] = n
    if not noSave then LC.SaveData() end
    return n
end

function LC.RemoveNode(n)
    if not n or LC.Nodes[n.id] ~= n then return false end
    for other in pairs(n.links) do
        if LC.Nodes[other] then LC.Nodes[other].links[n.id] = nil end
    end
    LC.Nodes[n.id] = nil
    LC.SaveData()
    return true
end

function LC.NearestNode(pos, radius)
    local best, bestD
    for _, n in pairs(LC.Nodes) do
        local d = n.pos:DistToSqr(pos)
        if d < radius * radius and (not bestD or d < bestD) then best, bestD = n, d end
    end
    return best
end

-- Returns true if the two nodes are now linked, false if now unlinked.
function LC.ToggleLink(a, b, noSave)
    if not a or not b or a == b then return nil end
    local linked
    if a.links[b.id] then
        a.links[b.id], b.links[a.id] = nil, nil
        linked = false
    else
        a.links[b.id], b.links[a.id] = true, true
        linked = true
    end
    if not noSave then LC.SaveData() end
    return linked
end

------------------------------------------------------------------------
-- Zones
------------------------------------------------------------------------

-- box: optional { mins, maxs } (LCZ.BoxFromCorners); then pos and r are worked out from it.
function LC.AddZone(pos, r, kind, group, box)
    if not LC.ZONE_KINDS[kind] then return nil end
    if box then pos, r = LCZ.BoxCircle(box) end
    local z = {
        pos = pos, r = math.Clamp(tonumber(r) or 150, 32, 6000), kind = kind,
        group = math.max(0, math.floor(tonumber(group) or 0)), box = box,
    }
    LC.Zones[#LC.Zones + 1] = z
    LC.SaveData()
    return z
end

function LC.RemoveZone(z)
    for i, q in ipairs(LC.Zones) do
        if q == z then
            table.remove(LC.Zones, i)
            LC.SaveData()
            if LC.SaveTerritory then LC.SaveTerritory() end
            return true
        end
    end
    return false
end

-- The smallest zone containing pos.
-- What the editor means when you aim at a zone: aiming at a zone's center
-- marker picks that zone (even inside a bigger or smaller one); otherwise
-- the smallest zone you're aiming inside. The overlay highlights the same one.
function LC.ZoneForEditing(pos)
    local best, bd
    for _, z in ipairs(LC.Zones) do
        local dx, dy = pos.x - z.pos.x, pos.y - z.pos.y
        local d2 = dx * dx + dy * dy
        if d2 < 48 * 48 and math.abs(pos.z - z.pos.z) < 128 and (not bd or d2 < bd) then best, bd = z, d2 end
    end
    return best or LC.ZoneAt(pos)
end

function LC.ZoneAt(pos)
    local best
    for _, z in ipairs(LC.Zones) do
        if LCZ.Contains(z, pos) and (not best or z.r < best.r) then best = z end
    end
    return best
end

------------------------------------------------------------------------
-- Doors
------------------------------------------------------------------------

function LC.GetDoorTag(door)
    if not IsValid(door) then return nil end
    local id = door:MapCreationID()
    if not id or id < 0 then return nil end
    return LC.DoorTags[id]
end

-- tag is one of LC.DOOR_TAGS, or nil to clear. Returns ok, previousTag.
function LC.SetDoorTag(door, tag)
    local id = door:MapCreationID()
    if not id or id < 0 then return false end
    local old = LC.DoorTags[id]
    LC.DoorTags[id] = LC.DOOR_TAGS[tag] and tag or nil
    LC.SaveData()
    if LC.ApplyDoorState then LC.ApplyDoorState(door) end
    return true, old
end

------------------------------------------------------------------------

hook.Add("InitPostEntity", "LivingCityLoadData", function() LC.LoadData(true) end)

-- Lua refresh while a map is running: reload once every file is back.
if #ents.GetAll() > 1 then
    timer.Simple(0, function() if LC.LoadData then LC.LoadData(false) end end)
end

concommand.Add("lc_reload", function(ply)
    if not LC.CanEdit(ply) then return end
    LC.LoadData(true)
    if LC.ApplyAllDoors then LC.ApplyAllDoors() end
    local msg = string.format("[Miscount] Reloaded layout: %d points, %d path nodes, %d zones, %d tagged doors.",
        #LC.Points, table.Count(LC.Nodes), #LC.Zones, table.Count(LC.DoorTags))
    if IsValid(ply) then ply:ChatPrint(msg) else print(msg) end
end)

local function Reply(ply, msg) if IsValid(ply) then ply:ChatPrint(msg) else print(msg) end end

concommand.Add("lc_backup", function(ply)
    if not LC.CanEdit(ply) then return end
    local name = LC.BackupLayout("manual")
    Reply(ply, name and ("[Miscount] Backed up the layout as " .. name .. ".") or "[Miscount] Nothing to back up yet.")
end)

concommand.Add("lc_backups", function(ply)
    if not LC.CanEdit(ply) then return end
    local all = LC.ListBackups()
    Reply(ply, string.format("[Miscount] Layout: data/%s. %d backups in data/%s/:", Path(), #all, BackupDir()))
    for i = 1, math.min(10, #all) do Reply(ply, string.format("  %d. %s", i, all[i])) end
    if #all > 0 then Reply(ply, "Restore one with lc_restore <number>. What's there now is backed up first.") end
end)

concommand.Add("lc_restore", function(ply, _, args)
    if not LC.CanEdit(ply) then return end
    local ok, what = LC.RestoreBackup(args[1])
    Reply(ply, ok and ("[Miscount] Restored " .. what .. ".") or ("[Miscount] " .. what))
end)

concommand.Add("lc_savesettings", function(ply)
    if not LC.CanEdit(ply) then return end
    LC.SaveSettings()
    local msg = "[Miscount] Population settings saved for " .. game.GetMap() .. "."
    if IsValid(ply) then ply:ChatPrint(msg) else print(msg) end
end)

concommand.Add("lc_autolink", function(ply, _, args)
    if not LC.CanEdit(ply) then return end
    local n = LC.AutoLink(tonumber(args[1]) or 450)
    LC.SaveData()
    local orphans = #LC.OrphanNodes()
    local msg = string.format("[Miscount] Made %d new links.%s", n,
        orphans > 0 and string.format(" %d nodes still have no links (shown in red).", orphans) or "")
    if IsValid(ply) then ply:ChatPrint(msg) else print(msg) end
end)

-- The editor's "Go": take an editor to the nth of a kind of thing in the layout
-- (in the same order the layout browser lists them).
concommand.Add("lc_goto_layout", function(ply, _, args)
    if not IsValid(ply) or not LC.CanEdit(ply) then return end
    local id, n = tostring(args[1] or ""), math.max(1, math.floor(tonumber(args[2]) or 1))
    local list = {}
    if id == "node" then
        local ids = table.GetKeys(LC.Nodes)
        table.sort(ids)
        for _, k in ipairs(ids) do list[#list + 1] = LC.Nodes[k].pos end
    elseif string.StartWith(id, "zone_") then
        local k = string.sub(id, 6)
        for _, z in ipairs(LC.Zones) do if z.kind == k then list[#list + 1] = z.pos end end
    elseif string.StartWith(id, "door_") then
        local k = string.sub(id, 6)
        local doors = {}
        for mid, tag in pairs(LC.DoorTags) do
            local e = ents.GetMapCreatedEntity(mid)
            if tag == k and IsValid(e) then doors[#doors + 1] = e end
        end
        table.sort(doors, function(a, b) return a:EntIndex() < b:EntIndex() end)
        for _, e in ipairs(doors) do list[#list + 1] = e:GetPos() + e:GetForward() * 60 end
    elseif string.StartWith(id, "work_") then
        local job = LCJ and LCJ.ById and LCJ.ById[string.sub(id, 6)]
        for _, p in ipairs(LC.Points) do if job and p.kind == "work" and p.group == job.num then list[#list + 1] = p.pos end end
    elseif id == "prop" then
        for _, r in ipairs(LC.Props or {}) do list[#list + 1] = r.pos + Vector(60, 0, 0) end
    else
        for _, p in ipairs(LC.Points) do if p.kind == id then list[#list + 1] = p.pos end end
    end
    if #list == 0 then return ply:ChatPrint("[Miscount] None of those on this map.") end
    n = (n - 1) % #list + 1
    local pos = list[n]
    if ply.SetMoveType and ply:GetMoveType() ~= MOVETYPE_NOCLIP then ply:SetMoveType(MOVETYPE_NOCLIP) end
    ply:SetPos(pos + Vector(0, 0, 24) - ply:GetForward() * 40)
    ply:ChatPrint(string.format("[Miscount] %s %d of %d. (You're in noclip; it's easy to land inside things.)", id, n, #list))
end)

------------------------------------------------------------------------
-- The editor panel's settings (lua/weapons/gmod_tool/stools/livingcity_editor.lua):
-- on a hosted server a player's game can't set the server's convars itself,
-- so the panel asks, and the server checks they're allowed to.
------------------------------------------------------------------------

util.AddNetworkString("lc_setting")
util.AddNetworkString("lc_settings_get")
util.AddNetworkString("lc_settings")


local function SendSettings(ply, names)
    local out = {}
    for i, name in ipairs(names) do
        if i > 200 then break end
        if OurSetting(name) then out[name] = GetConVar(name):GetString() end
    end
    net.Start("lc_settings")
    net.WriteTable(out)
    net.Send(ply)
end

net.Receive("lc_settings_get", function(_, ply)
    if not IsValid(ply) or not LC.CanEdit(ply) then return end
    local names = net.ReadTable()
    if istable(names) then SendSettings(ply, names) end
end)

net.Receive("lc_setting", function(_, ply)
    if not IsValid(ply) or not LC.CanEdit(ply) then return end
    local name, value = net.ReadString(), net.ReadString()
    if not OurSetting(name) or not tonumber(value) then return end
    RunConsoleCommand(name, value)
    LC.RememberSetting(name, value)
    LC.Log("info", string.format("%s set %s to %s", ply:Nick(), name, value))
    timer.Simple(0.1, function() if IsValid(ply) then SendSettings(ply, { name }) end end)
end)

