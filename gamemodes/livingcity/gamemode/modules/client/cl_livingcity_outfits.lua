--[[
    Living City (client): the job outfit designer (sv_livingcity_outfits.lua)

    Editor panel > Job outfits, or !outfits (admin). Pick a job on the left,
    a model from what's installed, tick the skins and bodygroup pieces that
    fit (the preview shows the last thing ticked), Add this look, and Save
    the job. A job can have several looks; each person gets one of them.
]]

LC_CL = LC_CL or {}

local INK, DIM = Color(232, 230, 224), Color(160, 160, 160)
local FACE = "{face}"
local frame

local function ReadCompressed()
    local len = net.ReadUInt(32)
    local data = net.ReadData(len)
    local json = util.Decompress(data or "")
    return json and util.JSONToTable(json) or nil
end

local function SaveJob(job, list)
    local data = util.Compress(util.TableToJSON({ job = job, list = list }) or "{}")
    if not data then return end
    net.Start("lc_outfits_save")
    net.WriteUInt(#data, 32)
    net.WriteData(data, #data)
    net.SendToServer()
end

local function FaceOf(path) return path and string.match(string.lower(path), "((f?e?male)_%d+)%.mdl$") or nil end

-- every playermodel the game knows about, by name
local function Installed()
    local out = {}
    for name, path in pairs(player_manager and player_manager.AllValidModels and player_manager.AllValidModels() or {}) do
        out[#out + 1] = { name = name, path = path }
    end
    table.sort(out, function(a, b) return a.name < b.name end)
    return out
end

local function Set(list) local s = {} for _, v in ipairs(list or {}) do s[v] = true end return s end
local function List(set) local l = {} for v in pairs(set or {}) do l[#l + 1] = v end table.sort(l) return l end

local function Describe(e)
    local n = 0
    for _ in pairs(e.bg or {}) do n = n + 1 end
    local base = string.match(e.pm or "", "([^/]+)%.mdl$") or e.pm or "?"
    return string.format("%s%s   (%d skins, %d pieces)", string.find(e.pm or "", FACE, 1, true) and "own face, " or "", string.gsub(base, "{face}", "*"), #(e.skins or {}), n)
end

function LC_CL.OpenOutfitDesigner(t)
    if IsValid(frame) then frame:Remove() end
    local outfits = t.outfits or {}
    local job -- the job being dressed
    local look = { pm = nil, npc = "", skins = {}, bg = {}, own = false }
    local shown = { skin = 0, bg = {} } -- what the preview wears

    frame = vgui.Create("DFrame")
    frame:SetTitle("Job outfits")
    frame:SetSize(math.min(ScrW() - 40, 1000), math.min(ScrH() - 40, 640))
    frame:Center()
    frame:MakePopup()

    local jobs = vgui.Create("DListView", frame)
    jobs:Dock(LEFT)
    jobs:SetWide(190)
    jobs:AddColumn("Job")
    jobs:SetMultiSelect(false)

    local side = vgui.Create("DScrollPanel", frame)
    side:Dock(RIGHT)
    side:SetWide(340)

    local mid = vgui.Create("DPanel", frame)
    mid:Dock(FILL)
    mid.Paint = nil

    local looks = vgui.Create("DListView", mid)
    looks:Dock(BOTTOM)
    looks:SetTall(130)
    looks:AddColumn("Looks for this job (each person gets one)")
    looks:SetMultiSelect(false)

    local btns = vgui.Create("DPanel", mid)
    btns:Dock(BOTTOM)
    btns:SetTall(30)
    btns.Paint = nil

    local preview = vgui.Create("DModelPanel", mid)
    preview:Dock(FILL)
    preview:SetFOV(38)
    preview.LayoutEntity = function(s, ent) ent:SetAngles(Angle(0, CurTime() * 20 % 360, 0)) end

    local function PathFor(p) return p and string.gsub(p, "{face}", "male_07") or nil end

    local function Dress()
        local ent = preview:GetEntity()
        if not IsValid(ent) then return end
        ent:SetSkin(shown.skin or 0)
        for _, g in ipairs(ent:GetBodyGroups() or {}) do
            if shown.bg[g.name] then ent:SetBodygroup(g.id, shown.bg[g.name]) end
        end
    end

    local function RefreshLooks()
        looks:Clear()
        for _, e in ipairs(job and outfits[job] and outfits[job].list or {}) do looks:AddLine(Describe(e)) end
    end

    local Rebuild
    local function SetModel(path)
        look = { pm = path, npc = "", skins = {}, bg = {}, own = false }
        shown = { skin = 0, bg = {} }
        Rebuild()
    end

    function Rebuild()
        side:Clear()
        local function Label(text, col)
            local l = vgui.Create("DLabel", side)
            l:Dock(TOP)
            l:DockMargin(6, 6, 6, 0)
            l:SetText(text)
            l:SetTextColor(col or INK)
            l:SetWrap(true)
            l:SetAutoStretchVertical(true)
            return l
        end
        if not job then Label("Pick a job on the left.", DIM) return end
        Label("Model (anything installed: citizens, medics, hostages, a pack)")
        local combo = vgui.Create("DComboBox", side)
        combo:Dock(TOP)
        combo:DockMargin(6, 2, 6, 0)
        combo:SetValue(look.pm and (string.match(look.pm, "([^/]+)%.mdl$") or look.pm) or "Choose a model...")
        for _, m in ipairs(Installed()) do combo:AddChoice(m.name .. "  (" .. m.path .. ")", m.path) end
        combo.OnSelect = function(_, _, _, path) SetModel(path) end
        if not look.pm then return end
        preview:SetModel(PathFor(look.pm))
        local ent = preview:GetEntity()
        if FaceOf(look.pm) or look.own then
            local own = vgui.Create("DCheckBoxLabel", side)
            own:Dock(TOP)
            own:DockMargin(6, 6, 6, 0)
            own:SetText("Keep each person's own face (a Half-Life 2 citizen face, in these clothes)")
            own:SetValue(look.own)
            own.OnChange = function(_, v)
                look.own = v
                local face = FaceOf(look.pm)
                if v and face then look.pm = string.gsub(look.pm, face, FACE, 1) end
            end
        end
        Label("NPC model (blank: worked out from the playermodel)", DIM)
        local npc = vgui.Create("DTextEntry", side)
        npc:Dock(TOP)
        npc:DockMargin(6, 2, 6, 0)
        npc:SetValue(look.npc or "")
        npc.OnChange = function(s) look.npc = s:GetValue() end
        if not IsValid(ent) then return end
        local skins = ent:SkinCount() or 1
        if skins > 1 then
            Label(string.format("Skins it may wear (%d): none ticked means any", skins))
            for i = 0, skins - 1 do
                local cb = vgui.Create("DCheckBoxLabel", side)
                cb:Dock(TOP)
                cb:DockMargin(14, 2, 6, 0)
                cb:SetText("Skin " .. i)
                cb:SetValue(look.skins[i] == true)
                cb.OnChange = function(_, v) look.skins[i] = v or nil shown.skin = i Dress() end
            end
        end
        for _, g in ipairs(ent:GetBodyGroups() or {}) do
            if (g.num or 1) > 1 then
                Label(g.name .. ": the pieces it may show (none ticked: left as it is)")
                look.bg[g.name] = look.bg[g.name] or {}
                for v = 0, g.num - 1 do
                    local cb = vgui.Create("DCheckBoxLabel", side)
                    cb:Dock(TOP)
                    cb:DockMargin(14, 2, 6, 0)
                    local sub = g.submodels and g.submodels[v]
                    cb:SetText((sub and sub ~= "" and string.match(sub, "([^/]+)$") or ("piece " .. v)))
                    cb:SetValue(look.bg[g.name][v] == true)
                    cb.OnChange = function(_, on) look.bg[g.name][v] = on or nil shown.bg[g.name] = v Dress() end
                end
            end
        end
        Dress()
    end

    local function Button(text, fn)
        local b = vgui.Create("DButton", btns)
        b:Dock(LEFT)
        b:DockMargin(0, 2, 6, 2)
        b:SetWide(170)
        b:SetText(text)
        b.DoClick = fn
    end
    Button("Add this look", function()
        if not job or not look.pm then return end
        local e = { pm = look.pm, npc = look.npc ~= "" and look.npc or nil, skins = List(look.skins), bg = {} }
        for name, set in pairs(look.bg) do
            local l = List(set)
            if #l > 0 then e.bg[name] = l end
        end
        outfits[job] = outfits[job] or { list = {} }
        table.insert(outfits[job].list, e)
        RefreshLooks()
    end)
    Button("Remove the selected look", function()
        local line = looks:GetSelectedLine()
        if not job or not line or not outfits[job] then return end
        table.remove(outfits[job].list, line)
        RefreshLooks()
    end)
    Button("Save this job", function()
        if job then SaveJob(job, outfits[job] and outfits[job].list or {}) end
    end)

    for _, j in ipairs(t.jobs or {}) do
        local line = jobs:AddLine(j.name)
        line.lcJob = j.id
    end
    jobs.OnRowSelected = function(_, _, line)
        job = line.lcJob
        look = { pm = nil, npc = "", skins = {}, bg = {}, own = false }
        RefreshLooks()
        Rebuild()
    end
    Rebuild()
end

net.Receive("lc_outfits_open", function()
    local t = ReadCompressed()
    if t then LC_CL.OpenOutfitDesigner(t) end
end)
