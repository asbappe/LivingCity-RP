--[[
    Living City: the collapse on screen (sv_livingcity_collapse.lua)

      The G-Man's offer       a window for the Administrator: step down, end it yourself, or refuse him
      Her shield              a bubble round the Administrator in her last stand (orange and flickering
                              with her office's power cut)
      The last stand          the time left, her health and shield, and where her office is
      Heroes                  who the hero is, and "you are" for the one playing him
]]

LC_CL = LC_CL or {}

local HERO_NAMES = { barney = "BARNEY CALHOUN", freeman = "GORDON FREEMAN" }

------------------------------------------------------------------------
-- The G-Man's offer
------------------------------------------------------------------------

net.Receive("lc_collapse_offer", function()
    local secs = net.ReadFloat()
    if IsValid(LC_CL.CollapseOffer) then LC_CL.CollapseOffer:Remove() end
    local f = vgui.Create("DFrame")
    LC_CL.CollapseOffer = f
    f:SetTitle("")
    f:SetSize(520, 250)
    f:Center()
    f:MakePopup()
    f:ShowCloseButton(false)
    local ends = CurTime() + (secs or 300)
    local function Send(how)
        net.Start("lc_collapse_answer") net.WriteString(how) net.SendToServer()
        if IsValid(f) then f:Remove() end
    end
    f.Paint = function(self, w, h)
        draw.RoundedBox(6, 0, 0, w, h, Color(8, 10, 14, 240))
        draw.RoundedBox(0, 0, h - 3, w, 3, Color(170, 120, 230))
        draw.SimpleText("A man in a blue suit", "DermaLarge", w / 2, 18, Color(220, 220, 230), TEXT_ALIGN_CENTER)
        draw.DrawText("\"Your city has fallen into chaos, Administrator. It will not recover.\n" ..
            "You may step aside. You may ... end things yourself. Or you may refuse,\n" ..
            "and I will see to it that the city ends you.\"", "DermaDefault", w / 2, 62, Color(200, 200, 210), TEXT_ALIGN_CENTER)
        local left = math.max(0, ends - CurTime())
        draw.SimpleText(string.format("No answer in %d:%02d is a refusal.", math.floor(left / 60), math.floor(left % 60)), "DermaDefault", w / 2, 130, Color(160, 160, 170), TEXT_ALIGN_CENTER)
        if left <= 0 then self:Remove() end
    end
    local function Btn(text, x, how, tip)
        local b = vgui.Create("DButton", f)
        b:SetText(text)
        b:SetPos(x, 160)
        b:SetSize(156, 60)
        if tip then b:SetTooltip(tip) end
        b.DoClick = function() Send(how) end
    end
    Btn("Step down", 16, "resign", "Leave the post: a citizen again. The city calms.")
    Btn("End it myself", 182, "end", "Die by your own hand and leave the post. The city calms.")
    Btn("Refuse him", 348, "refuse", "He hastens your end: crates of guns, people waking armed, the grid failing, then your last stand in your office.")
end)

------------------------------------------------------------------------
-- Her shield
------------------------------------------------------------------------

local SHIELD = Color(140, 110, 255, 60)
local SHIELD_WEAK = Color(255, 150, 60, 50)
hook.Add("PostDrawTranslucentRenderables", "LivingCityCollapseShield", function(depth, sky)
    if sky then return end
    local boss = GetGlobal2Entity("lc_collapse_boss")
    if not IsValid(boss) then return end
    local frac = boss:GetNW2Float("lc_shield_frac", 0)
    if frac <= 0 then return end
    if boss == LocalPlayer() and not LocalPlayer():ShouldDrawLocalPlayer() then return end
    local weak = boss:GetNW2Bool("lc_shield_weak", false)
    local c = weak and SHIELD_WEAK or SHIELD
    local a = (25 + 70 * frac) * (weak and (0.5 + 0.5 * math.abs(math.sin(CurTime() * 9))) or 1)
    render.SetColorMaterial()
    render.DrawSphere(boss:GetPos() + Vector(0, 0, 40), 52, 24, 24, Color(c.r, c.g, c.b, a))
end)

------------------------------------------------------------------------
-- The last stand, and the heroes, on screen
------------------------------------------------------------------------

local function Bar(x, y, w, frac, r, g, b, label)
    surface.SetDrawColor(20, 22, 28, 200)
    surface.DrawRect(x, y, w, 12)
    surface.SetDrawColor(r, g, b, 230)
    surface.DrawRect(x + 1, y + 1, (w - 2) * math.Clamp(frac, 0, 1), 10)
    draw.SimpleText(label, "DermaDefault", x + w / 2, y + 6, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end

hook.Add("HUDPaint", "LivingCityCollapseHUD", function()
    local me = LocalPlayer()
    if not IsValid(me) then return end
    local w = ScrW()
    local hero = me:GetNW2String("lc_hero", "")
    if hero ~= "" and HERO_NAMES[hero] then
        draw.SimpleTextOutlined("YOU ARE " .. HERO_NAMES[hero], "DermaLarge", w / 2, ScrH() * 0.12, Color(255, 170, 60), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 2, color_black)
    end
    if GetGlobal2String("lc_collapse_stage", "") ~= "stand" then return end
    local boss = GetGlobal2Entity("lc_collapse_boss")
    local left = math.max(0, GetGlobal2Float("lc_collapse_until", 0) - CurTime())
    local y = 40
    draw.SimpleTextOutlined(string.format("THE ADMINISTRATOR'S LAST STAND   %d:%02d", math.floor(left / 60), math.floor(left % 60)), "DermaDefaultBold", w / 2, y,
        Color(200, 160, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, 1, color_black)
    if IsValid(boss) then
        local hp = boss:Health() / math.max(1, boss:GetMaxHealth())
        Bar(w / 2 - 110, y + 18, 220, hp, 220, 70, 60, "Health")
        local sh = boss:GetNW2Float("lc_shield_frac", 0)
        local weak = boss:GetNW2Bool("lc_shield_weak", false)
        Bar(w / 2 - 110, y + 33, 220, sh, weak and 255 or 140, weak and 150 or 110, weak and 60 or 255, sh > 0 and (weak and "Shield (power cut: weak)" or "Shield") or "Shield broken")
    end
    local h = GetGlobal2String("lc_collapse_hero", "")
    if h ~= "" and HERO_NAMES[h] then
        draw.SimpleTextOutlined(HERO_NAMES[h] .. " IS IN THE CITY", "DermaDefaultBold", w / 2, y + 50, Color(255, 170, 60), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, 1, color_black)
    end
    -- where her office is (not for her)
    if boss ~= me then
        local office = GetGlobal2Vector("lc_collapse_office", vector_origin)
        if office ~= vector_origin then
            local sp = (office + Vector(0, 0, 60)):ToScreen()
            if sp.visible then
                local d = math.floor(me:GetPos():Distance(office) / 52.5)
                draw.SimpleTextOutlined("HER OFFICE  " .. d .. " m", "DermaDefaultBold", sp.x, sp.y, Color(200, 160, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, color_black)
            end
        end
    end
end)
