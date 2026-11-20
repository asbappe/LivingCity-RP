--[[
    Living City: the map's own lights, by the hour and by the dream

    The owner, 20 November: "can we have you hook into the lights in the map so we can
    shut off and alter the lights on the big dream zone cube area??? Also is it possible
    to alter the sun's light dynamically or at intervals to create a day/night cycle?
    And I won't take no for an answer", and "I really want the infested quarter to be
    darker and not sunny and even the southern half of the ring should be a bit dimmer".

    What the engine allows, and so what this does:

      The sun        A map's sun (its light_environment) can be faded while the map runs
                     only if the mapper gave it a name: then the engine keeps it, and it
                     takes FadeToPattern like any named light. The merged map names it
                     lc_sun (_dev/tools/map_merge.py). Where it has a name, the sun is
                     faded by the hour, a step at a time through dawn and dusk, with no
                     reloading of the map's lighting on anyone's screen, and the lamps
                     indoors stay as they are. Where it has none (the map as it was),
                     nothing here touches it: sv_livingcity_atmos.lua goes on dimming
                     every light of the map in four steps, as before.
      The sky        The owner's map draws its sky with GMod's painted sky (env_skypaint),
                     set in the map to black with the stock star picture at every hour;
                     nothing in the gamemode had touched it (the owner, 20 November: "I
                     have only seen a dark starry night for the skybox in game", and of
                     its stars, "looks like a toddler drew some stars"). So the whole day
                     is painted here: an overcast grey-blue by day (the city's own light
                     is dim), a glow on the horizon at dawn and dusk, near black by
                     night, a pale sun that rises and sets. The stock star picture is
                     switched off and every client draws finer stars of its own
                     (cl_livingcity_daylight.lua). With day and night switched off in
                     the settings the sky is the map's own again. The sun's glow
                     (env_sun) goes out at night.
      The dream room Every named light in or round the dream zone (the owner's four are
                     named evr_l) is the dream's to set: on, dim, dark, off, flickering,
                     or red where the map has the red set (lc_dream_red: the merged map
                     adds one beside each). A nightmare dims the room (red, with the red
                     set); the dream where every light goes out puts them out; they come
                     back on as the dream ends. Staff: F4 > Admin testing tools, "Lights".
      Darker places  A light's colour and the sun's strength are fixed when the map is
                     compiled, and one sun lights everything under a sky alike. So the
                     infested quarter is kept out of the sun in the map itself (a sheet
                     the light compiler stops at, and its own dim lights, lc_raven_gloom,
                     which follow the hour here), and both it and the ring's southern
                     half are also darkened on the screen of whoever stands there: marks
                     in the map named lc_mood_dark and lc_mood_dim, sent to every client
                     (cl_livingcity_daylight.lua).

    Nothing here needs a setting: it follows lc_atmosphere, lc_daynight and
    lc_daynight_light (sv_livingcity_atmos.lua). The numbers are in LC.Daylight.
]]

if CLIENT then return end

util.AddNetworkString("lc_moods")

LC = LC or {}
LC.Daylight = LC.Daylight or {}
local D = LC.Daylight

D.DAWN, D.DAY, D.DUSK, D.NIGHT = 5, 7, 19, 21     -- the hours the light turns at (as LC.DayPhase's)
D.STEPS = 12              -- the sun's steps from out ("a") to full ("m")
D.GLOOM_NIGHT = 4         -- the quarter's own lights at night, in the same steps ("e")
D.DREAM_REACH = 1200      -- how far outside the dream zone a named light still counts as the room's
-- The painted sky: straight up and at the horizon, by day and by night; the glow at dawn and dusk; the sun in it.
D.SKY = {
    day = { top = Vector(0.20, 0.26, 0.34), bottom = Vector(0.50, 0.55, 0.60) },
    night = { top = Vector(0.0, 0.0, 0.01), bottom = Vector(0.01, 0.015, 0.03) },
}
D.DUSK_COLOR = Vector(1.0, 0.45, 0.15)
D.SUN_COLOR, D.SUN_SIZE = Vector(0.6, 0.55, 0.45), 1.0
D.SUN_YAW, D.SUN_HIGH = 329, 70                  -- where the map's own sun stands at noon (its light_environment: angles 0 149 0, pitch -70)

-- What a dream may ask of the room's lights: the white ones' pattern (false: off) and the red set's.
D.MODES = {
    on = { white = "m", red = false },
    dim = { white = "e", red = false },
    dark = { white = "b", red = false },
    off = { white = false, red = false },
    flicker = { white = "mmamammmmammamamaaamammma", red = false },
    red = { white = false, red = "m" },
    redpulse = { white = false, red = "ccdefghijklmmlkjihgfedcc" },
}
-- A dream's own choice (by its id), else by its mood. "nightmare" is "red" where the map has the red set.
D.DREAM_MODE = { harpies = "off" }
D.MOOD_MODE = { happy = "on", neutral = "on", nightmare = "dim" }

------------------------------------------------------------------------
-- The hour
------------------------------------------------------------------------

-- How much of the day's light there is at this hour: 0 by night, 1 by day, rising through dawn, falling through dusk.
function D.Light(h)
    h = (h or (LC.Hour and LC.Hour()) or 12) % 24
    if h < D.DAWN or h >= D.NIGHT then return 0 end
    if h < D.DAY then return (h - D.DAWN) / (D.DAY - D.DAWN) end
    if h < D.DUSK then return 1 end
    return 1 - (h - D.DUSK) / (D.NIGHT - D.DUSK)
end

local function Letter(steps) return string.char(97 + math.Clamp(math.floor(steps + 0.5), 0, 25)) end
function D.SunLetter(h) return Letter(D.Light(h) * D.STEPS) end
function D.GloomLetter(h) return Letter(D.GLOOM_NIGHT + D.Light(h) * (D.STEPS - D.GLOOM_NIGHT)) end

local function Cycling()
    local cvA, cvL = GetConVar("lc_atmosphere"), GetConVar("lc_daynight_light")
    if cvA and not cvA:GetBool() then return false end
    if cvL and not cvL:GetBool() then return false end
    return not LC.DayNightOn or LC.DayNightOn()
end

------------------------------------------------------------------------
-- The sun, and the quarter's own lights
------------------------------------------------------------------------

-- The map's sun, if it can be faded (the engine keeps a light_environment only when it has a name).
function D.Sun()
    if IsValid(D.sun) then return D.sun end
    D.sun = ents.FindByClass("light_environment")[1]
    return IsValid(D.sun) and D.sun or nil
end
-- Is the sun ours to fade? Then the map's other lights are left alone at night (sv_livingcity_atmos.lua).
function D.SunHooked() return D.Sun() ~= nil and Cycling() end

local function Fade(list, letter, key)
    if D[key] == letter then return end
    D[key] = letter
    for _, e in ipairs(list) do
        if IsValid(e) then e:Fire("FadeToPattern", letter) end
    end
end

------------------------------------------------------------------------
-- The painted sky
------------------------------------------------------------------------

local function Sky()
    if IsValid(D.sky) then return D.sky end
    D.sky = ents.FindByClass("env_skypaint")[1]
    return IsValid(D.sky) and D.sky or nil
end

local function Mix(a, b, f) return a + (b - a) * f end

-- The sky as the map has it: read once, before anything here changes it, and put back when day and night are off.
local OWN = { "TopColor", "BottomColor", "SunSize", "SunColor", "SunNormal", "DuskScale", "DuskIntensity", "DuskColor", "DrawStars" }
local function SkyAsSet(sky)
    if D.skyOwn and D.skyOwn.of == sky then return D.skyOwn end
    if not sky.GetTopColor then return nil end
    local own = { of = sky }
    for _, k in ipairs(OWN) do own[k] = sky["Get" .. k](sky) end
    D.skyOwn = own
    return own
end

-- Where the sun stands in the sky at this hour: up from the east of its noon place, down to the west of it.
function D.SunNormal(h)
    h = (h or 12) % 24
    local high = math.rad(D.SUN_HIGH * math.max(-0.15, math.sin(math.pi * (h - 6) / 12)))
    local yaw = math.rad(D.SUN_YAW + (h - 12) * 8)
    return Vector(math.cos(high) * math.cos(yaw), math.cos(high) * math.sin(yaw), math.sin(high))
end

-- Paint the sky for this much of the day's light at this hour. f nil: day and night are off, the map's own sky again.
function D.PaintSky(f, h)
    local sky = Sky()
    local own = sky and SkyAsSet(sky)
    if not own then return false end
    if f == nil then
        if D.skyKey ~= "own" then
            D.skyKey = "own"
            for _, k in ipairs(OWN) do sky["Set" .. k](sky, own[k]) end
            SetGlobal2Bool("lc_sky_stars", false)
        end
        return true
    end
    f = math.Clamp(f, 0, 1)
    local key = math.floor(f * 48 + 0.5) .. ":" .. math.floor((h or 12) * 4)
    if D.skyKey == key then return true end
    D.skyKey = key
    local day, night = D.SKY.day, D.SKY.night
    sky:SetTopColor(Mix(night.top, day.top, f))
    sky:SetBottomColor(Mix(night.bottom, day.bottom, f))
    -- the glow on the horizon: none by night or by day, most halfway through dawn and dusk
    sky:SetDuskColor(D.DUSK_COLOR)
    sky:SetDuskScale(0.6)
    sky:SetDuskIntensity(1.1 * (1 - math.abs(f * 2 - 1)))
    sky:SetSunColor(D.SUN_COLOR)
    sky:SetSunSize(D.SUN_SIZE * f)
    sky:SetSunNormal(D.SunNormal(h))
    -- (the stock star picture stays off: each client draws its own stars, as the light goes)
    sky:SetDrawStars(false)
    SetGlobal2Bool("lc_sky_stars", true)
    return true
end

------------------------------------------------------------------------
-- The dream room's lights
------------------------------------------------------------------------

local function InReach(pos, zone)
    if not zone then return false end
    local r = D.DREAM_REACH
    if zone.box then
        return pos.x > zone.box.mins.x - r and pos.x < zone.box.maxs.x + r and pos.y > zone.box.mins.y - r and pos.y < zone.box.maxs.y + r
    end
    local reach = (zone.r or 0) + r
    return zone.pos ~= nil and (pos.x - zone.pos.x) ^ 2 + (pos.y - zone.pos.y) ^ 2 < reach * reach
end

-- The room's lights: white (every named light in or round the dream zone, and any named lc_dream_light) and red (lc_dream_red).
function D.DreamLights(zone)
    zone = zone or (LC.DreamZone and LC.DreamZone()) or nil
    if not zone and LC.DreamPoint and LC.DreamPoint() then zone = { pos = LC.DreamPoint().pos, r = 1500 } end
    local white, red, seen = {}, {}, {}
    local function Take(e)
        if not IsValid(e) or seen[e] then return end
        seen[e] = true
        local name = e:GetName()
        if name == "lc_dream_red" then red[#red + 1] = e
        elseif name == "lc_dream_light" or InReach(e:GetPos(), zone) then
            if name ~= "lc_raven_gloom" and e:GetClass() ~= "light_environment" then white[#white + 1] = e end
        end
    end
    for _, cls in ipairs({ "light", "light_spot" }) do
        for _, e in ipairs(ents.FindByClass(cls)) do Take(e) end
    end
    return white, red
end

local function Set(list, pattern)
    for _, e in ipairs(list) do
        if pattern then
            e:Fire("TurnOn")
            e:Fire("SetPattern", pattern)
        else
            e:Fire("TurnOff")
        end
    end
end

-- Put the room's lights in a mode (D.MODES). Returns how many white and red lights it reached, or false and why.
function D.SetDreamLights(mode, zone)
    local m = D.MODES[mode]
    if not m then return false, "No such mode." end
    local white, red = D.DreamLights(zone)
    if #white + #red == 0 then return false, "This map has no named lights in or round the dream zone." end
    if m.red and #red == 0 then
        -- (no red set in this map: the nearest thing, the room dimmed)
        m = D.MODES.dim
    end
    Set(white, m.white)
    Set(red, m.red)
    D.dreamMode = mode
    return #white, #red
end

function D.ModeFor(dream)
    local id = dream and dream.id
    if id and D.DREAM_MODE[id] then return D.DREAM_MODE[id] end
    local mood = id and LC.DreamMood and LC.DreamMood(id) or "neutral"
    local mode = D.MOOD_MODE[mood] or "on"
    if mood == "nightmare" then
        local _, red = D.DreamLights(dream and dream.zone)
        if #red > 0 then mode = "red" end
    end
    return mode
end

hook.Add("LivingCityDreamStarted", "LivingCityDaylight", function(dream)
    local ok, err = LC.Try(D.SetDreamLights, D.ModeFor(dream), dream and dream.zone)
    if not ok and LC.Error then LC.Error("dream lights", err) end
end)
hook.Add("LivingCityDreamEnded", "LivingCityDaylight", function(dream)
    local ok, err = LC.Try(D.SetDreamLights, "on", dream and dream.zone)
    if not ok and LC.Error then LC.Error("dream lights", err) end
end)

------------------------------------------------------------------------
-- Darker places: the map's marks, for every client
------------------------------------------------------------------------

function D.Moods()
    local out = {}
    for kind, name in pairs({ dark = "lc_mood_dark", dim = "lc_mood_dim" }) do
        for _, e in ipairs(ents.FindByName and ents.FindByName(name) or {}) do
            local p = e:GetPos()
            out[#out + 1] = { k = kind, x = math.floor(p.x), y = math.floor(p.y), z = math.floor(p.z) }
        end
    end
    return out
end

local function SendMoods(ply)
    local list = D.Moods()
    net.Start("lc_moods")
    net.WriteUInt(math.min(#list, 255), 8)
    for i = 1, math.min(#list, 255) do
        local m = list[i]
        net.WriteBool(m.k == "dark")
        net.WriteVector(Vector(m.x, m.y, m.z))
    end
    if ply then net.Send(ply) else net.Broadcast() end
end
D.SendMoods = SendMoods

hook.Add("PlayerInitialSpawn", "LivingCityDaylight", function(ply)
    timer.Simple(4, function() if IsValid(ply) then SendMoods(ply) end end)
end)

------------------------------------------------------------------------
-- Keeping time
------------------------------------------------------------------------

function D.Tick()
    local cycling = Cycling()
    local f = cycling and D.Light() or 1
    local sun = D.Sun()
    if sun then Fade({ sun }, Letter(f * D.STEPS), "sunLetter") end
    local gloom = ents.FindByName and ents.FindByName("lc_raven_gloom") or {}
    if #gloom > 0 then Fade(gloom, Letter(D.GLOOM_NIGHT + f * (D.STEPS - D.GLOOM_NIGHT)), "gloomLetter") end
    D.PaintSky(cycling and f or nil, LC.Hour and LC.Hour() or 12)
    -- the sun's glow in the sky
    local on = f > 0.05
    if D.sunGlow ~= on then
        D.sunGlow = on
        for _, e in ipairs(ents.FindByClass("env_sun")) do e:Fire(on and "TurnOn" or "TurnOff") end
    end
end

timer.Create("LivingCityDaylight", 5, 0, function()
    local ok, err = LC.Try(D.Tick)
    if not ok and LC.Error then LC.Error("daylight", err) end
end)

-- What this map gives it to work with, in plain words (F4 > Admin testing tools > Lights: what this map has).
function D.Report()
    local out = {}
    local sun = D.Sun()
    out[#out + 1] = sun and ("Sun: named (" .. tostring(sun:GetName()) .. "), faded by the hour.")
        or "Sun: no name in this map, so it cannot be faded: the old four steps dim every light instead."
    out[#out + 1] = Sky() and "Sky: painted, follows the hour." or "Sky: not a painted sky (a fixed picture), left alone."
    local white, red = D.DreamLights()
    out[#out + 1] = string.format("Dream room: %d named light%s%s.", #white, #white == 1 and "" or "s",
        #red > 0 and (", and a red set of " .. #red) or ", no red set")
    local dark, dim = 0, 0
    for _, m in ipairs(D.Moods()) do if m.k == "dark" then dark = dark + 1 else dim = dim + 1 end end
    out[#out + 1] = string.format("Darker places: %d dark mark%s, %d dim.", dark, dark == 1 and "" or "s", dim)
    return table.concat(out, " ")
end

-- (for the tests: as if the map had just loaded)
function D.Reset()
    D.sun, D.sky, D.skyOwn, D.skyKey, D.sunLetter, D.gloomLetter, D.sunGlow, D.dreamMode = nil, nil, nil, nil, nil, nil, nil, nil
end
