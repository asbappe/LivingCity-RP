--[[
    Living City: the power grid

    Transformers (an editor fixture) power the district around them, out to
    lc_grid_radius (1800 units): every streetlight, loudspeaker, city screen
    and forcefield there runs off the nearest transformer, and so do the locks
    on Combine doors. Anything with no transformer near it is on the city's
    mains and never goes out.

    Sabotage a transformer (a multitool, twelve seconds; or enough damage:
    explosives, a lot of bullets) and its district goes dark: lights out,
    loudspeakers silent (nobody there hears the PA or a broadcast), screens
    dead, forcefields down, and Combine doors unlocked. Units hear about it at
    once; the Resistance hears the doors are open. A Maintenance Technician
    brings it back (E on it, ten seconds: paid), and so do the city's own
    maintenance crews after a while (sv_livingcity_npcwork.lua), or the
    emergency crews after lc_blackout_minutes (8).

    Forcefields: a keycard swipe (E) opens one for you for a few seconds; a
    multitool shorts one out for a minute.
]]

if CLIENT then return end

LC = LC or {}

local FLAGS = bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED)
local cvRadius  = CreateConVar("lc_grid_radius", "1800", FLAGS, "How far a transformer's district reaches")
local cvOutage  = CreateConVar("lc_blackout_minutes", "8", FLAGS, "Minutes before emergency crews restore a sabotaged transformer nobody fixed")

local cvShare = CreateConVar("lc_blackout_share", "0.5", FLAGS, "Share of the transformers that must be down at once for the whole city to go dark, map lighting and all (0 = never)")
local cvDark  = CreateConVar("lc_blackout_light", "b", FLAGS, "How dark a city-wide blackout is: a (pitch black) to m (normal)")

-- Everything that runs off the grid: Living City's own fixtures...
local POWERED = { "lc_streetlight", "lc_loudspeaker", "lc_screen", "lc_powerbank", "lc_forcefield", "lc_dispenser", "lc_vending", "lc_terminal" }
-- ...and the map's own lights that can be switched. (A light is only still an
-- entity in the running map if the mapper named it; the rest are baked into
-- the map's lighting, which only goes dark all at once: the city-wide
-- blackout, below.) Only the map's own: not the glows on a scanner or a
-- manhack, which are sprites too.
local function SpawnOff(e) return bit.band(e:GetSpawnFlags(), 1) ~= 0 end
local function Var(e, name, default) local v = e.GetInternalVariable and e:GetInternalVariable(name) if v == nil then return default end return v == true end
local function Drawn(e) return not (e.IsEffectActive and e:IsEffectActive(EF_NODRAW or 32)) end
local MAPLIGHTS = {
    light           = { off = "TurnOff", on = "TurnOn", lit = function(e) return not SpawnOff(e) end },
    light_spot      = { off = "TurnOff", on = "TurnOn", lit = function(e) return not SpawnOff(e) end },
    light_dynamic   = { off = "TurnOff", on = "TurnOn", lit = function(e) return Var(e, "m_On", true) end },
    point_spotlight = { off = "LightOff", on = "LightOn", lit = function(e) return Var(e, "m_bSpotlightOn", true) end },
    env_sprite      = { off = "HideSprite", on = "ShowSprite", lit = Drawn },
    beam            = { off = "TurnOff", on = "TurnOn", lit = Drawn },
}
local DOORS = { "prop_door_rotating", "func_door", "func_door_rotating", "func_movelinear" }
LC.PowerOut = LC.PowerOut or {}     -- [door] = true: Combine locks dead for now
LC.DarkLights = LC.DarkLights or {} -- [map light] = true: one we switched off, to switch back on
LC.CityDark = LC.CityDark or false

local function Where(pos) return LC.DescribePlace and LC.DescribePlace(pos) or "somewhere" end
local function Units() local o = {} for _, p in ipairs(player.GetAll()) do if LC.PlayerIsCP(p) then o[#o + 1] = p end end return o end

-- The transformer that feeds pos: the nearest within reach, or none (the mains).
function LC.FeederOf(pos)
    local r2, best, bd = cvRadius:GetFloat() ^ 2
    for _, t in ipairs(LC.EntsOf("lc_transformer")) do
        local d = t:GetPos():DistToSqr(pos)
        if d < r2 and (not bd or d < bd) then best, bd = t, d end
    end
    return best
end

function LC.PoweredAt(pos)
    if LC.CityDark then return false end
    local t = LC.FeederOf(pos)
    return not (IsValid(t) and t:GetNW2Bool("lc_down", false))
end

local function IsCombineDoor(door)
    local tag = LC.EffectiveDoorTag and LC.EffectiveDoorTag(door)
    return tag == "cp"
end

local function FeederDown(pos)
    local t = LC.FeederOf(pos)
    return IsValid(t) and t:GetNW2Bool("lc_down", false)
end
local function Dark(pos) return LC.CityDark or FeederDown(pos) end
LC.PowerDarkAt = Dark

-- Work out what has power, everywhere: Living City's fixtures, the map's
-- switchable lights, and the locks on Combine doors. (Prison doors aren't
-- Combine doors here: they stay locked when the power goes.)
function LC.RefreshPower()
    for _, cls in ipairs(POWERED) do
        for _, e in ipairs(LC.EntsOf(cls)) do
            local off
            if e.lcForcefield and LC.FieldOff then
                off = LC.FieldOff(e) -- (off its checkpoint's power bank, if it has one: sv_livingcity_checkpoints.lua)
            else
                off = Dark(e:GetPos())
            end
            if e:GetNW2Bool("lc_nopower", false) ~= off then
                e:SetNW2Bool("lc_nopower", off)
                if e.lcForcefield and LC.FieldRulesChanged then LC.FieldRulesChanged(e) end -- (who it stops has changed)
            end
        end
    end
    for cls, kind in pairs(MAPLIGHTS) do
        for _, e in ipairs(LC.EntsOf(cls)) do
            if IsValid(e) and (not e.CreatedByMap or e:CreatedByMap()) and not IsValid(e:GetParent()) then
                local off = Dark(e:GetPos())
                if off and not LC.DarkLights[e] then
                    if kind.lit(e) then
                        LC.DarkLights[e] = true
                        e:Fire(kind.off)
                    end
                elseif not off and LC.DarkLights[e] then
                    LC.DarkLights[e] = nil
                    e:Fire(kind.on)
                end
            end
        end
    end
    for _, cls in ipairs(DOORS) do
        for _, door in ipairs(LC.EntsOf(cls)) do
            if IsValid(door) then
                local out = IsCombineDoor(door) and Dark(door:WorldSpaceCenter())
                if out and not LC.PowerOut[door] then
                    LC.PowerOut[door] = true
                    door:Fire("Unlock")
                elseif not out and LC.PowerOut[door] then
                    LC.PowerOut[door] = nil
                    if LC.ApplyDoorState then LC.ApplyDoorState(door) end
                end
            end
        end
    end
    LC.FixtureVersion = (LC.FixtureVersion or 0) + 1 -- (whether a loudspeaker works has changed)
end

------------------------------------------------------------------------
-- The whole city goes dark
------------------------------------------------------------------------

-- The map's baked lighting (every lamp the mapper didn't name, and the sun
-- with it: Source bakes them together) is light style 0, so this is all or
-- nothing: night-dark everywhere, the sky itself still bright.
local function Letter()
    local l = string.lower(string.sub(cvDark:GetString(), 1, 1))
    return l:match("^[a-z]$") and l or "b"
end
LC.BlackoutStyle = Letter

local function SetCityDark(on, why)
    on = on == true
    if LC.CityDark == on then return false end
    LC.CityDark = on
    SetGlobal2Bool("lc_blackout", on)
    -- the map's lighting, with the hour of the day (sv_livingcity_atmos.lua tells everyone's game to rebuild it)
    if LC.ApplyLightStyle then LC.ApplyLightStyle()
    elseif engine and engine.LightStyle then engine.LightStyle(0, on and Letter() or "m") end
    LC.RefreshPower()
    for _, p in ipairs(player.GetAll()) do
        p:ChatPrint(on and "[City] The grid's gone. The whole city is dark: switch on your flashlight (F)."
            or "[City] The lights come back on across the city.")
    end
    if on and LC.RadioNotice then LC.RadioNotice("resistance", "The whole grid's down. Every Combine door in the city is dead.") end
    hook.Run("LivingCityBlackout", on, why)
    return true
end

-- Enough of the grid down at once, or an admin says so.
function LC.CheckCityGrid()
    if LC.ForcedDark ~= nil then return SetCityDark(LC.ForcedDark, "admin") end
    local ts, share = LC.EntsOf("lc_transformer"), cvShare:GetFloat()
    if #ts == 0 or share <= 0 then return SetCityDark(false, "grid") end
    local down = 0
    for _, t in ipairs(ts) do if t:GetNW2Bool("lc_down", false) then down = down + 1 end end
    return SetCityDark(down / #ts >= share - 1e-6, "grid")
end

-- Admins (the admin tools, or lc_blackout): on, off, or back to the grid ("auto").
function LC.ForceBlackout(mode)
    if mode == "on" then LC.ForcedDark = true
    elseif mode == "off" then LC.ForcedDark = false
    else LC.ForcedDark = nil end
    LC.CheckCityGrid()
    return LC.CityDark
end

concommand.Add("lc_blackout", function(ply, _, args)
    if IsValid(ply) and not ply:IsAdmin() then return end
    local mode = args[1] or (LC.CityDark and "auto" or "on")
    LC.ForceBlackout(mode)
    local msg = "[Living City] City-wide blackout: " .. (LC.CityDark and "ON" or "off") .. (LC.ForcedDark == nil and " (following the grid)" or " (forced)")
    if IsValid(ply) then ply:ChatPrint(msg) else print(msg) end
end)

-- Fixtures placed or moved, transformers added or taken away.
hook.Add("LivingCityLayoutChanged", "LivingCityPower", function()
    timer.Simple(0.5, function() LC.RefreshPower() LC.CheckCityGrid() end)
end)

function LC.TransformerDown(t, by, how)
    if not IsValid(t) or t:GetNW2Bool("lc_down", false) then return false end
    t:SetNW2Bool("lc_down", true)
    t.lcDownAt = CurTime()
    t.lcBrokenAt = CurTime()
    t:EmitSound("ambient/energy/zap9.wav", 85)
    timer.Simple(0.3, function() if IsValid(t) then t:EmitSound("ambient/energy/powerdown2.wav", 80) end end)
    if EffectData then
        local fx = EffectData()
        fx:SetOrigin(t:WorldSpaceCenter())
        util.Effect("Sparks", fx, true, true)
    end
    LC.RefreshPower()
    LC.CheckCityGrid()
    local where = Where(t:GetPos())
    for _, u in ipairs(Units()) do
        u:ChatPrint("[CP net] Power failure " .. where .. ". The district's Combine locks are dead and its forcefields are down. Secure it.")
    end
    if LC.RadioNotice then LC.RadioNotice("resistance", "The grid's down " .. where .. ". Their doors are open, for now.") end
    for _, p in ipairs(player.GetAll()) do
        if p:GetNW2String("lcj_job", "") == "maintenance" then p:ChatPrint("[Union] Power failure " .. where .. ". Get the transformer back up (E on it).") end
    end
    if IsValid(by) and by:IsPlayer() then
        if LC.SeenBySecurity and LC.SeenBySecurity(by, 900) and not LC.PlayerIsCP(by) then LC.ReportCrime(by, "Sabotage", 300) end
        if by:GetNW2String("lcf_faction", "") == "resistance" and LC.AddXP then LC.AddXP(by, 25, "the grid") end
    end
    hook.Run("LivingCityPowerDown", t, by, how)
    return true
end

function LC.TransformerRestore(t, by)
    if not IsValid(t) or not t:GetNW2Bool("lc_down", false) then return false end
    t:SetNW2Bool("lc_down", false)
    t:EmitSound("ambient/machines/thumper_startup1.wav", 75)
    LC.RefreshPower()
    LC.CheckCityGrid()
    local where = Where(t:GetPos())
    for _, u in ipairs(Units()) do u:ChatPrint("[CP net] Power restored " .. where .. ".") end
    hook.Run("LivingCityPowerRestored", t, by)
    return true
end

-- E on a transformer: a maintenance technician fixes it.
function LC.UseTransformer(ply, t)
    if not t:GetNW2Bool("lc_down", false) then return false, "It hums. The district has power." end
    if ply:GetNW2String("lcj_job", "") ~= "maintenance" then
        return false, "Dead, and sparking. You don't know the first thing about it: Maintenance Technicians repair these."
    end
    return LC.StartTask(ply, 10, "Rewiring the transformer...", {
        maxMove = 60, cancelText = "You leave it half rewired.",
        done = function(p)
            if not IsValid(t) or not LC.TransformerRestore(t, p) then return end
            if LC.AddCredits then LC.AddCredits(p, 15, "power restored") end
            if LC.AddStanding then LC.AddStanding(p, 5) end
            p:ChatPrint("[Union] The district has power again.")
        end,
    })
end

-- A multitool: twelve seconds, and the district goes dark.
function LC.SabotageTransformer(ply, t)
    if not LC.CanHack or not LC.CanHack(ply) then return false, "You need a multitool." end
    if not IsValid(t) or t:GetClass() ~= "lc_transformer" then return false, "Look at a transformer." end
    if t:GetNW2Bool("lc_down", false) then return false, "It's already dead." end
    return LC.StartTask(ply, 12, "Shorting the transformer... keep at it", {
        maxMove = 40, cancelText = "You pull back before it blows.",
        done = function(p) if IsValid(t) then LC.TransformerDown(t, p, "sabotage") end end,
    })
end

-- Forcefields
function LC.ShortForcefield(ply, f)
    if not LC.CanHack or not LC.CanHack(ply) then return false, "You need a multitool." end
    if not IsValid(f) or f:GetClass() ~= "lc_forcefield" then return false, "Look at a forcefield." end
    return LC.StartTask(ply, 6, "Shorting the forcefield...", {
        maxMove = 40, cancelText = "The field snaps back.",
        done = function(p)
            if not IsValid(f) then return end
            f:SetNW2Float("lc_short_until", CurTime() + 60)
            LC.FieldRulesChanged(f)
            timer.Simple(60.05, function() LC.FieldRulesChanged(f) end) -- (and again when it comes back)
            f:EmitSound("ambient/energy/zap1.wav", 75)
            if LC.SeenBySecurity and LC.SeenBySecurity(p, 900) then LC.ReportCrime(p, "Sabotage", 180) end
            hook.Run("LivingCityFieldShorted", f, p)
        end,
    })
end

function LC.SwipeForcefield(ply, f)
    if f:GetNW2Bool("lc_ff_broken", false) and LC.RepairForcefield then return LC.RepairForcefield(ply, f) end
    if LC.FieldPass(ply) then return true end
    if not (LC.HasItem and LC.HasItem(ply, "cp_keycard")) then
        f:EmitSound("buttons/combine_button_locked.wav", 65)
        return false, "Access denied. (Civil Protection units pass; a Combine keycard opens it for a moment.)"
    end
    ply:SetNW2Float("lc_ffpass_until", CurTime() + 4)
    LC.FieldRulesChanged(ply)
    timer.Simple(4.05, function() LC.FieldRulesChanged(ply) end)
    f:EmitSound("buttons/combine_button1.wav", 65)
    if LC.SeenBySecurity and LC.SeenBySecurity(ply, 700) and not LC.PlayerIsCP(ply) and not (LC.DisguisedAsCP and LC.DisguisedAsCP(ply)) then
        LC.ReportCrime(ply, "Unauthorized access", 120)
    end
    return true
end

-- Nobody gets stuck inside one. A field that comes up (power back, a short
-- running out, a pass expiring) around someone it wouldn't let through gives
-- them a moment to step out, whichever side they choose.
local function InsideField(f, p)
    local l = f:WorldToLocal(p:GetPos())
    local t, w, h = f.Thick or 4, f.HalfWidth or 64, f.Height or 112
    -- (a player's hull is 32 wide and 72 tall; pressed against it doesn't count)
    return math.abs(l.x) < t + 14 and math.abs(l.y) < w + 14 and l.z > -70 and l.z < h
end
LC.InsideField = InsideField

function LC.FieldUnstick()
    local fields = LC.EntsOf("lc_forcefield")
    if #fields == 0 then return end
    local plys = player.GetAll()
    for _, f in ipairs(fields) do
        if f.FieldUp and f:FieldUp() then
            local c = f:GetPos()
            for _, p in ipairs(plys) do
                if p:Alive() and p:GetPos():DistToSqr(c) < 260 * 260 and not LC.FieldPass(p) and InsideField(f, p) then
                    p:SetNW2Float("lc_ffpass_until", CurTime() + 0.5)
                    LC.FieldRulesChanged(p)
                    timer.Simple(0.55, function() LC.FieldRulesChanged(p) end)
                end
            end
        end
    end
end
timer.Create("LivingCityFieldUnstick", 0.25, 0, function()
    local ok, err = pcall(LC.FieldUnstick)
    if not ok and LC.Error then LC.Error("forcefield", err) end
end)

-- Emergency crews, eventually.
timer.Create("LivingCityPower", 10, 0, function()
    local now = CurTime()
    for _, t in ipairs(LC.EntsOf("lc_transformer")) do
        if t:GetNW2Bool("lc_down", false) and now - (t.lcDownAt or now) > cvOutage:GetFloat() * 60 then
            LC.TransformerRestore(t, nil)
            for _, p in ipairs(player.GetAll()) do p:ChatPrint("[City] Emergency crews have restored power " .. Where(t:GetPos()) .. ".") end
        end
    end
end)

-- The city's own maintenance crews see to it too (after the players have had their chance).
if LC.AddNPCTask then
    LC.AddNPCTask("maintenance", { id = "power", label = "restoring power", urgent = true, find = function(npc, st, now)
        local grace = LC.NPCWorkGrace and LC.NPCWorkGrace("maintenance") or 60
        local best, bd
        for _, t in ipairs(LC.EntsOf("lc_transformer")) do
            if t:GetNW2Bool("lc_down", false) and now - (t.lcDownAt or now) >= grace and not (LC.NPCWorkClaimed and LC.NPCWorkClaimed("power" .. t:EntIndex())) then
                local d = t:GetPos():DistToSqr(npc:GetPos())
                if d < 5000 * 5000 and (not bd or d < bd) then best, bd = t, d end
            end
        end
        if not best then return nil end
        local t = best
        return { key = "power" .. t:EntIndex(), steps = {
            { pos = function(n) return LC.NPCWorkBeside(t:GetPos(), n:GetPos(), 60) end, face = function() return t:WorldSpaceCenter() end,
              check = function() return IsValid(t) and t:GetNW2Bool("lc_down", false) end,
              secs = 12, anim = { "ACT_PICKUP_RACK", "ACT_PICKUP_GROUND" },
              sound = { "ambient/energy/spark1.wav", "ambient/energy/spark2.wav", "ambient/energy/spark3.wav" }, doing = "restoring power",
              done = function(n) LC.TransformerRestore(t, n) end },
        } }
    end })
end
