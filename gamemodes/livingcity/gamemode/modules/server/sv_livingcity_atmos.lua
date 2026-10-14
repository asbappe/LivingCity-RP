--[[
    Living City: the time of day, the weather, and the city's music

      Day and night   A day lasts lc_day_minutes (60) real minutes. The clock
                      is on everyone's HUD. Night (21:00 to 05:00) is dark: the
                      map's own lighting dims at dawn, day, dusk and night
                      (lc_daynight_light 1; it's a short hitch for clients when
                      it changes, four times a day), and screens are tinted.
                      Curfew is three times as likely at night and rations
                      half as likely.

      Weather         Clear, overcast, fog, rain or a storm, changing every so
                      often (lc_weather_auto 1). Rain and storms fall around you
                      outdoors, with the sound of it; storms bring thunder and
                      lightning; fog closes in. Being out in the rain with an
                      empty bottle or can fills it (still untreated).

      Music           The city's music, now and then (clients: lc_music 0/1,
                      lc_music_volume). Calm by day, tense under curfew or a
                      yellow sociostability, urgent in a fight or a red one.

      Admins: lc_time <hour>, lc_weather <clear|overcast|fog|rain|storm>,
      lc_weather auto. Everyone: !time.
]]

if CLIENT then return end

util.AddNetworkString("lc_lightstyle")

LC = LC or {}

local FLAGS = bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED)
local cvDay     = CreateConVar("lc_day_minutes", "60", FLAGS, "Real minutes in one city day")
local cvLight   = CreateConVar("lc_daynight_light", "1", FLAGS, "Dim the map's own lighting at night (clients reload lighting four times a day)")
local cvAuto    = CreateConVar("lc_weather_auto", "1", FLAGS, "The weather changes by itself")
local cvAtmos   = CreateConVar("lc_atmosphere", "1", FLAGS, "Day and night, and weather")

local cvDayNight = CreateConVar("lc_daynight", "-1", FLAGS,
    "Day and night on this map: 1 on, 0 off (a map that's always night, say), -1 decide from the map's sky")
local WEATHERS = { clear = 40, overcast = 25, fog = 10, rain = 18, storm = 7 }

-- A map built for night (its sky says so) has no day to dim from: the lighting
-- is left alone, the screen isn't tinted, and there's no overcast sky to see.
local NIGHT_SKIES = { "night", "borealis", "_09", "dark", "storm" }
function LC.DayNightOn()
    local v = cvDayNight:GetInt()
    if v == 0 then return false end
    if v == 1 then return true end
    local sky = string.lower(GetConVarString and GetConVarString("sv_skyname") or "")
    for _, k in ipairs(NIGHT_SKIES) do
        if string.find(sky, k, 1, true) then return false end
    end
    return true
end
LC.Weathers = WEATHERS

-- The clock --------------------------------------------------------------

local function DayLen() return math.max(5, cvDay:GetFloat()) * 60 end

function LC.SetHour(h)
    h = (tonumber(h) or 12) % 24
    SetGlobal2Float("lc_day_len", DayLen())
    SetGlobal2Float("lc_day_zero", CurTime() - h / 24 * DayLen())
end

function LC.Hour()
    local zero = GetGlobal2Float("lc_day_zero", 0)
    local len = GetGlobal2Float("lc_day_len", DayLen())
    return ((CurTime() - zero) / len * 24) % 24
end

function LC.DayPhase(h)
    h = h or LC.Hour()
    if h >= 21 or h < 5 then return "night" end
    if h < 7 then return "dawn" end
    if h < 19 then return "day" end
    return "dusk"
end

function LC.IsNight() return cvAtmos:GetBool() and LC.DayPhase() == "night" end

function LC.AtmosEventMul(name)
    if not LC.IsNight() then return 1 end
    if name == "curfew" then return 3 end
    if name == "rations" then return 0.5 end
    return 1
end

local LIGHT = { night = "d", dawn = "i", day = "m", dusk = "i" }
LC.AtmosPhase = LC.AtmosPhase or nil

local function ApplyLight(phase)
    if not cvLight:GetBool() or not cvAtmos:GetBool() or not LC.DayNightOn() then phase = "day" end
    local style = LIGHT[phase] or "m"
    -- a city-wide blackout (sv_livingcity_power.lua): whichever's darker
    local dark = LC.CityDark and LC.BlackoutStyle and LC.BlackoutStyle()
    if dark and dark < style then style = dark end
    if LC.EndingDark then style = "a" end -- (a secret ending turned every light out: sv_livingcity_endings.lua)
    if LC.LightStyle == style then return end
    LC.LightStyle = style
    if engine.LightStyle then engine.LightStyle(0, style) end
    net.Start("lc_lightstyle")
    net.WriteString(style)
    net.Broadcast()
end

-- The map's lighting as it should be right now (the hour, and the grid).
function LC.ApplyLightStyle() ApplyLight(LC.AtmosPhase or LC.DayPhase()) end

-- The weather ------------------------------------------------------------

LC.WeatherOverride = LC.WeatherOverride or nil

function LC.Weather() return GetGlobal2String("lc_weather", "clear") end

function LC.SetWeather(w, quiet)
    if not WEATHERS[w] then return false end
    local old = LC.Weather()
    SetGlobal2String("lc_weather", w)
    LC.NextWeather = CurTime() + math.random(8, 20) * 60
    if old ~= w and not quiet then
        local line = ({ rain = "It starts to rain.", storm = "A storm rolls in over the city.", fog = "Fog comes down over the streets.",
            overcast = "The sky clouds over.", clear = "The sky clears." })[w]
        for _, p in ipairs(player.GetAll()) do p:ChatPrint("** " .. line) end
    end
    hook.Run("LivingCityWeather", w, old)
    return true
end

local function PickWeather()
    local total = 0
    for _, n in pairs(WEATHERS) do total = total + n end
    local r = math.random() * total
    local night = not LC.DayNightOn()
    for w, n in pairs(WEATHERS) do
        r = r - n
        if r <= 0 then
            if night and w == "overcast" then return "fog" end -- nothing to cloud over on a night map
            return w
        end
    end
    return "clear"
end

-- Out in the rain, under the open sky?
function LC.InRain(ply)
    local w = LC.Weather()
    if w ~= "rain" and w ~= "storm" then return false end
    local tr = util.TraceLine({ start = ply:EyePos(), endpos = ply:EyePos() + Vector(0, 0, 4000), mask = MASK_SOLID_BRUSHONLY or MASK_OPAQUE })
    return not tr.Hit or tr.HitSky == true
end

timer.Create("LivingCityAtmos", 2, 0, function()
    if not cvAtmos:GetBool() then
        if LC.LightStyle and LC.LightStyle ~= "m" then ApplyLight("day") end
        return
    end
    if GetGlobal2Float("lc_day_zero", 0) == 0 then LC.SetHour(9) end
    SetGlobal2Bool("lc_daynight", LC.DayNightOn())
    SetGlobal2Float("lc_day_len", DayLen())
    local phase = LC.DayPhase()
    if phase ~= LC.AtmosPhase then
        local old = LC.AtmosPhase
        LC.AtmosPhase = phase
        ApplyLight(phase)
        if old then hook.Run("LivingCityDayPhase", phase, old) end
    end
    if cvAuto:GetBool() and CurTime() > (LC.NextWeather or 0) then
        LC.SetWeather(PickWeather(), LC.NextWeather == nil)
    end
end)

-- Rain fills an empty bottle or can held out to it.
timer.Create("LivingCityRainFill", 20, 0, function()
    for _, ply in ipairs(player.GetAll()) do
        if ply:Alive() and LC.InRain(ply) then
            for _, pair in ipairs({ { "bottle_empty", "bottle_dirty" }, { "can_empty", "can_dirty" } }) do
                if LC.HasItem(ply, pair[1]) then
                    LC.TakeItem(ply, pair[1], 1)
                    LC.GiveItem(ply, pair[2], 1)
                    ply:ChatPrint("[Living City] Rain fills your " .. (LCS.Items[pair[1]] and string.lower(LCS.Items[pair[1]].name) or pair[1]) .. ". Boil it before you drink it.")
                    break
                end
            end
        end
    end
end)

hook.Add("PlayerInitialSpawn", "LivingCityAtmos", function(ply)
    timer.Simple(3, function()
        if not IsValid(ply) or not LC.LightStyle then return end
        net.Start("lc_lightstyle") net.WriteString(LC.LightStyle) net.Send(ply)
    end)
end)

-- Commands ----------------------------------------------------------------

local function Clock(h)
    h = h or LC.Hour()
    return string.format("%02d:%02d", math.floor(h), math.floor((h % 1) * 60))
end
LC.ClockString = Clock

concommand.Add("lc_time", function(ply, _, args)
    if IsValid(ply) and not ply:IsAdmin() then return end
    local h = tonumber(args[1])
    if not h then
        local m = "It's " .. Clock() .. " (" .. LC.DayPhase() .. "). Usage: lc_time <hour 0-23>"
        if IsValid(ply) then ply:ChatPrint(m) else print(m) end
        return
    end
    LC.SetHour(h)
    local m = "The time is now " .. Clock() .. "."
    if IsValid(ply) then ply:ChatPrint(m) else print(m) end
end)

concommand.Add("lc_weather", function(ply, _, args)
    if IsValid(ply) and not ply:IsAdmin() then return end
    local w = string.lower(args[1] or "")
    local m
    if w == "auto" then
        RunConsoleCommand("lc_weather_auto", "1")
        LC.NextWeather = 0
        m = "The weather will change by itself."
    elseif WEATHERS[w] then
        RunConsoleCommand("lc_weather_auto", "0")
        LC.SetWeather(w)
        m = "Weather: " .. w .. " (lc_weather auto to let it change again)."
    else
        m = "Weather: clear, overcast, fog, rain, storm, or auto. Now: " .. LC.Weather()
    end
    if IsValid(ply) then ply:ChatPrint(m) else print(m) end
end)

hook.Add("PlayerSay", "LivingCityAtmosChat", function(ply, text)
    local t = string.lower(string.Trim(text or ""))
    if t ~= "!time" and t ~= "!weather" then return end
    ply:ChatPrint(string.format("It's %s, %s. The weather: %s.", Clock(), LC.DayPhase(), LC.Weather()))
    return ""
end)
