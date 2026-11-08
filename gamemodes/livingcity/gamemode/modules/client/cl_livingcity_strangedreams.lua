--[[
    Living City: the strange dreams, your side (sv_livingcity_strangedreams.lua)

      The Cheese Dream: the screen goes black and Half-Life 2's citizens, a man and then a woman,
      say "Sometimes I dream about cheese", each line echoing away, then both at once, before the
      dream swims up. Then it's psychedelic: the colours roll round the rainbow, the picture
      ripples and smears, rainbow sparks drift round you and the music wobbles. Golden cheese turns
      the colours inside out for a few seconds.
      Wings: golden rings hanging in the sky (fly through them), clouds, a pale blue sky.
      It's Raining Melons: a warm summer light. Musical Chairs: the music stops, and you'd better sit.
      (The rest, the glows, the meter, the music, is the dreams' own screen: cl_livingcity_dreamgames.lua.)
]]

LC_CL = LC_CL or {}

local function St() return LC_CL.DreamGame and LC_CL.DreamGame() or nil end
local glow = Material("sprites/light_glow02_add")

-- A colour round the rainbow (h from 0 to 1).
local function Rainbow(h, a)
    h = (h or 0) % 1
    local i = math.floor(h * 6)
    local f = h * 6 - i
    local q = 1 - f
    local rgb = ({ { 1, f, 0 }, { q, 1, 0 }, { 0, 1, f }, { 0, q, 1 }, { f, 0, 1 }, { 1, 0, q } })[i + 1]
    return Color(math.floor(rgb[1] * 255), math.floor(rgb[2] * 255), math.floor(rgb[3] * 255), a or 255)
end

------------------------------------------------------------------------
-- The Cheese Dream: the voices in the dark
------------------------------------------------------------------------

-- Each line, then its echoes: later, quieter, lower. (delay, volume, pitch)
LC_CL.CheeseEchoes = { { 0, 1, 100 }, { 0.5, 0.6, 95 }, { 1.0, 0.35, 90 }, { 1.5, 0.2, 85 }, { 2.0, 0.1, 80 } }
local function Echo(path, at, pitch)
    if not path then return end
    for _, e in ipairs(LC_CL.CheeseEchoes) do
        timer.Simple(at + e[1], function()
            local me = LocalPlayer()
            if not IsValid(me) or not me:GetNW2Bool("lc_dreaming", false) then return end
            me:EmitSound(path, 75, math.floor(e[3] * (pitch or 100) / 100), e[2], CHAN_STATIC or 6)
        end)
    end
end
-- The man, then the woman, then both together, slower and faster.
function LC_CL.CheeseIntro(lines)
    lines = lines or {}
    Echo(lines[1], 0.5)
    Echo(lines[2], 3.3)
    Echo(lines[1], 6.0, 80)
    Echo(lines[2], 6.15, 125)
end

local seen
hook.Add("Think", "LivingCityStrangeDreams", function()
    local st = St()
    if st == seen then
        -- the music wobbles in the cheese dream
        if st and st.theme == "cheese" and LC_CL.DreamGameSongChannel then
            local ch = LC_CL.DreamGameSongChannel()
            if IsValid(ch) and ch.SetPlaybackRate then ch:SetPlaybackRate(1 + 0.12 * math.sin(CurTime() * 0.9)) end
        end
        return
    end
    seen = st
    if st and st.theme == "cheese" and (st.intro or 0) > CurTime() then LC_CL.CheeseIntro(st.lines) end
end)

------------------------------------------------------------------------
-- How it looks
------------------------------------------------------------------------

local function Cm(t) if DrawColorModify then DrawColorModify(t) end end
hook.Add("RenderScreenspaceEffects", "LivingCityStrangeDreams", function()
    local st = St()
    if not st then return end
    local now = CurTime()
    if st.theme == "cheese" then
        local intro = st.intro or 0
        if now < intro then -- (dark while the voices echo; it swims up over the last two seconds)
            local f = math.Clamp((intro - now) / 2, 0, 1)
            Cm({ ["$pp_colour_addr"] = 0, ["$pp_colour_addg"] = 0, ["$pp_colour_addb"] = 0, ["$pp_colour_brightness"] = -f,
                ["$pp_colour_contrast"] = 1, ["$pp_colour_colour"] = 1, ["$pp_colour_mulr"] = 0, ["$pp_colour_mulg"] = 0, ["$pp_colour_mulb"] = 0 })
            return
        end
        local flip = (st.flip or 0) > now
        Cm({ ["$pp_colour_addr"] = 0.07 * math.sin(now * 1.3), ["$pp_colour_addg"] = 0.07 * math.sin(now * 1.7 + 2), ["$pp_colour_addb"] = 0.07 * math.sin(now * 2.1 + 4),
            ["$pp_colour_brightness"] = 0.02, ["$pp_colour_contrast"] = flip and 1.4 or 1.1, ["$pp_colour_colour"] = flip and -1.6 or (1.9 + 0.7 * math.sin(now * 0.5)),
            ["$pp_colour_mulr"] = 0.8 * math.sin(now * 0.9), ["$pp_colour_mulg"] = 0.8 * math.sin(now * 1.1 + 1), ["$pp_colour_mulb"] = 0.8 * math.sin(now * 1.3 + 2) })
        if DrawMotionBlur then DrawMotionBlur(0.12, 0.7, 0.01) end
        if DrawMaterialOverlay then DrawMaterialOverlay("effects/water_warp01", 0.04 + 0.03 * math.sin(now * 0.7)) end
    elseif st.theme == "flying" then
        Cm({ ["$pp_colour_addr"] = 0, ["$pp_colour_addg"] = 0.01, ["$pp_colour_addb"] = 0.04, ["$pp_colour_brightness"] = 0.03,
            ["$pp_colour_contrast"] = 1.05, ["$pp_colour_colour"] = 1.2, ["$pp_colour_mulr"] = 0, ["$pp_colour_mulg"] = 0, ["$pp_colour_mulb"] = 0 })
    elseif st.theme == "melons" then
        Cm({ ["$pp_colour_addr"] = 0.03, ["$pp_colour_addg"] = 0.02, ["$pp_colour_addb"] = 0, ["$pp_colour_brightness"] = 0.02,
            ["$pp_colour_contrast"] = 1.05, ["$pp_colour_colour"] = 1.3, ["$pp_colour_mulr"] = 0, ["$pp_colour_mulg"] = 0, ["$pp_colour_mulb"] = 0 })
    end
end)

hook.Add("PostDrawTranslucentRenderables", "LivingCityStrangeDreams", function(_, sky)
    local st = St()
    if sky or not st then return end
    local now = CurTime()
    if st.theme == "cheese" and now >= (st.intro or 0) then -- (rainbow sparks drifting round you)
        local me = LocalPlayer()
        if not IsValid(me) then return end
        local at = me:GetPos()
        render.SetMaterial(glow)
        for i = 1, 24 do
            local a = i * 0.9 + now * (0.2 + (i % 5) * 0.05)
            local r = 120 + (i * 37) % 260
            local p = at + Vector(math.cos(a) * r, math.sin(a) * r, 30 + ((i * 53) % 220) + math.sin(now * 2 + i) * 30)
            local sz = 18 + 10 * math.sin(now * 3 + i)
            render.DrawSprite(p, sz, sz, Rainbow(now * 0.2 + i / 24, 200))
        end
    elseif st.theme == "flying" then
        render.SetMaterial(glow)
        local ea = EyeAngles and EyeAngles() or Angle(0, 0, 0)
        local right, up = ea:Right(), ea:Up()
        local pulse = 0.85 + 0.15 * math.sin(now * 4)
        for _, r in ipairs(st.rings or {}) do -- (each ring faces you)
            local c = Vector(r[1], r[2], r[3])
            for i = 1, 20 do
                local a = i / 20 * math.pi * 2 + now
                render.DrawSprite(c + right * math.cos(a) * 70 + up * math.sin(a) * 70, 26 * pulse, 26 * pulse, Color(255, 210, 80))
            end
            render.DrawSprite(c, 60, 60, Color(255, 240, 180, 80))
        end
        local ctr = st.center
        if ctr then -- (clouds)
            for i = 1, 14 do
                local a = i * 2.4 + now * 0.02
                local d = 300 + (i * 97) % 900
                local h = (st.ceiling or (ctr[3] + 800)) - ctr[3]
                local p = Vector(ctr[1] + math.cos(a) * d, ctr[2] + math.sin(a) * d, ctr[3] + h * (0.35 + ((i * 31) % 60) / 100))
                render.DrawSprite(p, 420, 260, Color(255, 255, 255, 50))
            end
        end
    end
end)

-- The Cheese Dream's words in the dark.
hook.Add("HUDPaint", "LivingCityStrangeDreams", function()
    local st = St()
    if not st or st.theme ~= "cheese" then return end
    local now = CurTime()
    local intro = st.intro or 0
    if now >= intro then return end
    local left = intro - now
    local from = intro - 9
    local t = now - from
    local a = math.floor(255 * math.Clamp(math.min(t / 1.5, left / 1.5), 0, 1))
    local text = t < 3 and "Sometimes..." or (t < 6 and "Sometimes... I dream about cheese." or "Sometimes... I dream... about... cheese.")
    local x = ScrW() / 2 + math.sin(now * 2) * 12
    local y = ScrH() * 0.45 + math.cos(now * 1.6) * 8
    draw.SimpleTextOutlined(text, "DermaLarge", x, y, Rainbow(now * 0.15, a), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(0, 0, 0, a))
end)
