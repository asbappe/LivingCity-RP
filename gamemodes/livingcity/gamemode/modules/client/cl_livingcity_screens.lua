--[[
    Living City (client): terminals with their menu on their own screen

    Instead of a window, a terminal's menu is drawn on a screen in the world,
    standing in front of it: your crosshair is the cursor (the button under
    it lights up) and E (or left click) presses it. Walk away and it closes.
    Typing (a name, a description) still opens a small popup.

    Used by Civil Intake and Housing Allocation (cl_livingcity_intake.lua)
    and the Civil Protection Commissary's unit counter (cl_livingcity_needs.lua).
    Each player can have the window instead: the full menu's Settings, or
    lc_screen_ui 0.

    LC_CL.ScreenFor(classes)      the terminal in front of you, if the screens are on
    LC_CL.ScreenOpen(ent, title, sub, rows)
        rows: { kind = "head" | "line" | "button", text, col, enabled, fn }
    LC_CL.ScreenClose()
]]

LC_CL = LC_CL or {}

local cvOn = CreateClientConVar("lc_screen_ui", "1", true, false, "Terminals show their menu on their own screen in the world (0: a window instead)")

local W, ROW, HEAD, PER_PAGE = 600, 26, 46, 11
local SCALE = 0.055
local BG, EDGE, INK, DIM, HOT = Color(10, 16, 22, 235), Color(110, 170, 230), Color(220, 230, 240), Color(140, 150, 160), Color(110, 170, 230)
local HOT_ON, HOT_OFF, BTN = Color(HOT.r, HOT.g, HOT.b, 120), Color(HOT.r, HOT.g, HOT.b, 60), Color(30, 40, 52, 230) -- (made once, not every frame)

surface.CreateFont("LCScreenTitle", { font = "Trebuchet MS", size = 30, weight = 700 })
surface.CreateFont("LCScreenText", { font = "Trebuchet MS", size = 20, weight = 500 })

local S -- the open screen: { ent, title, sub, rows, page, hover, opened }

-- The terminal in front of you (aimed at, or the nearest close by), if this player uses the screens.
function LC_CL.ScreenFor(classes)
    if not cvOn:GetBool() then return nil end
    local me = LocalPlayer()
    if not IsValid(me) then return nil end
    local want = {}
    for _, c in ipairs(classes) do want[c] = true end
    local tr = me.GetEyeTrace and me:GetEyeTrace()
    local e = tr and tr.Entity
    if IsValid(e) and want[e:GetClass()] and e:GetPos():DistToSqr(me:GetPos()) < 200 * 200 then return e end
    local best, bd
    for c in pairs(want) do
        for _, x in ipairs(ents.FindByClass(c)) do
            local d = x:GetPos():DistToSqr(me:GetPos())
            if d < 200 * 200 and (not bd or d < bd) then best, bd = x, d end
        end
    end
    return best
end

-- Where the screen stands: in front of the terminal, upright, facing the way it faces.
local function Frame(ent, h)
    local ang = ent:GetAngles()
    ang:RotateAroundAxis(ang:Up(), 90)
    ang:RotateAroundAxis(ang:Forward(), 90)
    local maxs = ent.OBBMaxs and ent:OBBMaxs() or Vector(16, 16, 60)
    local center = ent:GetPos() + ent:GetForward() * (math.max(8, maxs.x) + 10) + ent:GetUp() * 54
    -- (the owner, 1 November: it stood at crotch height. Its middle a hair below your eyes, as they were
    -- when it opened, wherever the terminal's own origin is)
    if S and S.ent == ent and S.eyeZ then center.z = S.eyeZ - 8 end
    local tl = center - ang:Forward() * (W / 2 * SCALE) - ang:Right() * (h / 2 * SCALE)
    return tl, ang
end

-- The rows on this page, laid out: each with its y and height.
local function Layout()
    local rows, out = S.rows, {}
    local pages = math.max(1, math.ceil(#rows / PER_PAGE))
    S.page = math.Clamp(S.page or 1, 1, pages)
    local first = (S.page - 1) * PER_PAGE + 1
    local y = HEAD
    for i = first, math.min(#rows, first + PER_PAGE - 1) do
        out[#out + 1] = { r = rows[i], y = y }
        y = y + ROW
    end
    -- paging and closing, always at the bottom
    local nav = {}
    if S.page > 1 then nav[#nav + 1] = { kind = "button", text = "< Previous page", enabled = true, fn = function() S.page = S.page - 1 end, keep = true } end
    if S.page < pages then nav[#nav + 1] = { kind = "button", text = "Next page >", enabled = true, fn = function() S.page = S.page + 1 end, keep = true } end
    nav[#nav + 1] = { kind = "button", text = "Close", enabled = true, fn = function() LC_CL.ScreenClose() end, keep = true }
    y = y + 6
    for _, r in ipairs(nav) do out[#out + 1] = { r = r, y = y } y = y + ROW end
    return out, y + 10
end

function LC_CL.ScreenOpen(ent, title, sub, rows)
    if not IsValid(ent) then return false end
    local me = LocalPlayer()
    S = { ent = ent, title = title or "", sub = sub or "", rows = rows or {}, page = 1, opened = CurTime(),
        eyeZ = IsValid(me) and me.EyePos and me:EyePos().z or nil }
    return true
end
function LC_CL.ScreenClose() S = nil end
function LC_CL.ScreenState() return S end

-- Where the crosshair is on the screen (x, y in its own pixels), or nil.
local function Aim()
    if not S or not IsValid(S.ent) then return nil end
    local me = LocalPlayer()
    local _, h = Layout()
    local tl, ang = Frame(S.ent, h)
    local hit = util.IntersectRayWithPlane and util.IntersectRayWithPlane(me:EyePos(), me:GetAimVector(), tl, ang:Up())
    if not hit then return nil end
    local d = hit - tl
    return d:Dot(ang:Forward()) / SCALE, d:Dot(ang:Right()) / SCALE
end
LC_CL.ScreenAim = Aim

local function Hovered()
    local x, y = (LC_CL.ScreenAim or Aim)() -- (the tests stand in for the crosshair here)
    if not x or x < 0 or x > W then return nil end
    local lay = Layout()
    for _, l in ipairs(lay) do
        if l.r.kind == "button" and y >= l.y and y < l.y + ROW - 2 then return l end
    end
    return nil
end

-- Press the button under the crosshair. True if there was one.
function LC_CL.ScreenClick()
    if not S then return false end
    local l = Hovered()
    if not l then return false end
    if l.r.enabled == false then surface.PlaySound("buttons/combine_button_locked.wav") return true end
    surface.PlaySound("buttons/combine_button1.wav")
    local fn = l.r.fn
    if fn then fn() end
    return true
end

hook.Add("Think", "LivingCityScreens", function()
    if not S then return end
    local me = LocalPlayer()
    if not IsValid(S.ent) or not IsValid(me) or not me:Alive() or me:GetPos():DistToSqr(S.ent:GetPos()) > 240 * 240 or CurTime() - S.opened > 300 then
        S = nil
        return
    end
    local l = Hovered()
    -- (by where it is: the paging and Close buttons are made anew each time the screen's laid out, so the
    -- one under the crosshair was never the same one being drawn, and never lit up)
    S.hover = l and l.y or nil
end)

-- E (or left click) on a button presses it, and nothing else happens (the terminal isn't used again).
hook.Add("PlayerBindPress", "LivingCityScreens", function(ply, bind, pressed)
    if not S or not pressed then return end
    if string.find(bind, "+use", 1, true) or string.find(bind, "+attack", 1, true) then
        if LC_CL.ScreenClick() then return true end
    end
end)

hook.Add("PostDrawTranslucentRenderables", "LivingCityScreens", function(depth, sky)
    if sky or not S or not IsValid(S.ent) then return end
    local lay, h = Layout()
    local tl, ang = Frame(S.ent, h)
    -- a Combine machine's screen, whoever reads it: the Combine look (cl_livingcity_theme.lua), or as it was with lc_ui_theme 0
    local T = LC_CL.ThemeOn and LC_CL.ThemeOn() and LC_CL.Themes and LC_CL.Themes.combine or nil
    local edge = T and T.line or EDGE
    cam.Start3D2D(tl, ang, SCALE)
        if T then
            local top = math.max(30, (lay[1] and lay[1].y or 40) - 6)
            draw.RoundedBox(0, 0, 0, W, h, T.bg)
            surface.SetDrawColor(255, 255, 255, 5)
            for y = top + 2, h - 3, 4 do surface.DrawRect(2, y, W - 4, 1) end
            draw.RoundedBox(0, 0, 0, W, top, T.head)
            surface.SetDrawColor(T.dim.r, T.dim.g, T.dim.b, 255)
            surface.DrawOutlinedRect(0, 0, W, h, 1)
            surface.SetDrawColor(T.line.r, T.line.g, T.line.b, 255)
            surface.DrawRect(0, top - 2, W, 2)
            surface.DrawRect(0, 0, 22, 3) surface.DrawRect(0, 0, 3, 22) surface.DrawRect(W - 22, h - 3, 22, 3) surface.DrawRect(W - 3, h - 22, 3, 22)
            for i = 0, 5 do
                surface.SetDrawColor(i % 2 == 0 and T.line or T.dim)
                surface.DrawRect(10 + i * 9, h - 9, 6, 4)
            end
        else
            draw.RoundedBox(6, 0, 0, W, h, BG)
            surface.SetDrawColor(EDGE.r, EDGE.g, EDGE.b, 200)
            surface.DrawOutlinedRect(0, 0, W, h, 2)
        end
        draw.SimpleText(S.title, "LCScreenTitle", 14, 8, edge)
        draw.SimpleText(S.sub, "LCScreenText", W - 14, 14, DIM, TEXT_ALIGN_RIGHT)
        for _, l in ipairs(lay) do
            local r = l.r
            if r.kind == "button" then
                local hot = S.hover == l.y
                local off = r.enabled == false
                if T then
                    draw.RoundedBox(0, 10, l.y, W - 20, ROW - 4, (hot and not off) and T.plateHot or T.plate)
                    surface.SetDrawColor(off and T.dim or T.line)
                    surface.DrawRect(10, l.y, 4, ROW - 4)
                    if hot then surface.DrawOutlinedRect(10, l.y, W - 20, ROW - 4, 1) end
                else
                    draw.RoundedBox(4, 10, l.y, W - 20, ROW - 4, hot and (off and HOT_OFF or HOT_ON) or BTN)
                end
                draw.SimpleText((hot and "> " or "") .. (r.text or ""), "LCScreenText", T and 24 or 20, l.y + (ROW - 4) / 2, off and DIM or (T and T.text or INK), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            else
                local text = r.text or ""
                if #text > 64 then text = string.sub(text, 1, 62) .. "..." end
                draw.SimpleText(text, "LCScreenText", 14, l.y + ROW / 2, r.col or (r.kind == "head" and edge or INK), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            end
        end
        if not S.hover then
            draw.SimpleText("Aim at a button and press E", "LCScreenText", W / 2, h - 6, DIM, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
        end
    cam.End3D2D()
end)

-- Long lines, split to fit the screen (a line's words kept together).
function LC_CL.ScreenWrap(text, max)
    max = max or 62
    local out, cur = {}, ""
    for word in string.gmatch(tostring(text or ""), "%S+") do
        if #cur + #word + 1 > max and cur ~= "" then out[#out + 1] = cur cur = word
        else cur = cur == "" and word or (cur .. " " .. word) end
    end
    if cur ~= "" then out[#out + 1] = cur end
    return out
end
