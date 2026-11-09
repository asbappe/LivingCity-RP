--[[
    Living City: the strange dreams, your side (sv_livingcity_strangedreams.lua, sv_livingcity_strangedreams2.lua)

      The voices in the dark (The Cheese Dream, Hooves and All): the screen goes black, and each line
      comes as if from far away, then echoes, further and further off, drifting from one side to the
      other, fading and sinking in pitch, in a cavern's reverb (the owner: "a dreamy distant echo
      effect"); then both voices at once, and the dream swims up out of the dark.
      The Cheese Dream: psychedelic (the colours roll round the rainbow, the picture ripples and smears,
      rainbow sparks drift round you, the music wobbles; golden cheese turns the colours inside out).
      Wings: golden rings, clouds, a pale blue sky. It's Raining Melons: summer light.
      Hooves and All: a cold night, the horse's red eyes, a flash at every shot. The Main Event: the
      ring's ropes and a spotlight; a red glow under it as it winds up. Running in Molasses: sepia and
      smeared. Hot Potato: the grenade glows red, faster as it burns down. Dance Marathon: the lights
      flash on the beat and a ring closes in on every big beat. Counting Headcrabs: a sleepy night.
      (The glows, boards, meters, music and lines are the dreams' own screen: cl_livingcity_dreamgames.lua.)
]]

LC_CL = LC_CL or {}

local function St() return LC_CL.DreamGame and LC_CL.DreamGame() or nil end
local glow = Material("sprites/light_glow02_add")
local beam = Material("cable/rope")

-- A colour round the rainbow (h from 0 to 1).
local function Rainbow(h, a)
    h = (h or 0) % 1
    local i = math.floor(h * 6)
    local f = h * 6 - i
    local q = 1 - f
    local rgb = ({ { 1, f, 0 }, { q, 1, 0 }, { 0, 1, f }, { 0, q, 1 }, { f, 0, 1 }, { 1, 0, q } })[i + 1]
    return Color(math.floor(rgb[1] * 255), math.floor(rgb[2] * 255), math.floor(rgb[3] * 255), a or 255)
end
LC_CL.StrangeRainbow = Rainbow

------------------------------------------------------------------------
-- The voices in the dark: a dreamy, distant echo
------------------------------------------------------------------------

-- Each line, then its echoes: { delay, distance, volume, pitch }. The first is already far off;
-- every echo is further, quieter and lower, and drifts to the other side.
LC_CL.DreamEchoes = { { 0, 350, 0.9, 100 }, { 0.6, 750, 0.55, 97 }, { 1.2, 1150, 0.35, 94 }, { 1.8, 1550, 0.22, 91 }, { 2.4, 1950, 0.12, 88 }, { 3.0, 2350, 0.06, 85 } }
LC_CL.DreamEchoDSP = 25 -- (Source's "cavern, large": the server sets it too)
local function Far(dist, side)
    local me = LocalPlayer()
    local eye = (EyePos and EyePos()) or (IsValid(me) and me:GetPos() + Vector(0, 0, 64)) or Vector(0, 0, 0)
    local ang = (EyeAngles and EyeAngles()) or Angle(0, 0, 0)
    local yaw = math.rad(ang.y + 90 * side + 20 * side)
    return eye + Vector(math.cos(yaw) * dist, math.sin(yaw) * dist, 60)
end
local function Echo(path, at, pitch)
    if not path or path == "" then return end
    for i, e in ipairs(LC_CL.DreamEchoes) do
        timer.Simple(at + e[1], function()
            local me = LocalPlayer()
            if not IsValid(me) or not me:GetNW2Bool("lc_dreaming", false) then return end
            local p = math.floor(e[4] * (pitch or 100) / 100)
            if sound and sound.Play then
                sound.Play(path, Far(e[2], i % 2 == 0 and 1 or -1), 100, p, e[3])
            else
                me:EmitSound(path, 75, p, e[3], CHAN_STATIC or 6)
            end
        end)
    end
end
LC_CL.DreamEcho = Echo
-- The first voice, then the second, then both together, one lower and one higher.
function LC_CL.DreamIntro(lines)
    lines = lines or {}
    local me = LocalPlayer()
    if IsValid(me) and me.SetDSP then pcall(me.SetDSP, me, LC_CL.DreamEchoDSP, false) end
    Echo(lines[1], 0.4)
    Echo(lines[2] or lines[1], 3.0)
    Echo(lines[1], 5.6, 82)
    Echo(lines[2] or lines[1], 5.75, 122)
end
LC_CL.CheeseIntro = LC_CL.DreamIntro -- (its first name)

local seen
hook.Add("Think", "LivingCityStrangeDreams", function()
    local st = St()
    if st == seen then
        if st and st.theme == "cheese" and LC_CL.DreamGameSongChannel then -- (the music wobbles in the cheese dream)
            local ch = LC_CL.DreamGameSongChannel()
            if IsValid(ch) and ch.SetPlaybackRate then ch:SetPlaybackRate(1 + 0.12 * math.sin(CurTime() * 0.9)) end
        end
        return
    end
    seen = st
    if st and (st.intro or 0) > CurTime() and st.lines then LC_CL.DreamIntro(st.lines) end
end)

------------------------------------------------------------------------
-- How it looks
------------------------------------------------------------------------

local function Cm(addr, addg, addb, bright, contrast, colour, mulr, mulg, mulb)
    if not DrawColorModify then return end
    DrawColorModify({ ["$pp_colour_addr"] = addr or 0, ["$pp_colour_addg"] = addg or 0, ["$pp_colour_addb"] = addb or 0, ["$pp_colour_brightness"] = bright or 0,
        ["$pp_colour_contrast"] = contrast or 1, ["$pp_colour_colour"] = colour or 1, ["$pp_colour_mulr"] = mulr or 0, ["$pp_colour_mulg"] = mulg or 0, ["$pp_colour_mulb"] = mulb or 0 })
end
-- Where the next big beat is (Dance Marathon): seconds to it, and whether it's on now.
function LC_CL.DanceBeat(st, now)
    if not st or not st.bpm or not st.beat0 then return nil end
    local beat = 60 / st.bpm
    local t = now - st.beat0
    if t < -beat * 4 then return nil end
    local bar = beat * 4
    local into = t % bar
    return bar - into, into < 0.15 or into > bar - 0.05, math.floor(t / beat)
end

hook.Add("RenderScreenspaceEffects", "LivingCityStrangeDreams", function()
    local st = St()
    if not st then return end
    local now = CurTime()
    local intro = st.intro or 0
    if now < intro then -- (dark while the voices echo; it swims up over the last two seconds)
        Cm(0, 0, 0, -math.Clamp((intro - now) / 2, 0, 1), 1, 1)
        return
    end
    local th = st.theme
    if th == "cheese" then
        local flip = (st.flip or 0) > now
        Cm(0.07 * math.sin(now * 1.3), 0.07 * math.sin(now * 1.7 + 2), 0.07 * math.sin(now * 2.1 + 4), 0.02, flip and 1.4 or 1.1,
            flip and -1.6 or (1.9 + 0.7 * math.sin(now * 0.5)), 0.8 * math.sin(now * 0.9), 0.8 * math.sin(now * 1.1 + 1), 0.8 * math.sin(now * 1.3 + 2))
        if DrawMotionBlur then DrawMotionBlur(0.12, 0.7, 0.01) end
        if DrawMaterialOverlay then DrawMaterialOverlay("effects/water_warp01", 0.04 + 0.03 * math.sin(now * 0.7)) end
    elseif th == "flying" then Cm(0, 0.01, 0.04, 0.03, 1.05, 1.2)
    elseif th == "melons" then Cm(0.03, 0.02, 0, 0.02, 1.05, 1.3)
    elseif th == "horse" then
        Cm(0.02, 0, 0.03, -0.08, 1.25, 0.45)
        if st.stunned and DrawBloom then DrawBloom(0.6, 1.2, 9, 9, 1, 1, 1, 1, 1) end
    elseif th == "molasses" then
        Cm(0.06, 0.03, 0, -0.02, 1.1, 0.35)
        if DrawMotionBlur then DrawMotionBlur(0.05, 0.9, 0.02) end
    elseif th == "boxing" then Cm(0.02, 0.015, 0, 0, 1.15, 1.1)
    elseif th == "dance" then
        local _, on = LC_CL.DanceBeat(st, now)
        Cm(on and 0.08 or 0, 0, on and 0.06 or 0.02, on and 0.06 or 0, 1.1, 1.5)
    elseif th == "sheep" then Cm(0, 0, 0.05, -0.05, 1, 0.7)
    elseif th == "exam" then Cm(0.02, 0.02, 0, 0, 1.05, 0.8)
    elseif th == "train" then Cm(0, 0.01, 0.02, -0.02, 1.1, 0.6)
    end
end)

local function EntOf(i) local e = i and Entity and Entity(i) return IsValid(e) and e or nil end
local RED, GOLD = Color(255, 30, 20), Color(255, 210, 80)

hook.Add("PostDrawTranslucentRenderables", "LivingCityStrangeDreams", function(_, sky)
    local st = St()
    if sky or not st then return end
    local now = CurTime()
    local th = st.theme
    render.SetMaterial(glow)
    if th == "cheese" and now >= (st.intro or 0) then -- (rainbow sparks drifting round you)
        local me = LocalPlayer()
        if not IsValid(me) then return end
        local at = me:GetPos()
        for i = 1, 24 do
            local a = i * 0.9 + now * (0.2 + (i % 5) * 0.05)
            local r = 120 + (i * 37) % 260
            local p = at + Vector(math.cos(a) * r, math.sin(a) * r, 30 + ((i * 53) % 220) + math.sin(now * 2 + i) * 30)
            local sz = 18 + 10 * math.sin(now * 3 + i)
            render.DrawSprite(p, sz, sz, Rainbow(now * 0.2 + i / 24, 200))
        end
    elseif th == "flying" then
        local ea = EyeAngles and EyeAngles() or Angle(0, 0, 0)
        local right, up = ea:Right(), ea:Up()
        local pulse = 0.85 + 0.15 * math.sin(now * 4)
        for _, r in ipairs(st.rings or {}) do -- (each ring faces you)
            local c = Vector(r[1], r[2], r[3])
            for i = 1, 20 do
                local a = i / 20 * math.pi * 2 + now
                render.DrawSprite(c + right * math.cos(a) * 70 + up * math.sin(a) * 70, 26 * pulse, 26 * pulse, GOLD)
            end
            render.DrawSprite(c, 60, 60, Color(255, 240, 180, 80))
        end
        local ctr = st.center
        if ctr then -- (clouds)
            for i = 1, 14 do
                local a = i * 2.4 + now * 0.02
                local d = 300 + (i * 97) % 900
                local h = (st.ceiling or (ctr[3] + 800)) - ctr[3]
                render.DrawSprite(Vector(ctr[1] + math.cos(a) * d, ctr[2] + math.sin(a) * d, ctr[3] + h * (0.35 + ((i * 31) % 60) / 100)), 420, 260, Color(255, 255, 255, 50))
            end
        end
    elseif th == "horse" then -- (its red eyes; a flash as the shot hits)
        local e = EntOf(st.horse)
        if e then
            local sc = e.GetModelScale and e:GetModelScale() or 1
            local mx = e.OBBMaxs and e:OBBMaxs() or Vector(60, 10, 150)
            local fwd, side = e:GetAngles():Forward(), e:GetAngles():Right()
            local head = e:GetPos() + Vector(0, 0, mx.z * sc * 0.85) + fwd * mx.x * sc * 0.75
            local f = 0.8 + 0.2 * math.sin(now * 9)
            render.DrawSprite(head + side * 8, 22 * f, 22 * f, RED)
            render.DrawSprite(head - side * 8, 22 * f, 22 * f, RED)
            if st.stunned then render.DrawSprite(head, 160, 160, Color(255, 230, 190, 120)) end
        end
    elseif th == "boxing" and st.ring then -- (the ropes, a spotlight, and a red glow as it winds up)
        local x, y, z, r = st.ring[1], st.ring[2], st.ring[3], st.ring[4]
        local corners = { Vector(x - r, y - r, z), Vector(x + r, y - r, z), Vector(x + r, y + r, z), Vector(x - r, y + r, z) }
        local cols = { Color(220, 30, 30), Color(240, 240, 240), Color(40, 70, 220) }
        render.SetMaterial(beam)
        for k, h in ipairs({ 32, 52, 72 }) do
            for i = 1, 4 do
                local a, b = corners[i], corners[i % 4 + 1]
                render.DrawBeam(a + Vector(0, 0, h), b + Vector(0, 0, h), 3, 0, 1, cols[k])
            end
        end
        render.SetMaterial(glow)
        render.DrawSprite(Vector(x, y, z + 300), 300, 300, Color(255, 250, 220, 60))
        local foe = EntOf(st.foe)
        if foe and st.windup then render.DrawSprite(foe:GetPos() + Vector(0, 0, 10), 320, 320, Color(255, 30, 30, 160)) end
    elseif th == "potato" then
        local e = EntOf(st.nade)
        if e then
            local f = 0.6 + 0.4 * math.abs(math.sin(now * 8))
            render.DrawSprite(e:GetPos(), 70 * f, 70 * f, RED)
        end
    elseif th == "train" then
        local e = EntOf(st.door)
        if e then render.DrawSprite(e:GetPos() + Vector(0, 0, 60), 180, 220, Color(255, 230, 150, st.watched and 60 or 140)) end
    elseif th == "dance" then -- (the lights, on the beat)
        local _, on, beat = LC_CL.DanceBeat(st, now)
        local me = LocalPlayer()
        if beat and IsValid(me) then
            local at = me:GetPos()
            for i = 1, 12 do
                local a = i / 12 * math.pi * 2 + (beat or 0) * 0.5
                local c = Rainbow(i / 12 + (beat or 0) * 0.1, on and 255 or 120)
                render.DrawSprite(at + Vector(math.cos(a) * 300, math.sin(a) * 300, 220), on and 120 or 60, on and 120 or 60, c)
            end
        end
    elseif th == "sheep" then -- (stars)
        local me = LocalPlayer()
        if IsValid(me) then
            local at = me:GetPos()
            for i = 1, 30 do
                local p = at + Vector(((i * 137) % 1600) - 800, ((i * 251) % 1600) - 800, 700 + (i * 53) % 300)
                local tw = 0.6 + 0.4 * math.sin(now * 2 + i)
                render.DrawSprite(p, 14 * tw, 14 * tw, Color(255, 255, 230, 200))
            end
        end
    end
end)

-- The words in the dark, and the big beat.
hook.Add("HUDPaint", "LivingCityStrangeDreams", function()
    local st = St()
    if not st then return end
    local now = CurTime()
    local intro = st.intro or 0
    if now < intro then
        local secs = st.introSecs or 9
        local t = now - (intro - secs)
        local a = math.floor(255 * math.Clamp(math.min(t / 1.5, (intro - now) / 1.5), 0, 1))
        local texts = st.introText or { "..." }
        local text = texts[math.Clamp(math.floor(t / (secs / #texts)) + 1, 1, #texts)]
        local x = ScrW() / 2 + math.sin(now * 2) * 12
        local y = ScrH() * 0.45 + math.cos(now * 1.6) * 8
        local col = st.theme == "horse" and Color(200, 30, 30, a) or Rainbow(now * 0.15, a)
        draw.SimpleTextOutlined(text, "DermaLarge", x, y, col, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(0, 0, 0, a))
        return
    end
    if st.theme == "dance" then -- (a ring closing in on the big beat)
        local left, on = LC_CL.DanceBeat(st, now)
        if left then
            local r = math.floor(30 + left * 90)
            local cx, cy = ScrW() / 2, ScrH() * 0.62
            surface.SetDrawColor(255, 255, 255, on and 255 or 140)
            for i = 0, 35 do
                local a1, a2 = i / 36 * math.pi * 2, (i + 1) / 36 * math.pi * 2
                surface.DrawLine(cx + math.cos(a1) * r, cy + math.sin(a1) * r, cx + math.cos(a2) * r, cy + math.sin(a2) * r)
            end
            if on then draw.SimpleTextOutlined("JUMP!", "DermaLarge", cx, cy, Color(255, 120, 220), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(0, 0, 0, 220)) end
        end
    end
end)
