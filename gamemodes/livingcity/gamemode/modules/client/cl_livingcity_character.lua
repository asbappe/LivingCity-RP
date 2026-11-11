--[[
    Living City (client): choosing who you are

    Shown when you first join, and again each time you start over as a new
    person: a name, and a face from the citizen models (any installed
    citizen pack too), then that face's skin and its clothes and
    accessories (bodygroups), one at a time with < and >. An admin can
    narrow what's offered: Job outfits > New characters choose from. The window says what
    kind of name fits (and the server enforces it). "Keep this one" accepts
    the random name and face you were given.

    In a city with Civil Intake (sv_livingcity_intake.lua) it's the
    registration form instead, opened at the terminal: nothing filled in for
    you (a button suggests an ordinary name if you're stuck), a description
    for the register, and no "keep what I was given".
]]

local INK, DIM, ACCENT, RED = Color(232, 226, 210), Color(170, 165, 150), Color(230, 180, 90), Color(225, 95, 80)
local PANEL = Color(16, 15, 13, 245)

surface.CreateFont("LCCreatorTitle", { font = "Trebuchet MS", size = 28, weight = 600 })
surface.CreateFont("LCCreatorText", { font = "Trebuchet MS", size = 17, weight = 500 })

local function ReadCompressed()
    local len = net.ReadUInt(32)
    local data = net.ReadData(len)
    local json = util.Decompress(data or "")
    return json and util.JSONToTable(json) or nil
end

local frame

local function Wrap(text, font, width)
    surface.SetFont(font)
    local lines, line = {}, ""
    for word in string.gmatch(tostring(text or ""), "%S+") do
        local try = line == "" and word or (line .. " " .. word)
        if line ~= "" and surface.GetTextSize(try) > width then
            lines[#lines + 1] = line
            line = word
        else
            line = try
        end
    end
    if line ~= "" then lines[#lines + 1] = line end
    return lines
end

local INTAKE_NOTE = "This is the Civil Intake terminal's registration screen. Enter who you are, then submit it; the terminal processes you while you wait beside it."

net.Receive("lcc_open", function()
    local data = ReadCompressed()
    if not data then return end
    if IsValid(frame) then frame:Remove() end
    local intake = data.intake == true

    local W, H = math.min(ScrW() - 40, 860), math.min(ScrH() - 40, intake and 700 or 620)
    -- the looks on offer: a path each, and what it may wear (sv_livingcity_outfits.lua)
    local looks = {}
    for _, m in ipairs(data.models or {}) do
        local l = istable(m) and m or { path = m }
        -- (a look this computer hasn't got would only show the ERROR model)
        if not util.IsValidModel or util.IsValidModel(l.path or "") or l.path == data.model then looks[#looks + 1] = l end
    end
    if #looks == 0 then for _, m in ipairs(data.models or {}) do looks[#looks + 1] = istable(m) and m or { path = m } end end
    local function LookOf(path) for _, l in ipairs(looks) do if l.path == path then return l end end end
    local chosenModel = data.model ~= "" and data.model or (looks[1] and looks[1].path) or ""
    local chosenSkin, chosenBG = tonumber(data.skin) or 0, istable(data.bg) and data.bg or {}
    frame = vgui.Create("DFrame")
    if LC_CL.SetTheme then LC_CL.SetTheme(frame, "ooc") end -- (out of character: cl_livingcity_theme.lua)
    frame:SetTitle("")
    frame:ShowCloseButton(false)
    frame:SetSize(W, H)
    frame:Center()
    frame:MakePopup()

    local noteLines = Wrap(intake and ((data.reminder or "") .. " " .. INTAKE_NOTE) or (data.reminder or ""), "LCCreatorText", W - 300 - 24)
    frame.Paint = function(self, w, h)
        draw.RoundedBox(6, 0, 0, w, h, PANEL)
        draw.SimpleText(intake and "CIVIL INTAKE: REGISTRATION" or (data.first and "WHO ARE YOU?" or "A NEW LIFE"), "LCCreatorTitle", 20, 14, ACCENT)
        draw.SimpleText((intake and "Number to be issued: " or "Citizen ") .. (data.cid or ""), "LCCreatorText", w - 20, 24, DIM, TEXT_ALIGN_RIGHT)
        local y = 70
        for _, l in ipairs(noteLines) do
            draw.SimpleText(l, "LCCreatorText", 300, y, DIM)
            y = y + 22
        end
        local errorText = self.errorMessage or ""
        if errorText ~= "" then
            local ey = h - 100
            for _, l in ipairs(Wrap(errorText, "LCCreatorText", w - 300 - 24)) do
                draw.SimpleText(l, "LCCreatorText", 300, ey, RED)
                ey = ey + 22
            end
        end
    end

    -- the face, turning slowly; under it, the face and clothes this look may wear
    local LOOK_H = 190
    local preview = vgui.Create("DModelPanel", frame)
    preview:SetPos(14, 56)
    preview:SetSize(270, H - 80 - LOOK_H)
    preview:SetModel(chosenModel)
    local lookPanel = vgui.Create("DScrollPanel", frame)
    lookPanel:SetPos(14, 56 + H - 80 - LOOK_H + 4)
    lookPanel:SetSize(270, LOOK_H - 8)

    local function Dress()
        local ent = preview:GetEntity()
        if not IsValid(ent) then return end
        ent:SetSkin(chosenSkin or 0)
        local groups = ent.GetBodyGroups and ent:GetBodyGroups()
        for _, g in ipairs(istable(groups) and groups or {}) do
            if istable(g) and g.id then ent:SetBodygroup(g.id, chosenBG[g.name] or 0) end
        end
    end

    -- one row: a label and < value >, cycling through what's allowed
    local function Cycler(label, values, current, names, onPick)
        local row = vgui.Create("DPanel", lookPanel)
        row:Dock(TOP)
        row:DockMargin(0, 0, 0, 3)
        row:SetTall(26)
        row.Paint = function(s, w, h) draw.RoundedBox(3, 0, 0, w, h, Color(30, 28, 25, 230)) end
        local idx = 1
        for i, v in ipairs(values) do if v == current then idx = i end end
        local text = vgui.Create("DLabel", row)
        text:Dock(FILL)
        text:DockMargin(30, 0, 30, 0)
        text:SetContentAlignment(5)
        text:SetTextColor(INK)
        local function Show() text:SetText(label .. ": " .. (names and names[values[idx]] or tostring(values[idx]))) end
        Show()
        local function Step(d)
            idx = (idx - 1 + d) % #values + 1
            Show()
            onPick(values[idx])
            Dress()
        end
        local l = vgui.Create("DButton", row) l:Dock(LEFT) l:SetWide(26) l:SetText("<") l.DoClick = function() Step(-1) end
        local r = vgui.Create("DButton", row) r:Dock(RIGHT) r:SetWide(26) r:SetText(">") r.DoClick = function() Step(1) end
    end

    local function BuildLook()
        lookPanel:Clear()
        local ent = preview:GetEntity()
        if not IsValid(ent) then return end
        local look = LookOf(chosenModel) or { path = chosenModel }
        local skins = {}
        if istable(look.skins) and #look.skins > 0 then skins = look.skins
        else for i = 0, math.max(0, (tonumber(ent.SkinCount and ent:SkinCount()) or 1) - 1) do skins[#skins + 1] = i end end
        if not table.HasValue(skins, chosenSkin) then chosenSkin = skins[1] or 0 end
        if #skins > 1 then
            local names = {}
            for i, v in ipairs(skins) do names[v] = string.format("%d of %d", i, #skins) end
            Cycler("Face", skins, chosenSkin, names, function(v) chosenSkin = v end)
        end
        local groups = ent.GetBodyGroups and ent:GetBodyGroups()
        for _, g in ipairs(istable(groups) and groups or {}) do
            local vals = {}
            if not istable(g) or not isstring(g.name) then g = { name = "", num = 0 } end
            if istable(look.bg) then vals = look.bg[g.name] or {}
            else for v = 0, (g.num or 1) - 1 do vals[#vals + 1] = v end end
            if #vals > 1 then
                if not table.HasValue(vals, chosenBG[g.name]) then chosenBG[g.name] = vals[1] end
                local names = {}
                for _, v in ipairs(vals) do
                    local sub = g.submodels and g.submodels[v]
                    names[v] = (sub and sub ~= "" and string.gsub(string.match(sub, "([^/]+)$") or sub, "%.smd$", "")) or ("option " .. v)
                end
                Cycler((string.gsub(g.name or "", "_", " ")), vals, chosenBG[g.name], names, function(v) chosenBG[g.name] = v end)
            elseif #vals == 1 then
                chosenBG[g.name] = vals[1]
            end
        end
        Dress()
    end
    BuildLook()
    preview:SetFOV(32)
    preview:SetCamPos(Vector(75, 0, 42))
    preview:SetLookAt(Vector(0, 0, 36))
    function preview:LayoutEntity(ent)
        ent:SetAngles(Angle(0, (RealTime() * 25) % 360, 0))
    end

    local nameLabel = vgui.Create("DLabel", frame)
    nameLabel:SetPos(300, 70 + #noteLines * 22 + 8)
    nameLabel:SetFont("LCCreatorText")
    nameLabel:SetTextColor(INK)
    nameLabel:SetText("Your name")
    nameLabel:SizeToContents()

    local entry = vgui.Create("DTextEntry", frame)
    entry:SetPos(300, nameLabel:GetY() + 22)
    entry:SetSize(W - 300 - 20 - (intake and 136 or 0), 30)
    entry:SetFont("LCCreatorText")
    entry:SetText(data.name or "")
    entry:SetUpdateOnType(false)
    frame.lcNameEntry = entry

    local below = entry
    local descEntry
    if intake then
        if entry.SetPlaceholderText then entry:SetPlaceholderText("First name and surname") end
        -- stuck for a name: an ordinary one, for the face picked
        local suggest = vgui.Create("DButton", frame)
        suggest:SetPos(W - 20 - 130, entry:GetY())
        suggest:SetSize(130, 30)
        suggest:SetText("Suggest a name")
        suggest.DoClick = function()
            net.Start("lcc_suggest")
            net.WriteString(chosenModel or "")
            net.SendToServer()
        end
        local descLabel = vgui.Create("DLabel", frame)
        descLabel:SetPos(300, entry:GetY() + 40)
        descLabel:SetFont("LCCreatorText")
        descLabel:SetTextColor(INK)
        descLabel:SetText("How a stranger would know you")
        descLabel:SizeToContents()
        descEntry = vgui.Create("DTextEntry", frame)
        descEntry:SetPos(300, descLabel:GetY() + 22)
        descEntry:SetSize(W - 300 - 20, 30)
        descEntry:SetFont("LCCreatorText")
        descEntry:SetText(data.desc or "")
        descEntry:SetUpdateOnType(false)
        if descEntry.SetPlaceholderText then descEntry:SetPlaceholderText("tall, grey coat, a scar over one eye") end
        below = descEntry
    end

    local facesLabel = vgui.Create("DLabel", frame)
    facesLabel:SetPos(300, below:GetY() + 42)
    facesLabel:SetFont("LCCreatorText")
    facesLabel:SetTextColor(INK)
    facesLabel:SetText("Your face (then its look, under the picture)")
    facesLabel:SizeToContents()

    local layout = vgui.Create("DIconLayout", frame)
    layout:SetPos(300, facesLabel:GetY() + 22)
    layout:SetSize(W - 300 - 20, H - (facesLabel:GetY() + 22) - 110)
    layout:SetSpaceX(4)
    layout:SetSpaceY(4)
    for _, look in ipairs(looks) do
        local path = look.path
        local icon = layout:Add("SpawnIcon")
        icon:SetSize(58, 58)
        icon:SetModel(path)
        icon.PaintOver = function(self, w, h)
            if chosenModel == path then
                surface.SetDrawColor(ACCENT.r, ACCENT.g, ACCENT.b, 255)
                surface.DrawOutlinedRect(0, 0, w, h, 3)
            end
        end
        icon.DoClick = function()
            if chosenModel ~= path then chosenSkin, chosenBG = 0, {} end
            chosenModel = path
            preview:SetModel(path)
            BuildLook()
        end
    end

    local function Button(text, x, w, fn)
        local b = vgui.Create("DButton", frame)
        b:SetPos(x, H - 56)
        b:SetSize(w, 38)
        b:SetText(text)
        b.DoClick = fn
        return b
    end

    local rightEdge = W - 20
    if intake then
        Button("Not now", 300, 120, function()
            net.Start("lcc_cancel")
            net.SendToServer()
            frame:Remove()
        end)
    else
        Button("Keep what I was given (ignores edits)", 300, 250, function()
            net.Start("lcc_keep")
            net.SendToServer()
            frame:Remove()
        end)
    end
    Button(intake and "Submit to the terminal" or "This is me", rightEdge - 170, 170, function()
        frame.errorMessage = ""
        net.Start("lcc_submit")
        net.WriteString(entry:GetValue())
        net.WriteString(chosenModel)
        net.WriteString(descEntry and descEntry:GetValue() or "")
        net.WriteUInt(math.Clamp(chosenSkin or 0, 0, 255), 8)
        net.WriteString(util.TableToJSON(chosenBG or {}) or "{}")
        net.SendToServer()
    end)

    frame.OnRemove = function() end
end)

-- A suggested name, into the box.
net.Receive("lcc_suggested", function()
    local name = net.ReadString()
    if IsValid(frame) and IsValid(frame.lcNameEntry) and name and name ~= "" then frame.lcNameEntry:SetText(name) end
end)

-- The server says yes, or why not.
net.Receive("lcc_result", function()
    local ok, msg = net.ReadBool(), net.ReadString()
    if ok then
        if IsValid(frame) then frame:Remove() end
        chat.AddText(Color(120, 200, 255), "[Miscount] ", color_white, "You are " .. msg .. ".")
    elseif IsValid(frame) then
        frame.errorMessage = msg
    end
end)
