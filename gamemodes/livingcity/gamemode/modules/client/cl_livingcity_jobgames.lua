--[[
    Living City (client): work you actually do (sv_livingcity_jobgames.lua)

      - the game's panel at the right of the screen: what's done, what's left
      - the street sweep: the rubbish nearby outlined, the cart's count over it
      - papers check: the traveler's papers beside today's rules, with their
        photo, and Approve / Deny / Call a unit
]]

LC_CL = LC_CL or {}

local game -- { kind, title, lines }

local function ReadCompressed()
    local len = net.ReadUInt(32)
    local data = net.ReadData(len)
    local json = util.Decompress(data or "")
    return json and util.JSONToTable(json) or nil
end

local closeOnEnd = {} -- (windows a game opened: shut when it's over)
LC_CL.JobGameWindows = closeOnEnd
net.Receive("lc_jobgame", function()
    local t = ReadCompressed()
    game = (t and t.kind) and t or nil
    if not game then
        for _, f in ipairs(closeOnEnd) do if f and f() then end end
    end
end)
function LC_CL.JobGame() return game end

------------------------------------------------------------------------
-- The panel
------------------------------------------------------------------------

surface.CreateFont("LCJobTitle", { font = "Tahoma", size = 16, weight = 800 })
surface.CreateFont("LCJobLine", { font = "Tahoma", size = 14, weight = 500 })
local BG, INK, DIM, ACC = Color(10, 12, 16, 200), Color(235, 235, 225), Color(175, 180, 185), Color(230, 190, 90)

hook.Add("HUDPaint", "LivingCityJobGames", function()
    if not game then return end
    local lines = game.lines or {}
    local w = 300
    local h = 30 + #lines * 17
    local x, y = ScrW() - w - 16, math.floor(ScrH() * 0.32)
    LC_CL.JobGameBottom, LC_CL.JobGameAt = y + h, CurTime() -- (the panel of what you can do keeps clear: cl_livingcity_context.lua)
    draw.RoundedBox(4, x, y, w, h, BG)
    draw.RoundedBox(0, x, y, 3, h, ACC)
    draw.SimpleText(string.upper(game.title or "Work"), "LCJobTitle", x + 10, y + 6, ACC)
    for i, l in ipairs(lines) do draw.SimpleText(l, "LCJobLine", x + 10, y + 10 + i * 17, i == #lines and INK or DIM) end
end)

------------------------------------------------------------------------
-- The street sweep: rubbish outlined, the cart's count
------------------------------------------------------------------------

local LITTER_COL, CART_COL, CART_INK = Color(150, 230, 120), Color(120, 180, 255), Color(220, 235, 255)

-- What's nearby, searched for a fifth of a second at a time, not every frame (the outlines and labels
-- still redraw every frame; a search of every entity within 900 to 1200 units was the costly part).
-- Kept per use: { at = when to search again, list = the entities that passed the test }.
local NEAR_EVERY = 0.2
local nearby = {}
local function Nearby(key, radius, test)
    local now = CurTime()
    local c = nearby[key]
    if c and now < c.at and now >= c.at - NEAR_EVERY then
        local ok = true
        for _, e in ipairs(c.list) do if not IsValid(e) then ok = false break end end
        if ok then return c.list end -- (one gone: look again now, as before)
    end
    local list = {}
    local me = LocalPlayer()
    if IsValid(me) then
        for _, e in ipairs(ents.FindInSphere(me:GetPos(), radius)) do
            if IsValid(e) and test(e) then list[#list + 1] = e end
        end
    end
    nearby[key] = { at = now + NEAR_EVERY, list = list }
    return list
end

local function IsLitter(e) return e:GetNW2Bool("lc_litter", false) end
local function IsCartOnly(e) return not e:GetNW2Bool("lc_litter", false) and e:GetNW2Bool("lc_cart", false) end
local function IsCart(e) return e:GetNW2Bool("lc_cart", false) end
local function IsPatient(e) return e:GetNW2Bool("lc_patient", false) end

hook.Add("PreDrawHalos", "LivingCityJobGames", function()
    if not game or game.kind ~= "sweep" or not halo then return end
    local litter, carts = Nearby("litter", 900, IsLitter), Nearby("carts", 900, IsCartOnly)
    if #litter > 0 then halo.Add(litter, LITTER_COL, 1, 1, 1, true, false) end
    if #carts > 0 then halo.Add(carts, CART_COL, 2, 2, 1, true, true) end
end)

hook.Add("PostDrawTranslucentRenderables", "LivingCityJobCart", function(depth, sky)
    if sky or not game or game.kind ~= "sweep" then return end
    for _, e in ipairs(Nearby("cartlabels", 1200, IsCart)) do
        if IsValid(e) then
            local top = e:LocalToWorld(Vector(0, 0, e:OBBMaxs().z + 18))
            local ang = (top - EyePos()):Angle()
            ang = Angle(0, ang.y - 90, 90)
            cam.Start3D2D(top, ang, 0.12)
                draw.SimpleTextOutlined(string.format("%d / %d", e:GetNW2Int("lc_fill", 0), e:GetNW2Int("lc_need", 0)), "DermaLarge", 0, 0,
                    CART_INK, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 2, color_black)
            cam.End3D2D()
        end
    end
end)

------------------------------------------------------------------------
-- Papers check
------------------------------------------------------------------------

local frame
local PAPER, PINK, STAMP, BAD = Color(222, 214, 190), Color(40, 36, 30), Color(150, 40, 40), Color(60, 90, 160)
closeOnEnd[#closeOnEnd + 1] = function() if IsValid(frame) then frame:Remove() end end

local function Decide(choice)
    net.Start("lc_papers_decide")
    net.WriteString(choice)
    net.SendToServer()
    if IsValid(frame) then frame:Remove() end
end
LC_CL.PapersDecide = Decide

net.Receive("lc_papers_check", function()
    local t = util.JSONToTable(net.ReadString() or "") or {}
    local p = t.papers or {}
    if IsValid(frame) then frame:Remove() end
    frame = vgui.Create("DFrame")
    -- (on the street, a unit's own check of someone they stopped: sv_livingcity_jobgames.lua, LC.StreetPapers)
    frame:SetTitle(t.street and "Papers check" or string.format("Papers check: traveler %d of %d", t.n or 1, t.of or 5))
    frame:SetSize(math.min(ScrW() - 40, 720), math.min(ScrH() - 40, 420))
    frame:Center()
    frame:MakePopup()

    -- today's rules, on the left
    local rules = vgui.Create("DPanel", frame)
    rules:Dock(LEFT)
    rules:SetWide(230)
    rules:DockMargin(0, 0, 8, 0)
    rules.Paint = function(s, w, h)
        draw.RoundedBox(4, 0, 0, w, h, Color(30, 34, 40))
        draw.SimpleText("TODAY: DAY " .. tostring(t.today or "?"), "LCJobTitle", 10, 8, ACC)
        draw.SimpleText("Rules", "LCJobLine", 10, 32, DIM)
        local y = 54
        for _, r in ipairs(t.rules or {}) do
            for _, l in ipairs(LC_CL.WrapText and LC_CL.WrapText("- " .. r, "LCJobLine", w - 20) or { "- " .. r }) do
                draw.SimpleText(l, "LCJobLine", 10, y, INK)
                y = y + 17
            end
            y = y + 4
        end
        draw.SimpleText("The seal must read OCS.", "LCJobLine", 10, h - 46, DIM)
        draw.SimpleText("Look at the traveler: is it them?", "LCJobLine", 10, h - 26, DIM)
    end

    -- the buttons, at the bottom
    local bar = vgui.Create("DPanel", frame)
    bar:Dock(BOTTOM)
    bar:SetTall(40)
    bar.Paint = nil
    local calls = { { "Approve", "approve", Color(70, 140, 80) }, { "Deny", "deny", Color(150, 70, 60) }, { "Call a Civil Protection unit", "unit", Color(70, 90, 150) } }
    if t.street then
        calls = { { "In order: wave them on", "approve", Color(70, 140, 80) }, { "Out of order: cite them", "deny", Color(150, 70, 60) }, { "Forged: take them in", "unit", Color(70, 90, 150) } }
    end
    for i, b in ipairs(calls) do
        local btn = vgui.Create("DButton", bar)
        btn:Dock(LEFT)
        btn:SetWide(150)
        btn:DockMargin(i == 1 and 0 or 8, 6, 0, 0)
        btn:SetText(b[1])
        btn:SetTextColor(color_white)
        btn.Paint = function(s, w, h) draw.RoundedBox(4, 0, 0, w, h, s:IsHovered() and Color(b[3].r + 30, b[3].g + 30, b[3].b + 30) or b[3]) end
        btn.DoClick = function() Decide(b[2]) end
    end

    -- the papers themselves
    local card = vgui.Create("DPanel", frame)
    card:Dock(FILL)
    card.Paint = function(s, w, h)
        draw.RoundedBox(4, 0, 0, w, h, PAPER)
        draw.SimpleText("UNION IDENTITY PAPERS", "LCJobTitle", 14, 10, PINK)
        local x, y = 170, 44
        local function Row(k, v, col)
            draw.SimpleText(k, "LCJobLine", x, y, Color(110, 100, 85))
            draw.SimpleText(tostring(v), "LCJobTitle", x + 100, y - 1, col or PINK)
            y = y + 24
        end
        Row("Name", p.name or "?")
        Row("Citizen no.", p.cid or "?")
        Row("Issued in", p.district or "?")
        Row("Valid until", "Day " .. tostring(p.expires or "?"))
        Row("Purpose", p.purpose or "?")
        -- stamps
        local sy = h - 70
        if p.permit then
            draw.RoundedBox(4, 14, sy, 120, 40, Color(0, 0, 0, 0))
            surface.SetDrawColor(STAMP) surface.DrawOutlinedRect(14, sy, 120, 40, 2)
            draw.SimpleText("TRANSIT", "LCJobTitle", 74, sy + 8, STAMP, TEXT_ALIGN_CENTER)
            draw.SimpleText("PERMITTED", "LCJobLine", 74, sy + 24, STAMP, TEXT_ALIGN_CENTER)
        end
        if p.union then
            surface.SetDrawColor(Color(60, 110, 60)) surface.DrawOutlinedRect(146, sy, 110, 40, 2)
            draw.SimpleText("UNION", "LCJobTitle", 201, sy + 12, Color(60, 110, 60), TEXT_ALIGN_CENTER)
        end
        -- the seal
        local cx, cy = w - 54, h - 52
        surface.SetDrawColor(BAD)
        for r = 30, 32 do surface.DrawCircle(cx, cy, r, BAD.r, BAD.g, BAD.b, 255) end
        draw.SimpleText(p.seal or "OCS", "LCJobTitle", cx, cy, BAD, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    -- the photo
    local photo = vgui.Create("DModelPanel", card)
    photo:SetPos(14, 40)
    photo:SetSize(140, 150)
    photo:SetModel(p.model or "models/Humans/Group01/male_01.mdl")
    photo.LayoutEntity = function() end
    local ent = photo.Entity
    if IsValid(ent) then
        local head = ent.LookupBone and ent:LookupBone("ValveBiped.Bip01_Head1")
        local hp = head and ent:GetBonePosition(head) or Vector(0, 0, 64)
        photo:SetLookAt(hp)
        photo:SetCamPos(hp + Vector(22, 0, 0))
        photo:SetFOV(40)
    end
end)

------------------------------------------------------------------------
-- Rewiring: the board of circuit tiles (click turns a tile; right-click turns it back)
------------------------------------------------------------------------

local wire -- { frame, w, h, tiles, lit = { [k] = true }, sparks = { [k] = true }, feed, lamp, zap, turns, par, shocks, endsAt }
local TILE = 64
local COPPER, LIVE, BOARD = Color(120, 95, 70), Color(255, 210, 90), Color(28, 32, 30)

local function CloseWires() if wire and IsValid(wire.frame) then wire.frame:Remove() end wire = nil end

local function Arms(m, x, y, col)
    local c, t = TILE / 2, 10
    surface.SetDrawColor(col)
    if bit.band(m, 1) ~= 0 then surface.DrawRect(x + c - t / 2, y, t, c + t / 2) end
    if bit.band(m, 2) ~= 0 then surface.DrawRect(x + c - t / 2, y + c - t / 2, c + t / 2, t) end
    if bit.band(m, 4) ~= 0 then surface.DrawRect(x + c - t / 2, y + c - t / 2, t, c + t / 2) end
    if bit.band(m, 8) ~= 0 then surface.DrawRect(x, y + c - t / 2, c + t / 2, t) end
end

net.Receive("lc_wire_open", function()
    local t = util.JSONToTable(net.ReadString() or "") or {}
    if not t.tiles then return CloseWires() end
    local fresh = not (wire and IsValid(wire.frame) and wire.w == t.w and wire.h == t.h)
    if fresh then CloseWires() wire = {} end
    wire.w, wire.h, wire.tiles, wire.feed, wire.lamp = t.w, t.h, t.tiles, t.feed, t.lamp
    wire.turns, wire.par, wire.shocks, wire.what, wire.dark = t.turns or 0, t.par or 0, t.shocks or 0, t.what, t.dark
    wire.endsAt = CurTime() + (t.secs or 30)
    wire.lit, wire.sparks = {}, {}
    for _, k in ipairs(t.lit or {}) do wire.lit[k] = true end
    for _, k in ipairs(t.sparks or {}) do wire.sparks[k] = true end
    if t.zap then wire.zap = { k = t.zap, t = CurTime() + 0.5 } end
    if not fresh then return end
    local ox, oy = 44, 40
    local f = vgui.Create("DFrame")
    wire.frame = f
    f:SetTitle("Rewiring " .. tostring(t.what or "the panel"))
    f:SetSize(ox * 2 + t.w * TILE, oy + t.h * TILE + 76)
    f:Center()
    f:MakePopup()
    f.PaintOver = function(s, w, h)
        if not wire then return end
        -- the feed (left) and the lamp (right)
        local fy, ly = oy + (wire.feed - 1) * TILE + TILE / 2, oy + (wire.lamp - 1) * TILE + TILE / 2
        surface.SetDrawColor(LIVE)
        surface.DrawRect(8, fy - 5, ox - 8, 10)
        draw.SimpleText("FEED", "DermaDefault", 6, fy - 16, LIVE)
        local lampOn = wire.lit[(wire.lamp - 1) * wire.w + wire.w] and bit.band(wire.tiles[(wire.lamp - 1) * wire.w + wire.w] or 0, 2) ~= 0
        surface.SetDrawColor(lampOn and LIVE or COPPER)
        surface.DrawRect(ox + wire.w * TILE, ly - 5, 14, 10)
        draw.RoundedBox(10, w - 30, ly - 10, 20, 20, lampOn and LIVE or Color(70, 70, 60))
        draw.SimpleText("LAMP", "DermaDefault", w - 6, ly - 24, INK, TEXT_ALIGN_RIGHT)
        local left = math.max(0, math.ceil(wire.endsAt - CurTime()))
        draw.SimpleText(string.format("%d s    Turns %d (par %d)    Shocks %d", left, wire.turns, wire.par, wire.shocks), "LCJobTitle", w / 2, h - 50,
            left <= 10 and Color(255, 120, 90) or INK, TEXT_ALIGN_CENTER)
        draw.SimpleText("Click turns a tile, right-click turns it back. Get the current to the lamp. Don't touch a sparking tile.", "DermaDefault",
            w / 2, h - 22, INK, TEXT_ALIGN_CENTER)
    end
    for k = 1, t.w * t.h do
        local x, y = (k - 1) % t.w, math.floor((k - 1) / t.w)
        local b = vgui.Create("DButton", f)
        b:SetPos(ox + x * TILE, oy + y * TILE)
        b:SetSize(TILE, TILE)
        b:SetText("")
        b.Paint = function(s, w, h)
            if not wire then return end
            draw.RoundedBox(4, 1, 1, w - 2, h - 2, s:IsHovered() and Color(44, 50, 46) or BOARD)
            Arms(wire.tiles[k] or 0, 0, 0, wire.lit[k] and LIVE or COPPER)
            if wire.sparks[k] then
                -- a live spark: crackling, white-hot
                local now = CurTime()
                surface.SetDrawColor(255, 255, 200, 140 + 110 * math.abs(math.sin(now * 23 + k)))
                for i = 1, 5 do
                    local a = now * 9 + i * 1.3 + k
                    surface.DrawLine(w / 2, h / 2, w / 2 + math.cos(a) * (14 + (i * 7) % 16), h / 2 + math.sin(a) * (14 + (i * 5) % 16))
                end
                surface.SetDrawColor(255, 240, 120)
                surface.DrawOutlinedRect(0, 0, w, h, 2)
            end
            if wire.zap and wire.zap.k == k and wire.zap.t > CurTime() then
                draw.RoundedBox(4, 0, 0, w, h, Color(255, 60, 40, 120))
            end
        end
        local function Turn(ccw)
            net.Start("lc_wire_try") net.WriteUInt(k, 6) net.WriteBool(ccw) net.SendToServer()
        end
        b.DoClick = function() Turn(false) end
        b.DoRightClick = function() Turn(true) end
    end
end)
LC_CL.WireState = function() return wire end

------------------------------------------------------------------------
-- Triage: what's wrong with each patient, and how long they've got
------------------------------------------------------------------------

local PATIENT_UP = Vector(0, 0, 84)
local INJURY_INK, BAR_BG = Color(255, 220, 200), Color(20, 20, 20, 220)
local BAR_LOW, BAR_MID, BAR_OK = Color(220, 60, 50), Color(230, 170, 50), Color(90, 200, 90)
hook.Add("PostDrawTranslucentRenderables", "LivingCityJobPatients", function(depth, sky)
    if sky or not game or game.kind ~= "triage" then return end
    for _, e in ipairs(Nearby("patients", 900, IsPatient)) do
        if IsValid(e) then
            local top = e:GetPos() + PATIENT_UP
            local ang = (top - EyePos()):Angle()
            ang = Angle(0, ang.y - 90, 90)
            local hp, max = e:GetNW2Int("lc_hp", 0), math.max(1, e:GetNW2Int("lc_hpmax", 40))
            local f = math.Clamp(hp / max, 0, 1)
            cam.Start3D2D(top, ang, 0.1)
                draw.SimpleTextOutlined(e:GetNW2String("lc_injury", ""), "DermaLarge", 0, -30, INJURY_INK, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 2, color_black)
                draw.RoundedBox(4, -100, 0, 200, 22, BAR_BG)
                draw.RoundedBox(4, -98, 2, 196 * f, 18, f < 0.3 and BAR_LOW or (f < 0.6 and BAR_MID or BAR_OK))
            cam.End3D2D()
        end
    end
end)
