--[[
    Living City: IEDs (homemade bombs set on the ground and blown by hand)

      The owner, 20 November: "the resistance to sabotage the train by having
      IEDs on the tracks that can be set and blown up (a SWEP for IED
      detonator would be neat) that a player can use to manually blow up the
      train, which derails it and wrecks the tracks where exploded, causing a
      problem with supplies ... the combine need to go out and repair it";
      then: "they should be useable on the roads as well as the train tracks".

      The item   "ied", made at the lab (2 weedkiller, 3 scrap, 1 gun parts),
                 contraband. Carrying one hands you the Detonator
                 (weapon_lc_ied); it goes when you have none left and none set.
      Setting    Left click: one is set on the ground you are looking at
                 (within reach). Up to lc_ied_max (3) of yours at once. It is
                 live after lc_ied_arm (2) seconds.
      Blowing    Right click: every one of yours that is live goes off, each
                 a blast of lc_ied_damage (220) over lc_ied_radius (320).
                 Anywhere: a road, a doorway, the tracks. One that is shot
                 goes off too. A Civil Protection or Overwatch unit who
                 presses E at one takes it apart.
      The tracks A blast within lc_ied_track (260) of a train's rails wrecks
                 them: that train's timetable stops, a train passing within
                 600 is stopped where it is, and rubble marks the place. No
                 train runs there (LC.TracksWrecked()) until a unit presses E
                 at the rubble and finishes the rewiring game: then the train
                 is put back and the timetable starts again.

      The rails are the map's own: every func_tracktrain named lc_train_N
      between its path_tracks lc_train_N_p1 and _p2 (map_corridor.py). A map
      with none has IEDs all the same, for roads and doors.

      Hooks: LivingCityIED(pos, by), LivingCityTracksWrecked(name, pos, by),
      LivingCityTracksRepaired(name, by). Nothing is taken from the city's
      supplies yet: what a cut line costs is for the owner to say.
]]

if CLIENT then return end

LC = LC or {}
LC.IED = LC.IED or {}
local I = LC.IED

local FLAGS = bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED)
local cvMax = CreateConVar("lc_ied_max", "3", FLAGS, "How many IEDs one player may have set at once", 1, 20)
local cvArm = CreateConVar("lc_ied_arm", "2", FLAGS, "Seconds after it is set before an IED can be blown", 0, 60)
local cvRadius = CreateConVar("lc_ied_radius", "320", FLAGS, "How far an IED's blast reaches", 50, 2000)
local cvDamage = CreateConVar("lc_ied_damage", "220", FLAGS, "An IED's damage at its middle", 1, 5000)
local cvTrack = CreateConVar("lc_ied_track", "260", FLAGS, "How near a train's rails an IED's blast wrecks them", 10, 2000)

local MODEL = "models/props_junk/propane_tank001a.mdl"
local RUBBLE = "models/props_debris/broken_pile001a.mdl"
I.set = I.set or {}          -- every IED on the ground
I.wrecks = I.wrecks or {}    -- [train's name] = { pos, marker, by, derailed }

local function Unit(p)
    local f = IsValid(p) and p.GetNW2String and p:GetNW2String("lcf_faction", "") or ""
    return (f == "cp" or f == "ota") and (not p.Alive or p:Alive())
end
local function Mine(ply)
    local out = {}
    for _, e in ipairs(I.set) do if IsValid(e) and e.lcOwner == ply then out[#out + 1] = e end end
    return out
end

-- The Detonator is in your hands while you carry an IED or have one set.
function LC.IEDSync(ply)
    if not (IsValid(ply) and ply.HasWeapon) then return end
    local want = (LC.HasItem and LC.HasItem(ply, "ied")) or #Mine(ply) > 0
    if want and not ply:HasWeapon("weapon_lc_ied") then
        ply:Give("weapon_lc_ied")
    elseif not want and ply:HasWeapon("weapon_lc_ied") then
        ply:StripWeapon("weapon_lc_ied")
    end
end

function LC.IEDPlant(ply)
    if not (IsValid(ply) and (not ply.Alive or ply:Alive())) then return false end
    if not (LC.HasItem and LC.HasItem(ply, "ied")) then return false, "No IED to set." end
    if #Mine(ply) >= cvMax:GetInt() then return false, "That is all you can keep track of." end
    local from = ply.EyePos and ply:EyePos() or ply:GetPos() + Vector(0, 0, 64)
    local tr = util.TraceLine({ start = from, endpos = from + ply:GetAimVector() * 130, filter = ply })
    if not (tr and tr.Hit and tr.HitPos) or (tr.HitNormal and tr.HitNormal.z < 0.6) then return false, "Set it on the ground in front of you." end
    local e = ents.Create("prop_physics")
    if not IsValid(e) then return false end
    e:SetModel(MODEL)
    e:SetPos(tr.HitPos + Vector(0, 0, 6))
    e:SetAngles(Angle(90, math.random(0, 359), 0))
    e:Spawn()
    local phys = e.GetPhysicsObject and e:GetPhysicsObject()
    if IsValid(phys) then phys:EnableMotion(false) end
    e.lcIED, e.lcOwner, e.lcArmAt, e.lcDressing = true, ply, CurTime() + cvArm:GetFloat(), true
    I.set[#I.set + 1] = e
    LC.TakeItem(ply, "ied", 1)
    if ply.EmitSound then ply:EmitSound("weapons/slam/mine_mode.wav", 55) end
    return true
end

-- How far a point is from the stretch of rail between a and b, and the nearest place on it.
local function ToRail(p, a, b)
    local ab = b - a
    local len2 = ab:LengthSqr()
    local t = len2 > 0 and math.Clamp((p - a):Dot(ab) / len2, 0, 1) or 0
    local at = a + ab * t
    return at:Distance(p), at
end

-- Every train's rails on this map: { name, a, b, train }.
function I.Rails()
    local out = {}
    for _, tr in ipairs(ents.FindByClass and ents.FindByClass("func_tracktrain") or {}) do
        local name = IsValid(tr) and tr.GetName and tr:GetName() or ""
        if string.sub(name, 1, 9) == "lc_train_" then
            local a, b = ents.FindByName(name .. "_p1")[1], ents.FindByName(name .. "_p2")[1]
            if IsValid(a) and IsValid(b) then out[#out + 1] = { name = name, a = a:GetPos(), b = b:GetPos(), train = tr } end
        end
    end
    return out
end

local function Fire(name, input, value)
    for _, e in ipairs(ents.FindByName and ents.FindByName(name) or {}) do
        if IsValid(e) and e.Fire then e:Fire(input, value or "", 0) end
    end
end

function LC.TracksWrecked(name)
    if name then return I.wrecks[name] ~= nil end
    return next(I.wrecks) ~= nil
end

function I.Wreck(rail, at, by)
    if I.wrecks[rail.name] then return false end
    local w = { pos = at, by = by, derailed = false }
    Fire(rail.name .. "_timer", "Disable")
    if IsValid(rail.train) and rail.train:GetPos():Distance(at) <= 600 then
        w.derailed = true
        if rail.train.Fire then rail.train:Fire("Stop", "", 0) end
        Fire(rail.name .. "_hurt", "Disable")
    end
    local m = ents.Create("prop_physics")
    if IsValid(m) then
        m:SetModel(RUBBLE)
        m:SetPos(at)
        m:Spawn()
        local phys = m.GetPhysicsObject and m:GetPhysicsObject()
        if IsValid(phys) then phys:EnableMotion(false) end
        m.lcTrackWreck, m.lcDressing = rail.name, true
        w.marker = m
    end
    I.wrecks[rail.name] = w
    SetGlobal2Bool("lc_tracks_wrecked", true)
    hook.Run("LivingCityTracksWrecked", rail.name, at, by)
    if LC.Log then LC.Log("info", "The tracks were blown (" .. rail.name .. ")") end
    return true
end

function I.Repair(name, by)
    local w = I.wrecks[name]
    if not w then return false end
    if IsValid(w.marker) then w.marker:Remove() end
    I.wrecks[name] = nil
    if w.derailed then
        Fire(name, "TeleportToPathTrack", name .. "_p1")
        Fire(name, "Stop")
    end
    Fire(name .. "_timer", "Enable")
    SetGlobal2Bool("lc_tracks_wrecked", next(I.wrecks) ~= nil)
    hook.Run("LivingCityTracksRepaired", name, by)
    if LC.Log then LC.Log("info", "The tracks were mended (" .. name .. ")") end
    return true
end

function I.Blow(e, by)
    if not IsValid(e) then return false end
    local pos = e:GetPos()
    for k, x in ipairs(I.set) do if x == e then table.remove(I.set, k) break end end
    e.lcIED = nil
    e:Remove()
    if util.Effect and EffectData then
        local ed = EffectData()
        ed:SetOrigin(pos)
        util.Effect("Explosion", ed, true, true)
    end
    if sound and sound.Play then sound.Play("ambient/explosions/explode_4.wav", pos, 110, 100, 1) end
    local who = IsValid(by) and by or game.GetWorld()
    if util.BlastDamage then util.BlastDamage(who, who, pos, cvRadius:GetFloat(), cvDamage:GetFloat()) end
    if util.ScreenShake then util.ScreenShake(pos, 12, 40, 1.2, cvRadius:GetFloat() * 3) end
    hook.Run("LivingCityIED", pos, by)
    for _, rail in ipairs(I.Rails()) do
        local d, at = ToRail(pos, rail.a, rail.b)
        if d <= cvTrack:GetFloat() then I.Wreck(rail, at, by) end
    end
    return true
end

function LC.IEDDetonate(ply)
    local mine, n, waiting = Mine(ply), 0, false
    if #mine == 0 then return false, "Nothing set." end
    for _, e in ipairs(mine) do
        if CurTime() >= (e.lcArmAt or 0) then
            if I.Blow(e, ply) then n = n + 1 end
        else
            waiting = true
        end
    end
    if n == 0 and waiting then return false, "Not live yet." end
    return n > 0
end

-- One that is shot goes off.
hook.Add("EntityTakeDamage", "LivingCityIED", function(ent, dmg)
    if IsValid(ent) and ent.lcIED and CurTime() >= (ent.lcArmAt or 0) and dmg and dmg.GetDamage and dmg:GetDamage() >= 5 then
        local by = dmg.GetAttacker and dmg:GetAttacker() or nil
        timer.Simple(0, function() I.Blow(ent, IsValid(by) and by:IsPlayer() and by or ent.lcOwner) end)
    end
end)

-- A unit's E: takes an IED apart, or starts mending the tracks at the rubble (the rewiring game, never a wait).
function LC.IEDUnitUse(ply)
    if not Unit(ply) then return false end
    local at = ply:GetPos()
    for k, e in ipairs(I.set) do
        if IsValid(e) and e:GetPos():DistToSqr(at) <= 70 * 70 then
            table.remove(I.set, k)
            e:Remove()
            hook.Run("LivingCityIEDDisarmed", ply)
            return true
        end
    end
    for name, w in pairs(I.wrecks) do
        if w.pos:DistToSqr(at) <= 130 * 130 then
            if LC.JobGames and LC.JobGames[ply] then return false end
            if LC.JobGameStart and LC.JobGameStart(ply, "wiring", nil, { what = "the signal box", pos = w.pos, lcTrack = name }) then return true end
            return I.Repair(name, ply)      -- (a server with the job games off: mended at once)
        end
    end
    return false
end
hook.Add("KeyPress", "LivingCityIED", function(ply, key)
    if key == IN_USE then LC.IEDUnitUse(ply) end
end)
-- The rewiring game finished at the rubble: the tracks are mended.
if LC.JobGameEnd and not I.wrapped then
    I.wrapped = true
    local endWas = LC.JobGameEnd
    function LC.JobGameEnd(ply, how)
        local g = LC.JobGames and LC.JobGames[ply]
        local name = g and g.opts and g.opts.lcTrack
        local r = endWas(ply, how)
        if name and (how == "done" or how == "test") then I.Repair(name, ply) end
        return r
    end
end

timer.Create("LivingCityIED", 2, 0, function()
    local ok, err = LC.Try(function()
        for k = #I.set, 1, -1 do if not IsValid(I.set[k]) then table.remove(I.set, k) end end
        for _, p in ipairs(player.GetAll()) do LC.IEDSync(p) end
    end)
    if not ok and LC.Error then LC.Error("IEDs", err) end
end)

local function Clear()
    for _, e in ipairs(I.set) do if IsValid(e) then e:Remove() end end
    for _, w in pairs(I.wrecks) do if IsValid(w.marker) then w.marker:Remove() end end
    I.set, I.wrecks = {}, {}
    SetGlobal2Bool("lc_tracks_wrecked", false)
end
hook.Add("LivingCityStopped", "LivingCityIED", Clear)
function I.Reset() Clear() end
