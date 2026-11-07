--[[
    Living City (client): traitors, hijacked screens, and what custody did to you

    The Resistance see TRAITOR over anyone known to have informed or talked in
    custody. A hijacked city screen shows the lambda. A crippled player sees how
    long until they can run; a stalker how long they have left to serve; someone
    being interrogated how to make it stop.
]]

LC_CL = LC_CL or {}

local RED = Color(255, 80, 70)
local LAMBDA = Color(230, 150, 60)

local function MyFaction() return LocalPlayer():GetNW2String("lcf_faction", "") end

-- (made once here, not every frame)
local C_200_180_170 = Color(200, 180, 170)
local C_230_190_160 = Color(230, 190, 160)
local V_0_0_82 = Vector(0, 0, 82)
hook.Add("HUDPaint", "LivingCityTraitors", function()
    local me = LocalPlayer()
    if not IsValid(me) then return end
    local now = CurTime()
    if MyFaction() == "resistance" then
        for _, p in LC.Players() do
            if p ~= me and p:Alive() and p:GetNW2Float("lc_traitor_until", 0) > now and p:GetPos():DistToSqr(me:GetPos()) < 1500 * 1500 then
                local s = (p:GetPos() + V_0_0_82):ToScreen()
                if s.visible then
                    draw.SimpleTextOutlined("TRAITOR", "DermaDefaultBold", s.x, s.y, RED, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM, 1, color_black)
                end
            end
        end
    end
    local y = ScrH() * 0.72
    local crip = me:GetNW2Float("lc_crippled_until", 0) - now
    if crip > 0 then
        draw.SimpleTextOutlined(string.format("BROKEN FEET: no running for %d:%02d", math.floor(crip / 60), math.floor(crip % 60)), "DermaDefault",
            ScrW() - 20, y, C_230_190_160, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER, 1, color_black)
        y = y + 16
    end
    if MyFaction() == "stalker" then
        draw.SimpleTextOutlined("COMBINE PROPERTY: there is no way out but death", "DermaDefaultBold",
            ScrW() / 2, ScrH() * 0.1, C_200_180_170, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, color_black)
    end
    if me:GetNW2Bool("lc_interrogated", false) then
        draw.SimpleTextOutlined("INTERROGATION   Talk (F1, or the choice on screen) to make it stop. Or say nothing, and take it.", "DermaDefaultBold",
            ScrW() / 2, ScrH() * 0.78, RED, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, color_black)
    end
end)

-- Stalkers see the world the way the Combine left them: dim, and closer.
hook.Add("HUDPaintBackground", "LivingCityStalkerView", function()
    if MyFaction() ~= "stalker" then return end
    surface.SetDrawColor(30, 15, 10, 90)
    surface.DrawRect(0, 0, ScrW(), ScrH())
end)

-- A hijacked city screen: the Resistance's minute
timer.Simple(0, function()
    local orig = LC_CL.DrawCityScreen
    -- who's on air: a player, the Administrator at the studio, or her recording
    local function OnAir()
        local live = GetGlobal2Entity("lc_live")
        if IsValid(live) and live:IsPlayer() then return live, live:Nick() end
        if IsValid(live) or GetGlobal2Bool("lc_live_npc", false) then
            local n = IsValid(live) and live:GetNW2String("lc_pname", "") or ""
            if n == "" then n = GetGlobal2String("lc_live_name", "") end
            return live, n ~= "" and n or "The Administrator"
        end
    end
    LC_CL.OnAir = OnAir
    LC_CL.DrawCityScreen = function(ent)
        -- someone on air: every screen shows it
        local live, liveName = OnAir()
        if liveName then
            local pirate = GetGlobal2Bool("lc_live_pirate", false)
            local col = pirate and LAMBDA or Color(150, 210, 240)
            -- the camera's picture (cl_livingcity_livecam.lua), with the station's captions over it
            local pic, u, v
            if LC_CL.LiveCamPicture then pic, u, v = LC_CL.LiveCamPicture() end
            if pic then
                surface.SetDrawColor(255, 255, 255)
                surface.SetMaterial(pic)
                surface.DrawTexturedRectUV(-320, -180, 640, 360, 0, 0, u, v)
                draw.RoundedBox(0, -320, -180, 640, 34, Color(10, 12, 16, 200))
                draw.SimpleText(pirate and "PIRATE BROADCAST" or "CITY BROADCAST", "DermaDefaultBold", -306, -163, col, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                if math.floor(CurTime() * 2) % 2 == 0 then
                    draw.RoundedBox(6, 236, -170, 12, 12, Color(255, 60, 50))
                    draw.SimpleText("LIVE", "DermaDefaultBold", 256, -163, Color(255, 80, 70), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                end
                draw.RoundedBox(0, -320, 130, 640, 50, Color(10, 12, 16, 200))
                draw.SimpleText(string.upper(liveName), "DermaLarge", -306, 155, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                return
            end
            draw.RoundedBox(0, -320, -180, 640, 360, Color(12, 14, 18, 250))
            draw.SimpleText(pirate and "PIRATE BROADCAST" or "CITY BROADCAST", "DermaLarge", 0, -120, col, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            draw.SimpleText(string.upper(liveName), "DermaLarge", 0, -60, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            if math.floor(CurTime() * 2) % 2 == 0 then draw.SimpleText("ON AIR", "DermaLarge", 0, 20, Color(255, 80, 70), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER) end
            local bars = 12
            for i = 1, bars do
                local hgt = 10 + math.abs(math.sin(CurTime() * 7 + i)) * 60
                surface.SetDrawColor(col)
                surface.DrawRect(-180 + (i - 1) * 30, 150 - hgt, 18, hgt)
            end
            return
        end
        if IsValid(ent) and ent:GetNW2Float("lc_hijacked_until", 0) > CurTime() then
            local left = math.ceil(ent:GetNW2Float("lc_hijacked_until", 0) - CurTime())
            draw.RoundedBox(0, -480, -270, 960, 540, Color(15, 12, 10, 245))
            surface.SetDrawColor(LAMBDA) -- the lambda, drawn
            for w = -3, 3 do surface.DrawLine(-30 + w, -150, 40 + w, -50) surface.DrawLine(5 + w, -100, -35 + w, -50) end
            draw.SimpleText("FREE CITY 17", "DermaLarge", 0, 0, LAMBDA, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            draw.SimpleText("They are not invincible. Look out for one another.", "DermaDefaultBold", 0, 50, Color(220, 210, 200), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            draw.SimpleText(left .. "s", "DermaDefault", 0, 90, Color(180, 170, 160), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            return
        end
        if orig then return orig(ent) end
    end
end)

-- Someone on air: a banner for everyone, so you know whose voice it is
-- (made once here, not every frame)
local C_150_210_240 = Color(150, 210, 240)
hook.Add("HUDPaint", "LivingCityLive", function()
    local _, liveName
    if LC_CL.OnAir then _, liveName = LC_CL.OnAir() end
    if not liveName then return end
    local pirate = GetGlobal2Bool("lc_live_pirate", false)
    local quiet = LC_CL.SpeakerBrokenNear and LC_CL.SpeakerBrokenNear(LocalPlayer():GetPos())
    local text = (pirate and "PIRATE BROADCAST: " or "CITY BROADCAST: ") .. liveName .. (quiet and "  (the loudspeaker here is broken)" or "")
    draw.SimpleTextOutlined(text, "DermaDefaultBold", ScrW() / 2, 96, pirate and LAMBDA or C_150_210_240, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, color_black)
end)
