--[[
    Living City (client): choosing who you are

    Shown when you first join, and again each time you start over as a new
    person: a name, and a face from the citizen models. The window says what
    kind of name fits (and the server enforces it). "Keep this one" accepts
    the random name and face you were given.
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

net.Receive("lcc_open", function()
    local data = ReadCompressed()
    if not data then return end
    if IsValid(frame) then frame:Remove() end

    local W, H = math.min(ScrW() - 40, 820), math.min(ScrH() - 40, 560)
    local chosenModel = data.model ~= "" and data.model or (data.models and data.models[1]) or ""
    frame = vgui.Create("DFrame")
    frame:SetTitle("")
    frame:ShowCloseButton(false)
    frame:SetSize(W, H)
    frame:Center()
    frame:MakePopup()

    local noteLines = Wrap(data.reminder or "", "LCCreatorText", W - 300 - 24)
    frame.Paint = function(self, w, h)
        draw.RoundedBox(6, 0, 0, w, h, PANEL)
        draw.SimpleText(data.first and "WHO ARE YOU?" or "A NEW LIFE", "LCCreatorTitle", 20, 14, ACCENT)
        draw.SimpleText("Citizen " .. (data.cid or ""), "LCCreatorText", w - 20, 24, DIM, TEXT_ALIGN_RIGHT)
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

    -- the face, turning slowly
    local preview = vgui.Create("DModelPanel", frame)
    preview:SetPos(14, 56)
    preview:SetSize(270, H - 80)
    preview:SetModel(chosenModel)
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
    entry:SetSize(W - 300 - 20, 30)
    entry:SetFont("LCCreatorText")
    entry:SetText(data.name or "")
    entry:SetUpdateOnType(false)

    local facesLabel = vgui.Create("DLabel", frame)
    facesLabel:SetPos(300, entry:GetY() + 42)
    facesLabel:SetFont("LCCreatorText")
    facesLabel:SetTextColor(INK)
    facesLabel:SetText("Your face")
    facesLabel:SizeToContents()

    local layout = vgui.Create("DIconLayout", frame)
    layout:SetPos(300, facesLabel:GetY() + 22)
    layout:SetSize(W - 300 - 20, H - (facesLabel:GetY() + 22) - 110)
    layout:SetSpaceX(4)
    layout:SetSpaceY(4)
    for _, path in ipairs(data.models or {}) do
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
            chosenModel = path
            preview:SetModel(path)
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
    Button("Keep the name and face I was given", 300, 250, function()
        net.Start("lcc_keep")
        net.SendToServer()
        frame:Remove()
    end)
    Button("This is me", rightEdge - 140, 140, function()
        frame.errorMessage = ""
        net.Start("lcc_submit")
        net.WriteString(entry:GetValue())
        net.WriteString(chosenModel)
        net.SendToServer()
    end)

    frame.OnRemove = function() end
end)

-- The server says yes, or why not.
net.Receive("lcc_result", function()
    local ok, msg = net.ReadBool(), net.ReadString()
    if ok then
        if IsValid(frame) then frame:Remove() end
        chat.AddText(Color(120, 200, 255), "[Living City] ", color_white, "You are " .. msg .. ".")
    elseif IsValid(frame) then
        frame.errorMessage = msg
    end
end)
