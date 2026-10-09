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

net.Receive("lc_jobgame", function()
    local t = ReadCompressed()
    game = (t and t.kind) and t or nil
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
    draw.RoundedBox(4, x, y, w, h, BG)
    draw.RoundedBox(0, x, y, 3, h, ACC)
    draw.SimpleText(string.upper(game.title or "Work"), "LCJobTitle", x + 10, y + 6, ACC)
    for i, l in ipairs(lines) do draw.SimpleText(l, "LCJobLine", x + 10, y + 10 + i * 17, i == #lines and INK or DIM) end
end)

------------------------------------------------------------------------
-- The street sweep: rubbish outlined, the cart's count
------------------------------------------------------------------------

local LITTER_COL, CART_COL = Color(150, 230, 120), Color(120, 180, 255)

hook.Add("PreDrawHalos", "LivingCityJobGames", function()
    if not game or game.kind ~= "sweep" or not halo then return end
    local me = LocalPlayer()
    local litter, carts = {}, {}
    for _, e in ipairs(ents.FindInSphere(me:GetPos(), 900)) do
        if IsValid(e) then
            if e:GetNW2Bool("lc_litter", false) then litter[#litter + 1] = e
            elseif e:GetNW2Bool("lc_cart", false) then carts[#carts + 1] = e end
        end
    end
    if #litter > 0 then halo.Add(litter, LITTER_COL, 1, 1, 1, true, false) end
    if #carts > 0 then halo.Add(carts, CART_COL, 2, 2, 1, true, true) end
end)

hook.Add("PostDrawTranslucentRenderables", "LivingCityJobCart", function(depth, sky)
    if sky or not game or game.kind ~= "sweep" then return end
    local me = LocalPlayer()
    for _, e in ipairs(ents.FindInSphere(me:GetPos(), 1200)) do
        if IsValid(e) and e:GetNW2Bool("lc_cart", false) then
            local top = e:LocalToWorld(Vector(0, 0, e:OBBMaxs().z + 18))
            local ang = (top - EyePos()):Angle()
            ang = Angle(0, ang.y - 90, 90)
            cam.Start3D2D(top, ang, 0.12)
                draw.SimpleTextOutlined(string.format("%d / %d", e:GetNW2Int("lc_fill", 0), e:GetNW2Int("lc_need", 0)), "DermaLarge", 0, 0,
                    Color(220, 235, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 2, color_black)
            cam.End3D2D()
        end
    end
end)

------------------------------------------------------------------------
-- Papers check
------------------------------------------------------------------------

local frame
local PAPER, PINK, STAMP, BAD = Color(222, 214, 190), Color(40, 36, 30), Color(150, 40, 40), Color(60, 90, 160)

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
    frame:SetTitle(string.format("Papers check: traveler %d of %d", t.n or 1, t.of or 5))
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
    for i, b in ipairs({ { "Approve", "approve", Color(70, 140, 80) }, { "Deny", "deny", Color(150, 70, 60) }, { "Call a unit", "unit", Color(70, 90, 150) } }) do
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
