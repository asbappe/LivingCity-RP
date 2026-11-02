--[[
    Sealed directives on the client (sv_livingcity_directives.lua)

      The envelopes   the Administrator's device, the office, Sealed directives: eleven
                      envelopes, a wax seal and a rhyming riddle on each, and how warm it is.
                      An open one glows, with Sign it and Refuse it.
      The popup       a superadmin's (or an admin's) choice when there's no Administrator:
                      start it now, put it to the G-Man's vote, or let it pass.
      The G-Man       drawn like Half-Life 2's own intro: his own empty space over your
                      screen, whatever you're doing (asleep in bed included), his voice, a
                      line under him; a visit ends with him turning and walking off into
                      the dark. A dream is the same, softer, at the edges of sleep.
]]

LC_CL = LC_CL or {}

local INK, PAPER, WAX = Color(40, 34, 26), Color(222, 210, 180), Color(150, 30, 30)
local HEAT = { cold = Color(120, 150, 190), warm = Color(220, 160, 70), hot = Color(230, 80, 50) }

local function Act(what, id)
    net.Start("lc_directive_act") net.WriteString(what) net.WriteString(id or "") net.SendToServer()
end
LC_CL.DirectiveAct = Act

local frame
net.Receive("lc_directives", function()
    local list = net.ReadTable() or {}
    if IsValid(frame) then frame:Remove() end
    frame = vgui.Create("DFrame")
    frame:SetTitle("Sealed directives")
    frame:SetSize(math.min(ScrW() - 40, 720), math.min(ScrH() - 60, 640))
    frame:Center()
    frame:MakePopup()
    local scroll = vgui.Create("DScrollPanel", frame)
    scroll:Dock(FILL)
    -- closed with an open one left unanswered: he notices (once a directive: sv_livingcity_directives.lua)
    local openId, answered
    for _, d in ipairs(list) do if d.open then openId = d.id end end
    frame.OnRemove = function() if openId and not answered then Act("walkaway", openId) end end
    for i, d in ipairs(list) do
        local card = scroll:Add("DPanel")
        card:Dock(TOP)
        card:DockMargin(4, 4, 4, 4)
        card:SetTall(d.open and 112 or 76)
        card.Paint = function(s, w, h)
            local glow = d.open and (120 + 100 * math.abs(math.sin(CurTime() * 2))) or 0
            draw.RoundedBox(4, 0, 0, w, h, PAPER)
            if glow > 0 then surface.SetDrawColor(255, 210, 120, glow) surface.DrawOutlinedRect(0, 0, w, h, 3) end
            -- the seal: whole, or broken
            local cx, cy = 34, 38
            draw.RoundedBox(14, cx - 16, cy - 16, 32, 32, d.open and Color(110, 30, 30) or WAX)
            if d.open then surface.SetDrawColor(PAPER) surface.DrawLine(cx - 10, cy - 12, cx + 6, cy + 12) end
            draw.SimpleText(d.open and (d.name or "Open") or ("Sealed directive " .. i), "DermaDefaultBold", 64, 8, INK)
            draw.SimpleText(d.heat, "DermaDefaultBold", w - 10, 8, HEAT[d.heat] or INK, TEXT_ALIGN_RIGHT)
            local a, b = string.match(d.riddle or "", "^(.-)%s*/%s*(.*)$")
            draw.SimpleText(a or d.riddle or "", "DermaDefault", 64, 30, INK)
            draw.SimpleText(b or "", "DermaDefault", 64, 48, INK)
            if d.open and d.left then draw.SimpleText(string.format("%d:%02d left to answer", math.floor(d.left / 60), d.left % 60), "DermaDefault", w - 10, 30, INK, TEXT_ALIGN_RIGHT) end
        end
        if d.open then
            local sign = vgui.Create("DButton", card)
            sign:SetText("Sign it")
            sign:SetPos(64, 76) sign:SetSize(120, 26)
            sign.DoClick = function() answered = true Act("sign", d.id) frame:Remove() end
            local no = vgui.Create("DButton", card)
            no:SetText("Refuse it")
            no:SetPos(194, 76) no:SetSize(120, 26)
            no.DoClick = function() answered = true Act("refuse", d.id) frame:Remove() end
        end
    end
end)

net.Receive("lc_directive_staff", function()
    local id, name, riddle = net.ReadString(), net.ReadString(), net.ReadString()
    local f = vgui.Create("DFrame")
    f:SetTitle("A sealed directive has broken its seal")
    f:SetSize(460, 200)
    f:Center()
    f:MakePopup()
    local l = vgui.Create("DLabel", f)
    l:Dock(TOP) l:SetTall(70) l:SetWrap(true)
    l:SetText("There's no City Administrator here to answer it, so it's yours. The ending: " .. name .. ".\n\"" .. riddle .. "\"")
    for _, b in ipairs({ { "Start it now", "start" }, { "Put it to the G-Man's vote", "vote" }, { "Let it pass", "pass" } }) do
        local btn = vgui.Create("DButton", f)
        btn:Dock(TOP) btn:DockMargin(0, 4, 0, 0)
        btn:SetText(b[1])
        btn.DoClick = function() Act(b[2], id) f:Remove() end
    end
end)

------------------------------------------------------------------------
-- The G-Man, in his own space over your screen
------------------------------------------------------------------------

local V -- { mode, text, t0, dur, model }
local VOID = Vector(0, 0, -16000) -- (where he stands: drawn with its own camera, nowhere you can walk)
local function Seq(m, names, act)
    if act and m.SelectWeightedSequence then
        local s = m:SelectWeightedSequence(act)
        if s and s >= 0 then return s end
    end
    for _, n in ipairs(names) do local s = m:LookupSequence(n) if s and s >= 0 then return s end end
    return nil
end
function LC_CL.GmanVision(mode, snd, text)
    if V and IsValid(V.model) then V.model:Remove() end
    V = { mode = mode, text = text or "", t0 = CurTime() }
    if snd and snd ~= "" then surface.PlaySound(snd) end
    if mode == "voice" then V.dur = 4 return end
    V.dur = mode == "dream" and 9 or (mode == "summon" and 8 or 7)
    if not ClientsideModel then return end
    local m = ClientsideModel("models/gman_high.mdl", RENDERGROUP_OPAQUE)
    if not IsValid(m) then return end
    m:SetNoDraw(true)
    m:SetPos(VOID)
    m:SetAngles(Angle(0, 180, 0))
    V.idle = Seq(m, { "idle_subtle", "idle", "Idle01" }, ACT_IDLE)
    V.walk = Seq(m, { "walk_all", "Walk", "walk" }, ACT_WALK)
    if V.idle then m:ResetSequence(V.idle) end
    V.model = m
end
net.Receive("lc_gman_vision", function()
    local mode, snd, text = net.ReadString(), net.ReadString(), net.ReadString()
    LC_CL.GmanVision(mode, snd, text)
end)

hook.Add("HUDPaint", "LivingCityGmanVision", function()
    if not V then return end
    local t = CurTime() - V.t0
    if t > V.dur then
        if IsValid(V.model) then V.model:Remove() end
        V = nil
        return
    end
    local w, h = ScrW(), ScrH()
    -- in and out of the dark
    local a = math.min(1, t / 0.8, (V.dur - t) / 1.2)
    if V.mode ~= "voice" then
        surface.SetDrawColor(0, 0, 0, (V.mode == "dream" and 235 or 215) * a)
        surface.DrawRect(0, 0, w, h)
    end
    local m = V.model
    if IsValid(m) then
        -- a visit: he speaks, then turns and walks off into the dark
        local leaving = V.mode == "visit" and t > V.dur - 3
        if leaving and not V.turned then
            V.turned = true
            m:SetAngles(Angle(0, 20, 0))
            if V.walk then m:ResetSequence(V.walk) end
        end
        if leaving then m:SetPos(VOID + Vector(math.min(3, t - (V.dur - 3)) * 45, 0, 0)) end
        if m.FrameAdvance then m:FrameAdvance(FrameTime()) end
        local fade = leaving and math.max(0, 1 - (t - (V.dur - 3)) / 3) or 1
        cam.Start3D(VOID + Vector(-95, 0, 62), Angle(4, 0, 0), 55, 0, 0, w, h)
            render.SuppressEngineLighting(true)
            render.SetLightingOrigin(VOID)
            render.ResetModelLighting(0.25, 0.25, 0.3)
            render.SetModelLighting(BOX_FRONT or 0, 0.9, 0.85, 0.8)
            render.SetBlend(a * fade * (V.mode == "dream" and 0.75 or 1))
            m:DrawModel()
            render.SetBlend(1)
            render.SuppressEngineLighting(false)
        cam.End3D()
    end
    -- a summons: the envelope beside him, so it's plain what he's calling them back to
    if V.mode == "summon" then
        local ex, ey = w * 0.68, h * 0.42
        draw.RoundedBox(4, ex - 60, ey - 38, 120, 76, Color(222, 210, 180, 255 * a))
        surface.SetDrawColor(120, 100, 70, 255 * a)
        surface.DrawLine(ex - 60, ey - 38, ex, ey) surface.DrawLine(ex + 60, ey - 38, ex, ey)
        draw.RoundedBox(12, ex - 13, ey - 8, 26, 26, Color(150, 30, 30, 255 * a))
        draw.SimpleTextOutlined("Your sealed directive is waiting", "DermaDefaultBold", ex, ey + 54, Color(235, 225, 200, 255 * a), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(0, 0, 0, 200 * a))
    end
    -- his words, under him
    if V.text ~= "" then
        local lines = {}
        for part in string.gmatch(V.text, "[^/]+") do lines[#lines + 1] = string.Trim(part) end
        for i, line in ipairs(lines) do
            draw.SimpleTextOutlined(line, "DermaLarge", w / 2, h * 0.78 + (i - 1) * 34, Color(225, 225, 210, 255 * a), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(0, 0, 0, 200 * a))
        end
    end
end)

-- The reminder: while a directive waits on the Administrator, a bar at the top of the screen says so,
-- how long is left, and how to open it; red and pulsing once the G-Man has called them back to it.
hook.Add("HUDPaint", "LivingCityDirectiveReminder", function()
    local me = LocalPlayer()
    if not IsValid(me) then return end
    local left = me:GetNW2Float("lc_directive_until", 0) - CurTime()
    if left <= 0 then return end
    local urgent = me:GetNW2Bool("lc_directive_urgent", false)
    local w = ScrW()
    local pulse = urgent and (0.55 + 0.45 * math.abs(math.sin(CurTime() * 3))) or 1
    local bg = urgent and Color(120, 20, 20, 220 * pulse) or Color(40, 32, 20, 200)
    local bw = math.min(w - 40, 640)
    draw.RoundedBox(4, w / 2 - bw / 2, 8, bw, 46, bg)
    draw.SimpleText((urgent and "THE G-MAN IS WAITING: " or "A SEALED DIRECTIVE IS WAITING: ") .. string.format("%d:%02d left", math.floor(left / 60), math.floor(left % 60)),
        "DermaDefaultBold", w / 2, 20, Color(245, 225, 190), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    draw.SimpleText("Right click with your Administrator's device: the office, Sealed directives. Sign it or refuse it.",
        "DermaDefault", w / 2, 40, Color(235, 225, 205), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end)

-- A glimpse of him (sv_livingcity_directives.lua): standing a way off, somewhere in plain sight, facing
-- you; he's gone when you look straight at him, get close, or after a few seconds.
local G
net.Receive("lc_gman_glimpse", function()
    local snd = net.ReadString()
    local me = LocalPlayer()
    if not IsValid(me) or not ClientsideModel or (G and IsValid(G.model)) then return end
    local eye = me:EyePos()
    for _ = 1, 12 do
        local yaw = me:EyeAngles().y + (math.random(2) == 1 and 1 or -1) * math.Rand(12, 35) -- (off to one side: glimpsed, not stared at)
        local dist = math.Rand(450, 1100)
        local dir = Angle(0, yaw, 0):Forward()
        local tr = util.TraceLine({ start = eye, endpos = eye + dir * dist, filter = me, mask = MASK_SOLID })
        if not tr.Hit then
            local down = util.TraceLine({ start = tr.HitPos, endpos = tr.HitPos - Vector(0, 0, 400), mask = MASK_SOLID_BRUSHONLY })
            if down.Hit and not down.StartSolid then
                local m = ClientsideModel("models/gman_high.mdl", RENDERGROUP_OPAQUE)
                if not IsValid(m) then return end
                m:SetPos(down.HitPos)
                m:SetAngles(Angle(0, yaw + 180, 0))
                local idle = m:LookupSequence("idle_subtle")
                if idle and idle >= 0 then m:ResetSequence(idle) end
                G = { model = m, t0 = CurTime() }
                if snd ~= "" then sound.Play(snd, down.HitPos, 60, 100, 0.8) end
                return
            end
        end
    end
end)
hook.Add("Think", "LivingCityGmanGlimpse", function()
    if not G then return end
    local me = LocalPlayer()
    local m = G.model
    if not IsValid(m) or not IsValid(me) then G = nil return end
    local to = m:GetPos() + Vector(0, 0, 60) - me:EyePos()
    local d = to:Length()
    local looking = me:GetAimVector():Dot(to:GetNormalized()) > 0.995 and CurTime() - G.t0 > 0.6
    if looking or d < 250 or CurTime() - G.t0 > 7 then m:Remove() G = nil end
end)
