--[[
    Episode Two's particle effects the maps use (the owner's compile of the forest bunker, 25 November: the
    rocket launch printed "Attempted to create unknown particle system 'choreo_launch_rocket_jet'" and the like,
    and drew no smoke or fire). Garry's Mod does not load Episode Two's particle files by itself, so the ones
    that hold these effects are found by reading the game's particle files for the effects' names, loaded, and
    the effects made ready, before the map's entities ask for them.
]]

LC = LC or {}

-- the effects the launch room, the silo and White Forest's rooms use
LC.MAP_PARTICLES = {
    "choreo_launch_rocket_start", "choreo_launch_rocket_jet", "choreo_launch_rocket_upsmoke", "choreo_silo_door",
    "Dust_Ceiling_Rumble_24Diam", "Dust_Ceiling_Rumble_512Square", "dust_motes_lit_cone",
}

-- (files whose names suggest them are read first, so most loads read only a few)
local LIKELY = { "choreo", "launch", "dust", "rumble", "ambient", "light", "silo" }

local function likelyFirst(names)
    local first, rest = {}, {}
    for _, n in ipairs(names) do
        local low, hit = string.lower(n), false
        for _, w in ipairs(LIKELY) do if string.find(low, w, 1, true) then hit = true break end end
        if hit then first[#first + 1] = n else rest[#rest + 1] = n end
    end
    for _, n in ipairs(rest) do first[#first + 1] = n end
    return first
end

-- Loads the particle files that hold the wanted effects. Returns the files loaded and the effects found in none.
function LC.LoadMapParticles(want)
    want = want or LC.MAP_PARTICLES
    local missing, left = {}, 0
    for _, n in ipairs(want) do missing[n] = true left = left + 1 end
    local loaded = {}
    if not (file and file.Find and file.Read and game and game.AddParticles) then return loaded, missing end
    local names = file.Find("particles/*.pcf", "GAME") or {}
    for _, name in ipairs(likelyFirst(names)) do
        if left == 0 then break end
        local path = "particles/" .. name
        local data = file.Read(path, "GAME")
        if data then
            local hit = false
            for n in pairs(missing) do
                if string.find(data, n, 1, true) then missing[n], left, hit = nil, left - 1, true end
            end
            if hit then
                game.AddParticles(path)
                loaded[#loaded + 1] = path
            end
        end
    end
    if PrecacheParticleSystem then
        for _, n in ipairs(want) do if not missing[n] then PrecacheParticleSystem(n) end end
    end
    return loaded, missing
end

LC.Try(function() LC.LoadMapParticles() end)
