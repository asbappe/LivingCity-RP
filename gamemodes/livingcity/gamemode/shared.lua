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

------------------------------------------------------------------------
-- How it moves: a person walking around a city, not a deathmatch
--
-- Half-Life 2's movement is built for strafing and hopping. Here there's a
-- slow walk and a slower sprint, a short low jump with a beat to recover from
-- it, no jumping from a crouch, no ducking in the air, and no gaining speed
-- in the air. lc_slow_movement 0 gives the old feel back.
------------------------------------------------------------------------

local FLAGS = bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED)
GM.cvSlow  = CreateConVar("lc_slow_movement", "1", FLAGS, "Slow, grounded movement: lower speeds and jump, no bunny hopping or crouch jumping")
GM.cvWalk  = CreateConVar("lc_walk_speed", "110", FLAGS, "Walking speed")
GM.cvRun   = CreateConVar("lc_run_speed", "190", FLAGS, "Sprinting speed (hold shift)")
GM.cvJump  = CreateConVar("lc_jump_power", "200", FLAGS, "Jump strength (200 is Half-Life 2's, enough for a curb or a crate)")
GM.cvHop   = CreateConVar("lc_jump_delay", "0.9", FLAGS, "Seconds between jumps")

function GM:LCSlowMovement() return self.cvSlow:GetBool() end

-- Pulling yourself up onto a ledge: look at something up to about chest height
-- (a crate, the lip of a platform, out of a track bed) and jump.
local MANTLE_MIN, MANTLE_MAX = 28, 92

local function Mantle(ply, mv)
    if not mv.GetOrigin or not mv.GetAngles then return false end
    local pos = mv:GetOrigin()
    local fwd = Angle(0, mv:GetAngles().y, 0):Forward()
    -- a wall right ahead
    local wall = util.TraceHull({
        start = pos + Vector(0, 0, 20), endpos = pos + Vector(0, 0, 20) + fwd * 30,
        mins = Vector(-10, -10, -4), maxs = Vector(10, 10, 4), filter = ply, mask = MASK_PLAYERSOLID,
    })
    if not wall.Hit or (wall.HitNormal and wall.HitNormal.z > 0.5) then return false end
    -- the top of it
    local from = Vector(wall.HitPos.x, wall.HitPos.y, pos.z + MANTLE_MAX + 10) + fwd * 14
    local down = util.TraceLine({ start = from, endpos = from - Vector(0, 0, MANTLE_MAX + 10), filter = ply, mask = MASK_PLAYERSOLID })
    if not down.Hit or down.StartSolid or (down.HitNormal and down.HitNormal.z < 0.7) then return false end
    local h = down.HitPos.z - pos.z
    if h < MANTLE_MIN or h > MANTLE_MAX then return false end
    -- room to stand up there
    local room = util.TraceHull({
        start = down.HitPos + Vector(0, 0, 2), endpos = down.HitPos + Vector(0, 0, 70),
        mins = Vector(-14, -14, 0), maxs = Vector(14, 14, 2), filter = ply, mask = MASK_PLAYERSOLID,
    })
    if room.Hit then return false end
    local g = 600
    local cv = GetConVar("sv_gravity")
    if cv then g = cv:GetFloat() end
    mv:SetVelocity(Vector(fwd.x * 90, fwd.y * 90, math.sqrt(2 * g * (h + 12))))
    return true
end

hook.Add("SetupMove", "LivingCityMovement", function(ply, mv)
    local gm = GAMEMODE
    if not gm or not gm.IsLivingCity or not gm:LCSlowMovement() then return end
    if ply:GetMoveType() ~= MOVETYPE_WALK then return end
    local buttons = mv:GetButtons()
    if bit.band(buttons, IN_JUMP) ~= 0 and (ply.lcNextMantle or 0) <= CurTime() and Mantle(ply, mv) then
        ply.lcNextMantle = CurTime() + 1
        ply.lcNextJump = CurTime() + gm.cvHop:GetFloat()
        return
    end
    if ply:IsOnGround() then
        if bit.band(buttons, IN_JUMP) ~= 0 then
            if (ply.lcNextJump or 0) > CurTime() or ply:Crouching() then
                buttons = bit.band(buttons, bit.bnot(IN_JUMP)) -- no hopping, no crouch jumping
            else
                ply.lcNextJump = CurTime() + gm.cvHop:GetFloat()
            end
        end
    else
        buttons = bit.band(buttons, bit.bnot(IN_DUCK)) -- no tucking up in the air
        local v = mv:GetVelocity()
        local cap = math.max(ply:GetRunSpeed(), mv:GetMaxSpeed())
        local flat = Vector(v.x, v.y, 0)
        if flat:Length() > cap then
            flat = flat:GetNormalized() * cap
            mv:SetVelocity(Vector(flat.x, flat.y, v.z))
        end
    end
    mv:SetButtons(buttons)
end)
