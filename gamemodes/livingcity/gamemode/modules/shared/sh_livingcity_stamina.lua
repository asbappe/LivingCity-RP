--[[
    Stamina (the owner, 2 November: the lost v2.7 piece, rebuilt)

    Running and jumping tire you. Stamina (out of 100) drains while you run
    (lc_stamina_run a second) and with each jump (lc_stamina_jump); it comes back
    once you stop running (lc_stamina_regen a second, after a second's rest). Run
    it all out and you're winded: you can only walk, and can't jump, until it's
    back to lc_stamina_winded. The Overwatch's soldiers tire at half the rate; the
    infested, noclip, a morning drill and an ending don't tire anyone. A bar at
    the bottom of the screen shows it while it isn't full. lc_stamina 0 turns it off.
]]

LC = LC or {}
LCS = LCS or {}
local FLAGS = bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED)
local cvOn     = CreateConVar("lc_stamina", "1", FLAGS, "Running and jumping tire you; run out, and you can only walk for a while")
local cvRun    = CreateConVar("lc_stamina_run", "6", FLAGS, "Stamina (of 100) a second of running costs")
local cvJump   = CreateConVar("lc_stamina_jump", "10", FLAGS, "Stamina (of 100) a jump costs")
local cvRegen  = CreateConVar("lc_stamina_regen", "12", FLAGS, "Stamina (of 100) that comes back each second you're not running")
local cvWinded = CreateConVar("lc_stamina_winded", "30", FLAGS, "Run out, and you can't run or jump until your stamina is back to this")

function LCS.On() return cvOn:GetBool() end
function LCS.Get(ply) return ply:GetNW2Float("lc_stamina", 100) end
function LCS.Winded(ply) return cvOn:GetBool() and ply:GetNW2Bool("lc_winded", false) end

local function Free(ply)
    if not ply:Alive() or ply:GetMoveType() == MOVETYPE_NOCLIP or (ply.InVehicle and ply:InVehicle()) then return true end
    if ply:GetNW2String("lcf_faction", "") == "zombie" then return true end
    if GetGlobal2Bool("lc_timestop", false) then return true end
    if SERVER and LC.ExerciseSession and LC.ExerciseSession() then return true end -- (the morning drill: everyone keeps up)
    return false
end
LCS.Free = Free

hook.Add("SetupMove", "LivingCityStamina", function(ply, mv)
    if not cvOn:GetBool() or not mv or not mv.SetButtons or not mv.KeyPressed or Free(ply) then return end
    if ply:GetNW2Bool("lc_winded", false) then
        local walk = ply:GetWalkSpeed()
        if mv.GetMaxClientSpeed and mv:GetMaxClientSpeed() > walk then mv:SetMaxClientSpeed(walk) end
        mv:SetButtons(bit.band(mv:GetButtons(), bit.bnot(bit.bor(IN_JUMP, IN_SPEED))))
    elseif mv:KeyPressed(IN_JUMP) and ply:GetNW2Float("lc_stamina", 100) < cvJump:GetFloat() then
        mv:SetButtons(bit.band(mv:GetButtons(), bit.bnot(IN_JUMP)))
    end
end)

if CLIENT then return end

-- running: the run key down, on the ground, moving faster than a walk
local function Running(ply)
    if not ply:KeyDown(IN_SPEED) or not ply:IsOnGround() then return false end
    local v = ply:GetVelocity()
    return v.x * v.x + v.y * v.y > (ply:GetWalkSpeed() + 15) ^ 2
end

function LCS.Tick(now, dt)
    if not cvOn:GetBool() then return end
    for _, ply in ipairs(player.GetAll()) do
        local s = ply:GetNW2Float("lc_stamina", 100)
        local was = s
        if Free(ply) then
            s = 100
            ply.lcRanAt = nil
        elseif Running(ply) then
            local mul = (LCF and LCF.IsOverwatch and LCF.IsOverwatch(ply)) and 0.5 or 1
            s = s - cvRun:GetFloat() * mul * dt
            ply.lcRanAt = now
        elseif now - (ply.lcRanAt or 0) > 1 then
            s = s + cvRegen:GetFloat() * dt
        end
        s = math.Clamp(s, 0, 100)
        if math.abs(s - was) >= 0.5 or (s == 100 and was ~= 100) or (s == 0 and was ~= 0) then ply:SetNW2Float("lc_stamina", s) end
        local winded = ply:GetNW2Bool("lc_winded", false)
        if not winded and s <= 0 then
            ply:SetNW2Bool("lc_winded", true)
            ply:EmitSound("player/breathe1.wav", 60, 100, 0.6)
        elseif winded and s >= cvWinded:GetFloat() then
            ply:SetNW2Bool("lc_winded", false)
        end
    end
end
timer.Create("LivingCityStamina", 0.2, 0, function()
    local ok, err = pcall(LCS.Tick, CurTime(), 0.2)
    if not ok and LC.Error then LC.Error("stamina", err) end
end)

-- a jump costs stamina
hook.Add("KeyPress", "LivingCityStamina", function(ply, key)
    if key ~= IN_JUMP or not cvOn:GetBool() or Free(ply) or not ply:IsOnGround() then return end
    local s = ply:GetNW2Float("lc_stamina", 100)
    if s < cvJump:GetFloat() then return end
    ply:SetNW2Float("lc_stamina", math.max(0, s - cvJump:GetFloat()))
    ply.lcRanAt = CurTime()
end)
hook.Add("PlayerSpawn", "LivingCityStamina", function(ply)
    ply:SetNW2Float("lc_stamina", 100)
    ply:SetNW2Bool("lc_winded", false)
end)
