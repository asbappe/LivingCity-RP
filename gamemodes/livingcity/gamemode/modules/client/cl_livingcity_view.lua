--[[
    Living City (client): how you see the city

    One camera for everything that moves it. Garry's Mod gives the view to the
    first CalcView hook that answers, so two of them (holding a pose, say, and
    the field of view) can't both have it: whichever answered first won, and
    the other was lost. Instead the gamemode's own CalcView (cl_init.lua) asks
    Sandbox for the view (vehicles, weapons) and then runs every touch the
    city adds, in order:

      10 scanner   flying a scanner: the view leaves your body   (cl_livingcity_scanner.lua)
      20 acts      holding a pose: the camera pulls back         (cl_livingcity_acts.lua)
      30 bob       a faint sway in step with your feet, a dip when you land
      35 fov       never wider than lc_fov (75, Half-Life 2's)
      40 dizzy     Breen's water                                 (cl_livingcity_needs.lua)

    A module adds one with LC_CL.ViewMods.<name> = { order = n, fn = function(ply, view, ctx) end }:
    change view.origin, view.angles, view.fov in place; ctx says what came
    before (ctx.remote: the view isn't from your eyes; ctx.third: third person;
    ctx.vehicle). One that errors is switched off, so it can't take the camera
    down with it.

    Players: !bob (or lc_my_view_bob 0) keeps the camera still.
    Server: lc_fov, lc_view_bob (sh_livingcity_feel.lua).
]]

LC_CL = LC_CL or {}
LC_CL.ViewMods = LC_CL.ViewMods or {}

local INK, ACCENT = Color(232, 226, 210), Color(230, 180, 90)

local cvMine = CreateClientConVar("lc_my_view_bob", "1", true, false, "Sway the camera a little as you walk (the server can turn it off for everyone with lc_view_bob 0)")

concommand.Add("lc_bob_toggle", function()
    local on = not cvMine:GetBool()
    RunConsoleCommand("lc_my_view_bob", on and "1" or "0")
    if chat and chat.AddText then
        chat.AddText(ACCENT, "[Living City] ", INK, on and "The camera sways with your steps again. (!bob keeps it still.)"
            or "The camera holds still now. (!bob brings the sway back.)")
    end
end)

-- The steps in order. Sorted once a second, not every frame (and straight
-- away when one breaks), so a reloaded file still gets picked up.
local broken = {}
local sorted, sortedAt = nil, -1
local function Sorted()
    local now = (RealTime and RealTime()) or CurTime()
    if sorted and now - sortedAt < 1 and now >= sortedAt then return sorted end
    local list = {}
    for name, m in pairs(LC_CL.ViewMods) do
        if istable(m) and type(m.fn) == "function" and not broken[name] then list[#list + 1] = { name = name, order = m.order or 50, fn = m.fn } end
    end
    table.sort(list, function(a, b) if a.order == b.order then return a.name < b.name end return a.order < b.order end)
    sorted, sortedAt = list, now
    return list
end

local ctx = {}

-- The view, with the city's touches. view: { origin, angles, fov, ... } (changed in place, and returned).
function LC_CL.CalcView(ply, view)
    if not IsValid(ply) or not istable(view) then return view end
    view.origin = view.origin or ply:EyePos()
    view.angles = view.angles or ply:EyeAngles()
    view.fov = view.fov or 75
    ctx.vehicle = (ply.InVehicle and ply:InVehicle()) and true or false
    ctx.remote, ctx.third = nil, nil
    for _, m in ipairs(Sorted()) do
        local ok, err = pcall(m.fn, ply, view, ctx)
        if not ok then
            broken[m.name] = true
            sorted = nil
            ErrorNoHalt("[Living City] camera: '" .. m.name .. "' failed and is off until you rejoin: " .. tostring(err) .. "\n")
        end
    end
    return view
end

------------------------------------------------------------------------
-- Never wider than the server's field of view
------------------------------------------------------------------------

function LC_CL.FovCap()
    local cv = GetConVar("lc_fov")
    local cap = cv and cv:GetFloat() or 0
    if cap <= 0 then return nil end
    return math.Clamp(cap, 50, 120)
end

LC_CL.ViewMods.fov = { order = 35, fn = function(ply, view)
    local cap = LC_CL.FovCap()
    if cap and view.fov > cap then view.fov = cap end -- (a zoom narrower than that is left alone)
end }

------------------------------------------------------------------------
-- A body under the camera: steps and landings
------------------------------------------------------------------------

local STRIDE = 42        -- units per footstep at a walk
local STRIDE_RUN = 64    -- and at a run: a grown-up's stride lengthens, so the steps don't just come faster (about 3 a second, not 4.5)
local WALK = 110         -- (lc_walk_speed)
local RUN = 190          -- the speed the sway is sized for (lc_run_speed)
local UP, SIDE = 0.5, 0.27 -- units of sway at a run: up and down, side to side (lc_view_bob_amount 100)
local ROLL, PITCH = 0.3, 0.15 -- degrees

local bob = { phase = 0, amount = 0, dip = 0, dipVel = 0, fall = 0, ground = true, t = nil }
LC_CL.Bob = bob -- (for the smoke test)

function LC_CL.BobOn()
    local sv = GetConVar("lc_view_bob")
    return (sv == nil or sv:GetBool()) and cvMine:GetBool()
end

local function Clock() return (RealTime and RealTime()) or CurTime() end

local function FirstPerson(ply, view, ctx)
    if ctx.remote or ctx.third or ctx.vehicle or view.drawviewer then return false end
    if not ply:Alive() or ply:GetMoveType() ~= MOVETYPE_WALK then return false end
    if ply.GetObserverMode and ply:GetObserverMode() ~= (OBS_MODE_NONE or 0) then return false end
    if ply.GetViewEntity and IsValid(ply:GetViewEntity()) and ply:GetViewEntity() ~= ply then return false end
    return true
end

LC_CL.ViewMods.bob = { order = 30, fn = function(ply, view, ctx)
    local now = Clock()
    local dt = bob.t and math.Clamp(now - bob.t, 0, 0.1) or 0
    bob.t = now
    if not LC_CL.BobOn() or not FirstPerson(ply, view, ctx) then
        bob.amount, bob.dip, bob.dipVel, bob.fall, bob.ground = 0, 0, 0, 0, true
        return
    end
    local vel = ply:GetVelocity()
    local speed = vel:Length2D()
    local ground = ply:IsOnGround()

    -- a landing: the harder the fall, the deeper the knees give
    if not ground then
        bob.fall = math.min(bob.fall, vel.z)
    elseif not bob.ground then
        local hit = math.Clamp((-bob.fall - 120) / 420, 0, 1)
        if hit > 0 then bob.dipVel = bob.dipVel - 160 * hit end -- (about 5 units for a long drop, 1 or 2 for a jump)
        bob.fall = 0
    end
    bob.ground = ground
    -- and back up, like a spring that doesn't wobble (in small steps, so a slow frame can't throw it)
    local left = dt
    while left > 0 do
        local h = math.min(left, 0.016)
        bob.dipVel = bob.dipVel + (-150 * bob.dip - 24 * bob.dipVel) * h
        bob.dip = math.Clamp(bob.dip + bob.dipVel * h, -8, 1)
        left = left - h
    end

    -- steps: one rise and fall per footstep, one sway left and right per two
    local target = ground and math.Clamp(speed / RUN, 0, 1.25) or 0
    if ply:Crouching() then target = target * 0.5 end
    bob.amount = bob.amount + (target - bob.amount) * math.min(dt * 8, 1)
    local stride = STRIDE + (STRIDE_RUN - STRIDE) * math.Clamp((speed - WALK) / (RUN - WALK), 0, 1)
    bob.phase = (bob.phase + speed * dt / stride * math.pi) % (math.pi * 2)

    local amt = GetConVar("lc_view_bob_amount")
    local k = math.Clamp((amt and amt:GetFloat() or 100) / 100, 0, 3)
    local a = bob.amount * k
    local s, c2 = math.sin(bob.phase), math.cos(bob.phase * 2)
    local dip = bob.dip * k
    local up = UP * a * (c2 - 1) * 0.5 + dip
    local side = SIDE * a * s
    if up == 0 and side == 0 then return end
    view.origin = view.origin + Vector(0, 0, up) + view.angles:Right() * side
    view.angles = view.angles + Angle(PITCH * a * c2 - dip * 0.3, 0, ROLL * a * s)
end }
