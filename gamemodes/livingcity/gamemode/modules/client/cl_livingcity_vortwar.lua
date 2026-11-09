--[[
    Living City: vortigaunt dream warfare, your side (sv_livingcity_vortwar.lua)

    While the vortigaunts are in a propaganda dream: the screen turns purple, each vortigaunt
    stands in a ring of purple light (stand in one to side with them), and a tug-of-war meter at
    the top shows who's winning, her or them, and which side you're on.
]]

LC_CL = LC_CL or {}

local function VW()
    local st = LC_CL.DreamGame and LC_CL.DreamGame()
    return st and st.vw or nil
end
LC_CL.VortWar = VW

local glow = Material("sprites/light_glow02_add")
local PURPLE, PALE = Color(175, 90, 255), Color(220, 180, 255)

hook.Add("RenderScreenspaceEffects", "LivingCityVortWar", function()
    local vw = VW()
    if not vw or not DrawColorModify then return end
    DrawColorModify({ ["$pp_colour_addr"] = 0.04, ["$pp_colour_addg"] = 0, ["$pp_colour_addb"] = 0.09, ["$pp_colour_brightness"] = 0,
        ["$pp_colour_contrast"] = 1.05, ["$pp_colour_colour"] = 0.8, ["$pp_colour_mulr"] = 0.1, ["$pp_colour_mulg"] = 0, ["$pp_colour_mulb"] = 0.3 })
end)

hook.Add("PostDrawTranslucentRenderables", "LivingCityVortWar", function(_, sky)
    local vw = VW()
    if sky or not vw or not render then return end
    render.SetMaterial(glow)
    local r = vw.r or 120
    local now = CurTime()
    for _, s in ipairs(vw.spots or {}) do
        local c = Vector(s[1], s[2], s[3] + 4)
        for i = 0, 15 do
            local a = i / 16 * math.pi * 2 + now * 0.6
            render.DrawSprite(c + Vector(math.cos(a) * r, math.sin(a) * r, 0), 46, 46, PURPLE)
        end
        local p = 160 + 30 * math.sin(now * 2)
        render.DrawSprite(c + Vector(0, 0, 60), p, p, PURPLE)
    end
end)

hook.Add("HUDPaint", "LivingCityVortWar", function()
    local vw = VW()
    if not vw then return end
    local w, h = 420, 16
    local x, y = (ScrW() - w) / 2, ScrH() * 0.17
    local m = math.Clamp(vw.meter or 0, -1, 1)
    surface.SetDrawColor(0, 0, 0, 170)
    surface.DrawRect(x - 2, y - 2, w + 4, h + 4)
    surface.SetDrawColor(80, 80, 90, 200)
    surface.DrawRect(x, y, w, h)
    local mid = x + w / 2
    if m > 0 then
        surface.SetDrawColor(175, 90, 255, 230)
        surface.DrawRect(mid, y, w / 2 * m, h)
    elseif m < 0 then
        surface.SetDrawColor(255, 215, 120, 230)
        surface.DrawRect(mid + w / 2 * m, y, -w / 2 * m, h)
    end
    surface.SetDrawColor(255, 255, 255, 220)
    surface.DrawRect(mid - 1, y - 3, 2, h + 6)
    draw.SimpleTextOutlined("HER", "DermaDefaultBold", x - 8, y + h / 2, Color(255, 215, 120), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER, 1, color_black)
    draw.SimpleTextOutlined("THE VORTIGAUNTS", "DermaDefaultBold", x + w + 8, y + h / 2, PALE, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER, 1, color_black)
    draw.SimpleTextOutlined(vw.light and "You stand in their light" or "You keep to her", "DermaDefault", ScrW() / 2, y + h + 12,
        vw.light and PALE or Color(255, 215, 120), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, color_black)
end)
