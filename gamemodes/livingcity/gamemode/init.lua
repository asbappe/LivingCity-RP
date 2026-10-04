--[[
    Living City (gamemode, server)

    Regular players: no spawning anything, no noclip, no physgun or toolgun,
    no Sandbox menus. Everyone is a person in the city with fists and whatever
    their faction issues them. Death has a short respawn delay, falls hurt
    like they did in Half-Life 2, and the city starts on its own.

    Admins: !build (or lc_buildmode) toggles build mode, which gives back the
    spawn menu, context menu, physgun, toolgun (with the Living City Editor
    under Q > Tools > Living City) and noclip. Toggle it off to play.
]]

AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

util.AddNetworkString("lcg_help")

local function Builder(ply) return GAMEMODE:LCBuilder(ply) end

------------------------------------------------------------------------
-- Sandbox's building, for builders only
------------------------------------------------------------------------

local BUILD_ONLY = {
    "PlayerSpawnObject", "PlayerSpawnProp", "PlayerSpawnRagdoll", "PlayerSpawnEffect", "PlayerSpawnVehicle",
    "PlayerSpawnSWEP", "PlayerGiveSWEP", "PlayerSpawnSENT", "PlayerSpawnNPC", "CanTool", "CanProperty", "CanDrive",
}
for _, name in ipairs(BUILD_ONLY) do
    GM[name] = function(self, ply, ...)
        if not Builder(ply) then return false end
        local base = self.BaseClass and self.BaseClass[name]
        if base then return base(self, ply, ...) end
        return true
    end
end

function GM:PhysgunPickup(ply, ent)
    if not Builder(ply) then return false end
    return self.BaseClass.PhysgunPickup(self, ply, ent)
end

function GM:PlayerNoClip(ply, desired)
    if not desired then return true end -- always allowed to stop
    return Builder(ply)
end

------------------------------------------------------------------------
-- Living in the city
------------------------------------------------------------------------

-- Living City's factions hand out models and loadouts first (in a hook);
-- this is only the fallback.
function GM:PlayerLoadout(ply)
    ply:Give("weapon_fists")
    if Builder(ply) then
        ply:Give("weapon_physgun")
        ply:Give("gmod_tool")
    end
    ply:SelectWeapon("weapon_fists")
    return true
end

-- The slow, grounded feel (see shared.lua). Factions may set their own speeds on top.
function GM:LCApplyMovement(ply)
    if not self:LCSlowMovement() then return end
    ply:SetWalkSpeed(self.cvWalk:GetInt())
    ply:SetRunSpeed(self.cvRun:GetInt())
    ply:SetSlowWalkSpeed(70)
    ply:SetCrouchedWalkSpeed(0.4)
    ply:SetJumpPower(self.cvJump:GetInt())
end

hook.Add("PlayerSpawn", "LivingCityMovement", function(ply)
    if GAMEMODE and GAMEMODE.LCApplyMovement then GAMEMODE:LCApplyMovement(ply) end
end)

function GM:PlayerSetModel(ply)
    ply:SetModel(string.format("models/player/group01/%s_0%d.mdl", math.random() < 0.5 and "male" or "female", math.random(1, 6)))
    ply:SetupHands()
end

-- Killing each other is possible; the conduct system judges whether it was fair.
function GM:PlayerShouldTakeDamage(ply, attacker) return true end

-- Half-Life 2's realistic fall damage.
function GM:GetFallDamage(ply, speed) return math.max(0, (speed - 526.5) * (100 / 396)) end

function GM:PlayerDeath(ply, inflictor, attacker)
    self.BaseClass.PlayerDeath(self, ply, inflictor, attacker)
    ply.NextSpawnTime = CurTime() + 6
end

function GM:ShowHelp(ply)
    net.Start("lcg_help")
    net.WriteBool(ply:IsAdmin())
    net.Send(ply)
end

------------------------------------------------------------------------
-- Build mode
------------------------------------------------------------------------

function GM:LCSetBuild(ply, on)
    if not IsValid(ply) or not ply:IsAdmin() then return false end
    ply:SetNW2Bool("lc_build", on == true)
    if on then
        ply:Give("weapon_physgun")
        ply:Give("gmod_tool")
        ply:ChatPrint("[Living City] Build mode ON: spawn menu (Q), context menu (C), physgun, toolgun and noclip. The Living City Editor is under Q > Tools > Living City. Type !build again to go back to playing.")
    else
        ply:StripWeapon("weapon_physgun")
        ply:StripWeapon("gmod_tool")
        if ply:GetMoveType() == MOVETYPE_NOCLIP then ply:SetMoveType(MOVETYPE_WALK) end
        ply:ChatPrint("[Living City] Build mode OFF. You're just a person in the city now.")
    end
    return true
end

concommand.Add("lc_buildmode", function(ply)
    if not IsValid(ply) or not ply:IsAdmin() then return end
    GAMEMODE:LCSetBuild(ply, not ply:GetNW2Bool("lc_build", false))
end)

hook.Add("PlayerSay", "LivingCityGamemode", function(ply, text)
    local t = string.lower(string.Trim(text))
    if t == "!build" then
        if ply:IsAdmin() then
            GAMEMODE:LCSetBuild(ply, not ply:GetNW2Bool("lc_build", false))
        else
            ply:ChatPrint("[Living City] Build mode is for admins.")
        end
        return ""
    end
    if t == "!help" then
        GAMEMODE:ShowHelp(ply)
        return ""
    end
end)

------------------------------------------------------------------------
-- Arriving
------------------------------------------------------------------------

hook.Add("PlayerInitialSpawn", "LivingCityGamemode", function(ply)
    timer.Simple(6, function()
        if not IsValid(ply) then return end
        ply:ChatPrint("[Living City] Welcome to the city. F1 help, F2 pockets, F3 your board, F4 factions.")
        if ply:IsAdmin() then
            ply:ChatPrint("[Living City] You're an admin: !build switches to build mode for the editor, physgun and noclip.")
        end
    end)
end)

-- The city starts on its own.
hook.Add("InitPostEntity", "LivingCityGamemode", function()
    timer.Simple(4, function()
        if LC and LC.Start and not LC.Running then LC.Start(nil) end
    end)
end)
