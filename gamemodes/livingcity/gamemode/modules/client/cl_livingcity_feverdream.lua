--[[
    Living City (client): the fever dream

    At midday a fever takes you (sv_livingcity_illness.lua): you're down on
    the ground for a minute, and this is what you see (the owner, 10 November:
    "a really trippy fever dream"). Only you see it; everyone else sees a
    sick person lying in the street.

      The world melts: colours cycle and bleed, everything smears and
      ripples, the view rolls and breathes in and out.
      The city talks to you: its own slogans and worries drift past, too big
      and too close, repeating, warped ("LABOR EARNS RATIONS", "did you
      register?", "the old man is waiting").
      A great eye opens in the middle of it all and watches.
      Sounds come slow and deep: your heart, voices asking questions, a
      scanner's shutter. A recording of your own in
      sound/livingcity/body/feverdream* plays instead, if there is one.
]]

LC_CL = LC_CL or {}

local WORDS = {
    "LABOR EARNS RATIONS", "did you register?", "DON'T RUN", "don't run", "don't run", "the old man is waiting",
    "your ration card is late", "SHE IS WATCHING YOU SLEEP", "count the headcrabs", "the water is singing",
    "papers. papers. papers.", "CURFEW IS ABSOLUTE", "who are you?", "you were brought here for your own protection",
    "the tap is dry", "it's too hot", "is anyone fighting back?", "YOUR COOPERATION IS NOTED", "wake up", "wake up",
}
local VOICES = { "male01", "female01" }

local function In(me) return IsValid(me) and LC and LC.InFeverDream and LC.InFeverDream(me) end

local drift = {}
local nextWord, nextSound, started, music = 0, 0, nil, nil

local function Music()
    if music == nil then
        local f = file.Find("sound/livingcity/body/feverdream*", "GAME") or {}
        music = #f > 0 and ("livingcity/body/" .. f[math.random(#f)]) or false
    end
    return music
end

hook.Add("Think", "LivingCityFeverDream", function()
    local me = LocalPlayer()
    if not In(me) then
        if started then
            started = nil
            drift = {}
            if music then me:StopSound(music) end
        end
        return
    end
    local now = CurTime()
    if not started then
        started = now
        local m = Music()
        if m then me:EmitSound(m, 75, 100, 0.7) end
    end
    if now > nextWord then
        nextWord = now + math.Rand(0.6, 1.6)
        drift[#drift + 1] = { text = WORDS[math.random(#WORDS)], x = math.Rand(0.05, 0.85), y = math.Rand(0.1, 0.9),
            vx = math.Rand(-0.04, 0.04), vy = math.Rand(-0.03, 0.03), born = now, life = math.Rand(3, 6), size = math.Rand(1, 3.5),
            hue = math.random(0, 360) }
        while #drift > 14 do table.remove(drift, 1) end
    end
    if not music and now > nextSound then
        nextSound = now + math.Rand(2, 4)
        local r = math.random(3)
        if r == 1 then me:EmitSound("player/heartbeat1.wav", 70, math.random(45, 60), 0.8)
        elseif r == 2 then me:EmitSound("vo/npc/" .. VOICES[math.random(2)] .. "/" .. string.format("question%02d", math.random(1, 20)) .. ".wav", 70, math.random(50, 75), 0.6)
        else me:EmitSound("npc/scanner/scanner_photo1.wav", 70, math.random(40, 60), 0.5) end
    end
end)

-- the world melts
hook.Add("RenderScreenspaceEffects", "LivingCityFeverDream", function()
    local me = LocalPlayer()
    if not In(me) then return end
    local t = CurTime() - (started or CurTime())
    local fade = math.Clamp(t / 4, 0, 1)
    if DrawColorModify then
        DrawColorModify({
            ["$pp_colour_addr"] = 0.12 * math.sin(t * 0.9) * fade, ["$pp_colour_addg"] = 0.10 * math.sin(t * 1.3 + 2) * fade,
            ["$pp_colour_addb"] = 0.14 * math.sin(t * 0.7 + 4) * fade, ["$pp_colour_brightness"] = 0.02,
            ["$pp_colour_contrast"] = 1 + 0.5 * fade, ["$pp_colour_colour"] = 1 + 1.8 * fade * (0.6 + 0.4 * math.sin(t * 0.5)),
            ["$pp_colour_mulr"] = 2 * math.sin(t * 0.4) * fade, ["$pp_colour_mulg"] = 0, ["$pp_colour_mulb"] = 2 * math.cos(t * 0.3) * fade,
        })
    end
    if DrawMotionBlur then DrawMotionBlur(0.08, 0.85 * fade, 0.02) end
    if DrawMaterialOverlay then DrawMaterialOverlay("effects/water_warp01", 0.08 + 0.06 * math.sin(t * 1.7)) end
    if DrawSharpen then DrawSharpen(1.2 * fade, 1.5) end
end)

-- the view rolls and breathes
hook.Add("CalcView", "LivingCityFeverDream", function(ply, origin, angles, fov)
    if not In(ply) then return end
    local t = CurTime() - (started or CurTime())
    local fade = math.Clamp(t / 4, 0, 1)
    local a = Angle(angles.p + 8 * math.sin(t * 0.6) * fade, angles.y + 20 * math.sin(t * 0.25) * fade, 25 * math.sin(t * 0.45) * fade)
    return { origin = origin, angles = a, fov = fov + 35 * math.sin(t * 0.8) * fade, drawviewer = false }
end)

-- the city talks to you, and the eye watches
hook.Add("HUDPaint", "LivingCityFeverDream", function()
    local me = LocalPlayer()
    if not In(me) then return end
    local now = CurTime()
    local t = now - (started or now)
    local w, h = ScrW(), ScrH()
    -- the eye
    local r = math.min(w, h) * (0.12 + 0.03 * math.sin(t * 1.1))
    local open = math.Clamp(math.sin(t * 0.35) * 1.4, 0.05, 1)
    local cx, cy = w / 2 + 30 * math.sin(t * 0.7), h / 2 + 20 * math.cos(t * 0.5)
    surface.SetDrawColor(255, 240, 200, math.floor(40 * open))
    draw.NoTexture()
    for i = 0, 2 do
        local rr = r * (1 + i * 0.35)
        local seg = {}
        for k = 0, 40 do
            local ang = k / 40 * math.pi * 2
            seg[#seg + 1] = { x = cx + math.cos(ang) * rr, y = cy + math.sin(ang) * rr * open }
        end
        surface.SetDrawColor(255, 200 - i * 50, 120 + i * 40, math.floor((60 - i * 15) * open))
        surface.DrawPoly(seg)
    end
    surface.SetDrawColor(20, 10, 30, math.floor(200 * open))
    local pupil = {}
    for k = 0, 30 do
        local ang = k / 30 * math.pi * 2
        pupil[#pupil + 1] = { x = cx + math.cos(ang) * r * 0.35, y = cy + math.sin(ang) * r * 0.35 * open }
    end
    surface.DrawPoly(pupil)
    -- the words
    for _, d in ipairs(drift) do
        local age = (now - d.born) / d.life
        if age < 1 then
            local alpha = math.floor(255 * math.sin(age * math.pi))
            local c = HSVToColor and HSVToColor((d.hue + t * 60) % 360, 0.7, 1) or Color(255, 220, 180)
            local x = (d.x + d.vx * (now - d.born)) * w
            local y = (d.y + d.vy * (now - d.born)) * h + 10 * math.sin(now * 3 + d.hue)
            local font = d.size > 2.5 and "DermaLarge" or (d.size > 1.6 and "Trebuchet24" or "DermaDefaultBold")
            draw.SimpleText(d.text, font, x + 3, y + 3, Color(0, 0, 0, math.floor(alpha * 0.6)), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            draw.SimpleText(d.text, font, x, y, Color(c.r, c.g, c.b, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
    end
end)
