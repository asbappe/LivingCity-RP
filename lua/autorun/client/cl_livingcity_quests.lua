--[[
    Living City quests (client): the job board (F3 / !jobs), the dialogue
    window for choices, and the tracker with an objective marker.
]]

local function ReadCompressed()
    local len = net.ReadUInt(32)
    local data = net.ReadData(len)
    local json = util.Decompress(data or "")
    return json and util.JSONToTable(json) or nil
end

local INK = Color(232, 226, 210)
local DIM = Color(170, 165, 150)
local ACCENT = Color(230, 180, 90)
local RED = Color(220, 90, 80)
local PANEL = Color(16, 15, 13, 240)
local STORY = Color(175, 140, 235)

local SKILL_COLORS = {
    authority = Color(110, 160, 255), empathy = Color(120, 210, 150),
    guile = Color(220, 150, 220), nerve = Color(240, 200, 90),
}

local state = { active = false }
local board

------------------------------------------------------------------------
-- Board
------------------------------------------------------------------------

local function Trait(name, v)
    return string.format("%s %d", name, v or 0)
end

net.Receive("lcq_board", function()
    local data = ReadCompressed()
    if not data then return end
    if IsValid(board) then board:Remove() end

    board = vgui.Create("DFrame")
    board:SetTitle("")
    board:SetSize(math.min(ScrW() - 60, 760), math.min(ScrH() - 60, 640))
    board:Center()
    board:MakePopup()
    board.Paint = function(self, w, h)
        draw.RoundedBox(4, 0, 0, w, h, PANEL)
        draw.SimpleText(string.upper(data.board), "DermaLarge", 18, 14, ACCENT)
        local t = data.traits or {}
        draw.SimpleText(Trait("Loyalty", t.loyalty) .. "     " .. Trait("Sympathy", t.sympathy) .. "     " .. Trait("Corruption", t.corruption),
            "DermaDefault", w - 40, 24, DIM, TEXT_ALIGN_RIGHT)
    end

    local scroll = vgui.Create("DScrollPanel", board)
    scroll:Dock(FILL)
    scroll:DockMargin(6, 26, 6, 6)

    if data.jobs then
        local card = vgui.Create("DPanel", scroll)
        card:Dock(TOP)
        card:DockMargin(0, 0, 0, 10)
        card:DockPadding(14, 10, 10, 10)
        card:SetTall(66)
        card.Paint = function(self, w, h)
            draw.RoundedBox(4, 0, 0, w, h, Color(30, 28, 24, 240))
            draw.RoundedBox(0, 0, 0, 3, h, Color(200, 150, 100))
            local cur = LCJ and LCJ.ById[data.jobs.current]
            draw.SimpleText("UNION EMPLOYMENT", "DermaDefault", 14, 10, DIM)
            draw.SimpleText(cur and cur.name or "Unemployed", "DermaLarge", 14, 26, INK)
        end
        local combo = vgui.Create("DComboBox", card)
        combo:Dock(RIGHT)
        combo:SetWide(230)
        combo:DockMargin(0, 12, 0, 12)
        combo:SetValue("Change job...")
        for _, j in ipairs(data.jobs.list) do combo:AddChoice(j.name, j.id) end
        combo.OnSelect = function(_, _, _, id)
            net.Start("lcj_set")
            net.WriteString(id)
            net.SendToServer()
            board:Close()
        end
    end

    if data.wait and data.wait > 0 and not data.active then
        local w = vgui.Create("DLabel", scroll)
        w:Dock(TOP)
        w:SetTextColor(DIM)
        w:SetText("You can take another job in " .. data.wait .. " seconds.")
        w:SizeToContents()
    end

    if #data.postings == 0 then
        local none = vgui.Create("DLabel", scroll)
        none:Dock(TOP)
        none:SetTextColor(DIM)
        none:SetText("Nothing posted right now. Check back soon.")
        none:SizeToContents()
    end

    for _, p in ipairs(data.postings) do
        local card = vgui.Create("DPanel", scroll)
        card:Dock(TOP)
        card:DockMargin(0, 0, 0, 8)
        card:DockPadding(14, 10, 10, 10)
        card.Paint = function(self, w, h)
            draw.RoundedBox(4, 0, 0, w, h, Color(30, 28, 24, 240))
            draw.RoundedBox(0, 0, 0, p.story and 5 or 3, h, p.story and STORY or (p.violent and RED or ACCENT))
        end

        if p.story then
            local tag = vgui.Create("DLabel", card)
            tag:Dock(TOP)
            tag:SetFont("DermaDefaultBold")
            tag:SetTextColor(STORY)
            tag:SetText("YOUR STORY")
            tag:SizeToContents()
        end

        local title = vgui.Create("DLabel", card)
        title:Dock(TOP)
        title:SetFont("DermaLarge")
        title:SetTextColor(INK)
        title:SetText(p.title)
        title:SizeToContents()

        local desc = vgui.Create("DLabel", card)
        desc:Dock(TOP)
        desc:DockMargin(0, 4, 0, 0)
        desc:SetWrap(true)
        desc:SetAutoStretchVertical(true)
        desc:SetTextColor(DIM)
        desc:SetText(p.desc or "")

        local meta = vgui.Create("DLabel", card)
        meta:Dock(TOP)
        meta:DockMargin(0, 6, 0, 0)
        meta:SetTextColor(p.violent and RED or ACCENT)
        meta:SetText(string.format("%d XP   |   %d minutes%s%s", p.reward or 0, math.ceil((p.limit or 300) / 60),
            p.violent and "   |   violent" or "", (not p.story and p.taken > 0) and string.format("   |   %d/%d on it", p.taken, p.max) or ""))
        meta:SizeToContents()

        local b = vgui.Create("DButton", card)
        b:Dock(TOP)
        b:DockMargin(0, 8, 0, 0)
        b:SetTall(26)
        if p.mine then
            b:SetText("Abandon")
            b.DoClick = function()
                net.Start("lcq_abandon")
                net.SendToServer()
                board:Close()
            end
        elseif p.story then
            b:SetText("Begin")
            b:SetEnabled(not data.active)
        elseif p.taken > 0 then
            b:SetText(p.taken < p.max and "Join the squad" or "Full")
            b:SetEnabled(p.taken < p.max and not data.active)
        else
            b:SetText("Take the job")
            b:SetEnabled(not data.active)
        end
        if not p.mine then
            b.DoClick = function()
                net.Start("lcq_accept")
                net.WriteUInt(p.id, 32)
                net.SendToServer()
                board:Close()
            end
        end

        card:InvalidateLayout(true)
        card:SizeToChildren(false, true)
    end
end)

------------------------------------------------------------------------
-- Choices
------------------------------------------------------------------------

local dialog

surface.CreateFont("LCChoicePrompt", { font = "Trebuchet MS", size = 20, weight = 500 })
surface.CreateFont("LCChoiceOption", { font = "Trebuchet MS", size = 17, weight = 500 })

-- Breaks text into lines that fit a pixel width.
local function WrapLines(text, font, width)
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
    if line ~= "" or #lines == 0 then lines[#lines + 1] = line end
    return lines
end

net.Receive("lcq_choice_open", function()
    local data = ReadCompressed()
    if not data then return end
    if IsValid(dialog) then dialog:Remove() end

    local W = math.min(ScrW() - 60, 640)
    local PROMPT_LH, OPT_LH, PAD = 24, 20, 16
    local promptLines = WrapLines(data.prompt, "LCChoicePrompt", W - PAD * 2)
    local promptH = #promptLines * PROMPT_LH

    -- every option gets as many lines as it needs
    local rows = {}
    for n, o in ipairs(data.options) do
        local tag = o.skill and string.format("[%s %d]", string.upper(o.skill), o.dc) or nil
        local chance = o.skill and math.Clamp(math.floor((21 - (o.dc - (o.mod or 0))) / 20 * 100), 5, 95) or nil
        surface.SetFont("DermaDefaultBold")
        local tagW = tag and (surface.GetTextSize(tag) + 10) or 0
        local chanceW = chance and 48 or 0
        local textW = W - PAD * 2 - 24 - tagW - chanceW
        local lines = WrapLines(n .. ". " .. o.text, "LCChoiceOption", textW)
        rows[n] = { o = o, tag = tag, chance = chance, tagW = tagW, lines = lines, h = math.max(40, #lines * OPT_LH + 16) }
    end
    local optsH = 0
    for _, r in ipairs(rows) do optsH = optsH + r.h + 6 end

    local head = 36 + promptH + 14
    local maxH = ScrH() - 60
    local H = math.min(maxH, head + optsH + PAD)
    dialog = vgui.Create("DFrame")
    dialog:SetTitle("")
    dialog:ShowCloseButton(false)
    dialog:SetSize(W, H)
    dialog:SetPos(math.max(10, ScrW() - W - 30), math.max(10, ScrH() / 2 - H / 2))
    dialog:MakePopup()
    dialog.Paint = function(self, w, h)
        draw.RoundedBox(4, 0, 0, w, h, PANEL)
        draw.SimpleText(string.upper(data.title or ""), "DermaDefaultBold", PAD, 12, ACCENT)
        for i, l in ipairs(promptLines) do
            draw.SimpleText(l, "LCChoicePrompt", PAD, 36 + (i - 1) * PROMPT_LH, INK)
        end
    end

    -- scrolls if the choices are taller than the screen
    local scroll = vgui.Create("DScrollPanel", dialog)
    scroll:SetPos(PAD - 6, head)
    scroll:SetSize(W - (PAD - 6) * 2, H - head - 10)

    for n, r in ipairs(rows) do
        local o = r.o
        local b = vgui.Create("DButton", scroll)
        b:Dock(TOP)
        b:DockMargin(6, 0, 6, 6)
        b:SetTall(r.h)
        b:SetText("")
        b.Paint = function(self, w, h)
            local hover = self:IsHovered()
            draw.RoundedBox(3, 0, 0, w, h, hover and Color(50, 46, 38) or Color(30, 28, 24))
            local x = 10
            if r.tag then
                draw.SimpleText(r.tag, "DermaDefaultBold", x, h / 2, SKILL_COLORS[o.skill] or ACCENT, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                x = x + r.tagW
            end
            local ty = (h - #r.lines * OPT_LH) / 2
            for i, l in ipairs(r.lines) do
                draw.SimpleText(l, "LCChoiceOption", x, ty + (i - 1) * OPT_LH, hover and color_white or INK)
            end
            if r.chance then draw.SimpleText(r.chance .. "%", "DermaDefaultBold", w - 10, h / 2, DIM, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER) end
        end
        b.DoClick = function()
            net.Start("lcq_choice")
            net.WriteUInt(data.qid, 32)
            net.WriteUInt(o.i, 8)
            net.SendToServer()
            dialog:Remove()
        end
    end
end)

------------------------------------------------------------------------
-- Tracker
------------------------------------------------------------------------

net.Receive("lcq_state", function()
    state = ReadCompressed() or { active = false }
    state.received = CurTime()
    if not state.active and IsValid(dialog) then dialog:Remove() end
end)

hook.Add("InitPostEntity", "LivingCityQuestsSync", function()
    timer.Simple(5, function()
        net.Start("lcq_request")
        net.SendToServer()
    end)
end)

local function Wrap(text, font, width)
    surface.SetFont(font)
    local lines, line = {}, ""
    for word in string.gmatch(text, "%S+") do
        local try = line == "" and word or (line .. " " .. word)
        if surface.GetTextSize(try) > width and line ~= "" then
            lines[#lines + 1] = line
            line = word
        else
            line = try
        end
    end
    if line ~= "" then lines[#lines + 1] = line end
    return lines
end

-- Where the objective really is (the marker is drawn a little above it; the compass
-- measures up and down to the thing itself).
local function RawObjectivePos()
    if state.ent then
        local e = Entity(state.ent)
        if IsValid(e) then return e:GetPos() end
    end
    if state.pos then return Vector(state.pos[1], state.pos[2], state.pos[3]) end
    return nil
end

local function ObjectivePos()
    if state.ent then
        local e = Entity(state.ent)
        if IsValid(e) then return e:GetPos() + Vector(0, 0, 80) end
    end
    if state.pos then return Vector(state.pos[1], state.pos[2], state.pos[3] + 60) end
    return nil
end

local HEADINGS = { "ahead", "ahead left", "left", "behind left", "behind", "behind right", "right", "ahead right" }

-- Where the objective is, relative to where you're looking: a heading, a
-- distance, and whether it's up or down (about 140 units to a floor).
local function Compass(target)
    local me = LocalPlayer()
    local delta = target - me:GetPos()
    local rel = math.NormalizeAngle(delta:Angle().y - EyeAngles().y) -- 0 ahead, +left
    local bucket = math.floor((rel + 22.5) / 45) % 8 + 1
    local dz = delta.z
    -- anything more than a flight of stairs away counts: 48 units is "other level", then about 144 to a floor
    local floors = math.abs(dz) < 48 and 0 or math.max(1, math.floor(math.abs(dz) / 144 + 0.5))
    local level = "same level"
    if floors >= 1 then level = string.format("%d floor%s %s", floors, floors == 1 and "" or "s", dz > 0 and "UP" or "DOWN") end
    local flat = Vector(delta.x, delta.y, 0):Length()
    return rel, HEADINGS[bucket], math.floor(flat * 0.019), level, dz
end

local function DrawArrow(cx, cy, rel, col)
    -- a little arrow that points the way: up on screen is straight ahead
    local a = math.rad(rel)
    local function P(r, off) local t = a + off return { x = cx - math.sin(t) * r, y = cy - math.cos(t) * r } end
    surface.SetDrawColor(col.r, col.g, col.b, 255)
    draw.NoTexture()
    surface.DrawPoly({ P(13, 0), P(10, math.rad(140)), P(4, math.rad(180)), P(10, math.rad(-140)) })
end

hook.Add("HUDPaint", "LivingCityQuestsTracker", function()
    if not state.active then return end
    local w = ScrW()
    local x, y, bw = w - 340, 120, 320
    local left = math.max(0, (state.left or 0) - (CurTime() - (state.received or CurTime())))
    local compassTarget = RawObjectivePos()

    local lines = Wrap(state.objective or "", "DermaDefault", bw - 24)
    local narr = state.narration and Wrap(state.narration, "DermaDefault", bw - 24) or {}
    local h = 54 + #lines * 16 + (state.progress and 16 or 0) + (#narr > 0 and (#narr * 15 + 8) or 0) + (state.choice and 18 or 0) + (compassTarget and 34 or 0)
    draw.RoundedBox(4, x, y, bw, h, Color(16, 15, 13, 210))
    draw.RoundedBox(0, x, y, 3, h, ACCENT)
    draw.SimpleText(string.upper(state.board or "") .. string.format("   step %d/%d", state.step or 1, state.steps or 1), "DermaDefault", x + 12, y + 8, DIM)
    draw.SimpleText(state.title or "", "DermaDefaultBold", x + 12, y + 24, INK)
    draw.SimpleText(string.FormattedTime(left, "%02i:%02i"), "DermaDefault", x + bw - 10, y + 8, left < 60 and RED or DIM, TEXT_ALIGN_RIGHT)

    local ly = y + 44
    for _, l in ipairs(lines) do
        draw.SimpleText(l, "DermaDefault", x + 12, ly, ACCENT)
        ly = ly + 16
    end
    if state.progress then
        draw.SimpleText(state.progress, "DermaDefaultBold", x + 12, ly, INK)
        ly = ly + 16
    end
    if state.choice then
        draw.SimpleText(state.owner and "A choice is waiting (it may be behind other windows)" or "Your squad leader is deciding...", "DermaDefault", x + 12, ly, DIM)
        ly = ly + 18
    end
    if #narr > 0 then
        ly = ly + 6
        for _, l in ipairs(narr) do
            draw.SimpleText(l, "DermaDefault", x + 12, ly, DIM)
            ly = ly + 15
        end
    end

    -- compass: heading, distance and up or down, for when the marker is off screen
    if compassTarget then
        local rel, heading, meters, level, dz = Compass(compassTarget)
        ly = ly + 8
        draw.RoundedBox(3, x + 8, ly - 4, bw - 16, 30, Color(30, 28, 24, 220))
        DrawArrow(x + 28, ly + 11, rel, ACCENT)
        draw.SimpleText(string.format("%d m, %s", meters, heading), "DermaDefaultBold", x + 50, ly + 1, INK)
        draw.SimpleText(level, "DermaDefaultBold", x + 50, ly + 14, dz > 48 and Color(120, 200, 255) or (dz < -48 and Color(255, 170, 110) or DIM))
    end

    -- objective marker
    local target = ObjectivePos()
    if not target then return end
    local s = target:ToScreen()
    local dist = math.floor(LocalPlayer():GetPos():Distance(target) * 0.019)
    local sw, sh = ScrW(), ScrH()
    if s.visible and s.x > 40 and s.x < sw - 40 and s.y > 40 and s.y < sh - 40 then
        draw.SimpleTextOutlined("v", "DermaLarge", s.x, s.y, ACCENT, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 2, color_black)
        draw.SimpleTextOutlined(dist .. " m", "DermaDefaultBold", s.x, s.y + 20, INK, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, color_black)
    else
        local yawTo = (target - LocalPlayer():GetPos()):Angle().y
        local rel = math.rad(math.NormalizeAngle(yawTo - EyeAngles().y))
        local ax, ay = sw / 2 - math.sin(rel) * (sh * 0.4), sh / 2 - math.cos(rel) * (sh * 0.4)
        draw.SimpleTextOutlined("objective  " .. dist .. " m", "DermaDefaultBold", ax, ay, ACCENT, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, color_black)
    end
end)

-- Highlight the quest target so it stands out in a crowd.
hook.Add("PreDrawHalos", "LivingCityQuestsHalo", function()
    if not state.active or not state.ent then return end
    local e = Entity(state.ent)
    if IsValid(e) and (e:IsNPC() or e:GetClass() == "prop_physics") then halo.Add({ e }, ACCENT, 2, 2, 1, true, false) end
end)
