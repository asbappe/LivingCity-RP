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
        plane      numa numa: everyone dancing on the wings of an airplane over
                   the city, the webcam dance, everyone mouthing the words, a
                   little webcam of your own face in the corner; swooping and
                   rolling in the choruses, fireworks in the last, and up into
                   the clouds on the final note (lc_ending_plane_sections)
        standup    the rope (the hanged painted white, white cone hats on, a
                   crowd cheering): someone new strung up every other beat, from
                   whatever is above them or the nearest wall; the hanged
                   struggle while their health drains, then go limp and look
                   on (lc_ending_standup_sections)
        hard       party hard: everyone at the landing zone (every NPC in the
                   city dancing too), the cheap mirror-flip meme dance on the
                   half-beat, PARTY HARD flashing everywhere, strobes; people
                   pass out one at a time (lc_ending_hard_sections)
        base       someone set up us the bomb: the song's opening lines as
                   arcade subtitles, bombs all over the city, CATS in the sky;
                   everyone on a ZIG (a dropship), the fleet circling the city
                   as the bombs go off, then diving at CATS for great justice;
                   chat in Engrish (lc_ending_base_sections, _lines)
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
        water      the flood: a stage floats at the landing zone in the worst
                   storm the city's seen; the waves knock people off it,
                   ichthyosaurs hunt the water and leap at the edge; swim, or
                   drown. Father Grigori rocks out on it, mouthing every word,
                   untouchable, and goes last on the final note
                   (lc_ending_flood_sections, from the song itself).
                   Triggered by Father Grigori himself eating the motherlode:
                   /eatchip, with a master data core in his pockets.

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
    plane     = { name = "Plane", say = "Alo, salut. Please fasten your seatbelts." },
    standup   = { name = "Standup", say = "Look up." },
    water     = { name = "The Flood", say = "Father Grigori has eaten the motherlode. The waters rise." },
    bloom     = { name = "Bloom", say = "Everybody dances. Nobody stops." },
    marrow    = { name = "Marrow", say = "Something is rattling out there. Lots of somethings." },
    base      = { name = "Base", say = "What happen ?" },
    hard      = { name = "Hard", say = "It's time." },
}
-- The ones with strobes or flashes: everyone is warned before and as they start
-- (and lc_ending_calm, on each player's own screen, leaves the flashing out).
for _, id in ipairs({ "bus", "bloom", "marrow", "base", "hard", "water", "plane" }) do if LC.Endings[id] then LC.Endings[id].flashing = true end end
LC.EndingOrder = { "harpies", "bus", "plane", "standup", "water", "bloom", "marrow", "base", "hard" }

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
            floodZ = E.floodZ, client = E.client, flashing = LC.Endings[E.id].flashing or nil })
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
    E.songEnds = true -- (it is over when the song is)
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
        for _, p in ipairs(Living()) do Take(p, "The ride doesn't stop. It never stops.") end
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
    E.songEnds = true -- (it is over when the song is)
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

-- Swimming in the flood: you sink slowly, move slowly, and Jump swims up
-- (cl_livingcity_endings.lua does the same, so it feels right).
function LC.FloodSwim(p, mv, z)
    if not z or p:GetPos().z + 40 >= z then return false end
    local v = mv:GetVelocity()
    v.x, v.y = v.x * 0.9, v.y * 0.9
    v.z = math.max(v.z * 0.9, -50)
    if mv:KeyDown(IN_JUMP) then v.z = 220 end
    mv:SetVelocity(v)
    return true
end
hook.Add("SetupMove", "LivingCityFlood", function(p, mv)
    if not E or E.id ~= "water" or E.phase ~= "apocalypse" or p.lcEndTaken or IsValid(E.realWater) then return end
    LC.FloodSwim(p, mv, E.floodZ)
end)

-- Nobody gets off the bus: no suicide, and the dead are put straight back on.
hook.Add("CanPlayerSuicide", "LivingCityEndings", function() if E and E.phase == "apocalypse" then return false end end)
hook.Add("PlayerDeath", "LivingCityEndingBus", function(p)
    if E and E.id == "bus" and E.boarded then
        p.lcEndRide = nil
        timer.Simple(0.5, function() if IsValid(p) and not p:Alive() then p:Spawn() end end)
    end
end)

-- Base (a codeword): someone set up us the bomb. The song's opening lines
-- play as arcade subtitles (lc_ending_base_lines); bombs appear all over the
-- city, beeping; the main screen turns on and CATS fills the sky; when the
-- remix kicks in everyone (and some of the Combine) is on a ZIG, a dropship,
-- and the whole fleet takes off and circles the city on the beat while the
-- bombs go off below; "Move ZIG" faster; "For great justice" they dive at
-- CATS, the bombs chain, and everything blows. All the while, everyone's
-- chat comes out in Engrish.
local cvBaseSections = CreateConVar("lc_ending_base_sections", "3.5:bomb,14.7:screen,34:zig,126:move,174:justice,212:boom,224:end", FLAGS,
    "Base: the song's moments, second:kind (bomb, screen, zig, move, justice, boom, end)")
local cvBaseLines = CreateConVar("lc_ending_base_lines",
    "2.2=CAPTAIN: What happen ?|3.5=MECHANIC: Somebody set up us the bomb.|6.5=OPERATOR: We get signal.|9.5=CAPTAIN: What !|12.5=OPERATOR: Main screen turn on.|14.7=CAPTAIN: It's you !!|16.4=CATS: How are you gentlemen !!|18.4=CATS: All your base are belong to us.|20.4=CATS: You are on the way to destruction.|21.6=CAPTAIN: What you say !!|23.0=CATS: You have no chance to survive make your time.|26.0=CATS: Ha ha ha ha ....|34=CAPTAIN: Take off every 'ZIG' !!|126=CAPTAIN: Move 'ZIG'.|174=CAPTAIN: For great justice.",
    FLAGS, "Base: the subtitles, second=WHO: line, separated by |")
local cvBaseBPM   = CreateConVar("lc_ending_base_bpm", "150", FLAGS, "Base: the song's beats per minute (the bombs and the fleet keep to it)")
local cvBaseBombs = CreateConVar("lc_ending_base_bombs", "30", FLAGS, "Base: how many bombs someone sets up")
local ZIG = { "models/combine_dropship.mdl" }
local BOMB = { "models/props_phx/ww2bomb.mdl", "models/props_c17/oildrum001_explosive.mdl" }

function LC.BaseLines(str)
    local out = {}
    for t, line in string.gmatch((str or cvBaseLines:GetString()) .. "|", "([%d%.]+)%s*=%s*([^|]+)|") do out[#out + 1] = { t = tonumber(t), text = string.Trim(line) } end
    table.sort(out, function(x, y) return x.t < y.t end)
    return out
end

-- Engrish: what everyone says, the way the captain would say it.
local ENGRISH = { { "%f[%a][Yy]our%f[%A]", "you" }, { "%f[%a][Yy]ou're%f[%A]", "you are" }, { "%f[%a]is%f[%A]", "are belong" },
    { "%f[%a]the%f[%A] ", "" }, { "%f[%a]The%f[%A] ", "" }, { "%f[%a]a%f[%A] ", "" }, { "%f[%a]I am%f[%A]", "I are" },
    { "%f[%a]happened%f[%A]", "happen" }, { "%f[%a]what's%f[%A]", "what" }, { "%f[%a]going to%f[%A]", "on the way to" } }
function LC.Engrish(text)
    local s = tostring(text or "")
    for _, r in ipairs(ENGRISH) do s = string.gsub(s, r[1], r[2]) end
    s = string.gsub(s, "%s+$", "")
    if not string.find(s, "[!?%.]$") then s = s .. " !!" else s = string.gsub(s, "([!?])$", " %1%1") end
    return s
end

local function BaseSection(t)
    local kind = "intro"
    for _, sct in ipairs(E.sections) do if t >= sct.t then kind = sct.kind end end
    return kind
end

local function Blow(pos, big)
    if util.Effect and EffectData then
        local fx = EffectData()
        fx:SetOrigin(pos)
        util.Effect("Explosion", fx)
    end
    if util.ScreenShake then util.ScreenShake(pos, big and 12 or 5, 5, big and 2 or 1, big and 3000 or 1500) end
    if sound and sound.Play then sound.Play("ambient/explosions/explode_" .. math.random(1, 9) .. ".wav", pos, big and 140 or 110, 100, 1) end
end

local function SetBomb(pos)
    local b = Prop(FirstModel(BOMB), pos + Vector(0, 0, 10))
    if b then
        b:SetAngles(Angle(0, math.Rand(0, 360), math.Rand(-10, 10)))
        if b.SetSolid then b:SetSolid(SOLID_NONE) end
        E.bombs[#E.bombs + 1] = b
    end
    return b
end

local function BombIndices()
    local out = {}
    for _, b in ipairs(E.bombs) do if IsValid(b) then out[#out + 1] = b:EntIndex() end end
    return out
end

-- On a ZIG: a place on top of it (crammed in, like the bus).
local function ZigSeat(i)
    local row, side = (i - 1) % 3, math.floor((i - 1) / 3) % 2
    return Vector(-80 + row * 80, side == 0 and -40 or 40, 150 + math.floor((i - 1) / 6) * 50)
end

local function ZigBoard(e)
    if not IsValid(e) or e.lcEndRide or #E.zigs == 0 then return end
    E.zigSeat = (E.zigSeat or 0) + 1
    local zi = (E.zigSeat - 1) % #E.zigs + 1
    local per = math.floor((E.zigSeat - 1) / #E.zigs) + 1
    e.lcEndRide = { v = E.zigs[zi], off = ZigSeat(per) }
    E.riders = E.riders or {}
    E.riders[#E.riders + 1] = e
    if e:IsPlayer() then
        if e.InVehicle and e:InVehicle() and e.ExitVehicle then e:ExitVehicle() end
        e.lcEndFrozen = true
        e:Freeze(true)
        e:SetMoveType(MOVETYPE_NONE)
    end
    e:SetNW2Entity("lc_riding", E.zigs[zi])
    e:SetNW2Bool("lc_dancing", true)
end

SETUP.base = function()
    local now = CurTime()
    E.songEnds = true -- (it is over when the song is)
    E.sections = LC.MarrowSections(cvBaseSections:GetString())
    for _, sct in ipairs(E.sections) do if sct.kind == "end" then E.holdUntil = now + sct.t end end
    E.holdUntil = E.holdUntil or (now + 224)
    local lz = LC.PointsOfKind and LC.PointsOfKind("lz") or {}
    E.lz = (#lz > 0 and lz[1].pos) or (IsValid(E.by) and E.by:GetPos()) or Centre()
    E.bombs, E.zigs = {}, {}
    E.sky = E.lz + Vector(0, 0, 2600)
    LC.TimeStopped = true -- (the city stops and stares)
    if RunConsoleCommand then RunConsoleCommand("ai_disabled", "1") end
    E.dark = true
    LC.EndingDark = "f"
    if LC.ApplyLightStyle then LC.ApplyLightStyle() end
    E.client = { party = true, lights = false, dance = "bus", bpm = cvBaseBPM:GetFloat(), offset = 0, start = now,
        lines = LC.BaseLines(), palette = { { 255, 60, 40 }, { 255, 200, 60 } }, sky = E.sky, bombs = {} }
    E.section = "intro"
end

TICK.base = function(now)
    local t = now - E.phaseT
    local kind = BaseSection(t)
    local beat = t * cvBaseBPM:GetFloat() / 60
    if kind ~= E.section then
        E.section = kind
        E.client.section = kind
        if kind == "bomb" then
            -- somebody set up us the bomb: all over the city
            for _ = 1, cvBaseBombs:GetInt() do
                local g = RingSpot(E.lz, math.Rand(300, 3000), false)
                if g then SetBomb(g) end
            end
        elseif kind == "screen" then
            E.client.cats = true -- (main screen turn on: CATS in the sky)
        elseif kind == "zig" then
            -- take off every ZIG: the fleet at the landing zone, everyone aboard
            local n = math.max(3, math.ceil(#player.GetAll() / 6) + 1)
            for i = 1, n do
                local side = (i % 2 == 0) and 1 or -1
                local rank = math.floor(i / 2)
                local z = Prop(FirstModel(ZIG), E.lz + Vector(-rank * 420, side * rank * 380, 250))
                if z then
                    if z.SetSolid then z:SetSolid(SOLID_NONE) end
                    z.lcSlot = Vector(-rank * 420, side * rank * 380, rank * 60)
                    E.zigs[#E.zigs + 1] = z
                end
            end
            for _, p in ipairs(player.GetAll()) do ZigBoard(p) end
            local c = 0
            for _, npc in ipairs(CombineNPCs()) do if c < 6 then c = c + 1 ZigBoard(npc) end end
            E.client.lights = true
            E.fleetA = 0
        elseif kind == "move" then
            E.client.strobe = true
        elseif kind == "boom" then
            -- for great justice
            for _, b in ipairs(E.bombs) do if IsValid(b) then Blow(b:GetPos(), true) b:Remove() end end
            Blow(E.sky, true)
            E.client.cats = false
            E.client.boomAt = now
        end
        E.client.bombs = BombIndices()
        Send()
    end
    if E.boarded ~= false and #E.zigs > 0 then for _, p in ipairs(player.GetAll()) do ZigBoard(p) end end
    -- the fleet: round the city in formation, faster with the beat; at the end, at CATS
    if #E.zigs > 0 then
        local surge = 1 + 0.3 * math.abs(math.sin(beat * math.pi))
        local speed = (kind == "move" and 0.32) or (kind == "justice" and 0.4) or 0.2
        E.fleetA = (E.fleetA or 0) + speed * surge * 0.1
        local r = kind == "justice" and math.max(500, cvRadius:GetFloat() * (1 - math.Clamp((t - 174) / 38, 0, 1) * 0.75)) or cvRadius:GetFloat()
        local height = kind == "justice" and (900 + math.Clamp((t - 174) / 38, 0, 1) * 1500) or 900
        local lead = E.lz + Vector(math.cos(E.fleetA) * r, math.sin(E.fleetA) * r, height)
        local yaw = math.deg(E.fleetA) + 90
        local roll = (kind == "move" or kind == "justice") and math.sin(t * 2) * 25 or math.sin(t) * 8
        for _, z in ipairs(E.zigs) do
            if IsValid(z) then
                local off = z.lcSlot or Vector()
                local ang = Angle(0, yaw, 0)
                local pos = lead + ang:Forward() * off.x + ang:Right() * off.y + Vector(0, 0, off.z)
                z:SetPos(LerpVector(0.35, z:GetPos(), pos))
                z:SetAngles(Angle(math.sin(t * 1.3) * 5, yaw, roll))
            end
        end
        for _, e in ipairs(E.riders or {}) do
            local rd = IsValid(e) and e.lcEndRide
            if rd and IsValid(rd.v) then e:SetPos(rd.v.LocalToWorld and rd.v:LocalToWorld(rd.off) or (rd.v:GetPos() + rd.off)) end
        end
    end
    -- the bombs go off below, more and more of them
    if (kind == "zig" or kind == "move" or kind == "justice") then
        local b = math.floor(beat)
        if b ~= E.lastBeat then
            E.lastBeat = b
            local chance = (kind == "justice" and 0.7) or (kind == "move" and 0.4) or 0.2
            if math.random() < chance then
                local alive = {}
                for _, bb in ipairs(E.bombs) do if IsValid(bb) then alive[#alive + 1] = bb end end
                E.bombs = alive
                if #alive > 0 then
                    local bb = table.remove(E.bombs, math.random(#alive))
                    Blow(bb:GetPos(), false)
                    bb:Remove()
                    local g = RingSpot(E.lz, math.Rand(300, 3000), false) -- (and somebody sets up another)
                    if g then SetBomb(g) end
                    E.client.bombs = BombIndices()
                    Send()
                end
            end
        end
    end
end

-- Everyone's chat, in Engrish, while the base is belong to them.
hook.Add("PlayerSay", "LivingCityEngrish", function(p, text, team)
    if not E or E.id ~= "base" or E.phase ~= "apocalypse" then return end
    if string.sub(text or "", 1, 1) == "!" or string.sub(text or "", 1, 1) == "/" then return end
    return LC.Engrish(text)
end)

-- Hard (a codeword): party hard. Everyone at the landing zone, the Combine's
-- units too, every NPC in the city dancing where they stand; the cheap meme
-- dance (each half-beat, the mirror image of the last pose), PARTY HARD
-- flashing everywhere, the strobe never stops. From lc_ending_hard_sections'
-- "passout" people drop, one at a time, having partied too hard; when the
-- music cuts, whoever's left goes down too.
local cvHardSections = CreateConVar("lc_ending_hard_sections", "6:hard,28:break,32:hard,150:passout,177:fade,188:end", FLAGS,
    "Hard: the song's sections, second:kind (hard, break, passout, fade, end); before the first, the intro")
local cvHardBPM = CreateConVar("lc_ending_hard_bpm", "150", FLAGS, "Hard: the song's beats per minute (the flips and the strobe keep to it)")
local RAINBOW2 = { { 255, 40, 40 }, { 255, 150, 30 }, { 255, 240, 40 }, { 60, 230, 80 }, { 60, 140, 255 }, { 200, 70, 255 }, { 255, 80, 200 } }

local function HardSection(t)
    local kind = "intro"
    for _, sct in ipairs(E.sections) do if t >= sct.t then kind = sct.kind end end
    return kind
end

-- Partied too hard: down they go.
local function PassOut(e, how)
    if not IsValid(e) or e.lcEndTaken then return end
    Body(e:GetModel(), e:GetPos(), e:GetAngles().y, 60)
    if e:IsPlayer() then
        e:EmitSound("vo/npc/male01/moan0" .. math.random(1, 5) .. ".wav", 75)
        if e.SetNoDraw then e:SetNoDraw(true) end
        Spectator(e, how or "You partied too hard. Lights out.", Color(255, 80, 200, 200))
    else
        e:Remove()
    end
end

SETUP.hard = function()
    local now = CurTime()
    E.songEnds = true -- (it is over when the song is)
    E.sections = LC.MarrowSections(cvHardSections:GetString())
    for _, sct in ipairs(E.sections) do
        if sct.kind == "end" then E.holdUntil = now + sct.t end
        if sct.kind == "passout" then E.passAt = now + sct.t end
        if sct.kind == "fade" then E.fadeAt = now + sct.t end
    end
    E.holdUntil = E.holdUntil or (now + 188)
    E.passAt, E.fadeAt = E.passAt or (now + 150), E.fadeAt or (now + 177)
    local lz = LC.PointsOfKind and LC.PointsOfKind("lz") or {}
    E.lz = (#lz > 0 and lz[1].pos) or (IsValid(E.by) and E.by:GetPos()) or Centre()
    LC.TimeStopped = true
    if RunConsoleCommand then RunConsoleCommand("ai_disabled", "1") end
    local ps = player.GetAll()
    for i, p in ipairs(ps) do
        if p.InVehicle and p:InVehicle() and p.ExitVehicle then p:ExitVehicle() end
        local a = (i / math.max(1, #ps)) * math.pi * 2
        local r = 60 + 14 * #ps
        p:SetPos((Ground(E.lz + Vector(math.cos(a) * r, math.sin(a) * r, 0)) or E.lz) + Vector(0, 0, 4))
        p.lcEndFrozen = true
        p:Freeze(true)
        p:SetNW2Bool("lc_dancing", true)
    end
    GatherCombine(E.lz, 120 + 14 * #ps)
    for npc in pairs(LC.NPCs or {}) do if IsValid(npc) then npc:SetNW2Bool("lc_dancing", true) end end
    E.dark = true
    LC.EndingDark = "e"
    if LC.ApplyLightStyle then LC.ApplyLightStyle() end
    E.client = { party = true, lights = true, strobe = true, dance = "hard", partyText = true, palette = RAINBOW2,
        bpm = cvHardBPM:GetFloat(), offset = 0, start = now, section = "intro" }
    E.passGap = math.max(0.5, (E.fadeAt - E.passAt) / math.max(1, #ps))
end

TICK.hard = function(now)
    local t = now - E.phaseT
    local kind = HardSection(t)
    if kind ~= E.client.section then
        E.client.section = kind
        E.client.strobe = kind ~= "break" and kind ~= "fade"
        E.client.partyText = kind ~= "break" and kind ~= "fade"
        Send()
    end
    -- one at a time, they drop
    if kind == "passout" and now >= (E.nextPass or 0) then
        E.nextPass = now + E.passGap
        local pick = Living()
        if #pick > 0 then PassOut(pick[math.random(#pick)]) end
    end
    if (kind == "passout") and now >= (E.nextNPCPass or 0) then
        E.nextNPCPass = now + 0.4
        for npc in pairs(LC.NPCs or {}) do if IsValid(npc) then PassOut(npc) break end end
    end
    -- the music cuts: everyone left goes down
    if (kind == "fade" or kind == "end") and not E.allOut then
        E.allOut = true
        for _, p in ipairs(Living()) do PassOut(p, "The music stops. So do you. You partied too hard.") end
    end
end

-- Plane (a codeword): numa numa. Like the band in the video, everyone dances
-- on the wings of an airplane over the city. It circles low through the
-- intro; at the first hook everyone (and some of the Combine) is up on it,
-- doing the webcam dance, everyone's jaw mouthing the words; the verses
-- cruise, the choruses swoop and roll, the breakdown glides, the last chorus
-- is fastest, with fireworks; on the final note it climbs into the clouds.
local cvPlaneSections = CreateConVar("lc_ending_plane_sections", "17:board,26:verse,63:chorus,89:verse,122:chorus,148:break,167:final,210:climb,215:end", FLAGS,
    "Plane: the song's sections, second:kind (board, verse, chorus, break, final, climb, end); before the first, it circles low")
local cvPlaneCaptions = CreateConVar("lc_ending_plane_captions", "15.1=MA-IA-HII|16.3=MA-IA-HUU|17.5=MA-IA-HOO|18.7=MA-IA-HAHA", FLAGS,
    "Plane: the sing-along captions, second=TEXT, separated by | (the choruses add their own)")
local cvPlaneBPM = CreateConVar("lc_ending_plane_bpm", "130", FLAGS, "Plane: the song's beats per minute")
local cvPlaneCombine = CreateConVar("lc_ending_plane_combine", "8", FLAGS, "Plane: how many of the Combine's units get on the wings too")
local PLANE_BODY, PLANE_WING = { "models/xqm/jetbody3.mdl", "models/props_vehicles/van001a_physics.mdl" }, "models/xqm/airplanewing1.mdl"
local FIREWORK = { { 255, 60, 60 }, { 255, 210, 60 }, { 80, 200, 255 }, { 120, 255, 120 }, { 255, 100, 230 } }

local function PlaneSection(t)
    local kind = "intro"
    for _, sct in ipairs(E.sections) do if t >= sct.t then kind = sct.kind end end
    return kind
end

-- A place on the wings and the roof: out along each wing, a few rows deep.
local function WingSpot(i)
    local side = (i % 2 == 0) and 1 or -1
    local k = math.floor((i - 1) / 2)
    local along, row = k % 5, math.floor(k / 5)
    return Vector(-40 + row * 50, side * (90 + along * 55), 80 + row * 6)
end

local function PlaneBoard(e)
    if not IsValid(e) or e.lcEndRide or not IsValid(E.plane) then return end
    E.planeSeat = (E.planeSeat or 0) + 1
    e.lcEndRide = { v = E.plane, off = WingSpot(E.planeSeat) }
    E.riders = E.riders or {}
    E.riders[#E.riders + 1] = e
    if e:IsPlayer() then
        if e.InVehicle and e:InVehicle() and e.ExitVehicle then e:ExitVehicle() end
        e.lcEndFrozen = true
        e:Freeze(true)
        e:SetMoveType(MOVETYPE_NONE)
    end
    e:SetNW2Entity("lc_riding", E.plane)
    e:SetNW2Bool("lc_dancing", true)
end

SETUP.plane = function()
    local now = CurTime()
    E.songEnds = true -- (it is over when the song is)
    E.sections = LC.MarrowSections(cvPlaneSections:GetString())
    for _, sct in ipairs(E.sections) do if sct.kind == "end" then E.holdUntil = now + sct.t end end
    E.holdUntil = E.holdUntil or (now + 215)
    local lz = LC.PointsOfKind and LC.PointsOfKind("lz") or {}
    E.lz = (#lz > 0 and lz[1].pos) or (IsValid(E.by) and E.by:GetPos()) or Centre()
    LC.TimeStopped = true
    if RunConsoleCommand then RunConsoleCommand("ai_disabled", "1") end
    -- the plane: a body and two wings, low over the city
    local body = Prop(FirstModel(PLANE_BODY), E.lz + Vector(cvRadius:GetFloat(), 0, 450), 3)
    if not body then return end
    if body.SetSolid then body:SetSolid(SOLID_NONE) end
    E.plane = body
    if not util.IsValidModel or util.IsValidModel(PLANE_WING) then
        for _, side in ipairs({ -1, 1 }) do
            local w = Prop(PLANE_WING, body:GetPos(), 3)
            if w then
                if w.SetSolid then w:SetSolid(SOLID_NONE) end
                w:SetParent(body)
                if w.SetLocalPos then w:SetLocalPos(Vector(0, side * 160, 40)) end
                if w.SetLocalAngles then w:SetLocalAngles(Angle(0, side > 0 and 0 or 180, 0)) end
            end
        end
    end
    E.planeA, E.roll = 0, 0
    local caps = LC.BaseLines(cvPlaneCaptions:GetString())
    E.client = { party = true, lights = true, dance = "numa", bpm = cvPlaneBPM:GetFloat(), offset = 0, start = now, section = "intro",
        palette = FIREWORK, captions = caps, webcam = true, lipsync = true }
end

TICK.plane = function(now)
    local plane = E.plane
    if not IsValid(plane) then return end
    local t = now - E.phaseT
    local kind = PlaneSection(t)
    local beat = t * cvPlaneBPM:GetFloat() / 60
    if kind ~= E.client.section then
        E.client.section = kind
        E.client.lights = kind ~= "break"
        if kind == "board" then
            for _, p in ipairs(player.GetAll()) do PlaneBoard(p) end
            local c = 0
            for _, npc in ipairs(CombineNPCs()) do if c < cvPlaneCombine:GetInt() then c = c + 1 PlaneBoard(npc) end end
        elseif kind == "climb" then
            E.client.whiteAt = now + 3
        end
        Send()
    end
    if E.planeSeat then for _, p in ipairs(player.GetAll()) do PlaneBoard(p) end end -- (anyone joining, or back)
    -- the flight: wide and steady in the verses, swooping in the choruses, a glide in the break
    local speed = ({ intro = 0.12, board = 0.15, verse = 0.14, chorus = 0.24, ["break"] = 0.07, final = 0.32, climb = 0.2 })[kind] or 0.14
    E.planeA = E.planeA + speed * 0.1
    local r = cvRadius:GetFloat()
    local height = ({ intro = 450, board = 700 })[kind] or 1300
    if kind == "chorus" or kind == "final" then height = height + math.sin(t * 0.9) * 350 end
    if kind == "climb" then E.climb = (E.climb or 0) + 60 + (E.climb or 0) * 0.08 end
    local pos = E.lz + Vector(math.cos(E.planeA) * r, math.sin(E.planeA) * r, height + (E.climb or 0))
    local yaw = math.deg(E.planeA) + 90
    -- a barrel roll on the big hits (every 16 beats in a chorus), a bank otherwise
    local bank = (kind == "chorus" or kind == "final") and 30 or 12
    if (kind == "chorus" or kind == "final") and math.floor(beat) % 16 == 0 and math.floor(beat) ~= E.rollBeat then
        E.rollBeat = math.floor(beat)
        E.rollFrom = now
    end
    local roll = bank
    if E.rollFrom and now - E.rollFrom < 2 then roll = bank + 360 * ((now - E.rollFrom) / 2) end
    local pitch = kind == "climb" and -70 or math.sin(t * 0.7) * 6
    plane:SetPos(LerpVector(0.4, plane:GetPos(), pos))
    plane:SetAngles(Angle(pitch, yaw, roll))
    for _, e in ipairs(E.riders or {}) do
        local rd = IsValid(e) and e.lcEndRide
        if rd and IsValid(rd.v) then e:SetPos(rd.v.LocalToWorld and rd.v:LocalToWorld(rd.off) or (rd.v:GetPos() + rd.off)) end
    end
    -- fireworks round it in the last chorus
    if kind == "final" and now >= (E.nextFirework or 0) then
        E.nextFirework = now + math.Rand(0.3, 0.8)
        if util.Effect and EffectData then
            local fx = EffectData()
            fx:SetOrigin(plane:GetPos() + VectorRand() * 600 + Vector(0, 0, 200))
            local c = FIREWORK[math.random(#FIREWORK)]
            if fx.SetStart then fx:SetStart(Vector(c[1], c[2], c[3])) end
            util.Effect("balloon_pop", fx)
            util.Effect("cball_explode", fx)
        end
        if sound and sound.Play then sound.Play("weapons/flaregun/burn.wav", plane:GetPos(), 90, math.random(90, 130), 0.6) end
    end
end

-- Standup (a codeword): the rope. Every other beat from lc_ending_standup_sections'
-- "hang", someone else is strung up: a rope from whatever is above them (a
-- ledge, a balcony, a ceiling), or from the nearest wall of a building, or
-- failing both, from the sky. Players are spread through the song; the
-- city's people (the Combine's units too) fill the beats between, and when
-- there's nobody left, new people turn up near you to be next. The hanged
-- swing and struggle while their health drains; at nothing they go limp,
-- and stay hanging there, looking on.
local cvStandupSections = CreateConVar("lc_ending_standup_sections", "11:hang,104:last,110:end", FLAGS,
    "Standup: the song's sections, second:kind (hang, last, end)")
local cvStandupBPM   = CreateConVar("lc_ending_standup_bpm", "133", FLAGS, "Standup: the song's beats per minute (someone new every other beat)")
local cvStandupDrain = CreateConVar("lc_ending_standup_drain", "4", FLAGS, "Standup: health a second the hanged lose")
local cvStandupMax   = CreateConVar("lc_ending_standup_max", "60", FLAGS, "Standup: the most people strung up in all")
local cvStandupCrowd = CreateConVar("lc_ending_standup_crowd", "14", FLAGS, "Standup: how many people gather round to cheer")
-- (the hanged are painted white, white cone hats on: the Klan, strung up, and the crowd loves it)
local CROWD = {
    "models/humans/group01/male_01.mdl", "models/humans/group01/male_03.mdl", "models/humans/group01/male_04.mdl", "models/humans/group01/male_07.mdl",
    "models/humans/group01/male_09.mdl", "models/humans/group01/female_01.mdl", "models/humans/group01/female_03.mdl", "models/humans/group01/female_06.mdl",
    "models/humans/group02/male_02.mdl", "models/humans/group02/male_06.mdl", "models/humans/group02/female_02.mdl", "models/humans/group02/female_04.mdl",
}
local CHEERS = { "vo/npc/male01/yeah02.wav", "vo/npc/female01/yeah02.wav", "vo/npc/male01/fantastic01.wav", "vo/npc/female01/finally.wav",
    "vo/npc/male01/likethat.wav", "vo/npc/female01/nice01.wav", "vo/npc/male01/question17.wav" }

local function StandupSection(t)
    local kind = "intro"
    for _, sct in ipairs(E.sections) do if t >= sct.t then kind = sct.kind end end
    return kind
end

-- Where the rope goes: something overhead, else the nearest wall, else the sky.
local function RopeAnchor(pos)
    local up = util.TraceLine({ start = pos + Vector(0, 0, 80), endpos = pos + Vector(0, 0, 900), mask = MASK_SOLID_BRUSHONLY })
    if up.Hit and not up.HitSky then return up.HitPos - Vector(0, 0, 4), Vector(0, 0, 0) end
    local best, bestD, out
    for i = 0, 7 do
        local dir = Angle(0, i * 45, 0):Forward()
        local tr = util.TraceLine({ start = pos + Vector(0, 0, 300), endpos = pos + Vector(0, 0, 300) + dir * 700, mask = MASK_SOLID_BRUSHONLY })
        if tr.Hit and not tr.HitSky and (not bestD or tr.Fraction < bestD) then best, bestD, out = tr.HitPos, tr.Fraction, (tr.HitNormal or -dir) end
    end
    if best then return best + out * 40, out end
    return pos + Vector(0, 0, 500), Vector(0, 0, 0)
end

local function Hang(e)
    if not IsValid(e) or e.lcHang or e.lcEndTaken then return false end
    local pos = e:GetPos()
    local anchor = RopeAnchor(pos)
    local g = Ground(pos)
    local drop = anchor.z - 110 - 72 -- (a rope, then the person under it)
    local feet = math.max(drop, ((g and g.z) or pos.z) + 25)
    e.lcHang = { anchor = anchor, base = Vector(anchor.x, anchor.y, feet), t0 = CurTime() }
    e:SetNW2Float("lc_hanged", CurTime())
    -- painted white, and (on each screen) a white cone hat over the head
    if e.SetMaterial then e:SetMaterial("models/debug/debugwhite") end
    if e.SetColor then e:SetColor(Color(245, 245, 245, 255)) end
    if e:IsPlayer() then
        if e.InVehicle and e:InVehicle() and e.ExitVehicle then e:ExitVehicle() end
        e.lcEndFrozen = true
        e:Freeze(true)
        e:SetMoveType(MOVETYPE_NONE)
        e:ChatPrint("A rope drops round your neck from above, and up you go.")
    end
    e:EmitSound("physics/wood/wood_strain" .. math.random(2, 4) .. ".wav", 80)
    -- and the crowd goes wild
    for i = 1, math.min(3, #(E.crowd or {})) do
        local c = E.crowd[math.random(#E.crowd)]
        if IsValid(c) then c:EmitSound(CHEERS[math.random(#CHEERS)], 80, math.random(95, 108)) end
    end
    E.hanged[#E.hanged + 1] = e
    E.client.hangs[#E.client.hangs + 1] = { e = e:EntIndex(), a = anchor }
    Send()
    return true
end

-- Gone limp: still hanging there, looking on.
local function Limp(e)
    if not IsValid(e) or e.lcEndTaken then return end
    e:SetNW2Bool("lc_limp", true)
    if e:IsPlayer() then
        e.lcEndTaken = true
        e:SetNW2Bool("lc_end_taken", true)
        e:ChatPrint("You stop kicking. You hang there, and watch the rest.")
        hook.Run("LivingCityEndingTook", e, E and E.id)
    end
end

SETUP.standup = function()
    local now = CurTime()
    E.songEnds = true -- (it is over when the song is)
    E.sections = LC.MarrowSections(cvStandupSections:GetString())
    local hangAt, lastAt = now + 11, now + 104
    for _, sct in ipairs(E.sections) do
        if sct.kind == "end" then E.holdUntil = now + sct.t end
        if sct.kind == "hang" then hangAt = now + sct.t end
        if sct.kind == "last" then lastAt = now + sct.t end
    end
    E.holdUntil = E.holdUntil or (now + 110)
    E.hanged, E.crowd = {}, {}
    E.beatLen = 60 / math.max(1, cvStandupBPM:GetFloat())
    -- the players, spread through the song; everyone else on the beats between
    local ps = player.GetAll()
    E.playerGap = math.max(E.beatLen * 2, (lastAt - hangAt) / math.max(1, #ps))
    E.nextPlayer = hangAt
    E.nextAny = hangAt
    LC.TimeStopped = true
    if RunConsoleCommand then RunConsoleCommand("ai_disabled", "1") end
    E.client = { party = true, lights = false, dance = "cheer", bpm = cvStandupBPM:GetFloat(), offset = 0, start = now, hangs = {} }
end

TICK.standup = function(now)
    local t = now - E.phaseT
    local kind = StandupSection(t)
    -- the crowd gathers round, and cheers every one
    if (kind == "hang" or kind == "last") and not E.crowded then
        E.crowded = true
        local near = Living()[1] or player.GetAll()[1]
        local centre = near and near:GetPos() or Centre()
        for i = 1, cvStandupCrowd:GetInt() do
            local spot = RingSpot(centre, math.Rand(220, 520), false)
            if spot then
                local c = ents.Create("npc_citizen")
                if IsValid(c) then
                    c:SetModel(CROWD[(i - 1) % #CROWD + 1])
                    c:SetPos(spot)
                    c:SetAngles(Angle(0, (centre - spot):Angle().y, 0))
                    c:Spawn()
                    c.lcCrowd = true
                    c:SetNW2Bool("lc_dancing", true)
                    E.ents[#E.ents + 1] = c
                    E.crowd[#E.crowd + 1] = c
                end
            end
        end
    end
    if kind == "hang" or kind == "last" then
        -- a player, on their turn
        if now >= E.nextPlayer then
            E.nextPlayer = now + E.playerGap
            local pick = {}
            for _, p in ipairs(Living()) do if not p.lcHang then pick[#pick + 1] = p end end
            if #pick > 0 then Hang(pick[math.random(#pick)]) E.nextAny = now + E.beatLen * 2 end
        end
        -- and on every other beat between, somebody else
        if now >= E.nextAny and #E.hanged < cvStandupMax:GetInt() then
            E.nextAny = now + E.beatLen * 2
            local victim
            for npc in pairs(LC.NPCs or {}) do if IsValid(npc) and not npc.lcHang and not npc.lcCrowd then victim = npc break end end
            if not victim then
                -- nobody left: someone turns up near one of you to be next
                local near = Living()[1] or player.GetAll()[1]
                local spot = near and RingSpot(near:GetPos(), math.Rand(250, 600), false)
                if spot then
                    victim = ents.Create("npc_citizen")
                    if IsValid(victim) then
                        victim:SetPos(spot)
                        victim:Spawn()
                        E.ents[#E.ents + 1] = victim
                    end
                end
            end
            if IsValid(victim) then Hang(victim) end
        end
    end
    -- the last of the song: everyone left goes up
    if kind == "last" and not E.lastHang then
        E.lastHang = true
        for _, p in ipairs(Living()) do if not p.lcHang then Hang(p) end end
    end
    -- the hanged: swinging, turning, and (the living) losing health
    local drain = cvStandupDrain:GetFloat() * 0.1
    for _, e in ipairs(E.hanged) do
        local h = IsValid(e) and e.lcHang
        if h then
            local k = now - h.t0
            local limp = e:GetNW2Bool("lc_limp", false)
            local swing = limp and 4 or 10
            e:SetPos(h.base + Vector(math.sin(k * 1.3) * swing, math.cos(k * 1.1) * swing * 0.6, 0))
            e:SetAngles(Angle(0, (k * (limp and 6 or 25)) % 360, 0))
            if not limp then
                if e:IsPlayer() then
                    e.lcHangHP = (e.lcHangHP or e:Health()) - drain
                    e:SetHealth(math.max(1, math.floor(e.lcHangHP)))
                    if e.lcHangHP <= 0 then Limp(e) end
                elseif k > 6 then
                    Limp(e)
                end
            end
        end
    end
end

-- The hanged can't do anything about it.
hook.Add("CanPlayerSuicide", "LivingCityStandup", function(p) if p.lcHang then return false end end)

-- The Flood: Father Grigori's song. A stage floats at the landing zone with
-- everyone on it; the storm is at its worst; the water rises over the city.
-- The song's sections (lc_ending_flood_sections, worked out from the song
-- itself) set how violent it is: the stage pitches and the waves knock
-- people off, ichthyosaurs circle under the water, go for anyone in it, and
-- leap at anyone near the edge; lightning on the big beats. In the water
-- you swim (Jump to go up) and can climb back on, but stay under too long
-- and you drown. Father Grigori rocks out the whole time, untouchable, and
-- goes last, on the final note.
local cvFloodSections = CreateConVar("lc_ending_flood_sections", "15:heavy,79:calm,102:heavy,134:calm,169:heavy,183:climax,212:calm,235:heavy,249:climax,264:outro,276:last,285:end", FLAGS,
    "The Flood: the song's sections, second:kind (calm, heavy, climax, outro, last, end); before the first, it builds")
local cvFloodBPM   = CreateConVar("lc_ending_flood_bpm", "150", FLAGS, "The Flood: the song's beats per minute (the lightning keeps to it)")
local cvFloodRise  = CreateConVar("lc_ending_flood_rise", "900", FLAGS, "The Flood: how high the water rises over the landing zone by the outro")
local cvFloodDrown = CreateConVar("lc_ending_flood_drown", "10", FLAGS, "The Flood: seconds under the water before you drown")
local cvIcthys     = CreateConVar("lc_ending_flood_icthys", "8", FLAGS, "The Flood: how many ichthyosaurs at the worst of it")
local INTENSITY = { intro = 0.3, calm = 0.35, heavy = 0.75, climax = 1, outro = 0.25, last = 0.1 }
local STAGE_MODEL, STAGE_R = "models/hunter/plates/plate8x8.mdl", 170

local function FloodSection(t)
    local kind = "intro"
    for _, sct in ipairs(E.sections) do if t >= sct.t then kind = sct.kind end end
    return kind
end

local function OnStage(p)
    local st = E.stage
    if not IsValid(st) then return false end
    local d = p:GetPos() - st:GetPos()
    return math.abs(d.x) < STAGE_R + 20 and math.abs(d.y) < STAGE_R + 20 and d.z > -20 and d.z < 140
end
local function StageSpot(spread)
    local st = E.stage
    return st:GetPos() + Vector(math.Rand(-spread, spread), math.Rand(-spread, spread), 8)
end
local function Immune(p) return p == E.grigori end

local function Bite(p, how)
    local now = CurTime()
    if not IsValid(p) or p.lcEndTaken or Immune(p) or now < (p.lcBiteAt or 0) then return false end
    p.lcBiteAt = now + 1
    p:EmitSound("npc/ichthyosaur/snap.wav", 85)
    p:SetHealth(p:Health() - math.random(15, 25))
    if p.ViewPunch then p:ViewPunch(Angle(math.Rand(-15, 15), math.Rand(-15, 15), 0)) end
    if p:Health() <= 0 then Spectator(p, how or "Something huge comes up out of the dark water. That's the last you see.", Color(20, 40, 90, 230)) end
    return true
end

function LC.IcthyStep(m, dt)
    local s = m.lcIcthy
    if not s or not E or E.id ~= "water" then return end
    local now = CurTime()
    if s.leap then
        local L = s.leap
        local f = math.min(1, (now - L.t0) / L.dur)
        m:SetPos(LerpVector(f, L.from, L.to) + Vector(0, 0, 4 * L.h * f * (1 - f)))
        if f >= 1 then
            s.leap = nil
            local t = s.target
            if IsValid(t) and t:GetPos():DistToSqr(m:GetPos()) < 100 * 100 and Bite(t, "It comes over the edge of the stage at you, jaws first. That's the last you see.") then
                local away = t:GetPos() - E.stage:GetPos()
                away.z = 0
                if t.SetVelocity and not t.lcEndTaken then t:SetVelocity(away:GetNormalized() * 400 + Vector(0, 0, 200)) end
            end
        end
        return
    end
    if not s.goal then return end
    local pos = m:GetPos()
    local to = s.goal - pos
    local dist = to:Length()
    if dist < 8 then return end
    local dir = to * (1 / dist)
    local nextPos = pos + dir * math.min(dist, (s.speed or 200) * (dt or 0.1))
    nextPos.z = math.min(nextPos.z, (E.floodZ or nextPos.z) - 45) -- (under the water, always)
    m:SetPos(nextPos)
    m:SetAngles(Angle(0, dir:Angle().y, 0))
end

function LC.IcthyHurt(m, dmg)
    local s = m.lcIcthy
    if not s then return false end
    s.hp = s.hp - (dmg and dmg.GetDamage and dmg:GetDamage() or 150)
    if s.hp > 0 then return false end
    m:EmitSound("npc/ichthyosaur/die1.wav", 85)
    m:Remove()
    E.nextIcthy = CurTime() + 6
    return true
end

local function SpawnIcthy()
    local st = E.stage
    local a = math.Rand(0, math.pi * 2)
    local pos = st:GetPos() + Vector(math.cos(a), math.sin(a), 0) * math.Rand(600, 900)
    pos.z = E.floodZ - 70
    local m = ents.Create("lc_icthy")
    if not IsValid(m) then return end
    m:SetModel("models/ichthyosaur.mdl")
    m:SetPos(pos)
    m:Spawn()
    m.lcIcthy = { hp = 150, a = a, dir = math.random() < 0.5 and 1 or -1 }
    E.ents[#E.ents + 1] = m
    E.icthys[#E.icthys + 1] = m
end

SETUP.water = function()
    local now = CurTime()
    E.songEnds = true -- (it is over when the song is)
    E.sections = LC.MarrowSections(cvFloodSections:GetString())
    for _, sct in ipairs(E.sections) do if sct.kind == "end" then E.holdUntil = now + sct.t end end
    E.holdUntil = E.holdUntil or (now + 285)
    E.riseBy = now + 264
    for _, sct in ipairs(E.sections) do if sct.kind == "outro" then E.riseBy = now + sct.t end end
    local lz = LC.PointsOfKind and LC.PointsOfKind("lz") or {}
    E.lz = (#lz > 0 and lz[1].pos) or (IsValid(E.by) and E.by:GetPos()) or Centre()
    E.floodBase = E.lz.z - 30
    E.floodZ = E.floodBase
    -- real water, if the map has it: a func_water_analog named lc_flood (the
    -- mapper's own rising water, the way Half-Life 2 does it). Then the engine
    -- does the swimming; otherwise the water is drawn and the swimming is ours.
    local real = ents.FindByName and ents.FindByName("lc_flood")[1]
    if IsValid(real) then
        E.realWater = real
        SetGlobal2Bool("lc_flood_real", true)
        real:Fire("Open") -- (func_water_analog rises to its open position; SetPosition below follows the song)
    end
    E.icthys = {}
    LC.TimeStopped = true
    if RunConsoleCommand then RunConsoleCommand("ai_disabled", "1") end
    -- the stage, at the landing zone
    local st = Prop(STAGE_MODEL, E.lz + Vector(0, 0, 4))
    if st then
        if st.PhysicsInit then st:PhysicsInit(SOLID_VPHYSICS) end
        local ph = st.GetPhysicsObject and st:GetPhysicsObject()
        if IsValid(ph) then ph:EnableMotion(false) end
        if st.SetMaterial then st:SetMaterial("phoenix_storms/wood") end
    end
    E.stage = st
    -- Father Grigori in the middle, everyone round him
    if IsValid(E.by) then
        E.grigori = E.by
        E.by:SetNW2Bool("lc_rocking", true)
    end
    for _, p in ipairs(player.GetAll()) do
        if p.InVehicle and p:InVehicle() and p.ExitVehicle then p:ExitVehicle() end
        if IsValid(st) then p:SetPos(p == E.grigori and (st:GetPos() + Vector(0, 0, 8)) or StageSpot(STAGE_R - 40)) end
        if p:Health() < 100 then p:SetHealth(100) end
    end
    -- the worst storm the city has seen
    if LC.SetWeather then LC.SetWeather("storm", true) end
    SetGlobal2Bool("lc_storm_max", true)
    E.dark = true
    LC.EndingDark = "e"
    if LC.ApplyLightStyle then LC.ApplyLightStyle() end
    E.section = "intro"
    E.client = { bpm = cvFloodBPM:GetFloat(), offset = 0, start = now } -- (the beat Father Grigori headbangs to)
end

TICK.water = function(now)
    local st = E.stage
    if not IsValid(st) then return end
    local t = now - E.phaseT
    local kind = FloodSection(t)
    E.section = kind
    if E.client and E.client.section ~= kind then E.client.section = kind Send() end -- (Father Grigori headbangs the heavy parts and dances the rest)
    local I = INTENSITY[kind] or 0.5
    SetGlobal2Float("lc_flood_slosh", I)
    -- the water rises, and the stage floats on it
    local k = math.Clamp(t / math.max(1, E.riseBy - E.phaseT), 0, 1)
    E.floodZ = E.floodBase + cvFloodRise:GetFloat() * (1 - (1 - k) ^ 2)
    if IsValid(E.realWater) then
        -- the map's own water: raised along its path, and its surface is the water line
        E.realWater:Fire("SetPosition", tostring(1 - (1 - k) ^ 2))
        local top = E.realWater.OBBMaxs and E.realWater:LocalToWorld(E.realWater:OBBMaxs()).z
        if top then E.floodZ = top end
    end
    SetGlobal2Float("lc_flood_z", E.floodZ)
    local sp = st:GetPos()
    st:SetPos(Vector(sp.x, sp.y, math.max(E.lz.z + 4, E.floodZ - 6)))
    -- the waves: a shove all the time, and a big one now and then
    local wave = Angle(0, (t * 25 + math.sin(t * 0.13) * 120) % 360, 0):Forward()
    local big = now >= (E.nextWave or 0)
    if big then
        E.nextWave = now + math.Rand(6, 10) * (1.2 - I)
        st:EmitSound("ambient/water/wave" .. math.random(1, 6) .. ".wav", 90)
        if util.ScreenShake then util.ScreenShake(st:GetPos(), 2 + 6 * I, 5, 1.2, 900) end
    end
    local g = E.grigori
    for _, p in ipairs(Living()) do
        if p ~= g then
            if OnStage(p) and p.SetVelocity then
                local push = wave * ((big and (250 + 500 * I) or (25 + 70 * I)) * math.Rand(0.6, 1.2))
                p:SetVelocity(Vector(push.x, push.y, big and 60 or 0))
            end
            -- under the water: you hold your breath, then you drown
            if p:EyePos().z < E.floodZ then
                p.lcEndUnder = p.lcEndUnder or now
                if now - p.lcEndUnder > cvFloodDrown:GetFloat() then
                    Spectator(p, "The water closes over your head. Somewhere above, Father Grigori hits the high note.", Color(20, 40, 90, 230))
                end
            else
                p.lcEndUnder = nil
            end
        end
    end
    -- Father Grigori keeps his feet, whatever happens
    if IsValid(g) and not g.lcEndTaken then
        if not OnStage(g) then g:SetPos(st:GetPos() + Vector(0, 0, 8)) end
        if g:Health() < 100 then g:SetHealth(100) end
        -- (he headbangs, mic in hand: cl_livingcity_endings.lua, on the song's beat)
    end
    -- lightning on the big beats
    if (kind == "heavy" or kind == "climax") then
        local beat = math.floor(t * cvFloodBPM:GetFloat() / 60)
        if beat ~= E.lastBeat then
            E.lastBeat = beat
            if beat % (kind == "climax" and 4 or 8) == 0 and math.random() < 0.8 then SetGlobal2Float("lc_flood_flash", now) end
        end
    end
    -- the ichthyosaurs, once there's water enough for them
    local alive = {}
    for _, m in ipairs(E.icthys) do if IsValid(m) then alive[#alive + 1] = m end end
    E.icthys = alive
    local want = math.max(2, math.floor(cvIcthys:GetInt() * I))
    if kind == "last" then want = 0 end
    if E.floodZ - E.floodBase > 60 and #E.icthys < want and now >= (E.nextIcthy or 0) then
        E.nextIcthy = now + 1.5
        SpawnIcthy()
    end
    local swimmers, edge = {}, {}
    for _, p in ipairs(Living()) do
        if p ~= g then
            if not OnStage(p) and p:GetPos().z < E.floodZ - 10 then swimmers[#swimmers + 1] = p
            elseif OnStage(p) and (p:GetPos() - st:GetPos()):Length2D() > STAGE_R * 0.5 then edge[#edge + 1] = p end
        end
    end
    for _, m in ipairs(E.icthys) do
        local s = m.lcIcthy
        if not s.leap then
            local best, bd
            for _, p in ipairs(swimmers) do
                local d = p:GetPos():DistToSqr(m:GetPos())
                if d < 1500 * 1500 and (not bd or d < bd) then best, bd = p, d end
            end
            if best then
                s.goal, s.speed, s.target = best:GetPos(), 260 + 200 * I, best
                if bd < 100 * 100 then Bite(best) end
            else
                -- circling the stage
                s.a = s.a + s.dir * 0.03 * (0.5 + I)
                s.goal = st:GetPos() + Vector(math.cos(s.a), math.sin(s.a), 0) * (STAGE_R + 220)
                s.goal.z = E.floodZ - 70
                s.speed = 160 + 160 * I
                -- and in the worst of it, a leap at whoever's near the edge
                if #edge > 0 and (kind == "heavy" or kind == "climax") and math.random() < 0.012 * I * 10 and now >= (s.nextLeap or 0) then
                    local v = edge[math.random(#edge)]
                    s.target = v
                    s.nextLeap = now + 6
                    s.leap = { from = m:GetPos(), to = v:GetPos(), t0 = now, dur = 0.9, h = 120 }
                    m:EmitSound("npc/ichthyosaur/attack_growl" .. math.random(1, 3) .. ".wav", 90)
                end
            end
        end
        if not m.lcThinks then LC.IcthyStep(m, 0.1) end
    end
    -- the last note: whoever's still here goes, and Father Grigori last of all
    if kind == "last" and not E.lastDone then
        E.lastDone = true
        for _, p in ipairs(Living()) do
            if p ~= g then Spectator(p, "The tide takes you, gently, at the very end.", Color(20, 40, 90, 230)) end
        end
        if IsValid(g) then Spectator(g, "Father Grigori holds the last note, bows, and the flood takes its encore.", Color(255, 255, 255, 200)) end
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
        if p.lcHang then
            p:Freeze(false)
            p:SetMoveType(MOVETYPE_WALK)
            if p.SetMaterial then p:SetMaterial("") end
            if p.SetColor then p:SetColor(Color(255, 255, 255, 255)) end
        end
        p.lcHang, p.lcHangHP = nil, nil
        p:SetNW2Float("lc_hanged", 0)
        p:SetNW2Bool("lc_limp", false)
        p.lcEndTaken, p.lcEndRide, p.lcEndHang, p.lcEndUnder = nil, nil, nil, nil
        p.lcEndSpectating, p.lcEndWatching, p.lcEndRoam = nil, nil, nil
        if p.lcEndModel then p:SetModel(p.lcEndModel) p.lcEndModel = nil end
        p:SetNW2Bool("lc_end_taken", false)
        p:SetNW2Bool("lc_end_spectating", false)
        p:SetNW2Bool("lc_dancing", false)
        p:SetNW2Bool("lc_seated", false)
        p:SetNW2Entity("lc_riding", NULL)
        p.lcBloomUp = nil
        p:SetNW2Bool("lc_rocking", false)
    end
    SetGlobal2Float("lc_flood_z", 0)
    SetGlobal2Float("lc_flood_slosh", 0)
    SetGlobal2Bool("lc_storm_max", false)
    SetGlobal2Bool("lc_flood_real", false)
    for _, p in ipairs(player.GetAll()) do if p.SetGravity then p:SetGravity(1) end p.lcEndUnder = nil end
    for npc in pairs(LC.NPCs or {}) do
        if IsValid(npc) then
            npc:SetNW2Bool("lc_dancing", false) npc:SetNW2Bool("lc_seated", false) npc.lcBloomUp = nil npc.lcEndRide = nil
            if npc.lcHang then npc.lcHang = nil npc:SetNW2Float("lc_hanged", 0) npc:SetNW2Bool("lc_limp", false) end
        end
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
            -- (an ending can run to the end of its song even after the last one goes: the dead
            -- watch; and one that lasts its song, with people still in it, ends with the song)
            local songOver = E.holdUntil and now >= E.holdUntil
            if (songOver and (#Living() == 0 or E.songEnds)) or (not E.holdUntil and #Living() == 0)
                or now - E.phaseT > math.max(cvMax:GetFloat(), (E.holdUntil or 0) - E.phaseT + 1) then GoTo("reset") end
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
    return LC.TriggerEnding("water", ply)
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
