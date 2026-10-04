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

local cvShow  = CreateClientConVar("lc_show", "0", true, false, "Always show the Living City layout")
local cvDebug = CreateClientConVar("lc_show_npcs", "1", true, false, "Show NPC states in the editor overlay")
local cvFill  = CreateClientConVar("lc_zone_fill", "1", true, false, "Shade zones on the ground in the editor")

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
    idle = Color(90, 220, 120), sit = Color(60, 200, 200), sitchair = Color(60, 170, 220), lean = Color(120, 230, 230),
    queue = Color(240, 200, 60), patrol = Color(80, 150, 255), checkpoint = Color(255, 80, 80),
    spawn = Color(240, 240, 240), cell = Color(255, 140, 40), release = Color(255, 200, 140),
    work = Color(200, 150, 100), vending = Color(90, 170, 230), dispenser = Color(200, 200, 120),
    terminal = Color(230, 180, 90), stove = Color(230, 110, 60), fire = Color(255, 120, 40), dealer = Color(150, 110, 190),
    zspawn = Color(170, 220, 40), rspawn = Color(230, 150, 70),
}
local POINT_NAMES = {
    idle = "LOITER", sit = "SIT", sitchair = "BENCH", lean = "LEAN", queue = "LINE", patrol = "PATROL",
    checkpoint = "CHECKPOINT", spawn = "SPAWN/EXIT", cell = "CELL", release = "RELEASE",
    work = "WORKPLACE", vending = "VENDING", dispenser = "RATIONS", terminal = "COMMISSARY", stove = "STOVE", fire = "FIRE",
    dealer = "DEALER", zspawn = "ZOMBIE SPAWN", rspawn = "REBEL SPAWN",
}
local ZONE_COLORS = {
    nogo = Color(255, 60, 60), infest = Color(170, 220, 40), prison = Color(255, 140, 40),
    block = Color(180, 120, 255), rebel = Color(230, 150, 70), combine = Color(70, 140, 255),
}
local ZONE_NAMES = { nogo = "NO-GO", infest = "INFESTATION", prison = "PRISON", block = "BLOCK", rebel = "REBEL TERRITORY", combine = "COMBINE ONLY" }
local DOOR_COLORS = {
    cp = Color(80, 150, 255), locked = Color(255, 70, 70), open = Color(90, 220, 120),
    ignore = Color(160, 160, 160), force = Color(240, 200, 60),
}
local DOOR_LABELS = { cp = "CP ONLY", locked = "LOCKED", open = "ALWAYS OPEN", ignore = "NPCS IGNORE", force = "FORCED DOOR" }
local LINK_COLOR, NODE_COLOR, ORPHAN_COLOR, SELECT_COLOR = Color(0, 200, 255), Color(0, 160, 255), Color(255, 50, 50), Color(255, 230, 0)

local function BlockName(n)
    local cv = GetConVar("lc_block_name")
    local ok, s = pcall(string.format, cv and cv:GetString() or "Habitation Block %02d", n)
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
        LC_CL.zones[i] = { pos = Vector(z.x, z.y, z.z), r = z.r, kind = z.kind, group = z.group or 0 }
    end
    LC_CL.doors = t.doors or {}

    -- sequences: ration lines and patrol beats, in placement order
    LC_CL.sequences = {}
    local index = {}
    for _, p in ipairs(LC_CL.points) do
        if (p.kind == "queue" or p.kind == "patrol") and p.group > 0 then
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
        LC_CL.blocks[#LC_CL.blocks + 1] = { n = b.n, pos = Vector(b.x, b.y, b.z), r = b.r }
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

local function Visible() return cvShow:GetBool() or HoldingEditor() end

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

local MAX_DIST2 = 3000 * 3000
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

local function DrawEdge(d, col, thick)
    local ring = d.rings[#d.rings]
    if thick then
        render.SetMaterial(FILL_MAT)
        for j = 1, d.segs do
            render.DrawBeam(ring[j] + Vector(0, 0, 1), ring[j % d.segs + 1] + Vector(0, 0, 1), 5, 0, 1, col)
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
        if pos:DistToSqr(z.pos) < z.r * z.r and (not best or z.r < best.r) then best = z end
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

hook.Add("PostDrawTranslucentRenderables", "LivingCityOverlay", function(_, skybox)
    if skybox then return end
    local eye = EyePos()

    -- test walker route (shown to whoever ran the test, even after putting the tool away)
    local route = LC_CL.route
    if route and CurTime() < route.untilT then
        render.SetColorMaterial()
        for i = 2, #route.pts do render.DrawLine(route.pts[i - 1] + UP8, route.pts[i] + UP8, Color(255, 255, 255), false) end
        for _, p in ipairs(route.pts) do render.DrawSphere(p + UP8, 5, 8, 8, Color(255, 255, 255, 200)) end
        if route.stuck then render.DrawSphere(route.stuck + Vector(0, 0, 36), 18, 12, 12, Color(255, 0, 0, 120)) end
    end

    if not Visible() then return end
    render.SetColorMaterial()

    UpdateAim()
    local aimZone = aimed and aimed.kind == "zone" and aimed.it or nil
    local aimPoint = aimed and aimed.kind == "point" and aimed.it or nil
    local aimNode = aimed and aimed.kind == "node" and aimed.it or nil

    for _, p in ipairs(LC_CL.points) do
        if p.pos:DistToSqr(eye) < MAX_DIST2 then
            local col = POINT_COLORS[p.kind] or color_white
            local base = p.pos + Vector(0, 0, 2)
            if p == aimPoint then
                local pulse = 10 + math.sin(CurTime() * 6) * 2
                render.DrawSphere(base + UP8, pulse, 16, 16, Color(col.r, col.g, col.b, 240))
                render.DrawWireframeSphere(base + UP8, 64, 16, 8, Color(255, 255, 255, 90), true)
                render.SetColorMaterial()
            else
                render.DrawSphere(base + UP8, 7, 12, 12, Color(col.r, col.g, col.b, 180))
            end
            render.DrawLine(base, base + UP60, col, false)
            render.DrawLine(base + UP8, base + UP8 + Angle(0, p.yaw, 0):Forward() * 36, col, false)
        end
    end

    for _, seq in ipairs(LC_CL.sequences or {}) do
        local col = POINT_COLORS[seq.kind]
        for i = 2, #seq.pts do render.DrawLine(seq.pts[i - 1].pos + UP8, seq.pts[i].pos + UP8, col, false) end
        if seq.kind == "patrol" and #seq.pts > 2 then
            render.DrawLine(seq.pts[#seq.pts].pos + UP8, seq.pts[1].pos + UP8, Color(col.r, col.g, col.b, 90), false)
        end
    end

    for id, n in pairs(LC_CL.nodes) do
        if n.pos:DistToSqr(eye) < MAX_DIST2 then
            local col = (LC_CL.selected == id) and SELECT_COLOR or (n.orphan and ORPHAN_COLOR or NODE_COLOR)
            if n == aimNode then
                render.DrawWireframeBox(n.pos, angle_zero, Vector(-10, -10, 0), Vector(10, 10, 22), color_white, false)
            end
            render.DrawWireframeBox(n.pos, angle_zero, Vector(-6, -6, 0), Vector(6, 6, 14), col, false)
            for _, other in ipairs(n.links) do
                local o = LC_CL.nodes[other]
                if o then render.DrawLine(n.pos + UP8, o.pos + UP8, LINK_COLOR, false) end
            end
        end
    end

    -- zones: every zone faintly shaded, the one you're aiming at filled in
    -- strongly with a bold edge, and the others dimmed so it stands out
    local fill = cvFill:GetBool()
    for _, z in ipairs(LC_CL.zones) do
        if z.pos:DistToSqr(eye) < (3000 + z.r) ^ 2 then
            local col = ZONE_COLORS[z.kind] or color_white
            local ok = pcall(function()
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

    -- placing a zone: shade where it will go, at the radius on the slider
    local zoneKind = HoldingEditor() and ZONE_MODE_KIND[EditorMode()]
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
                DrawEdge(preview.drape, Color(255, 255, 255, 200), true)
            end)
            render.SetColorMaterial()
        end
    end

    for _, d in ipairs(LC_CL.doors) do
        local door = Entity(d.idx)
        if IsValid(door) and door:GetPos():DistToSqr(eye) < MAX_DIST2 then
            render.DrawWireframeBox(door:GetPos(), door:GetAngles(), door:OBBMins(), door:OBBMaxs(), DOOR_COLORS[d.tag] or color_white, false)
        end
    end

    if cvDebug:GetBool() then
        for _, e in ipairs(npcCache) do
            if IsValid(e) and e:GetNW2String("lc_state", "") == "moving" then
                local dest = e:GetNW2Vector("lc_dest", vector_origin)
                if dest ~= vector_origin then render.DrawLine(e:GetPos() + UP8, dest + UP8, Color(255, 255, 255, 60), false) end
            end
        end
    end
end)

local function Label(pos, text, col, font)
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
        text = string.format("%s   |   radius %d units (about %.1f m across)   |   right click removes", name, z.r, z.r * 2 * 0.019)
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
    DrawAimInfo()
    local eye = EyePos()
    local near = 1000 * 1000

    for _, p in ipairs(LC_CL.points) do
        if p.pos:DistToSqr(eye) < near then
            local txt = POINT_NAMES[p.kind] or string.upper(p.kind)
            if p.kind == "queue" and p.group > 0 then txt = string.format("LINE %d  #%d", p.group, p.order or 0)
            elseif p.kind == "queue" then txt = "STAND HERE"
            elseif p.kind == "patrol" and p.group > 0 then txt = string.format("BEAT %d  #%d", p.group, p.order or 0)
            elseif p.kind == "work" then
                local job = LCJ and LCJ.ByNum[p.group]
                txt = "WORK: " .. string.upper(job and job.place or ("job " .. p.group))
            end
            Label(p.pos + Vector(0, 0, 66), txt, POINT_COLORS[p.kind])
        end
    end
    for id, n in pairs(LC_CL.nodes) do
        if n.orphan and n.pos:DistToSqr(eye) < near then Label(n.pos + Vector(0, 0, 22), "UNLINKED", ORPHAN_COLOR) end
    end
    for _, z in ipairs(LC_CL.zones) do
        if z.pos:DistToSqr(eye) < (1500 + z.r) ^ 2 then
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
    if cvDebug:GetBool() then
        for _, e in ipairs(npcCache) do
            if IsValid(e) and e:GetPos():DistToSqr(eye) < near then
                Label(e:GetPos() + Vector(0, 0, 84), string.upper(e:GetNW2String("lc_role", "")) .. ": " .. e:GetNW2String("lc_state", ""),
                    Color(255, 255, 255, 220), "DermaDefault")
            end
        end
    end
end

------------------------------------------------------------------------
-- HUD for everyone
------------------------------------------------------------------------

local banner -- { text, sub, untilT }

net.Receive("lc_announce", function()
    local path = net.ReadString()
    local title = net.ReadString()
    surface.PlaySound(path)
    banner = { text = "CITY ANNOUNCEMENT", sub = title, untilT = CurTime() + 7 }
end)

local function Box(x, y, w, h, col)
    draw.RoundedBox(6, x, y, w, h, Color(10, 12, 16, 200))
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
        if b.n == n and me:DistToSqr(b.pos) < b.r * b.r then return true end
    end
    return false
end

local function DrawHomeMarker(target)
    local s = (target + Vector(0, 0, 80)):ToScreen()
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

hook.Add("HUDPaint", "LivingCityHUD", function()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end
    local now = CurTime()
    local w = ScrW()
    local y = 24

    if Visible() then DrawEditorLabels() end

    if banner and now < banner.untilT then
        Box(w / 2 - 210, y, 420, 52, Color(220, 60, 60))
        draw.SimpleText(banner.text, "DermaDefaultBold", w / 2, y + 16, Color(220, 220, 220), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText(banner.sub, "DermaLarge", w / 2, y + 36, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        y = y + 60
    end

    local jail = ply:GetNW2Float("lc_jail_until", 0)
    if jail > now then
        Box(w / 2 - 210, y, 420, 52, Color(255, 140, 40))
        draw.SimpleText("IN CUSTODY  " .. string.FormattedTime(jail - now, "%02i:%02i"), "DermaLarge", w / 2, y + 18, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText(ply:GetNW2String("lc_jail_reason", ""), "DermaDefault", w / 2, y + 40, Color(220, 220, 220), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        y = y + 60
    end

    local held = ply:GetNW2Float("lc_detained_until", 0)
    if held > now then
        Box(w / 2 - 210, y, 420, 52, Color(255, 140, 40))
        draw.SimpleText(string.format("DETAINED  %ds", math.ceil(held - now)), "DermaLarge", w / 2, y + 18, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText("Cuffed and kneeling. Wait it out.", "DermaDefault", w / 2, y + 40, Color(220, 220, 220), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        y = y + 60
    end

    local wanted = ply:GetNW2Float("lc_wanted_until", 0)
    local alert = ply:GetNW2Int("lc_alert", 0)
    if wanted > now or alert > 0 then
        local tall = alert >= 2
        Box(w / 2 - 210, y, 420, tall and 58 or 40, Color(255, 40, 40))
        local reason = ply:GetNW2String("lc_wanted_reason", "")
        draw.SimpleText("WANTED" .. (reason ~= "" and (": " .. reason) or ""), "DermaLarge", w / 2, y + 20, Color(255, 120, 120), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        if tall then
            local names = { "", "SECTOR-WIDE SEARCH: UNITS ARMED", "OVERWATCH DISPATCHED: LETHAL FORCE", "LOCKDOWN: SECOND SQUAD" }
            draw.SimpleText(string.format("ALERT %d   %s", alert, names[alert] or ""), "DermaDefaultBold", w / 2, y + 44,
                Color(255, 200, 200), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        y = y + (tall and 66 or 48)
    end

    local trespass = ply:GetNW2Float("lc_trespass_until", 0)
    if trespass > now then
        Box(w / 2 - 210, y, 420, 40, Color(70, 140, 255))
        draw.SimpleText(string.format("RESTRICTED AREA: LEAVE NOW (%ds)", math.ceil(trespass - now)), "DermaLarge", w / 2, y + 20,
            color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        y = y + 48
    end

    local protect = ply:GetNW2Float("lc_protect_until", 0)
    if protect > now then
        draw.SimpleTextOutlined(string.format("Spawn protection %ds", math.ceil(protect - now)), "DermaDefaultBold",
            w / 2, y + 8, Color(140, 220, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, color_black)
        y = y + 22
    end

    local ev = GetGlobal2String("lc_event", "")
    if ev ~= "" then
        local left = math.max(0, GetGlobal2Float("lc_event_ends", 0) - now)
        local names = { rations = "Ration distribution", sweep = "Civil status inspections", curfew = "CURFEW IN EFFECT", lockdown = "LOCKDOWN", raid = "Housing block inspection" }
        local strict = ev == "curfew" or ev == "lockdown"
        local block = ply:GetNW2Int("lc_block", 0)
        local sub = string.FormattedTime(left, "%02i:%02i") .. " remaining"
        local grace = GetGlobal2Float("lc_event_grace", 0) - now
        if strict and grace > 0 and not (block > 0 and InMyBlock(block)) then
            sub = string.format("Grace period: %ds to get home. ", math.ceil(grace)) .. sub
        end
        if strict and block > 0 then
            sub = (InMyBlock(block) and "You are home. Stay inside. " or ("Report to " .. BlockName(block) .. ". ")) .. sub
        end
        Box(w / 2 - 230, y, 460, 46, strict and Color(255, 60, 60) or Color(240, 200, 60))
        draw.SimpleText(names[ev] or ev, "DermaLarge", w / 2, y + 15, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText(sub, "DermaDefault", w / 2, y + 35, Color(220, 220, 220), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        if strict and block > 0 and not InMyBlock(block) then
            local b = MyBlockCenter(block)
            if b then DrawHomeMarker(b.pos) end
        end
    end
end)

------------------------------------------------------------------------
-- Debug report viewer
------------------------------------------------------------------------

net.Receive("lc_report", function()
    local t = ReadCompressed() or {}
    local text = t.text or "(empty report)"
    SetClipboardText(text)
    chat.AddText(Color(120, 200, 255), "[Living City] ", color_white, "Debug report copied to your clipboard. Paste it to Claude. Also saved to " .. tostring(t.file))

    local f = vgui.Create("DFrame")
    f:SetTitle("Living City debug report")
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
