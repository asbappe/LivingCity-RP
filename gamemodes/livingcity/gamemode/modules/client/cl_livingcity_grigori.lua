--[[
    Living City (client): Father Grigori's window (sv_livingcity_grigori.lua),
    and the powered vest's charge on screen in place of HL2's "SUIT"
    (sv_livingcity_vest.lua), with being blessed or emboldened under it.
]]

LC_CL = LC_CL or {}

local INK, DIM, GOLD = Color(235, 230, 215), Color(170, 165, 150), Color(225, 190, 110)

------------------------------------------------------------------------
-- Father Grigori
------------------------------------------------------------------------

local frame

local function Ask(what)
    net.Start("lc_grigori_ask")
    net.WriteString(what)
    net.SendToServer()
    if IsValid(frame) then frame:Remove() end
end
LC_CL.GrigoriAsk = Ask

net.Receive("lc_grigori", function()
    local rebel, blessIn, sermonIn = net.ReadBool(), net.ReadFloat(), net.ReadFloat()
    if IsValid(frame) then frame:Remove() end
    frame = vgui.Create("DFrame")
    frame:SetTitle("")
    frame:SetSize(math.min(ScrW() - 40, 440), 230)
    frame:Center()
    frame:MakePopup()
    frame.Paint = function(s, w, h)
        draw.RoundedBox(6, 0, 0, w, h, Color(24, 20, 16, 245))
        draw.SimpleText("FATHER GRIGORI", "DermaLarge", 16, 10, GOLD)
        draw.SimpleText(rebel and "\"What do you need, child?\"" or "\"Go with God. But go.\"", "DermaDefault", 16, 46, DIM)
    end
    local function Btn(y, label, sub, what, enabled)
        local b = vgui.Create("DButton", frame)
        b:SetPos(16, y)
        b:SetSize(frame:GetWide() - 32, 42)
        b:SetText("")
        b:SetEnabled(enabled)
        b.Paint = function(s, w, h)
            draw.RoundedBox(4, 0, 0, w, h, (not enabled and Color(45, 42, 38)) or (s:IsHovered() and Color(90, 70, 40) or Color(60, 48, 32)))
            draw.SimpleText(label, "DermaDefaultBold", 10, 8, enabled and INK or DIM)
            draw.SimpleText(sub, "DermaDefault", 10, 24, DIM)
        end
        b.DoClick = function() Ask(what) end
    end
    Btn(70, "Ask for his blessing", blessIn > 0 and string.format("Again in %d s", math.ceil(blessIn)) or "25 health, and five minutes of taking less harm", "bless", rebel and blessIn <= 0)
    Btn(118, "Ask him to preach", sermonIn > 0 and string.format("Again in %d s", math.ceil(sermonIn)) or "Everyone of ours nearby is emboldened for ten minutes", "sermon", rebel and sermonIn <= 0)
    Btn(166, "Talk to him", "A word from the old man", "talk", true)
end)

------------------------------------------------------------------------
-- The vest's charge, in place of HL2's suit power
------------------------------------------------------------------------

hook.Add("HUDShouldDraw", "LivingCityVest", function(name)
    if name == "CHudBattery" then return false end
end)

hook.Add("HUDPaint", "LivingCityVest", function()
    local me = LocalPlayer()
    if not IsValid(me) or not me:Alive() then return end
    local h = ScrH()
    local x, y = 20, h - 150
    local now = CurTime()
    local lines = {}
    if me:GetNW2Float("lc_blessed_until", 0) > now then lines[#lines + 1] = { string.format("Blessed (%d s)", math.ceil(me:GetNW2Float("lc_blessed_until", 0) - now)), GOLD } end
    if me:GetNW2Float("lc_emboldened_until", 0) > now then lines[#lines + 1] = { string.format("Emboldened (%d s)", math.ceil(me:GetNW2Float("lc_emboldened_until", 0) - now)), Color(230, 140, 90) } end
    local armor = me:Armor()
    local cap = math.max(me:GetNW2Int("lc_vest_cap", 0), me:GetNW2Bool("lc_vest", false) and 75 or 0, armor)
    if cap > 0 then
        draw.RoundedBox(4, x, y, 200, 30, Color(10, 12, 16, 190))
        draw.SimpleText("VEST", "DermaDefaultBold", x + 8, y + 15, Color(150, 200, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        draw.RoundedBox(2, x + 52, y + 9, 138, 12, Color(30, 34, 40))
        draw.RoundedBox(2, x + 52, y + 9, 138 * math.Clamp(armor / cap, 0, 1), 12, Color(110, 170, 255))
        y = y - 20
    end
    for _, l in ipairs(lines) do
        draw.SimpleText(l[1], "DermaDefaultBold", x + 4, y, l[2])
        y = y - 16
    end
end)
