--[[
    Living City (gamemode)

    A Combine-occupied city to live in. Built on Sandbox only so admins keep
    the building tools for editing the city; everything Sandbox gives regular
    players (spawn menu, context menu, props, noclip, physgun, toolgun) is off.
    Admins switch between playing and building with !build (lc_buildmode).

    All of the city itself (NPCs, factions, jobs, quests, survival, prisons,
    contraband...) lives in the Living City addon code under lua/autorun, which
    this gamemode switches fully on: factions and ranks are always enabled and
    the city starts by itself when the map loads.
]]

DeriveGamemode("sandbox")

GM.Name = "Living City"
GM.Author = "Living City"
GM.Email = ""
GM.Website = ""
GM.TeamBased = false
GM.IsLivingCity = true

-- Admins in build mode get Sandbox's tools back.
function GM:LCBuilder(ply)
    return IsValid(ply) and ply:IsAdmin() and ply:GetNW2Bool("lc_build", false)
end
