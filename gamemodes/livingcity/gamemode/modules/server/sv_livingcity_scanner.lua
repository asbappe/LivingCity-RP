--[[
    Living City: flying a scanner from a Combine console

    Prison is long. A Combine console (editor: "Fixture: Combine console", put
    one in a cell, or anywhere) lets a prisoner, or a unit, link to one of the
    city's scanners and fly it: the nearest city scanner is taken over (or one
    is put up over the streets if there are none), and your view goes with it.
    Your body stays standing at the console, where everyone can see it.

      Fly          WASD, Space up, Ctrl down, Shift faster; the mouse looks
      Flash        left click: the scanner's camera flash. Anyone in front of it
                   within photo range (about ten feet, the same as the photograph,
                   so being dazzled means you were photographed) is dazzled, and the city's people
                   (units too) are stunned for a few seconds. A prisoner who
                   flashes a unit gets lc_scanner_penalty seconds (60) more,
                   and is told so straight away.
      Report       every flash is also a photograph, but only of what's up
                   close: within lc_scanner_photo_range (128 units, about ten
                   feet), the way a scanner's camera works. Rebels, Father
                   Grigori, free vortigaunts, the wanted, BOLO subjects,
                   anticitizens, zombies, anyone on rebel ground, and rebel
                   ground itself (the scanner in it, or that close to it): what
                   the camera catches goes to every unit on duty as a scanner
                   report, with the subjects highlighted for lc_scanner_spotted
                   seconds (60) through walls, and rebel ground marked on their
                   screens. The city's own units nearby go after the hunted and
                   the wanted. The pilot earns Civil Standing for it (never time
                   off), up to lc_scanner_snitch_cap (40) every ten minutes; the
                   same person can't be reported again for
                   lc_scanner_spot_cooldown (300s). Whoever's photographed is
                   told, and it goes on their record. Smoke blinds the camera:
                   nobody in a smoke grenade's cloud, or behind one, can be
                   flashed or photographed. The pilot's view brackets
                   the nearest suspect in front of the camera and says whether
                   it's close enough yet.
      Disconnect   R

    The link drops when your sentence is up (you're released at the release
    spot as usual), when you're hurt, if the scanner is shot down, or past
    lc_scanner_range (6000) from where it went up.

      lc_scanner_link 0/1, lc_scanner_penalty (60), lc_scanner_range (6000)
]]

if CLIENT then return end

LC = LC or {}

local FLAGS = bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED)
local cvOn      = CreateConVar("lc_scanner_link", "1", FLAGS, "Prisoners and Civil Protection units can fly a city scanner from a Combine console")
local cvPenalty = CreateConVar("lc_scanner_penalty", "60", FLAGS, "Seconds added to a prisoner's sentence for flashing a Civil Protection unit with a linked scanner")
local cvRange   = CreateConVar("lc_scanner_range", "6000", FLAGS, "How far from where it went up a linked scanner can fly")

local cvPhotoRange   = CreateConVar("lc_scanner_photo_range", "128", FLAGS, "How close a scanner has to be to photograph someone for a report (128 Civil Protection units, about ten feet)")
local cvSpotSecs     = CreateConVar("lc_scanner_spotted", "60", FLAGS, "Seconds the people in a scanner report stay highlighted for Civil Protection units")
local cvSpotCooldown = CreateConVar("lc_scanner_spot_cooldown", "300", FLAGS, "Seconds before the same person can be reported again (rebel ground: twice as long)")
local cvSnitchCap    = CreateConVar("lc_scanner_snitch_cap", "100", FLAGS, "Most Civil Standing a pilot can earn from scanner reports in ten minutes")
local cvRebelFire    = CreateConVar("lc_scanner_rebel_fire", "1", FLAGS, "Rebels who notice a flown scanner shoot at it")

local SPEED, FAST = 230, 420
local FLASH_COOLDOWN = 4

LC.ScannerLinks = LC.ScannerLinks or {} -- [ply] = { sc, console, input, nextFlash, wasPrisoner }

local function Prisoner(ply) return LC.Prisoners ~= nil and LC.Prisoners[ply] ~= nil end
local function Unit(ply) return LC.PlayerIsCP and LC.PlayerIsCP(ply) end

function LC.CanLinkScanner(ply, console)
    if not cvOn:GetBool() then return false, "The console is dead. (Scanner links are off on this server.)" end
    if not ply:Alive() then return false end
    if LC.ScannerLinks[ply] then return false, "You're already linked." end
    if not (Prisoner(ply) or Unit(ply) or ply:IsAdmin()) then return false, "ACCESS DENIED. Civil Protection credentials required." end
    for other, l in pairs(LC.ScannerLinks) do
        if console ~= nil and l.console == console and IsValid(other) then return false, "Someone's already on this console." end
    end
    return true
end

-- Where the scanner comes from: the nearest of the city's own, taken over; or a
-- fresh one up over a street.
-- Room for a scanner here (it's about thirty units across)?
local function Free(pos)
    local tr = util.TraceHull({ start = pos, endpos = pos, mins = Vector(-18, -18, -18), maxs = Vector(18, 18, 18), mask = MASK_SOLID })
    return not tr.Hit and not tr.StartSolid
end
-- The nearest spot with room, around pos (or nil).
local function FreeNear(pos)
    if Free(pos) then return pos end
    for _, r in ipairs({ 40, 80, 140 }) do
        for i = 0, 7 do
            local a = i / 8 * math.pi * 2
            for _, dz in ipairs({ 0, 40, -30, 80 }) do
                local p = pos + Vector(math.cos(a) * r, math.sin(a) * r, dz)
                if Free(p) then return p end
            end
        end
    end
    return nil
end
LC.ScannerFreeNear = FreeNear

-- Open sky above pos? Then a height to fly at, under it.
local function UnderSky(pos)
    local tr = util.TraceLine({ start = pos + Vector(0, 0, 40), endpos = pos + Vector(0, 0, 6000), mask = MASK_SOLID_BRUSHONLY or MASK_SOLID })
    if not tr.HitSky then return nil end
    local room = tr.HitPos.z - pos.z
    if room < 160 then return nil end
    local p = pos + Vector(0, 0, math.min(260, room - 80))
    return Free(p) and p or nil
end
LC.ScannerUnderSky = UnderSky

-- Where a flown scanner appears: the editor's "scanner launch spot" nearest the
-- console if there is one; otherwise out in the open air, somewhere under the
-- sky near the console (never inside the map's geometry); only then the old way.
local function LaunchSpot(home)
    local best, bd
    for _, p in ipairs(LC.Points or {}) do
        if p.kind == "sspawn" then
            local d = p.pos:DistToSqr(home)
            if not bd or d < bd then best, bd = p, d end
        end
    end
    if best then return FreeNear(best.pos + Vector(0, 0, 40)) or (best.pos + Vector(0, 0, 40)), "point" end
    for _ = 1, 40 do
        local street = LC.RandomWanderPos and LC.RandomWanderPos("citizen", home)
        local p = street and UnderSky(street)
        if p then return p, "sky" end
    end
    for _ = 1, 40 do
        local street = LC.RandomWanderPos and LC.RandomWanderPos("citizen")
        local p = street and UnderSky(street)
        if p then return p, "sky" end
    end
    return nil
end
LC.ScannerLaunchSpot = LaunchSpot

-- One of the city's own scanners is taken over (it goes; the city puts up
-- another in time). The link's scanner appears at the launch spot.
local function TakeScanner(near)
    local best, bd
    for npc, st in pairs(LC.NPCs or {}) do
        if IsValid(npc) and st.role == "scanner" then
            local d = npc:GetPos():DistToSqr(near)
            if not bd or d < bd then best, bd = npc, d end
        end
    end
    local ang = Angle(0, 0, 0)
    if best then
        ang = best:GetAngles()
        best:Remove()
    end
    local pos = LaunchSpot(near)
    if pos then return pos, ang end
    local street = LC.RandomWanderPos and LC.RandomWanderPos("citizen", near) or nil
    return (street or near) + Vector(0, 0, 140), ang
end

function LC.StartScannerLink(ply, console)
    local ok, why = LC.CanLinkScanner(ply, console)
    if not ok then return false, why end
    local home = IsValid(console) and console:GetPos() or ply:GetPos()
    local pos, ang = TakeScanner(home)
    -- never inside a wall: somewhere with room near there, or over the console
    pos = FreeNear(pos) or FreeNear(home + Vector(0, 0, 90)) or (home + Vector(0, 0, 90))
    local sc = ents.Create("lc_rscanner")
    if not IsValid(sc) then return false, "The console flickers. Nothing answers." end
    sc:SetPos(pos)
    sc:SetAngles(Angle(0, ang.y or 0, 0))
    sc:Spawn()
    sc:SetNW2Entity("lc_pilot", ply)
    sc:SetNW2Float("lc_photo_range", cvPhotoRange:GetFloat()) -- for the pilot's view
    ply:SetNW2Entity("lc_scanner", sc)
    if ply.SetViewEntity then ply:SetViewEntity(sc) end -- what the scanner sees is sent to you
    LC.ScannerLinks[ply] = { sc = sc, console = console, input = { quit = true }, nextFlash = 0, wasPrisoner = Prisoner(ply), -- (input: the E that linked them is still down)
        home = pos, at = CurTime(), hp = ply:Health() } -- (range is measured from where it went up)
    ply:EmitSound("buttons/combine_button1.wav", 60)
    if ply.SelectWeapon and ply:HasWeapon("weapon_lc_hands") then ply:SelectWeapon("weapon_lc_hands") end -- nothing in the hands to fire
    ply:ChatPrint("[Scanner link] You're in the scanner. WASD to fly, Space and Ctrl up and down, Shift faster, left click to flash, R (or E, or F1 > Disconnect) to disconnect.")
    if Prisoner(ply) then
        ply:ChatPrint(string.format("[Scanner link] Flash a Civil Protection unit and it's %d more seconds on your sentence.", cvPenalty:GetInt()))
    end
    hook.Run("LivingCityScannerLinked", ply, sc)
    return true
end

function LC.EndScannerLink(ply, why)
    local l = LC.ScannerLinks[ply]
    if not l then return false end
    LC.ScannerLinks[ply] = nil
    if IsValid(l.sc) then l.sc:Remove() end
    if IsValid(ply) then
        ply:SetNW2Entity("lc_scanner", NULL)
        if ply.SetViewEntity then ply:SetViewEntity(ply) end
        if why then ply:ChatPrint("[Scanner link] " .. why) end
        ply:EmitSound("buttons/combine_button2.wav", 55)
    end
    return true
end

function LC.ScannerInput(ply, input)
    local l = LC.ScannerLinks[ply]
    if not l then return end
    local was = l.input or {}
    l.input = input
    if input.quit and not was.quit then
        timer.Simple(0, function() LC.EndScannerLink(ply, "Link closed.") end)
        return
    end
    if input.flash and not was.flash then LC.ScannerFlash(ply) end
end

-- Steering: every tick, from the pilot's keys and where they're looking.
function LC.ScannerThink(sc)
    local ply = sc:GetNW2Entity("lc_pilot")
    local l = IsValid(ply) and LC.ScannerLinks[ply]
    if not l or l.sc ~= sc then sc:Remove() return end
    local in_ = l.input or {}
    local ang = ply:EyeAngles()
    local fwd, right = ang:Forward(), ang:Right()
    local dir = fwd * ((in_.f and 1 or 0) - (in_.b and 1 or 0)) + right * ((in_.r and 1 or 0) - (in_.l and 1 or 0))
        + Vector(0, 0, (in_.up and 1 or 0) - (in_.down and 1 or 0))
    local limp = LC.IsCrippled and LC.IsCrippled(ply)
    local vel = dir:LengthSqr() > 0 and dir:GetNormalized() * (in_.fast and FAST or SPEED) * (limp and 0.75 or 1) or Vector(0, 0, 0)
    -- broken feet: the camera lurches with every step you can't take, and rolls with it
    local roll = 0
    if limp and vel:LengthSqr() > 1 then
        local t = CurTime() * 5
        vel = vel + right * math.sin(t) * 45 + Vector(0, 0, math.abs(math.sin(t)) * -50)
        roll = math.sin(t) * 7
    end
    -- the signal only reaches so far
    local away = sc:GetPos() - l.home
    local range = cvRange:GetFloat()
    if away:LengthSqr() > range * range then
        vel = -away:GetNormalized() * SPEED
        if (l.nextWarn or 0) < CurTime() then
            l.nextWarn = CurTime() + 4
            ply:ChatPrint("[Scanner link] Signal weak. Turn back.")
        end
    end
    if (l.nextTarget or 0) <= CurTime() then
        l.nextTarget = CurTime() + 0.2
        LC.ScannerTarget(ply, sc)
    end
    -- wedged in something: trying to fly and going nowhere. Shake it loose.
    local moving = vel:LengthSqr() > 1
    if moving and l.lastPos and sc:GetPos():DistToSqr(l.lastPos) < 4 then
        l.stuckFor = (l.stuckFor or 0) + FrameTime()
        if l.stuckFor > 1.5 then
            l.stuckFor = 0
            local p = FreeNear(sc:GetPos()) or FreeNear(l.home + Vector(0, 0, 90))
            if p then sc:SetPos(p) end
        end
    else
        l.stuckFor = 0
    end
    l.lastPos = sc:GetPos()
    local phys = sc.GetPhysicsObject and sc:GetPhysicsObject()
    if math.abs(sc:GetNW2Float("lc_roll", 0) - roll) > 0.2 then sc:SetNW2Float("lc_roll", roll) end
    if IsValid(phys) then
        phys:SetVelocity(vel)
        phys:SetAngles(Angle(ang.p, ang.y, roll))
        -- no spin left over from bumping into things (it kept tipping and rolling the camera)
        if phys.GetAngleVelocity and phys.AddAngleVelocity then phys:AddAngleVelocity(-phys:GetAngleVelocity()) end
        phys:Wake()
    else
        sc:SetPos(sc:GetPos() + vel * FrameTime())
        sc:SetAngles(Angle(ang.p, ang.y, roll))
    end
end

-- The camera's line of sight: walls block it, and so does smoke (a smoke
-- grenade's cloud hides anyone in it, or behind it, from the flash and the
-- photograph alike; the scanner in the smoke sees nothing either).
local function Sees(from, to, filter)
    if LC.SmokeBlocks and LC.SmokeBlocks(from, to) then return false end
    local tr = util.TraceLine({ start = from, endpos = to, mask = MASK_OPAQUE, filter = filter })
    return not tr.Hit or tr.Fraction > 0.97
end

-- The camera flash: whoever is in front of it and close enough.
function LC.ScannerFlash(ply)
    local l = LC.ScannerLinks[ply]
    if not l or not IsValid(l.sc) then return false end
    local now = CurTime()
    if now < l.nextFlash then return false end
    l.nextFlash = now + FLASH_COOLDOWN
    local sc = l.sc
    local origin = sc:GetPos()
    local aim = ply:EyeAngles():Forward()
    sc:EmitSound("npc/scanner/scanner_photo1.wav", 80)
    sc:SetNW2Float("lc_flash_at", now)
    local function InCone(pos)
        local to = pos - origin
        local d = to:Length()
        -- the same reach and the same frame as the photograph: dazzled means photographed
        if d > cvPhotoRange:GetFloat() or d < 1 then return false end
        return to:GetNormalized():Dot(aim) > 0.85 and Sees(origin, pos, { sc })
    end
    local unitsHit = 0
    for _, p in ipairs(player.GetAll()) do
        if p ~= ply and p:Alive() and InCone(p:EyePos()) then
            p:ScreenFade(SCREENFADE.IN, Color(255, 255, 255, 230), 1.2, 0.8)
            if Unit(p) then unitsHit = unitsHit + 1 end
        end
    end
    for npc, st in pairs(LC.NPCs or {}) do
        if IsValid(npc) and st.role ~= "scanner" and st.role ~= "zombie" and InCone(npc:EyePos()) then
            st.stunnedUntil = now + 3
            if npc.SetEnemy then npc:SetEnemy(NULL) end
            if npc.SetSchedule then npc:SetSchedule(SCHED_IDLE_STAND) end
            if st.role == "cop" or st.role == "soldier" then unitsHit = unitsHit + 1 end
        end
    end
    if unitsHit > 0 and Prisoner(ply) then
        local pr = LC.Prisoners[ply]
        local add = cvPenalty:GetFloat()
        pr.untilT = pr.untilT + add
        ply:SetNW2Float("lc_jail_until", pr.untilT)
        ply:ChatPrint(string.format("[Prison] You flashed a Civil Protection unit through the scanner. %d more seconds on your sentence (%d:%02d left).",
            add, math.floor((pr.untilT - now) / 60), math.floor((pr.untilT - now) % 60)))
        ply:EmitSound("buttons/combine_button_locked.wav", 60)
        if LC.AddViolation then LC.AddViolation(ply, "Interfered with a Civil Protection unit through a city scanner, from custody") end
        hook.Run("LivingCityScannerPenalty", ply, add)
    end
    local report = LC.ScannerPhoto(ply, l, origin, aim)
    return true, unitsHit, report
end

------------------------------------------------------------------------
-- Snitching: every flash is also a photograph, and it goes to Civil Protection
------------------------------------------------------------------------

LC.ScannerSpotted = LC.ScannerSpotted or {}  -- [ent or zone] = CurTime() it can be reported again
LC.ScannerEarned = LC.ScannerEarned or {}    -- [ply] = { { t, n }, ... } standing earned lately

-- Who's worth a report, and what it's worth to the one who sends it.
function LC.ScannerSuspect(ent)
    if not IsValid(ent) then return nil end
    if ent:IsPlayer() then
        if not ent:Alive() or Unit(ent) then return nil end
        if LC.PlayerIsZombie and LC.PlayerIsZombie(ent) then return "a zombie", 2 end
        local passes = LC.PassesAsCitizen and LC.PassesAsCitizen(ent) or (LC.DisguisedAsCP and LC.DisguisedAsCP(ent))
        if ent:GetNW2String("lcf_special", "") == "chaplain" and not passes then return "Father Grigori", 15 end
        if ent:GetNW2String("lcf_special", "") == "vortigaunt" then return "a free vortigaunt", 12 end -- no hiding the shackles are off
        if LC.PlayerIsHunted and LC.PlayerIsHunted(ent) and not passes then return "a rebel", 12 end
        if LC.DisguisedAsRebel and LC.DisguisedAsRebel(ent) then return "a rebel", 12 end
        if LC.PlayerIsWanted and LC.PlayerIsWanted(ent) then return "a wanted citizen", 8 end
        if ent:GetNW2Bool("lc_bolo", false) then return "a BOLO subject", 8 end
        if LC.InRebelZone and LC.InRebelZone(ent:GetPos()) then return "someone on rebel ground", 8 end
        local standing = LC.Standing and LC.Standing(ent) or 0
        if LCS and LCS.TierFor and LCS.TierFor(standing).name == "Anticitizen" then return "an anticitizen", 6 end
        return nil
    end
    local st = LC.NPCs and LC.NPCs[ent]
    if not st then return nil end
    if st.role == "rebel" or st.role == "resistance" then return "a rebel", 12 end
    if st.role == "vortigaunt" or st.role == "vort" then return "a free vortigaunt", 12 end
    if st.role == "zombie" then return "a zombie", 1 end
    return nil
end

local function Earned(ply, now)
    local list = LC.ScannerEarned[ply] or {}
    local keep, sum = {}, 0
    for _, e in ipairs(list) do
        if now - e.t < 600 then keep[#keep + 1] = e sum = sum + e.n end
    end
    LC.ScannerEarned[ply] = keep
    return sum, keep
end

-- Is ent in the camera's frame (in front, in sight), and how far? maxd caps it.
local function InFrame(origin, aim, ent, maxd, sc)
    local pos = ent:EyePos()
    local to = pos - origin
    local d = to:Length()
    if d > maxd or d < 1 then return nil end
    if to:GetNormalized():Dot(aim) <= 0.85 then return nil end
    if not Sees(origin, pos, { sc, ent }) then return nil end
    return d
end

-- Rebel ground close enough to photograph: the scanner's in it, or it's pointed
-- at it from within range.
local function GroundInFrame(origin, aim, range, sc)
    if not LC.RebelZoneAt then return nil end
    local z = LC.RebelZoneAt(origin)
    if z and not (LC.SmokeBlocks and LC.SmokeBlocks(origin, origin)) then return z, origin end
    local tr = util.TraceLine({ start = origin, endpos = origin + aim * range, mask = MASK_OPAQUE, filter = { sc } })
    local at = tr.HitPos or (origin + aim * range)
    z = LC.RebelZoneAt(at)
    if z and not (LC.SmokeBlocks and LC.SmokeBlocks(origin, at)) then return z, at end
    return nil
end

local function Candidates(pilot)
    local list = {}
    for _, p in ipairs(player.GetAll()) do if p ~= pilot then list[#list + 1] = p end end
    for npc in pairs(LC.NPCs or {}) do list[#list + 1] = npc end
    return list
end

-- What the pilot sees: the nearest thing worth a report in front of the
-- camera (out to a few times the photo range), so the view can say "closer".
function LC.ScannerTarget(ply, sc)
    local origin, aim = sc:GetPos(), ply:EyeAngles():Forward()
    local range = cvPhotoRange:GetFloat()
    local best, bd, bwhy
    local far = (range * 4) ^ 2
    for _, ent in ipairs(Candidates(ply)) do
        -- out of reach (cheap) before whether they're worth a report, before whether they're in the frame
        local why = IsValid(ent) and ent:GetPos():DistToSqr(origin) < far and LC.ScannerSuspect(ent)
        if why then
            local d = InFrame(origin, aim, ent, range * 4, sc)
            if d and (not bd or d < bd) then best, bd, bwhy = ent, d, why end
        end
    end
    local now = CurTime()
    sc:SetNW2Entity("lc_target", best or NULL)
    sc:SetNW2String("lc_target_why", bwhy or "")
    sc:SetNW2Bool("lc_target_done", best ~= nil and (LC.ScannerSpotted[best] or 0) > now)
    local z = GroundInFrame(origin, aim, range, sc)
    sc:SetNW2Bool("lc_ground", z ~= nil)
    sc:SetNW2Bool("lc_jammed", LC.Jammed ~= nil and LC.Jammed(origin) == true)
    sc:SetNW2Bool("lc_smoke", LC.SmokeBlocks ~= nil and LC.SmokeBlocks(origin, origin + aim * range * 4))
    sc:SetNW2Bool("lc_ground_done", z ~= nil and (LC.ScannerSpotted[z] or 0) > now)
    return best, bd, bwhy
end

-- What the camera caught: suspects in front of it and close, within
-- lc_scanner_photo_range (about ten feet, as close as a scanner's camera
-- works), and rebel ground it's in or pointed at from that close. Each subject is reported once
-- every lc_scanner_spot_cooldown, by anyone, so the same rebel can't be farmed.
-- The report is real: units see who was caught, highlighted, wherever they are.
function LC.ScannerPhoto(ply, l, origin, aim)
    local now = CurTime()
    local range = cvPhotoRange:GetFloat()
    local cooldown = cvSpotCooldown:GetFloat()
    local spotSecs = cvSpotSecs:GetFloat()
    local caught, counts, order, pts = {}, {}, {}, 0
    -- a jammer near the scanner: the picture's taken, but it never reaches anyone
    if LC.Jammed and LC.Jammed(origin) then
        ply:ChatPrint("[Scanner link] Interference. The picture doesn't go through: something nearby is jamming the signal.")
        return nil
    end
    local function Note(label, n)
        if not counts[label] then counts[label] = 0 order[#order + 1] = label end
        counts[label] = counts[label] + 1
        pts = pts + n
    end
    local zombies = 0
    for _, ent in ipairs(Candidates(ply)) do
        local label, n = LC.ScannerSuspect(ent)
        if label and (LC.ScannerSpotted[ent] or 0) <= now and InFrame(origin, aim, ent, range, l.sc)
            and not (LC.Jammed and LC.Jammed(ent:GetPos())) then
            if label == "a zombie" then zombies = zombies + 1 end
            if label ~= "a zombie" or zombies <= 4 then
                LC.ScannerSpotted[ent] = now + cooldown
                caught[#caught + 1] = ent
                ent:SetNW2Float("lc_spotted_until", now + spotSecs)
                ent:SetNW2String("lc_spotted_why", label)
                Note(label, n)
                if ent:IsPlayer() then
                    ent:ChatPrint("A scanner's flash. You've been photographed, and Civil Protection has the picture.")
                    if label ~= "a zombie" and LC.AddViolation then LC.AddViolation(ent, "Photographed by a city scanner: " .. label) end
                end
            end
        end
    end
    -- rebel ground, where the camera's pointed
    local base
    local z, at = GroundInFrame(origin, aim, range, l.sc)
    if z ~= nil and (LC.ScannerSpotted[z] or 0) <= now then
        LC.ScannerSpotted[z] = now + cooldown * 2
        base = at
        Note("rebel ground", 15)
    end
    if #order == 0 then return nil end

    -- the report: every unit on duty gets it, with the subjects lit up
    local parts = {}
    for _, label in ipairs(order) do
        parts[#parts + 1] = counts[label] > 1 and (label .. " x" .. counts[label]) or label
    end
    local where = LC.DescribePlace and LC.DescribePlace(base or (IsValid(caught[1]) and caught[1]:GetPos()) or origin) or ""
    local who = Prisoner(ply) and "a scanner run from custody" or ("scanner " .. (LC.Callsign and LC.Callsign(ply) or ply:Nick()))
    local text = string.format("[CP net] Scanner report from %s: %s%s. Subjects highlighted for %ds.",
        who, table.concat(parts, ", "), where ~= "" and (", " .. where) or "", spotSecs)
    local units = {}
    for _, p in ipairs(player.GetAll()) do if Unit(p) then units[#units + 1] = p p:ChatPrint(text) end end
    if base and LC.SendCompressed and #units > 0 then
        LC.SendCompressed("lc_cpmark", { name = "SCANNER: rebel ground", x = base.x, y = base.y, z = base.z, secs = spotSecs * 2 }, units)
    end
    -- the city's own units act on it too: hunted people, and the wanted, near enough
    for _, ent in ipairs(caught) do
        if ent:IsPlayer() and LC.MakeCopsHostile then
            local label = ent:GetNW2String("lc_spotted_why", "")
            if label == "a rebel" or label == "Father Grigori" or label == "a wanted citizen" then
                LC.MakeCopsHostile(ent, ent:GetPos(), 2000)
            end
        end
    end

    -- a Scanner Operator's photographs: XP (the same cap as a snitch's standing),
    -- and a rebel caught on camera goes out to every unit as a BOLO
    local gain = 0
    if LC.IsScannerOperator(ply) then
        local earned = Earned(ply, now)
        gain = math.max(0, math.min(pts, cvSnitchCap:GetInt() - earned))
        if gain > 0 then
            table.insert(LC.ScannerEarned[ply], { t = now, n = gain })
            if LC.AddXP then LC.AddXP(ply, gain, "scanner report") end
        end
        for _, ent in ipairs(caught) do
            if ent:IsPlayer() and ent:GetNW2String("lc_spotted_why", "") == "a rebel" and LC.AddBOLO and LC.RecordKey then
                local spot = LC.DescribePlace and LC.DescribePlace(ent:GetPos()) or ""
                LC.AddBOLO(ply, LC.RecordKey(ent), "Photographed by a city scanner as a rebel" .. (spot ~= "" and (", " .. spot) or ""), 30)
            end
        end
        ply:ChatPrint(string.format("[Scanner link] Report filed: %s.%s", table.concat(parts, ", "), gain > 0 and string.format(" %+d XP.", gain) or ""))
    elseif not Unit(ply) then
        local earned = Earned(ply, now)
        gain = math.max(0, math.min(pts, cvSnitchCap:GetInt() - earned))
        if gain > 0 then
            table.insert(LC.ScannerEarned[ply], { t = now, n = gain })
            if LC.AddStanding then LC.AddStanding(ply, gain, nil) end
            ply:ChatPrint(string.format("[Scanner link] Report filed: %s. Civil Standing %+d.%s", table.concat(parts, ", "), gain,
                Prisoner(ply) and " Your sentence stands." or ""))
        else
            ply:ChatPrint("[Scanner link] Report filed: " .. table.concat(parts, ", ") .. ". The city has had enough from you for now; no more standing for a while.")
        end
    else
        ply:ChatPrint("[Scanner link] Report filed: " .. table.concat(parts, ", ") .. ".")
    end
    ply:EmitSound("npc/scanner/scanner_talk" .. math.random(1, 2) .. ".wav", 60)
    local report = { parts = parts, caught = caught, base = base, gain = gain, points = pts }
    hook.Run("LivingCityScannerReport", ply, report)
    return report
end

-- Rebels who notice a flown scanner shoot at it. They have to see it: in front
-- of them (or close enough to hear it hum), in plain sight, for a moment first.
-- Their aim is poor and gets worse with distance and with how fast it is going,
-- and a hit only chips it. Come up behind them and nobody fires; charge them in
-- the open and they do.
local FIRE_RANGE, FIRE_DELAY, FIRE_EVERY, HEAR = 1100, 1.1, 0.9, 150
function LC.RebelsFireAtScanner(ply, l, now)
    local sc = l.sc
    if not cvRebelFire:GetBool() or not IsValid(sc) then return 0 end
    l.noticed = l.noticed or {}
    local fired = 0
    local speed = IsValid(sc:GetPhysicsObject()) and sc:GetPhysicsObject():GetVelocity():Length() or 0
    for npc, st in pairs(LC.NPCs or {}) do
        if IsValid(npc) and st.role == "rebel" and npc:Health() > 0 and not st.test then
            local to = sc:GetPos() - npc:GetPos()
            local d = to:Length()
            local seen = false
            if d < FIRE_RANGE and d > 1 then
                local facing = npc:GetForward():Dot(to / d) > 0.25
                if facing or d < HEAR then
                    local tr = util.TraceLine({ start = npc:EyePos(), endpos = sc:GetPos(), mask = MASK_OPAQUE, filter = { npc, sc } })
                    seen = not tr.Hit
                end
            end
            if seen then
                l.noticed[npc] = l.noticed[npc] or now
                if now - l.noticed[npc] >= FIRE_DELAY and now >= (st.scannerFireAt or 0) then
                    st.scannerFireAt = now + FIRE_EVERY
                    fired = fired + 1
                    local spread = 0.02 + (d / FIRE_RANGE) * 0.07 + math.min(speed / FAST, 1) * 0.05
                    if npc.FireBullets then
                        npc:FireBullets({ Src = npc:EyePos(), Dir = to / d, Spread = Vector(spread, spread, 0), Num = 1,
                            Damage = 8, Tracer = 1, Force = 1, Attacker = npc })
                    else
                        npc:EmitSound("weapons/pistol/pistol_fire2.wav", 80)
                        if math.random() > spread * 6 then sc:TakeDamage(8, npc, npc) end
                    end
                end
            elseif l.noticed[npc] and now - (l.lastSeen and l.lastSeen[npc] or now) > 2 then
                l.noticed[npc] = nil
            end
            l.lastSeen = l.lastSeen or {}
            if seen then l.lastSeen[npc] = now end
        end
    end
    return fired
end

timer.Create("LivingCityScannerFire", 0.4, 0, function()
    for ply, l in pairs(LC.ScannerLinks) do
        if IsValid(ply) and IsValid(l.sc) then
            local ok, err = LC.Try(LC.RebelsFireAtScanner, ply, l, CurTime())
            if not ok and LC.Error then LC.Error("scanner fire", err) end
        end
    end
end)

-- When the link drops by itself
timer.Create("LivingCityScannerLinks", 0.5, 0, function()
    -- who sees scanner reports lit up (clients can't ask the gamemode themselves)
    for _, p in ipairs(player.GetAll()) do
        local u = Unit(p) == true
        if p:GetNW2Bool("lc_unit", false) ~= u then
            p:SetNW2Bool("lc_unit", u)
            if LC.FieldRulesChanged then LC.FieldRulesChanged(p) end -- (forcefields let units through)
        end
    end
    for ply, l in pairs(LC.ScannerLinks) do
        if not IsValid(ply) then
            if IsValid(l.sc) then l.sc:Remove() end
            LC.ScannerLinks[ply] = nil
        elseif not ply:Alive() then
            LC.EndScannerLink(ply, nil)
        elseif ply:Health() < (l.hp or ply:Health()) then
            -- hurt, however it happened (some damage never reaches the hook below)
            LC.EndScannerLink(ply, "Something hits you. You pull out of the link.")
        elseif not IsValid(l.sc) then
            LC.EndScannerLink(ply, "The link drops.")
        elseif l.wasPrisoner and not Prisoner(ply) then
            -- sentence served: the release has already walked them out
            LC.EndScannerLink(ply, "Time's up. The console goes dark.")
        elseif l.console ~= nil and not IsValid(l.console) then
            LC.EndScannerLink(ply, "The console is gone.")
        else
            l.hp = ply:Health() -- healing up doesn't count
        end
    end
end)

-- Being hurt pulls you out of it.
------------------------------------------------------------------------
-- Flying a scanner from a terminal: any Civil Protection unit, from a Combine
-- console, a data terminal, or anywhere in the Nexus (a map with none of
-- those: from anywhere). F2 > Unit tools. (It was a role, the Scanner
-- Operator, until 7 November: the owner, "it's just something you can do from
-- the scanner terminal".)
------------------------------------------------------------------------

local DESKS = { "lc_console", "lc_dataterminal", "lc_masterterminal" }
function LC.IsScannerOperator(ply)
    return IsValid(ply) and ply:IsPlayer() and LC.PlayerIsCP(ply) and not (LC.PlayerIsStalker and LC.PlayerIsStalker(ply))
end

-- Where an operator can fly from here: a desk (the console entity), "here"
-- (in the Nexus, or a map with no desks), or nil.
function LC.OperatorDesk(ply)
    local any = false
    for _, cls in ipairs(DESKS) do
        for _, e in ipairs(LC.EntsOf and LC.EntsOf(cls) or {}) do
            any = true
            if IsValid(e) and e:GetPos():DistToSqr(ply:GetPos()) < 160 * 160 then return e end
        end
    end
    for _, z in ipairs(LC.ZonesOfKind and LC.ZonesOfKind("combine") or {}) do
        any = true
        if LCZ and LCZ.Contains(z, ply:GetPos(), 0) then return "here" end
    end
    if not any then return "here" end
    return nil
end

function LC.OperatorLink(ply)
    if not LC.IsScannerOperator(ply) then return false, "Civil Protection units only." end
    local desk = LC.OperatorDesk(ply)
    if not desk then return false, "Get to a terminal: a Combine console, a data terminal, or anywhere in the Nexus." end
    return LC.StartScannerLink(ply, desk ~= "here" and desk or nil)
end

LC.SlashCommands = LC.SlashCommands or {}
LC.SlashCommands.scanner = function(ply)
    local ok, why = LC.OperatorLink(ply)
    if not ok and why then
        if LC.Notice then LC.Notice(ply, "bad", "Scanner link", why, 5) else ply:ChatPrint(why) end
    end
end

hook.Add("EntityTakeDamage", "LivingCityScannerLinks", function(target, dmg)
    if IsValid(target) and target:IsPlayer() and LC.ScannerLinks[target] and dmg:GetDamage() > 0 then
        timer.Simple(0, function() if IsValid(target) then LC.EndScannerLink(target, "Something hits you. You pull out of the link.") end end)
    end
end)
hook.Add("PlayerDisconnected", "LivingCityScannerLinks", function(ply) LC.EndScannerLink(ply, nil) end)
hook.Add("PlayerDeath", "LivingCityScannerLinks", function(ply) LC.EndScannerLink(ply, nil) end)
-- released or not, nobody walks out of the cell still flying
hook.Add("LivingCityReleased", "LivingCityScannerLinks", function(ply)
    if LC.ScannerLinks[ply] then LC.EndScannerLink(ply, "Time's up. The console goes dark.") end
end)

-- Out of the link by chat or console, whatever the keys are doing.
hook.Add("PlayerSay", "LivingCityScannerUnlink", function(ply, text)
    local t = string.lower(string.Trim(text))
    if (t == "!unlink" or t == "/unlink" or t == "!disconnect") and LC.ScannerLinks[ply] then
        LC.EndScannerLink(ply, "Link closed.")
        return ""
    end
end)
concommand.Add("lc_scanner_exit", function(ply) if IsValid(ply) then LC.EndScannerLink(ply, "Link closed.") end end)
