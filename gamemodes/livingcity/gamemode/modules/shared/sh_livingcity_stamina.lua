--[[
    Stamina (the owner, 2 November: the lost v2.7 piece, rebuilt)

    Running and jumping tire you. Stamina (out of 100) drains while you run
    (lc_stamina_run a second) and with each jump (lc_stamina_jump); it comes back
    once you stop running (lc_stamina_regen a second, after a second's rest). Run
    it all out and you're winded: you can only walk, and can't jump, until it's
    back to lc_stamina_winded. The Overwatch's soldiers tire at half the rate; the
    infested, noclip and an ending don't tire anyone (the morning drill does: the
    owner, 2 November, it makes it harder). A good night's sleep, and a stomach
    above lc_stamina_fed_hunger, each bring it back a little faster
    (lc_stamina_rested_bonus, lc_stamina_fed_bonus). A bar at
    the bottom of the screen shows it while it isn't full. lc_stamina 0 turns it off.

    Out of breath, you pant (the owner, 7 November, twice: "breathing ... repeats
    endlessly even after stamina refills"). The server never plays it: each game
    plays it for the people near it, through one sound handle per person
    (CreateSound), started once when they run out and stopped (Stop, then dropped)
    as soon as they have their breath back, at most 8 seconds on, when they die,
    respawn or change faction, and by a watchdog every second.
    player/breathe1.wav loops by itself, so it is never played without a handle.
]]

LC = LC or {}
LCS = LCS or {}
local FLAGS = bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED)
local cvOn     = CreateConVar("lc_stamina", "1", FLAGS, "Running and jumping tire you; run out, and you can only walk for a while")
local cvRun    = CreateConVar("lc_stamina_run", "6", FLAGS, "Stamina (of 100) a second of running costs")
local cvJump   = CreateConVar("lc_stamina_jump", "10", FLAGS, "Stamina (of 100) a jump costs")
local cvRegen  = CreateConVar("lc_stamina_regen", "12", FLAGS, "Stamina (of 100) that comes back each second you're not running")
local cvWinded = CreateConVar("lc_stamina_winded", "30", FLAGS, "Run out, and you can't run or jump until your stamina is back to this")
local cvRested = CreateConVar("lc_stamina_rested_bonus", "25", FLAGS, "Percent faster your stamina comes back after a good night's sleep")
local cvFed    = CreateConVar("lc_stamina_fed_bonus", "25", FLAGS, "Percent faster your stamina comes back while you're fed (hunger above lc_stamina_fed_hunger)")
local cvFedAt  = CreateConVar("lc_stamina_fed_hunger", "30", FLAGS, "Hunger (of 100) above which you count as fed, for stamina")

function LCS.On() return cvOn:GetBool() end
function LCS.Get(ply) return ply:GetNW2Float("lc_stamina", 100) end
function LCS.Winded(ply) return cvOn:GetBool() and ply:GetNW2Bool("lc_winded", false) end

local function Free(ply)
    if not ply:Alive() or ply:GetMoveType() == MOVETYPE_NOCLIP or (ply.InVehicle and ply:InVehicle()) then return true end
    if ply:GetNW2String("lcf_faction", "") == "zombie" then return true end
    if GetGlobal2Bool("lc_timestop", false) then return true end
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

if CLIENT then
    -- Panting: one CSoundPatch per player who's out of breath, owned here and nowhere else.
    local BREATH = "player/breathe1.wav" -- (a looping sample: only ever played through a handle that is stopped)
    local MAX_SECS = 8                  -- (never longer than this, however long they stay winded)
    local NEAR = 700                    -- (others are heard panting this close; you always hear yourself)
    local pants = {}                    -- [ply] = { snd = CSoundPatch, t0 = when, faction = at the start }
    local spent = {}                    -- [ply] = true: panted already for this time out of breath
    LCS.Pants = pants
    local function StopPant(ply)
        local p = pants[ply]
        pants[ply] = nil
        if p and p.snd then p.snd:Stop() p.snd = nil end
        -- (and anything an older version of the server started on them without a handle)
        if IsValid(ply) and ply.StopSound then ply:StopSound(BREATH) end
    end
    LCS.StopPant = StopPant
    local function ShouldPant(ply, now, p)
        if not IsValid(ply) or not cvOn:GetBool() or not ply:Alive() then return false end
        if not ply:GetNW2Bool("lc_winded", false) then return false end
        if ply:GetNW2Float("lc_stamina", 100) >= cvWinded:GetFloat() then return false end
        if p and (now - p.t0 > MAX_SECS or p.faction ~= ply:GetNW2String("lcf_faction", "")) then return false end
        return true
    end
    LCS.ShouldPant = ShouldPant
    -- Stops whatever shouldn't be playing; starts it for anyone who just ran out. True if it plays for ply.
    function LCS.BreathTick(now)
        now = now or CurTime()
        for ply, p in pairs(pants) do
            if not ShouldPant(ply, now, p) then StopPant(ply) end
        end
        for ply in pairs(spent) do
            if not IsValid(ply) or not ply:GetNW2Bool("lc_winded", false) or not ply:Alive() then spent[ply] = nil end
        end
        local me = LocalPlayer and LocalPlayer()
        for _, ply in ipairs(player.GetAll()) do
            if not pants[ply] and not spent[ply] and ShouldPant(ply, now)
                and (ply == me or (IsValid(me) and ply:GetPos():DistToSqr(me:GetPos()) < NEAR * NEAR)) then
                spent[ply] = true
                local snd = CreateSound and CreateSound(ply, BREATH) or nil
                if snd then
                    if snd.SetSoundLevel then snd:SetSoundLevel(ply == me and 0 or 60) end
                    snd:PlayEx(0.6, 100)
                    pants[ply] = { snd = snd, t0 = now, faction = ply:GetNW2String("lcf_faction", "") }
                end
            end
        end
    end
    -- The watchdog: every second, nothing pants that shouldn't, whatever else went wrong.
    function LCS.BreathWatchdog(now)
        now = now or CurTime()
        for ply, p in pairs(pants) do
            if not ShouldPant(ply, now, p) then StopPant(ply) end
        end
        local me = LocalPlayer and LocalPlayer()
        if IsValid(me) and not pants[me] and me.StopSound then me:StopSound(BREATH) end
    end
    timer.Create("LivingCityBreath", 0.25, 0, function()
        local ok, err = pcall(LCS.BreathTick, CurTime())
        if not ok then print("[Living City] panting: " .. tostring(err)) end
    end)
    timer.Create("LivingCityBreathWatchdog", 1, 0, function()
        local ok, err = pcall(LCS.BreathWatchdog, CurTime())
        if not ok then print("[Living City] panting watchdog: " .. tostring(err)) end
    end)
    hook.Add("ShutDown", "LivingCityBreath", function() for ply in pairs(pants) do StopPant(ply) end end)
    return
end

-- slept well, and fed: a little faster each
function LCS.RegenMul(ply)
    local mul = 1
    if LC.IsRested and LC.IsRested(ply) then mul = mul + math.max(0, cvRested:GetFloat()) / 100 end
    if LC.Hunger and LC.Hunger(ply) > cvFedAt:GetFloat() then mul = mul + math.max(0, cvFed:GetFloat()) / 100 end
    return mul
end

-- running: the run key down, on the ground, moving faster than a walk
local function Running(ply)
    if not ply:KeyDown(IN_SPEED) or not ply:IsOnGround() then return false end
    local v = ply:GetVelocity()
    return v.x * v.x + v.y * v.y > (ply:GetWalkSpeed() + 15) ^ 2
end

function LCS.Tick(now, dt)
    if not cvOn:GetBool() then return end
    for _, ply in LC.Players() do
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
            s = s + cvRegen:GetFloat() * LCS.RegenMul(ply) * dt
        end
        s = math.Clamp(s, 0, 100)
        if math.abs(s - was) >= 0.5 or (s == 100 and was ~= 100) or (s == 0 and was ~= 0) then ply:SetNW2Float("lc_stamina", s) end
        local winded = ply:GetNW2Bool("lc_winded", false)
        if not winded and s <= 0 then
            ply:SetNW2Bool("lc_winded", true) -- (the panting is each player's own game's: above)
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
