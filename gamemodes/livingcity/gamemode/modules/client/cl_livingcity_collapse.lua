--[[
    Living City: the collapse on screen (sv_livingcity_collapse.lua)

      The G-Man, in person    his words and voice (he himself is lc_gman, in front of her, only she sees him);
                              walk away from him or shut his window, and 10 seconds to go back and press E
      The G-Man's offer       a window for the Administrator: step down, end it yourself, or refuse him
      Her shield              a bubble round the Administrator in her last stand, and a faint stream of
                              power from her transformer to it
      The last stand          the time left, her health, her transformer's, where she and it are
      Heroes                  who the hero is, and "you are" for the one playing him
]]

LC_CL = LC_CL or {}

local HERO_NAMES = { barney = "BARNEY CALHOUN", freeman = "GORDON FREEMAN" }

------------------------------------------------------------------------
-- The G-Man, in person, in front of the Administrator (the owner, 10 November: "not only a window popping up,
-- but the Gman appears before the administrator himself and tries to force the issue")
------------------------------------------------------------------------

-- (he's lc_gman, a real thing in the world only she is sent: this is his voice and words on her screen)
local GM -- { kind, text, textUntil, leaveAt }
LC_CL.CollapseGmanState = function() return GM end

net.Receive("lc_collapse_gman", function()
    local kind, text, snd = net.ReadString(), net.ReadString(), net.ReadString()
    if snd ~= "" and file.Exists("sound/" .. snd, "GAME") then surface.PlaySound(snd) end
    GM = GM or {}
    GM.kind, GM.text, GM.textUntil = kind, text, CurTime() + math.max(5, #text / 12)
    GM.leaveAt = (kind == "leave") and CurTime() + 3 or (kind == "visit" and CurTime() + math.max(8, #text / 10) + 3) or nil
    if kind == "walkaway" and IsValid(LC_CL.CollapseOffer) then LC_CL.CollapseOffer:Remove() end
end)
hook.Add("Think", "LivingCityCollapseGman", function()
    if GM and GM.leaveAt and CurTime() >= GM.leaveAt then GM = nil end
end)

-- his words, and the world dimming at the edges while he's there
hook.Add("HUDPaint", "LivingCityCollapseGmanWords", function()
    if not GM then return end
    local w, h = ScrW(), ScrH()
    local a = GM.leaveAt and math.Clamp((GM.leaveAt - CurTime()) / 3, 0, 1) or 1
    for i = 0, 5 do
        surface.SetDrawColor(0, 0, 0, (60 - i * 10) * a)
        surface.DrawRect(0, 0, w, h * (0.12 - i * 0.02))
        surface.DrawRect(0, h - h * (0.12 - i * 0.02), w, h * (0.12 - i * 0.02))
    end
    if GM.text ~= "" and CurTime() < (GM.textUntil or 0) then
        draw.SimpleTextOutlined(GM.text, "DermaLarge", w / 2, h * 0.8, Color(225, 225, 210, 255 * a), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(0, 0, 0, 200 * a))
    end
end)

-- walked away from him: 10 seconds to go back and press E on him, or it's a refusal
hook.Add("HUDPaint", "LivingCityCollapseGmanBack", function()
    local me = LocalPlayer()
    if not IsValid(me) then return end
    local left = me:GetNW2Float("lc_gman_back_by", 0) - CurTime()
    if left <= 0 then return end
    local w, h = ScrW(), ScrH()
    draw.SimpleTextOutlined(string.format("Go back to him and press E (%d)", math.ceil(left)), "DermaLarge", w / 2, h * 0.32,
        Color(255, 200, 120), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 2, color_black)
    draw.SimpleTextOutlined("Walking away is a refusal.", "DermaDefaultBold", w / 2, h * 0.32 + 30, Color(230, 230, 230), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, color_black)
end)

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
    -- (closing it is walking away from him: 10 seconds to come back and press E on him, or it's a refusal)
    local x = vgui.Create("DButton", f)
    x:SetText("Walk away")
    x:SetPos(520 - 92, 6)
    x:SetSize(84, 22)
    x:SetTooltip("Brush him aside. He gives you 10 seconds to come back and press E on him; after that it's a refusal.")
    x.DoClick = function() Send("walkaway") end
end)

------------------------------------------------------------------------
-- Her shield
------------------------------------------------------------------------

local SHIELD = Color(140, 110, 255, 60)
local BEAM = Material("sprites/physbeam")
local SPARK = Material("sprites/light_glow02_add")
hook.Add("PostDrawTranslucentRenderables", "LivingCityCollapseShield", function(depth, sky)
    if sky then return end
    local boss = GetGlobal2Entity("lc_collapse_boss")
    if not IsValid(boss) then return end
    if boss:GetNW2Float("lc_shield_frac", 0) <= 0 then return end
    local centre = boss:GetPos() + Vector(0, 0, 40)
    -- the bubble (not drawn round her own first-person view)
    if not (boss == LocalPlayer() and not LocalPlayer():ShouldDrawLocalPlayer()) then
        local a = 45 + 25 * math.abs(math.sin(CurTime() * 2))
        render.SetColorMaterial()
        render.DrawSphere(centre, 52, 24, 24, Color(SHIELD.r, SHIELD.g, SHIELD.b, a))
    end
    -- the power, a faint stream from her transformer to the bubble
    local power = GetGlobal2Entity("lc_collapse_power")
    if IsValid(power) and not power:GetNW2Bool("lc_power_down", false) then
        local from = power:LocalToWorld(Vector(0, 0, power:OBBMaxs().z * 0.85))
        local len = from:Distance(centre)
        local scroll = CurTime() * 2
        render.SetMaterial(BEAM)
        render.DrawBeam(from, centre, 6, scroll, scroll + len / 96, Color(170, 130, 255, 70 + 30 * math.abs(math.sin(CurTime() * 6))))
        render.SetMaterial(SPARK)
        render.DrawSprite(from, 20, 20, Color(190, 150, 255, 120))
    end
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
        local power = GetGlobal2Entity("lc_collapse_power")
        local up = boss:GetNW2Float("lc_shield_frac", 0) > 0
        if IsValid(power) then
            local down = power:GetNW2Bool("lc_power_down", false)
            Bar(w / 2 - 110, y + 33, 220, down and 0 or power:GetNW2Float("lc_power_frac", 1), 160, 120, 255,
                down and "Her transformer: destroyed. Her shield is down" or (up and "Her transformer (her shield deflects everything)" or "Her transformer (she's out of its reach)"))
        end
    end
    local h = GetGlobal2String("lc_collapse_hero", "")
    if h ~= "" and HERO_NAMES[h] then
        draw.SimpleTextOutlined(HERO_NAMES[h] .. " IS IN THE CITY", "DermaDefaultBold", w / 2, y + 50, Color(255, 170, 60), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, 1, color_black)
    end
    -- where her transformer is: what the rebellion has to destroy, and the Combine to guard
    local power = GetGlobal2Entity("lc_collapse_power")
    if IsValid(power) and not power:GetNW2Bool("lc_power_down", false) and boss ~= me then
        local sp = (power:GetPos() + Vector(0, 0, power:OBBMaxs().z + 16)):ToScreen()
        if sp.visible then
            local f = me:GetNW2String("lcf_faction", "")
            local mine = f == "cp" or f == "admin"
            draw.SimpleTextOutlined(mine and "HER TRANSFORMER: GUARD IT" or "HER TRANSFORMER: DESTROY IT", "DermaDefaultBold", sp.x, sp.y, Color(255, 170, 60), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, color_black)
        end
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
