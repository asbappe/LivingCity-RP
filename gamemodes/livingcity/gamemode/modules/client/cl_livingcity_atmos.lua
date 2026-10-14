--[[
    Living City (client): the clock, night, the weather you can see and hear,
    and the city's music.
      lc_music 0/1, lc_music_volume (0.35), lc_weather_effects 0/1, lc_night_tint 0/1
]]

LC_CL = LC_CL or {}

local cvMusic   = CreateClientConVar("lc_music", "1", true, false, "The city's music, now and then")
local cvVolume  = CreateClientConVar("lc_music_volume", "0.35", true, false, "How loud the city's music is (0 to 1)")
-- the music sits 20% under the setting (the city's tracks are mastered loud)
local MUSIC_SCALE = 0.8
local function MusicVolume() return math.Clamp(cvVolume:GetFloat(), 0, 1) * MUSIC_SCALE end
local cvEffects = CreateClientConVar("lc_weather_effects", "1", true, false, "Rain, fog and lightning you can see")
local cvTint    = CreateClientConVar("lc_night_tint", "1", true, false, "Darken the screen a little at night")

------------------------------------------------------------------------
-- The clock
------------------------------------------------------------------------

function LC_CL.Hour()
    local zero = GetGlobal2Float("lc_day_zero", 0)
    local len = GetGlobal2Float("lc_day_len", 3600)
    if zero == 0 then return nil end
    return ((CurTime() - zero) / math.max(1, len) * 24) % 24
end

local function Phase(h)
    if not h then return "day" end
    if h >= 21 or h < 5 then return "night" end
    if h < 7 then return "dawn" end
    if h < 19 then return "day" end
    return "dusk"
end
LC_CL.DayPhase = Phase

-- How dark it is, 0 (noon) to 1 (the middle of the night), easing through dawn and dusk.
local function Darkness(h)
    if not h then return 0 end
    if h >= 21 or h < 5 then return 1 end
    if h < 7 then return 1 - (h - 5) / 2 end
    if h >= 19 then return (h - 19) / 2 end
    return 0
end
LC_CL.Darkness = Darkness

-- The map's lighting, when the server changes it (night, and city-wide blackouts)
net.Receive("lc_lightstyle", function()
    local style = net.ReadString()
    if LC_CL.lightStyle == style then return end
    LC_CL.lightStyle = style
    if render and render.RedownloadAllLightmaps then render.RedownloadAllLightmaps(true, true) end
end)

local WEATHER_NAMES = { clear = "Clear", overcast = "Overcast", fog = "Fog", rain = "Rain", storm = "Storm" }
-- what the city is doing at this hour (sv_livingcity_rhythm.lua)
local function DayPart(h)
    if not GetGlobal2Bool("lc_rhythm_on", true) then return nil end
    if h >= 21 or h < 5 then return "night: the streets are quiet" end
    if h < 7 then return "morning: off to work" end
    if h < 12 then return "the work day" end
    if h < 14 then return "midday: ration lines" end
    if h < 18 then return "afternoon" end
    return "evening"
end
local CLOCK_BG, CLOCK_INK, CLOCK_DIM = Color(10, 12, 16, 160), Color(230, 230, 225), Color(160, 165, 175)
local STOCK_LOW, STOCK_EMPTY = Color(230, 190, 110), Color(240, 110, 90)

hook.Add("HUDPaint", "LivingCityClock", function()
    local h = LC_CL.Hour()
    if not h then return end
    local w = ScrW()
    local text = string.format("%02d:%02d", math.floor(h), math.floor((h % 1) * 60))
    local weather = WEATHER_NAMES[GetGlobal2String("lc_weather", "clear")] or ""
    draw.RoundedBox(4, w - 150, 12, 136, 24, CLOCK_BG)
    draw.SimpleText(text, "DermaDefaultBold", w - 140, 24, CLOCK_INK, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    draw.SimpleText(weather, "DermaDefault", w - 22, 24, CLOCK_DIM, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
    local part = DayPart(h)
    if part then draw.SimpleText(part, "DermaDefault", w - 14, 44, CLOCK_DIM, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER) end
    -- the city's ration stores (sv_livingcity_stockpile.lua)
    if GetGlobal2Bool("lc_stock_on", false) then
        local frac = GetGlobal2Int("lc_stock", 0) / math.max(1, GetGlobal2Int("lc_stock_max", 400))
        local col = frac <= 0 and STOCK_EMPTY or frac < 0.25 and STOCK_LOW or CLOCK_DIM
        draw.SimpleText(string.format("ration stores %d%%%s", math.floor(frac * 100), frac <= 0 and ": empty" or frac < 0.25 and ": low" or ""),
            "DermaDefault", w - 14, part and 60 or 44, col, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
    end
end)

-- A little darker at night, whatever the map's lighting does
hook.Add("HUDPaintBackground", "LivingCityNight", function()
    if not cvTint:GetBool() then return end
    local d = GetGlobal2Bool("lc_daynight", true) and Darkness(LC_CL.Hour()) or 0 -- a night map is dark already
    local storm = GetGlobal2String("lc_weather", "clear") == "storm" and 0.25 or 0
    local a = math.Clamp(d * 70 + storm * 60, 0, 90)
    if a <= 0 then return end
    surface.SetDrawColor(5, 10, 25, a)
    surface.DrawRect(0, 0, ScrW(), ScrH())
end)

------------------------------------------------------------------------
-- Weather you can see
------------------------------------------------------------------------

local FOG = { fog = { 120, 900, 0.85 }, storm = { 200, 2200, 0.65 }, rain = { 300, 3200, 0.5 }, overcast = { 1000, 8000, 0.25 } }
-- Rain and storms only fog the air you're standing out in: under a roof it
-- clears, and it closes back in as you step out (outFog, eased each frame).
local RAIN_FOG = { rain = true, storm = true }
local outFog = 0
local fogCol = { 130, 135, 140 }

-- The infestation's haze (cl_livingcity_infest.lua): close, thick and a dark,
-- dirty yellow, the deeper in you are. start, end, max density, colour.
local HAZE = { 0, 800, 0.88, 105, 95, 25 }

local function ApplyFog(scale)
    local w = GetGlobal2String("lc_weather", "clear")
    local f = cvEffects:GetBool() and FOG[w] or nil
    if f and RAIN_FOG[w] then
        if outFog <= 0.01 then f = nil
        else f = { Lerp(outFog, 6000, f[1]), Lerp(outFog, 20000, f[2]), f[3] * outFog } end
    end
    local haze = LC_CL.InfestHaze or 0
    if not f and haze <= 0.01 then return end
    local dark = 1 - Darkness(LC_CL.Hour()) * 0.8
    dark = Lerp(haze * 0.35, dark, 1) -- (the haze still shows at night, but isn't lit up)
    local s, e, d = 6000, 20000, 0
    local r, g, b = fogCol[1], fogCol[2], fogCol[3]
    if f then s, e, d = f[1], f[2], f[3] end
    if haze > 0.01 then
        -- how far you can see shrinks by the same share at each step in
        -- (a straight line from 20000 to 800 would only close in at the very end)
        s, e = Lerp(haze, s, HAZE[1]), e * (HAZE[2] / e) ^ haze
        d = math.max(d, HAZE[3] * math.min(1, haze * 1.4))
        r, g, b = Lerp(haze, r, HAZE[4]), Lerp(haze, g, HAZE[5]), Lerp(haze, b, HAZE[6])
    end
    render.FogMode(MATERIAL_FOG_LINEAR)
    render.FogStart(s * (scale or 1))
    render.FogEnd(e * (scale or 1))
    render.FogMaxDensity(d)
    render.FogColor(r * dark, g * dark, b * dark)
    return true
end
hook.Add("SetupWorldFog", "LivingCityWeather", function() return ApplyFog(1) end)
hook.Add("SetupSkyboxFog", "LivingCityWeather", function(scale) return ApplyFog(scale) end)

-- Rain: streaks falling around you, when there's open sky above you.
local drops = {}
local outdoors, nextRoof = false, 0
local rainSound, thunderAt, flashUntil = nil, 0, 0

local function Exists(path) return file and file.Exists and file.Exists("sound/" .. path, "GAME") end
local function First(list) for _, p in ipairs(list) do if Exists(p) then return p end end return nil end
local RAIN_LOOPS = { "ambient/weather/rumble_rain.wav", "ambient/water/water_flow_loop1.wav", "ambient/levels/canals/drip_loop.wav" }
local THUNDER = { "ambient/atmosphere/thunder1.wav", "ambient/atmosphere/thunder2.wav", "ambient/atmosphere/thunder3.wav", "ambient/atmosphere/thunder4.wav" }

hook.Add("Think", "LivingCityRain", function()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end
    local w = GetGlobal2String("lc_weather", "clear")
    local raining = (w == "rain" or w == "storm") and cvEffects:GetBool()
    if CurTime() > nextRoof then
        nextRoof = CurTime() + 0.5
        local tr = util.TraceLine({ start = ply:EyePos(), endpos = ply:EyePos() + Vector(0, 0, 4000), mask = MASK_SOLID_BRUSHONLY })
        outdoors = not tr.Hit or tr.HitSky == true
    end
    outFog = math.Approach(outFog, (outdoors and raining) and 1 or 0, FrameTime() * 0.6) -- (about two seconds in or out)
    -- the sound of it
    if raining then
        if not rainSound then
            local p = First(RAIN_LOOPS)
            if p then rainSound = CreateSound(ply, p) if rainSound then rainSound:PlayEx(0.1, 100) end end
        end
        if rainSound then rainSound:ChangeVolume(outdoors and (w == "storm" and 0.6 or 0.4) or 0.12, 1) end
    elseif rainSound then
        rainSound:FadeOut(2)
        rainSound = nil
    end
    -- thunder and lightning
    if w == "storm" and cvEffects:GetBool() and CurTime() > thunderAt then
        thunderAt = CurTime() + (GetGlobal2Bool("lc_storm_max", false) and math.random(4, 10) or math.random(12, 35)) -- (the worst storm: a secret ending)
        flashUntil = CurTime() + 0.25
        local p = First(THUNDER)
        if p then timer.Simple(math.Rand(0.4, 2.5), function() surface.PlaySound(p) end) end
    end
end)

local RAIN_TOP, RAIN_BOT, RAIN_COL = Vector(), Vector(), Color(205, 220, 240, 85) -- (pale blue-white)
hook.Add("PostDrawTranslucentRenderables", "LivingCityRain", function(depth, sky)
    if sky or depth then return end
    local w = GetGlobal2String("lc_weather", "clear")
    if (w ~= "rain" and w ~= "storm") or not outdoors or not cvEffects:GetBool() then return end
    local ply = LocalPlayer()
    if not IsValid(ply) then return end
    local origin = ply:EyePos()
    local n = w == "storm" and (GetGlobal2Bool("lc_storm_max", false) and 2800 or 1760) or 1120 -- (twice as many as they were, half as thick; more still in the worst storm)
    local now = CurTime()
    render.SetColorMaterial() -- (plain colour: a texture would tint it)
    -- the same few hundred drops recycled, and the same two vectors moved about:
    -- nothing new made each frame
    local ox, oy, oz = origin.x, origin.y, origin.z
    for i = 1, n do
        local d = drops[i]
        if not d then d = {} drops[i] = d end
        if now > (d.dieAt or 0) then
            d.x, d.y, d.z, d.born, d.speed = math.Rand(-500, 500), math.Rand(-500, 500), math.Rand(150, 400), now, math.Rand(900, 1300)
            d.dieAt = now + d.z / d.speed + 0.2
        end
        local tz = oz + d.z - (now - d.born) * d.speed
        RAIN_TOP.x, RAIN_TOP.y, RAIN_TOP.z = ox + d.x, oy + d.y, tz
        RAIN_BOT.x, RAIN_BOT.y, RAIN_BOT.z = ox + d.x - 2, oy + d.y - 1, tz - 17
        render.DrawBeam(RAIN_TOP, RAIN_BOT, 0.3, 0, 1, RAIN_COL)
    end
end)

-- the flash only under open sky, where the rain is (indoors you just hear the thunder)
hook.Add("HUDPaint", "LivingCityLightning", function()
    if CurTime() < flashUntil and outdoors then
        surface.SetDrawColor(220, 230, 255, 90 * (flashUntil - CurTime()) / 0.25)
        surface.DrawRect(0, 0, ScrW(), ScrH())
    end
end)

------------------------------------------------------------------------
-- Music
------------------------------------------------------------------------

local TRACKS = {
    calm = { "music/hl2_song19.mp3", "music/hl2_song10.mp3", "music/hl2_song2.mp3", "music/hl2_song26.mp3", "music/hl2_song27_trainstation2.mp3" },
    tense = { "music/hl2_song13.mp3", "music/hl2_song26_trainstation1.mp3", "music/hl2_song30.mp3", "music/hl2_song33.mp3" },
    urgent = { "music/hl2_song3.mp3", "music/hl2_song4.mp3", "music/hl2_song29.mp3", "music/hl2_song16.mp3" },
}
local playing, playingMood, nextTrack = nil, nil, 100

local function Mood()
    local socio = GetGlobal2String("lc_socio", "green")
    local event = GetGlobal2String("lc_event", "")
    local ply = LocalPlayer()
    if socio == "red" or (IsValid(ply) and ply:GetNW2Float("lc_wanted_until", 0) > CurTime()) then return "urgent" end
    if event == "lockdown" then return "urgent" end
    if socio == "yellow" or event == "curfew" or Phase(LC_CL.Hour()) == "night" then return "tense" end
    return "calm"
end
LC_CL.MusicMood = Mood

-- A sound channel isn't an ordinary entity: the global IsValid indexes it and
-- errors on some builds (the error that started with the music). Ask it directly.
local function Live(ch)
    if ch == nil then return false end
    local ok = pcall(function() return ch:GetState() end)
    return ok
end

local function Stop(fade)
    if Live(playing) then
        local ch = playing
        if fade then
            local v = ch:GetVolume()
            for i = 1, 10 do timer.Simple(i * 0.2, function() if Live(ch) then ch:SetVolume(v * (1 - i / 10)) if i == 10 then ch:Stop() end end end) end
        else
            ch:Stop()
        end
    end
    playing, playingMood = nil, nil
end

local fadingUntil = 0 -- (a sound channel can't carry fields of its own: the fade-in is tracked here)

local function PlayMood(mood)
    local options = {}
    for _, p in ipairs(TRACKS[mood] or {}) do if Exists(p) then options[#options + 1] = p end end
    if #options == 0 or not sound.PlayFile then return end
    local path = options[math.random(#options)]
    sound.PlayFile("sound/" .. path, "noplay", function(ch)
        if not Live(ch) then return end
        Stop(false)
        playing, playingMood = ch, mood
        -- every piece fades in over a few seconds rather than starting at full blast
        ch:SetVolume(0)
        ch:Play()
        local FADE = 4
        fadingUntil = CurTime() + FADE + 0.2
        for i = 1, 20 do
            timer.Simple(i * FADE / 20, function()
                if not Live(ch) or playing ~= ch then return end
                ch:SetVolume(MusicVolume() * i / 20)
            end)
        end
    end)
end

local lastEvent = ""
local lastMood = nil
timer.Create("LivingCityMusic", 1, 0, function()
    if not cvMusic:GetBool() then if playing then Stop(true) end return end
    -- a lockdown starts with its music, straight away: no waiting for the next piece
    local event = GetGlobal2String("lc_event", "")
    if event ~= lastEvent then
        lastEvent = event
        if event == "lockdown" then
            if Live(playing) then Stop(true) end
            timer.Simple(1.5, function() if cvMusic:GetBool() then PlayMood("urgent") end end)
            nextTrack = CurTime() + 60
            return
        end
    end
    local mood = Mood()
    if Live(playing) then
        if CurTime() > fadingUntil then playing:SetVolume(MusicVolume()) end
        -- the mood changed a lot: let this one go
        -- (the urgent music comes in about five seconds after things turn: an alarm, a chase)
        if playingMood ~= mood and (mood == "urgent" or playingMood == "urgent") then Stop(true) nextTrack = CurTime() + 5 end
        if Live(playing) and playing:GetState() == GMOD_CHANNEL_STOPPED then
            playing, playingMood = nil, nil
            nextTrack = CurTime() + math.random(306, 714) -- quiet for a while between pieces (5 to 12 minutes)
        end
        return
    end
    -- nothing playing and things just turned urgent: give it about five seconds
    if mood == "urgent" and lastMood ~= "urgent" then nextTrack = math.min(nextTrack, CurTime() + 5) end
    lastMood = mood
    if CurTime() >= nextTrack then
        nextTrack = CurTime() + 30
        PlayMood(mood)
    end
end)
