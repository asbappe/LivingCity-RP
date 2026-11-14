--[[
    Living City (client)

      - Editor overlay: points, path nodes and links, zones, door tags, live NPC
        states and routes, test walker routes. Shown while holding the Living
        City Editor (or always with lc_show 1).
      - HUD for everyone: custody countdown, wanted status, spawn protection,
        city events, and directions home during curfew.
      - City announcements.
      - Debug report viewer with a Copy button.
      - Forwards Living City Lua errors to the server log.
]]

LC_CL = LC_CL or { points = {}, nodes = {}, zones = {}, doors = {}, blocks = {} }

------------------------------------------------------------------------
-- The view through a mask's lenses, or a scanner's eye: tinted, dark at the
-- edges, and scanlines. The scanlines are drawn once into a texture (per
-- screen size) and laid over the screen in one go, instead of a few hundred
-- thin rectangles every frame. (cl_livingcity_cp.lua, cl_livingcity_scanner.lua)
------------------------------------------------------------------------

local gradU, gradD, gradL, gradR = Material("vgui/gradient-u"), Material("vgui/gradient-d"), Material("vgui/gradient-l"), Material("vgui/gradient-r")
local lines = { w = 0, h = 0 }
local function ScanlineMaterial(w, h)
    if lines.mat and lines.w == w and lines.h == h then return lines.mat end
    if lines.failed or not GetRenderTarget or not CreateMaterial then return nil end
    local pushed, started = false, false
    local ok = pcall(function()
        local name = "lc_scanlines_" .. w .. "x" .. h
        local rt = GetRenderTarget(name, w, h)
        render.PushRenderTarget(rt)
        pushed = true
        render.Clear(0, 0, 0, 255, true, true)
        cam.Start2D()
        started = true
        surface.SetDrawColor(255, 255, 255, 255)
        for y = 0, h, 4 do surface.DrawRect(0, y, w, 1) end
        cam.End2D()
        started = false
        render.PopRenderTarget()
        pushed = false
        lines.mat = CreateMaterial(name, "UnlitGeneric", {
            ["$basetexture"] = rt:GetName(), ["$additive"] = "1", ["$vertexcolor"] = "1", ["$vertexalpha"] = "1",
        })
        lines.w, lines.h = w, h
    end)
    -- (an error halfway mustn't leave the HUD drawing into the texture)
    if started then cam.End2D() end
    if pushed then render.PopRenderTarget() end
    if not ok then lines.failed = true return nil end
    return lines.mat
end

-- tint, edge and line: { r, g, b, a }
function LC_CL.DrawLens(w, h, tint, edge, line)
    local e = math.floor(math.min(w, h) * 0.14)
    surface.SetDrawColor(tint[1], tint[2], tint[3], tint[4])
    surface.DrawRect(0, 0, w, h)
    surface.SetDrawColor(edge[1], edge[2], edge[3], edge[4])
    surface.SetMaterial(gradU) surface.DrawTexturedRect(0, 0, w, e)
    surface.SetMaterial(gradD) surface.DrawTexturedRect(0, h - e, w, e)
    surface.SetMaterial(gradL) surface.DrawTexturedRect(0, 0, e, h)
    surface.SetMaterial(gradR) surface.DrawTexturedRect(w - e, 0, e, h)
    surface.SetDrawColor(line[1], line[2], line[3], line[4])
    local mat = ScanlineMaterial(w, h)
    if mat then
        surface.SetMaterial(mat)
        surface.DrawTexturedRect(0, 0, w, h)
    else
        for y = 0, h, 4 do surface.DrawRect(0, y, w, 1) end
    end
end

local cvShow  = CreateClientConVar("lc_show", "0", true, false, "Always show the Miscount layout")
local cvDebug = CreateClientConVar("lc_show_npcs", "1", true, false, "Show what the NPC you're looking at is doing, in the editor overlay")
local cvAllNpcs = CreateClientConVar("lc_show_all_npcs", "0", true, false, "Show every nearby NPC's state and destination (cluttered)")
local cvFill  = CreateClientConVar("lc_zone_fill", "1", true, false, "Shade zones on the ground in the editor")
local cvMarkers = CreateClientConVar("lc_editor_markers", "1", true, false, "Show the editor's markers at all (0: hide them all)")
local cvXray = CreateClientConVar("lc_editor_xray", "1", true, false, "See the editor's markers through walls (0: only what's in sight)")
-- lines and boxes: drawn over everything, or hidden behind walls like anything else
local function Z() return not cvXray:GetBool() end
-- in sight from where you stand (for the labels, when not seeing through walls); kept a moment
local seenCache = {}
local function InSight(pos)
    if cvXray:GetBool() then return true end
    local key = math.floor(pos.x / 16) .. ":" .. math.floor(pos.y / 16) .. ":" .. math.floor(pos.z / 16)
    local c = seenCache[key]
    local now = CurTime()
    if c and c.t > now then return c.v end
    local eye = EyePos()
    local tr = util.TraceLine({ start = eye, endpos = pos, mask = MASK_SOLID_BRUSHONLY, filter = LocalPlayer() })
    local v = not tr.Hit or tr.HitPos:DistToSqr(pos) < 24 * 24
    seenCache[key] = { v = v, t = now + 0.5 }
    return v
end

local function ReadCompressed()
    local len = net.ReadUInt(32)
    local data = net.ReadData(len)
    local json = util.Decompress(data or "")
    return json and util.JSONToTable(json) or nil
end

------------------------------------------------------------------------
-- Colors and names
------------------------------------------------------------------------

local POINT_COLORS = {
    jogroute = Color(120, 230, 160), yard = Color(255, 210, 90), parade = Color(240, 120, 200), waymark = Color(232, 145, 42),
    idle = Color(90, 220, 120), sit = Color(60, 200, 200), sitchair = Color(60, 170, 220), lean = Color(120, 230, 230),
    queue = Color(240, 200, 60), patrol = Color(80, 150, 255), checkpoint = Color(255, 80, 80),
    spawn = Color(240, 240, 240), cell = Color(255, 140, 40), release = Color(255, 200, 140),
    work = Color(200, 150, 100), vending = Color(90, 170, 230), dispenser = Color(200, 200, 120),
    terminal = Color(230, 180, 90), stove = Color(230, 110, 60), fire = Color(255, 120, 40), dealer = Color(150, 110, 190), locker = Color(120, 150, 170), evidlocker = Color(110, 140, 200), screen = Color(110, 190, 230), lawboard = Color(200, 200, 220), cpfeed = Color(92, 200, 216), rebelboard = Color(210, 120, 90), interrochair = Color(240, 230, 190), rebelcage = Color(170, 150, 120), console = Color(120, 210, 200), workbench = Color(190, 150, 100), recycler = Color(140, 200, 240), bin = Color(140, 160, 90), salvage = Color(170, 140, 110), ladder = Color(230, 230, 120), sspawn = Color(255, 90, 80), dataterm = Color(90, 200, 255), rlookout = Color(235, 150, 70), bunk = Color(200, 140, 90), masterterm = Color(120, 230, 255), lz = Color(70, 140, 255), citybin = Color(140, 160, 90), streetlight = Color(255, 220, 140), loudspeaker = Color(200, 200, 200), screen_big = Color(110, 190, 230), tv = Color(110, 190, 230), incinerator = Color(255, 110, 40), hazbarrel = Color(220, 190, 40), dock = Color(180, 160, 120), graffiti = Color(200, 120, 220), rubble = Color(150, 130, 110), pipe = Color(120, 170, 200), studio = Color(110, 190, 230), desk = Color(170, 120, 230), adminpower = Color(190, 140, 255), suppressor = Color(120, 200, 255), platform = Color(200, 180, 120), intake = Color(120, 200, 255), housingterm = Color(150, 210, 170), laborterm = Color(210, 190, 120), cpsupply = Color(100, 170, 255), conveyor = Color(200, 170, 90), bed = Color(170, 150, 210), toilet = Color(220, 220, 230), bath = Color(150, 200, 230), arrival = Color(230, 220, 160), transformer = Color(120, 200, 255), forcefield = Color(80, 160, 255), powerbank = Color(90, 190, 255), turret = Color(255, 90, 80), barricade_low = Color(150, 160, 175), barricade = Color(150, 160, 175), barricade_tall = Color(150, 160, 175),
    zspawn = Color(170, 220, 40), rspawn = Color(230, 150, 70),
    infodesk = Color(120, 190, 240), civposter = Color(210, 210, 160),
    dream = Color(200, 160, 255), -- (the shared dreams: sv_livingcity_dreams.lua)
    sterm = Color(150, 200, 255), -- (a Combine zone's stalker works a terminal here)
    speechcrowd = Color(230, 200, 120), -- (where the city gathers for her address: sv_livingcity_speech.lua)
}
local POINT_NAMES = {
    jogroute = "JOGGING ROUTE", yard = "EXERCISE YARD", parade = "PARADE ROUTE", waymark = "WAY MARK", dream = "DREAM POINT", sterm = "STALKER TERMINAL", speechcrowd = "SPEECH CROWD",
    idle = "LOITER", sit = "SIT", sitchair = "BENCH", lean = "LEAN", queue = "LINE", patrol = "PATROL",
    checkpoint = "CHECKPOINT", spawn = "SPAWN/EXIT", cell = "CELL", release = "RELEASE",
    work = "WORKPLACE", vending = "VENDING", dispenser = "RATIONS", terminal = "COMMISSARY", stove = "STOVE", fire = "FIRE",
    dealer = "DEALER", locker = "LOCKER", evidlocker = "EVIDENCE LOCKER", screen = "CITY SCREEN", lawboard = "LAW BOARD", cpfeed = "CP INCIDENT FEED", rebelboard = "RESISTANCE NOTICE BOARD", interrochair = "INTERROGATION CHAIR", rebelcage = "HOLDING CAGE", infodesk = "CITIZEN INFORMATION", civposter = "CIVIL NOTICE", console = "SCANNER CONSOLE", workbench = "RESISTANCE LAB", cpsupply = "CP COMMISSARY", conveyor = "CONVEYOR", bed = "BED", toilet = "TOILET", bath = "BATHTUB", recycler = "RECLAMATION", bin = "BIN", salvage = "SALVAGE PILE", ladder = "LADDER", sspawn = "SCANNER LAUNCH", dataterm = "DATA TERMINAL", rlookout = "REBEL LOOKOUT", bunk = "BUNK", masterterm = "MASTER TERMINAL", lz = "LANDING ZONE", citybin = "BIN", streetlight = "STREETLIGHT", loudspeaker = "LOUDSPEAKER", screen_big = "BIG SCREEN", tv = "TV", incinerator = "INCINERATOR", hazbarrel = "INFESTATION BARREL", dock = "LOADING DOCK", graffiti = "GRAFFITI WALL", rubble = "RUBBLE", pipe = "LEAKY PIPE", studio = "BROADCAST STUDIO", desk = "ADMINISTRATOR'S DESK", adminpower = "HER POWER (TRANSFORMER)", suppressor = "SUPPRESSION DEVICE", platform = "TRAIN PLATFORM", intake = "CIVIL INTAKE", housingterm = "HOUSING ALLOCATION", laborterm = "LABOR ASSIGNMENT", arrival = "ARRIVAL", transformer = "TRANSFORMER", forcefield = "FORCEFIELD", powerbank = "POWER BANK", turret = "TURRET", barricade_low = "BARRICADE (LOW)", barricade = "BARRICADE", barricade_tall = "BARRICADE (TALL)", zspawn = "ZOMBIE SPAWN", rspawn = "REBEL SPAWN",
}
LC_CL.PointColor = function(k) return POINT_COLORS[k] end
LC_CL.PointName = function(k)
    if POINT_NAMES[k] then return POINT_NAMES[k] end
    local z = string.match(k, "^zone_(.+)$")
    if z then return "ZONE " .. string.upper(z) end
    local d = string.match(k, "^door_(.+)$")
    if d then return "DOOR " .. string.upper(d) end
    return k
end
local ZONE_COLORS = {
    nogo = Color(255, 60, 60), infest = Color(170, 220, 40), prison = Color(255, 140, 40),
    block = Color(180, 120, 255), rebel = Color(230, 150, 70), combine = Color(70, 140, 255),
    dream = Color(200, 160, 255),
}
LC_CL.ZONE_COLORS = ZONE_COLORS
local ZONE_NAMES = { nogo = "NO-GO", infest = "INFESTATION", prison = "PRISON", block = "BLOCK", rebel = "REBEL TERRITORY", combine = "COMBINE ONLY", dream = "DREAM" }
local DOOR_COLORS = {
    cp = Color(80, 150, 255), prison = Color(255, 140, 40), locked = Color(255, 70, 70), open = Color(90, 220, 120),
    ignore = Color(160, 160, 160), force = Color(240, 200, 60), rent = Color(120, 200, 160),
}
local DOOR_LABELS = { cp = "CP ONLY", prison = "PRISON DOOR", locked = "LOCKED", open = "ALWAYS OPEN", ignore = "NPCS IGNORE", force = "FORCED DOOR", rent = "FOR RENT", office = "ADMINISTRATOR'S OFFICE" }
local LINK_COLOR, NODE_COLOR, ORPHAN_COLOR, SELECT_COLOR = Color(0, 200, 255), Color(0, 160, 255), Color(255, 50, 50), Color(255, 230, 0)

local function BlockName(n)
    local cv = GetConVar("lc_block_name")
    local ok, s = pcall(string.format, GetGlobal2String("lc_block_name", "") ~= "" and GetGlobal2String("lc_block_name", "") or (cv and cv:GetString()) or "Habitation Block %02d", n)
    return ok and s or ("Block " .. n)
end

------------------------------------------------------------------------
-- Data from the server
------------------------------------------------------------------------

net.Receive("lc_data", function()
    local t = ReadCompressed() or {}
    LC_CL.points = {}
    for i, p in ipairs(t.points or {}) do
        LC_CL.points[i] = { pos = Vector(p.x, p.y, p.z), yaw = p.yaw or 0, kind = p.kind, group = p.group or 0 }
    end
    LC_CL.nodes = {}
    local degree = {}
    for _, n in ipairs(t.nodes or {}) do
        LC_CL.nodes[n.id] = { id = n.id, pos = Vector(n.x, n.y, n.z), links = n.l or {} }
        degree[n.id] = degree[n.id] or 0
        for _, other in ipairs(n.l or {}) do
            degree[n.id] = degree[n.id] + 1
            degree[other] = (degree[other] or 0) + 1
        end
    end
    for id, n in pairs(LC_CL.nodes) do n.orphan = (degree[id] or 0) == 0 end
    LC_CL.zones = {}
    for i, z in ipairs(t.zones or {}) do
        LC_CL.zones[i] = { pos = Vector(z.x, z.y, z.z), r = z.r, h = z.h, kind = z.kind, group = z.group or 0, box = LCZ and LCZ.UnpackBox(z.box) or nil,
            grown = z.grown }
        if z.ground and LCZ and LCZ.UnpackGround then LCZ.UnpackGround(z.ground, LC_CL.zones[i]) end
    end
    LC_CL.doors = t.doors or {}
    LC_CL.props = {}
    for i, p in ipairs(t.props or {}) do LC_CL.props[i] = { pos = Vector(p.x, p.y, p.z), model = p.model } end

    -- sequences: ration lines and patrol beats, in placement order
    LC_CL.sequences = {}
    local index = {}
    for _, p in ipairs(LC_CL.points) do
        if ((p.kind == "queue" or p.kind == "patrol") and p.group > 0) or p.kind == "jogroute" or p.kind == "parade" then
            local key = p.kind .. p.group
            if not index[key] then
                index[key] = { kind = p.kind, group = p.group, pts = {} }
                LC_CL.sequences[#LC_CL.sequences + 1] = index[key]
            end
            table.insert(index[key].pts, p)
            p.order = #index[key].pts
        end
    end
end)

net.Receive("lc_public", function()
    local t = ReadCompressed() or {}
    LC_CL.blocks = {}
    for _, b in ipairs(t.blocks or {}) do
        LC_CL.blocks[#LC_CL.blocks + 1] = { n = b.n, pos = Vector(b.x, b.y, b.z), r = b.r, box = LCZ and LCZ.UnpackBox(b.box) or nil }
    end
    LC_CL.territory = {}
    for _, z in ipairs(t.territory or {}) do
        local tz = { kind = z.k, pos = Vector(z.x, z.y, z.z), r = z.r, h = z.h, box = LCZ and LCZ.UnpackBox(z.box) or nil }
        if z.ground and LCZ and LCZ.UnpackGround then LCZ.UnpackGround(z.ground, tz) end
        LC_CL.territory[#LC_CL.territory + 1] = tz
    end
end)

net.Receive("lc_select", function()
    LC_CL.selected = net.ReadUInt(32)
end)

net.Receive("lc_route", function()
    local t = ReadCompressed() or {}
    local pts = {}
    for _, p in ipairs(t.pts or {}) do pts[#pts + 1] = Vector(p[1], p[2], p[3]) end
    LC_CL.route = { pts = pts, stuck = t.stuck and Vector(t.stuck[1], t.stuck[2], t.stuck[3]), untilT = CurTime() + 25 }
end)

------------------------------------------------------------------------
-- Overlay
------------------------------------------------------------------------

local function HoldingEditor()
    local ply = LocalPlayer()
    if not IsValid(ply) then return false end
    local wep = ply:GetActiveWeapon()
    return IsValid(wep) and wep:GetClass() == "gmod_tool" and wep.GetMode and wep:GetMode() == "livingcity_editor"
end

-- With the markers hidden, holding the editor still shows what the tool in hand places (Focus).
local function Visible() return (cvShow:GetBool() or HoldingEditor()) and (cvMarkers:GetBool() or HoldingEditor()) end

local wasVisible = false
local npcCache, nextNpcScan = {}, 0
hook.Add("Think", "LivingCityOverlay", function()
    local vis = Visible()
    if vis and not wasVisible then
        net.Start("lc_request")
        net.SendToServer()
    end
    wasVisible = vis
    if vis and CurTime() > nextNpcScan then
        nextNpcScan = CurTime() + 1
        npcCache = {}
        for _, e in ipairs(ents.GetAll()) do
            if e:IsNPC() and e:GetNW2String("lc_role", "") ~= "" then npcCache[#npcCache + 1] = e end
        end
    end
end)

local MAX_DIST2 = 1800 * 1800 -- the overlay only draws what's reasonably close

-- The NPC you're pointing at (within a body's width of your aim line), if any.
local function AimedNpc()
    local ply = LocalPlayer()
    local eye, dir = EyePos(), ply:GetAimVector()
    local best, bd
    for _, e in ipairs(npcCache) do
        if IsValid(e) then
            local to = e:GetPos() + Vector(0, 0, 40) - eye
            local along = to:Dot(dir)
            if along > 0 and along < 1500 then
                local off = (to - dir * along):Length()
                if off < 45 and (not bd or off < bd) then best, bd = e, off end
            end
        end
    end
    return best
end

-- Which NPCs get a state label and a destination line.
local function ShownNpcs(eye)
    if cvAllNpcs:GetBool() then
        local out = {}
        for _, e in ipairs(npcCache) do
            if IsValid(e) and e:GetPos():DistToSqr(eye) < 600 * 600 then out[#out + 1] = e end
        end
        return out
    end
    if not cvDebug:GetBool() then return {} end
    local e = AimedNpc()
    return e and { e } or {}
end
local UP8, UP60 = Vector(0, 0, 8), Vector(0, 0, 60)

local function Circle(center, r, col)
    local seg = 32
    local prev
    for i = 0, seg do
        local a = (i / seg) * math.pi * 2
        local p = center + Vector(math.cos(a) * r, math.sin(a) * r, 4)
        if prev then render.DrawLine(prev, p, col, true) end
        prev = p
    end
end

------------------------------------------------------------------------
-- Zones shaded on the ground. The disc is draped over the terrain (one
-- trace per vertex, worked out once per zone), so it follows slopes, steps
-- and curbs instead of floating or sinking into them.
------------------------------------------------------------------------

local FILL_MAT = CreateMaterial("lc_zonefill", "UnlitGeneric", {
    ["$basetexture"] = "color/white", ["$vertexcolor"] = 1, ["$vertexalpha"] = 1,
    ["$translucent"] = 1, ["$nocull"] = 1,
})

local function GroundZ(x, y, z)
    local tr = util.TraceLine({ start = Vector(x, y, z + 64), endpos = Vector(x, y, z - 256), mask = MASK_SOLID_BRUSHONLY })
    if tr.Hit and not tr.StartSolid then return tr.HitPos.z + 3 end
    return z + 3
end

local function Drape(center, r, fine)
    local segs = math.Clamp(math.floor(r / (fine and 12 or 20)), 20, fine and 64 or 40)
    local rings = math.Clamp(math.floor(r / (fine and 70 or 120)), 2, fine and 10 or 6)
    local d = { center = Vector(center.x, center.y, GroundZ(center.x, center.y, center.z)), rings = {}, segs = segs }
    for i = 1, rings do
        local rr = r * i / rings
        local ring = {}
        for j = 1, segs do
            local a = (j - 1) / segs * math.pi * 2
            local x, y = center.x + math.cos(a) * rr, center.y + math.sin(a) * rr
            ring[j] = Vector(x, y, GroundZ(x, y, center.z))
        end
        d.rings[i] = ring
    end
    return d
end

local function ZoneDrape(z)
    if not z.drape then z.drape = Drape(z.pos, z.r, true) end
    return z.drape
end

local function DrawFill(d, col, alpha)
    local segs, rings = d.segs, d.rings
    render.SetMaterial(FILL_MAT)
    mesh.Begin(MATERIAL_TRIANGLES, segs + (#rings - 1) * segs * 2)
    local ok = pcall(function()
        local function V(p) mesh.Position(p) mesh.Color(col.r, col.g, col.b, alpha) mesh.AdvanceVertex() end
        local first = rings[1]
        for j = 1, segs do
            local k = j % segs + 1
            V(d.center) V(first[j]) V(first[k])
        end
        for i = 2, #rings do
            local a, b = rings[i - 1], rings[i]
            for j = 1, segs do
                local k = j % segs + 1
                V(a[j]) V(b[j]) V(b[k])
                V(a[j]) V(b[k]) V(a[k])
            end
        end
    end)
    mesh.End()
    return ok
end

local EDGE_UP = Vector(0, 0, 1) -- (made once, not for every segment of every frame)
local function DrawEdge(d, col, thick)
    local ring = d.rings[#d.rings]
    if thick then
        render.SetMaterial(FILL_MAT)
        for j = 1, d.segs do
            render.DrawBeam(ring[j] + EDGE_UP, ring[j % d.segs + 1] + EDGE_UP, 5, 0, 1, col)
        end
    else
        for j = 1, d.segs do render.DrawLine(ring[j], ring[j % d.segs + 1], col, true) end
    end
end

------------------------------------------------------------------------
-- What the editor is aiming at: the same thing a right click would remove
------------------------------------------------------------------------

local ZONE_MODE_KIND = { zone_nogo = "nogo", zone_rebel = "rebel", zone_block = "block", zone_prison = "prison", zone_infest = "infest", zone_combine = "combine" }

local function EditorMode()
    local cv = GetConVar("livingcity_editor_mode")
    return cv and cv:GetString() or "idle"
end

-- "Show the editor's markers" off: holding the editor shows only the markers of the tool in hand
-- (that kind of zone, that kind of point, or the path nodes). nil: show everything.
local function Focus()
    if cvMarkers:GetBool() or not HoldingEditor() then return nil end
    local m = EditorMode()
    if ZONE_MODE_KIND[m] then return { zone = ZONE_MODE_KIND[m] } end
    if m == "node" then return { node = true } end
    if string.StartWith(m, "work_") then return { point = "work" } end
    return { point = m }
end
local function Shown(f, kind, what)
    if not f then return true end
    if what == "zone" then return f.zone == kind end
    if what == "node" then return f.node == true end
    return f.point == kind
end

-- mirrors LC.ZoneForEditing on the server
local function ZoneForEditing(pos)
    local best, bd
    for _, z in ipairs(LC_CL.zones) do
        local dx, dy = pos.x - z.pos.x, pos.y - z.pos.y
        local d2 = dx * dx + dy * dy
        if d2 < 48 * 48 and math.abs(pos.z - z.pos.z) < 128 and (not bd or d2 < bd) then best, bd = z, d2 end
    end
    if best then return best end
    for _, z in ipairs(LC_CL.zones) do
        if LCZ.Contains(z, pos) and (not best or z.r < best.r) then best = z end
    end
    return best
end

local function NearestPoint(pos)
    local best, bd
    for _, p in ipairs(LC_CL.points) do
        local d = p.pos:DistToSqr(pos)
        if d < 64 * 64 and (not bd or d < bd) then best, bd = p, d end
    end
    return best
end

local function NearestNode(pos)
    local best, bd
    for _, n in pairs(LC_CL.nodes) do
        local d = n.pos:DistToSqr(pos)
        if d < 64 * 64 and (not bd or d < bd) then best, bd = n, d end
    end
    return best
end

local aimed -- { kind = "zone" | "point" | "node", it = ... }, refreshed every frame while holding the editor
local function UpdateAim()
    aimed = nil
    if not HoldingEditor() then return end
    local tr = LocalPlayer():GetEyeTrace()
    if not tr.Hit then return end
    local mode = EditorMode()
    local finders = {
        zone = function() local z = ZoneForEditing(tr.HitPos) return z and { kind = "zone", it = z } end,
        point = function() local p = NearestPoint(tr.HitPos) return p and { kind = "point", it = p } end,
        node = function() local n = NearestNode(tr.HitPos) return n and { kind = "node", it = n } end,
    }
    local order = string.StartWith(mode, "zone_") and { "zone", "point", "node" }
        or (mode == "node" and { "node", "point", "zone" } or { "point", "node", "zone" })
    for _, k in ipairs(order) do
        aimed = finders[k]()
        if aimed then return end
    end
end

local preview -- the shaded disc for a zone about to be placed: { key, drape }

-- (made once here, not every frame)
local C_255_0_0_120 = Color(255, 0, 0, 120)
local C_255_255_255 = Color(255, 255, 255)
local C_255_255_255_120 = Color(255, 255, 255, 120)
local C_255_255_255_200 = Color(255, 255, 255, 200)
local C_255_255_255_220 = Color(255, 255, 255, 220)
local C_255_255_255_90 = Color(255, 255, 255, 90)
local V_0_0_2 = Vector(0, 0, 2)
local V_0_0_36 = Vector(0, 0, 36)
local V_10_10_22 = Vector(10, 10, 22)
local V_6_6_14 = Vector(6, 6, 14)
local V_8_8_16 = Vector(8, 8, 16)
local V_m10_m10_0 = Vector(-10, -10, 0)
local V_m6_m6_0 = Vector(-6, -6, 0)
local V_m8_m8_0 = Vector(-8, -8, 0)
hook.Add("PostDrawTranslucentRenderables", "LivingCityOverlay", function(_, skybox)
    if skybox or LC_CL.LiveCamRendering then return end -- (not in the broadcast picture on the city's screens)
    local eye = EyePos()

    -- test walker route (shown to whoever ran the test, even after putting the tool away)
    local route = LC_CL.route
    if route and CurTime() < route.untilT then
        render.SetColorMaterial()
        for i = 2, #route.pts do render.DrawLine(route.pts[i - 1] + UP8, route.pts[i] + UP8, C_255_255_255, false) end
        for _, p in ipairs(route.pts) do render.DrawSphere(p + UP8, 5, 8, 8, C_255_255_255_200) end
        if route.stuck then render.DrawSphere(route.stuck + V_0_0_36, 18, 12, 12, C_255_0_0_120) end
    end

    if not Visible() then return end
    render.SetColorMaterial()

    UpdateAim()
    local focus = Focus()
    local aimZone = aimed and aimed.kind == "zone" and aimed.it or nil
    local aimPoint = aimed and aimed.kind == "point" and aimed.it or nil
    local aimNode = aimed and aimed.kind == "node" and aimed.it or nil

    for _, p in ipairs(LC_CL.points) do
        if p.pos:DistToSqr(eye) < MAX_DIST2 and Shown(focus, p.kind, "point") then
            local col = POINT_COLORS[p.kind] or color_white
            local base = p.pos + V_0_0_2
            if p == aimPoint then
                local pulse = 10 + math.sin(CurTime() * 6) * 2
                render.DrawSphere(base + UP8, pulse, 16, 16, Color(col.r, col.g, col.b, 240))
                render.DrawWireframeSphere(base + UP8, 64, 16, 8, C_255_255_255_90, true)
                render.SetColorMaterial()
            else
                render.DrawSphere(base + UP8, 7, 12, 12, Color(col.r, col.g, col.b, 180))
            end
            render.DrawLine(base, base + UP60, col, Z())
            render.DrawLine(base + UP8, base + UP8 + Angle(0, p.yaw, 0):Forward() * 36, col, Z())
        end
    end

    for _, seq in ipairs(LC_CL.sequences or {}) do
        local col = POINT_COLORS[seq.kind]
        local near = false
        for _, sp in ipairs(seq.pts) do if sp.pos:DistToSqr(eye) < 1500 * 1500 then near = true break end end
        if not Shown(focus, seq.kind, "point") then near = false end
        if near then
            for i = 2, #seq.pts do render.DrawLine(seq.pts[i - 1].pos + UP8, seq.pts[i].pos + UP8, col, Z()) end
            if seq.kind == "patrol" and #seq.pts > 2 then
                render.DrawLine(seq.pts[#seq.pts].pos + UP8, seq.pts[1].pos + UP8, Color(col.r, col.g, col.b, 90), Z())
            end
        end
    end

    for id, n in pairs(LC_CL.nodes) do
        if n.pos:DistToSqr(eye) < MAX_DIST2 and Shown(focus, nil, "node") then
            local col = (LC_CL.selected == id) and SELECT_COLOR or (n.orphan and ORPHAN_COLOR or NODE_COLOR)
            if n == aimNode then
                render.DrawWireframeBox(n.pos, angle_zero, V_m10_m10_0, V_10_10_22, color_white, Z())
            end
            render.DrawWireframeBox(n.pos, angle_zero, V_m6_m6_0, V_6_6_14, col, Z())
            for _, other in ipairs(n.links) do
                local o = LC_CL.nodes[other]
                if o then render.DrawLine(n.pos + UP8, o.pos + UP8, LINK_COLOR, Z()) end
            end
        end
    end

    -- zones: every zone faintly shaded, the one you're aiming at filled in
    -- strongly with a bold edge, and the others dimmed so it stands out
    local fill = cvFill:GetBool()
    for _, z in ipairs(LC_CL.zones) do
        if z.pos:DistToSqr(eye) < (3000 + z.r) ^ 2 and Shown(focus, z.kind, "zone") then
            local col = ZONE_COLORS[z.kind] or color_white
            local ok = pcall(function()
                if z.rects then
                    -- territory that grew along the path nodes: the rectangles its cells merge into, eight feet tall
                    render.SetColorMaterial()
                    local a = z == aimZone and 60 or (fill and (aimZone and 6 or 16) or 0)
                    local C = LCZ.CELL
                    for _, r in ipairs(z.rects) do
                        local mins, maxs = Vector(r.x0 * C, r.y0 * C, r.lo), Vector((r.x1 + 1) * C, (r.y1 + 1) * C, r.hi)
                        if a > 0 then render.DrawBox(vector_origin, angle_zero, mins, maxs, Color(col.r, col.g, col.b, a), true) end
                        render.DrawWireframeBox(vector_origin, angle_zero, mins, maxs, Color(col.r, col.g, col.b, z == aimZone and 255 or (aimZone and 70 or 230)), Z())
                    end
                    return
                end
                if z.box then
                    -- a box zone: the box itself, shaded, with its edges drawn
                    render.SetColorMaterial()
                    local a = z == aimZone and 60 or (fill and (aimZone and 6 or 16) or 0)
                    if a > 0 then render.DrawBox(vector_origin, angle_zero, z.box.mins, z.box.maxs, Color(col.r, col.g, col.b, a), true) end
                    render.DrawWireframeBox(vector_origin, angle_zero, z.box.mins, z.box.maxs, Color(col.r, col.g, col.b, z == aimZone and 255 or (aimZone and 70 or 230)), Z())
                    return
                end
                local d = ZoneDrape(z)
                if z == aimZone then
                    DrawFill(d, col, 75)
                    DrawEdge(d, Color(col.r, col.g, col.b, 255), true)
                else
                    if fill then DrawFill(d, col, aimZone and 8 or 22) end
                    DrawEdge(d, Color(col.r, col.g, col.b, aimZone and 70 or 230), false)
                end
            end)
            if not ok then Circle(z.pos, z.r, col) end
            render.SetColorMaterial()
            render.DrawSphere(z.pos + UP8, z == aimZone and 10 or 6, 8, 8, Color(col.r, col.g, col.b, 220))
        end
    end

    -- placing a zone: shade where it will go, at the radius on the slider, or
    -- (box shape) the box from the first corner to where you're aiming
    local zoneKind = HoldingEditor() and ZONE_MODE_KIND[EditorMode()]
    local shapeCv = GetConVar("livingcity_editor_shape")
    local boxShape = shapeCv and shapeCv:GetString() == "box"
    if zoneKind and boxShape then
        local tr = LocalPlayer():GetEyeTrace()
        local col = ZONE_COLORS[zoneKind] or color_white
        render.SetColorMaterial()
        if tr.Hit then render.DrawWireframeBox(tr.HitPos, angle_zero, V_m8_m8_0, V_8_8_16, C_255_255_255_220, Z()) end
        if LC_CL.boxCorner and tr.Hit then
            local hcv = GetConVar("livingcity_editor_height")
            local b = LCZ.BoxFromCorners(LC_CL.boxCorner, tr.HitPos, hcv and hcv:GetFloat() or 192)
            render.DrawBox(vector_origin, angle_zero, b.mins, b.maxs, Color(col.r, col.g, col.b, 40), true)
            render.DrawWireframeBox(vector_origin, angle_zero, b.mins, b.maxs, C_255_255_255_220, Z())
        end
        zoneKind = nil
    end
    if zoneKind then
        local tr = LocalPlayer():GetEyeTrace()
        local rcv = GetConVar("livingcity_editor_radius")
        local r = rcv and rcv:GetFloat() or 300
        if tr.Hit and r > 0 then
            local hp = tr.HitPos
            local key = string.format("%d_%d_%d_%d", math.floor(hp.x / 16), math.floor(hp.y / 16), math.floor(hp.z / 16), math.floor(r))
            if not preview or preview.key ~= key then preview = { key = key, drape = Drape(hp, r, false) } end
            local col = ZONE_COLORS[zoneKind] or color_white
            pcall(function()
                DrawFill(preview.drape, col, 45)
                DrawEdge(preview.drape, C_255_255_255_200, true)
            end)
            render.SetColorMaterial()
        end
    end

    for _, d in ipairs(LC_CL.doors) do
        local door = Entity(d.idx)
        if IsValid(door) and door:GetPos():DistToSqr(eye) < MAX_DIST2 then
            render.DrawWireframeBox(door:GetPos(), door:GetAngles(), door:OBBMins(), door:OBBMaxs(), DOOR_COLORS[d.tag] or color_white, Z())
        end
    end

    for _, e in ipairs(ShownNpcs(eye)) do
        if e:GetNW2String("lc_state", "") == "moving" then
            local dest = e:GetNW2Vector("lc_dest", vector_origin)
            if dest ~= vector_origin then render.DrawLine(e:GetPos() + UP8, dest + UP8, C_255_255_255_120, Z()) end
        end
    end
end)

local function Label(pos, text, col, font)
    if not InSight(pos) then return end
    local s = pos:ToScreen()
    if s.visible then
        draw.SimpleTextOutlined(text, font or "DermaDefaultBold", s.x, s.y, col or color_white,
            TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, color_black)
    end
end

local function DrawAimInfo()
    if not aimed then return end
    local text, col
    if aimed.kind == "zone" then
        local z = aimed.it
        local name = ZONE_NAMES[z.kind] or z.kind
        if z.kind == "block" then name = string.upper(BlockName(z.group)) end
        text = string.format("%s   |   radius %d Civil Protection units (about %.1f m across)   |   right click removes", name, z.r, z.r * 2 * 0.019)
        col = ZONE_COLORS[z.kind]
    elseif aimed.kind == "point" then
        local p = aimed.it
        local name = POINT_NAMES[p.kind] or string.upper(p.kind)
        if p.group and p.group > 0 then name = name .. " #" .. p.group end
        text = name .. "   |   right click removes"
        col = POINT_COLORS[p.kind]
    else
        text = string.format("PATH NODE %d   |   %d links   |   right click removes", aimed.it.id, #(aimed.it.links or {}))
        col = NODE_COLOR
    end
    draw.SimpleTextOutlined(text, "DermaDefaultBold", ScrW() / 2, ScrH() / 2 + 34, col or color_white,
        TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, color_black)
end

local function DrawEditorLabels()
    local focus = Focus()
    DrawAimInfo()
    local eye = EyePos()
    local near = 450 * 450 -- text only for what's close; the thing you aim at is named under the crosshair

    for _, p in ipairs(LC_CL.points) do
        if p.pos:DistToSqr(eye) < near and Shown(focus, p.kind, "point") then
            local txt = POINT_NAMES[p.kind] or string.upper(p.kind)
            if p.kind == "queue" and p.group > 0 then txt = string.format("LINE %d  #%d", p.group, p.order or 0)
            elseif p.kind == "queue" then txt = "STAND HERE"
            elseif p.kind == "patrol" and p.group > 0 then txt = string.format("BEAT %d  #%d", p.group, p.order or 0)
            elseif p.kind == "jogroute" then txt = string.format("JOG ROUTE %d  #%d%s", p.group, p.order or 0, p.order == 1 and " (START)" or "")
            elseif p.kind == "parade" then txt = string.format("PARADE ROUTE %d  #%d%s", p.group, p.order or 0, p.order == 1 and " (FORM UP)" or "")
            elseif p.kind == "work" then
                local job = LCJ and LCJ.ByNum[p.group]
                txt = "WORK: " .. string.upper(job and job.place or ("job " .. p.group))
            end
            Label(p.pos + Vector(0, 0, 66), txt, POINT_COLORS[p.kind])
        end
    end
    for id, n in pairs(LC_CL.nodes) do
        if n.orphan and n.pos:DistToSqr(eye) < near and Shown(focus, nil, "node") then Label(n.pos + Vector(0, 0, 22), "UNLINKED", ORPHAN_COLOR) end
    end
    for _, z in ipairs(LC_CL.zones) do
        -- a zone's name floats at its center, but only when you're standing in it
        if LCZ.Contains(z, eye, 0) and Shown(Focus(), z.kind, "zone") then
            local txt = ZONE_NAMES[z.kind] or z.kind
            if z.kind == "block" then txt = string.upper(BlockName(z.group)) end
            Label(z.pos + Vector(0, 0, 30), txt, ZONE_COLORS[z.kind])
        end
    end
    for _, d in ipairs(LC_CL.doors) do
        local door = Entity(d.idx)
        if IsValid(door) and door:WorldSpaceCenter():DistToSqr(eye) < near then
            Label(door:WorldSpaceCenter(), DOOR_LABELS[d.tag] or d.tag, DOOR_COLORS[d.tag])
        end
    end
    -- persistent props (sv_livingcity_props.lua)
    for _, p in ipairs(LC_CL.props or {}) do
        if p.pos:DistToSqr(eye) < near then Label(p.pos + Vector(0, 0, 16), "PERSISTENT PROP", Color(150, 230, 150)) end
    end
    for _, e in ipairs(ShownNpcs(eye)) do
        local who = LC.NPCStr(e, "lc_pname", "")
        Label(e:GetPos() + Vector(0, 0, 84), string.upper(e:GetNW2String("lc_role", "")) .. (who ~= "" and (" " .. who) or "") .. ": " .. e:GetNW2String("lc_state", ""),
            Color(255, 255, 255, 220), "DermaDefault")
    end
end

------------------------------------------------------------------------
-- HUD for everyone
------------------------------------------------------------------------

local banner -- { text, sub, untilT }

-- One voice at a time: lines that arrive while another is still playing wait
-- their turn, instead of talking over each other.
local voiceQueue, voiceBusy = {}, 0
-- The PA comes out of the loudspeakers: next to a broken one, you don't hear it.
local spkCache = { t = -1 }
function LC_CL.SpeakerBrokenNear(pos)
    -- asked every frame by the on-air banner: the answer is kept half a second
    local now = CurTime()
    if now - spkCache.t < 0.5 and spkCache.pos and spkCache.pos:DistToSqr(pos) < 64 * 64 then return spkCache.v end
    local best, bd
    for _, e in ipairs(LC.EntsOf("lc_loudspeaker")) do
        local d = e:GetPos():DistToSqr(pos)
        if d < 2500 * 2500 and (not bd or d < bd) then best, bd = e, d end
    end
    local v = best ~= nil and (best:GetNW2Bool("lc_broken", false) or best:GetNW2Bool("lc_nopower", false))
    spkCache.t, spkCache.pos, spkCache.v = now, pos, v
    return v
end

-- How long a line runs: the longer of what the server worked out and what this
-- game makes of the file itself (either one alone can come out short, and a
-- short guess is a voice talking over the next one).
local function VoiceSecs(path, said, fallback)
    local mine = SoundDuration and SoundDuration(path) or 0
    if not mine or mine <= 0.2 or mine > 120 then mine = 0 end
    if string.lower(string.sub(path or "", -4)) ~= ".wav" then mine = 0 end -- (an MP3's or OGG's own guess is unreliable: the server reads those)
    local d = math.max(said or 0, mine)
    if d <= 0.2 or d > 120 then d = fallback end
    return d
end
LC_CL.VoiceSecs = VoiceSecs

local function PlayNextVoice()
    if CurTime() < voiceBusy or #voiceQueue == 0 then return end
    local v = table.remove(voiceQueue, 1)
    -- the Administrator over the loudspeakers: in turn with Overwatch, never over him
    -- (the server only sends hers to people near a working loudspeaker)
    if v.admin then
        local me = LocalPlayer()
        local vol = LC_CL.BreencastVolume and LC_CL.BreencastVolume() or 0.5
        if LC_CL.SoundTrouble then LC_CL.SoundTrouble(v.path) end
        if vol > 0 and IsValid(me) then
            me:EmitSound(v.path, 0, 100, vol, CHAN_VOICE2)
            LC_CL.lastBreencast = v.path
        end
        voiceBusy = CurTime() + VoiceSecs(v.path, v.dur, 6) + 0.8
        return
    end
    if LC_CL.SpeakerBrokenNear(LocalPlayer():GetPos()) then
        banner = { text = "CITY ANNOUNCEMENT", sub = "(the loudspeaker here is broken)", untilT = CurTime() + 5 }
        voiceBusy = CurTime() + 2
        return
    end
    -- (a stock line's loudspeaker version, "_spkr", missing here: the plain one, if that's here)
    local path = v.path
    if path ~= "" and not file.Exists("sound/" .. path, "GAME") then
        local plain = string.gsub(path, "_spkr%.wav$", ".wav")
        if plain ~= path and file.Exists("sound/" .. plain, "GAME") then path = plain end
    end
    v.path = path
    if v.path == "" then -- (nothing to say aloud: Half-Life 2's voice is off, lc_announce_stock; the banner only)
    elseif file.Exists("sound/" .. v.path, "GAME") then
        surface.PlaySound(v.path)
    elseif string.find(v.path, "^livingcity/") and LC_CL.SoundTrouble then
        LC_CL.SoundTrouble(v.path) -- (one of the server's own recordings: say it's missing here)
    end -- (a stock Half-Life 2 line this install doesn't have: the banner and the words, without the sound)
    local dur = VoiceSecs(v.path, v.dur, 4.5)
    voiceBusy = CurTime() + dur + 0.8
    banner = { text = "CITY ANNOUNCEMENT", sub = v.title, untilT = CurTime() + math.max(7, dur + 1) }
end
-- admin: the Administrator's (over the loudspeakers); dur: how long, if the server knows
LC_CL.QueueVoice = function(path, title, admin, dur)
    if LC_CL.Ending and LC_CL.Ending() then return end -- (the city's announcer is quiet through a secret ending)
    if #voiceQueue >= 5 then table.remove(voiceQueue, 1) end -- never a long backlog
    voiceQueue[#voiceQueue + 1] = { path = path, title = title, admin = admin, dur = dur }
    PlayNextVoice()
end
timer.Create("LivingCityVoiceQueue", 0.25, 0, PlayNextVoice)
LC_CL.ClearVoices = function() voiceQueue = {} end

net.Receive("lc_announce", function()
    local path = net.ReadString()
    local title = net.ReadString()
    local dur = net.ReadFloat and net.ReadFloat() or 0
    LC_CL.QueueVoice(path, title, false, dur)
end)

local BOX_BG = Color(10, 12, 16, 200) -- (made once, not every frame)
local function Box(x, y, w, h, col)
    draw.RoundedBox(6, x, y, w, h, BOX_BG)
    if col then draw.RoundedBox(0, x, y, 4, h, col) end
end

local function MyBlockCenter(n)
    local best, bd
    local me = LocalPlayer():GetPos()
    for _, b in ipairs(LC_CL.blocks or {}) do
        if b.n == n then
            local d = b.pos:DistToSqr(me)
            if not bd or d < bd then best, bd = b, d end
        end
    end
    return best
end

local function InMyBlock(n)
    local me = LocalPlayer():GetPos()
    for _, b in ipairs(LC_CL.blocks or {}) do
        if b.n == n and LCZ.Contains(b, me, LCZ.Mercy()) then return true end
    end
    return false
end

-- (made once here, not every frame)
local V_0_0_80 = Vector(0, 0, 80)
local function DrawHomeMarker(target)
    local s = (target + V_0_0_80):ToScreen()
    local w, h = ScrW(), ScrH()
    local dist = math.floor(LocalPlayer():GetPos():Distance(target) * 0.019) -- about meters
    local col = Color(180, 120, 255)
    if s.visible and s.x > 40 and s.x < w - 40 and s.y > 40 and s.y < h - 40 then
        draw.SimpleTextOutlined("HOME", "DermaLarge", s.x, s.y - 14, col, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 2, color_black)
        draw.SimpleTextOutlined(dist .. " m", "DermaDefaultBold", s.x, s.y + 12, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, color_black)
    else
        -- off screen: an arrow at the edge pointing the way
        local yawTo = (target - LocalPlayer():GetPos()):Angle().y
        local rel = math.rad(math.NormalizeAngle(yawTo - EyeAngles().y))
        local cx, cy = w / 2, h / 2
        local ax, ay = cx - math.sin(rel) * (h * 0.38), cy - math.cos(rel) * (h * 0.38)
        draw.SimpleTextOutlined("HOME  " .. dist .. " m", "DermaDefaultBold", ax, ay, col, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, color_black)
    end
end

-- (made once here, not every frame)
local C_140_220_255 = Color(140, 220, 255)
local C_170_200_255 = Color(170, 200, 255)
local C_220_220_220 = Color(220, 220, 220)
local C_220_60_60 = Color(220, 60, 60)
local C_240_200_60 = Color(240, 200, 60)
local C_255_120_120 = Color(255, 120, 120)
local C_255_140_40 = Color(255, 140, 40)
local C_255_200_200 = Color(255, 200, 200)
local C_255_40_40 = Color(255, 40, 40)
local C_255_60_60 = Color(255, 60, 60)
local C_70_140_255 = Color(70, 140, 255)
hook.Add("HUDPaint", "LivingCityHUD", function()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end
    local now = CurTime()
    local w = ScrW()
    local y = 24

    if Visible() then DrawEditorLabels() end

    if banner and now < banner.untilT then
        Box(w / 2 - 210, y, 420, 52, C_220_60_60)
        draw.SimpleText(banner.text, "DermaDefaultBold", w / 2, y + 16, C_220_220_220, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText(banner.sub, "DermaLarge", w / 2, y + 36, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        y = y + 60
    end

    local jail = ply:GetNW2Float("lc_jail_until", 0)
    if jail > now then
        Box(w / 2 - 210, y, 420, 52, C_255_140_40)
        draw.SimpleText("IN CUSTODY  " .. string.FormattedTime(jail - now, "%02i:%02i"), "DermaLarge", w / 2, y + 18, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText(ply:GetNW2String("lc_jail_reason", ""), "DermaDefault", w / 2, y + 40, C_220_220_220, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        y = y + 60
    end

    local held = ply:GetNW2Float("lc_detained_until", 0)
    if held > now then
        Box(w / 2 - 210, y, 420, 52, C_255_140_40)
        draw.SimpleText(string.format("DETAINED  %ds", math.ceil(held - now)), "DermaLarge", w / 2, y + 18, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText("Cuffed and kneeling. Wait it out.", "DermaDefault", w / 2, y + 40, C_220_220_220, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        y = y + 60
    end

    local wanted = ply:GetNW2Float("lc_wanted_until", 0)
    local alert = ply:GetNW2Int("lc_alert", 0)
    if wanted > now or alert > 0 then
        local tall = alert >= 2
        Box(w / 2 - 210, y, 420, tall and 58 or 40, C_255_40_40)
        local reason = ply:GetNW2String("lc_wanted_reason", "")
        draw.SimpleText("WANTED" .. (reason ~= "" and (": " .. reason) or ""), "DermaLarge", w / 2, y + 20, C_255_120_120, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        if tall then
            local names = { "", "SECTOR-WIDE SEARCH: UNITS ARMED", "OVERWATCH DISPATCHED: LETHAL FORCE", "LOCKDOWN: SECOND SQUAD" }
            draw.SimpleText(string.format("ALERT %d   %s", alert, names[alert] or ""), "DermaDefaultBold", w / 2, y + 44,
                C_255_200_200, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        y = y + (tall and 66 or 48)
    end

    local trespass = ply:GetNW2Float("lc_trespass_until", 0)
    if trespass > now then
        Box(w / 2 - 210, y, 420, 40, C_70_140_255)
        draw.SimpleText(string.format("RESTRICTED AREA: LEAVE NOW (%ds)", math.ceil(trespass - now)), "DermaLarge", w / 2, y + 20,
            color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        y = y + 48
    end

    -- a Civil Protection escort (sv_livingcity_escort.lua)
    local ephase = ply:GetNW2String("lc_escort_phase", "")
    if ephase ~= "" or ply:GetNW2Bool("lc_escort_wait", false) then
        local who = ply:GetNW2String("lc_escort_name", "")
        local text, col = "Waiting for an escort...", C_170_200_255
        if ephase == "coming" then text = "Escort on the way: " .. who
        elseif ephase == "with" then text = "Escorted by " .. who .. ": Combine doors open for you (E)"
        elseif ephase == "out" then text = "Escorted by " .. who .. ": they're walking you out"
        elseif ephase == "unattended" then
            text = string.format("ESCORT CALLED AWAY: stay put, another Civil Protection unit is coming (%ds)", math.max(0, math.ceil(ply:GetNW2Float("lc_escort_grace", 0) - now)))
            col = Color(255, 210, 120)
        end
        draw.SimpleTextOutlined(text, "DermaDefaultBold", w / 2, y + 8, col, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, color_black)
        y = y + 22
    end

    local protect = ply:GetNW2Float("lc_protect_until", 0)
    if protect > now then
        draw.SimpleTextOutlined(string.format("Spawn protection %ds", math.ceil(protect - now)), "DermaDefaultBold",
            w / 2, y + 8, C_140_220_255, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, color_black)
        y = y + 22
    end

    local ev = GetGlobal2String("lc_event", "")
    if ev ~= "" then
        local left = math.max(0, GetGlobal2Float("lc_event_ends", 0) - now)
        local names = { rations = "Ration distribution", sweep = "Civil status inspections", curfew = "CURFEW IN EFFECT", lockdown = "LOCKDOWN", raid = "Housing block inspection", supply = "Supply convoy unloading" }
        local strict = ev == "curfew" or ev == "lockdown"
        -- units and Overwatch don't go home for curfew: they enforce it
        local f = ply:GetNW2String("lcf_faction", "")
        local unit = ply:GetNW2Bool("lc_unit", false) or f == "cp"
        local block = unit and 0 or ply:GetNW2Int("lc_block", 0)
        local sub = string.FormattedTime(left, "%02i:%02i") .. " remaining"
        if strict and unit then sub = "Clear the streets. " .. sub end
        local grace = GetGlobal2Float("lc_event_grace", 0) - now
        if strict and not unit and grace > 0 and not (block > 0 and InMyBlock(block)) then
            sub = string.format("Grace period: %ds to get home. ", math.ceil(grace)) .. sub
        end
        -- (a stalker has no home: the curfew's "report to your block" and HOME marker aren't for it)
        if LocalPlayer():GetNW2String("lcf_faction", "") == "stalker" then block = 0 end
        if strict and block > 0 then
            sub = (InMyBlock(block) and "You are home. Stay inside. " or ("Report to " .. BlockName(block) .. ". ")) .. sub
        end
        Box(w / 2 - 230, y, 460, 46, strict and C_255_60_60 or C_240_200_60)
        draw.SimpleText(names[ev] or ev, "DermaLarge", w / 2, y + 15, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText(sub, "DermaDefault", w / 2, y + 35, C_220_220_220, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        if strict and block > 0 and not InMyBlock(block) then
            local b = MyBlockCenter(block)
            if b then DrawHomeMarker(b.pos) end
        end
        y = y + 54
    end
    LC_CL.StatusBottom = y -- (the notice cards go under all this: cl_livingcity_notices.lua)
end)

------------------------------------------------------------------------
-- Debug report viewer
------------------------------------------------------------------------

net.Receive("lc_report", function()
    local t = ReadCompressed() or {}
    local text = t.text or "(empty report)"
    SetClipboardText(text)
    chat.AddText(Color(120, 200, 255), "[Miscount] ", color_white, "Debug report copied to your clipboard. Paste it to Claude. Also saved to " .. tostring(t.file))

    local f = vgui.Create("DFrame")
    if LC_CL.SetTheme then LC_CL.SetTheme(f, "staff") end
    f:SetTitle("Miscount debug report")
    f:SetSize(math.min(ScrW() - 80, 900), math.min(ScrH() - 80, 640))
    f:Center()
    f:MakePopup()
    local entry = vgui.Create("DTextEntry", f)
    entry:Dock(FILL)
    entry:SetMultiline(true)
    entry:SetVerticalScrollbarEnabled(true)
    entry:SetFont("DebugFixed")
    entry:SetText(text)
    local copy = vgui.Create("DButton", f)
    copy:Dock(BOTTOM)
    copy:SetTall(30)
    copy:SetText("Copy to clipboard again")
    copy.DoClick = function() SetClipboardText(text); copy:SetText("Copied!") end
end)

------------------------------------------------------------------------
-- Forward our own client errors to the server log
------------------------------------------------------------------------

local nextSend = 0
hook.Add("OnLuaError", "LivingCityClientErrors", function(err, realm, stack, name)
    local text = tostring(err)
    if istable(stack) and stack[1] then text = text .. " @ " .. tostring(stack[1].File) .. ":" .. tostring(stack[1].Line) end
    local low = string.lower(text .. tostring(name))
    if not (string.find(low, "livingcity", 1, true) or string.find(low, "weapon_lc_", 1, true)) then return end
    if CurTime() < nextSend then return end
    nextSend = CurTime() + 5
    net.Start("lc_clerror")
    net.WriteString(string.sub(text, 1, 400))
    net.SendToServer()
end)

-- the first corner of a box zone being placed (the editor tells us)
net.Receive("lc_boxcorner", function()
    local has = net.ReadBool()
    LC_CL.boxCorner = has and net.ReadVector() or nil
end)

-- Path mapping (sv_livingcity_pathmap.lua): say so on screen while it's on
-- (made once here, not every frame)
local C_0_0_0_220 = Color(0, 0, 0, 220)
local C_230_180_60 = Color(230, 180, 60)
local C_90_220_140 = Color(90, 220, 140)
hook.Add("HUDPaint", "LC_PathMapHUD", function()
    local ply = LocalPlayer()
    if not IsValid(ply) or not ply:GetNW2Bool("lc_pathmap", false) then return end
    local paused = ply:GetMoveType() == MOVETYPE_NOCLIP
    draw.SimpleTextOutlined(paused and "PATH MAPPING PAUSED (noclip)" or "PATH MAPPING: walk to lay nodes",
        "DermaDefaultBold", ScrW() / 2, ScrH() * 0.12, paused and C_230_180_60 or C_90_220_140, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, C_0_0_0_220)
end)

------------------------------------------------------------------------
-- Luggage swinging in the hand (sv_livingcity_npcwork.lua, LC.NPCCarry)
------------------------------------------------------------------------

-- A suitcase hangs from the carrier's right hand, following it as the arm
-- swings, but stays upright and facing the way they walk (hung from the
-- hand bone itself, it would turn with the wrist).
local function DrawHeld(self)
    local npc = self:GetParent()
    local att = IsValid(npc) and npc:LookupAttachment("anim_attachment_RH") or 0
    local a = att and att > 0 and npc:GetAttachment(att)
    if not a then return self:DrawModel() end
    local pos, ang = LocalToWorld(self:GetNW2Vector("lc_hold_off", Vector(0, 0, 0)), self:GetNW2Angle("lc_hold_ang", Angle(0, 0, 0)),
        a.Pos - Vector(0, 0, 2), Angle(0, npc:GetAngles().y, 0))
    self:SetRenderOrigin(pos)
    self:SetRenderAngles(ang)
    self:SetupBones()
    self:DrawModel()
    self:SetRenderOrigin()
    self:SetRenderAngles()
end

-- Carrying a box or a crate out in front (sv_livingcity_npcwork.lua): each hand held on its side
-- of the box, wherever the walk would swing the arm (the arms used to be bent on top of the
-- walk, so the hands swung about under the box). Each arm reaches for its spot: the upper arm
-- and forearm keep their lengths, the elbow bends down and out, and the hand (with its fingers)
-- comes along.
local function Turned(ang, from, to)
    local axis = from:Cross(to)
    local s = axis:Length()
    if s < 1e-4 then return ang end
    local a = Angle(ang.p, ang.y, ang.r)
    a:RotateAroundAxis(axis / s, math.deg(math.atan2(s, from:Dot(to))))
    return a
end

-- Every bone under this one (but not the arm's own next bone) moved as `move` moved its parent.
local function Carry(e, bone, skip, move)
    for _, c in ipairs(e.GetChildBones and e:GetChildBones(bone) or {}) do
        if c ~= skip then
            local m = e:GetBoneMatrix(c)
            if m then e:SetBoneMatrix(c, move * m) Carry(e, c, nil, move) end
        end
    end
end

local function Reach(e, side, target)
    local pre = "ValveBiped.Bip01_" .. side .. "_"
    local u, f, h = e:LookupBone(pre .. "UpperArm"), e:LookupBone(pre .. "Forearm"), e:LookupBone(pre .. "Hand")
    if not (u and f and h) then return end
    local mu, mf, mh = e:GetBoneMatrix(u), e:GetBoneMatrix(f), e:GetBoneMatrix(h)
    if not (mu and mf and mh) then return end
    local S, F, H = mu:GetTranslation(), mf:GetTranslation(), mh:GetTranslation()
    local a, b = S:Distance(F), F:Distance(H)
    if a < 1 or b < 1 then return end
    local toT = target - S
    local d = math.Clamp(toT:Length(), math.abs(a - b) + 0.5, a + b - 0.5)
    local dir = toT:GetNormalized()
    -- the elbow: down and out from the line shoulder to hand
    local out = side == "R" and -e:GetRight() or e:GetRight()
    local pole = (out * 0.5 - e:GetUp()) - dir * (out * 0.5 - e:GetUp()):Dot(dir)
    if pole:LengthSqr() < 1e-4 then pole = -e:GetUp() end
    pole:Normalize()
    local x = (a * a - b * b + d * d) / (2 * d)
    local E = S + dir * x + pole * math.sqrt(math.max(0, a * a - x * x))
    local T = S + dir * d
    -- the upper arm points at the elbow, the forearm at the hand, each turned the least it can
    local nu = Matrix() nu:SetTranslation(S) nu:SetAngles(Turned(mu:GetAngles(), (F - S):GetNormalized(), (E - S):GetNormalized()))
    local nf = Matrix() nf:SetTranslation(E) nf:SetAngles(Turned(mf:GetAngles(), (H - F):GetNormalized(), (T - E):GetNormalized()))
    local nh = Matrix() nh:SetTranslation(T) nh:SetAngles(Turned(mh:GetAngles(), (H - F):GetNormalized(), (T - E):GetNormalized()))
    e:SetBoneMatrix(u, nu)
    e:SetBoneMatrix(f, nf)
    e:SetBoneMatrix(h, nh)
    Carry(e, u, f, nu * mu:GetInverseTR())
    Carry(e, f, h, nf * mf:GetInverseTR())
    Carry(e, h, nil, nh * mh:GetInverseTR())
end

local function HoldBox(e)
    if not IsValid(e) or not e:GetNW2Bool("lc_carry_front", false) then return end
    local hand = e:GetNW2Vector("lc_carry_hand", Vector(28, -10, 42))
    Reach(e, "R", e:LocalToWorld(hand))
    Reach(e, "L", e:LocalToWorld(Vector(hand.x, -hand.y, hand.z)))
end
LC_CL.CarryReach = Reach

local carryPosed = {}
timer.Create("LivingCityCarryFront", 0.25, 0, function()
    local seen = {}
    for _, e in ipairs(ents.FindByClass("npc_*")) do
        if IsValid(e) and e:GetNW2Bool("lc_carry_front", false) then
            seen[e] = true
            if not carryPosed[e] and e.AddCallback then carryPosed[e] = e:AddCallback("BuildBonePositions", HoldBox) or true end
        end
    end
    for e, id in pairs(carryPosed) do
        if not seen[e] then
            if IsValid(e) and e.RemoveCallback and id ~= true then e:RemoveCallback("BuildBonePositions", id) end
            carryPosed[e] = nil
        end
    end
end)

timer.Create("LivingCityHeldLuggage", 0.5, 0, function()
    for _, e in ipairs(ents.FindByClass("prop_dynamic")) do
        if not e.lcHeldDraw and e:GetNW2Bool("lc_hold_side", false) then
            e.lcHeldDraw = true
            e.RenderOverride = DrawHeld
        end
    end
end)
