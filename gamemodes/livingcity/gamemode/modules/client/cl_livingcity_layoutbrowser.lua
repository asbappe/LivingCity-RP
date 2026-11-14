--[[
    Living City (client): the editor's layout browser

    The editor's mode list, grouped (points, fixtures, paths, zones, doors,
    tools) into sections that fold away, each line showing how many of that
    thing are placed on this map. Click a line to use it. "Find" marks every
    one of them on your screen, through walls, with how far away it is; "Go"
    takes you to the next one (admins). At the top: the layout at a glance,
    and what's missing that the city would like to have.
]]

LC_CL = LC_CL or { points = {}, nodes = {}, zones = {}, doors = {}, blocks = {} }
LC_CL.highlight = LC_CL.highlight or {} -- [mode id] = true

local CATS = {
    { key = "Point", title = "Points" },
    { key = "Fixture", title = "Fixtures" },
    { key = "Street", title = "Street furniture and screens" },
    { key = "Workplace", title = "Workplaces (Union jobs)" },
    { key = "Path", title = "Paths and ladders" },
    { key = "Zone", title = "Zones" },
    { key = "Door", title = "Doors" },
    { key = "Prop", title = "Persistent props" },
    { key = "", title = "Tools" },
}

-- The other way to look at the same list: by what it's for, everything a part of the city needs
-- in one place (building a rebel base: its zone, its lab, its beds, its lookouts, all together).
-- A thing can be in more than one. Occupations get a folder each: their workplace and what goes with it.
local USES = {
    { title = "Citizens' daily life", ids = { "idle", "sit", "sitchair", "lean", "queue", "dispenser", "vending", "terminal", "stove", "bed",
        "toilet", "bath", "fire", "locker", "tv", "screen", "lawboard", "jobboard", "infodesk", "civposter", "citybin", "bin", "zone_block", "door_rent" } },
    { title = "Arriving and leaving the city", ids = { "arrival", "intake", "laborterm", "housingterm", "platform", "spawn", "lz" } },
    { title = "Civil Protection and the Combine", ids = { "patrol", "checkpoint", "cpsupply", "cpfeed", "evidlocker", "console", "sspawn", "powerbank", "turret",
        "forcefield", "barricade_low", "barricade", "barricade_tall", "dataterm", "masterterm", "zone_combine", "sterm", "door_cp", "door_office", "studio", "loudspeaker", "screen_big" } },
    { title = "The Administrator's last stand", ids = { "desk", "adminpower", "suppressor", "speech", "speechcrowd", "door_office", "zone_combine" } },
    { title = "Prison", ids = { "cell", "release", "prisonwork", "zone_prison", "door_prison" } },
    { title = "The Resistance and rebel bases", ids = { "zone_rebel", "rspawn", "rlookout", "rebelboard", "interrochair", "rebelcage", "bunk", "workbench", "dealer", "bed", "toilet", "stove",
        "sit", "sitchair", "lean", "fire", "locker", "graffiti", "way_left", "way_right", "way_up", "way_down", "way_freedom" } },
    { title = "Infestation", ids = { "zone_infest", "zspawn", "hazbarrel" } },
    { title = "Morning exercise", ids = { "yard", "parade" } },
    { title = "Dreams", ids = { "dream", "zone_dream" } }, -- (the owner, 11 November: missing from this view)
    { title = "Power and the street", ids = { "transformer", "streetlight", "loudspeaker", "screen_big", "pipe", "rubble", "salvage" } },
    { title = "Paths, ladders and doors", ids = { "node", "link", "ladder", "zone_nogo", "door_locked", "door_open", "door_ignore", "door_force", "door_test" } },
    { title = "Tools", ids = { "prop", "inspect", "walker" } },
}
-- an occupation's things beside its workplace
local JOB_EXTRAS = {
    sanitation = { "citybin", "bin", "graffiti", "toilet" }, kitchen = { "dispenser", "queue", "dock" }, medic = { "bed" },
    factory = { "conveyor", "dock" }, courier = { "dock" }, maintenance = { "streetlight", "transformer", "pipe", "powerbank", "forcefield" },
    porter = { "platform", "arrival", "dock" }, clerk = { "intake", "housingterm" }, laundry = {}, mortuary = { "incinerator" }, cleanup = { "zone_infest", "hazbarrel" },
    scrap = { "rubble", "salvage", "recycler" }, radio = {},
}
local cvArrange = CreateClientConVar("lc_editor_arrange", "type", true, false, "How the editor's list is arranged: type (points, fixtures...) or use (what it's for)")

-- Add to a panel's Think without replacing its own (a category's open and
-- close animation, a label stretching to fit its text).
local function AlsoThink(pnl, fn)
    local base = pnl.Think
    pnl.Think = function(self)
        if base then base(self) end
        fn(self)
    end
end

local function CatOf(m)
    for _, c in ipairs(CATS) do
        if c.key ~= "" and string.StartWith(m.label, c.key .. ":") then return c.key end
    end
    return ""
end

-- A workplace line is a workplace point with that job's number.
local function Matches(id, p)
    if string.StartWith(id, "work_") then
        local job = LCJ and LCJ.ById and LCJ.ById[string.sub(id, 6)]
        return job ~= nil and p.kind == "work" and tonumber(p.group) == job.num
    end
    return p.kind == id
end

local function Short(m)
    local s = string.gsub(m.label, "^%a+: ", "")
    return s
end

-- How many of this are on the map (nil: not something you place).
function LC_CL.LayoutCount(id)
    if id == "inspect" or id == "walker" or id == "door_test" then return nil end
    if id == "node" then return table.Count(LC_CL.nodes or {}) end
    if id == "link" then
        local n = 0
        for _, nd in pairs(LC_CL.nodes or {}) do n = n + #(nd.links or {}) end
        return n
    end
    if string.StartWith(id, "zone_") then
        local k, n = string.sub(id, 6), 0
        for _, z in ipairs(LC_CL.zones or {}) do if z.kind == k then n = n + 1 end end
        return n
    end
    if id == "prop" then return #(LC_CL.props or {}) end
    if string.StartWith(id, "door_") then
        local k, n = string.sub(id, 6), 0
        for _, d in ipairs(LC_CL.doors or {}) do if d.tag == k then n = n + 1 end end
        return n
    end
    local n = 0
    for _, p in ipairs(LC_CL.points or {}) do if Matches(id, p) then n = n + 1 end end
    return n
end

-- Where each one of this is, in a fixed order (the same order the server uses for "Go").
function LC_CL.LayoutPositions(id)
    local out = {}
    if id == "node" then
        local ids = table.GetKeys(LC_CL.nodes or {})
        table.sort(ids)
        for _, k in ipairs(ids) do out[#out + 1] = LC_CL.nodes[k].pos end
    elseif string.StartWith(id, "zone_") then
        local k = string.sub(id, 6)
        for _, z in ipairs(LC_CL.zones or {}) do if z.kind == k then out[#out + 1] = z.pos end end
    elseif id == "prop" then
        for _, p in ipairs(LC_CL.props or {}) do out[#out + 1] = p.pos end
    elseif string.StartWith(id, "door_") then
        local k = string.sub(id, 6)
        for _, d in ipairs(LC_CL.doors or {}) do
            local e = Entity(d.idx or 0)
            if d.tag == k and IsValid(e) then out[#out + 1] = e:WorldSpaceCenter() end
        end
    else
        for _, p in ipairs(LC_CL.points or {}) do if Matches(id, p) then out[#out + 1] = p.pos end end
    end
    return out
end

-- What the city would like to have and hasn't got.
local WANTED = {
    { "cell", "No prison cells: arrests happen on the street." },
    { "release", "No release spot: prisoners walk out of their cell." },
    { "dispenser", "No ration dispenser." },
    { "queue", "No ration line." },
    { "spawn", "No spawn/exit doorways: NPCs appear out of sight." },
    { "checkpoint", "No checkpoints for Civil Protection units to man." },
    { "zone_block", "No housing blocks: curfew has nowhere to send people." },
    { "zone_prison", "No prison area (optional; the cells work without it)." },
    { "zspawn", "No infestation spawns: zombies appear anywhere in infestation zones." },
    { "incinerator", "No incinerator: Morticians bag bodies at the morgue workplace, or have no collections." },
    { "sspawn", "No scanner launch spot: flown scanners go up in the open air near the console." },
    { "intake", "No Civil Intake (optional): new people are registered as they arrive, with a room handed to them." },
    { "laborterm", "No Labor Assignment (optional): the Union assigns work by itself and the board (F4) changes jobs." },
    { "cpsupply", "No Civil Protection Commissary: Civil Protection units are issued their supplies at the Union Commissary instead." },
    { "workbench", "No Resistance lab: the Resistance can only get guns, jammers and radios from the black market." },
}

local function Glance()
    local pts, fx, zones, doors = 0, 0, #(LC_CL.zones or {}), #(LC_CL.doors or {})
    local FIX = { vending = true, dispenser = true, terminal = true, stove = true, fire = true, dealer = true, locker = true,
        screen = true, lawboard = true, cpfeed = true, evidlocker = true, rebelboard = true, interrochair = true, rebelcage = true, infodesk = true, civposter = true, console = true, workbench = true, recycler = true, dataterm = true, masterterm = true, citybin = true, streetlight = true, loudspeaker = true, screen_big = true, tv = true, incinerator = true, hazbarrel = true, transformer = true, forcefield = true, powerbank = true, turret = true, barricade_low = true, barricade = true, barricade_tall = true, intake = true, housingterm = true, laborterm = true, cpsupply = true, conveyor = true, bed = true, toilet = true, bath = true }
    for _, p in ipairs(LC_CL.points or {}) do if FIX[p.kind] then fx = fx + 1 else pts = pts + 1 end end
    local npcs = 0
    for _, e in ipairs(ents.FindByClass("npc_*")) do if e:GetNW2String("lc_role", "") ~= "" then npcs = npcs + 1 end end
    local lines = {
        string.format("%d points, %d fixtures, %d zones, %d tagged doors, %d path nodes.  %d city NPCs about.",
            pts, fx, zones, doors, table.Count(LC_CL.nodes or {}), npcs),
    }
    for _, w in ipairs(WANTED) do
        if (LC_CL.LayoutCount(w[1]) or 1) == 0 then lines[#lines + 1] = "  - " .. w[2] end
    end
    return table.concat(lines, "\n")
end

local goIndex = {}

function LC_CL.BuildLayoutBrowser(panel, modes)
    net.Start("lc_request")
    net.SendToServer()

    local glance = vgui.Create("DLabel")
    glance:SetWrap(true)
    glance:SetAutoStretchVertical(true)
    glance:SetTextColor(Color(40, 40, 40))
    glance:SetText("Loading the layout...")
    AlsoThink(glance, function(self)
        if (self.next or 0) > CurTime() then return end
        self.next = CurTime() + 1
        self:SetText(Glance())
    end)
    panel:AddItem(glance)

    local cv = GetConVar("livingcity_editor_mode")
    local function Current() return cv and cv:GetString() or "idle" end

    local clear = vgui.Create("DButton")
    clear:SetText("Stop finding everything")
    clear.DoClick = function() LC_CL.highlight = {} end
    panel:AddItem(clear)

    -- arranged by type (points, fixtures...) or by what it's for: the list is rebuilt in place
    local arrange = vgui.Create("DComboBox")
    arrange:AddChoice("Arrange by type: points, fixtures, zones, doors", "type", cvArrange:GetString() ~= "use")
    arrange:AddChoice("Arrange by what it's for: rebels, prison, each job...", "use", cvArrange:GetString() == "use")
    panel:AddItem(arrange)
    local holder = vgui.Create("DListLayout")
    panel:AddItem(holder)
    local Fill
    arrange.OnSelect = function(_, _, _, v) RunConsoleCommand("lc_editor_arrange", v) timer.Simple(0.1, function() if IsValid(holder) then Fill() end end) end

    local byId = {}
    for _, m in ipairs(modes) do byId[m.id] = m end
    local function Groups()
        local out = {}
        if cvArrange:GetString() == "use" then
            for _, o in ipairs(LCJ and LCJ.Occupations or {}) do
              -- (no workplace to place for the Block Warden or Infestation Cleanup; Cleanup still has its barrels and zones)
              local list = {}
              if not o.noWorkplace then list[1] = byId["work_" .. o.id] end
              for _, id in ipairs(JOB_EXTRAS[o.id] or {}) do if byId[id] then list[#list + 1] = byId[id] end end
              if #list > 0 then out[#out + 1] = { title = "Job: " .. o.name, list = list, sorted = true } end
            end
            for _, u in ipairs(USES) do
                local list = {}
                for _, id in ipairs(u.ids) do if byId[id] then list[#list + 1] = byId[id] end end
                table.insert(out, #out + 1, { title = u.title, list = list })
            end
            -- (daily life first, the jobs after it)
            local jobs = {}
            for i = #out, 1, -1 do if string.StartWith(out[i].title, "Job: ") then table.insert(jobs, 1, table.remove(out, i)) end end
            for i, j in ipairs(jobs) do table.insert(out, 1 + i, j) end
        else
            for _, c in ipairs(CATS) do
                local list = {}
                for _, m in ipairs(modes) do if CatOf(m) == c.key then list[#list + 1] = m end end
                out[#out + 1] = { title = c.title, list = list }
            end
        end
        return out
    end

    Fill = function()
    holder:Clear()
    for i, c in ipairs(Groups()) do
        local list = c.list
        table.sort(list, function(a, b) return string.lower(Short(a)) < string.lower(Short(b)) end) -- A to Z
        if #list > 0 then
            local cat = vgui.Create("DCollapsibleCategory")
            cat:SetExpanded(i == 1)
            AlsoThink(cat, function(self)
                if (self.next or 0) > CurTime() then return end
                self.next = CurTime() + 1
                local total, counted = 0, false
                for _, m in ipairs(list) do
                    local n = LC_CL.LayoutCount(m.id)
                    if n then total, counted = total + n, true end
                end
                self:SetLabel(c.title .. (counted and ("  (" .. total .. ")") or ""))
            end)
            cat:SetLabel(c.title)
            local body = vgui.Create("DListLayout")
            cat:SetContents(body)
            for _, m in ipairs(list) do
                local row = vgui.Create("DButton")
                row:SetTall(24)
                row:SetText("")
                row.count = LC_CL.LayoutCount(m.id)
                AlsoThink(row, function(self)
                    if (self.next or 0) > CurTime() then return end
                    self.next = CurTime() + 1
                    self.count = LC_CL.LayoutCount(m.id)
                end)
                row.Paint = function(self, w, h)
                    local sel = Current() == m.id
                    draw.RoundedBox(2, 0, 0, w, h, sel and Color(70, 120, 200) or (self:IsHovered() and Color(225, 230, 238) or Color(245, 245, 245)))
                    draw.SimpleText(Short(m), "DermaDefault", 6, h / 2, sel and color_white or Color(30, 30, 30), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                    local c = self.count
                    if type(c) == "number" then
                        draw.SimpleText(tostring(c), "DermaDefaultBold", w - 82, h / 2,
                            sel and color_white or (c > 0 and Color(30, 30, 30) or Color(170, 170, 170)), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
                    end
                end
                row:SetTooltip(m.label)
                row.DoClick = function() RunConsoleCommand("livingcity_editor_mode", m.id) end
                if row.count ~= nil then
                    local go = vgui.Create("DButton", row)
                    go:Dock(RIGHT)
                    go:SetWide(34)
                    go:SetText("Go")
                    go:SetTooltip("Take me to the next one (admins)")
                    go.DoClick = function()
                        local n = LC_CL.LayoutCount(m.id) or 0
                        if n == 0 then return end
                        goIndex[m.id] = (goIndex[m.id] or 0) % n + 1
                        RunConsoleCommand("lc_goto_layout", m.id, tostring(goIndex[m.id]))
                    end
                    local find = vgui.Create("DButton", row)
                    find:Dock(RIGHT)
                    find:SetWide(40)
                    AlsoThink(find, function(self) self:SetText(LC_CL.highlight[m.id] and "Hide" or "Find") end)
                    find:SetTooltip("Mark every one of these on screen, through walls")
                    find.DoClick = function() LC_CL.highlight[m.id] = not LC_CL.highlight[m.id] or nil end
                end
                body:Add(row)
            end
            holder:Add(cat)
        end
    end
    end
    Fill()
end

------------------------------------------------------------------------
-- Finding things: every one of a kind, marked through walls
------------------------------------------------------------------------

local COLORS = {
    zone_nogo = Color(255, 60, 60), zone_infest = Color(170, 220, 40), zone_prison = Color(255, 140, 40),
    zone_block = Color(180, 120, 255), zone_rebel = Color(230, 150, 70), zone_combine = Color(70, 140, 255),
}

local nextAsk = 0
-- (made once here, not every frame)
local C_255_230_0 = Color(255, 230, 0)
local V_0_0_40 = Vector(0, 0, 40)
hook.Add("HUDPaint", "LivingCityLayoutFinder", function()
    if not next(LC_CL.highlight) then return end
    -- the layout only comes to editors who ask for it
    if CurTime() > nextAsk then
        nextAsk = CurTime() + 10
        net.Start("lc_request")
        net.SendToServer()
    end
    local me = LocalPlayer():GetPos()
    for id in pairs(LC_CL.highlight) do
        local col = COLORS[id] or (LC_CL.PointColor and LC_CL.PointColor(id)) or C_255_230_0
        local name = string.upper(LC_CL.PointName and LC_CL.PointName(id) or id)
        for i, pos in ipairs(LC_CL.LayoutPositions(id)) do
            local s = (pos + V_0_0_40):ToScreen()
            if s.visible then
                local d = math.floor(me:Distance(pos) * 0.019)
                surface.SetDrawColor(col)
                surface.DrawRect(s.x - 5, s.y - 5, 10, 10)
                surface.SetDrawColor(0, 0, 0, 200)
                surface.DrawOutlinedRect(s.x - 6, s.y - 6, 12, 12)
                draw.SimpleTextOutlined(name .. " " .. i, "DermaDefaultBold", s.x, s.y - 10, col, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM, 1, color_black)
                draw.SimpleTextOutlined(d .. " m", "DermaDefault", s.x, s.y + 8, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, 1, color_black)
            end
        end
    end
end)
