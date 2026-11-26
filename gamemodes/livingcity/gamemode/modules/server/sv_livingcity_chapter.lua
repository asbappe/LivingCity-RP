--[[
    Living City: a chapter, "the city falls to the Resistance" (the owner, 25 November, about the rocket in the
    Resistance's silo: "not necessarily a secret ending, but an ending of sorts; maybe a 'chapter' would be the
    better answer ... some sort of targetted explosion over the city that explodes in a massive energy effect/wave
    ... that kills all the combine and disables all their equipment, turrets, shields/forcefields, etc. which would
    allow the resistance to just walk in and take over ... the combine would need somewhere to respawn where they
    could setup base and act as a role reversal ... maybe their arrest batons stop working or something? Their vests
    won't charge and their masks are glitchy and they can't see through them and they have to take them off? it's
    like a targetted EMP towards combine technology ... and all combine doors forceably open and stay open until the
    role reversal is reversed and the combine regain control").

    Not a secret ending: no vote, no time stop, no map reload. A lasting state of the city, kept over restarts
    (data/livingcity/<map>_chapter.json), until the Combine take the city back. docs/features/chapter-city-falls.md.

      The launch   the map's relay lc_rocket_launch is triggered when the silo's red button is pressed
                   (_dev/tools/map_launch.py): 30 s of countdown, then the rocket's climb. With lc_chapter 1 (0 by
                   default) and a Resistance Lieutenant or Commander at the button, the wave comes LC.Chapter.CLIMB
                   seconds after the rocket rises. Staff start and end it whatever the setting: F4 > Factions >
                   Admin: testing tools > The city.
      The wave     a burst over the city and a wave over the whole map (cl_livingcity_chapter.lua): no words. At
                   once every Combine NPC and every Civil Protection and Overwatch player dies, the Combine's
                   machines go dead and every Combine door opens and stays open.
      Reversed     LC.ChapterReversed(): no Combine NPC comes out, the PA is silent, no city event starts, a
                   Combine-only zone is nobody's to trespass in, the districts are the Resistance's. A unit's baton
                   does nothing, its vest holds no charge, its mask glitches until taken off (F2). Units come back
                   at a "choldout" point (the editor), or at the Resistance's old spawn points with none placed,
                   and then the Resistance at the units'.
      The retake   after lc_chapter_hold_minutes: Combine players holding the Nexus (the Combine-only zone with
                   the Administrator's desk) for LC.Chapter.RETAKE_SECS against waves of fighters. The clock runs
                   only while a living unit stands in it. Then everything comes back, and the chapter cannot start
                   again for lc_chapter_cooldown_minutes.

    For other code: LC.ChapterReversed(); hooks LivingCityChapterBegan(why, by) and LivingCityChapterEnded(why).
]]

if CLIENT then return end

LC = LC or {}
LC.Chapter = LC.Chapter or {}
local C = LC.Chapter

local FLAGS = bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED)
local cvOn   = CreateConVar("lc_chapter", "0", FLAGS, "The rocket launched from the Resistance's silo by a Lieutenant or Commander brings the chapter 'the city falls to the Resistance' (staff can start and end it whatever this says)")
local cvHold = CreateConVar("lc_chapter_hold_minutes", "60", FLAGS, "Minutes the city stays the Resistance's before the Combine can take the Nexus back")
local cvCool = CreateConVar("lc_chapter_cooldown_minutes", "120", FLAGS, "Minutes after the Combine take the city back before the chapter can start again")

util.AddNetworkString("lc_chapter_wave")

C.RELAY = "lc_rocket_launch"   -- the map's launch relay (the red button triggers it)
C.COUNTDOWN = 30               -- the map's countdown before the rocket rises
C.CLIMB = 25                   -- then its climb, to the burst
C.WAVE_SECS = 6                -- the wave rolling out over the map
C.WAVE_RADIUS = 46000
C.RETAKE_SECS = 480            -- the Nexus held this long takes the city back
C.WAVE_GAPS = { 70, 50, 40, 25 } -- the fighters' waves, each sooner than the last (then every 25 s)
C.KEEP_EVERY = 20              -- doors and machines are looked at again this often

local UNIT = { cp = true }     -- Civil Protection and Overwatch (Overwatch is its top ranks)
local ROLES = { cop = true, soldier = true, scanner = true }
-- what dies with the wave, by class (whoever made them), and what only goes dead and comes back with the Combine
local DIES = { "npc_metropolice", "npc_combine_s", "npc_cscanner", "npc_clawscanner", "npc_manhack", "npc_rollermine", "npc_hunter",
    "npc_strider", "npc_combinegunship", "npc_helicopter", "npc_combinedropship", "npc_sniper" }
local GOES_DEAD = { "npc_turret_floor", "npc_turret_ceiling", "npc_turret_ground", "npc_combine_camera" }
local ENDS_ITSELF = { npc_strider = "Explode", npc_combinegunship = "SelfDestruct", npc_helicopter = "SelfDestruct", npc_rollermine = "InteractivePowerDown" }
local DEAD_FIXTURES = { lc_powerbank = true, lc_forcefield = true, lc_monitor = true, lc_screen = true, lc_loudspeaker = true }
local DOOR_CLASSES = { "prop_door_rotating", "func_door", "func_door_rotating", "func_movelinear" }
local COMBINE_DOOR = { cp = true, prison = true, office = true }

------------------------------------------------------------------------
-- The state, kept over restarts
------------------------------------------------------------------------

local function File() return "livingcity/" .. game.GetMap() .. "_chapter.json" end
local function Fresh() return { state = "normal", elapsed = 0, cooldown = 0, lock = false } end

local function Load()
    local s = Fresh()
    local t = LC.SafeReadJSON and LC.SafeReadJSON(File())
    if istable(t) then
        s.state = t.state == "reversed" and "reversed" or "normal"
        s.elapsed = math.max(0, tonumber(t.elapsed) or 0)
        s.cooldown = math.max(0, tonumber(t.cooldown) or 0)
        s.lock = t.lock == true
    end
    return s
end
C.S = C.S or Load()
C.maskOff = C.maskOff or {} -- [player] = true: took the mask off (until the chapter ends)

function LC.ChapterSave()
    if not file or not file.Write then return end
    if file.CreateDir then file.CreateDir("livingcity") end
    local s = C.S
    if LC.SafeWrite then LC.SafeWrite(File(), util.TableToJSON({ state = s.state, elapsed = math.floor(s.elapsed), cooldown = math.floor(s.cooldown), lock = s.lock }, true)) end
end

function LC.ChapterReversed() return C.S ~= nil and C.S.state == "reversed" end

function LC.ChapterIsUnit(ply)
    return IsValid(ply) and ply:IsPlayer() and UNIT[ply:GetNW2String("lcf_faction", "")] == true
end

-- What staff see on the testing tools.
function LC.ChapterStatus()
    local s = C.S
    local line
    if s.state == "reversed" then
        local left = math.max(0, cvHold:GetFloat() * 60 - s.elapsed)
        line = "The city is the Resistance's. " .. (C.retake and string.format("The Nexus is being held: %d of %d s.", math.floor(C.retake.prog), C.RETAKE_SECS)
            or (left > 0 and string.format("The Combine can take the Nexus back in %d min.", math.ceil(left / 60)) or "The Combine can take the Nexus back now."))
    elseif C.pendingAt then
        line = string.format("The rocket is on its way: the wave in %d s.", math.max(0, math.ceil(C.pendingAt - CurTime())))
    else
        line = "The city is the Combine's." .. (s.cooldown > 0 and string.format(" The chapter can start again in %d min.", math.ceil(s.cooldown / 60)) or "")
            .. (cvOn:GetBool() and "" or " (lc_chapter is 0: the launch alone does not start it.)")
    end
    return { state = s.state, lock = s.lock, line = line .. (s.lock and " Locked." or "") }
end

------------------------------------------------------------------------
-- What the wave kills
------------------------------------------------------------------------

function LC.ChapterCombineNPCs()
    local out, seen = {}, {}
    local function Add(e) if IsValid(e) and not seen[e] then seen[e] = true out[#out + 1] = e end end
    for npc, st in pairs(LC.NPCs or {}) do if ROLES[st.role] then Add(npc) end end
    for _, cls in ipairs(DIES) do for _, e in ipairs(ents.FindByClass(cls)) do Add(e) end end
    return out
end

local function Slay(npc)
    npc.lcChapterSlain = true
    local own = ENDS_ITSELF[npc:GetClass()]
    if own and npc.Fire then npc:Fire(own) end
    local hp = (npc.Health and npc:Health() or 0) + 1000
    local world = game.GetWorld and game.GetWorld() or nil
    if DamageInfo and npc.TakeDamageInfo then
        local d = DamageInfo()
        d:SetDamage(hp)
        d:SetDamageType(bit.bor(DMG_SHOCK or 256, DMG_DISSOLVE or 67108864)) -- (they go as a Combine ball's victims go)
        if IsValid(world) then d:SetAttacker(world) d:SetInflictor(world) end
        d:SetDamagePosition(npc:WorldSpaceCenter())
        npc:TakeDamageInfo(d)
    elseif npc.TakeDamage then
        npc:TakeDamage(hp, world, world)
    end
end

-- Every Combine NPC, and every unit. Returns how many of each.
function LC.ChapterKill()
    local npcs, units = 0, 0
    local slain = LC.ChapterCombineNPCs()
    for _, npc in ipairs(slain) do
        if LC.Try(Slay, npc) then npcs = npcs + 1 end
    end
    for npc, r in pairs(LC.Cremators or {}) do
        if IsValid(npc) and LC.CrematorDie then LC.Try(LC.CrematorDie, r) npcs = npcs + 1 end
    end
    -- (what will not die of it, or only lies there: gone a moment later)
    timer.Simple(4, function()
        for _, npc in ipairs(slain) do if IsValid(npc) then LC.Try(npc.Remove, npc) end end
    end)
    for _, p in ipairs(player.GetAll()) do
        if p:Alive() and not p:GetNW2Bool("lc_build", false) then
            if LC.ChapterIsUnit(p) then
                -- (no character ends with the wave: they come back as the units they were, at their holdout)
                local was = p.lcNoPermadeath
                p.lcNoPermadeath = true
                p:Kill()
                p.lcNoPermadeath = was
                units = units + 1
            elseif LC.IsAdministrator and LC.IsAdministrator(p) and p.SetArmor then
                p:SetArmor(0) -- (she is no machine: she lives, without her guards and her vest's charge)
            end
        end
    end
    return npcs, units
end

------------------------------------------------------------------------
-- The Combine's machines and doors
------------------------------------------------------------------------

-- (sv_livingcity_power.lua asks this for every fixture it lights)
function LC.ChapterDeadTech(e)
    return LC.ChapterReversed() and IsValid(e) and DEAD_FIXTURES[e:GetClass()] == true
end

function LC.ChapterMachines()
    local off = LC.ChapterReversed()
    local n = 0
    for _, cls in ipairs(GOES_DEAD) do
        for _, e in ipairs(ents.FindByClass(cls)) do
            if IsValid(e) and e.Fire then
                if off and not e.lcChapterOff then
                    e.lcChapterOff = true
                    e:Fire("Disable")
                    n = n + 1
                elseif not off and e.lcChapterOff then
                    e.lcChapterOff = nil
                    e.lcPowered = nil -- (a checkpoint's turret: its power decides again, sv_livingcity_checkpoints.lua)
                    if not (LC.IsCheckpointTurret and LC.IsCheckpointTurret(e)) then e:Fire("Enable") end
                    n = n + 1
                end
            end
        end
    end
    if off then
        -- nobody flies a scanner or mans a mounted gun
        for p in pairs(LC.ScannerLinks or {}) do if IsValid(p) and LC.EndScannerLink then LC.Try(LC.EndScannerLink, p, "chapter") end end
        for _, p in pairs(LC.Turret and LC.Turret.Gunners or {}) do if IsValid(p) and LC.TurretRelease then LC.Try(LC.TurretRelease, p, "chapter") end end
    end
    if LC.RefreshPower then LC.Try(LC.RefreshPower) end
    if LC.CheckpointTick then LC.Try(LC.CheckpointTick, CurTime()) end
    return n
end

-- Every Combine door: open, and locked open. Looked at again on a slow timer, so one the map shuts opens again.
function LC.ChapterDoorsOpen()
    local n = 0
    for _, cls in ipairs(DOOR_CLASSES) do
        for _, door in ipairs(ents.FindByClass(cls)) do
            if IsValid(door) and door.Fire and (door.lcChapterOpen or COMBINE_DOOR[LC.EffectiveDoorTag and LC.EffectiveDoorTag(door) or ""]) then
                if not door.lcChapterOpen or (LC.DoorIsOpen and LC.DoorIsOpen(door) == false) then
                    door.lcChapterOpen, door.lcHeldOpen = true, true
                    if LC.OpenedDoors then LC.OpenedDoors[door] = nil end
                    if LC.Relock then LC.Relock[door] = nil end
                    if LC.PrisonDoors then LC.PrisonDoors[door] = nil end
                    if LC.DoorHoldOpen then LC.DoorHoldOpen(door, true) end -- (it does not swing back by itself)
                    door:Fire("Unlock")
                    door:Fire("Open", "", 0.1)
                    door:Fire("Lock", "", 1.5) -- (in the open position: E won't shut it)
                    n = n + 1
                end
            end
        end
    end
    return n
end

function LC.ChapterDoorsRelease()
    local n = 0
    for _, cls in ipairs(DOOR_CLASSES) do
        for _, door in ipairs(ents.FindByClass(cls)) do
            if IsValid(door) and door.lcChapterOpen then
                door.lcChapterOpen, door.lcHeldOpen = nil, nil
                if LC.DoorHoldOpen then LC.DoorHoldOpen(door, false) end
                if door.Fire then door:Fire("Unlock") end
                if LC.ApplyDoorState then LC.ApplyDoorState(door) end -- (shut and locked again, as its tag says)
                n = n + 1
            end
        end
    end
    return n
end

------------------------------------------------------------------------
-- The city's ledger
------------------------------------------------------------------------

local function LedgerTo(what, target, why)
    local s = LC.Ledger and LC.Ledger()
    if not (s and s[what] and LC.LedgerAdd) then return end
    LC.LedgerAdd(what, target - s[what], why)
end

local function Districts(control)
    local s = LC.Ledger and LC.Ledger()
    if not s then return end
    s.crackdown, s.liberated = {}, {}
    for _, n in ipairs(LC.BlockNumbers and LC.BlockNumbers() or {}) do s.districts[tostring(n)] = control end
end

------------------------------------------------------------------------
-- It begins, it ends
------------------------------------------------------------------------

local function Flags()
    local on = LC.ChapterReversed()
    SetGlobal2Bool("lc_chapter", on)
    for _, p in ipairs(player.GetAll()) do
        local mask = on and LC.ChapterIsUnit(p) and not C.maskOff[p]
        if p:GetNW2Bool("lc_chapter_mask", false) ~= mask then p:SetNW2Bool("lc_chapter_mask", mask) end
    end
end

-- The world as the state says (the wave, a restart, the map cleaned up).
function LC.ChapterApply()
    Flags()
    if LC.ChapterReversed() then LC.ChapterDoorsOpen() else LC.ChapterDoorsRelease() end
    LC.ChapterMachines()
end

function LC.ChapterBegin(why, by)
    local s = C.S
    if s.state == "reversed" then return false end
    s.state, s.elapsed, s.cooldown = "reversed", 0, 0
    C.pendingAt, C.pendingBy, C.retake = nil, nil, nil
    C.maskOff = {}
    if LC.Event and LC.EndEvent then LC.Try(LC.EndEvent, true) end -- (no curfew, sweep or lockdown outlives the Combine)
    -- (each on its own: one that fails must not leave the rest undone)
    LC.Try(LC.ChapterKill)
    LC.Try(LC.ChapterApply)
    Districts(100)
    LedgerTo("combine", 3)
    LedgerTo("authority", 3)
    local led = LC.Ledger and LC.Ledger()
    if led then LedgerTo("resistance", math.min(100, (led.resistance or 50) + 40), "The city has fallen to the Resistance.") end
    if LC.RefreshSocio then LC.Try(LC.RefreshSocio, true) end
    LC.ChapterSave()
    if LC.Log then LC.Log("info", "chapter: the city falls to the Resistance (" .. tostring(why or "the launch") .. ")") end
    hook.Run("LivingCityChapterBegan", why or "launch", by)
    return true
end

function LC.ChapterEnd(why)
    local s = C.S
    if s.state ~= "reversed" then return false end
    s.state, s.elapsed = "normal", 0
    s.cooldown = math.max(0, cvCool:GetFloat()) * 60
    C.retake, C.maskOff = nil, {}
    LC.Try(LC.ChapterApply)
    Districts(0)
    LedgerTo("combine", 40)
    LedgerTo("authority", 30, "The Combine hold the city again.")
    if LC.RefreshSocio then LC.Try(LC.RefreshSocio, true) end
    LC.ChapterSave()
    if LC.Log then LC.Log("info", "chapter: the Combine have the city again (" .. tostring(why or "the Nexus held") .. ")") end
    hook.Run("LivingCityChapterEnded", why or "retaken")
    return true
end

------------------------------------------------------------------------
-- The launch and the wave
------------------------------------------------------------------------

-- High over the middle of the city: over the Nexus if the map has one, else over whoever is there.
function LC.ChapterBurstAt()
    local sum, n = Vector(0, 0, 0), 0
    for _, z in ipairs(LC.ChapterNexus and LC.ChapterNexus() or {}) do
        if z.pos then sum, n = sum + z.pos, n + 1 end
    end
    if n == 0 then for _, p in ipairs(player.GetAll()) do sum, n = sum + p:GetPos(), n + 1 end end
    local at = n > 0 and sum / n or Vector(0, 0, 0)
    local top = at + Vector(0, 0, 5000)
    if util.TraceLine then
        local tr = util.TraceLine({ start = at + Vector(0, 0, 72), endpos = at + Vector(0, 0, 12000), mask = MASK_SOLID_BRUSHONLY })
        if tr and tr.Hit and tr.HitPos then top = tr.HitPos - Vector(0, 0, 160) end
    end
    return top
end

-- The burst and the wave on every screen, and at once what it does. No words.
function LC.ChapterWave(by, why)
    if LC.ChapterReversed() then return false end
    local at = LC.ChapterBurstAt()
    net.Start("lc_chapter_wave")
    net.WriteVector(at)
    net.WriteFloat(C.WAVE_SECS)
    net.WriteFloat(C.WAVE_RADIUS)
    net.Broadcast()
    return LC.ChapterBegin(why or "launch", by)
end

-- May the launch start it? (Staff's own button asks nobody.)
function LC.ChapterMayStart(by)
    local s = C.S
    if not cvOn:GetBool() then return false, "off" end
    if s.lock then return false, "locked" end
    if s.state == "reversed" or C.pendingAt then return false, "already" end
    if s.cooldown > 0 then return false, "cooldown" end
    if not (IsValid(by) and by:IsPlayer() and LC.BaseMayLead and LC.BaseMayLead(by)) then return false, "rank" end
    return true
end

-- The red button pressed: the wave comes when the rocket has climbed.
function LC.ChapterLaunch(by)
    local ok, why = LC.ChapterMayStart(by)
    if not ok then return false, why end
    C.pendingAt, C.pendingBy = CurTime() + C.COUNTDOWN + C.CLIMB, by
    return true
end

hook.Add("AcceptInput", "LivingCityChapter", function(ent, input, activator, caller)
    if not IsValid(ent) or string.lower(input or "") ~= "trigger" then return end
    if (ent.GetName and ent:GetName() or "") ~= C.RELAY then return end
    local by = (IsValid(activator) and activator:IsPlayer() and activator) or (IsValid(caller) and caller:IsPlayer() and caller) or nil
    LC.Try(LC.ChapterLaunch, by)
end)

------------------------------------------------------------------------
-- A unit while the city is the Resistance's: the baton, the vest, the mask, where they come back
------------------------------------------------------------------------

function LC.ChapterVestDead(ply) return LC.ChapterReversed() and LC.ChapterIsUnit(ply) end
function LC.ChapterMaskOff(ply) return LC.ChapterVestDead(ply) and C.maskOff[ply] == true end

-- F2 > Take off the mask (cl_livingcity_quick.lua: only while it glitches)
LC.TargetActions = LC.TargetActions or {}
LC.TargetActions.chaptermask = function(ply)
    if not LC.ChapterVestDead(ply) or C.maskOff[ply] then return false end
    C.maskOff[ply] = true
    ply:SetNW2Bool("lc_chapter_mask", false)
    ply:EmitSound("npc/combine_soldier/gear" .. math.random(1, 6) .. ".wav", 60, 90)
    return true
end

hook.Add("PlayerCanPickupItem", "LivingCityChapter", function(ply, item)
    if IsValid(item) and item:GetClass() == "item_battery" and LC.ChapterVestDead(ply) then return false end
end)

local function UnitGround()
    local zones = LC.ZonesOfKind and LC.ZonesOfKind("combine") or {}
    local spot = #zones > 0 and LC.SpotInZone and LC.SpotInZone(zones[math.random(#zones)]) or nil
    if spot then return spot end
    local sup = LC.EntsOf and LC.EntsOf("lc_cpsupply") or {}
    local e = sup[math.random(math.max(1, #sup))]
    if IsValid(e) then return e:GetPos() + e:GetForward() * 70 end
end

-- Where they come back while the city is the Resistance's (sv_livingcity_factions.lua asks first): true when placed.
function LC.ChapterSpawn(ply)
    if not LC.ChapterReversed() or not IsValid(ply) or ply:GetNW2Bool("lc_build", false) then return false end
    local f = ply:GetNW2String("lcf_faction", "")
    local hold = LC.PointsOfKind and LC.PointsOfKind("choldout") or {}
    if UNIT[f] then
        local pts = #hold > 0 and hold or (LC.PointsOfKind and LC.PointsOfKind("rspawn") or {})
        if #pts == 0 then return false end
        ply:SetPos(pts[math.random(#pts)].pos + Vector(0, 0, 4))
        return true
    elseif f == "resistance" and #hold == 0 and not (LC.PlayerIsZombie and LC.PlayerIsZombie(ply)) then
        local spot = UnitGround()
        if not spot then return false end
        ply:SetPos(spot + Vector(0, 0, 4))
        return true
    end
    return false
end

------------------------------------------------------------------------
-- The Combine take it back: the Nexus held against waves
------------------------------------------------------------------------

-- The Combine-only zone with the Administrator's desk in it (her office, by its door, with no desk placed); a map
-- with neither: every Combine-only zone.
function LC.ChapterNexus()
    local zones = LC.ZonesOfKind and LC.ZonesOfKind("combine") or {}
    local out = {}
    local at = {}
    for _, p in ipairs(LC.PointsOfKind and LC.PointsOfKind("desk") or {}) do at[#at + 1] = p.pos end
    if #at == 0 and LC.CollapseOffice then
        local ok, p = LC.Try(LC.CollapseOffice)
        if ok and p then at[1] = p end
    end
    for _, z in ipairs(zones) do
        for _, p in ipairs(at) do
            if LCZ.Contains(z, p, 64) then out[#out + 1] = z break end
        end
    end
    return #out > 0 and out or zones
end

local function InNexus(pos, zones)
    for _, z in ipairs(zones) do if LCZ.Contains(z, pos) then return true end end
    return false
end

-- one line to each side, at the start and at the end (house rule 10: nothing else is said)
local function Tell(unitsText, rebelsText)
    for _, p in ipairs(player.GetAll()) do
        local f = p:GetNW2String("lcf_faction", "")
        local text = (UNIT[f] or f == "admin") and unitsText or (f == "resistance" and rebelsText) or nil
        if text then LC.Notice(p, "event", "The Nexus", text, 8) end
    end
end

local function WaveGap(i) return C.WAVE_GAPS[math.min(i, #C.WAVE_GAPS)] end

-- The alarm: slow and low at first, quicker and higher as the hold nears its end.
local function Alarm(r, zones, now)
    if now < (r.alarmAt or 0) then return end
    local frac = math.Clamp(r.prog / C.RETAKE_SECS, 0, 1)
    r.alarmAt = now + (10 - 7.5 * frac)
    if not (sound and sound.Play) then return end
    for _, z in ipairs(zones) do
        if z.pos then sound.Play("ambient/alarms/klaxon1.wav", z.pos + Vector(0, 0, 96), 100, math.floor(80 + 50 * frac), 1) end
    end
end

function LC.ChapterRetakeTick(now, dt)
    local s = C.S
    if s.state ~= "reversed" or s.lock then return end
    if s.elapsed < cvHold:GetFloat() * 60 then return end
    local zones = LC.ChapterNexus()
    if #zones == 0 then return end
    local inside = {}
    for _, p in ipairs(player.GetAll()) do
        if p:Alive() and LC.ChapterIsUnit(p) and InNexus(p:GetPos(), zones) then inside[#inside + 1] = p end
    end
    local r = C.retake
    if not r then
        local need = #player.GetAll() <= 4 and 1 or 2
        if #inside < need then return end
        r = { prog = 0, wave = 0, nextWave = 8 }
        C.retake = r
        Tell("Hold the Nexus. The city comes back with it.", "The Combine are in the Nexus. Drive them out.")
    end
    if #inside == 0 then return end -- (nobody of theirs in it: the clock stands)
    r.prog = r.prog + dt
    Alarm(r, zones, now)
    if r.prog >= C.RETAKE_SECS then
        LC.ChapterEnd("retaken")
        Tell("The city is yours again.", "The Combine have the city again.")
        return
    end
    if r.prog >= r.nextWave and r.prog < C.RETAKE_SECS - 5 then
        r.wave = r.wave + 1
        r.nextWave = r.prog + WaveGap(r.wave)
        local n = math.min(8, 2 + r.wave + #inside)
        local z = zones[math.random(#zones)]
        local centre = z.pos or inside[1]:GetPos()
        r.sent = (r.sent or 0) + (LC.RebelWave and select(1, LC.RebelWave(centre, inside, n)) or 0)
    end
end

------------------------------------------------------------------------
-- Every second
------------------------------------------------------------------------

function LC.ChapterTick(now)
    local s = C.S
    local dt = math.Clamp(now - (C.lastTick or now), 0, 5)
    C.lastTick = now
    if C.pendingAt and now >= C.pendingAt then
        local by = C.pendingBy
        C.pendingAt, C.pendingBy = nil, nil
        if cvOn:GetBool() and not s.lock and s.cooldown <= 0 then LC.ChapterWave(by, "launch") end
    end
    if s.state ~= "reversed" then
        if s.cooldown > 0 then
            s.cooldown = math.max(0, s.cooldown - dt)
            if s.cooldown == 0 or now >= (C.saveAt or 0) then C.saveAt = now + 60 LC.ChapterSave() end
        end
        return
    end
    s.elapsed = s.elapsed + dt
    Flags()
    for _, p in ipairs(player.GetAll()) do
        if p:Alive() and LC.ChapterIsUnit(p) and p:Armor() > 0 then p:SetArmor(0) end
    end
    if now >= (C.keepAt or 0) then
        C.keepAt = now + C.KEEP_EVERY
        LC.ChapterDoorsOpen()
        LC.ChapterMachines()
    end
    LC.ChapterRetakeTick(now, dt)
    if LC.ChapterReversed() and now >= (C.saveAt or 0) then C.saveAt = now + 60 LC.ChapterSave() end
end

timer.Create("LivingCityChapter", 1, 0, function() LC.Try(LC.ChapterTick, CurTime()) end)

-- (read back from the file: a restart, or a test)
function LC.ChapterReload()
    C.S = Load()
    C.retake, C.pendingAt, C.pendingBy, C.keepAt = nil, nil, nil, nil
    LC.ChapterApply()
    return C.S
end

-- A restart or the map cleaned up while the city is the Resistance's: its doors and machines as the chapter has them.
-- (The city the Combine's: nothing of the map's is touched.)
local function Again() if LC.ChapterReversed() then LC.ChapterApply() else Flags() end end
hook.Add("InitPostEntity", "LivingCityChapter", function() timer.Simple(3, function() LC.Try(Again) end) end)
hook.Add("PostCleanupMap", "LivingCityChapter", function() timer.Simple(1, function() LC.Try(Again) end) end)
hook.Add("ShutDown", "LivingCityChapter", function() if C.S.state == "reversed" or C.S.cooldown > 0 then LC.ChapterSave() end end)
hook.Add("PlayerDisconnected", "LivingCityChapter", function(ply) C.maskOff[ply] = nil end)

------------------------------------------------------------------------
-- Staff: F4 > Factions > Admin: testing tools > The city (sv_livingcity_admintools.lua)
------------------------------------------------------------------------

if LC.ADMIN_ACTIONS then
    LC.ADMIN_ACTIONS.chapter = function(_, v, admin)
        if IsValid(admin) and not admin:IsSuperAdmin() then return false, "Superadmins only." end
        if v == "wave" then
            if LC.ChapterReversed() then return false, "The city is the Resistance's already." end
            LC.ChapterWave(admin, "staff")
            return true, "The wave: the city falls to the Resistance."
        elseif v == "retake" then
            if not LC.ChapterEnd("staff") then return false, "The city is the Combine's already." end
            return true, "The Combine have the city again."
        elseif v == "lock" then
            C.S.lock = not C.S.lock
            LC.ChapterSave()
            return true, C.S.lock and "The chapter is locked: neither the launch nor the Nexus flips it." or "The chapter is unlocked."
        end
        return false, "Chapter: wave, retake or lock?"
    end
end
