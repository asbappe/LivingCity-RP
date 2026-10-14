--[[
    Living City: secret endings

      Do the right (wrong) thing, mostly with the motherlode (the master data
      core out of the Combine's master terminal), and the city ends. Not for
      real: nobody dies, characters, Civil Standing and credits carry on, and
      the map reloads with its Living City layout afterwards.

      How every one goes
        1. Something triggers it.
        2. A few seconds later (lc_ending_pause, 4) the G-Man stops time:
           everyone freezes, every NPC stops, colour drains out of the world,
           his voice plays for everyone (lc_ending_gman_lines) and the vote
           comes up on every screen. 1: let it happen. 2: skip it.
        3. lc_ending_vote_secs (30) later: more skips than yeses and he
           straightens his tie, time starts again, and life goes on. Anything
           else (a tie, or nobody voting at all): the apocalypse.
        4. The ending plays out with its song, until everyone's been taken
           (or lc_ending_max seconds), then the world goes white and the map
           reloads.

      The endings (their songs: sound/livingcity/endings/<id>/, any file
      there, .wav, .mp3 or .ogg; they live in the separate sound addon,
      garrysmod/addons/livingcity_sound/sound/livingcity/endings/<id>/,
      so updating the gamemode never touches them)
        harpies    lights out, everyone at the landing zone, and the mingebags
                   (the 2007 default: Dr. Kleiner in the reference pose, a
                   physgun stuck at his crotch, sliding)
                   gather in the dark for a minute, rush in when the song
                   swells, then leap; everyone's dead by 2:00 and watches
                   (lc_ending_minge_swell, lc_ending_minge_end, _max, _models)
        bus        the party bus: it drives about through the song's intro,
                   then everyone (and some of the Combine) is in it and it
                   flies through walls, a rainbow behind it, speed surging on
                   the beat, through rings that pop; down to drive again, then
                   up faster (lc_ending_bus_sections)
        nuanua     everyone on an airplane, high over the city
        topsecret  everyone hung by barnacles, one a second
        marrow     skeletons dance their way in from all over the map to the
                   landing zone; on the song's heavy parts everyone (the
                   Combine's units too) dances with them, club lights
                   strobing; in between they attack, and whoever they get
                   becomes one, dancing for good; the outro (the xylophone)
                   claims the rest, everyone dancing double time
                   (lc_ending_marrow_sections lines it up with your file)
        bloom      everyone dances (every NPC too) and can't stop; the city dims
                   and coloured light pulses on the beat; from 2:01
                   (lc_ending_bloom_speedup) the song speeds up, and at the top
                   of it the dancers spin up into the sky one at a time and
                   burst. (A codeword: the song's name is in nothing players
                   download.)
        grigori    a rising flood; Father Grigori rocks out above it, mouthing
                   every word. Triggered by Father Grigori himself eating the
                   motherlode: /eatchip, with a master data core in his pockets.

      Nobody can be hurt during the vote or an ending (and "taken" isn't dead:
      no new character). The city's events wait. One ending (or a skipped one)
      every lc_ending_cooldown minutes (60), remembered across the reload.

      Admins: lc_endings (the songs found, the cooldown), lc_ending <id> [now]
      (trigger one; now: no vote), lc_ending_cancel (stop one, no reload),
      lc_ending_reset_cooldown.
]]

if CLIENT then return end

LC = LC or {}

util.AddNetworkString("lc_ending")
util.AddNetworkString("lc_ending_vote")

local FLAGS = bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED)
local cvOn      = CreateConVar("lc_endings_on", "1", FLAGS, "Secret endings (the G-Man, a vote, and the city's end)")
local cvPause   = CreateConVar("lc_ending_pause", "4", FLAGS, "Seconds between a secret ending's trigger and the G-Man stopping time")
local cvVote    = CreateConVar("lc_ending_vote_secs", "30", FLAGS, "Seconds the G-Man's vote stays open")
local cvMax     = CreateConVar("lc_ending_max", "180", FLAGS, "Longest a secret ending runs before the reset")
local cvCool    = CreateConVar("lc_ending_cooldown", "60", FLAGS, "Minutes between secret endings (triggered, voted on or skipped)")
local cvGman    = CreateConVar("lc_ending_gman_lines", "vo/citadel/gman_exit01.wav,vo/citadel/gman_exit02.wav", FLAGS,
    "The G-Man's lines when he stops time, in order (comma-separated sound paths)")
local cvRadius  = CreateConVar("lc_ending_flight_radius", "2200", FLAGS, "How wide the flying endings circle the city")

local ROOT = "livingcity/endings/"
local EXT = { wav = true, mp3 = true, ogg = true }

LC.Endings = {
    harpies   = { name = "The Harpies", say = "The lights go out. Something is gathering out there in the dark." },
    bus       = { name = "The Bus", say = "Hear that horn? All aboard." },
    nuanua    = { name = "Nua Nua", say = "Please fasten your seatbelts." },
    topsecret = { name = "Top Secret", say = "Look up." },
    grigori   = { name = "The Flood", say = "Father Grigori has eaten the motherlode. The waters rise." },
    bloom     = { name = "Bloom", say = "Everybody dances. Nobody stops." },
    marrow    = { name = "Marrow", say = "Something is rattling out there. Lots of somethings." },
}
LC.EndingOrder = { "harpies", "bus", "nuanua", "topsecret", "grigori", "bloom", "marrow" }

local E -- the ending in progress: { id, phase, by, ... }
function LC.EndingSession() return E end
function LC.EndingBusy() return E ~= nil end

local function All(msg) for _, p in ipairs(player.GetAll()) do p:ChatPrint(msg) end end

------------------------------------------------------------------------
-- Songs, and the cooldown (kept in a file: it outlasts the reload)
------------------------------------------------------------------------

function LC.EndingSongs(id)
    local out = {}
    local dir = "sound/" .. ROOT .. id
    local names = file.Find(dir .. "/*", "GAME") or {}
    table.sort(names)
    for _, n in ipairs(names) do
        local ext = string.match(n, "%.([%w]+)$")
        if ext and EXT[string.lower(ext)] then
            out[#out + 1] = ROOT .. id .. "/" .. n
            if resource and resource.AddFile then resource.AddFile("sound/" .. ROOT .. id .. "/" .. n) end
        end
    end
    return out
end

local COOL_FILE = "livingcity/endings.json"
local function LastEnding()
    local raw = file.Read(COOL_FILE, "DATA")
    if not raw or raw == "" then return 0 end
    local t = util.JSONToTable(raw) or {}
    return tonumber(t.last) or 0
end
local function MarkEnding()
    if file.CreateDir then file.CreateDir("livingcity") end
    file.Write(COOL_FILE, util.TableToJSON({ last = os.time() }))
end
function LC.EndingCooldownLeft()
    return math.max(0, LastEnding() + cvCool:GetFloat() * 60 - os.time())
end

------------------------------------------------------------------------
-- Telling the clients
------------------------------------------------------------------------

local function Send(to)
    net.Start("lc_ending")
    if not E then
        net.WriteTable({})
    else
        local yes, skip = 0, 0
        for _, v in pairs(E.votes or {}) do if v then yes = yes + 1 else skip = skip + 1 end end
        net.WriteTable({ id = E.id, phase = E.phase, name = LC.Endings[E.id].name, say = LC.Endings[E.id].say,
            voteEnds = E.voteEnds, yes = yes, skip = skip, song = E.song, lines = E.lines, grigori = E.grigori,
            floodZ = E.floodZ, client = E.client })
    end
    if to then net.Send(to) else net.Broadcast() end
end

------------------------------------------------------------------------
-- Stopping time
------------------------------------------------------------------------

local function Freeze(on)
    LC.TimeStopped = on or nil
    SetGlobal2Bool("lc_timestop", on and true or false)
    if RunConsoleCommand then RunConsoleCommand("ai_disabled", on and "1" or "0") end
    for _, p in ipairs(player.GetAll()) do
        if on then
            p.lcEndFrozen = true
            p:Freeze(true)
        elseif p.lcEndFrozen then
            p.lcEndFrozen = nil
            p:Freeze(false)
        end
    end
end
LC.EndingFreeze = Freeze

local function SpawnGman(near)
    local by = IsValid(near) and near or player.GetAll()[1]
    if not IsValid(by) then return nil end
    local fwd = by.GetForward and by:GetForward() or Vector(1, 0, 0)
    fwd.z = 0
    fwd = fwd:GetNormalized()
    local pos = by:GetPos() + fwd * 90
    local g = ents.Create("npc_gman")
    if not IsValid(g) then return nil end
    g:SetPos(pos)
    g:SetAngles(Angle(0, (by:GetPos() - pos):Angle().y, 0))
    g:Spawn()
    g:Activate()
    return g
end

------------------------------------------------------------------------
-- The endings themselves
------------------------------------------------------------------------

-- "Taken": out of it, not dead (no new character). Frozen, hidden, the screen goes.
local function Take(p, how)
    if not IsValid(p) or p.lcEndTaken then return end
    p.lcEndTaken = true
    p:Freeze(true)
    if p.SetNoDraw then p:SetNoDraw(true) end
    if p.SetNotSolid then p:SetNotSolid(true) end
    p:SetNW2Bool("lc_end_taken", true)
    if p.ScreenFade then p:ScreenFade(SCREENFADE and SCREENFADE.OUT or 2, Color(0, 0, 0, 255), 1.5, 600) end
    p:ChatPrint(how or "You were taken.")
    hook.Run("LivingCityEndingTook", p, E and E.id)
end
LC.EndingTake = Take

local function Living()
    local out = {}
    for _, p in ipairs(player.GetAll()) do if p:Alive() and not p.lcEndTaken then out[#out + 1] = p end end
    return out
end

local function Centre()
    local sum, n = Vector(0, 0, 0), 0
    for _, p in ipairs(player.GetAll()) do sum = sum + p:GetPos() n = n + 1 end
    return n > 0 and sum * (1 / n) or Vector(0, 0, 0)
end

local function FirstModel(list)
    for _, m in ipairs(list) do if not util.IsValidModel or util.IsValidModel(m) then return m end end
    return list[#list]
end

local function Prop(model, pos, scale)
    local e = ents.Create("prop_dynamic")
    if not IsValid(e) then return nil end
    e:SetModel(model)
    e:SetPos(pos)
    e:Spawn()
    if scale and e.SetModelScale then e:SetModelScale(scale, 0) end
    E.ents[#E.ents + 1] = e
    return e
end

-- Riders: held in place on a moving thing, every tick.
local function Board(vehicle, riders, offsets)
    for i, p in ipairs(riders) do
        p:Freeze(true)
        p:SetMoveType(MOVETYPE_NONE)
        p.lcEndRide = { v = vehicle, off = offsets[i] or Vector(0, 0, 40) }
    end
end

local function Ride(now)
    for _, p in ipairs(player.GetAll()) do
        local r = p.lcEndRide
        if r and IsValid(r.v) then p:SetPos(r.v:GetPos() + r.off) end
    end
end

local SETUP, TICK = {}, {}

-- the Harpies: the mingebags. Lights out, everyone at the landing zone, and
-- old-school Garry's Mod players in the civilian pose, sliding. For the first
-- minute they gather in the dark, far off and out of sight, keeping their
-- distance and getting bolder; when the song swells (lc_ending_minge_swell,
-- 60 s) they rush in and surround everyone; 9 seconds later they leap, all of
-- them, and it's a slaughter. From 1:50 walls don't stop them; by 2:00
-- (lc_ending_minge_end) everyone's gone. The dead watch (spectating).
local cvMingeMax    = CreateConVar("lc_ending_minge_max", "60", FLAGS, "How many mingebags the Harpies ending gathers")
local cvMingeSwell  = CreateConVar("lc_ending_minge_swell", "60", FLAGS, "Seconds into the Harpies' song when it swells and the mingebags rush in (they leap 9 seconds later)")
local cvMingeEnd    = CreateConVar("lc_ending_minge_end", "120", FLAGS, "Seconds into the Harpies' song by which everyone is dead (walls stop mattering 10 seconds before)")
CreateConVar("lc_ending_minge_pose", "ragdoll", FLAGS, "The mingebags' pose: a sequence name on their models (ragdoll: the reference pose)")
local cvMingeModels = CreateConVar("lc_ending_minge_models",
    "models/player/kleiner.mdl", FLAGS, "The mingebags' models (comma-separated; any missing are skipped). Kleiner: the 2007 default, physgun at the crotch")

local RUSH = 9 -- (seconds of rushing in before the leaping)
local UP = Vector(0, 0, 1)

-- The floor under a spot (nil: inside a wall, or nothing there).
local function Ground(pos)
    local tr = util.TraceLine({ start = pos + Vector(0, 0, 120), endpos = pos - Vector(0, 0, 600), mask = MASK_SOLID_BRUSHONLY })
    if not tr.Hit or tr.StartSolid then return nil end
    return tr.HitPos
end

-- Nothing solid between two spots, at knee height.
local function Clear(a, b)
    local tr = util.TraceLine({ start = a + Vector(0, 0, 24), endpos = b + Vector(0, 0, 24), mask = MASK_SOLID_BRUSHONLY })
    return not tr.Hit
end

-- The Combine's own units in the city (they're in this too).
local function CombineNPCs()
    local out = {}
    for npc, st in pairs(LC.NPCs or {}) do
        if IsValid(npc) and LC.IsSecurity and LC.IsSecurity(st) then out[#out + 1] = npc end
    end
    return out
end

-- The Combine's units, to the landing zone with everyone (a ring outside the players).
local function GatherCombine(centre, r)
    local list = CombineNPCs()
    for i, npc in ipairs(list) do
        local a = (i / math.max(1, #list)) * math.pi * 2 + 0.3
        local spot = centre + Vector(math.cos(a) * r, math.sin(a) * r, 0)
        npc:SetPos((Ground(spot) or centre) + Vector(0, 0, 4))
        npc:SetAngles(Angle(0, math.deg(a), 0))
    end
    return list
end

local function Seen(pos)
    for _, p in ipairs(Living()) do
        local tr = util.TraceLine({ start = p:EyePos(), endpos = pos + Vector(0, 0, 50), mask = MASK_SOLID_BRUSHONLY })
        if not tr.Hit then return true end
    end
    return false
end

-- A spot about `dist` from the centre (near `angle`, if given), out of sight if `hide`.
local function RingSpot(centre, dist, hide, angle)
    for i = 1, 10 do
        local a = angle and (angle + math.Rand(-0.5, 0.5)) or math.Rand(0, math.pi * 2)
        local d = dist + math.Rand(-150, 150)
        local g = Ground(centre + Vector(math.cos(a) * d, math.sin(a) * d, 0))
        if g and (not hide or i > 7 or not Seen(g)) then return g, a end
    end
    return nil
end

local function MingeModel()
    local list = {}
    for m in string.gmatch(cvMingeModels:GetString() or "", "[^,]+") do
        m = string.Trim(m)
        if m ~= "" and (not util.IsValidModel or util.IsValidModel(m)) then list[#list + 1] = m end
    end
    return list[math.random(math.max(1, #list))] or "models/player/kleiner.mdl"
end

local function SpawnMinge(pos, angle)
    local m = ents.Create("lc_minge")
    if not IsValid(m) then return nil end
    m.lcModel = MingeModel()
    m:SetModel(m.lcModel)
    m:SetPos(pos)
    m:SetAngles(Angle(0, math.deg(angle or 0) + 180, 0))
    m:Spawn()
    m.lcMinge = { mode = "lurk", angle = angle, hp = 25 }
    E.ents[#E.ents + 1] = m
    E.minges[#E.minges + 1] = m
    return m
end

local function Body(model, pos, yaw, fling)
    local r = ents.Create("prop_ragdoll")
    if not IsValid(r) then return nil end
    r:SetModel(model or "models/player/kleiner.mdl")
    r:SetPos(pos)
    r:SetAngles(Angle(0, yaw or 0, 0))
    r:Spawn()
    if r.GetPhysicsObjectCount then
        for i = 0, r:GetPhysicsObjectCount() - 1 do
            local ph = r:GetPhysicsObjectNum(i)
            if IsValid(ph) then ph:SetVelocity(VectorRand() * fling + Vector(0, 0, fling * 0.6)) end
        end
    end
    E.ents[#E.ents + 1] = r
    E.bodies = E.bodies or {}
    E.bodies[#E.bodies + 1] = r
    if #E.bodies > 40 then local old = table.remove(E.bodies, 1) if IsValid(old) then old:Remove() end end
    return r
end

-- Who a dead player watches: the living first, then the mingebags.
local function Watch(p, dir)
    local list = {}
    for _, q in ipairs(Living()) do list[#list + 1] = q end
    for _, m in ipairs(E and E.minges or {}) do if IsValid(m) then list[#list + 1] = m end end
    if #list == 0 then return end
    p.lcEndWatchI = ((p.lcEndWatchI or 0) + (dir or 1) - 1) % #list + 1
    p.lcEndWatching = list[p.lcEndWatchI]
    if p.SpectateEntity then p:SpectateEntity(p.lcEndWatching) end
end

-- Killed by them: a body on the ground, and the player watches the rest.
-- (Not really dead: no close call spent, no new character; the map resets.)
local function Spectator(p, how, col)
    if not IsValid(p) or p.lcEndTaken then return end
    p.lcEndTaken, p.lcEndSpectating = true, true
    p:SetNW2Bool("lc_end_taken", true)
    p:SetNW2Bool("lc_end_spectating", true)
    if p.SetNoDraw then p:SetNoDraw(true) end
    if p.SetNotSolid then p:SetNotSolid(true) end
    if p.Spectate then p:Spectate(OBS_MODE_CHASE) end
    Watch(p, 1)
    if p.ScreenFade then p:ScreenFade(SCREENFADE and SCREENFADE.IN or 1, col or Color(140, 0, 0, 220), 2, 0) end
    p:ChatPrint(how or "You're out of it. Watch the rest.")
    hook.Run("LivingCityEndingTook", p, E and E.id)
end
LC.EndingSpectator = Spectator

local function Slaughter(p, how)
    if not IsValid(p) or p.lcEndTaken then return end
    Body(p:GetModel(), p:GetPos(), p:EyeAngles().y, 260)
    p:EmitSound("vo/npc/male01/pain0" .. math.random(7, 9) .. ".wav", 80)
    Spectator(p, how or "The mingebags got you.")
end
LC.EndingSlaughter = Slaughter

local function Hit(p)
    if not IsValid(p) or p.lcEndTaken then return false end
    local now = CurTime()
    if now < (p.lcMingeHitAt or 0) then return false end
    p.lcMingeHitAt = now + 0.3
    if not p:IsPlayer() then -- (one of the Combine's units)
        p:SetHealth(p:Health() - math.random(10, 18))
        p:EmitSound("physics/body/body_medium_impact_hard" .. math.random(1, 6) .. ".wav", 75)
        if p:Health() <= 0 then Body(p:GetModel(), p:GetPos(), p:GetAngles().y, 260) p:Remove() end
        return true
    end
    p:SetHealth(p:Health() - math.random(7, 12))
    if p.ViewPunch then p:ViewPunch(Angle(math.Rand(-10, 10), math.Rand(-10, 10), 0)) end
    p:EmitSound("physics/body/body_medium_impact_hard" .. math.random(1, 6) .. ".wav", 75)
    if util.Effect and EffectData then
        local fx = EffectData()
        fx:SetOrigin(p:GetPos() + Vector(0, 0, 40))
        util.Effect("BloodImpact", fx)
    end
    if p:Health() <= 0 then Slaughter(p, "They're on you, all of them, in that pose. The mingebags got you.") end
    return true
end

-- One step of a mingebag's slide or leap (each server tick: lc_minge.lua).
function LC.MingeStep(m, dt)
    local s = m.lcMinge
    if not s or not E or E.id ~= "harpies" then return end
    local now = CurTime()
    local pos = m:GetPos()
    if s.leap then
        local L = s.leap
        local f = math.min(1, (now - L.t0) / L.dur)
        m:SetPos(LerpVector(f, L.from, L.to) + UP * (4 * L.h * f * (1 - f)))
        if f >= 1 then
            s.leap = nil
            local t = s.target
            if IsValid(t) and (t:IsPlayer() or t:IsNPC()) and t:GetPos():DistToSqr(m:GetPos()) < 80 * 80 then Hit(t) end
        end
        return
    end
    if not s.goal then return end
    local to = s.goal - pos
    to.z = 0
    local dist = to:Length()
    if dist < 4 then return end
    local dir = to * (1 / dist)
    local step = math.min(dist, (s.speed or 100) * (dt or 0.1))
    local nextPos = pos + dir * step
    if not s.noclip then
        if not Clear(pos, nextPos + dir * 16) then
            local found
            for _, turn in ipairs({ 50, -50, 90, -90 }) do
                local a = dir:Angle()
                a.y = a.y + turn
                local alt = pos + a:Forward() * step
                if Clear(pos, alt + a:Forward() * 16) then nextPos, found = alt, true break end
            end
            if not found then s.stuck = (s.stuck or 0) + (dt or 0.1) return end
        end
        s.stuck = 0
        local g = Ground(nextPos)
        if g and math.abs(g.z - pos.z) < 60 then nextPos.z = g.z end
    else
        local g = Ground(nextPos)
        nextPos.z = g and g.z or nextPos.z + (s.goal.z - nextPos.z) * 0.2
    end
    m:SetPos(nextPos)
end

-- Shot: nothing touches them until they've gathered; after that one goes
-- down, and another takes its place.
function LC.MingeHurt(m, dmg)
    local s = m.lcMinge
    if not s or not E or not E.vulnerable then return false end
    s.hp = s.hp - (dmg and dmg.GetDamage and dmg:GetDamage() or 25)
    if s.hp > 0 then return false end
    Body(m:GetModel(), m:GetPos(), m:GetAngles().y, 120)
    m:Remove()
    return true
end

local function Nearest(pos, list)
    local best, bd
    for _, p in ipairs(list) do
        local d = p:GetPos():DistToSqr(pos)
        if not bd or d < bd then best, bd = p, d end
    end
    return best, bd and math.sqrt(bd) or nil
end

SETUP.harpies = function()
    E.minges, E.bodies = {}, {}
    local lz = LC.PointsOfKind and LC.PointsOfKind("lz") or {}
    E.lz = (#lz > 0 and lz[1].pos) or (LC.SupplyDropSpot and LC.SupplyDropSpot()) or (IsValid(E.by) and E.by:GetPos()) or Centre()
    E.holdUntil = CurTime() + cvMingeEnd:GetFloat()
    if LC.OpenEveryDoor then LC.OpenEveryDoor() E.doorsOpen = true end -- (every door locked open: nothing stuck behind one, them or us)
    -- everyone to the landing zone, facing out into the dark
    local ps = player.GetAll()
    for i, p in ipairs(ps) do
        if p.InVehicle and p:InVehicle() and p.ExitVehicle then p:ExitVehicle() end
        local a = (i / math.max(1, #ps)) * math.pi * 2
        local r = 60 + 12 * #ps
        local spot = E.lz + Vector(math.cos(a) * r, math.sin(a) * r, 0)
        p:SetPos((Ground(spot) or E.lz) + Vector(0, 0, 4))
        if p.SetEyeAngles then p:SetEyeAngles(Angle(0, math.deg(a), 0)) end
        if p:Health() < 100 then p:SetHealth(100) end
    end
    -- the city stops, and the Combine's units are out there with everyone, in a ring round them
    LC.TimeStopped = true
    if RunConsoleCommand then RunConsoleCommand("ai_disabled", "1") end
    E.combine = GatherCombine(E.lz, 150 + 12 * #ps)
    -- and every light in the city goes out
    E.dark = true
    LC.EndingDark = true
    if LC.ForceBlackout then LC.ForceBlackout("on") end
    if LC.ApplyLightStyle then LC.ApplyLightStyle() end
end

TICK.harpies = function(now)
    local t = now - E.phaseT
    local swell, fin = cvMingeSwell:GetFloat(), cvMingeEnd:GetFloat()
    local living = Living()
    local targets = {}
    for _, p in ipairs(living) do targets[#targets + 1] = p end
    for _, n in ipairs(E.combine or {}) do if IsValid(n) then targets[#targets + 1] = n end end
    local centre = E.lz
    local mode = t < swell and "lurk" or (t < swell + RUSH and "rush" or "leap")
    local noclip = t >= fin - 10
    local k = math.Clamp(t / swell, 0, 1)
    local far = 2400 - 1800 * k -- (how far off they keep: closer as the song goes on)
    E.vulnerable = t >= swell - 10
    E.mode = mode

    -- gather: a handful at first, a crowd by the swell, replaced as fast as they fall after it
    local alive = {}
    for _, m in ipairs(E.minges) do if IsValid(m) then alive[#alive + 1] = m end end
    E.minges = alive
    local want = mode == "lurk" and math.floor(4 + (cvMingeMax:GetInt() - 4) * k ^ 1.3) or cvMingeMax:GetInt()
    if #E.minges < want and now >= (E.nextSpawn or 0) then
        E.nextSpawn = now + (mode == "lurk" and 0.4 or 0.1)
        local g, a = RingSpot(centre, mode == "lurk" and far or 900, mode == "lurk" and k < 0.6)
        if g then SpawnMinge(g, a) end
    end

    for i, m in ipairs(E.minges) do
        local s = m.lcMinge
        local pos = m:GetPos()
        s.noclip = noclip
        local near, nd = Nearest(pos, living)
        local face = (near and near:GetPos()) or centre
        m:SetAngles(Angle(0, (face - pos):Angle().y, 0))
        if mode == "lurk" then
            -- keep their distance, at the edge of the dark, a little bolder all the time
            s.speed = 40 + 160 * k
            if not s.goal or (pos:DistToSqr(s.goal) < 30 * 30 and now >= (s.rest or 0)) or math.abs((s.ringD or far) - far) > 250 then
                local g, a = RingSpot(centre, far, k < 0.6, s.angle)
                if g then s.goal, s.angle, s.ringD = g, a, far end
                s.rest = now + math.Rand(2, 6)
            end
            if near and nd < far * 0.5 then
                -- someone walks up to one: it backs away into the dark
                s.goal = pos + (pos - near:GetPos()):GetNormalized() * 500
                s.speed = 260 - 120 * k
                s.rest = now + 3
            end
        else
            -- each has someone (shared out evenly: players and the Combine's units) and a place round them
            if not IsValid(s.target) or s.target.lcEndTaken then
                s.target = #targets > 0 and targets[(i - 1) % #targets + 1] or nil
                s.slot = math.Rand(0, math.pi * 2)
                s.ring = math.floor((i - 1) / math.max(1, #targets) / 8)
            end
            local tp = IsValid(s.target) and s.target:GetPos()
                or (#E.bodies > 0 and IsValid(E.bodies[#E.bodies]) and E.bodies[#E.bodies]:GetPos()) or centre
            if mode == "rush" then
                s.goal = tp + Vector(math.cos(s.slot), math.sin(s.slot), 0) * (60 + 32 * (s.ring or 0))
                s.speed = 650
            elseif not s.leap and now >= (s.nextLeap or 0) then
                local d = pos:Distance(tp)
                if d < 520 and (noclip or Clear(pos, tp)) then
                    local dur = 0.3 + d / 1500
                    s.leap = { from = pos, to = tp + Vector(math.Rand(-15, 15), math.Rand(-15, 15), 0), t0 = now, dur = dur, h = 30 + d * 0.18 }
                    s.nextLeap = now + dur + math.Rand(0.15, 0.7)
                else
                    s.goal, s.speed = tp, noclip and 700 or 520
                end
            end
            -- stuck behind something (before the walls stop mattering): around the other way, out of sight
            if not noclip and (s.stuck or 0) > 1.5 and IsValid(s.target) then
                local g = RingSpot(tp, 350, true)
                if g then m:SetPos(g) s.stuck = 0 end
            end
        end
    end

    -- the last two seconds: nobody's left
    if t >= fin - 2 then
        for _, p in ipairs(living) do Slaughter(p, "There's nowhere left. The mingebags got you.") end
        for _, n in ipairs(E.combine or {}) do if IsValid(n) then Body(n:GetModel(), n:GetPos(), n:GetAngles().y, 260) n:Remove() end end
    end
    -- the dead keep watching someone
    for _, p in ipairs(player.GetAll()) do
        if p.lcEndSpectating and (not IsValid(p.lcEndWatching) or p.lcEndWatching.lcEndTaken) then Watch(p, 1) end
    end
    -- (anything that doesn't move itself every tick, moves here)
    for _, m in ipairs(E.minges) do if IsValid(m) and not m.lcThinks then LC.MingeStep(m, 0.1) end end
end

-- The dead watching: left and right click, someone else; jump, fly free.
hook.Add("KeyPress", "LivingCityEndingWatch", function(p, key)
    if not E or not p.lcEndSpectating then return end
    if key == IN_ATTACK then Watch(p, 1)
    elseif key == IN_ATTACK2 then Watch(p, -1)
    elseif key == IN_JUMP and p.Spectate then
        p.lcEndRoam = not p.lcEndRoam
        p:Spectate(p.lcEndRoam and OBS_MODE_ROAM or OBS_MODE_CHASE)
        if not p.lcEndRoam then Watch(p, 0) end
    end
end)

-- Bloom: everyone dances (players, and every NPC in the city), and nobody
-- can stop. The city dims, coloured light pulses on the beat, the props
-- hop. At lc_ending_bloom_speedup (2:01) the song starts speeding up; at the
-- top of it, the dancers spin up into the sky one at a time and burst.
-- (The song's own name stays out of everything players can see: the folder
-- is endings/bloom/, and the file can be called anything.)
local cvBloomBPM     = CreateConVar("lc_ending_bloom_bpm", "165", FLAGS, "Bloom: the song's beats per minute (the dance keeps to it)")
local cvBloomOffset  = CreateConVar("lc_ending_bloom_offset", "0", FLAGS, "Bloom: seconds into the song of its first beat")
local cvBloomSpeedup = CreateConVar("lc_ending_bloom_speedup", "121", FLAGS, "Bloom: seconds into the song when it starts speeding up")
local cvBloomRamp    = CreateConVar("lc_ending_bloom_ramp", "20", FLAGS, "Bloom: seconds it takes to reach top speed")
local cvBloomPeak    = CreateConVar("lc_ending_bloom_peak", "1.6", FLAGS, "Bloom: top speed (1.6: 60% faster, and higher, like a record spun up)")
local cvBloomWindow  = CreateConVar("lc_ending_bloom_launch_secs", "16", FLAGS, "Bloom: seconds over which everyone spins up into the sky, one at a time, once it's at top speed")

local function Dancers()
    local out = {}
    for npc in pairs(LC.NPCs or {}) do if IsValid(npc) then out[#out + 1] = npc end end
    return out
end

SETUP.bloom = function()
    E.dark = true
    LC.EndingDark = "e" -- (dim, so the coloured light shows)
    if LC.ApplyLightStyle then LC.ApplyLightStyle() end
    -- the city stops what it's doing...
    LC.TimeStopped = true
    if RunConsoleCommand then RunConsoleCommand("ai_disabled", "1") end
    -- ...and dances
    for _, p in ipairs(player.GetAll()) do
        if p.InVehicle and p:InVehicle() and p.ExitVehicle then p:ExitVehicle() end
        p.lcEndFrozen = true -- (so a cancel lets them go again)
        p:Freeze(true)
        p:SetNW2Bool("lc_dancing", true)
    end
    for _, n in ipairs(Dancers()) do n:SetNW2Bool("lc_dancing", true) end
    -- the props near anyone hop along
    local props, seen = {}, {}
    for _, p in ipairs(player.GetAll()) do
        for _, e in ipairs(ents.FindInSphere(p:GetPos(), 900)) do
            local c = IsValid(e) and e:GetClass() or ""
            if not seen[e] and #props < 48 and (c == "prop_physics" or c == "prop_dynamic" or c == "prop_physics_multiplayer") then
                seen[e] = true
                props[#props + 1] = e:EntIndex()
            end
        end
    end
    local now = CurTime()
    E.client = { party = true, lights = true, overlay = "bloom", dance = "ears", bpm = cvBloomBPM:GetFloat(), offset = cvBloomOffset:GetFloat(), start = now,
        rateAt = now + cvBloomSpeedup:GetFloat(), rateDur = math.max(1, cvBloomRamp:GetFloat()), peak = math.max(1, cvBloomPeak:GetFloat()),
        props = props }
    E.climax = E.client.rateAt + E.client.rateDur
    E.launchGap = math.Clamp(cvBloomWindow:GetFloat() / math.max(1, #player.GetAll()), 0.6, 3)
    E.holdUntil = E.climax + math.max(cvBloomWindow:GetFloat(), E.launchGap * #player.GetAll()) + 5 -- (the last one up, and a moment)
    E.launching = {}
end

-- One dancer spins up into the sky, and bursts.
local function Launch(e, now)
    if not IsValid(e) or e.lcBloomUp then return end
    e.lcBloomUp = { t0 = now, from = e:GetPos() }
    e:SetNW2Float("lc_spin_t0", now)
    if e:IsPlayer() then e:SetMoveType(MOVETYPE_NONE) end
    E.launching[#E.launching + 1] = e
end

TICK.bloom = function(now)
    if now >= (E.climax or math.huge) then
        -- the players, one at a time
        if now >= (E.nextLaunch or 0) then
            E.nextLaunch = now + E.launchGap
            local pick = {}
            for _, p in ipairs(Living()) do if not p.lcBloomUp then pick[#pick + 1] = p end end
            if #pick > 0 then Launch(pick[math.random(#pick)], now) end
        end
        -- and the city's own dancers, a few at a time
        if now >= (E.nextNPCLaunch or 0) then
            E.nextNPCLaunch = now + 0.25
            for _, n in ipairs(Dancers()) do if not n.lcBloomUp then Launch(n, now) break end end
        end
    end
    local keep = {}
    for _, e in ipairs(E.launching) do
        local u = IsValid(e) and e.lcBloomUp
        if u then
            local t = now - u.t0
            e:SetPos(u.from + Vector(0, 0, 40 * t + 160 * t * t))
            if t >= 2.5 then
                if util.Effect and EffectData then
                    local fx = EffectData()
                    fx:SetOrigin(e:GetPos() + Vector(0, 0, 40))
                    if fx.SetStart then fx:SetStart(Vector(255, 120, 200)) end
                    util.Effect("balloon_pop", fx)
                end
                e:EmitSound("garrysmod/balloon_pop_cute.wav", 90)
                if e:IsPlayer() then
                    if e.SetNoDraw then e:SetNoDraw(true) end
                    Spectator(e, "You spin up into the sky and burst into sparkles. Watch the rest go.", Color(255, 150, 210, 220))
                else
                    e:Remove()
                end
            else
                keep[#keep + 1] = e
            end
        end
    end
    E.launching = keep
end

-- Marrow: skeletons. Everyone (the Combine's units too) is put at the
-- landing zone and the city dims; skeletons appear dancing all over the map
-- and work their way in. The song's sections decide the rest
-- (lc_ending_marrow_sections): on the heavy parts everyone is made to dance
-- with them, a club, strobing (the rave part faster); in between, the
-- skeletons attack, and whoever they get becomes one of them, dancing for
-- good; at the outro they claim whoever's left.
local cvMarrowSections = CreateConVar("lc_ending_marrow_sections", "45:dance,75:attack,82:rave,112:attack,150:dance,180:attack,188:dance,217:outro,232:end", FLAGS,
    "Marrow: the song's sections, second:kind (dance, rave, attack, outro, end); before the first, the skeletons gather")
local cvMarrowMax   = CreateConVar("lc_ending_marrow_max", "40", FLAGS, "Marrow: how many skeletons")
local cvMarrowBPM   = CreateConVar("lc_ending_marrow_bpm", "128", FLAGS, "Marrow: the song's beats per minute (the dancing and the lights keep to it)")
local cvMarrowModel = CreateConVar("lc_ending_marrow_model", "models/player/skeleton.mdl", FLAGS, "Marrow: the skeletons' model")
local SPOOKY = { { 170, 60, 255 }, { 255, 130, 20 } } -- (purple and orange)
local DANCING = { dance = true, rave = true, outro = true }

function LC.MarrowSections(str)
    local out = {}
    for t, kind in string.gmatch(str or cvMarrowSections:GetString(), "([%d%.]+)%s*:%s*(%a+)") do out[#out + 1] = { t = tonumber(t), kind = string.lower(kind) } end
    table.sort(out, function(x, y) return x.t < y.t end)
    return out
end

local function SectionAt(t)
    local kind = "intro"
    for _, sct in ipairs(E.sections) do if t >= sct.t then kind = sct.kind end end
    return kind
end

local function SpawnSkel(pos)
    local k = ents.Create("lc_skel")
    if not IsValid(k) then return nil end
    k.lcModel = cvMarrowModel:GetString()
    k:SetModel(k.lcModel)
    k:SetPos(pos)
    k:Spawn()
    k.lcSkel = { hp = 40, phase = "walk", untilT = CurTime() + math.Rand(3, 6) }
    E.ents[#E.ents + 1] = k
    E.skels[#E.skels + 1] = k
    return k
end

local function Anim(m, name)
    local s = m.lcSkel
    if s.anim == name or not m.LookupSequence then return end
    s.anim = name
    local seq = m:LookupSequence(name)
    if seq and seq >= 0 then m:ResetSequence(seq) if m.SetPlaybackRate then m:SetPlaybackRate(1) end end
end

-- Got by a skeleton: you're one of them now, dancing for good.
local function Convert(p, how)
    if not IsValid(p) or p.lcEndTaken then return end
    p.lcEndTaken = true
    p.lcEndModel = p.lcEndModel or p:GetModel()
    p:SetModel(cvMarrowModel:GetString())
    p:SetNW2Bool("lc_end_taken", true)
    p.lcEndFrozen = true
    p:Freeze(true)
    p:SetNW2Bool("lc_dancing", true)
    if p.ScreenFade then p:ScreenFade(SCREENFADE and SCREENFADE.IN or 1, Color(90, 255, 120, 200), 1.5, 0) end
    p:ChatPrint(how or "The skeletons got you. You're one of them now. Dance.")
    hook.Run("LivingCityEndingTook", p, E and E.id)
end

-- A unit of the Combine caught: a skeleton where it stood.
local function Bones(npc)
    if not IsValid(npc) then return end
    local pos = npc:GetPos()
    npc:Remove()
    local k = SpawnSkel(pos)
    if k then k:SetNW2Bool("lc_dancing", DANCING[E.section] or false) end
end

local function Claw(target)
    local now = CurTime()
    if not IsValid(target) or now < (target.lcClawAt or 0) then return end
    target.lcClawAt = now + 0.6
    target:EmitSound("npc/zombie/claw_strike" .. math.random(1, 3) .. ".wav", 75)
    target:SetHealth(target:Health() - math.random(8, 14))
    if target:IsPlayer() then
        if target.ViewPunch then target:ViewPunch(Angle(math.Rand(-8, 8), math.Rand(-8, 8), 0)) end
        if target:Health() <= 0 then Convert(target) end
    elseif target:Health() <= 0 then
        Bones(target)
    end
end

-- One step of a skeleton (each server tick: lc_skel.lua).
function LC.SkelStep(m, dt)
    local s = m.lcSkel
    if not s or not E or E.id ~= "marrow" then return end
    local pos = m:GetPos()
    if not s.goal or m:GetNW2Bool("lc_dancing", false) then Anim(m, "idle_all_01") return end
    local to = s.goal - pos
    to.z = 0
    local dist = to:Length()
    if dist < 6 then Anim(m, "idle_all_01") return end
    Anim(m, (s.speed or 0) > 180 and "run_all_01" or "walk_all")
    local dir = to * (1 / dist)
    local step = math.min(dist, (s.speed or 100) * (dt or 0.1))
    local nextPos = pos + dir * step
    if not Clear(pos, nextPos + dir * 16) then
        local found
        for _, turn in ipairs({ 50, -50, 90, -90 }) do
            local a = dir:Angle()
            a.y = a.y + turn
            local alt = pos + a:Forward() * step
            if Clear(pos, alt + a:Forward() * 16) then nextPos, found = alt, true break end
        end
        if not found then s.stuck = (s.stuck or 0) + (dt or 0.1) return end
    end
    s.stuck = 0
    local g = Ground(nextPos)
    if g and math.abs(g.z - pos.z) < 60 then nextPos.z = g.z end
    m:SetPos(nextPos)
    m:SetAngles(Angle(0, dir:Angle().y, 0))
end

-- Hurt: only in a fight (dancing, they're untouchable); down it goes, and another comes later.
function LC.SkelHurt(m, dmg)
    local s = m.lcSkel
    if not s or not E or E.section ~= "attack" then return false end
    s.hp = s.hp - (dmg and dmg.GetDamage and dmg:GetDamage() or 40)
    if s.hp > 0 then return false end
    Body(m:GetModel(), m:GetPos(), m:GetAngles().y, 100)
    m:EmitSound("physics/wood/wood_box_break" .. math.random(1, 2) .. ".wav", 75)
    m:Remove()
    E.nextSpawn = CurTime() + 3
    return true
end

local function ApplySection(kind, now)
    E.section = kind
    local dancing = DANCING[kind] or false
    E.client.lights = true -- (purple and orange, all the way through)
    E.client.strobe = kind == "dance" or kind == "rave"
    E.client.dance = kind == "rave" and "rave" or "club"
    E.client.danceRate = (kind == "rave" and 1.5) or (kind == "outro" and 2) or 1 -- (the xylophone outro: double time)
    for _, p in ipairs(player.GetAll()) do
        if p.lcEndTaken then
            p:SetNW2Bool("lc_dancing", true)
        elseif dancing then
            p.lcEndFrozen = true
            p:Freeze(true)
            p:SetNW2Bool("lc_dancing", true)
        else
            p.lcEndFrozen = nil
            p:Freeze(false)
            p:SetNW2Bool("lc_dancing", false)
        end
    end
    for _, n in ipairs(CombineNPCs()) do n:SetNW2Bool("lc_dancing", dancing) end
    for _, k in ipairs(E.skels) do
        if IsValid(k) then
            k:SetNW2Bool("lc_dancing", dancing)
            if dancing then k.lcSkel.goal = nil end
        end
    end
    if kind == "outro" then
        for _, p in ipairs(Living()) do Convert(p, "The skeletons claim everyone in the end. You're one of them now. Dance it out.") end
        for _, n in ipairs(CombineNPCs()) do Bones(n) end
    end
    Send()
end

SETUP.marrow = function()
    local now = CurTime()
    E.skels = {}
    E.sections = LC.MarrowSections()
    local lz = LC.PointsOfKind and LC.PointsOfKind("lz") or {}
    E.lz = (#lz > 0 and lz[1].pos) or (IsValid(E.by) and E.by:GetPos()) or Centre()
    for _, sct in ipairs(E.sections) do if sct.kind == "end" then E.holdUntil = now + sct.t end end
    E.holdUntil = E.holdUntil or (now + 232)
    if LC.OpenEveryDoor then LC.OpenEveryDoor() E.doorsOpen = true end -- (every door locked open: nothing stuck behind one, them or us)
    -- the city stops; everyone (the Combine's units too) to the landing zone; the lights dim
    LC.TimeStopped = true
    if RunConsoleCommand then RunConsoleCommand("ai_disabled", "1") end
    local ps = player.GetAll()
    for i, p in ipairs(ps) do
        if p.InVehicle and p:InVehicle() and p.ExitVehicle then p:ExitVehicle() end
        local a = (i / math.max(1, #ps)) * math.pi * 2
        local r = 60 + 12 * #ps
        p:SetPos((Ground(E.lz + Vector(math.cos(a) * r, math.sin(a) * r, 0)) or E.lz) + Vector(0, 0, 4))
        if p:Health() < 100 then p:SetHealth(100) end
    end
    GatherCombine(E.lz, 100 + 12 * #ps)
    -- the map goes dark (every lamp out), and the coloured light pulses everywhere
    E.dark = true
    LC.EndingDark = true
    if LC.ForceBlackout then LC.ForceBlackout("on") end
    if LC.ApplyLightStyle then LC.ApplyLightStyle() end
    E.client = { party = true, lights = true, ambient = true, dance = "club", palette = SPOOKY, bpm = cvMarrowBPM:GetFloat(), offset = 0, start = now }
    E.section = "intro"
end

TICK.marrow = function(now)
    local t = now - E.phaseT
    local kind = SectionAt(t)
    if kind ~= E.section and kind ~= "end" then ApplySection(kind, now) end
    local alive = {}
    for _, k in ipairs(E.skels) do if IsValid(k) then alive[#alive + 1] = k end end
    E.skels = alive
    -- more of them, all over the map at first
    local max = cvMarrowMax:GetInt()
    local want = E.section == "intro" and math.floor(max * math.Clamp(t / 30, 0.15, 1)) or max
    if #E.skels < want and now >= (E.nextSpawn or 0) then
        E.nextSpawn = now + (E.section == "intro" and 0.3 or 1)
        local g = RingSpot(E.lz, E.section == "intro" and math.Rand(1500, 3500) or 1200, false)
        if g then
            local k = SpawnSkel(g)
            if k then k:SetNW2Bool("lc_dancing", DANCING[E.section] or false) end
        end
    end
    local targets = {}
    for _, p in ipairs(Living()) do targets[#targets + 1] = p end
    if #targets == 0 then targets = CombineNPCs() end
    for _, k in ipairs(E.skels) do
        local s = k.lcSkel
        if E.section == "intro" then
            -- dancing their way in: walk a while, stop and dance a while
            if now >= s.untilT then
                if s.phase == "walk" then
                    s.phase, s.untilT, s.goal = "dance", now + math.Rand(1.5, 3), nil
                    k:SetNW2Bool("lc_dancing", true)
                else
                    s.phase, s.untilT = "walk", now + math.Rand(3, 6)
                    k:SetNW2Bool("lc_dancing", false)
                    local a = math.Rand(0, math.pi * 2)
                    s.goal = E.lz + Vector(math.cos(a), math.sin(a), 0) * math.Rand(250, 450)
                    s.speed = 140
                end
            end
        elseif E.section == "attack" then
            -- at whoever's nearest, and the claws
            local best, bd = nil, nil
            for _, p in ipairs(targets) do
                local d = p:GetPos():DistToSqr(k:GetPos())
                if not bd or d < bd then best, bd = p, d end
            end
            if best then
                s.goal, s.speed = best:GetPos(), 230
                if bd < 60 * 60 then Claw(best) end
            end
            if (s.stuck or 0) > 1.5 and best then
                local g = RingSpot(best:GetPos(), 300, true)
                if g then k:SetPos(g) s.stuck = 0 end
            end
        end
        if not k.lcThinks then LC.SkelStep(k, 0.1) end
    end
end

-- flying things: a vehicle per group of riders, circling the city
local function Fly(models, perVehicle, height, speed, scale, secs)
    E.flights = {}
    E.flightSecs = secs
    local living = Living()
    local centre = Centre()
    local model = FirstModel(models)
    local groups = math.max(1, math.ceil(#living / perVehicle))
    for g = 1, groups do
        local riders = {}
        for i = (g - 1) * perVehicle + 1, math.min(#living, g * perVehicle) do riders[#riders + 1] = living[i] end
        local v = Prop(model, centre + Vector(0, 0, height), scale)
        if v then
            local offs = {}
            for i = 1, #riders do offs[i] = Vector((i - (#riders + 1) / 2) * 40, 0, 50) end
            Board(v, riders, offs)
            E.flights[#E.flights + 1] = { v = v, phase = (g - 1) / groups * math.pi * 2, height = height, speed = speed }
        end
    end
    E.centre = centre
    E.started = CurTime()
end

local function FlyTick(now)
    local r = cvRadius:GetFloat()
    for i, f in ipairs(E.flights or {}) do
        if IsValid(f.v) then
            local a = f.phase + (now - E.started) * f.speed
            local pos = E.centre + Vector(math.cos(a) * r, math.sin(a) * r, f.height + math.sin(a * 3 + i) * 120)
            f.v:SetPos(pos)
            f.v:SetAngles(Angle(math.sin(a * 2) * 12, math.deg(a) + 90, math.cos(a * 3) * 18))
        end
    end
    Ride(now)
    -- the ride lasts the song, more or less, and then nobody ever gets off
    if now - E.started > (E.flightSecs or 80) then
        for _, p in ipairs(Living()) do Take(p, E.id == "nuanua" and "The plane climbs into the clouds and keeps climbing." or "The bus doesn't stop. It never stops.") end
    end
end

-- The Bus: the party bus. It drives about the streets through the
-- song's intro; on the drop (lc_ending_bus_sections) everyone, and some of
-- the Combine's units, are in it, seated, and it takes off: through walls,
-- a rainbow behind it, its speed surging on the beat, rings to fly through,
-- the light inside pulsing. It comes down and drives again for a while,
-- then takes off faster still. Nobody gets off (die, and you're back on).
local cvBusSections = CreateConVar("lc_ending_bus_sections", "27:fly,149:drive,176:fast,220:end", FLAGS,
    "The Bus: the song's sections, second:kind (fly, drive, fast, end); before the first, it drives about the streets")
local cvBusBPM   = CreateConVar("lc_ending_bus_bpm", "138", FLAGS, "The Bus: the song's beats per minute (its speed and the lights keep to it)")
local cvBusCombine = CreateConVar("lc_ending_bus_combine", "6", FLAGS, "The Bus: how many of the Combine's units get on too")
local BUS = { "models/props_vehicles/bus01_2.mdl", "models/props_vehicles/van001a_physics.mdl" }
local RAINBOW = { { 255, 40, 40 }, { 255, 150, 30 }, { 255, 240, 40 }, { 60, 230, 80 }, { 60, 140, 255 }, { 170, 70, 255 } }
local RING = "models/hunter/tubes/tube4x4x025.mdl"

local function BusSection(t)
    local kind = "drive"
    for _, sct in ipairs(E.sections) do if t >= sct.t then kind = sct.kind end end
    return kind
end

-- A seat: rows down the bus, two across, and on top of each other when it's full.
local function Seat(i)
    local row, side, layer = (i - 1) % 8, math.floor((i - 1) / 8) % 2, math.floor((i - 1) / 16)
    return Vector(-140 + row * 40, side == 0 and -24 or 24, 18 + layer * 46)
end

local function BusBoard(e)
    if not IsValid(e) or e.lcEndRide then return end
    E.seats = (E.seats or 0) + 1
    e.lcEndRide = { v = E.bus, off = Seat(E.seats) }
    E.riders = E.riders or {}
    E.riders[#E.riders + 1] = e
    if e:IsPlayer() then
        if e.InVehicle and e:InVehicle() and e.ExitVehicle then e:ExitVehicle() end
        e.lcEndFrozen = true
        e:Freeze(true)
        e:SetMoveType(MOVETYPE_NONE)
    end
    e:SetNW2Bool("lc_seated", true)
    e:SetNW2Bool("lc_dancing", true)
end

local function GroundSpot(near)
    local a = math.Rand(0, math.pi * 2)
    local d = math.Rand(400, 1100)
    return Ground(near + Vector(math.cos(a) * d, math.sin(a) * d, 0)) or near
end

local function SkySpot()
    local r = cvRadius:GetFloat()
    local p = E.centre + Vector(math.Rand(-r, r), math.Rand(-r, r), 0)
    local g = Ground(p)
    return Vector(p.x, p.y, (g and g.z or E.centre.z) + math.Rand(300, 1100))
end

local function NewRing(at, from)
    local ring = ents.Create("prop_dynamic")
    if not IsValid(ring) then return end
    ring:SetModel(RING)
    ring:SetPos(at)
    local dir = (at - from)
    ring:SetAngles(dir:Angle() + Angle(90, 0, 0)) -- (facing the way the bus comes)
    ring:Spawn()
    if ring.SetModelScale then ring:SetModelScale(1.7, 0) end
    if ring.SetSolid then ring:SetSolid(SOLID_NONE) end
    if ring.SetRenderMode then ring:SetRenderMode(RENDERMODE_TRANSCOLOR) end
    E.ents[#E.ents + 1] = ring
    E.rings[#E.rings + 1] = ring
end

SETUP.bus = function()
    local now = CurTime()
    E.sections = LC.MarrowSections(cvBusSections:GetString())
    for _, sct in ipairs(E.sections) do if sct.kind == "end" then E.holdUntil = now + sct.t end end
    E.holdUntil = E.holdUntil or (now + 220)
    local lz = LC.PointsOfKind and LC.PointsOfKind("lz") or {}
    E.centre = (#lz > 0 and lz[1].pos) or Centre()
    E.rings = {}
    LC.TimeStopped = true -- (the city stops and watches)
    if RunConsoleCommand then RunConsoleCommand("ai_disabled", "1") end
    -- the bus, somewhere near people, on the road
    local near = (Living()[1] and Living()[1]:GetPos()) or E.centre
    local bus = Prop(FirstModel(BUS), GroundSpot(near))
    if not bus then return end
    if bus.SetSolid then bus:SetSolid(SOLID_NONE) end
    E.bus = bus
    E.busDir = Vector(1, 0, 0)
    E.goal = GroundSpot(near)
    -- the rainbow behind it: a trail of each colour, one above the other
    for i, c in ipairs(RAINBOW) do
        local a = ents.Create("prop_dynamic")
        if IsValid(a) then
            a:SetModel("models/hunter/plates/plate.mdl")
            a:SetPos(bus:GetPos())
            a:Spawn()
            if a.SetNoDraw then a:SetNoDraw(true) end
            if a.SetSolid then a:SetSolid(SOLID_NONE) end
            a:SetParent(bus)
            if a.SetLocalPos then a:SetLocalPos(Vector(-230, 0, 20 + (#RAINBOW - i) * 14)) end
            if util.SpriteTrail then util.SpriteTrail(a, 0, Color(c[1], c[2], c[3]), true, 16, 4, 2.5, 1 / 20 * 0.5, "trails/laser.vmt") end
            E.ents[#E.ents + 1] = a
        end
    end
    E.client = { party = true, lights = true, dance = "bus", palette = RAINBOW, bpm = cvBusBPM:GetFloat(), offset = 0, start = now, bus = bus:EntIndex() }
    E.section = "intro"
end

local function BoardBus()
    for _, p in ipairs(player.GetAll()) do BusBoard(p) end
    local n = 0
    for _, npc in ipairs(CombineNPCs()) do
        if n >= cvBusCombine:GetInt() then break end
        n = n + 1
        BusBoard(npc)
    end
end

TICK.bus = function(now)
    local bus = E.bus
    if not IsValid(bus) then return end
    local t = now - E.phaseT
    local kind = BusSection(t)
    if kind ~= E.section then
        E.section = kind
        if kind == "fly" or kind == "fast" then
            E.boarded = true
            BoardBus()
            E.goal = SkySpot()
        else
            E.goal = GroundSpot(bus:GetPos())
        end
        E.client.strobe = kind == "fast"
        Send()
    end
    if E.boarded then for _, p in ipairs(player.GetAll()) do BusBoard(p) end end -- (someone just joining, or back from the dead)
    -- the speed, surging on the beat
    local beat = t * cvBusBPM:GetFloat() / 60
    local surge = 1 + 0.35 * math.abs(math.sin(beat * math.pi))
    local flying = E.section == "fly" or E.section == "fast"
    local speed = (flying and (E.section == "fast" and 1500 or 900) or 380) * (flying and surge or 1)
    local pos = bus:GetPos()
    local to = E.goal - pos
    if not flying then to.z = 0 end
    local dist = to:Length()
    if dist < 120 then
        if flying then
            local from = E.goal
            E.goal = SkySpot()
            if #E.rings < 4 then NewRing(E.goal, from) end
        else
            E.goal = GroundSpot(pos)
        end
    else
        -- swing round towards it, not snap
        local want = to * (1 / dist)
        E.busDir = (E.busDir * 0.85 + want * 0.15):GetNormalized()
        local step = math.min(dist, speed * 0.1)
        local nextPos = pos + E.busDir * step
        if not flying then
            local g = Ground(nextPos)
            -- (coming down to the road: a gentle descent rather than a drop)
            nextPos.z = g and (pos.z + (g.z - pos.z) * 0.3) or pos.z
        end
        bus:SetPos(nextPos)
        local ang = E.busDir:Angle()
        bus:SetAngles(Angle(flying and ang.p or 0, ang.y, flying and math.sin(t * 1.3) * 14 or 0))
    end
    -- the rings: through one, and it pops
    local keep = {}
    for _, ring in ipairs(E.rings) do
        if IsValid(ring) then
            local c = RAINBOW[(math.floor(beat) % #RAINBOW) + 1]
            ring:SetColor(Color(c[1], c[2], c[3], 220))
            if ring:GetPos():DistToSqr(bus:GetPos()) < 160 * 160 then
                ring:EmitSound("garrysmod/balloon_pop_cute.wav", 90)
                if util.Effect and EffectData then
                    local fx = EffectData()
                    fx:SetOrigin(ring:GetPos())
                    util.Effect("balloon_pop", fx)
                end
                ring:Remove()
                E.ringsPopped = (E.ringsPopped or 0) + 1
            else
                keep[#keep + 1] = ring
            end
        end
    end
    E.rings = keep
    if flying and #E.rings == 0 then NewRing(E.goal, bus:GetPos()) end
    -- everyone in their seat (the seats turn with the bus)
    for _, e in ipairs(E.riders or {}) do
        local r = IsValid(e) and e.lcEndRide
        if r and r.v == bus then
            e:SetPos(bus.LocalToWorld and bus:LocalToWorld(r.off) or (bus:GetPos() + r.off))
            if not e:IsPlayer() then e:SetAngles(Angle(0, bus:GetAngles().y, 0)) end
        end
    end
end

-- Nobody gets off the bus: no suicide, and the dead are put straight back on.
hook.Add("CanPlayerSuicide", "LivingCityEndings", function() if E and E.phase == "apocalypse" then return false end end)
hook.Add("PlayerDeath", "LivingCityEndingBus", function(p)
    if E and E.id == "bus" and E.boarded then
        p.lcEndRide = nil
        timer.Simple(0.5, function() if IsValid(p) and not p:Alive() then p:Spawn() end end)
    end
end)

SETUP.nuanua = function()
    Fly({ "models/xqm/jetbody3.mdl", "models/xqm/airplanewing1.mdl", "models/props_vehicles/van001a_physics.mdl" }, 64, 1600, 0.2, 3, 90)
end
TICK.nuanua = FlyTick

-- Top Secret: barnacles, one victim a second
SETUP.topsecret = function()
    E.nextHang = CurTime() + 1
    E.hanging = {}
end
TICK.topsecret = function(now)
    if now >= E.nextHang then
        E.nextHang = now + 1
        for _, p in ipairs(Living()) do
            if not p.lcEndHang then
                p.lcEndHang = { t = now, from = p:GetPos() }
                p:Freeze(true)
                p:SetMoveType(MOVETYPE_NONE)
                Prop("models/barnacle.mdl", p:GetPos() + Vector(0, 0, 260))
                p:EmitSound("npc/barnacle/barnacle_tongue_pull1.wav", 80)
                E.hanging[#E.hanging + 1] = p
                break
            end
        end
    end
    for _, p in ipairs(E.hanging) do
        local h = IsValid(p) and p.lcEndHang
        if h and not p.lcEndTaken then
            local t = now - h.t
            p:SetPos(h.from + Vector(0, 0, math.min(1, t / 2.5) * 180))
            if t > 3.5 then
                p:EmitSound("npc/barnacle/barnacle_crunch2.wav", 80)
                Take(p, "Up you go.")
            end
        end
    end
end

-- the Flood: the water rises; Grigori rocks out above it
SETUP.grigori = function()
    local low
    for _, p in ipairs(player.GetAll()) do low = math.min(low or p:GetPos().z, p:GetPos().z) end
    E.floodZ = (low or 0) - 40
    E.floodStart = CurTime()
    if IsValid(E.by) then
        E.grigori = E.by
        E.by:SetNW2Bool("lc_rocking", true)
    end
end
TICK.grigori = function(now)
    E.floodZ = E.floodZ + 22 * 0.1
    SetGlobal2Float("lc_flood_z", E.floodZ)
    local g = E.grigori
    if IsValid(g) and now >= (E.nextDance or 0) then
        E.nextDance = now + 5
        g:ConCommand("act " .. (math.random() < 0.5 and "dance" or "muscle"))
    end
    for _, p in ipairs(Living()) do
        if p ~= g then
            local under = p:EyePos().z < E.floodZ
            if under then
                p.lcEndUnder = p.lcEndUnder or now
                if now - p.lcEndUnder > 6 then Take(p, "The water closes over your head. Somewhere above, Father Grigori hits the high note.") end
            else
                p.lcEndUnder = nil
            end
        end
    end
    -- Grigori is the last to go, once he's alone
    if IsValid(g) and not g.lcEndTaken and #Living() <= 1 and now - E.floodStart > 20 then
        Take(g, "Father Grigori bows. The flood takes its encore.")
    end
end

------------------------------------------------------------------------
-- The phases
------------------------------------------------------------------------

local function Clear()
    for _, e in ipairs(E and E.ents or {}) do if IsValid(e) then e:Remove() end end
    for _, p in ipairs(player.GetAll()) do
        if p.lcEndTaken or p.lcEndRide or p.lcEndHang then
            p:Freeze(false)
            p:SetMoveType(MOVETYPE_WALK)
            if p.SetNoDraw then p:SetNoDraw(false) end
            if p.SetNotSolid then p:SetNotSolid(false) end
        end
        if p.lcEndSpectating then
            if p.UnSpectate then p:UnSpectate() end
            if p.Spawn then p:Spawn() end
        end
        p.lcEndTaken, p.lcEndRide, p.lcEndHang, p.lcEndUnder = nil, nil, nil, nil
        p.lcEndSpectating, p.lcEndWatching, p.lcEndRoam = nil, nil, nil
        if p.lcEndModel then p:SetModel(p.lcEndModel) p.lcEndModel = nil end
        p:SetNW2Bool("lc_end_taken", false)
        p:SetNW2Bool("lc_end_spectating", false)
        p:SetNW2Bool("lc_dancing", false)
        p:SetNW2Bool("lc_seated", false)
        p.lcBloomUp = nil
        p:SetNW2Bool("lc_rocking", false)
    end
    SetGlobal2Float("lc_flood_z", 0)
    for npc in pairs(LC.NPCs or {}) do
        if IsValid(npc) then npc:SetNW2Bool("lc_dancing", false) npc:SetNW2Bool("lc_seated", false) npc.lcBloomUp = nil npc.lcEndRide = nil end
    end
    if E and E.doorsOpen and LC.ReleaseEveryDoor then LC.ReleaseEveryDoor() end
    if E and E.dark then
        LC.EndingDark = nil
        if LC.ForceBlackout then LC.ForceBlackout("auto") end
        if LC.ApplyLightStyle then LC.ApplyLightStyle() end
    end
end

-- The map reloads, with the city's layout (characters, standing and credits are kept).
function LC.EndingReload()
    if LC.TestMode then return end
    if RunConsoleCommand then RunConsoleCommand("changelevel", game.GetMap()) end
end

local function GoTo(phase)
    local now = CurTime()
    E.phase = phase
    E.phaseT = now
    if phase == "gman" then
        Freeze(true)
        E.gman = SpawnGman(E.by)
        if IsValid(E.gman) then E.ents[#E.ents + 1] = E.gman end
        E.voteEnds = now + math.max(5, cvVote:GetFloat())
        E.votes = {}
        E.lines = {}
        for p in string.gmatch(cvGman:GetString() or "", "[^,]+") do E.lines[#E.lines + 1] = string.Trim(p) end
        All("[???] Time stops. A man in a blue suit is standing in front of you. He'd like a word, and your vote: 1 to let it happen, 2 to skip it.")
        MarkEnding()
    elseif phase == "apocalypse" then
        Freeze(false)
        if IsValid(E.gman) then E.gman:Remove() end
        local songs = LC.EndingSongs(E.id)
        E.song = #songs > 0 and songs[math.random(#songs)] or nil
        All("[???] So be it. " .. LC.Endings[E.id].say)
        local ok, err = pcall(SETUP[E.id])
        if not ok then LC.Error("ending setup " .. E.id, err) end
        hook.Run("LivingCityEndingStarted", E.id)
    elseif phase == "reset" then
        for _, p in ipairs(player.GetAll()) do
            if p.ScreenFade then p:ScreenFade(SCREENFADE and SCREENFADE.OUT or 2, Color(255, 255, 255, 255), 4, 60) end
        end
        All("[???] The city resets. Everyone you were is still you.")
        hook.Run("LivingCityEndingReset", E.id)
    end
    Send()
end

function LC.TriggerEnding(id, by, now)
    if not LC.Endings[id] then return false, "No such ending." end
    if E then return false, "One's already under way." end
    if not cvOn:GetBool() then return false, "Secret endings are off." end
    if LC.EndingCooldownLeft() > 0 then return false, "Not yet (" .. math.ceil(LC.EndingCooldownLeft() / 60) .. " minutes)." end
    E = { id = id, by = by, phase = "pending", phaseT = CurTime(), ents = {}, votes = {} }
    if LC.Event and LC.EndEvent then LC.EndEvent(true) end
    LC.Log("info", "Secret ending triggered: " .. id .. (IsValid(by) and (" by " .. by:Nick()) or ""))
    hook.Run("LivingCityEndingTriggered", id, by)
    if now then
        MarkEnding()
        GoTo("apocalypse")
    end
    return true
end

-- Ends it where it stands (admin, or the reset), without a reload.
function LC.CancelEnding()
    if not E then return false end
    Freeze(false)
    Clear()
    E = nil
    Send()
    return true
end

local function Tally()
    local yes, skip = 0, 0
    for p, v in pairs(E.votes) do
        if IsValid(p) then if v then yes = yes + 1 else skip = skip + 1 end end
    end
    hook.Run("LivingCityEndingVote", E.id, yes, skip)
    return yes, skip
end

net.Receive("lc_ending_vote", function(_, ply)
    if not E or E.phase ~= "gman" or not IsValid(ply) then return end
    E.votes[ply] = net.ReadBool()
    Send()
end)
function LC.EndingVote(ply, yes)
    if not E or E.phase ~= "gman" then return false end
    E.votes[ply] = yes and true or false
    Send()
    return true
end

timer.Create("LivingCityEndings", 0.1, 0, function()
    if not E then return end
    local ok, err = pcall(function()
        local now = CurTime()
        if E.phase == "pending" then
            if now - E.phaseT >= cvPause:GetFloat() then GoTo("gman") end
        elseif E.phase == "gman" then
            for _, p in ipairs(player.GetAll()) do if not p.lcEndFrozen then p.lcEndFrozen = true p:Freeze(true) end end -- (someone just joining)
            if now >= E.voteEnds then
                local yes, skip = Tally()
                if skip > yes then
                    All(string.format("[???] %d to %d. Very well. He straightens his tie, and time starts again.", skip, yes))
                    LC.CancelEnding()
                else
                    All(yes + skip == 0 and "[???] Silence. He takes that as a yes." or string.format("[???] %d to %d.", yes, skip))
                    GoTo("apocalypse")
                end
            end
        elseif E.phase == "apocalypse" then
            if TICK[E.id] then TICK[E.id](now) end
            -- (an ending can run to the end of its song even after the last one goes: the dead watch)
            if (#Living() == 0 and now >= (E.holdUntil or 0)) or now - E.phaseT > math.max(cvMax:GetFloat(), (E.holdUntil or 0) - E.phaseT + 1) then GoTo("reset") end
        elseif E.phase == "reset" then
            if now - E.phaseT >= 5 then
                local id = E.id
                LC.CancelEnding()
                LC.Log("info", "Secret ending " .. id .. ": the map reloads")
                LC.EndingReload()
            end
        end
    end)
    if not ok then LC.Error("endings", err) end
end)

-- Nobody gets hurt while time's stopped or the world ends.
hook.Add("EntityTakeDamage", "LivingCityEndings", function(ent)
    if E and E.phase ~= "pending" and IsValid(ent) and ent:IsPlayer() then return true end
end)
hook.Add("PlayerInitialSpawn", "LivingCityEndings", function(ply)
    timer.Simple(3, function() if IsValid(ply) and E then Send(ply) end end)
end)
hook.Add("PlayerDisconnected", "LivingCityEndings", function(ply) if E then E.votes[ply] = nil end end)

------------------------------------------------------------------------
-- Triggers
------------------------------------------------------------------------

-- Father Grigori eats the motherlode.
function LC.EatChip(ply)
    if not IsValid(ply) or ply:GetNW2String("lcf_special", "") ~= "chaplain" then return false, "You'd break your teeth." end
    if not (LC.HasItem and LC.HasItem(ply, "master_chip")) then return false, "You've nothing like that to eat." end
    if E then return false, "Not now." end
    if LC.EndingCooldownLeft() > 0 or not cvOn:GetBool() then return false, "It doesn't go down. Not yet." end
    LC.TakeItem(ply, "master_chip", 1)
    ply:EmitSound("physics/metal/metal_box_break1.wav", 70)
    for _, p in ipairs(player.GetAll()) do
        if p:GetPos():DistToSqr(ply:GetPos()) < 600 * 600 then p:ChatPrint("** Father Grigori swallows a Combine data core whole. His eyes light up.") end
    end
    return LC.TriggerEnding("grigori", ply)
end
LC.SlashCommands = LC.SlashCommands or {}
LC.SlashCommands.eatchip = function(ply)
    local ok, why = LC.EatChip(ply)
    if not ok and why then ply:ChatPrint(why) end
end

------------------------------------------------------------------------
-- For the admin
------------------------------------------------------------------------

local function Reply(ply, m) if IsValid(ply) then ply:ChatPrint("[Living City] " .. m) else print("[Living City] " .. m) end end

concommand.Add("lc_endings", function(ply)
    if IsValid(ply) and not ply:IsSuperAdmin() then return end
    for _, id in ipairs(LC.EndingOrder) do
        local n = #LC.EndingSongs(id)
        Reply(ply, string.format("%s (%s): %s", id, LC.Endings[id].name, n > 0 and (n .. " song(s)") or "no song yet: sound/" .. ROOT .. id .. "/"))
    end
    local left = LC.EndingCooldownLeft()
    Reply(ply, left > 0 and ("Next one possible in " .. math.ceil(left / 60) .. " minutes (lc_ending_reset_cooldown).") or "One can happen now.")
end)

concommand.Add("lc_ending", function(ply, _, args)
    if IsValid(ply) and not ply:IsSuperAdmin() then return end
    local id = string.lower(tostring(args[1] or ""))
    if not LC.Endings[id] then Reply(ply, "lc_ending <" .. table.concat(LC.EndingOrder, "|") .. "> [now]") return end
    local ok, why = LC.TriggerEnding(id, IsValid(ply) and ply or nil, string.lower(tostring(args[2] or "")) == "now")
    Reply(ply, ok and ("Ending triggered: " .. id) or tostring(why))
end)

concommand.Add("lc_ending_cancel", function(ply)
    if IsValid(ply) and not ply:IsSuperAdmin() then return end
    Reply(ply, LC.CancelEnding() and "Ending cancelled. Time runs again." or "No ending on.")
end)

concommand.Add("lc_ending_reset_cooldown", function(ply)
    if IsValid(ply) and not ply:IsSuperAdmin() then return end
    if file.CreateDir then file.CreateDir("livingcity") end
    file.Write(COOL_FILE, util.TableToJSON({ last = 0 }))
    Reply(ply, "Secret ending cooldown cleared.")
end)

concommand.Add("lc_ending_vote", function(ply, _, args)
    if not IsValid(ply) then return end
    local a = string.lower(tostring(args[1] or ""))
    LC.EndingVote(ply, a == "yes" or a == "1")
end)

hook.Add("InitPostEntity", "LivingCityEndings", function()
    for _, id in ipairs(LC.EndingOrder) do LC.EndingSongs(id) end -- (so the songs are sent to joining players)
end)
