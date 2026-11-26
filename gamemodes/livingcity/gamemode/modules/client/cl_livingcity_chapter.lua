--[[
    Living City: the chapter "the city falls to the Resistance", your side (sv_livingcity_chapter.lua)

    The wave    a burst high over the city and a wave rolling out over the whole map: a white-blue flash, a
                sphere and a ring of light sweeping outward in the sky, a long shake, thunder. Drawn here with
                the game's own render calls, so it is there whatever the server has; Episode Two's portal storm
                particles and sounds are added when the game has them (looked for, never assumed). No words.
    The mask    a unit's mask while the city is the Resistance's: static, tearing and dropouts over the view,
                until it is taken off (F2 > Take off the mask).
]]

LC_CL = LC_CL or {}
LC_CL.Chapter = LC_CL.Chapter or {}
local CH = LC_CL.Chapter

local glow = Material("sprites/light_glow02_add")
local beam = Material("sprites/laserbeam")
local noise = Material("effects/tvscreen_noise002a")
local BLUE, WHITE = Color(150, 200, 255), Color(235, 245, 255)

------------------------------------------------------------------------
-- Episode Two's own, when the game has it
------------------------------------------------------------------------

local STORM_PCF = { "particles/aurora_sphere2.pcf", "particles/aurora.pcf" }
local STORM_FX = { "aurora_shockwave", "aurora_shockwave_ring", "aurora_shockwave_debris" }
local stormReady
local function StormParticles(at)
    if not (file and file.Exists and game and game.AddParticles and PrecacheParticleSystem and ParticleEffect) then return false end
    if stormReady == nil then
        stormReady = false
        for _, pcf in ipairs(STORM_PCF) do
            if file.Exists(pcf, "GAME") then game.AddParticles(pcf) stormReady = true end
        end
        if stormReady then for _, fx in ipairs(STORM_FX) do PrecacheParticleSystem(fx) end end
    end
    if not stormReady then return false end
    for _, fx in ipairs(STORM_FX) do ParticleEffect(fx, at, Angle(0, 0, 0)) end
    return true
end

-- A portal storm's own sound from Episode Two, whatever it is called there: the first found.
local stormSound
local function StormSound()
    if stormSound ~= nil then return stormSound or nil end
    stormSound = false
    if not (file and file.Find) then return nil end
    for _, dir in ipairs({ "ambient/levels/outland/", "ambient/levels/citadel/" }) do
        local found = file.Find("sound/" .. dir .. "*portal*storm*.wav", "GAME") or {}
        if #found == 0 then found = file.Find("sound/" .. dir .. "*portalblast*.wav", "GAME") or {} end
        if found[1] then stormSound = dir .. found[1] break end
    end
    return stormSound or nil
end

------------------------------------------------------------------------
-- The wave
------------------------------------------------------------------------

local function Play(path) if surface and surface.PlaySound then surface.PlaySound(path) end end

function CH.Wave(at, secs, radius)
    local now = CurTime()
    CH.wave = { at = at, t0 = now, secs = math.max(1, secs or 6), radius = math.max(1000, radius or 46000) }
    Play("ambient/energy/whiteflash.wav")
    Play("ambient/explosions/citadel_end_explosion" .. math.random(1, 2) .. ".wav")
    local own = StormSound()
    if own then Play(own) end
    timer.Simple(1.2, function() Play("ambient/levels/labs/teleport_postblast_thunder1.wav") end)
    timer.Simple(3.5, function() Play("ambient/atmosphere/thunder" .. math.random(1, 4) .. ".wav") end)
    if util and util.ScreenShake and IsValid(LocalPlayer()) then
        util.ScreenShake(LocalPlayer():GetPos(), 7, 4, CH.wave.secs + 2, 4000)
    end
    LC.Try(StormParticles, at)
end

net.Receive("lc_chapter_wave", function()
    local at, secs, radius = net.ReadVector(), net.ReadFloat(), net.ReadFloat()
    LC.Try(CH.Wave, at, secs, radius)
end)

-- How far the wave has rolled (0 to 1), or nil when there is none.
local function Rolled()
    local w = CH.wave
    if not w then return nil end
    local f = (CurTime() - w.t0) / w.secs
    if f > 1.6 then CH.wave = nil return nil end
    return f, w
end

hook.Add("PostDrawTranslucentRenderables", "LivingCityChapter", function(_, sky)
    if sky or not render then return end
    local f, w = Rolled()
    if not f then return end
    local fade = math.Clamp(1.4 - f, 0, 1)
    -- the burst itself
    if render.DrawSprite then
        render.SetMaterial(glow)
        local s = 3000 + 9000 * math.min(f * 4, 1)
        render.DrawSprite(w.at, s, s, Color(BLUE.r, BLUE.g, BLUE.b, 255 * math.Clamp(1.2 - f * 1.5, 0, 1)))
    end
    local r = w.radius * math.Clamp(f, 0, 1)
    -- the wave: a shell of light growing out of it (seen from inside and from outside)
    if render.DrawSphere and render.SetColorMaterial then
        render.SetColorMaterial()
        local col = Color(BLUE.r, BLUE.g, BLUE.b, 46 * fade)
        render.DrawSphere(w.at, r, 28, 28, col)
        render.DrawSphere(w.at, -r, 28, 28, col)
    end
    -- and a ring racing out across the sky at its height
    if render.DrawBeam then
        render.SetMaterial(beam)
        local width = 260 + 900 * f
        local col = Color(WHITE.r, WHITE.g, WHITE.b, 255 * fade)
        local last
        for i = 0, 48 do
            local a = i / 48 * math.pi * 2
            local p = w.at + Vector(math.cos(a) * r, math.sin(a) * r, 0)
            if last then render.DrawBeam(last, p, width, 0, 1, col) end
            last = p
        end
    end
end)

hook.Add("HUDPaint", "LivingCityChapterWave", function()
    local f, w = Rolled()
    if not f then return end
    -- the flash at the burst, and a second, paler one as the wave passes over you
    local a = 255 * math.Clamp(1 - f * 2.2, 0, 1)
    local me = LocalPlayer()
    if IsValid(me) then
        local mine = me:GetPos():Distance(w.at) / w.radius
        a = math.max(a, 150 * math.Clamp(1 - math.abs(f - mine) * 6, 0, 1))
    end
    if a <= 1 then return end
    surface.SetDrawColor(215, 232, 255, a)
    surface.DrawRect(0, 0, ScrW(), ScrH())
end)

------------------------------------------------------------------------
-- A unit's mask while the city is the Resistance's
------------------------------------------------------------------------

local function Glitching()
    local me = LocalPlayer()
    return IsValid(me) and me:Alive() and me:GetNW2Bool("lc_chapter_mask", false)
end
CH.MaskGlitching = Glitching

hook.Add("RenderScreenspaceEffects", "LivingCityChapterMask", function()
    if not Glitching() or not DrawColorModify then return end
    DrawColorModify({ ["$pp_colour_addr"] = 0, ["$pp_colour_addg"] = 0.02, ["$pp_colour_addb"] = 0.05, ["$pp_colour_brightness"] = -0.12,
        ["$pp_colour_contrast"] = 1.5, ["$pp_colour_colour"] = 0.15, ["$pp_colour_mulr"] = 0, ["$pp_colour_mulg"] = 0, ["$pp_colour_mulb"] = 0 })
end)

-- Under the HUD: static over everything, bands of the picture torn out, and the whole view dropping out for a
-- moment every few seconds. Strong on purpose: the mask has to come off.
local dropAt, dropUntil = 0, 0
hook.Add("HUDPaintBackground", "LivingCityChapterMask", function()
    if not Glitching() then return end
    local w, h, now = ScrW(), ScrH(), CurTime()
    if now >= dropAt then
        dropUntil = now + math.Rand(0.35, 1.1)
        dropAt = dropUntil + math.Rand(1.5, 4)
    end
    if now < dropUntil then
        surface.SetDrawColor(4, 6, 8, 250)
        surface.DrawRect(0, 0, w, h)
    end
    -- static
    if noise and not noise:IsError() and surface.DrawTexturedRectUV then
        surface.SetMaterial(noise)
        surface.SetDrawColor(255, 255, 255, 150)
        local u, v = math.Rand(0, 1), math.Rand(0, 1)
        surface.DrawTexturedRectUV(0, 0, w, h, u, v, u + 3, v + 2)
    end
    for _ = 1, 90 do
        local g = math.random(40, 230)
        surface.SetDrawColor(g, g, g, math.random(60, 170))
        surface.DrawRect(math.random(0, w), math.random(0, h), math.random(2, 60), math.random(1, 3))
    end
    -- tearing: bands of nothing, a few wide ones that jump about
    for i = 1, 7 do
        local y = (math.sin(now * (1.3 + i * 0.7) + i * 2.1) * 0.5 + 0.5) * h
        local bh = 6 + (i * 13) % 46
        surface.SetDrawColor(8, 12, 16, 235)
        surface.DrawRect(0, y, w, bh)
        surface.SetDrawColor(170, 200, 215, 90)
        surface.DrawRect(math.random(-40, 40), y + bh, w, 2)
    end
end)
