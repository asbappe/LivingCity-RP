--[[
    Living City quests (client): the job board (F4 > Jobs / !jobs), the dialogue
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

------------------------------------------------------------------------
-- Board
------------------------------------------------------------------------

local function Trait(name, v)
    return string.format("%s %d", name, v or 0)
end

-- The board, built into F4's Jobs tab (cl_livingcity_hub.lua). Its buttons shut the window, as the board's did.
local function Close() if LC_CL.CloseHub then LC_CL.CloseHub() end end

local function BuildBoard(parent, data)
    local head = vgui.Create("DPanel", parent)
    head:Dock(TOP)
    head:SetTall(40)
    head.Paint = function(self, w, h)
        draw.SimpleText(string.upper(data.board or ""), "DermaLarge", 12, 4, ACCENT)
        local t = data.traits or {}
        draw.SimpleText(Trait("Loyalty", t.loyalty) .. "     " .. Trait("Sympathy", t.sympathy) .. "     " .. Trait("Corruption", t.corruption),
            "DermaDefault", w - 12, 14, DIM, TEXT_ALIGN_RIGHT)
    end

    local scroll = vgui.Create("DScrollPanel", parent)
    scroll:Dock(FILL)
    scroll:DockMargin(4, 0, 4, 4)

    if data.jobs then
        local card = vgui.Create("DPanel", scroll)
        card:Dock(TOP)
        card:DockMargin(0, 0, 0, 10)
        card:DockPadding(14, 10, 10, 10)
        local desk = data.jobs.desk -- (a Labor Assignment terminal in the city: jobs are changed there, in person)
        card:SetTall(desk and 92 or 66)
        card.Paint = function(self, w, h)
            draw.RoundedBox(4, 0, 0, w, h, Color(30, 28, 24, 240))
            draw.RoundedBox(0, 0, 0, 3, h, Color(200, 150, 100))
            local cur = LCJ and LCJ.ById[data.jobs.current]
            draw.SimpleText("UNION EMPLOYMENT", "DermaDefault", 14, 10, DIM)
            draw.SimpleText(cur and cur.name or "Unemployed", "DermaLarge", 14, 26, INK)
            if desk then draw.SimpleText(data.jobs.lockLine or "Go to a Labor Assignment terminal to change your assignment.", "DermaDefault", 14, 68, ACCENT) end
        end
        if desk then
            local way = vgui.Create("DButton", card)
            way:Dock(RIGHT)
            way:SetWide(230)
            way:DockMargin(0, 12, 0, 36)
            way:SetText("Show me the way to Labor Assignment")
            way:SetTooltip("Jobs are given out and changed at a Labor Assignment terminal, in person.")
            way.DoClick = function()
                if LC_CL.SendAction then LC_CL.SendAction("waypoint", "labor") end
                Close()
            end
        end
        local combo = (not desk) and vgui.Create("DComboBox", card)
        if combo then
            combo:Dock(RIGHT)
            combo:SetWide(230)
            combo:DockMargin(0, 12, 0, 12)
            combo:SetValue("Change job...")
            -- grouped by career path: the Civil Protection path, the Administration path, then the rest of Union work
            local first = true
            for _, path in ipairs(LCJ and LCJ.Paths or { { id = "", name = "" } }) do
                local any = false
                for _, j in ipairs(data.jobs.list) do
                    if (j.path or "") == path.id then
                        if not any and not first and combo.AddSpacer then combo:AddSpacer() end
                        any = true
                        combo:AddChoice(j.name .. "   (" .. path.name .. ")", j.id)
                    end
                end
                if any then first = false end
            end
            combo.OnSelect = function(_, _, _, id)
                net.Start("lcj_set")
                net.WriteString(id)
                net.SendToServer()
                Close()
            end
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
            p.violent and "   |   violent" or "", (not p.story and p.taken > 0) and string.format("   |   %d/%d on it", p.taken, p.max) or ((not p.story and (p.max or 1) > 1) and string.format("   |   up to %d together", p.max) or "")))
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
                Close()
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
                Close()
            end
        end

        card:InvalidateLayout(true)
        card:SizeToChildren(false, true)
    end
end

net.Receive("lcq_board", function()
    local data = ReadCompressed()
    if not data then return end
    data.postings = data.postings or {}
    if LC_CL.HubFill then LC_CL.HubFill("jobs", function(p) BuildBoard(p, data) end) end
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

-- The quest as the tracker has it (the panel of what you can do reads the step: cl_livingcity_context.lua)
function LC_CL.QuestState() return state end

hook.Add("InitPostEntity", "LivingCityQuestsSync", function()
    timer.Simple(5, function()
        net.Start("lcq_request")
        net.SendToServer()
    end)
end)

-- Wrapping text means measuring it word by word: done once per text, not every frame.
local wrapCache, wrapCount = {}, 0
local WrapNow
local function Wrap(text, font, width)
    local byFont = wrapCache[font]
    if not byFont then byFont = {} wrapCache[font] = byFont end
    local byWidth = byFont[width]
    if not byWidth then byWidth = {} byFont[width] = byWidth end
    local hit = byWidth[text]
    if hit then return hit end
    if wrapCount > 64 then wrapCache, wrapCount = {}, 0 end -- old objectives don't pile up
    local lines = WrapNow(text, font, width)
    local f = wrapCache[font] or {}
    wrapCache[font] = f
    f[width] = f[width] or {}
    f[width][text] = lines
    wrapCount = wrapCount + 1
    return lines
end

function WrapNow(text, font, width)
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

-- (made once here, not every frame)
local C_120_200_255 = Color(120, 200, 255)
local C_140_190_140 = Color(140, 190, 140)
local C_16_15_13_210 = Color(16, 15, 13, 210)
local C_20_18_16_200 = Color(20, 18, 16, 200)
local C_255_120_100 = Color(255, 120, 100)
local C_255_170_110 = Color(255, 170, 110)
local C_30_28_24_220 = Color(30, 28, 24, 220)
hook.Add("HUDPaint", "LivingCityQuestsTracker", function()
    if not state.active then return end
    local w = ScrW()
    local x, y, bw = w - 340, 120, 320
    local left = math.max(0, (state.left or 0) - (CurTime() - (state.received or CurTime())))
    local compassTarget = RawObjectivePos()

    local lines = Wrap(state.objective or "", "DermaDefault", bw - 24)
    local narr = state.narration and Wrap(state.narration, "DermaDefault", bw - 24) or {}
    local h = 54 + #lines * 16 + (state.progress and 16 or 0) + (#narr > 0 and (#narr * 15 + 8) or 0) + (state.choice and 18 or 0) + (compassTarget and 34 or 0) + (state.suspicion and 22 or 0)
    LC_CL.QuestTrackerBottom, LC_CL.QuestTrackerAt = y + h, CurTime() -- (the panel of what you can do goes under it: cl_livingcity_context.lua)
    draw.RoundedBox(4, x, y, bw, h, C_16_15_13_210)
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
    if state.suspicion then
        -- how suspicious the person you're tailing is: fills while they can see you
        local frac = math.Clamp(state.suspicion / 100, 0, 1)
        local col = frac > 0.66 and RED or (frac > 0.33 and ACCENT or C_140_190_140)
        draw.RoundedBox(3, x + 12, ly + 2, bw - 24, 14, C_30_28_24_220)
        if frac > 0 then draw.RoundedBox(3, x + 12, ly + 2, (bw - 24) * frac, 14, col) end
        draw.SimpleText(state.seen and "SUSPICION: THEY CAN SEE YOU" or "Suspicion", "DermaDefaultBold", x + bw / 2, ly + 9,
            state.seen and color_white or INK, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        ly = ly + 22
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
        draw.RoundedBox(3, x + 8, ly - 4, bw - 16, 30, C_30_28_24_220)
        DrawArrow(x + 28, ly + 11, rel, ACCENT)
        draw.SimpleText(string.format("%d m, %s", meters, heading), "DermaDefaultBold", x + 50, ly + 1, INK)
        draw.SimpleText(level, "DermaDefaultBold", x + 50, ly + 14, dz > 48 and C_120_200_255 or (dz < -48 and C_255_170_110 or DIM))
    end

    -- being seen while tailing someone: right where you're looking, so you notice in time to duck back
    if state.suspicion and (state.seen or state.suspicion > 0) then
        local cx, cy, mw = ScrW() / 2, ScrH() * 0.30, 220
        local frac = math.Clamp(state.suspicion / 100, 0, 1)
        local col = frac > 0.66 and RED or ACCENT
        local a = state.seen and 255 or 140
        draw.RoundedBox(3, cx - mw / 2, cy, mw, 10, C_20_18_16_200)
        if frac > 0 then draw.RoundedBox(3, cx - mw / 2, cy, mw * frac, 10, Color(col.r, col.g, col.b, a)) end
        draw.SimpleTextOutlined(state.seen and "THEY SEE YOU" or "out of sight", "DermaDefaultBold", cx, cy - 4,
            state.seen and C_255_120_100 or DIM, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM, 1, color_black)
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
